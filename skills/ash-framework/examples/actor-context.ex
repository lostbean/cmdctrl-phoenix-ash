defmodule AshSkill.Examples.ActorContext do
  @moduledoc """
  Self-contained examples of actor context propagation in Ash Framework.

  Actor context is the most critical pattern in your application - it carries user identity
  and permissions through every operation for multi-tenant security.

  ## Related Files
  - ../reference/actor-context.md - Deep dive on actor patterns
  - DESIGN/concepts/actor-context.md - Project architecture
  - DESIGN/security/authorization.md - Authorization implementation
  """

  # -----------------------------------------------------------------------------
  # Example 1: Building Actor Context
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Build actor from authenticated user at entry point.

  The actor map contains:
  - id: User UUID
  - organization_id: Tenant boundary
  - role: :admin, :editor, or :viewer
  - permissions: Future granular permissions
  """
  def build_actor_from_user(user) do
    %{
      id: user.id,
      organization_id: user.organization_id,
      role: user.role,
      permissions: user.permissions || []
    }
  end

  # -----------------------------------------------------------------------------
  # Example 2: Actor in Resource Actions (Create)
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Pass actor explicitly when creating resources.

  This ensures:
  - Policies check organization membership
  - Role-based permissions enforced
  - Audit trails maintained
  """
  def create_connection_with_actor(user, connection_attrs) do
    actor = build_actor_from_user(user)

    MyApp.Domain.Connection
    |> Ash.Changeset.for_create(:create, connection_attrs, actor: actor)
    |> Ash.create()
  end

  @doc """
  ❌ WRONG: Never bypass authorization in production code.

  This allows:
  - Cross-tenant data access
  - Privilege escalation
  - No audit trail
  """
  def create_connection_without_actor_WRONG(connection_attrs) do
    # NEVER DO THIS IN PRODUCTION!
    MyApp.Domain.Connection
    |> Ash.Changeset.for_create(:create, connection_attrs)
    |> Ash.create(authorize?: false)
  end

  # -----------------------------------------------------------------------------
  # Example 3: Actor in Resource Actions (Read)
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Read operations filter by organization automatically.

  Ash policies add WHERE organization_id = actor.organization_id automatically.
  """
  def list_connections_for_user(user) do
    actor = build_actor_from_user(user)

    MyApp.Domain.Connection
    |> Ash.Query.for_read(:read, %{}, actor: actor)
    |> Ash.read()
  end

  # -----------------------------------------------------------------------------
  # Example 4: Actor in Resource Actions (Update)
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Update with actor enforces ownership and role checks.
  """
  def update_connection_name(connection, new_name, user) do
    actor = build_actor_from_user(user)

    connection
    |> Ash.Changeset.for_update(:update, %{name: new_name}, actor: actor)
    |> Ash.update()
  end

  # -----------------------------------------------------------------------------
  # Example 5: Actor in Change Functions
  # -----------------------------------------------------------------------------

  @doc """
  Example change function showing actor access from context.

  Change functions receive context as third parameter containing actor.
  """
  def example_change_function(changeset, _opts, context) do
    # ✅ CORRECT: Access actor from context parameter
    case Map.get(context, :actor) do
      nil ->
        Ash.Changeset.add_error(changeset, "Actor required")

      actor ->
        changeset
        |> Ash.Changeset.change_attribute(:created_by_id, actor.id)
        |> Ash.Changeset.change_attribute(:organization_id, actor.organization_id)
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Actor in After-Action Hooks
  # -----------------------------------------------------------------------------

  @doc """
  Example after-action hook showing actor access from context parameter.

  IMPORTANT: The context parameter contains actor, not changeset!
  """
  def example_after_action(changeset, resource, context) do
    # ✅ CORRECT: Access actor from context parameter (3rd param)
    case Map.get(context, :actor) do
      nil ->
        {:error, "Actor required"}

      actor ->
        # Create related resource with same actor
        related_attrs = %{
          resource_id: resource.id,
          organization_id: actor.organization_id
        }

        RelatedResource
        |> Ash.Changeset.for_create(:create, related_attrs, actor: actor)
        |> Ash.create()

        {:ok, resource}
    end
  end

  # ❌ WRONG: Common mistake - trying to access actor from changeset
  def example_after_action_WRONG(changeset, resource, context) do
    # This won't work - actor is in context, not changeset!
    actor = changeset.context[:actor]  # Wrong!
    # ...
  end

  # -----------------------------------------------------------------------------
  # Example 7: Actor in Reactor Workflows
  # -----------------------------------------------------------------------------

  @doc """
  Example Reactor step showing actor propagation from context.

  Workflows receive actor in context map and pass it to nested operations.
  """
  def example_reactor_step do
    """
    # In a Reactor workflow definition:

    step :create_data_source do
      run fn arguments, context ->
        # ✅ CORRECT: Get actor from context
        actor = Map.get(context, :actor)

        DataSource
        |> Ash.Changeset.for_create(:create, %{name: arguments.name}, actor: actor)
        |> Ash.create()
      end

      argument :name, input(:data_source_name)
    end

    # When running the workflow:
    inputs = %{data_source_name: "My Data Source"}
    Reactor.run(MyWorkflow, inputs, %{actor: actor})  # ✅ Pass actor in context
    """
  end

  # -----------------------------------------------------------------------------
  # Example 8: Actor in Background Jobs (Oban)
  # -----------------------------------------------------------------------------

  @doc """
  Example Oban worker showing actor reconstruction from job args.

  IMPORTANT: Don't serialize entire actor - store user_id and rebuild.
  """
  def example_oban_worker do
    """
    defmodule MyWorker do
      use Oban.Worker, queue: :default

      @impl Oban.Worker
      def perform(%Oban.Job{args: args}) do
        # ✅ CORRECT: Rebuild actor from user_id
        user = MyApp.Accounts.User.get!(args["user_id"])
        actor = build_actor_from_user(user)

        # Use actor in operations
        process_resource(args["resource_id"], actor)
      end
    end

    # Enqueue with user_id (not full actor):
    %{
      "user_id" => user.id,
      "resource_id" => resource.id
    }
    |> MyWorker.new()
    |> Oban.insert()
    """
  end

  # -----------------------------------------------------------------------------
  # Example 9: Actor in LiveView
  # -----------------------------------------------------------------------------

  @doc """
  Example LiveView showing actor in socket assigns.
  """
  def example_liveview do
    """
    defmodule MyLive do
      use MyAppWeb, :live_view

      @impl true
      def mount(_params, %{"user_id" => user_id}, socket) do
        # ✅ Build actor at mount and store in assigns
        user = MyApp.Accounts.User.get!(user_id)
        actor = build_actor_from_user(user)

        {:ok, assign(socket, :actor, actor)}
      end

      @impl true
      def handle_event("create", params, socket) do
        # ✅ Use actor from socket assigns
        actor = socket.assigns.actor

        case MyResource
          |> Ash.Changeset.for_create(:create, params, actor: actor)
          |> Ash.create() do
          {:ok, resource} ->
            {:noreply, socket}

          {:error, error} ->
            {:noreply, put_flash(socket, :error, "Failed")}
        end
      end
    end
    """
  end

  # -----------------------------------------------------------------------------
  # Example 10: System Actor (Special Case)
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Use system actor for authentication bootstrap.

  System actor is ONLY for:
  - Loading user from session during authentication
  - Creating organization during registration
  - Test fixtures (prefer authorize?: false)

  System actor has system?: true flag and limited policy access.
  """
  def load_user_for_authentication(user_id) do
    import MyApp.Auth.SystemActor

    # ✅ System actor allowed for authentication bootstrap
    MyApp.Accounts.User
    |> Ash.get(user_id, actor: system_actor(), action: :load_for_authentication)
  end

  # ❌ WRONG: Using system actor for regular operations
  def create_connection_with_system_actor_WRONG(attrs) do
    import MyApp.Auth.SystemActor

    # NEVER USE SYSTEM ACTOR FOR BUSINESS LOGIC!
    MyApp.Domain.Connection
    |> Ash.Changeset.for_create(:create, attrs, actor: system_actor())
    |> Ash.create()
  end

  # -----------------------------------------------------------------------------
  # Example 11: Actor in Tests
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Test patterns for actor context.

  - Setup: Use authorize?: false for test data creation
  - Tests: Always pass proper actor to verify authorization
  """
  def example_test do
    """
    defmodule MyResourceTest do
      use MyApp.DataCase, async: true

      describe "create action" do
        test "user can create resource in their organization" do
          # Setup: Create test data without authorization
          org = create_test_organization()
          user = create_test_user(org, %{role: :editor})

          # Build actor for test
          actor = build_test_actor(user)

          # Test: Use actor to verify authorization works
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

          # Try to create in org_b with org_a user
          assert {:error, %Ash.Error.Forbidden{}} =
            MyResource
            |> Ash.Changeset.for_create(
              :create,
              %{name: "Test", organization_id: org_b.id},
              actor: actor_a
            )
            |> Ash.create()
        end
      end
    end

    # Test helper for building actors:
    def build_test_actor(user, role \\\\ nil) do
      %{
        id: user.id,
        organization_id: user.organization_id,
        role: role || user.role,
        permissions: []
      }
    end
    """
  end

  # -----------------------------------------------------------------------------
  # Example 12: Context Setting in Changesets
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Pass context during changeset creation.

  CRITICAL: Context must be set during for_create/for_update call,
  not afterward via set_context/2 (which may be lost).
  """
  def create_with_context_CORRECT(attrs, actor) do
    Connection
    |> Ash.Changeset.for_create(
      :create,
      attrs,
      actor: actor,
      context: %{skip_validation: true}  # ✅ Context set during creation
    )
    |> Ash.create()
  end

  @doc """
  ❌ WRONG: Setting context after changeset creation may not work.

  Ash may recreate changesets during processing, losing context set afterward.
  """
  def create_with_context_WRONG(attrs, actor) do
    Connection
    |> Ash.Changeset.for_create(:create, attrs, actor: actor)
    |> Ash.Changeset.set_context(%{skip_validation: true})  # ❌ May be lost!
    |> Ash.create()
  end

  # -----------------------------------------------------------------------------
  # Common Pitfalls and Solutions
  # -----------------------------------------------------------------------------

  @doc """
  ## Common Pitfall #1: Forgetting Actor in Nested Operations

  ❌ Problem:
  ```
  def create_with_related(attrs, actor) do
    with {:ok, parent} <- create_parent(attrs, actor) do
      # Forgot to pass actor to child creation!
      create_child(%{parent_id: parent.id})  # ❌ No actor!
    end
  end
  ```

  ✅ Solution:
  ```
  def create_with_related(attrs, actor) do
    with {:ok, parent} <- create_parent(attrs, actor) do
      # Always pass actor through
      create_child(%{parent_id: parent.id}, actor)  # ✅ Actor passed
    end
  end
  ```

  ## Common Pitfall #2: Mixing Authorized and Unauthorized Operations

  ❌ Problem:
  ```
  def mixed_operations(attrs, actor) do
    # Mix of authorized and unauthorized operations
    {:ok, user} = User |> Ash.get(id, actor: actor)
    uploads = Upload |> Ash.read!(authorize?: false)  # ❌ Bypass!
  end
  ```

  ✅ Solution: Always use actor consistently
  ```
  def consistent_operations(attrs, actor) do
    with {:ok, user} <- User |> Ash.get(id, actor: actor),
         {:ok, uploads} <- Upload |> Ash.read(actor: actor) do
      # All operations use actor
    end
  end
  ```

  ## Common Pitfall #3: Silent Fallback on Authorization Failure

  ❌ Problem:
  ```
  case Resource |> Ash.get(id, actor: actor) do
    {:ok, resource} -> {:ok, resource}
    {:error, _} -> Resource |> Ash.get!(id, authorize?: false)  # ❌ Bypass!
  end
  ```

  ✅ Solution: Handle errors properly without bypassing
  ```
  case Resource |> Ash.get(id, actor: actor) do
    {:ok, resource} -> {:ok, resource}
    {:error, %Ash.Error.Forbidden{}} -> {:error, :not_found}  # Security
    {:error, error} -> {:error, error}
  end
  ```
  """
end
