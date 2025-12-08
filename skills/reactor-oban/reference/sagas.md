# Reactor Sagas - Transactional Workflows

Comprehensive guide to building transactional saga workflows with Reactor in
your application.

## Table of Contents

- [What is a Saga?](#what-is-a-saga)
- [Compensation Patterns](#compensation-patterns)
- [Step Dependencies](#step-dependencies)
- [Error Handling](#error-handling)
- [Real-World Examples](#real-world-examples)
- [Testing Sagas](#testing-sagas)

## What is a Saga?

A **saga** is a sequence of operations where each step has a corresponding
**compensating action** to undo its effects. Reactor orchestrates this flow,
managing dependencies between steps and ensuring that if any step fails, all
preceding steps are automatically rolled back.

### Key Characteristics

1. **Atomicity**: All steps succeed or all are rolled back
2. **Compensation**: Each step can be undone via compensation function
3. **Order**: Compensation runs in REVERSE order of execution
4. **Actor Propagation**: User context flows through all steps

### When to Use Sagas

✅ **Use sagas when**:

- Operations span multiple systems (database + external services)
- You need automatic rollback on failure
- Workflow has 3+ steps with side effects
- Operations are not easily transactional (e.g., external APIs, file systems)

❌ **Don't use sagas when**:

- Single Ash resource operation (use `transaction? true` instead)
- All operations in same database (use Ecto.Multi or Ash transactions)
- Operations have no side effects (pure reads)

## Compensation Patterns

### Basic Compensation

```elixir
step :create_resource do
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    Resource
    |> Ash.Changeset.for_create(:create, arguments.data, actor: actor)
    |> Ash.create()
  end

  # Compensation receives:
  # - result: The successful result from run/2
  # - arguments: All arguments passed to the step
  # - context: Workflow context (optional)
  compensate fn resource, arguments, context ->
    actor = Map.get(context, :actor)

    resource
    |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
    |> Ash.destroy()

    :ok  # Always return :ok
  end
end
```

### Idempotent Compensation

Make compensation safe to run multiple times:

```elixir
compensate fn resource, _arguments, context ->
  actor = Map.get(context, :actor)

  # Check if resource still exists
  case Ash.get(Resource, resource.id, actor: actor) do
    {:ok, existing} ->
      # Delete if it exists
      Ash.destroy(existing, actor: actor)

    {:error, %Ash.Error.Query.NotFound{}} ->
      # Already deleted
      :ok
  end

  :ok
end
```

### Multi-System Compensation

Clean up across database and external systems:

```elixir
compensate fn _result, %{external_service: service, identifier: id}, context ->
  actor = Map.get(context, :actor)

  # Clean up external system
  ExternalService.delete_resource(service, id)

  # Clean up database (Ash resource)
  case Resource |> Ash.Query.filter(external_id: ^id) |> Ash.read_one(actor: actor) do
    {:ok, resource} ->
      Ash.destroy(resource, actor: actor)

    {:error, _} ->
      :ok
  end

  :ok
end
```

### No Compensation for Reads

Read operations don't need compensation:

```elixir
step :load_resource do
  run fn arguments, context ->
    actor = Map.get(context, :actor)
    Ash.get(Resource, arguments.id, actor: actor)
  end

  compensate fn _result, _arguments ->
    # No cleanup needed for reads
    :ok
  end
end
```

### Compensation Order

Compensations execute in **REVERSE order**:

```elixir
defmodule MyWorkflow do
  use Reactor

  step :step_1 do
    run fn -> {:ok, 1} end
    compensate fn -> IO.puts("Compensate 1"); :ok end
  end

  step :step_2 do
    run fn -> {:ok, 2} end
    compensate fn -> IO.puts("Compensate 2"); :ok end
  end

  step :step_3 do
    run fn -> {:error, "fail"} end  # Fails here
  end
end

# Execution:
# 1. step_1 runs successfully
# 2. step_2 runs successfully
# 3. step_3 fails
# 4. Compensate 2 (step_2)
# 5. Compensate 1 (step_1)
```

## Step Dependencies

### Basic Dependency

Use `result/1` to depend on previous step:

```elixir
step :load_parent do
  run fn -> load_parent() end
end

step :create_child do
  argument :parent, result(:load_parent)  # Depends on :load_parent

  run fn %{parent: parent}, context ->
    create_child(parent)
  end
end
```

### Multiple Dependencies

Steps can depend on multiple previous steps:

```elixir
step :load_user do
  run fn -> load_user() end
end

step :load_settings do
  run fn -> load_settings() end
end

step :combine do
  argument :user, result(:load_user)
  argument :settings, result(:load_settings)

  run fn %{user: user, settings: settings}, context ->
    {:ok, %{user: user, settings: settings}}
  end
end
```

### Parallel Execution

Steps without dependencies run in parallel:

```elixir
step :fetch_data_a do
  # No dependencies - runs immediately
end

step :fetch_data_b do
  # No dependencies - runs in parallel with fetch_data_a
end

step :combine_results do
  argument :data_a, result(:fetch_data_a)
  argument :data_b, result(:fetch_data_b)
  # Waits for both to complete
end
```

### Conditional Dependencies

Skip steps based on conditions:

```elixir
step :check_needs_processing do
  run fn -> {:ok, true} end
end

step :process_if_needed do
  argument :needs_processing, result(:check_needs_processing)

  run fn %{needs_processing: needs}, context ->
    if needs do
      process_data()
    else
      {:ok, :skipped}
    end
  end
end
```

## Error Handling

### Returning Errors

Return `{:error, reason}` to fail a step and trigger compensation:

```elixir
step :validate do
  run fn arguments, _context ->
    if valid?(arguments.data) do
      {:ok, arguments.data}
    else
      {:error, "Validation failed"}  # Triggers compensation
    end
  end
end
```

### Retry Logic

Use `max_retries` for transient failures:

```elixir
step :call_external_api do
  max_retries 3  # Retry up to 3 times

  run fn arguments, context ->
    attempt = Map.get(context, :attempt, 1)

    case make_api_call(arguments.endpoint) do
      {:ok, response} ->
        {:ok, response}

      {:error, :timeout} ->
        # Will retry automatically
        {:error, :timeout}

      {:error, :not_found} ->
        # Don't retry permanent errors
        {:error, :not_found}
    end
  end
end
```

### Error Propagation

Errors bubble up through the workflow:

```elixir
step :step_1 do
  run fn -> {:ok, 1} end
  compensate fn -> cleanup_1(); :ok end
end

step :step_2 do
  run fn -> {:error, "Step 2 failed"} end
  compensate fn -> cleanup_2(); :ok end
end

step :step_3 do
  # Won't execute because step_2 failed
  run fn -> {:ok, 3} end
end

# Result: {:error, "Step 2 failed"}
# Compensation: cleanup_1() runs (cleanup_2 doesn't because step didn't succeed)
```

### Exception Handling

Exceptions are caught and converted to errors:

```elixir
step :risky_operation do
  run fn arguments, _context ->
    # If this raises, Reactor catches it and returns {:error, exception}
    risky_function!(arguments.data)
  end
end
```

## Real-World Examples

### Publishing Workflow

Complete workflow for publishing draft items as versions:

**Workflow Pattern**: Multi-step publication with validation and versioning

**Steps**:

1. Load draft with dependencies
2. Validate draft status and content
3. Transform draft data to versioned format
4. Create Version record
5. Create resources in external system
6. Process and store transformed data
7. Update version with processing metadata
8. Mark version as published
9. Mark draft as archived
10. Update counters and statistics

**Key Patterns**:

- Each external operation has compensation to remove created resources
- Database resources have compensation to delete records
- Synchronous execution (`async? false`) for transactional integrity
- Actor propagation through all steps

### Upload Workflow

File upload with processing:

**Workflow Pattern**: Multi-file upload with validation and processing

**Steps**:

1. Load upload record
2. Generate unique identifier
3. Create resources in external system (compensate: delete resources)
4. Create/update Resource (compensate: delete Resource)
5. Create Version (compensate: delete version)
6. Parse and upload files in parallel
7. Update version with file metadata
8. Finalize upload status

**Key Patterns**:

- Parallel file processing with `map`
- Proper ordering: external systems first, then database
- Connection pool management
- Detailed progress broadcasting

### Processing Workflow

Automated data processing workflow:

**Workflow Pattern**: Multi-step data processing with result generation

**Steps**:

1. Mark request as processing (compensate: mark as failed)
2. Get/create process state
3. Execute processing synchronously
4. Process results
5. Assess output requirements
6. Generate output (conditional)
7. Save Result (compensate: delete result)
8. Mark request completed (compensate: mark as failed)
9. Broadcast completion

**Key Patterns**:

- Synchronous execution within workflow
- Conditional output generation
- Real-time broadcasting
- Status tracking with compensation

## Testing Sagas

### Testing Complete Workflows

```elixir
defmodule MyWorkflowTest do
  use ExUnit.Case
  import MyApp.Factory

  test "workflow completes successfully" do
    user = insert(:user)
    actor = build_actor(user)

    inputs = %{
      resource_id: resource.id,
      data: %{name: "Test"}
    }

    context = %{actor: actor}

    assert {:ok, result} = Reactor.run(MyWorkflow, inputs, context)
    assert result.resource
  end

  test "workflow compensates on failure" do
    user = insert(:user)
    actor = build_actor(user)

    # Create scenario that will fail
    inputs = %{data: invalid_data}
    context = %{actor: actor}

    assert {:error, _reason} = Reactor.run(MyWorkflow, inputs, context)

    # Verify compensation ran
    assert Ash.count!(Resource, actor: actor) == 0
  end
end
```

### Testing Individual Steps

```elixir
test "step validates data correctly" do
  # Test step logic in isolation
  valid_data = %{name: "Test"}
  assert {:ok, _} = MyWorkflow.Steps.Validate.run(valid_data, %{})

  invalid_data = %{}
  assert {:error, _} = MyWorkflow.Steps.Validate.run(invalid_data, %{})
end
```

### Testing Compensation

```elixir
test "compensation cleans up resources" do
  resource = insert(:resource)

  # Call compensation directly
  MyWorkflow.Steps.CreateResource.compensate(resource, %{}, %{actor: actor})

  # Verify cleanup
  assert {:error, %Ash.Error.Query.NotFound{}} =
    Ash.get(Resource, resource.id, actor: actor)
end
```

## Related Documentation

### Examples

- [basic-workflow.ex](../examples/basic-workflow.ex) - Simple workflow structure
- [saga-compensation.ex](../examples/saga-compensation.ex) - Compensation
  patterns
- [error-handling.ex](../examples/error-handling.ex) - Error handling strategies

### Reference

- [actor-workflows.md](actor-workflows.md) - Actor context in workflows
- [oban-patterns.md](oban-patterns.md) - Running workflows in jobs

### Design Docs

- {project_root}/DESIGN/concepts/workflows.md - Workflow fundamentals
- {project_root}/DESIGN/architecture/reactor-patterns.md - Advanced patterns

### Related Skills

- [../../ash-framework/reference/transactions.md](../../ash-framework/reference/transactions.md) -
  Ash transactions
- [../../ash-framework/reference/actor-context.md](../../ash-framework/reference/actor-context.md) -
  Actor context

### Real Implementations

- `lib/my_app/workflows/publish_workflow.ex`
- `lib/my_app/workflows/processing_workflow.ex`
- `lib/my_app/workflows/upload_workflow.ex`

## External Resources

- **Reactor Documentation**: https://hexdocs.pm/reactor/
- **Ash.Reactor**: https://hexdocs.pm/ash/reactor.html
- **Saga Pattern**: https://microservices.io/patterns/data/saga.html
