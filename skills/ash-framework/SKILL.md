---
name: ash-framework
description:
  Ash Framework patterns for Elixir applications - use this skill when working
  with Ash resources, policies, actor context, changesets, transactions, or
  Reactor workflows. Essential for authorization, multi-tenancy, and
  resource-oriented design.
---

# Ash Framework Skill

**Master Ash Framework patterns for building secure, multi-tenant Elixir
applications.**

## What is Ash Framework?

Ash is a declarative, resource-oriented framework for building Elixir
applications. Ash resources model your business domain with:

- **Attributes**: Data fields with types and constraints
- **Relationships**: Connections between resources
- **Actions**: Operations (CRUD + custom) with validations
- **Policies**: Authorization rules for multi-tenant security
- **Calculations**: Derived values
- **Aggregates**: Computed summaries

## When to Use This Skill

Use this skill when you need to:

- ✅ **Understand actor context propagation** - How user identity flows through
  operations
- ✅ **Write authorization policies** - Multi-tenant security and RBAC
- ✅ **Create or modify resources** - Domain modeling with Ash
- ✅ **Work with changesets** - Validations and transformations
- ✅ **Build transactions** - Multi-step atomic operations
- ✅ **Debug authorization failures** - Policy issues and NotFound vs Forbidden
- ✅ **Implement Reactor workflows** - Sagas with compensation
- ✅ **Validate embedded resources** - Nested data structures

## Core Principles

### 1. Actor Context is Sacred

**ALWAYS pass actor explicitly in every Ash operation:**

```elixir
# ✅ Correct
Ash.create(changeset, actor: user)

# ❌ Never in production
Ash.create(changeset, authorize?: false)
```

Actor context enforces:

- Multi-tenant data isolation
- Role-based permissions
- Audit trails

See: [reference/actor-context.md](reference/actor-context.md) |
[examples/actor-context.ex](examples/actor-context.ex)

### 2. Resources are the Source of Truth

Model your domain declaratively. Ash derives:

- Database schemas
- APIs (JSON, GraphQL)
- Authorization enforcement
- Validation logic

See: [reference/resources.md](reference/resources.md) |
[examples/resources.ex](examples/resources.ex)

### 3. Policies Enforce Security

Every resource has policies that check:

- Organization membership (multi-tenancy)
- User roles (admin, editor, viewer)
- Custom business rules

See: [reference/policies.md](reference/policies.md) |
[examples/policies.ex](examples/policies.ex)

### 4. Transactions Ensure Consistency

Use `transaction? true` for multi-step operations with automatic rollback.

See: [reference/transactions.md](reference/transactions.md) |
[examples/transactions.ex](examples/transactions.ex)

## Quick Reference

### Common Tasks

