# Actor Context in Reactor Workflows

Comprehensive guide to actor context propagation in Reactor workflows for
multi-tenant authorization and audit trails.

## Table of Contents

- [What is Actor Context?](#what-is-actor-context)
- [Actor in Workflows](#actor-in-workflows)
- [Actor in Compensation](#actor-in-compensation)
- [Actor from Oban Jobs](#actor-from-oban-jobs)
- [Multi-Tenant Isolation](#multi-tenant-isolation)
- [Common Pitfalls](#common-pitfalls)

## What is Actor Context?

**Actor context** represents the authenticated user performing an operation.
Actor context is CRITICAL for:

1. **Multi-tenant isolation**: Users can only access their organization's data
2. **Role-based authorization**: Admin, editor, viewer permissions
3. **Audit trails**: Track who performed each operation
4. **Security**: Prevent cross-tenant data leakage

### Actor Structure

```elixir
actor = %{
  id: user.id,                          # User UUID
  organization_id: user.organization_id, # Tenant UUID
  role: :admin | :editor | :viewer      # Role atom
}
```

## Actor in Workflows

### Basic Pattern: Actor in Context

**CRITICAL**: Actor must be in workflow **context** (not just inputs):

```elixir
defmodule MyApp.ActorWorkflow do
  use Reactor

  alias MyApp.Resource

  input :resource_id
  # ✅ Actor can optionally be in inputs
  input :actor

  step :load_resource do
    argument :resource_id, input(:resource_id)

    run fn %{resource_id: id}, context ->
      # ✅ ALWAYS get actor from context
      actor = Map.get(context, :actor)

      # Use actor for Ash operation
      Resource |> Ash.get(id, actor: actor)
    end
  end

  step :update_resource do
    argument :resource, result(:load_resource)

    run fn %{resource: resource}, context ->
      # ✅ Get actor from context
      actor = Map.get(context, :actor)

      resource
      |> Ash.Changeset.for_update(:update, %{status: :processed}, actor: actor)
      |> Ash.update()
    end
  end
end

# Running workflow:
user = get_current_user()
actor = build_actor(user)

inputs = %{
  resource_id: "abc-123",
  actor: actor  # Optional in inputs
}

context = %{
  actor: actor  # REQUIRED in context
}

{:ok, result} = Reactor.run(MyApp.ActorWorkflow, inputs, context)
```

### Why Context Not Inputs?

✅ **Context** (recommended):

- Available to ALL steps without explicit arguments
- Conventional pattern in Reactor
- Easier to add new steps that need actor

❌ **Inputs** (not recommended):

- Must explicitly pass as argument to each step
- Verbose and repetitive
- Easy to forget in new steps

### Accessing Actor in Steps

```elixir
step :perform_action do
  # Arguments from previous steps or inputs
  argument :resource, result(:load_resource)

  run fn arguments, context ->
    # ✅ Access actor from context
    actor = Map.get(context, :actor)

    Logger.info("Performing action",
      user_id: actor.id,
      organization_id: actor.organization_id,
      role: actor.role
    )

    # Use actor in Ash operations
    Resource
    |> Ash.Changeset.for_create(:create, data, actor: actor)
    |> Ash.create()
  end
end
```

### Default Actor Value

Provide default when actor might be missing:

```elixir
run fn arguments, context ->
  # ✅ With default (nil)
  actor = Map.get(context, :actor)

  if actor do
    perform_with_actor(actor)
  else
    {:error, "Actor required"}
  end
end
```

## Actor in Compensation

Compensation functions receive context as third argument:

```elixir
step :create_resource do
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    Resource
    |> Ash.Changeset.for_create(:create, arguments.data, actor: actor)
    |> Ash.create()
  end

  # ✅ Actor available in compensation
  compensate fn resource, _arguments, context ->
    # Get actor from context for rollback
    actor = Map.get(context, :actor)

    Logger.warning("Rolling back resource creation",
      resource_id: resource.id,
      user_id: actor.id
    )

    resource
    |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
    |> Ash.destroy()

    :ok
  end
end
```

### Compensation Without Actor

Some compensation doesn't need actor (external systems):

```elixir
step :create_external_namespace do
  run fn arguments, context ->
    actor = Map.get(context, :actor)
    connection = load_connection(arguments.connection_id, actor)

    # External operation (no actor needed)
    Connection.create_namespace(connection, arguments.namespace)
  end

  compensate fn namespace, %{connection: connection}, _context ->
    # No actor needed for external cleanup
    Connection.drop_namespace(connection, namespace)
    :ok
  end
end
```

## Actor from Oban Jobs

### Storing Actor in Job Args

Oban serializes job args as JSON, so store actor with **string keys**:

```elixir
# Building actor from user
user = get_current_user()

actor = %{
  id: user.id,
  organization_id: user.organization_id,
  role: user.role
}

# ✅ Serialize actor for Oban (string keys)
job_args = %{
  "resource_id" => resource.id,
  "actor" => %{
    "id" => actor.id,
    "organization_id" => actor.organization_id,
    "role" => Atom.to_string(actor.role)  # Convert atom to string
  }
}

job_args
|> MyWorker.new()
|> Oban.insert()
```

### Reconstructing Actor in Worker

Convert string keys back to atom keys for Ash:

```elixir
defmodule MyApp.Jobs.Workers.MyWorker do
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    %{
      "resource_id" => resource_id,
      "actor" => actor_with_string_keys
    } = args

    # ✅ Reconstruct actor with atom keys
    actor = atomize_actor_keys(actor_with_string_keys)

    # Pass to workflow
    inputs = %{resource_id: resource_id}
    context = %{actor: actor, attempt: attempt}

    Reactor.run(MyWorkflow, inputs, context)
  end

  # ✅ Helper to convert keys
  defp atomize_actor_keys(actor_map) do
    %{
      id: actor_map["id"] || actor_map[:id],
      organization_id: actor_map["organization_id"] || actor_map[:organization_id],
      role:
        case actor_map["role"] || actor_map[:role] do
          role when is_atom(role) -> role
          role when is_binary(role) -> String.to_existing_atom(role)
        end
    }
  end
end
```

### Complete Pattern: User → Actor → Job → Workflow

```elixir
# 1. Build actor from user (Phoenix controller or LiveView)
defmodule MyAppWeb.ResourceController do
  def create(conn, params) do
    user = conn.assigns.current_user

    # Build actor
    actor = %{
      id: user.id,
      organization_id: user.organization_id,
      role: user.role
    }

    # 2. Enqueue job with actor
    {:ok, _job} =
      %{
        "resource_id" => params["resource_id"],
        "actor" => %{
          "id" => actor.id,
          "organization_id" => actor.organization_id,
          "role" => Atom.to_string(actor.role)
        }
      }
      |> MyApp.Jobs.Workers.ProcessResourceWorker.new()
      |> Oban.insert()

    json(conn, %{status: "processing"})
  end
end

# 3. Worker reconstructs actor and passes to workflow
defmodule MyApp.Jobs.Workers.ProcessResourceWorker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    actor = atomize_actor_keys(args["actor"])

    # 4. Pass actor in workflow context
    inputs = %{resource_id: args["resource_id"]}
    context = %{actor: actor}

    Reactor.run(MyApp.ProcessingWorkflow, inputs, context)
  end

  defp atomize_actor_keys(actor_map) do
    %{
      id: actor_map["id"],
      organization_id: actor_map["organization_id"],
      role: String.to_existing_atom(actor_map["role"])
    }
  end
end

# 5. Workflow uses actor for all Ash operations
defmodule MyApp.ProcessingWorkflow do
  use Reactor

  step :load_resource do
    run fn arguments, context ->
      actor = Map.get(context, :actor)
      # Actor enforces multi-tenant isolation
      MyResource |> Ash.get(arguments.resource_id, actor: actor)
    end
  end
end
```

## Multi-Tenant Isolation

### How Actor Enforces Isolation

Actor context automatically enforces organization boundaries:

```elixir
# Resource policy (in Ash resource)
policies do
  policy action_type(:read) do
    # ✅ Only allow access to same organization
    authorize_if expr(organization_id == ^actor(:organization_id))
  end

  policy action_type([:create, :update]) do
    authorize_if expr(organization_id == ^actor(:organization_id))
    authorize_if actor_attribute_equals(:role, :admin)
  end
end

# Workflow automatically enforces via actor
step :load_resource do
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    # This query is AUTOMATICALLY scoped to actor's organization
    # Users can ONLY see resources in their organization
    Resource |> Ash.get(arguments.id, actor: actor)
  end
end
```

### Cross-Organization Access Prevention

```elixir
# User A (organization: "org-1")
actor_a = %{
  id: "user-a",
  organization_id: "org-1",
  role: :admin
}

# Resource belongs to organization "org-2"
resource = %Resource{
  id: "res-123",
  organization_id: "org-2"
}

# Attempt to access
case Resource |> Ash.get(resource.id, actor: actor_a) do
  {:ok, _} ->
    # Will NOT reach here
    :ok

  {:error, %Ash.Error.Query.NotFound{}} ->
    # ✅ Returns NotFound (not Forbidden)
    # This prevents leaking information about resource existence
    :not_found
end
```

### Role-Based Authorization

```elixir
step :perform_admin_action do
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    # ✅ Check role for sensitive operations
    if actor.role in [:admin] do
      perform_admin_operation(arguments, actor)
    else
      {:error, "Admin access required"}
    end
  end
end
```

## Common Pitfalls

### ❌ Forgetting Actor in Context

```elixir
# WRONG - actor not in context
inputs = %{resource_id: id}
context = %{}  # Missing actor!

Reactor.run(MyWorkflow, inputs, context)

# Workflow will crash when trying to access actor
```

**Fix**: Always include actor in context:

```elixir
# ✅ CORRECT
context = %{actor: actor}
Reactor.run(MyWorkflow, inputs, context)
```

### ❌ Using authorize?: false

```elixir
# WRONG - bypassing authorization
step :create_resource do
  run fn arguments, _context ->
    Resource
    |> Ash.Changeset.for_create(:create, arguments.data)
    |> Ash.create(authorize?: false)  # NEVER DO THIS
  end
end
```

**Fix**: Always pass actor:

```elixir
# ✅ CORRECT
step :create_resource do
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    Resource
    |> Ash.Changeset.for_create(:create, arguments.data, actor: actor)
    |> Ash.create()
  end
end
```

### ❌ Direct Context Access

```elixir
# WRONG - will crash if actor missing
run fn arguments, context ->
  actor = context.actor  # Crashes if key doesn't exist
end
```

**Fix**: Use Map.get/2:

```elixir
# ✅ CORRECT
run fn arguments, context ->
  actor = Map.get(context, :actor)  # Returns nil if missing

  if actor do
    perform_action(actor)
  else
    {:error, "Actor required"}
  end
end
```

### ❌ Not Converting Actor Keys

```elixir
# WRONG - using string keys for Ash
actor = %{
  "id" => user_id,
  "organization_id" => org_id,
  "role" => "admin"
}

Resource |> Ash.get(id, actor: actor)  # May not work correctly
```

**Fix**: Always use atom keys:

```elixir
# ✅ CORRECT
actor = %{
  id: user_id,
  organization_id: org_id,
  role: :admin  # Atom, not string
}

Resource |> Ash.get(id, actor: actor)
```

### ❌ Leaking Organization Existence

```elixir
# WRONG - reveals if resource exists in other org
case Resource |> Ash.get(id, actor: actor) do
  {:error, %Ash.Error.Forbidden{}} ->
    {:error, "Access forbidden"}  # Leaks existence!
end
```

**Fix**: Ash automatically returns NotFound:

```elixir
# ✅ CORRECT - Ash handles this
case Resource |> Ash.get(id, actor: actor) do
  {:ok, resource} -> {:ok, resource}
  {:error, %Ash.Error.Query.NotFound{}} -> {:error, "Not found"}
end
```

## Testing with Actor

### Creating Test Actors

```elixir
defmodule MyApp.Factory do
  def build_actor(user) do
    %{
      id: user.id,
      organization_id: user.organization_id,
      role: user.role
    }
  end

  def build_admin_actor(user) do
    %{
      id: user.id,
      organization_id: user.organization_id,
      role: :admin
    }
  end
end
```

### Testing Multi-Tenancy

```elixir
test "users can only access their organization's resources" do
  org_1 = insert(:organization)
  org_2 = insert(:organization)

  user_1 = insert(:user, organization_id: org_1.id)
  user_2 = insert(:user, organization_id: org_2.id)

  resource = insert(:resource, organization_id: org_1.id)

  actor_1 = build_actor(user_1)
  actor_2 = build_actor(user_2)

  # ✅ User 1 can access (same org)
  assert {:ok, _} = Resource |> Ash.get(resource.id, actor: actor_1)

  # ❌ User 2 cannot access (different org)
  assert {:error, %Ash.Error.Query.NotFound{}} =
    Resource |> Ash.get(resource.id, actor: actor_2)
end
```

### Testing Workflows with Actor

```elixir
test "workflow enforces actor authorization" do
  user = insert(:user)
  actor = build_actor(user)
  resource = insert(:resource, organization_id: user.organization_id)

  inputs = %{resource_id: resource.id}
  context = %{actor: actor}

  assert {:ok, result} = Reactor.run(MyWorkflow, inputs, context)
  assert result.resource.id == resource.id
end

test "workflow fails with wrong organization" do
  user = insert(:user)
  other_org = insert(:organization)
  actor = build_actor(user)

  # Resource in different org
  resource = insert(:resource, organization_id: other_org.id)

  inputs = %{resource_id: resource.id}
  context = %{actor: actor}

  # Should fail due to authorization
  assert {:error, _} = Reactor.run(MyWorkflow, inputs, context)
end
```

## Related Documentation

### Examples

- See skill examples directory for actor propagation patterns
- See skill examples directory for workflow basics
- See skill examples directory for actor in jobs

### Reference

- [sagas.md](sagas.md) - Saga workflows
- [oban-patterns.md](oban-patterns.md) - Job processing

### Related Skills

- See ash-framework skill for actor context in Ash
- See ash-framework skill for authorization policies

### Design Docs

- See your project's design documentation for actor architecture
- See your project's design documentation for security patterns

### Real Implementations

- See your application's workflows and workers for examples

## External Resources

- **Ash Authorization**: https://hexdocs.pm/ash/policies.html
- **Reactor Context**: https://hexdocs.pm/reactor/Reactor.html#module-context
