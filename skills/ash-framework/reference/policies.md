# Policies Reference

**Deep dive into Ash Framework authorization policies**

Policies are the gatekeepers for all resource access. They enforce multi-tenant
isolation and role-based access control (RBAC).

## Table of Contents

- [What are Policies?](#what-are-policies)
- [Policy Structure](#policy-structure)
- [Multi-Tenant Patterns](#multi-tenant-patterns)
- [Role-Based Access Control](#role-based-access-control)
- [Common Policy Patterns](#common-policy-patterns)
- [Debugging Authorization Failures](#debugging-authorization-failures)
- [Related Resources](#related-resources)

## What are Policies?

Policies define WHO can perform WHAT operations on resources. Policies enforce:

- **Multi-tenant isolation**: Users can only access their organization's data
- **Role-based permissions**: Different roles have different capabilities
- **Custom business rules**: Ownership, approval workflows, etc.

### How Policies Work

1. User attempts operation with actor context
2. Ash checks resource policies for that action
3. Policies evaluate conditions using actor and resource data
4. If authorized, operation proceeds; if not, returns Forbidden

**See**:
[DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md)
for complete architecture

## Policy Structure

### Basic Policy Block

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end
end
```

**Components**:

- `policy` - Defines a policy block
- `action_type(:read)` - Which actions this applies to
- `authorize_if` - Condition that grants access
- `expr(...)` - Expression checked at runtime

**See**: [examples/policies.ex](../examples/policies.ex#L16-L31) for basic
examples

### Policy Logic

**Multiple policy blocks** for same action = **OR logic** (any can authorize):

```elixir
policy action_type(:read) do
  authorize_if expr(organization_id == ^actor(:organization_id))
end

policy action_type(:read) do
  authorize_if expr(id == ^actor(:id))  # OR owner
end
```

**Multiple authorize_if in one block** = **AND logic** (all must be true):

```elixir
policy action_type(:update) do
  authorize_if expr(organization_id == ^actor(:organization_id))  # AND
  authorize_if expr(^actor(:role) in [:admin, :editor])            # AND
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L526-L570) for logic
patterns

## Multi-Tenant Patterns

### Standard Multi-Tenant Policy

✅ **Correct**: Check organization membership

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  policy action_type(:create) do
    forbid_if expr(^actor(:role) not in [:admin, :editor])
    authorize_if changing_attributes(organization_id: [to: {:_actor, :organization_id}])
  end

  policy action_type(:update) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) in [:admin, :editor]
    )
  end

  policy action_type(:destroy) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) == :admin
    )
  end
end
```

**See**:

- [examples/policies.ex](../examples/policies.ex#L93-L148) for complete example
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#multi-tenancy-design)
  for architecture

### Organization Resource (Special Case)

Organization resource IS the organization, not a child:

```elixir
policies do
  # Check if actor belongs to THIS organization
  policy action_type(:read) do
    authorize_if expr(id == ^actor(:organization_id))
  end

  policy action_type(:update) do
    authorize_if expr(
      id == ^actor(:organization_id) and
      ^actor(:role) in [:admin, :editor]
    )
  end
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L582-L601) for
Organization patterns

### Nested Relationship Policies

For resources related through multiple levels, you can check authorization
through a chain of relationships:

```elixir
# Example: A deeply nested resource chain
policies do
  policy action_type(:read) do
    authorize_if relates_to_actor_via([
      :parent_resource,
      :grandparent_resource,
      :root_resource,
      :organization
    ])
  end
end
```

**IMPORTANT**: `relates_to_actor_via` only works for read/update/destroy. For
create, use `actor_present()` or `changing_attributes`.

**See**:

- [examples/policies.ex](../examples/policies.ex#L300-L331) for nested
  relationships
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#create-action-authorization-pattern)
  for create limitations

## Role-Based Access Control

### Role Hierarchy

Applications typically define role hierarchies such as:

- **Admin**: Full access within organization (create, read, update, destroy)
- **Editor**: Create and modify resources (create, read, update)
- **Viewer**: Read-only access (read)

### Role-Based Policies

```elixir
policies do
  # Read: All roles
  policy action_type(:read) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) in [:admin, :editor, :viewer]
    )
  end

  # Create/Update: Editor and Admin
  policy action_type([:create, :update]) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) in [:admin, :editor]
    )
  end

  # Destroy: Admin only
  policy action_type(:destroy) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) == :admin
    )
  end
end
```

**See**:

- [examples/policies.ex](../examples/policies.ex#L93-L148) for role patterns
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#role-based-access-control-patterns)
  for role architecture

### Ownership-Based Policies

Users can manage resources they created, admins can manage all:

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  policy action_type(:update) do
    # Owner can update
    authorize_if expr(created_by_id == ^actor(:id))
    # OR admin in organization
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) == :admin
    )
  end
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L162-L201) for ownership
patterns

