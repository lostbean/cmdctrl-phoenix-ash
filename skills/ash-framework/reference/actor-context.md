# Actor Context Reference

**Deep dive into actor context propagation in Ash Framework**

Actor context is the most critical security mechanism in MyApp. Every Ash
operation carries actor context to enforce multi-tenant isolation and role-based
permissions.

## Table of Contents

- [What is Actor Context?](#what-is-actor-context)
- [Actor Structure](#actor-structure)
- [Propagation Patterns](#propagation-patterns)
- [Common Pitfalls](#common-pitfalls)
- [Testing with Actors](#testing-with-actors)
- [Related Resources](#related-resources)

## What is Actor Context?

Actor context represents **who is performing an operation** in the system. It
carries:

- **User identity**: UUID of the authenticated user
- **Tenant boundary**: organization_id for multi-tenant isolation
- **Permissions**: Role and granular permissions
- **System flag**: Marks system actor for bootstrap operations

### Why Actor Context Matters

✅ **Security**: Enforces that users can only access their organization's data
✅ **Authorization**: Policies check actor.role to grant/deny actions ✅
**Audit**: Track who performed what operation ✅ **Consistency**: Same actor
flows through entire operation stack

## Actor Structure

```elixir
%{
  id: user.id,                          # User UUID
  organization_id: user.organization_id, # Tenant boundary
  role: user.role,                       # :admin, :editor, :viewer
  permissions: user.permissions || []    # Future: granular permissions
}
```

### Building Actor Context

Build actor once at entry point (LiveView mount, controller action, API
endpoint):

```elixir
def mount(_params, %{"user_id" => user_id}, socket) do
  user = Accounts.User.get!(user_id)

  actor = %{
    id: user.id,
    organization_id: user.organization_id,
    role: user.role,
    permissions: user.permissions || []
  }

  {:ok, assign(socket, :actor, actor)}
end
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L18-L31) for
complete example

## Propagation Patterns

### In Resource Actions

Always pass actor explicitly:

```elixir
# Create
Resource
|> Ash.Changeset.for_create(:create, attrs, actor: actor)
|> Ash.create()

# Read
Resource
|> Ash.Query.for_read(:read, %{}, actor: actor)
|> Ash.read()

# Update
resource
|> Ash.Changeset.for_update(:update, changes, actor: actor)
|> Ash.update()
```

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L46-L78) for action
  examples
- [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md#calling-actions-with-actor)
  for architecture

### In Change Functions

Access actor from `context` parameter (3rd argument):

```elixir
change fn changeset, _opts, context ->
  case Map.get(context, :actor) do
    nil ->
      Ash.Changeset.add_error(changeset, "Actor required")

    actor ->
      changeset
      |> Ash.Changeset.change_attribute(:created_by_id, actor.id)
      |> Ash.Changeset.change_attribute(:organization_id, actor.organization_id)
  end
end
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L96-L113) for
detailed example

### In After-Action Hooks

**CRITICAL**: Actor is in `context` parameter (3rd param), not changeset!

```elixir
change after_action(fn changeset, resource, context ->
  # ✅ CORRECT: Access actor from context parameter
  case Map.get(context, :actor) do
    nil -> {:error, "Actor required"}

    actor ->
      # Create related resource with same actor
      RelatedResource
      |> Ash.Changeset.for_create(:create, %{resource_id: resource.id}, actor: actor)
      |> Ash.create()

      {:ok, resource}
  end
end)
```

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L125-L149) for
  complete hook example
- [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md#after-action-hooks)
  for architecture details

### In Reactor Workflows

Pass actor in BOTH inputs and context:

```elixir
defmodule MyWorkflow do
  use Reactor

  input :actor  # ✅ Declare actor input

  step :create_resource do
    run fn arguments, context ->
      # ✅ Access actor from context
      actor = Map.get(context, :actor)

      Resource
      |> Ash.Changeset.for_create(:create, %{name: "Test"}, actor: actor)
      |> Ash.create()
    end
  end
end

# Run workflow
Reactor.run(
  MyWorkflow,
  %{data: data, actor: actor},  # ✅ Actor in inputs
  %{actor: actor}                # ✅ Actor in context
)
```

**See**:

- [examples/reactor-workflows.ex](../examples/reactor-workflows.ex#L65-L99) for
  workflow patterns
- [examples/actor-context.ex](../examples/actor-context.ex#L161-L187) for
  conceptual example
- [DESIGN/architecture/reactor-patterns.md](../../../../DESIGN/architecture/reactor-patterns.md)
  for workflow architecture

### In Background Jobs (Oban)

Reconstruct actor from user_id in job args:

```elixir
defmodule MyWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # ✅ Rebuild actor from user_id
    user = Accounts.User.get!(args["user_id"])

    actor = %{
      id: user.id,
      organization_id: user.organization_id,
      role: user.role,
      permissions: user.permissions || []
    }

    # Use actor in operations
    process_resource(args["resource_id"], actor)
  end
end

# Enqueue with user_id (not full actor)
%{
  "user_id" => user.id,
  "resource_id" => resource.id
}
|> MyWorker.new()
|> Oban.insert()
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L199-L223) for
Oban patterns

### In LiveView

Store actor in socket assigns at mount:

```elixir
def mount(_params, %{"user_id" => user_id}, socket) do
  user = Accounts.User.get!(user_id)
  actor = build_actor_from_user(user)

  {:ok, assign(socket, :actor, actor)}
end

def handle_event("create", params, socket) do
  # ✅ Use actor from socket assigns
  actor = socket.assigns.actor

  case MyResource
    |> Ash.Changeset.for_create(:create, params, actor: actor)
    |> Ash.create() do
    {:ok, resource} -> {:noreply, socket}
    {:error, error} -> {:noreply, put_flash(socket, :error, "Failed")}
  end
end
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L235-L265) for
LiveView example

## Common Pitfalls

### Pitfall #1: Forgetting Actor in Nested Operations

❌ **Problem**: Creating related resources without passing actor

```elixir
def create_with_related(attrs, actor) do
  with {:ok, parent} <- create_parent(attrs, actor) do
    # ❌ Forgot to pass actor to child!
    create_child(%{parent_id: parent.id})
  end
end
```

✅ **Solution**: Always pass actor through

```elixir
def create_with_related(attrs, actor) do
  with {:ok, parent} <- create_parent(attrs, actor) do
    # ✅ Actor passed to child operation
    create_child(%{parent_id: parent.id}, actor)
  end
end
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L461-L490) for
more pitfalls

### Pitfall #2: Accessing Actor from Changeset (Wrong!)

❌ **Problem**: Trying to get actor from changeset in after_action

```elixir
change after_action(fn changeset, resource, context ->
  # ❌ Actor is NOT in changeset!
  actor = changeset.context[:actor]  # Wrong!
end)
```

✅ **Solution**: Access from context parameter

```elixir
change after_action(fn changeset, resource, context ->
  # ✅ Actor is in context parameter
  actor = Map.get(context, :actor)
end)
```

**See**: [examples/actor-context.ex](../examples/actor-context.ex#L151-L159) for
correct pattern

### Pitfall #3: Using authorize?: false in Production

❌ **FORBIDDEN**: Bypassing authorization in business logic

```elixir
# ❌ NEVER DO THIS IN PRODUCTION!
Resource
|> Ash.Changeset.for_create(:create, attrs)
|> Ash.create(authorize?: false)
```

✅ **Solution**: Always pass actor

```elixir
# ✅ ALWAYS pass actor in production
Resource
|> Ash.Changeset.for_create(:create, attrs, actor: actor)
|> Ash.create()
```

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L60-L70) for
  comparison
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#authorization-bypass-guidelines)
  for bypass guidelines

## Testing with Actors

### Setup vs Test Operations

**Setup**: Use `authorize?: false` for creating test data

```elixir
def create_test_organization do
  Organization
  |> Ash.Changeset.for_create(:create, %{name: "Test Org"})
  |> Ash.create!(authorize?: false)  # ✅ OK for test setup
end
```

**Tests**: Always use proper actor to verify authorization

```elixir
test "user can create resource in their organization" do
  org = create_test_organization()
  user = create_test_user(org, %{role: :editor})

  # Build actor for test
  actor = %{
    id: user.id,
    organization_id: org.id,
    role: :editor,
    permissions: []
  }

  # ✅ Test with actor to verify authorization
  assert {:ok, resource} =
    MyResource
    |> Ash.Changeset.for_create(:create, %{name: "Test"}, actor: actor)
    |> Ash.create()

  assert resource.organization_id == org.id
end
```

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L279-L353) for
  complete test examples
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#policy-testing)
  for testing patterns

## System Actor (Special Case)

System actor is for authentication bootstrap ONLY:

```elixir
import MyApp.Auth.SystemActor

# ✅ CORRECT: Loading user during authentication
User |> Ash.get(user_id, actor: system_actor(), action: :load_for_authentication)

# ✅ CORRECT: Creating organization during registration
Organization
|> Ash.Changeset.for_create(:bootstrap_create, attrs)
|> Ash.create(actor: system_actor())
```

❌ **FORBIDDEN**: Using system actor for business logic

```elixir
# ❌ NEVER use system actor for regular operations!
Connection
|> Ash.Changeset.for_create(:create, attrs, actor: system_actor())
|> Ash.create()
```

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L270-L289) for system
  actor examples
- [DESIGN/reference/system_actor.md](../../../../DESIGN/reference/system_actor.md)
  for architecture
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#system-actor)
  for guidelines

## Debugging Actor Issues

### Checklist

1. **Is actor passed?** Check `actor: user` in every operation
2. **Is actor structured correctly?** Must have id, organization_id, role
3. **Does resource belong to actor's org?** Verify organization_id matches
4. **Are policies checking actor?** Review policy conditions
5. **Is actor in context?** For hooks, check `Map.get(context, :actor)`

### Common Errors

**Error**: `Ash.Error.Forbidden`

- **Cause**: Actor doesn't meet policy conditions
- **Fix**: Verify actor.role and actor.organization_id
- **See**:
  [reference/policies.md](./policies.md#debugging-authorization-failures)

**Error**: `Ash.Error.Query.NotFound`

- **Cause**: Resource doesn't exist OR cross-tenant access blocked
- **Fix**: Check if resource exists in actor's organization
- **Note**: NotFound hides existence for security

**Error**: "Actor required" in change function

- **Cause**: Context doesn't contain actor
- **Fix**: Ensure `Map.get(context, :actor)` returns value

## Related Resources

### Examples

- [examples/actor-context.ex](../examples/actor-context.ex) - Complete runnable
  examples
- [examples/reactor-workflows.ex](../examples/reactor-workflows.ex) - Actor in
  workflows
- [examples/policies.ex](../examples/policies.ex) - How policies use actor

### Reference Docs

- [reference/policies.md](./policies.md) - Authorization with actor
- [reference/resources.md](./resources.md) - Resources and actor context
- [reference/transactions.md](./transactions.md) - Actor in transactions

### Project Documentation

- [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md) -
  Complete architecture
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md) -
  Security implementation
- [.claude/context/elixir-patterns.md](../../../context/elixir-patterns.md) -
  Quick reference

### External Resources

- [Ash Policies](https://hexdocs.pm/ash/policies.html) - Official policy
  documentation
- [Ash Authorization](https://hexdocs.pm/ash/actors-and-authorization.html) -
  Actor and authorization guide

## Best Practices

1. **Build once, pass everywhere**: Create actor at entry point, pass to all
   operations
2. **Never rebuild with authorize?: false**: Reconstruct from user_id in jobs,
   not from unauthorized queries
3. **Use system actor sparingly**: Only for authentication/registration
4. **Test with actors**: Verify authorization works correctly
5. **Document actor requirements**: In custom actions and workflows
6. **Keep actor structure consistent**: Same keys throughout system

---

**Next Steps**:

- Read [policies.md](./policies.md) to understand how policies use actor
- Study [examples/actor-context.ex](../examples/actor-context.ex) for practical
  patterns
- Review
  [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md)
  for complete architecture
