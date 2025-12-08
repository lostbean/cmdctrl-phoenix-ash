# Oban Patterns - Background Job Processing

Comprehensive guide to background job processing with Oban.

## Table of Contents

- [What is Oban?](#what-is-oban)
- [Worker Structure](#worker-structure)
- [Job Enqueueing](#job-enqueueing)
- [Error Handling](#error-handling)
- [Scheduling](#scheduling)
- [Workflow Integration](#workflow-integration)
- [Testing](#testing)

## What is Oban?

**Oban** is a robust job processing library for Elixir that uses PostgreSQL for
persistence and coordination. All time-consuming operations should run as
background jobs to keep the UI responsive.

### Key Features

1. **Persistent Queue**: Jobs survive application restarts
2. **Multiple Queues**: Priority-based processing (agents, uploads, default,
   etc.)
3. **Automatic Retries**: Exponential backoff on failures
4. **Scheduled Jobs**: Delayed and cron-based execution
5. **Uniqueness**: Prevent duplicate jobs
6. **Observability**: Telemetry events for monitoring

### When to Use Oban

✅ **Use Oban for**:

- Operations taking > 5 seconds
- Agent execution (analytics, modeling)
- File uploads and processing
- External API calls
- Connection operations
- Scheduled/recurring tasks

❌ **Don't use Oban for**:

- Synchronous operations (< 1 second)
- Real-time user interactions
- Simple CRUD operations

## Worker Structure

### Basic Worker

```elixir
defmodule MyApp.Jobs.Workers.BasicWorker do
  @moduledoc """
  Worker for processing simple background tasks.
  """

  use Oban.Worker,
    queue: :default,        # Which queue
    max_attempts: 3,        # Retry limit
    priority: 1,            # 0 (highest) to 3 (lowest)
    tags: ["processing"]    # Metadata tags

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    %{"task_id" => task_id} = args

    Logger.info("Processing task",
      task_id: task_id,
      attempt: attempt
    )

    case process_task(task_id) do
      {:ok, result} ->
        Logger.info("Task completed", task_id: task_id)
        :ok

      {:error, reason} ->
        Logger.error("Task failed", task_id: task_id, error: reason)
        {:error, reason}
    end
  end

  # Optional: Custom timeout (default 1 minute)
  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)

  defp process_task(task_id) do
    # Do work
    {:ok, "result"}
  end
end
```

### Worker with Actor

```elixir
defmodule MyApp.Jobs.Workers.ActorWorker do
  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "resource_id" => resource_id,
      "actor" => actor_with_string_keys
    } = args

    # Reconstruct actor from string keys
    actor = atomize_actor_keys(actor_with_string_keys)

    Logger.info("Processing resource",
      resource_id: resource_id,
      user_id: actor.id
    )

    with {:ok, resource} <- load_resource(resource_id, actor),
         {:ok, processed} <- process_resource(resource, actor) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp load_resource(id, actor) do
    MyResource |> Ash.get(id, actor: actor)
  end

  defp process_resource(resource, actor) do
    resource
    |> Ash.Changeset.for_update(:process, %{}, actor: actor)
    |> Ash.update()
  end

  # Convert Oban's string keys to atom keys for Ash
  defp atomize_actor_keys(actor_map) do
    %{
      id: actor_map["id"],
      organization_id: actor_map["organization_id"],
      role:
        case actor_map["role"] do
          role when is_atom(role) -> role
          role when is_binary(role) -> String.to_existing_atom(role)
        end
    }
  end
end
```

## Job Enqueueing

### Basic Enqueueing

```elixir
# Simple job
%{"task_id" => "task-123"}
|> MyWorker.new()
|> Oban.insert()

# With options
%{"task_id" => "task-456"}
|> MyWorker.new(
  queue: :high_priority,
  priority: 0,
  max_attempts: 5
)
|> Oban.insert()
```

### With Actor Context

```elixir
# Build actor from user
user = get_current_user()
actor = %{
  id: user.id,
  organization_id: user.organization_id,
  role: user.role
}

# Store actor with string keys (Oban serialization)
%{
  "resource_id" => resource.id,
  "actor" => %{
    "id" => actor.id,
    "organization_id" => actor.organization_id,
    "role" => Atom.to_string(actor.role)
  }
}
|> MyWorker.new()
|> Oban.insert()
```

### Delayed Execution

```elixir
# Run in 5 minutes
%{"task_id" => id}
|> MyWorker.new(schedule_in: 300)
|> Oban.insert()

# Run at specific time
scheduled_time = ~U[2025-01-01 00:00:00Z]

%{"task_id" => id}
|> MyWorker.new(scheduled_at: scheduled_time)
|> Oban.insert()
```

### Job Uniqueness

Prevent duplicate jobs:

```elixir
defmodule MyApp.Jobs.Workers.UniqueWorker do
  use Oban.Worker,
    queue: :default,
    unique: [
      period: 60,                                    # Seconds
      keys: [:resource_id],                          # Uniqueness keys
      states: [:available, :scheduled, :executing]   # Check these states
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    # Process
    :ok
  end
end

# First insert - creates job
%{"resource_id" => "res-123"} |> UniqueWorker.new() |> Oban.insert()

# Second insert - returns existing job (not duplicated)
%{"resource_id" => "res-123"} |> UniqueWorker.new() |> Oban.insert()
```

## Error Handling

### Return Values

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args, attempt: attempt}) do
  case process(args) do
    {:ok, _result} ->
      # ✅ Success - job completed
      :ok

    {:error, :not_found} ->
      # ❌ Permanent failure - don't retry
      {:discard, :not_found}

    {:error, :forbidden} ->
      # ❌ Permanent failure - don't retry
      {:discard, :forbidden}

    {:error, :rate_limit} ->
      # ⏸️ Postpone - retry after delay
      {:snooze, 60}  # Retry in 60 seconds

    {:error, reason} ->
      # ↩️ Transient failure - retry
      {:error, reason}
  end
end
```

### Final Attempt Handling

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args, attempt: attempt}) do
  %{"resource_id" => id, "actor" => actor_map} = args
  actor = atomize_actor_keys(actor_map)

  case process_resource(id, actor) do
    {:ok, _} ->
      :ok

    {:error, reason} ->
      # Clean up on final attempt
      if attempt >= max_attempts() do
        handle_final_failure(id, actor, reason)
      end

      {:error, reason}
  end
end

defp handle_final_failure(resource_id, actor, reason) do
  Logger.error("Final attempt failed",
    resource_id: resource_id,
    error: reason
  )

  # Mark resource as failed
  mark_resource_failed(resource_id, actor, reason)

  # Broadcast failure to UI
  Phoenix.PubSub.broadcast(
    MyApp.PubSub,
    "resource:#{resource_id}",
    {:processing_failed, %{error: format_error(reason)}}
  )
end

defp max_attempts, do: 3
```

### Exponential Backoff

Oban automatically applies exponential backoff:

- First retry: ~15 seconds
- Second retry: ~2 minutes
- Third retry: ~10 minutes
- Fourth retry: ~1 hour

## Scheduling

### Delayed Jobs

```elixir
# Relative delay (seconds)
%{"notification_id" => id}
|> NotificationWorker.new(schedule_in: 300)  # 5 minutes
|> Oban.insert()
```

### Scheduled Jobs

```elixir
# Absolute time (DateTime)
scheduled_time = ~U[2025-01-01 09:00:00Z]

%{"report_type" => "daily"}
|> ReportWorker.new(scheduled_at: scheduled_time)
|> Oban.insert()
```

### Recurring Jobs (Cron)

Configure in `config/config.exs`:

```elixir
config :my_app, Oban,
  repo: MyApp.Repo,
  queues: [
    default: 10,
    maintenance: 2
  ],
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       # Every day at 2 AM - cleanup
       {"0 2 * * *", MyApp.Jobs.Workers.DailyCleanup},

       # Every hour - sync
       {"0 * * * *", MyApp.Jobs.Workers.HourlySync},

       # Every Monday at 9 AM - report
       {"0 9 * * 1", MyApp.Jobs.Workers.WeeklyReport},

       # Every 15 minutes - health check
       {"*/15 * * * *", MyApp.Jobs.Workers.HealthCheck}
     ]}
  ]
```

Cron expression format:

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6)
│ │ │ │ │
* * * * *
```

## Workflow Integration

### Critical Pattern: Workflow Inside Job

**✅ CORRECT**: Execute workflow from worker:

```elixir
defmodule MyApp.Jobs.Workers.WorkflowWorker do
  use Oban.Worker,
    queue: :workflows,
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    %{"resource_id" => id, "actor" => actor_map} = args

    actor = atomize_actor_keys(actor_map)

    # Prepare workflow inputs and context
    inputs = %{resource_id: id}
    context = %{actor: actor, attempt: attempt}

    # Execute workflow INSIDE the job
    case Reactor.run(MyWorkflow, inputs, context) do
      {:ok, result} ->
        Logger.info("Workflow completed", resource_id: id)
        :ok

      {:error, reason} ->
        Logger.error("Workflow failed", resource_id: id, error: reason)

        # Handle final failure
        if attempt >= 3 do
          handle_final_failure(id, actor, reason)
        end

        {:error, reason}
    end
  end

  defp atomize_actor_keys(actor_map) do
    %{
      id: actor_map["id"],
      organization_id: actor_map["organization_id"],
      role: String.to_existing_atom(actor_map["role"])
    }
  end
end
```

**❌ WRONG**: Never enqueue jobs from workflow steps:

```elixir
# DON'T DO THIS
step :trigger_job do
  run fn inputs, context ->
    # WRONG - breaks compensation
    %{resource_id: inputs.id}
    |> SomeWorker.new()
    |> Oban.insert()

    {:ok, :enqueued}
  end
end
```

### Real-World Example: Worker with Workflow

```elixir
defmodule MyApp.Jobs.Workers.AnalyticsAgentWorker do
  use Oban.Worker,
    queue: :analytics_agents,
    max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    %{
      "prompt_id" => prompt_id,
      "actor" => actor_with_string_keys
    } = args

    actor = atomize_actor_keys(actor_with_string_keys)

    with {:ok, prompt} <- load_prompt(prompt_id, actor) do
      # Execute Reactor workflow
      inputs = %{prompt_id: prompt_id, prompt: prompt}
      context = %{actor: actor, attempt: attempt}

      case Reactor.run(AnalyticsWorkflow, inputs, context) do
        {:ok, _result} ->
          Logger.info("Analytics workflow completed", prompt_id: prompt_id)
          :ok

        {:error, reason} ->
          if attempt >= 2 do
            mark_prompt_failed(prompt_id, actor, reason)
            broadcast_failure(prompt_id, actor, reason)
          end

          {:error, reason}
      end
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
```

### Queue Configuration

Example queue organization:

```elixir
config :my_app, Oban,
  queues: [
    agents: 10,          # Agent processing
    analytics: 5,        # Analytics queries
    modeling: 5,         # Model editing and materialization
    uploads: 3,          # File uploads
    validations: 2,      # Validation tasks
    default: 5           # Catch-all
  ]
```

**Queue Selection**:

- `agents`: Real-time agent interactions (high priority)
- `uploads`: File processing (IO-bound, moderate concurrency)
- `validations`: Background validation (low priority)
- `default`: Miscellaneous background tasks

## Testing

### Testing Workers

```elixir
defmodule MyWorkerTest do
  use ExUnit.Case
  use Oban.Testing, repo: MyApp.Repo

  import MyApp.Factory

  test "worker processes successfully" do
    user = insert(:user)
    resource = insert(:resource, organization_id: user.organization_id)
    actor = build_actor(user)

    # Enqueue job
    assert {:ok, job} =
             %{
               "resource_id" => resource.id,
               "actor" => serialize_actor(actor)
             }
             |> MyWorker.new()
             |> Oban.insert()

    # Perform job
    assert :ok = perform_job(MyWorker, job.args)

    # Verify results
    assert_enqueued worker: MyWorker
    refute_enqueued worker: OtherWorker
  end

  test "worker handles errors" do
    # Create scenario that will fail
    args = %{"resource_id" => "nonexistent"}

    assert {:discard, :not_found} = perform_job(MyWorker, args)
  end

  defp serialize_actor(actor) do
    %{
      "id" => actor.id,
      "organization_id" => actor.organization_id,
      "role" => Atom.to_string(actor.role)
    }
  end
end
```

### Testing with Workflows

```elixir
test "worker executes workflow successfully" do
  user = insert(:user)
  actor = build_actor(user)

  args = %{
    "resource_id" => resource.id,
    "actor" => serialize_actor(actor)
  }

  # Perform job (which runs workflow)
  assert :ok = perform_job(WorkflowWorker, args)

  # Verify workflow side effects
  assert resource_was_processed?(resource.id)
end
```

### Testing Scheduled Jobs

```elixir
test "job is scheduled for correct time" do
  scheduled_time = ~U[2025-01-01 00:00:00Z]

  {:ok, job} =
    %{"task_id" => "task-123"}
    |> MyWorker.new(scheduled_at: scheduled_time)
    |> Oban.insert()

  assert job.scheduled_at == scheduled_time
  assert job.state == :scheduled
end
```

## Related Documentation

### Examples

- See skill examples directory for worker patterns
- See skill examples directory for scheduling patterns
- See skill examples directory for error handling

### Reference

- [sagas.md](sagas.md) - Reactor workflows
- [actor-workflows.md](actor-workflows.md) - Actor context

### Design Docs

- See your project's design documentation for job architecture
- See your project's design documentation for workflow patterns

### Real Implementations

- See your application's jobs directory for worker implementations

## External Resources

- **Oban Documentation**: https://hexdocs.pm/oban/
- **Oban.Worker**: https://hexdocs.pm/oban/Oban.Worker.html
- **Oban Recipes**: https://getoban.pro/recipes