## Common Policy Patterns

### Pattern #1: Self-Modification Prevention

Prevent users from deleting themselves:

```elixir
policies do
  policy action_type(:destroy) do
    forbid_if expr(id == ^actor(:id))  # ✅ Check this first
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) == :admin
    )
  end
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L218-L239) for
self-modification prevention

### Pattern #2: Action-Specific Policies

Override general policies for specific actions:

```elixir
policies do
  # General read policy
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  # Specific action for authentication
  policy action(:load_for_authentication) do
    authorize_if actor_attribute_equals(:system?, true)
  end

  # Invite action - admins only
  policy action(:invite) do
    authorize_if expr(^actor(:role) == :admin)
  end
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L203-L233) for
action-specific policies

### Pattern #3: System Actor Policies

Allow system actor for authentication bootstrap:

```elixir
policies do
  policy action_type(:read) do
    # Allow system actor for auth bootstrap
    authorize_if actor_attribute_equals(:system?, true)
    # OR normal user in organization
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  policy action(:load_for_authentication) do
    authorize_if actor_attribute_equals(:system?, true)
  end
end
```

**See**:

- [examples/policies.ex](../examples/policies.ex#L254-L283) for system actor
  policies
- [DESIGN/reference/system_actor.md](../../../../DESIGN/reference/system_actor.md)
  for system actor architecture

### Pattern #4: Authentication Bypass

Bypass policies for authentication actions:

```elixir
policies do
  # Bypass for authentication interactions
  bypass AshAuthentication.Checks.AshAuthenticationInteraction do
    authorize_if always()
  end

  # Specific authentication actions
  policy action(:register_with_password) do
    authorize_if always()
  end

  policy action(:sign_in_with_password) do
    authorize_if always()
  end

  # Normal policies for other actions
  policy action_type(:read) do
    authorize_if expr(organization_id == ^actor(:organization_id))
  end
end
```

**See**: [examples/policies.ex](../examples/policies.ex#L285-L319) for
authentication bypass

### Pattern #5: Create Action Policies

Create actions can't use relationship filters (record doesn't exist yet):

```elixir
# ❌ WRONG - Can't use relates_to_actor_via on create
policy action_type(:create) do
  authorize_if relates_to_actor_via(:organization)  # Error!
end

# ✅ CORRECT - Use actor checks or changing_attributes
policy action_type(:create) do
  forbid_if expr(^actor(:role) not in [:admin, :editor])
  authorize_if changing_attributes(organization_id: [to: {:_actor, :organization_id}])
end

# ✅ CORRECT - Simple actor check (when parent verified separately)
policy action_type(:create) do
  authorize_if actor_present()
end
```

**See**:

- [examples/policies.ex](../examples/policies.ex#L603-L635) for create patterns
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#create-action-authorization-pattern)
  for limitations

## Debugging Authorization Failures

### Steps to Debug

1. **Check actor is passed**: `actor: user` in operation
2. **Verify actor structure**: Has id, organization_id, role
3. **Check resource organization_id**: Matches actor's organization_id
4. **Review policy conditions**: All expressions evaluate correctly
5. **Test policy logic**: Isolate each condition
6. **Check action type**: Policy applies to action being called
7. **Enable policy debugging**: See evaluation breakdown

### Enable Policy Debugging

```elixir
# In config/dev.exs
config :ash, :show_policy_breakdowns?, true
```

This shows which policies were checked and why they passed/failed.

### Common Authorization Errors

**Error**: `Ash.Error.Forbidden`

**Causes**:

- User doesn't belong to resource's organization
- User lacks required role
- Policy condition not met

**Debug**:

```elixir
# Check actor
IO.inspect(actor, label: "Actor")

# Check resource
IO.inspect(resource.organization_id, label: "Resource Org")

# Verify match
actor.organization_id == resource.organization_id
```

**Error**: `Ash.Error.Query.NotFound`

**Causes**:

- Resource doesn't exist
- OR cross-tenant access blocked (converted Forbidden → NotFound for security)

**Security Note**: Your application returns NotFound instead of Forbidden for
cross-tenant access to prevent information leakage.

**See**:

- [examples/policies.ex](../examples/policies.ex#L333-L350) for NotFound
  conversion
- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#multi-tenant-security-architecture)
  for security patterns

### Testing Policies

Test authorization works correctly:

```elixir
test "user can create in their organization" do
  org = create_test_organization()
  user = create_test_user(org, %{role: :editor})
  actor = build_test_actor(user)

  assert {:ok, resource} =
    MyResource
    |> Ash.Changeset.for_create(:create, %{name: "Test"}, actor: actor)
    |> Ash.create()

  assert resource.organization_id == org.id
end

test "user cannot create in other organization" do
  org_a = create_test_organization()
  org_b = create_test_organization()
  user_a = create_test_user(org_a)
  actor_a = build_test_actor(user_a)

  # Try to create in org_b
  assert {:error, %Ash.Error.Forbidden{}} =
    MyResource
    |> Ash.Changeset.for_create(
      :create,
      %{name: "Test", organization_id: org_b.id},
      actor: actor_a
    )
    |> Ash.create()
end
```

**See**:

- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md#policy-testing)
  for testing patterns
- [.claude/context/testing-strategy.md](../../../context/testing-strategy.md)
  for overall testing strategy

## Related Resources

### Examples

- [examples/policies.ex](../examples/policies.ex) - Complete runnable policy
  examples
- [examples/actor-context.ex](../examples/actor-context.ex) - How actor works
  with policies
- [examples/resources.ex](../examples/resources.ex) - Resources with policies

### Reference Docs

- [reference/actor-context.md](./actor-context.md) - Actor context deep dive
- [reference/resources.md](./resources.md) - Resource patterns
- [reference/transactions.md](./transactions.md) - Policies in transactions

### Project Documentation

- [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md) -
  Authorization architecture
- [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md) -
  Actor concepts
- [lib/my_app/policies/base_policy.ex](../../../../lib/my_app/policies/base_policy.ex) -
  Reusable policy macros

### External Resources

- [Ash Policies](https://hexdocs.pm/ash/policies.html) - Official documentation
- [Ash Authorization](https://hexdocs.pm/ash/actors-and-authorization.html) -
  Authorization guide

## Best Practices

1. **Organization check first**: Always verify organization membership
2. **Explicit role checks**: Use `^actor(:role) in [...]` for clarity
3. **forbid_if for exclusions**: Use forbid_if to explicitly block conditions
4. **Test cross-tenant access**: Verify users can't access other organizations
5. **Return NotFound not Forbidden**: Convert Forbidden to NotFound for security
6. **Split create policies**: Create actions need different patterns than
   read/update/destroy

---

**Next Steps**:

- Read [actor-context.md](./actor-context.md) to understand actor propagation
- Study [examples/policies.ex](../examples/policies.ex) for practical patterns
- Review
  [DESIGN/security/authorization.md](../../../../DESIGN/security/authorization.md)
  for complete security architecture
