defmodule ReactorObanSkill.Examples.ObanWorker do
  @moduledoc """
  Self-contained examples of basic Oban worker patterns.

  Shows fundamentals of background job processing with Oban,
  including job configuration, execution, and error handling.

  ## Related Files
  - ../reference/oban-patterns.md - Oban deep dive
  - DESIGN/concepts/jobs.md - Background job architecture
  - lib/my_app/jobs/workers/*.ex - Real worker implementations
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Oban Worker
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Minimal Oban worker structure.

  Demonstrates:
  - use Oban.Worker directive
  - Worker configuration (queue, max_attempts)
  - perform/1 callback implementation
  - Job enqueueing
  """
  def example_basic_worker do
    quote do
      defmodule MyApp.Jobs.Workers.BasicWorker do
        @moduledoc """
        Basic background worker for processing simple tasks.
        """

        use Oban.Worker,
          queue: :default,
          max_attempts: 3

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"task_id" => task_id} = args

          Logger.info("Processing task", task_id: task_id)

          case process_task(task_id) do
            {:ok, result} ->
              Logger.info("Task completed", task_id: task_id, result: result)
              :ok

            {:error, reason} ->
              Logger.error("Task failed", task_id: task_id, error: reason)
              {:error, reason}
          end
        end

        defp process_task(task_id) do
          # Simulate work
          :timer.sleep(100)
          {:ok, "Task #{task_id} processed"}
        end
      end

      # Enqueueing a job:
      %{"task_id" => "task-123"}
      |> MyApp.Jobs.Workers.BasicWorker.new()
      |> Oban.insert()
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Worker with Timeout
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Custom timeout configuration.

  Demonstrates:
  - timeout/1 callback for custom timeouts
  - Different timeouts for different job types
  - Default 1 minute timeout override
  """
  def example_worker_timeout do
    quote do
      defmodule MyApp.Jobs.Workers.LongRunningWorker do
        @moduledoc """
        Worker for long-running operations like file processing.
        """

        use Oban.Worker,
          queue: :heavy,
          max_attempts: 2

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"file_path" => file_path} = args

          Logger.info("Processing large file", file: file_path)

          case process_large_file(file_path) do
            {:ok, result} ->
              :ok

            {:error, reason} ->
              {:error, reason}
          end
        end

        # ✅ Set timeout to 30 minutes (default is 1 minute)
        @impl Oban.Worker
        def timeout(_job), do: :timer.minutes(30)

        defp process_large_file(file_path) do
          # Long-running operation
          {:ok, "processed"}
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Worker with Actor Context
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Worker that rebuilds actor from job args.

  Demonstrates:
  - Storing actor in job args
  - Reconstructing actor for Ash operations
  - Using actor for authorization
  """
  def example_worker_with_actor do
    quote do
      defmodule MyApp.Jobs.Workers.ActorWorker do
        @moduledoc """
        Worker that processes resources with actor context.
        """

        use Oban.Worker,
          queue: :default,
          max_attempts: 3

        require Logger

        alias MyApp.Resource

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{
            "resource_id" => resource_id,
            "actor" => actor_with_string_keys
          } = args

          # ✅ Reconstruct actor from string keys
          actor = atomize_actor_keys(actor_with_string_keys)

          Logger.info("Processing resource",
            resource_id: resource_id,
            user_id: actor.id
          )

          with {:ok, resource} <- load_resource(resource_id, actor),
               {:ok, processed} <- process_resource(resource, actor) do
            Logger.info("Resource processed successfully", resource_id: resource_id)
            :ok
          else
            {:error, reason} ->
              Logger.error("Resource processing failed",
                resource_id: resource_id,
                error: reason
              )

              {:error, reason}
          end
        end

        defp load_resource(resource_id, actor) do
          Resource
          |> Ash.get(resource_id, actor: actor)
        end

        defp process_resource(resource, actor) do
          resource
          |> Ash.Changeset.for_update(:process, %{status: :processed}, actor: actor)
          |> Ash.update()
        end

        # ✅ Convert string keys to atom keys
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

      # Enqueueing with actor:
      user = get_current_user()
      actor = build_actor(user)

      %{
        "resource_id" => resource.id,
        "actor" => %{
          "id" => actor.id,
          "organization_id" => actor.organization_id,
          "role" => Atom.to_string(actor.role)
        }
      }
      |> MyApp.Jobs.Workers.ActorWorker.new()
      |> Oban.insert()
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Worker Running Reactor Workflow
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Worker that executes a Reactor workflow.

  This is the FUNDAMENTAL pattern in your application:
  - Oban worker manages job lifecycle
  - Reactor workflow handles business logic
  - Actor flows from job args → workflow context
  """
  def example_worker_with_workflow do
    quote do
      defmodule MyApp.Jobs.Workers.WorkflowWorker do
        @moduledoc """
        Worker that orchestrates a Reactor workflow.

        This demonstrates the core pattern:
        - Worker: Job lifecycle, retry logic, progress tracking
        - Workflow: Business logic, compensation, step dependencies
        """

        use Oban.Worker,
          queue: :workflows,
          max_attempts: 3

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          %{
            "resource_id" => resource_id,
            "actor" => actor_with_string_keys
          } = args

          # ✅ Reconstruct actor
          actor = atomize_actor_keys(actor_with_string_keys)

          Logger.info("Starting workflow",
            resource_id: resource_id,
            user_id: actor.id,
            attempt: attempt
          )

          # ✅ Prepare workflow inputs and context
          inputs = %{resource_id: resource_id}

          context = %{
            actor: actor,
            attempt: attempt
          }

          # ✅ Execute workflow INSIDE the job
          case Reactor.run(MyApp.ProcessingWorkflow, inputs, context) do
            {:ok, result} ->
              Logger.info("Workflow completed successfully",
                resource_id: resource_id,
                result_keys: Map.keys(result)
              )

              broadcast_success(resource_id, result)
              :ok

            {:error, reason} ->
              Logger.error("Workflow failed",
                resource_id: resource_id,
                attempt: attempt,
                error: reason
              )

              # Mark as failed on final attempt
              if attempt >= 3 do
                mark_resource_failed(resource_id, actor, reason)
                broadcast_failure(resource_id, reason)
              end

              {:error, reason}
          end
        end

        @impl Oban.Worker
        def timeout(_job), do: :timer.minutes(5)

        defp atomize_actor_keys(actor_map) do
          %{
            id: actor_map["id"],
            organization_id: actor_map["organization_id"],
            role: String.to_existing_atom(actor_map["role"])
          }
        end

        defp broadcast_success(resource_id, result) do
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "resource:#{resource_id}",
            {:workflow_completed, %{resource_id: resource_id, result: result}}
          )
        end

        defp broadcast_failure(resource_id, reason) do
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "resource:#{resource_id}",
            {:workflow_failed, %{resource_id: resource_id, error: format_error(reason)}}
          )
        end

        defp mark_resource_failed(resource_id, actor, reason) do
          case MyApp.Resource |> Ash.get(resource_id, actor: actor) do
            {:ok, resource} ->
              resource
              |> Ash.Changeset.for_update(
                :mark_failed,
                %{error_message: format_error(reason)},
                actor: actor
              )
              |> Ash.update()

            {:error, _} ->
              :ok
          end
        end

        defp format_error(reason) when is_binary(reason), do: reason
        defp format_error(reason), do: inspect(reason)
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Error Handling in Workers
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Different error handling strategies.

  Demonstrates:
  - Permanent failures (don't retry)
  - Transient failures (retry)
  - Snoozing (postpone)
  - Cancellation
  """
  def example_error_handling do
    quote do
      defmodule MyApp.Jobs.Workers.ErrorHandlingWorker do
        @moduledoc """
        Worker demonstrating different error handling strategies.
        """

        use Oban.Worker,
          queue: :default,
          max_attempts: 5

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          %{"operation" => operation, "resource_id" => id} = args

          Logger.info("Processing operation",
            operation: operation,
            resource_id: id,
            attempt: attempt
          )

          case execute_operation(operation, id) do
            {:ok, result} ->
              # ✅ Success
              Logger.info("Operation succeeded", operation: operation)
              :ok

            {:error, :not_found} ->
              # ❌ Permanent failure - don't retry
              Logger.error("Resource not found, not retrying", resource_id: id)
              {:discard, :not_found}

            {:error, :forbidden} ->
              # ❌ Permanent failure - authorization won't change
              Logger.error("Access forbidden, not retrying", resource_id: id)
              {:discard, :forbidden}

            {:error, :rate_limit} ->
              # ⏸️ Transient - snooze and retry later
              Logger.warning("Rate limited, snoozing for 60 seconds")
              {:snooze, 60}

            {:error, :resource_locked} ->
              # ⏸️ Wait for lock to be released
              Logger.warning("Resource locked, snoozing for 30 seconds")
              {:snooze, 30}

            {:error, :database_timeout} ->
              # ↩️ Retry (will use max_attempts)
              Logger.error("Database timeout, will retry",
                attempt: attempt,
                max_attempts: 5
              )

              {:error, :database_timeout}

            {:error, reason} ->
              # ↩️ Retry other errors
              Logger.error("Operation failed, will retry",
                error: reason,
                attempt: attempt
              )

              {:error, reason}
          end
        end

        defp execute_operation(operation, id) do
          # Simulate different error scenarios
          case operation do
            "success" -> {:ok, "completed"}
            "not_found" -> {:error, :not_found}
            "forbidden" -> {:error, :forbidden}
            "rate_limit" -> {:error, :rate_limit}
            "locked" -> {:error, :resource_locked}
            "timeout" -> {:error, :database_timeout}
            _ -> {:error, :unknown_operation}
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Worker with Progress Broadcasting
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Broadcasting progress updates during job execution.

  Demonstrates:
  - Real-time progress via PubSub
  - Multi-phase operations
  - User-facing status updates
  """
  def example_progress_broadcasting do
    quote do
      defmodule MyApp.Jobs.Workers.ProgressWorker do
        @moduledoc """
        Worker that broadcasts progress updates for long-running operations.
        """

        use Oban.Worker,
          queue: :heavy,
          max_attempts: 2

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          %{"upload_id" => upload_id, "file_path" => file_path} = args

          Logger.info("Starting upload processing", upload_id: upload_id)

          with :ok <- broadcast_progress(upload_id, "Validating file", 10),
               {:ok, _} <- validate_file(file_path),
               :ok <- broadcast_progress(upload_id, "Parsing data", 30),
               {:ok, data} <- parse_file(file_path),
               :ok <- broadcast_progress(upload_id, "Creating tables", 50),
               {:ok, _} <- create_tables(data),
               :ok <- broadcast_progress(upload_id, "Uploading data", 70),
               {:ok, _} <- upload_data(data),
               :ok <- broadcast_progress(upload_id, "Finalizing", 90),
               {:ok, result} <- finalize_upload(upload_id),
               :ok <- broadcast_progress(upload_id, "Completed", 100) do
            Logger.info("Upload processing completed", upload_id: upload_id)
            :ok
          else
            {:error, reason} ->
              broadcast_error(upload_id, reason)
              {:error, reason}
          end
        end

        @impl Oban.Worker
        def timeout(_job), do: :timer.minutes(10)

        defp broadcast_progress(upload_id, phase, percent) do
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "upload:#{upload_id}",
            {:upload_progress,
             %{
               upload_id: upload_id,
               phase: phase,
               percent: percent,
               timestamp: DateTime.utc_now()
             }}
          )

          Logger.debug("Progress update",
            upload_id: upload_id,
            phase: phase,
            percent: percent
          )

          :ok
        end

        defp broadcast_error(upload_id, reason) do
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "upload:#{upload_id}",
            {:upload_failed,
             %{
               upload_id: upload_id,
               error: format_error(reason),
               failed_at: DateTime.utc_now()
             }}
          )
        end

        defp validate_file(file_path), do: {:ok, :valid}
        defp parse_file(file_path), do: {:ok, %{rows: 100}}
        defp create_tables(data), do: {:ok, :created}
        defp upload_data(data), do: {:ok, :uploaded}
        defp finalize_upload(upload_id), do: {:ok, :finalized}

        defp format_error(reason) when is_binary(reason), do: reason
        defp format_error(reason), do: inspect(reason)
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Oban Worker Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Oban Worker Best Practices

  ### 1. Worker Configuration

  ```elixir
  use Oban.Worker,
    queue: :queue_name,   # Which queue to use
    max_attempts: 3,      # How many retries
    priority: 1,          # 0 (highest) to 3 (lowest)
    tags: ["type"],       # Metadata tags
    unique: [             # Uniqueness constraints
      period: 60,
      keys: [:resource_id]
    ]
  ```

  ### 2. Job Enqueueing

  ✅ Basic:
  ```elixir
  %{"task_id" => id}
  |> MyWorker.new()
  |> Oban.insert()
  ```

  ✅ With scheduling:
  ```elixir
  %{"task_id" => id}
  |> MyWorker.new(scheduled_at: ~U[2025-01-01 00:00:00Z])
  |> Oban.insert()
  ```

  ✅ With delay:
  ```elixir
  %{"task_id" => id}
  |> MyWorker.new(schedule_in: 300)  # 5 minutes
  |> Oban.insert()
  ```

  ### 3. Error Return Values

  ✅ Success:
  ```elixir
  :ok
  ```

  ✅ Retry (uses max_attempts):
  ```elixir
  {:error, reason}
  ```

  ✅ Permanent failure (no retry):
  ```elixir
  {:discard, reason}
  ```

  ✅ Postpone (retry later):
  ```elixir
  {:snooze, seconds}
  ```

  ✅ Cancel:
  ```elixir
  {:cancel, reason}
  ```

  ### 4. Actor Reconstruction

  ✅ Store with string keys:
  ```elixir
  %{
    "actor" => %{
      "id" => actor.id,
      "organization_id" => actor.organization_id,
      "role" => Atom.to_string(actor.role)
    }
  }
  ```

  ✅ Reconstruct with atom keys:
  ```elixir
  actor = %{
    id: args["actor"]["id"],
    organization_id: args["actor"]["organization_id"],
    role: String.to_existing_atom(args["actor"]["role"])
  }
  ```

  ### 5. Workflow Integration

  ✅ ALWAYS run workflows inside jobs:
  ```elixir
  def perform(%Oban.Job{args: args}) do
    inputs = %{resource_id: args["resource_id"]}
    context = %{actor: build_actor(args)}

    Reactor.run(MyWorkflow, inputs, context)
  end
  ```

  ❌ NEVER enqueue jobs from workflows:
  ```elixir
  # DON'T DO THIS
  step :trigger_job do
    run fn -> Oban.insert(SomeWorker.new(%{})) end
  end
  ```
  """
end