| Task                        | Reference                                                     | Example                                               |
| --------------------------- | ------------------------------------------------------------- | ----------------------------------------------------- |
| Pass actor in actions       | [Actor Context](reference/actor-context.md)                   | [actor-context.ex](examples/actor-context.ex)         |
| Write multi-tenant policies | [Policies](reference/policies.md)                             | [policies.ex](examples/policies.ex)                   |
| Define resources            | [Resources](reference/resources.md)                           | [resources.ex](examples/resources.ex)                 |
| Build changesets            | [Changesets](reference/changesets.md)                         | [changesets.ex](examples/changesets.ex)               |
| Create transactions         | [Transactions](reference/transactions.md)                     | [transactions.ex](examples/transactions.ex)           |
| Build Reactor workflows     | [Actor Context](reference/actor-context.md#reactor-workflows) | [reactor-workflows.ex](examples/reactor-workflows.ex) |

### Critical Patterns

1. **Actor Propagation**: Build once at entry point, pass everywhere
2. **Context in Hooks**: Access actor via `Map.get(context, :actor)`
3. **NotFound over Forbidden**: Hide resource existence for security
4. **Embedded Validation**: Always validate with changeset before struct
   creation
5. **Transaction Atomicity**: Multi-step operations must succeed or rollback
   together

## Project-Specific Conventions

### Multi-Tenancy

Every resource scoped by `organization_id`:

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end
end
```

### Role Hierarchy

- **Admin**: Full access within organization
- **Editor**: Create/update resources
- **Viewer**: Read-only access

### System Actor

For authentication bootstrap, use system actor (not `authorize?: false`):

```elixir
# Example: Define system actor in your application
defmodule MyApp.Auth.SystemActor do
  def system_actor do
    %{id: :system, role: :system}
  end
end

User |> Ash.get(user_id, actor: system_actor())
```

## File Organization

```
.claude/skills/ash-framework/
├── SKILL.md              ← You are here
├── examples/             ← Self-contained runnable code
│   ├── actor-context.ex
│   ├── policies.ex
│   ├── resources.ex
│   ├── changesets.ex
│   ├── transactions.ex
│   └── reactor-workflows.ex
└── reference/            ← Deep dives with links
    ├── actor-context.md
    ├── policies.md
    ├── resources.md
    └── transactions.md
```

## External Resources

### Official Documentation

- **Ash Framework**: https://hexdocs.pm/ash/
- **Ash Get Started**: https://hexdocs.pm/ash/get-started.html
- **Ash Postgres**: https://hexdocs.pm/ash_postgres/
- **Ash Policy Authorizer**: https://hexdocs.pm/ash/policies.html
- **Reactor**: https://hexdocs.pm/reactor/

### Project Documentation

- **Project documentation**: Check your project's design docs for
  application-specific patterns
- **Team conventions**: Review project README and development guides
- **Official Ash docs**: hexdocs.pm/ash for framework details

## Learning Path

### Beginner: Understanding Basics

1. Read [reference/resources.md](reference/resources.md) - What are resources?
2. Study [examples/resources.ex](examples/resources.ex) - See real definitions
3. Read [reference/actor-context.md](reference/actor-context.md) - Why actor
   matters
4. Run [examples/actor-context.ex](examples/actor-context.ex) - Practice passing
   actor

### Intermediate: Building Features

1. Read [reference/policies.md](reference/policies.md) - Multi-tenant security
2. Study [examples/policies.ex](examples/policies.ex) - Real policy patterns
3. Read [reference/transactions.md](reference/transactions.md) - Atomic
   operations
4. Build a simple resource with policies

### Advanced: Complex Workflows

1. Study [examples/reactor-workflows.ex](examples/reactor-workflows.ex) - Sagas
2. Read DESIGN/architecture/reactor-patterns.md - Workflow patterns
3. Implement multi-step workflow with compensation
4. Review DESIGN/security/authorization.md - Advanced patterns

## Troubleshooting

### Authorization Failures

**Error**: `Ash.Error.Forbidden` or `Ash.Error.Query.NotFound`

**Check**:

1. Is actor passed? `actor: user`
2. Does user belong to resource's organization?
3. Does user have required role?
4. Review resource policies

See:
[reference/policies.md#debugging](reference/policies.md#debugging-authorization-failures)

### Changeset Errors

**Error**: Validation failures or struct creation errors

**Check**:

1. Are all required fields present?
2. Is embedded resource validated before struct creation?
3. Is context set during changeset creation (not after)?

See: [examples/changesets.ex](examples/changesets.ex#embedded-validation)

### Transaction Failures

**Error**: Partial updates or inconsistent state

**Check**:

1. Is `transaction? true` set on action?
2. Is `require_atomic? false` needed?
3. Are all steps passing actor?

See: [reference/transactions.md](reference/transactions.md)

## Getting Help

1. **Search examples**: Find pattern similar to your use case
2. **Read reference docs**: Deep dive into specific topic
3. **Check project docs**: Review your application's design documentation
4. **Review actual code**: Examine existing resources in your codebase
5. **Official docs**: hexdocs.pm/ash for framework details

## Related Skills

- **manual-qa**: Testing Ash resources and policies
- **testing-strategy**: How to test authorization
- **elixir-patterns**: General Elixir and Phoenix patterns

---

**Remember**: In multi-tenant Ash applications, actor context is everything.
Always pass it, never bypass it.
