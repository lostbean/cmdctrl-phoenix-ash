defmodule ReactorObanSkill.Examples.SagaCompensation do
  @moduledoc """
  Self-contained examples of saga pattern with compensation actions.

  Compensation ensures workflows can safely rollback on failure, maintaining
  system consistency even when operations span multiple systems (database,
  external connections, external APIs).

  ## Related Files
  - ../reference/sagas.md - Saga pattern deep dive
  - DESIGN/architecture/reactor-patterns.md - Workflow patterns
  - Real workflow examples in your application - Multi-system saga patterns
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Compensation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Basic compensation pattern.

  Demonstrates:
  - compensate/1 function
  - Automatic rollback on failure
  - Compensation order (reverse)
  """
  def example_basic_compensation do
    quote do
      defmodule MyApp.BasicCompensationWorkflow do
        use Reactor
        require Logger

        input :filename

        # Step 1: Create file
        step :create_file do
          argument :filename, input(:filename)

          run fn %{filename: name}, _context ->
            case File.write(name, "initial content") do
              :ok ->
                Logger.info("Created file: #{name}")
                {:ok, name}

              {:error, reason} ->
                {:error, "Failed to create file: #{reason}"}
            end
          end

          # ✅ Compensation: Delete file if workflow fails
          compensate fn filename, _arguments ->
            Logger.warning("Rolling back: Deleting file #{filename}")
            File.rm(filename)
            :ok
          end
        end

        # Step 2: Append content (will fail deliberately)
        step :append_content do
          argument :filename, result(:create_file)

          run fn %{filename: name}, _context ->
            # Simulate a failure
            {:error, "Simulated append failure"}
          end
        end
      end

      # Running the workflow:
      inputs = %{filename: "/tmp/test.txt"}
      context = %{}

      case Reactor.run(MyApp.BasicCompensationWorkflow, inputs, context) do
        {:ok, result} ->
          # Won't reach here
          :ok

        {:error, _reason} ->
          # Compensation ran - file was deleted
          Logger.info("File was cleaned up by compensation")
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Multi-Step Compensation Chain
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Multiple compensation actions in reverse order.

  Demonstrates:
  - Compensation runs in REVERSE order
  - Each step cleans up its own effects
  - Chained rollback
  """
  def example_compensation_chain do
    quote do
      defmodule MyApp.CompensationChainWorkflow do
        use Reactor
        require Logger

        input :namespace
        input :table_name

        # Step 1: Create namespace
        step :create_namespace do
          argument :namespace, input(:namespace)

          run fn %{namespace: ns}, _context ->
            Logger.info("Creating namespace: #{ns}")
            # Simulate namespace creation
            {:ok, ns}
          end

          compensate fn namespace, _arguments ->
            Logger.warning("COMPENSATION: Dropping namespace #{namespace}")
            # Clean up namespace
            :ok
          end
        end

        # Step 2: Create table
        step :create_table do
          argument :namespace, result(:create_namespace)
          argument :table_name, input(:table_name)

          run fn %{namespace: ns, table_name: table}, _context ->
            full_name = "#{ns}.#{table}"
            Logger.info("Creating table: #{full_name}")
            {:ok, full_name}
          end

          compensate fn table, %{namespace: namespace} ->
            Logger.warning("COMPENSATION: Dropping table #{table}")
            # Clean up table
            :ok
          end
        end

        # Step 3: Create record (will fail)
        step :create_record do
          argument :table, result(:create_table)

          run fn %{table: table}, _context ->
            Logger.info("Creating record in: #{table}")
            # Simulate failure
            {:error, "Record creation failed"}
          end
        end
      end

      # Running the workflow:
      {:error, _} =
        Reactor.run(
          MyApp.CompensationChainWorkflow,
          %{namespace: "test_ns", table_name: "test_table"},
          %{}
        )

      # Compensation order:
      # 1. Drop table (step 2 compensate)
      # 2. Drop namespace (step 1 compensate)
      # Note: Reverse order of execution!
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Idempotent Compensation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Idempotent compensation (safe to run multiple times).

  Demonstrates:
  - Checking if resource exists before cleanup
  - Defensive compensation
  - Handling partial failures
  """
  def example_idempotent_compensation do
    quote do
      defmodule MyApp.IdempotentCompensationWorkflow do
        use Reactor
        require Logger

        alias MyApp.Resource

        input :data

        step :create_resource do
          argument :data, input(:data)

          run fn %{data: data}, context ->
            actor = Map.get(context, :actor)

            case Resource
                 |> Ash.Changeset.for_create(:create, data, actor: actor)
                 |> Ash.create() do
              {:ok, resource} ->
                Logger.info("Created resource: #{resource.id}")
                {:ok, resource}

              {:error, reason} ->
                {:error, reason}
            end
          end

          # ✅ Idempotent compensation: Check existence before delete
          compensate fn resource, %{actor: actor} ->
            Logger.warning("Compensating: Deleting resource #{resource.id}")

            # Check if resource still exists
            case Ash.get(Resource, resource.id, actor: actor) do
              {:ok, existing_resource} ->
                # Resource exists, delete it
                case Ash.Changeset.for_destroy(existing_resource, :destroy, %{},
                       actor: actor
                     )
                     |> Ash.destroy() do
                  {:ok, _} ->
                    Logger.info("Successfully deleted resource")
                    :ok

                  {:error, reason} ->
                    Logger.error("Failed to delete resource: #{inspect(reason)}")
                    # Don't break compensation chain
                    :ok
                end

              {:error, _} ->
                # Resource already deleted or doesn't exist
                Logger.info("Resource already deleted, nothing to compensate")
                :ok
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Compensation with Arguments
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Accessing step arguments in compensation.

  Demonstrates:
  - Compensation receives result AND arguments
  - Using arguments for cleanup
  - Accessing nested data
  """
  def example_compensation_arguments do
    quote do
      defmodule MyApp.CompensationArgumentsWorkflow do
        use Reactor

        input :connection_id
        input :namespace

        step :get_connection do
          argument :connection_id, input(:connection_id)

          run fn %{connection_id: id}, context ->
            actor = Map.get(context, :actor)
            Connection |> Ash.get(id, actor: actor)
          end

          compensate fn _connection, _arguments ->
            # No cleanup needed for read operation
            :ok
          end
        end

        step :create_namespace do
          argument :namespace, input(:namespace)
          argument :connection, result(:get_connection)

          run fn %{namespace: ns, connection: conn}, _context ->
            # Create namespace in connection
            ConnectionOperations.create_namespace(conn, ns)
            {:ok, ns}
          end

          # ✅ Access both result AND arguments
          compensate fn
            namespace, %{connection: connection}, _context ->
              Logger.warning(
                "Dropping namespace #{namespace} from connection #{connection.id}"
              )

              # Use connection from arguments for cleanup
              ConnectionOperations.drop_namespace(connection, namespace)
              :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Real-World Saga Pattern
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Realistic multi-system saga workflow.

  Demonstrates realistic multi-system compensation:
  - Database resources (Resource versions)
  - External system operations (namespace, schemas)
  - Proper cleanup order
  """
  def example_realistic_saga do
    quote do
      defmodule MyApp.Example.SimplifiedPublishSaga do
        use Reactor
        require Logger

        alias MyApp.Domain.Draft
        alias MyApp.Domain.ResourceVersion
        alias MyApp.External.Materializer

        input :draft_id

        # Step 1: Load draft (no compensation needed for reads)
        step :load_draft do
          argument :draft_id, input(:draft_id)

          run fn %{draft_id: id}, context ->
            actor = Map.get(context, :actor)
            Ash.get(Draft, id, actor: actor)
          end

          compensate fn _result, _arguments ->
            # No compensation needed for read operation
            :ok
          end
        end

        # Step 2: Create resource version (database resource)
        step :create_version do
          argument :draft, result(:load_draft)

          run fn %{draft: draft}, context ->
            actor = Map.get(context, :actor)

            version_params = %{
              resource_id: draft.resource_id,
              data: draft.data
            }

            case ResourceVersion
                 |> Ash.Changeset.for_create(:create, version_params, actor: actor)
                 |> Ash.create() do
              {:ok, version} ->
                Logger.info("Created version #{version.id}")
                {:ok, version}

              {:error, reason} ->
                {:error, "Version creation failed: #{inspect(reason)}"}
            end
          end

          # ✅ Compensation: Delete version from database
          compensate fn version, _arguments ->
            Logger.warning("Rolling back version #{version.id}")

            case Ash.destroy(version) do
              :ok -> :ok
              {:ok, _} -> :ok
              {:error, reason} ->
                Logger.error("Failed to rollback version: #{inspect(reason)}")
                :ok
            end
          end
        end

        # Step 3: Create namespace in external system
        step :create_namespace do
          argument :version, result(:create_version)
          argument :draft, result(:load_draft)

          run fn %{version: version, draft: draft}, _context ->
            connection = draft.resource_version.resource.connection

            case Materializer.create_namespace(connection, version.namespace) do
              :ok ->
                Logger.info("Created namespace #{version.namespace}")
                {:ok, :created}

              {:error, reason} ->
                {:error, "Namespace creation failed: #{inspect(reason)}"}
            end
          end

          # ✅ Compensation: Drop namespace from external system
          compensate fn
            _result, %{version: version, draft: draft}, _context ->
              connection = draft.resource_version.resource.connection

              Logger.warning("Rolling back namespace #{version.namespace}")

              case Materializer.drop_namespace(connection, version.namespace) do
                :ok -> :ok
                {:error, reason} ->
                  Logger.error("Failed to rollback namespace: #{inspect(reason)}")
                  :ok
              end
          end
        end

        # Step 4: Materialize schemas (create tables)
        step :materialize_schemas do
          argument :version, result(:create_version)
          argument :draft, result(:load_draft)

          run fn %{version: version, draft: draft}, _context ->
            connection = draft.resource_version.resource.connection
            tasks = extract_materialization_tasks(draft.data)

            case Materializer.materialize_schemas(connection, tasks, version.namespace) do
              {:ok, schema_ids} ->
                Logger.info("Materialized #{length(schema_ids)} schemas")
                {:ok, schema_ids}

              {:error, reason} ->
                {:error, "Materialization failed: #{inspect(reason)}"}
            end
          end

          # ✅ Compensation: Drop all created schemas
          # Note: Dropping namespace also drops schemas
          compensate fn
            _result, %{version: version, draft: draft}, _context ->
              connection = draft.resource_version.resource.connection

              Logger.warning("Rolling back materialized schemas")

              # Drop namespace (which drops all schemas in it)
              Materializer.drop_namespace(connection, version.namespace)
              :ok
          end
        end

        # Step 5: Publish version
        step :publish_version do
          argument :version, result(:create_version)

          run fn %{version: version}, context ->
            actor = Map.get(context, :actor)

            case Ash.Changeset.for_update(version, :publish)
                 |> Ash.update(actor: actor) do
              {:ok, published} ->
                Logger.info("Published version #{published.id}")
                {:ok, published}

              {:error, reason} ->
                {:error, "Publish failed: #{inspect(reason)}"}
            end
          end

          # ✅ Compensation: Unpublish version
          compensate fn _result, %{version: version}, context ->
            actor = Map.get(context, :actor)

            Logger.warning("Rolling back publish for version #{version.id}")

            case Ash.Changeset.for_update(version, :unpublish)
                 |> Ash.update(actor: actor) do
              {:ok, _} -> :ok
              {:error, reason} ->
                Logger.error("Failed to unpublish: #{inspect(reason)}")
                :ok
            end
          end
        end
      end

      # Running the saga:
      inputs = %{draft_id: draft_id}
      context = %{actor: actor}

      case Reactor.run(MyApp.Example.SimplifiedPublishSaga, inputs, context) do
        {:ok, published_version} ->
          Logger.info("Saga completed successfully")

        {:error, reason} ->
          # All compensations ran in reverse order:
          # 5. Unpublish version
          # 4. Drop schemas
          # 3. Drop namespace
          # 2. Delete version
          # 1. (no compensation)
          Logger.error("Saga failed and rolled back: #{inspect(reason)}")
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Compensation Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Compensation Best Practices

  ### 1. Compensation Structure

  ```elixir
  step :create_resource do
    run fn arguments, context ->
      # Create resource
      {:ok, resource}
    end

    # Compensation receives:
    # - result: The successful result from run/2
    # - arguments: All arguments passed to the step
    # - context: Workflow context (optional)
    compensate fn result, arguments, context ->
      # Clean up resource
      :ok  # Always return :ok (don't break chain)
    end
  end
  ```

  ### 2. Compensation Order

  ✅ Compensations run in REVERSE order:

  ```elixir
  step :step1 do
    run fn -> {:ok, 1} end
    compensate fn -> cleanup_1() end
  end

  step :step2 do
    run fn -> {:ok, 2} end
    compensate fn -> cleanup_2() end
  end

  step :step3 do
    run fn -> {:error, "fail"} end  # Fails here
  end

  # Execution order:
  # 1. step1 runs successfully
  # 2. step2 runs successfully
  # 3. step3 fails
  # 4. cleanup_2() runs (step2 compensate)
  # 5. cleanup_1() runs (step1 compensate)
  ```

  ### 3. Idempotent Compensation

  ✅ Always make compensation safe to run multiple times:

  ```elixir
  compensate fn resource, _arguments ->
    # Check if resource still exists
    case Ash.get(Resource, resource.id) do
      {:ok, existing} ->
        # Delete if it exists
        Ash.destroy(existing)

      {:error, _} ->
        # Already deleted or never existed
        :ok
    end

    :ok
  end
  ```

  ### 4. Don't Break Compensation Chain

  ✅ Always return :ok from compensation:

  ```elixir
  compensate fn resource, _arguments ->
    case cleanup_resource(resource) do
      :ok ->
        Logger.info("Cleanup successful")
        :ok

      {:error, reason} ->
        # Log but don't break chain
        Logger.error("Cleanup failed: #{inspect(reason)}")
        :ok  # Still return :ok!
    end
  end
  ```

  ### 5. Access Previous Results in Compensation

  ✅ Use arguments map to access dependencies:

  ```elixir
  step :create_child do
    argument :parent, result(:create_parent)
    argument :data, input(:data)

    run fn %{parent: parent, data: data}, context ->
      create_child(parent, data)
    end

    # Access parent from arguments
    compensate fn child, %{parent: parent}, context ->
      delete_child(parent, child)
      :ok
    end
  end
  ```

  ### 6. No Compensation for Reads

  ✅ Read operations don't need compensation:

  ```elixir
  step :load_resource do
    run fn arguments, context ->
      Ash.get(Resource, arguments.id, actor: context.actor)
    end

    compensate fn _result, _arguments ->
      # No cleanup needed for reads
      :ok
    end
  end
  ```

  ### 7. Multi-System Cleanup

  ✅ Clean up in all affected systems:

  ```elixir
  compensate fn _result, %{connection: conn, version: v}, _context ->
    # Clean up external system
    Connection.drop_namespace(conn, v.namespace)

    # Clean up database
    Ash.destroy(v)

    # Clean up cache
    Cache.delete("version:#{v.id}")

    :ok
  end
  ```
  """
end
