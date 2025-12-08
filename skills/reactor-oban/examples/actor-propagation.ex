defmodule ReactorObanSkill.Examples.ActorPropagation do
  @moduledoc """
  Self-contained examples of actor context propagation in Reactor workflows.

  Actor context is CRITICAL in your application for:
  - Multi-tenant data isolation
  - Role-based authorization
  - Audit trails

  ## Related Files
  - ../reference/actor-workflows.md - Actor in workflows deep dive
  - ../../ash-framework/reference/actor-context.md - Actor context patterns
  - DESIGN/concepts/actor-context.md - Actor architecture
  - lib/my_app/**/workflows/*.ex - Real workflow implementations
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Actor Propagation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Actor in workflow inputs AND context.

  CRITICAL: Actor must be in BOTH places:
  - inputs: For explicit step arguments (optional)
  - context: For accessing via Map.get(context, :actor) (required)
  """
  def example_basic_actor do
    quote do
      defmodule MyApp.ActorWorkflow do
        use Reactor

        alias MyApp.Resource

        input :resource_id
        # ✅ Actor can be in inputs (optional)
        input :actor

        step :load_resource do
          argument :resource_id, input(:resource_id)

          run fn %{resource_id: id}, context ->
            # ✅ ALWAYS get actor from context
            actor = Map.get(context, :actor)

            # Use actor for Ash operation
            Resource
            |> Ash.get(id, actor: actor)
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

      # Running with actor:
      user = get_current_user()
      actor = build_actor(user)

      inputs = %{
        resource_id: "abc-123",
        actor: actor  # In inputs (optional)
      }

      context = %{
        actor: actor  # In context (REQUIRED)
      }

      {:ok, result} = Reactor.run(MyApp.ActorWorkflow, inputs, context)
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Actor in Compensation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Accessing actor in compensation actions.

  Compensation functions receive context as third argument.
  """
  def example_actor_in_compensation do
    quote do
      defmodule MyApp.CompensationWithActorWorkflow do
        use Reactor

        alias MyApp.DataSource

        input :data

        step :create_data_source do
          argument :data, input(:data)

          run fn %{data: data}, context ->
            # ✅ Get actor from context
            actor = Map.get(context, :actor)

            DataSource
            |> Ash.Changeset.for_create(:create, data, actor: actor)
            |> Ash.create()
          end

          # ✅ Actor available in compensation via context
          compensate fn data_source, _arguments, context ->
            # Get actor from context for rollback
            actor = Map.get(context, :actor)

            data_source
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Actor with Dependencies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Actor propagation through step dependencies.

  Shows how actor flows through multi-step workflows with dependencies.
  """
  def example_actor_dependencies do
    quote do
      defmodule MyApp.MultiStepActorWorkflow do
        use Reactor
        require Logger

        alias MyApp.{Parent, Child, Related}

        input :parent_data

        # Step 1: Create parent resource
        step :create_parent do
          argument :parent_data, input(:parent_data)

          run fn %{parent_data: data}, context ->
            actor = Map.get(context, :actor)

            Logger.info("Creating parent",
              user_id: actor.id,
              organization_id: actor.organization_id
            )

            Parent
            |> Ash.Changeset.for_create(:create, data, actor: actor)
            |> Ash.create()
          end

          compensate fn parent, _arguments, context ->
            actor = Map.get(context, :actor)
            Ash.destroy(parent, actor: actor)
            :ok
          end
        end

        # Step 2: Create child (depends on parent)
        step :create_child do
          argument :parent, result(:create_parent)

          run fn %{parent: parent}, context ->
            actor = Map.get(context, :actor)

            Child
            |> Ash.Changeset.for_create(
              :create,
              %{parent_id: parent.id, name: "Child of #{parent.name}"},
              actor: actor
            )
            |> Ash.create()
          end

          compensate fn child, _arguments, context ->
            actor = Map.get(context, :actor)
            Ash.destroy(child, actor: actor)
            :ok
          end
        end

        # Step 3: Create related (depends on parent)
        step :create_related do
          argument :parent, result(:create_parent)

          run fn %{parent: parent}, context ->
            actor = Map.get(context, :actor)

            Related
            |> Ash.Changeset.for_create(
              :create,
              %{parent_id: parent.id, type: "related"},
              actor: actor
            )
            |> Ash.create()
          end

          compensate fn related, _arguments, context ->
            actor = Map.get(context, :actor)
            Ash.destroy(related, actor: actor)
            :ok
          end
        end
      end

      # Running:
      {:ok, result} =
        Reactor.run(
          MyApp.MultiStepActorWorkflow,
          %{parent_data: %{name: "Test Parent"}},
          %{actor: actor}
        )
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Real-World Pattern from your application Workers
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Building actor from Oban job args.

  Shows complete pattern: job args → actor → workflow context.
  """
  def example_oban_actor_reconstruction do
    quote do
      defmodule MyApp.Jobs.Workers.ExampleWorker do
        use Oban.Worker,
          queue: :default,
          max_attempts: 3

        @impl Oban.Worker
        def perform(%Oban.Job{args: args, attempt: attempt}) do
          # ✅ Oban stores actor as map with string keys
          %{
            "resource_id" => resource_id,
            "actor" => actor_with_string_keys
          } = args

          # ✅ Convert to atom keys for Ash
          actor = atomize_actor_keys(actor_with_string_keys)

          Logger.info("Processing job",
            resource_id: resource_id,
            user_id: actor.id,
            attempt: attempt
          )

          # ✅ Execute workflow with actor in context
          inputs = %{resource_id: resource_id}

          context = %{
            actor: actor,  # ✅ Actor in context
            attempt: attempt
          }

          case Reactor.run(MyWorkflow, inputs, context) do
            {:ok, result} ->
              :ok

            {:error, reason} ->
              {:error, reason}
          end
        end

        # ✅ Convert actor keys from strings to atoms
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

      # Enqueueing job with actor:
      user = get_current_user()
      actor = build_actor(user)

      # ✅ Store actor as map with string keys (Oban serialization)
      %{
        "resource_id" => resource.id,
        "actor" => %{
          "id" => actor.id,
          "organization_id" => actor.organization_id,
          "role" => Atom.to_string(actor.role)
        }
      }
      |> MyApp.Jobs.Workers.ExampleWorker.new()
      |> Oban.insert()
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Actor with External System Operations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Actor in workflows with external system operations.

  Shows actor propagation in workflows that interact with both
  database (Ash resources) and external systems.
  """
  def example_actor_external_ops do
    quote do
      defmodule MyApp.Example.ExternalSystemWorkflow do
        use Reactor
        require Logger

        alias MyApp.Domain.{DataSource, Connection}
        alias MyApp.External.Materializer

        input :connection_id
        input :namespace

        # Step 1: Get connection (Ash resource)
        step :get_connection do
          argument :connection_id, input(:connection_id)

          run fn %{connection_id: id}, context ->
            # ✅ Actor for Ash operation
            actor = Map.get(context, :actor)

            Logger.info("Loading connection",
              connection_id: id,
              user_id: actor.id
            )

            Connection
            |> Ash.get(id, actor: actor)
          end
        end

        # Step 2: Create namespace (external operation, no actor needed)
        step :create_namespace do
          argument :connection, result(:get_connection)
          argument :namespace, input(:namespace)

          run fn %{connection: connection, namespace: ns}, context ->
            actor = Map.get(context, :actor)

            Logger.info("Creating namespace",
              namespace: ns,
              connection_id: connection.id,
              user_id: actor.id
            )

            # External operation (no actor needed - physical operation)
            case Materializer.create_namespace(connection, ns) do
              :ok -> {:ok, ns}
              {:error, reason} -> {:error, reason}
            end
          end

          compensate fn namespace, %{connection: connection}, context ->
            actor = Map.get(context, :actor)

            Logger.warning("Rolling back namespace",
              namespace: namespace,
              user_id: actor.id
            )

            Materializer.drop_namespace(connection, namespace)
            :ok
          end
        end

        # Step 3: Create DataSource (Ash resource, needs actor)
        step :create_data_source do
          argument :connection, result(:get_connection)
          argument :namespace, result(:create_namespace)

          run fn %{connection: connection, namespace: ns}, context ->
            # ✅ Actor for Ash operation
            actor = Map.get(context, :actor)

            Logger.info("Creating DataSource",
              namespace: ns,
              user_id: actor.id,
              organization_id: actor.organization_id
            )

            DataSource
            |> Ash.Changeset.for_create(
              :create,
              %{
                name: "Source #{ns}",
                connection_id: connection.id,
                namespace: ns
              },
              actor: actor
            )
            |> Ash.create()
          end

          compensate fn data_source, _arguments, context ->
            # ✅ Actor for rollback
            actor = Map.get(context, :actor)

            data_source
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Actor Error Handling
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Handling authorization failures gracefully.

  Shows how to detect and handle authorization errors in workflows.
  """
  def example_actor_error_handling do
    quote do
      defmodule MyApp.ActorErrorHandlingWorkflow do
        use Reactor
        require Logger

        alias MyApp.SecureResource

        input :resource_id

        step :load_secure_resource do
          argument :resource_id, input(:resource_id)

          run fn %{resource_id: id}, context ->
            actor = Map.get(context, :actor)

            case SecureResource |> Ash.get(id, actor: actor) do
              {:ok, resource} ->
                Logger.info("Loaded resource",
                  resource_id: id,
                  user_id: actor.id
                )

                {:ok, resource}

              {:error, %Ash.Error.Forbidden{}} ->
                # ✅ Handle authorization failure
                Logger.warning("Access forbidden",
                  resource_id: id,
                  user_id: actor.id,
                  role: actor.role
                )

                {:error, "You don't have permission to access this resource"}

              {:error, %Ash.Error.Query.NotFound{}} ->
                # ✅ NotFound could mean no access OR doesn't exist
                Logger.warning("Resource not found",
                  resource_id: id,
                  user_id: actor.id
                )

                {:error, "Resource not found"}

              {:error, reason} ->
                Logger.error("Unexpected error loading resource",
                  resource_id: id,
                  error: inspect(reason)
                )

                {:error, "Failed to load resource"}
            end
          end
        end

        step :verify_ownership do
          argument :resource, result(:load_secure_resource)

          run fn %{resource: resource}, context ->
            actor = Map.get(context, :actor)

            # ✅ Additional ownership check
            if resource.organization_id == actor.organization_id do
              {:ok, :verified}
            else
              Logger.error("Organization mismatch",
                resource_org: resource.organization_id,
                actor_org: actor.organization_id
              )

              {:error, "Organization mismatch"}
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Actor Propagation Patterns Summary
  # -----------------------------------------------------------------------------

  @doc """
  ## Actor Propagation Best Practices

  ### 1. Actor Structure

  Actor is a map with required fields:
  ```elixir
  actor = %{
    id: user.id,                      # User UUID
    organization_id: user.organization_id,  # Tenant UUID
    role: :admin | :editor | :viewer  # Role atom
  }
  ```

  ### 2. Passing Actor to Workflows

  ✅ ALWAYS pass in context (required):
  ```elixir
  inputs = %{resource_id: id}
  context = %{actor: actor}  # REQUIRED

  Reactor.run(MyWorkflow, inputs, context)
  ```

  ✅ Optionally in inputs (for explicit arguments):
  ```elixir
  inputs = %{resource_id: id, actor: actor}
  context = %{actor: actor}

  Reactor.run(MyWorkflow, inputs, context)
  ```

  ### 3. Accessing Actor in Steps

  ✅ ALWAYS use Map.get/2:
  ```elixir
  run fn arguments, context ->
    actor = Map.get(context, :actor)
    # Use actor...
  end
  ```

  ❌ NEVER use context.actor:
  ```elixir
  run fn arguments, context ->
    actor = context.actor  # WRONG - will crash if missing
  end
  ```

  ### 4. Actor in Compensation

  ✅ Access via third argument:
  ```elixir
  compensate fn result, arguments, context ->
    actor = Map.get(context, :actor)
    cleanup_with_actor(result, actor)
    :ok
  end
  ```

  ### 5. Actor from Oban Jobs

  ✅ Store as map with string keys:
  ```elixir
  # Enqueueing
  %{
    "resource_id" => id,
    "actor" => %{
      "id" => actor.id,
      "organization_id" => actor.organization_id,
      "role" => Atom.to_string(actor.role)
    }
  }
  |> MyWorker.new()
  |> Oban.insert()
  ```

  ✅ Reconstruct in worker:
  ```elixir
  def perform(%Oban.Job{args: args}) do
    actor = %{
      id: args["actor"]["id"],
      organization_id: args["actor"]["organization_id"],
      role: String.to_existing_atom(args["actor"]["role"])
    }

    # Pass to workflow
    Reactor.run(MyWorkflow, inputs, %{actor: actor})
  end
  ```

  ### 6. Multi-Tenant Isolation

  ✅ Actor enforces organization boundaries:
  ```elixir
  # Policy in resource:
  policies do
    policy action_type(:read) do
      authorize_if expr(organization_id == ^actor(:organization_id))
    end
  end

  # Workflow automatically enforces via actor:
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    # This query is automatically scoped to actor's organization
    MyResource
    |> Ash.Query.filter(some_field: value)
    |> Ash.read!(actor: actor)
  end
  ```

  ### 7. Role-Based Permissions

  ✅ Use role for authorization:
  ```elixir
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    # Check role for sensitive operations
    if actor.role in [:admin, :editor] do
      perform_sensitive_operation(actor)
    else
      {:error, "Insufficient permissions"}
    end
  end
  ```

  ### 8. Logging with Actor Context

  ✅ Always include actor in logs:
  ```elixir
  run fn arguments, context ->
    actor = Map.get(context, :actor)

    Logger.info("Starting operation",
      operation: :create_resource,
      user_id: actor.id,
      organization_id: actor.organization_id,
      role: actor.role
    )

    # Perform operation...
  end
  ```
  """
end
