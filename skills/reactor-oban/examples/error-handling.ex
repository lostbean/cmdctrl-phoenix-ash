defmodule ReactorObanSkill.Examples.ErrorHandling do
  @moduledoc """
  Self-contained examples of error handling in Reactor workflows and Oban jobs.

  Shows patterns for graceful failure handling, retry logic, compensation
  execution, and error reporting.

  ## Related Files
  - ../reference/sagas.md - Saga error handling
  - ../reference/oban-patterns.md - Job error handling
  - DESIGN/architecture/reactor-patterns.md - Workflow patterns
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Workflow Error Handling
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Returning errors from workflow steps.

  Demonstrates:
  - {:error, reason} return value
  - Automatic compensation on failure
  - Error propagation
  """
  def example_basic_error_handling do
    quote do
      defmodule MyApp.BasicErrorWorkflow do
        use Reactor
        require Logger

        input :data

        step :validate do
          argument :data, input(:data)

          run fn %{data: data}, _context ->
            if valid?(data) do
              {:ok, data}
            else
              # ✅ Return error to fail step
              {:error, "Validation failed: invalid data format"}
            end
          end
        end

        step :process do
          argument :validated, result(:validate)

          run fn %{validated: data}, _context ->
            case process_data(data) do
              {:ok, result} ->
                {:ok, result}

              {:error, reason} ->
                # ✅ Error triggers compensation
                Logger.error("Processing failed", error: reason)
                {:error, reason}
            end
          end

          compensate fn _result, _arguments ->
            Logger.warning("Compensating process step")
            :ok
          end
        end

        defp valid?(data), do: is_map(data) and map_size(data) > 0
        defp process_data(data), do: {:ok, data}
      end

      # Running workflow with error:
      case Reactor.run(MyApp.BasicErrorWorkflow, %{data: %{}}, %{}) do
        {:ok, result} ->
          Logger.info("Success")

        {:error, reason} ->
          # Compensation ran automatically
          Logger.error("Workflow failed: #{inspect(reason)}")
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Step Retry Logic
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Automatic retries for transient failures.

  Demonstrates:
  - max_retries option
  - Retry behavior
  - Distinguishing permanent vs transient errors
  """
  def example_step_retry do
    quote do
      defmodule MyApp.RetryWorkflow do
        use Reactor
        require Logger

        input :api_endpoint

        step :call_api do
          argument :endpoint, input(:api_endpoint)

          # ✅ Retry up to 3 times
          max_retries 3

          run fn %{endpoint: endpoint}, context ->
            attempt = Map.get(context, :attempt, 1)

            Logger.info("API call attempt #{attempt}")

            case make_api_call(endpoint) do
              {:ok, response} ->
                {:ok, response}

              {:error, :timeout} ->
                # ✅ Retry transient errors
                Logger.warning("Timeout, will retry")
                {:error, :timeout}

              {:error, :rate_limit} ->
                # ✅ Retry rate limits
                Logger.warning("Rate limited, will retry")
                {:error, :rate_limit}

              {:error, :not_found} ->
                # ❌ Don't retry permanent errors
                Logger.error("Resource not found, not retrying")
                {:error, :not_found}

              {:error, :unauthorized} ->
                # ❌ Don't retry auth errors
                Logger.error("Unauthorized, not retrying")
                {:error, :unauthorized}
            end
          end
        end

        defp make_api_call(endpoint) do
          # Simulate API call
          {:ok, "response"}
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Compensation on Failure
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Compensation executes on workflow failure.

  Demonstrates:
  - Compensation in reverse order
  - Partial rollback
  - Multi-system cleanup
  """
  def example_compensation_on_failure do
    quote do
      defmodule MyApp.CompensationWorkflow do
        use Reactor
        require Logger

        input :user_id

        # Step 1: Create user account (succeeds)
        step :create_account do
          argument :user_id, input(:user_id)

          run fn %{user_id: id}, _context ->
            Logger.info("Creating account for user #{id}")
            {:ok, %{account_id: "acc-#{id}"}}
          end

          compensate fn account, _arguments ->
            Logger.warning("ROLLBACK: Deleting account #{account.account_id}")
            delete_account(account.account_id)
            :ok
          end
        end

        # Step 2: Create profile (succeeds)
        step :create_profile do
          argument :account, result(:create_account)

          run fn %{account: account}, _context ->
            Logger.info("Creating profile for account #{account.account_id}")
            {:ok, %{profile_id: "prof-#{account.account_id}"}}
          end

          compensate fn profile, _arguments ->
            Logger.warning("ROLLBACK: Deleting profile #{profile.profile_id}")
            delete_profile(profile.profile_id)
            :ok
          end
        end

        # Step 3: Send welcome email (FAILS)
        step :send_welcome_email do
          argument :account, result(:create_account)

          run fn %{account: account}, _context ->
            Logger.info("Sending welcome email")
            # Simulate failure
            {:error, "Email service unavailable"}
          end
        end

        defp delete_account(id), do: :ok
        defp delete_profile(id), do: :ok
      end

      # Running workflow:
      case Reactor.run(MyApp.CompensationWorkflow, %{user_id: "user-123"}, %{}) do
        {:ok, _} ->
          Logger.info("All steps succeeded")

        {:error, _reason} ->
          # Compensation order:
          # 1. Delete profile (step 2 compensate)
          # 2. Delete account (step 1 compensate)
          Logger.info("Workflow failed, rollback completed")
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Error Context Preservation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Preserving error context through workflow.

  Demonstrates:
  - Detailed error information
  - Error context enrichment
  - Logging at failure point
  """
  def example_error_context do
    quote do
      defmodule MyApp.ErrorContextWorkflow do
        use Reactor
        require Logger

        input :file_path

        step :validate_file do
          argument :file_path, input(:file_path)

          run fn %{file_path: path}, _context ->
            cond do
              not File.exists?(path) ->
                # ✅ Detailed error with context
                error = %{
                  step: :validate_file,
                  reason: :file_not_found,
                  path: path,
                  timestamp: DateTime.utc_now()
                }

                Logger.error("File validation failed",
                  error: error
                )

                {:error, error}

              File.stat!(path).size == 0 ->
                error = %{
                  step: :validate_file,
                  reason: :empty_file,
                  path: path,
                  size: 0
                }

                {:error, error}

              true ->
                {:ok, path}
            end
          end
        end

        step :process_file do
          argument :file_path, result(:validate_file)

          run fn %{file_path: path}, _context ->
            try do
              data = File.read!(path)
              {:ok, data}
            rescue
              exception ->
                # ✅ Capture exception details
                error = %{
                  step: :process_file,
                  exception: Exception.message(exception),
                  stacktrace: Exception.format_stacktrace(__STACKTRACE__),
                  path: path
                }

                Logger.error("File processing exception", error: error)
                {:error, error}
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Job Error Handling
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Error handling in Oban workers.

  Demonstrates:
  - Different error types
  - Retry vs discard
  - Final attempt handling
  - Error broadcasting
  """
  def example_job_error_handling do
    quote do
      defmodule MyApp.Jobs.Workers.ErrorHandlingWorker do
        use Oban.Worker,
          queue: :default,
          max_attempts: 3

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          %{"resource_id" => id} = args

          Logger.info("Processing resource",
            resource_id: id,
            attempt: attempt
          )

          case process_resource(id) do
            {:ok, result} ->
              # ✅ Success
              :ok

            {:error, :not_found} ->
              # ❌ Permanent failure - discard
              Logger.error("Resource not found, discarding job", resource_id: id)
              {:discard, :not_found}

            {:error, :validation_error} ->
              # ❌ Permanent failure - discard
              Logger.error("Validation error, discarding job", resource_id: id)
              {:discard, :validation_error}

            {:error, reason} ->
              # ↩️ Transient failure - retry
              Logger.warning("Transient error, will retry",
                resource_id: id,
                attempt: attempt,
                error: reason
              )

              # Handle final attempt
              if attempt >= 3 do
                Logger.error("Final attempt failed, giving up", resource_id: id)
                broadcast_failure(id, reason)
                mark_resource_failed(id, reason)
              end

              {:error, reason}
          end
        end

        defp process_resource(id) do
          {:ok, "processed"}
        end

        defp broadcast_failure(id, reason) do
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "resource:#{id}",
            {:processing_failed, %{resource_id: id, error: reason}}
          )
        end

        defp mark_resource_failed(id, reason) do
          # Update resource status
          :ok
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Workflow + Job Error Coordination
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Error handling across job and workflow.

  Demonstrates:
  - Job wraps workflow
  - Error propagation from workflow to job
  - Cleanup on final failure
  """
  def example_coordinated_error_handling do
    quote do
      # Workflow with error handling
      defmodule MyApp.ProcessingWorkflow do
        use Reactor
        require Logger

        input :resource_id

        step :load_resource do
          argument :resource_id, input(:resource_id)

          run fn %{resource_id: id}, context ->
            actor = Map.get(context, :actor)

            case MyResource |> Ash.get(id, actor: actor) do
              {:ok, resource} ->
                {:ok, resource}

              {:error, %Ash.Error.Query.NotFound{}} ->
                {:error, :not_found}

              {:error, %Ash.Error.Forbidden{}} ->
                {:error, :forbidden}

              {:error, reason} ->
                {:error, reason}
            end
          end
        end

        step :process_resource do
          argument :resource, result(:load_resource)

          run fn %{resource: resource}, _context ->
            case dangerous_operation(resource) do
              {:ok, result} -> {:ok, result}
              {:error, reason} -> {:error, reason}
            end
          end

          compensate fn _result, %{resource: resource} ->
            Logger.warning("Compensating process step", resource_id: resource.id)
            :ok
          end
        end

        defp dangerous_operation(resource) do
          {:ok, "processed"}
        end
      end

      # Job wrapping workflow
      defmodule MyApp.Jobs.Workers.ProcessingWorker do
        use Oban.Worker,
          queue: :default,
          max_attempts: 3

        require Logger

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          %{"resource_id" => id, "actor" => actor_map} = args

          actor = atomize_actor_keys(actor_map)

          # Run workflow
          inputs = %{resource_id: id}
          context = %{actor: actor, attempt: attempt}

          case Reactor.run(MyApp.ProcessingWorkflow, inputs, context) do
            {:ok, result} ->
              Logger.info("Processing completed", resource_id: id)
              :ok

            {:error, :not_found} ->
              # ❌ Permanent - discard
              Logger.error("Resource not found", resource_id: id)
              {:discard, :not_found}

            {:error, :forbidden} ->
              # ❌ Permanent - discard
              Logger.error("Access forbidden", resource_id: id)
              {:discard, :forbidden}

            {:error, reason} ->
              # ↩️ Retry transient errors
              Logger.warning("Processing failed, will retry",
                resource_id: id,
                attempt: attempt,
                error: reason
              )

              # Cleanup on final attempt
              if attempt >= 3 do
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
          case MyResource |> Ash.get(resource_id, actor: actor) do
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

          # Broadcast failure
          Phoenix.PubSub.broadcast(
            MyApp.PubSub,
            "resource:#{resource_id}",
            {:processing_failed,
             %{
               resource_id: resource_id,
               error: format_error(reason),
               failed_at: DateTime.utc_now()
             }}
          )
        end

        defp atomize_actor_keys(actor_map) do
          %{
            id: actor_map["id"],
            organization_id: actor_map["organization_id"],
            role: String.to_existing_atom(actor_map["role"])
          }
        end

        defp format_error(reason) when is_binary(reason), do: reason
        defp format_error(reason), do: inspect(reason)
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Error Handling Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Error Handling Best Practices

  ### 1. Workflow Error Returns

  ✅ Return {:error, reason}:
  ```elixir
  run fn arguments, context ->
    case risky_operation() do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
  ```

  ### 2. Distinguishing Error Types

  ✅ Identify permanent vs transient:
  ```elixir
  case operation() do
    {:error, :not_found} -> {:error, :not_found}  # Permanent
    {:error, :forbidden} -> {:error, :forbidden}  # Permanent
    {:error, :timeout} -> {:error, :timeout}      # Transient (retry)
    {:error, :rate_limit} -> {:error, :rate_limit} # Transient (retry)
  end
  ```

  ### 3. Job Error Returns

  ✅ Use appropriate return value:
  ```elixir
  :ok                     # Success
  {:error, reason}        # Retry (uses max_attempts)
  {:discard, reason}      # Permanent failure (no retry)
  {:snooze, seconds}      # Postpone (retry later)
  {:cancel, reason}       # Cancel job
  ```

  ### 4. Final Attempt Handling

  ✅ Clean up on final attempt:
  ```elixir
  def perform(%Oban.Job{args: args, attempt: attempt}) do
    case process(args) do
      {:ok, _} -> :ok
      {:error, reason} ->
        if attempt >= max_attempts() do
          cleanup_on_final_failure(args, reason)
        end
        {:error, reason}
    end
  end
  ```

  ### 5. Error Context

  ✅ Provide detailed error information:
  ```elixir
  {:error, %{
    step: :validate_file,
    reason: :invalid_format,
    file: path,
    line: 42,
    details: "Expected CSV header"
  }}
  ```

  ### 6. Compensation Safety

  ✅ Never fail compensation:
  ```elixir
  compensate fn resource, _arguments ->
    case cleanup(resource) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("Cleanup failed: #{inspect(reason)}")
        :ok  # Still return :ok!
    end
  end
  ```

  ### 7. Error Logging

  ✅ Log at appropriate levels:
  ```elixir
  # Transient errors - warning
  Logger.warning("Timeout, will retry", attempt: attempt)

  # Permanent errors - error
  Logger.error("Resource not found", resource_id: id)

  # Final failures - error
  Logger.error("Final attempt failed, giving up")
  ```

  ### 8. User Communication

  ✅ Broadcast failures to UI:
  ```elixir
  Phoenix.PubSub.broadcast(
    MyApp.PubSub,
    "resource:#{id}",
    {:processing_failed, %{
      resource_id: id,
      error: "User-friendly error message",
      failed_at: DateTime.utc_now()
    }}
  )
  ```

  ### 9. Retry Strategy Decision Matrix

  | Error Type | Action | Reason |
  |------------|--------|--------|
  | :not_found | Discard | Won't exist on retry |
  | :forbidden | Discard | Auth won't change |
  | :validation_error | Discard | Data won't change |
  | :timeout | Retry | Transient network issue |
  | :rate_limit | Snooze | Need to wait |
  | :database_error | Retry | May recover |
  | :external_api_down | Retry | May recover |

  ### 10. Testing Error Paths

  ✅ Test both success and failure:
  ```elixir
  test "workflow compensates on failure" do
    inputs = %{data: invalid_data}
    assert {:error, _} = Reactor.run(MyWorkflow, inputs, %{})

    # Verify compensation ran
    assert resource_cleaned_up?()
  end

  test "job discards on permanent failure" do
    job = perform_job(%{args: %{"resource_id" => "nonexistent"}})
    assert {:discard, :not_found} = job
  end
  ```
  """
end
