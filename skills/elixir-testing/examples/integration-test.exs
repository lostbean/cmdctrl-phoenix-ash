defmodule MyApp.Example.IntegrationTest do
  @moduledoc """
  Example of an integration test pattern with Ash Framework and database.

  Integration tests verify:
  - Ash resource CRUD operations
  - Multi-component workflows
  - Database persistence
  - Policy enforcement
  - Actor-based authorization

  Use for: Resource actions, workflows, database operations, authorization
  """

  use MyApp.DataCase, async: true  # ✅ Database tests can be async with sandbox

  alias MyApp.Domain.{Resource, Connection}

  # ============================================================================
  # ✅ CORRECT PATTERNS
  # ============================================================================

  describe "Resource creation" do
    setup do
      # Create test organization and user with proper actor context
      organization = create_test_organization(%{
        name: "Test Organization",
        slug: "test-org-#{System.unique_integer([:positive])}"
      })

      user = create_test_user(organization, %{
        email: "test@example.com",
        name: "Test User",
        role: :editor
      })

      actor = build_test_actor(user, organization)

      # Create connection for resource
      {:ok, connection} =
        Connection
        |> Ash.Changeset.for_create(:create, %{
          name: "Test Connection",
          engine_type: :postgres,
          connection_config: test_connection_config(),
          organization_id: organization.id
        }, actor: actor)
        |> Ash.create()

      %{organization: organization, user: user, actor: actor, connection: connection}
    end

    test "creates resource with valid attributes", %{actor: actor, connection: connection} do
      attrs = %{
        name: "Test Resource",
        description: "A test resource",
        connection_id: connection.id
      }

      # ✅ Always provide actor context for authorization
      assert {:ok, resource} =
        Resource
        |> Ash.Changeset.for_create(:create, attrs, actor: actor)
        |> Ash.create()

      assert resource.name == "Test Resource"
      assert resource.description == "A test resource"
      assert resource.connection_id == connection.id
    end

    test "requires name field", %{connection: connection} do
      attrs = %{
        description: "Missing name",
        connection_id: connection.id
      }

      # ✅ Test validation errors
      assert {:error, error} =
        Resource
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(authorize?: false)  # ✅ OK to bypass auth in tests

      assert %Ash.Error.Invalid{} = error
    end

    test "auto-creates initial version", %{actor: actor, connection: connection} do
      {:ok, resource} =
        Resource
        |> Ash.Changeset.for_create(:create, %{
          name: "Test Resource",
          connection_id: connection.id
        }, actor: actor)
        |> Ash.create()

      # ✅ Load relationships to verify cascading creation
      resource_with_versions = Ash.load!(resource, [:versions, :active_version], actor: actor)

      assert length(resource_with_versions.versions) == 1
      assert not is_nil(resource_with_versions.active_version_id)

      initial_version = List.first(resource_with_versions.versions)
      assert initial_version.version_number == 1
      assert initial_version.commit_message == "Initial version"
    end
  end

  describe "authorization policies" do
    test "enforces organization isolation" do
      # Create two separate organizations
      org1 = create_test_organization(%{slug: "org-1"})
      org2 = create_test_organization(%{slug: "org-2"})

      user1 = create_test_user(org1, %{role: :editor})
      user2 = create_test_user(org2, %{role: :editor})

      actor1 = build_test_actor(user1, org1)
      actor2 = build_test_actor(user2, org2)

      # Create connection in org1
      {:ok, connection1} =
        Connection
        |> Ash.Changeset.for_create(:create, %{
          name: "Connection 1",
          engine_type: :postgres,
          connection_config: test_connection_config(),
          organization_id: org1.id
        }, actor: actor1)
        |> Ash.create()

      # Create resource in org1
      {:ok, resource1} =
        Resource
        |> Ash.Changeset.for_create(:create, %{
          name: "Resource 1",
          connection_id: connection1.id
        }, actor: actor1)
        |> Ash.create()

      # ✅ User from org2 should NOT be able to read org1's resource
      result = Resource
        |> Ash.Query.filter(id == ^resource1.id)
        |> Ash.read(actor: actor2)

      assert {:ok, []} = result  # Empty list due to policy filtering
    end

    test "role-based access control", %{organization: organization} do
      # Create users with different roles
      admin = create_test_user(organization, %{role: :admin})
      editor = create_test_user(organization, %{role: :editor})
      viewer = create_test_user(organization, %{role: :viewer})

      admin_actor = build_test_actor(admin, organization)
      editor_actor = build_test_actor(editor, organization)
      viewer_actor = build_test_actor(viewer, organization)

      # ✅ Test that different roles have appropriate access
      # (Actual permissions depend on your policy implementation)

      # Example: Viewer can read but not create
      {:ok, connections} = Connection |> Ash.read(actor: viewer_actor)
      assert is_list(connections)

      # Viewer cannot create (if policy forbids)
      # assert {:error, %Ash.Error.Forbidden{}} =
      #   Connection
      #   |> Ash.Changeset.for_create(:create, attrs, actor: viewer_actor)
      #   |> Ash.create()
    end
  end

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Use authorize?: false in production-like tests
  # Only use it for test data setup, not for testing actual behavior
  #
  # test "creates resource" do
  #   Resource
  #   |> Ash.Changeset.for_create(:create, attrs)
  #   |> Ash.create(authorize?: false)  # ❌ Bypasses important authorization logic
  # end

  # ❌ DON'T: Forget to test both success and error paths
  #
  # test "creates resource" do
  #   assert {:ok, _} = create_resource(valid_attrs)
  #   # ❌ Missing: Test with invalid attrs, unauthorized user, etc.
  # end

  # ❌ DON'T: Create test data without proper actor context
  #
  # test "creates user" do
  #   User
  #   |> Ash.Changeset.for_create(:create, attrs)
  #   |> Ash.create()  # ❌ Missing actor context
  # end

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  describe "workflow integration" do
    test "complete CRUD cycle", %{actor: actor, connection: connection} do
      # Create
      {:ok, resource} =
        Resource
        |> Ash.Changeset.for_create(:create, %{
          name: "Original Name",
          connection_id: connection.id
        }, actor: actor)
        |> Ash.create()

      # Read
      {:ok, found} = Resource |> Ash.get(resource.id, actor: actor)
      assert found.name == "Original Name"

      # Update
      {:ok, updated} =
        resource
        |> Ash.Changeset.for_update(:update, %{
          name: "Updated Name"
        }, actor: actor)
        |> Ash.update()

      assert updated.name == "Updated Name"

      # ✅ Verify persistence
      {:ok, reloaded} = Resource |> Ash.get(resource.id, actor: actor)
      assert reloaded.name == "Updated Name"
    end
  end

  # ============================================================================
  # NOTES
  # ============================================================================

  # Integration tests should cover:
  # - Happy path workflows
  # - Error handling and validation
  # - Authorization policies
  # - Multi-tenant isolation
  # - Relationship cascades
  # - Database constraints
  #
  # Aim for ~20% of your test suite to be integration tests.
  # They're slower than unit tests but verify real behavior.
end
