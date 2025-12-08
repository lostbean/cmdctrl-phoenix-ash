defmodule AshSkill.Examples.ReactorWorkflows do
  @moduledoc """
  Self-contained examples of Reactor workflows with actor context propagation.

  Reactor provides saga patterns for complex multi-step workflows with
  automatic compensation (rollback) and actor context threading.

  ## Related Files
  - ../reference/actor-context.md - Actor propagation patterns
  - DESIGN/architecture/reactor-patterns.md - Workflow architecture
  - DESIGN/concepts/workflows.md - Workflow concepts
  - lib/my_app/**/workflows/*.ex - Real workflow implementations
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Reactor Workflow Structure
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Basic Reactor workflow with inputs and steps.

  Workflows define:
  - Inputs: Named parameters passed when running
  - Steps: Individual operations with dependencies
  - Context: Shared data across steps (includes actor)
  """
  def example_basic_workflow do
    quote do
      defmodule MyApp.BasicWorkflow do
        use Reactor

        # Define inputs
        input :resource_id
        input :actor  # ✅ Always include actor as input

        # Step 1: Load resource
        step :load_resource do
          argument :resource_id, input(:resource_id)
          argument :actor, input(:actor)

          run fn %{resource_id: id, actor: actor}, _context ->
            MyResource
            |> Ash.get(id, actor: actor)
          end
        end

        # Step 2: Process resource (depends on step 1)
        step :process_resource do
          argument :resource, result(:load_resource)
          argument :actor, input(:actor)

          run fn %{resource: resource, actor: actor}, _context ->
            process_resource(resource, actor)
          end
        end
      end

      # Run workflow:
      inputs = %{
        resource_id: "uuid-here",
        actor: actor
      }

      context = %{actor: actor}  # ✅ Also pass in context

      {:ok, result} = Reactor.run(MyApp.BasicWorkflow, inputs, context)
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Actor Context Propagation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Access actor from context in workflow steps.

  CRITICAL: Actor must be in both inputs AND context:
  - inputs: For explicit step arguments
  - context: For access via Map.get(context, :actor)
  """
  def example_actor_propagation do
    quote do
      defmodule MyApp.WorkflowWithActor do
        use Reactor

        input :data
        input :actor

        step :create_parent do
          argument :data, input(:data)

          run fn arguments, context ->
            # ✅ CORRECT: Access actor from context
            actor = Map.get(context, :actor)

            ParentResource
            |> Ash.Changeset.for_create(:create, arguments.data, actor: actor)
            |> Ash.create()
          end
        end

        step :create_child do
          argument :parent, result(:create_parent)

          run fn arguments, context ->
            # ✅ CORRECT: Get actor from context
            actor = Map.get(context, :actor)

            ChildResource
            |> Ash.Changeset.for_create(
              :create,
              %{parent_id: arguments.parent.id},
              actor: actor
            )
            |> Ash.create()
          end
        end
      end

      # Running workflow:
      Reactor.run(
        MyApp.WorkflowWithActor,
        %{data: data, actor: actor},
        %{actor: actor}  # ✅ Pass actor in context
      )
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Workflow with Compensation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Workflow with compensation for rollback.

  Compensation functions run in reverse order if any step fails.
  """
  def example_compensation do
    quote do
      defmodule MyApp.UploadWorkflow do
        use Reactor

        input :file_path
        input :connection_id
        input :actor

        # Step 1: Create namespace in connection
        step :create_namespace do
          argument :connection_id, input(:connection_id)

          run fn arguments, context ->
            actor = Map.get(context, :actor)
            connection = get_connection(arguments.connection_id, actor)
            namespace = generate_unique_namespace()

            case create_namespace_in_connection(connection, namespace) do
              :ok -> {:ok, namespace}
              {:error, reason} -> {:error, reason}
            end
          end

          # ✅ Compensation: Delete namespace if later steps fail
          compensate fn namespace, _arguments ->
            delete_namespace_from_connection(namespace)
            :ok
          end
        end

        # Step 2: Create DataSource record
        step :create_data_source do
          argument :namespace, result(:create_namespace)

          run fn arguments, context ->
            actor = Map.get(context, :actor)

            DataSource
            |> Ash.Changeset.for_create(
              :create,
              %{name: "Upload", namespace: arguments.namespace},
              actor: actor
            )
            |> Ash.create()
          end

          # ✅ Compensation: Delete DataSource
          compensate fn data_source, %{actor: actor} ->
            data_source
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end

        # Step 3: Upload data
        step :upload_data do
          argument :file_path, input(:file_path)
          argument :namespace, result(:create_namespace)

          run fn arguments, _context ->
            upload_file_to_connection(arguments.file_path, arguments.namespace)
          end

          # ✅ Compensation: Drop uploaded tables
          compensate fn _result, %{namespace: namespace} ->
            drop_namespace_tables(namespace)
            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Conditional Steps
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Conditional execution based on previous results.
  """
  def example_conditional_steps do
    quote do
      defmodule MyApp.ConditionalWorkflow do
        use Reactor

        input :resource_id
        input :should_process
        input :actor

        step :load_resource do
          argument :resource_id, input(:resource_id)

          run fn arguments, context ->
            actor = Map.get(context, :actor)
            MyResource |> Ash.get(arguments.resource_id, actor: actor)
          end
        end

        # Conditional step - only runs if should_process is true
        step :process_resource do
          argument :resource, result(:load_resource)
          argument :should_process, input(:should_process)

          run fn arguments, context ->
            if arguments.should_process do
              actor = Map.get(context, :actor)
              process_resource(arguments.resource, actor)
            else
              {:ok, arguments.resource}
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Error Handling in Workflows
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Handle errors in workflow steps.

  Returning {:error, reason} triggers compensation of previous steps.
  """
  def example_error_handling do
    quote do
      defmodule MyApp.ErrorHandlingWorkflow do
        use Reactor

        input :data
        input :actor

        step :validate_data do
          argument :data, input(:data)

          run fn arguments, _context ->
            case validate(arguments.data) do
              :ok ->
                {:ok, arguments.data}

              {:error, reason} ->
                # ✅ Returning error triggers compensation
                {:error, "Validation failed: #{reason}"}
            end
          end
        end

        step :create_resource do
          argument :data, result(:validate_data)
          max_retries 3  # ✅ Retry on transient failures

          run fn arguments, context ->
            actor = Map.get(context, :actor)

            case MyResource
                 |> Ash.Changeset.for_create(:create, arguments.data, actor: actor)
                 |> Ash.create() do
              {:ok, resource} ->
                {:ok, resource}

              {:error, %Ash.Error.Forbidden{}} ->
                # ✅ Don't retry authorization failures
                {:error, :forbidden}

              {:error, error} ->
                # ✅ Retry other errors
                {:error, error}
            end
          end

          compensate fn resource, %{actor: actor} ->
            # Clean up created resource
            resource
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Parallel Steps
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Run independent steps in parallel.

  Steps without dependencies run concurrently.
  """
  def example_parallel_steps do
    quote do
      defmodule MyApp.ParallelWorkflow do
        use Reactor

        input :resource_id
        input :actor

        step :load_resource do
          argument :resource_id, input(:resource_id)

          run fn arguments, context ->
            actor = Map.get(context, :actor)
            MyResource |> Ash.get(arguments.resource_id, actor: actor)
          end
        end

        # These steps run in parallel (no dependencies between them)
        step :process_a do
          argument :resource, result(:load_resource)

          run fn arguments, context ->
            actor = Map.get(context, :actor)
            process_a(arguments.resource, actor)
          end
        end

        step :process_b do
          argument :resource, result(:load_resource)

          run fn arguments, context ->
            actor = Map.get(context, :actor)
            process_b(arguments.resource, actor)
          end
        end

        # This step waits for both parallel steps
        step :combine_results do
          argument :result_a, result(:process_a)
          argument :result_b, result(:process_b)

          run fn arguments, _context ->
            {:ok, %{a: arguments.result_a, b: arguments.result_b}}
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 7: Nested Workflows
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Call workflows from within workflows.

  Nested workflows inherit parent context including actor.
  """
  def example_nested_workflows do
    quote do
      defmodule MyApp.ChildWorkflow do
        use Reactor

        input :data
        input :actor

        step :process do
          run fn _arguments, context ->
            actor = Map.get(context, :actor)
            # Process with actor
            {:ok, "processed"}
          end
        end
      end

      defmodule MyApp.ParentWorkflow do
        use Reactor

        input :items
        input :actor

        # Process each item using child workflow
        step :process_all do
          argument :items, input(:items)

          run fn arguments, context ->
            actor = Map.get(context, :actor)

            results =
              Enum.map(arguments.items, fn item ->
                # Run child workflow with same actor
                {:ok, result} =
                  Reactor.run(
                    MyApp.ChildWorkflow,
                    %{data: item, actor: actor},
                    %{actor: actor}  # ✅ Pass actor to child
                  )

                result
              end)

            {:ok, results}
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 8: Real-World Upload Workflow (from your application)
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Real workflow from your application showing complete pattern.

  This demonstrates all the key patterns together.
  """
  def example_upload_workflow do
    quote do
      defmodule MyApp.DataPipeline.Workflows.UploadWorkflow do
        @moduledoc """
        File upload workflow with proper ordering and rollback.

        1. Parse and validate file
        2. Generate unique namespace
        3. Create tables in connection (physical storage)
        4. Create DataSource (metadata registry)
        5. Upload data
        6. Create RawTable records

        Each step has compensation for rollback on failure.
        """

        use Reactor

        input :upload_id
        input :file_path
        input :actor

        # Step 1: Load upload record
        step :load_upload do
          argument :upload_id, input(:upload_id)
          argument :actor, input(:actor)

          run fn %{upload_id: id, actor: actor}, _context ->
            MyApp.DataPipeline.Upload
            |> Ash.get(id, actor: actor)
          end

          compensate fn _result, _inputs ->
            # No compensation needed for read
            :ok
          end
        end

        # Step 2: Generate unique namespace
        step :generate_namespace do
          argument :upload, result(:load_upload)

          run fn %{upload: upload}, _context ->
            timestamp =
              DateTime.utc_now()
              |> DateTime.to_iso8601(:basic)

            random = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
            namespace = "upload_#{upload.data_source_name}_#{timestamp}_#{random}"

            {:ok, %{namespace: namespace, generated_at: DateTime.utc_now()}}
          end

          compensate fn _result, _inputs ->
            :ok
          end
        end

        # Step 3: Get connection
        step :get_connection do
          argument :upload, result(:load_upload)
          argument :actor, input(:actor)

          run fn %{upload: upload, actor: actor}, _context ->
            MyApp.DataPipeline.Connection
            |> Ash.get(upload.connection_id, actor: actor)
          end

          compensate fn _result, _inputs ->
            :ok
          end
        end

        # Step 4: Create namespace in connection
        step :create_namespace do
          argument :namespace_info, result(:generate_namespace)
          argument :connection, result(:get_connection)
          max_retries 2

          run fn %{namespace_info: info, connection: connection}, context ->
            actor = Map.get(context, :actor)
            namespace = info.namespace

            with {:ok, conn} <- get_connection(connection),
                 {:ok, sql_engine} <- get_sql_engine(connection.engine_type) do
              case sql_engine.create_namespace(conn, namespace) do
                :ok ->
                  # Reset failure counter on success
                  handle_connection_success(connection, actor: actor)
                  {:ok, namespace}

                {:error, reason} ->
                  # Track failure
                  handle_connection_failure(connection, reason, actor: actor)
                  {:error, "Failed to create namespace: #{reason}"}
              end
            end
          end

          # Compensation: Drop namespace
          compensate fn namespace, %{connection: connection} ->
            with {:ok, conn} <- get_connection(connection),
                 {:ok, sql_engine} <- get_sql_engine(connection.engine_type) do
              sql_engine.drop_namespace(conn, namespace)
            end

            :ok
          end
        end

        # Step 5: Create DataSource record
        step :create_data_source do
          argument :upload, result(:load_upload)
          argument :namespace, result(:create_namespace)
          argument :connection, result(:get_connection)

          run fn arguments, context ->
            actor = Map.get(context, :actor)

            MyApp.DataPipeline.DataSource
            |> Ash.Changeset.for_create(
              :create,
              %{
                name: arguments.upload.data_source_name,
                connection_id: arguments.connection.id,
                namespace: arguments.namespace
              },
              actor: actor
            )
            |> Ash.create()
          end

          # Compensation: Delete DataSource
          compensate fn data_source, %{actor: actor} ->
            data_source
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end

        # More steps omitted for brevity...
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Common Reactor Patterns
  # -----------------------------------------------------------------------------

  @doc """
  ## Pattern #1: Always Pass Actor

  ✅ Actor must be in both inputs AND context:

  ```elixir
  # Define input
  input :actor

  # Pass when running
  Reactor.run(
    MyWorkflow,
    %{data: data, actor: actor},  # In inputs
    %{actor: actor}                # In context
  )

  # Access in steps
  run fn arguments, context ->
    actor = Map.get(context, :actor)
    # Use actor in Ash operations
  end
  ```

  ## Pattern #2: Compensation Order

  ✅ Compensation runs in REVERSE order:

  ```elixir
  step :step1 do
    compensate fn -> cleanup_step1() end
  end

  step :step2 do
    compensate fn -> cleanup_step2() end
  end

  # If step2 fails:
  # 1. cleanup_step2() runs
  # 2. cleanup_step1() runs
  ```

  ## Pattern #3: Step Dependencies

  ✅ Use result/1 to create dependencies:

  ```elixir
  step :load do
    # No dependencies - runs first
  end

  step :process do
    argument :data, result(:load)  # Depends on :load
  end

  step :finalize do
    argument :processed, result(:process)  # Depends on :process
  end
  ```

  ## Pattern #4: Error Handling Strategy

  ✅ Different errors need different handling:

  ```elixir
  run fn arguments, context ->
    case do_operation(arguments, context) do
      {:ok, result} ->
        {:ok, result}

      {:error, %Ash.Error.Forbidden{}} ->
        # Don't retry authorization failures
        {:error, :forbidden}

      {:error, :temporary_failure} ->
        # Retry with max_retries
        {:error, :temporary_failure}

      {:error, reason} ->
        # Log and fail
        Logger.error("Operation failed", reason: reason)
        {:error, reason}
    end
  end
  ```

  ## Pattern #5: Idempotent Compensation

  ✅ Compensation should be idempotent (safe to run multiple times):

  ```elixir
  compensate fn resource, _inputs ->
    # Check if resource still exists before deleting
    case Ash.get(Resource, resource.id) do
      {:ok, _} -> Ash.destroy(resource)
      {:error, _} -> :ok  # Already deleted
    end

    :ok
  end
  ```

  ## Pattern #6: Testing Workflows

  ✅ Test complete workflows and individual steps:

  ```elixir
  test "workflow creates all resources" do
    inputs = %{data: data, actor: actor}
    context = %{actor: actor}

    assert {:ok, result} = Reactor.run(MyWorkflow, inputs, context)
    assert result.resource_id
  end

  test "workflow compensates on failure" do
    # Create scenario that causes failure
    assert {:error, _} = Reactor.run(MyWorkflow, inputs, context)

    # Verify compensation ran (resources cleaned up)
    assert Ash.count!(Resource) == 0
  end
  ```
  """
end
