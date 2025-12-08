defmodule ReactorObanSkill.Examples.BasicWorkflow do
  @moduledoc """
  Self-contained examples of basic Reactor workflow structure.

  Shows the fundamental building blocks: inputs, steps, dependencies, and running workflows.

  ## Related Files
  - ../reference/sagas.md - Saga pattern fundamentals
  - ../../ash-framework/reference/actor-context.md - Actor propagation
  - DESIGN/concepts/workflows.md - Workflow concepts
  - lib/my_app/**/workflows/*.ex - Real workflow implementations
  """

  # -----------------------------------------------------------------------------
  # Example 1: Minimal Workflow
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Simplest possible Reactor workflow.

  Demonstrates:
  - `use Reactor` directive
  - Input definitions
  - Basic step structure
  - Running the workflow
  """
  def example_minimal_workflow do
    quote do
      defmodule MyApp.MinimalWorkflow do
        use Reactor

        # Define required inputs
        input :message

        # Single step
        step :process_message do
          argument :message, input(:message)

          run fn %{message: msg}, _context ->
            {:ok, String.upcase(msg)}
          end
        end
      end

      # Running the workflow:
      inputs = %{message: "hello"}
      context = %{}

      {:ok, result} = Reactor.run(MyApp.MinimalWorkflow, inputs, context)
      # result => "HELLO"
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Multi-Step Workflow with Dependencies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Workflow with multiple steps and dependencies.

  Demonstrates:
  - Multiple steps
  - Step dependencies using result/1
  - Sequential execution
  """
  def example_multi_step_workflow do
    quote do
      defmodule MyApp.DataProcessingWorkflow do
        use Reactor
        require Logger

        input :data

        # Step 1: Validate data
        step :validate do
          argument :data, input(:data)

          run fn %{data: data}, _context ->
            if is_list(data) and length(data) > 0 do
              Logger.info("Data validated: #{length(data)} items")
              {:ok, data}
            else
              {:error, "Invalid data: must be non-empty list"}
            end
          end
        end

        # Step 2: Transform data (depends on validate)
        step :transform do
          argument :validated_data, result(:validate)

          run fn %{validated_data: data}, _context ->
            transformed = Enum.map(data, &String.upcase/1)
            Logger.info("Data transformed")
            {:ok, transformed}
          end
        end

        # Step 3: Count results (depends on transform)
        step :count do
          argument :transformed_data, result(:transform)

          run fn %{transformed_data: data}, _context ->
            count = length(data)
            Logger.info("Counted #{count} items")
            {:ok, %{data: data, count: count}}
          end
        end
      end

      # Running the workflow:
      inputs = %{data: ["apple", "banana", "cherry"]}
      context = %{}

      {:ok, result} = Reactor.run(MyApp.DataProcessingWorkflow, inputs, context)
      # result => %{data: ["APPLE", "BANANA", "CHERRY"], count: 3}
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Workflow with Context Access
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Accessing workflow context in steps.

  Demonstrates:
  - Passing data via context (not inputs)
  - Accessing context in step functions
  - Difference between inputs and context
  """
  def example_context_access do
    quote do
      defmodule MyApp.ContextWorkflow do
        use Reactor

        input :resource_id

        step :load_resource do
          argument :resource_id, input(:resource_id)

          run fn %{resource_id: id}, context ->
            # ✅ Access context for metadata (not business data)
            attempt = Map.get(context, :attempt, 1)
            Logger.info("Loading resource #{id}, attempt #{attempt}")

            # Simulate loading
            {:ok, %{id: id, name: "Resource #{id}"}}
          end
        end

        step :process_resource do
          argument :resource, result(:load_resource)

          run fn %{resource: resource}, context ->
            # ✅ Context contains execution metadata
            attempt = Map.get(context, :attempt, 1)
            timestamp = Map.get(context, :timestamp)

            processed = %{
              resource: resource,
              processed_at: timestamp,
              attempt: attempt
            }

            {:ok, processed}
          end
        end
      end

      # Running with context:
      inputs = %{resource_id: "abc-123"}

      context = %{
        attempt: 1,
        timestamp: DateTime.utc_now()
      }

      {:ok, result} = Reactor.run(MyApp.ContextWorkflow, inputs, context)
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Workflow with Conditional Steps
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Conditional execution based on previous results.

  Demonstrates:
  - Conditional logic in steps
  - Different execution paths
  - Skipping optional processing
  """
  def example_conditional_workflow do
    quote do
      defmodule MyApp.ConditionalWorkflow do
        use Reactor

        input :number
        input :should_double

        step :validate_number do
          argument :number, input(:number)

          run fn %{number: n}, _context ->
            if is_integer(n) do
              {:ok, n}
            else
              {:error, "Must be an integer"}
            end
          end
        end

        # Conditional step - processes based on flag
        step :process_number do
          argument :number, result(:validate_number)
          argument :should_double, input(:should_double)

          run fn %{number: n, should_double: should_double}, _context ->
            result =
              if should_double do
                n * 2
              else
                n
              end

            {:ok, result}
          end
        end

        step :format_result do
          argument :processed, result(:process_number)

          run fn %{processed: n}, _context ->
            {:ok, "Result: #{n}"}
          end
        end
      end

      # Running with doubling enabled:
      {:ok, result} =
        Reactor.run(
          MyApp.ConditionalWorkflow,
          %{number: 5, should_double: true},
          %{}
        )

      # result => "Result: 10"

      # Running without doubling:
      {:ok, result} =
        Reactor.run(
          MyApp.ConditionalWorkflow,
          %{number: 5, should_double: false},
          %{}
        )

      # result => "Result: 5"
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Workflow with Retry Logic
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Built-in retry mechanism for transient failures.

  Demonstrates:
  - max_retries option
  - Automatic retry on failure
  - Exponential backoff
  """
  def example_retry_workflow do
    quote do
      defmodule MyApp.RetryWorkflow do
        use Reactor
        require Logger

        input :api_endpoint

        step :call_external_api do
          argument :endpoint, input(:api_endpoint)

          # ✅ Retry up to 3 times on failure
          max_retries 3

          run fn %{endpoint: endpoint}, context ->
            attempt = Map.get(context, :attempt, 1)
            Logger.info("Calling API, attempt #{attempt}")

            # Simulate API call
            case make_api_call(endpoint) do
              {:ok, response} ->
                Logger.info("API call succeeded")
                {:ok, response}

              {:error, :rate_limit} ->
                # ✅ Return error to trigger retry
                Logger.warning("Rate limited, will retry")
                {:error, :rate_limit}

              {:error, :unauthorized} ->
                # ❌ Don't retry authorization failures
                Logger.error("Unauthorized, not retrying")
                {:error, :unauthorized}
            end
          end
        end

        step :process_response do
          argument :response, result(:call_external_api)

          run fn %{response: response}, _context ->
            processed = transform_response(response)
            {:ok, processed}
          end
        end
      end

      # Running the workflow:
      inputs = %{api_endpoint: "https://api.example.com/data"}
      context = %{attempt: 1}

      case Reactor.run(MyApp.RetryWorkflow, inputs, context) do
        {:ok, result} ->
          Logger.info("Workflow completed successfully")

        {:error, reason} ->
          Logger.error("Workflow failed after retries: #{inspect(reason)}")
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Real-World Pattern from your application
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Realistic workflow pattern.

  Shows realistic structure with:
  - Loading resources
  - Validation
  - Multiple transformation steps
  - Updating resources
  """
  def example_realistic_workflow do
    quote do
      defmodule MyApp.Example.SimplifiedPublishWorkflow do
        use Reactor
        require Logger

        alias MyApp.Domain.Draft

        input :draft_id

        # Step 1: Load draft
        step :load_draft do
          argument :draft_id, input(:draft_id)

          run fn %{draft_id: id}, context ->
            actor = Map.get(context, :actor)

            case Ash.get(Draft, id, actor: actor) do
              {:ok, draft} ->
                Logger.info("Loaded draft #{id}")
                {:ok, draft}

              {:error, reason} ->
                {:error, "Failed to load draft: #{inspect(reason)}"}
            end
          end
        end

        # Step 2: Validate draft
        step :validate_draft do
          argument :draft, result(:load_draft)

          run fn %{draft: draft}, _context ->
            cond do
              draft.status != :active ->
                {:error, "Draft is not active"}

              is_nil(draft.data) ->
                {:error, "Draft has no data"}

              true ->
                Logger.info("Draft validation passed")
                {:ok, :valid}
            end
          end
        end

        # Step 3: Transform data
        step :transform_data do
          argument :draft, result(:load_draft)

          run fn %{draft: draft}, _context ->
            case transform_data(draft.data) do
              {:ok, transformed} ->
                Logger.info("Data transformed successfully")
                {:ok, transformed}

              {:error, reason} ->
                {:error, "Transformation failed: #{inspect(reason)}"}
            end
          end
        end

        # Step 4: Create version
        step :create_version do
          argument :draft, result(:load_draft)
          argument :transformed_data, result(:transform_data)

          run fn %{draft: draft, transformed_data: data}, context ->
            actor = Map.get(context, :actor)

            version_params = %{
              resource_id: draft.resource_id,
              data: data
            }

            case create_resource_version(version_params, actor) do
              {:ok, version} ->
                Logger.info("Created version #{version.id}")
                {:ok, version}

              {:error, reason} ->
                {:error, "Version creation failed: #{inspect(reason)}"}
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Common Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Key Patterns for Basic Workflows

  ### 1. Input vs Context

  ✅ Use inputs for business data (what to process):
  - resource_id
  - file_path
  - user_query

  ✅ Use context for execution metadata (how to process):
  - actor (who is performing the action)
  - attempt (retry count)
  - timestamp

  ### 2. Step Structure

  ```elixir
  step :step_name do
    argument :arg_name, input(:input_name)       # From workflow input
    argument :dep_name, result(:previous_step)   # From previous step

    max_retries 3      # Optional: retry on failure
    async? false       # Optional: control async execution

    run fn arguments, context ->
      # Access arguments via arguments.arg_name
      # Access context via Map.get(context, :key)

      case do_work(arguments, context) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
      end
    end
  end
  ```

  ### 3. Running Workflows

  ```elixir
  # Prepare inputs (business data)
  inputs = %{
    resource_id: id,
    data: data
  }

  # Prepare context (execution metadata)
  context = %{
    actor: actor,
    attempt: 1
  }

  # Run workflow
  case Reactor.run(MyWorkflow, inputs, context) do
    {:ok, result} ->
      # All steps completed successfully
      handle_success(result)

    {:error, reason} ->
      # Workflow failed
      handle_failure(reason)
  end
  ```

  ### 4. Error Handling

  ✅ Return {:error, reason} to fail the step:
  ```elixir
  run fn arguments, _context ->
    if valid?(arguments.data) do
      {:ok, arguments.data}
    else
      {:error, "Validation failed"}
    end
  end
  ```

  ✅ Let exceptions bubble for unexpected errors:
  ```elixir
  run fn arguments, _context ->
    # Will raise if database is down
    # Reactor will catch and convert to {:error, exception}
    {:ok, fetch_from_database!(arguments.id)}
  end
  ```

  ### 5. Dependencies and Execution Order

  Steps without dependencies run in parallel:
  ```elixir
  step :fetch_user do
    # No dependencies - runs immediately
  end

  step :fetch_settings do
    # No dependencies - runs in parallel with fetch_user
  end

  step :combine do
    argument :user, result(:fetch_user)
    argument :settings, result(:fetch_settings)
    # Waits for both previous steps
  end
  ```
  """
end
