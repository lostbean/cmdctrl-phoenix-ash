defmodule MyApp.Example.TestHelpers do
  @moduledoc """
  Common test helper patterns for your application testing.

  Test helpers should:
  - Create consistent test data
  - Reduce duplication across tests
  - Use authorize?: false for setup (OK in helpers)
  - Provide actor contexts for authorization testing
  - Be reusable and composable

  See: test/support/data_case.ex for actual implementation
  """

  # ============================================================================
  # ✅ CORRECT PATTERNS
  # ============================================================================

  @doc """
  Create test organization with unique slug.

  Uses authorize?: false to bypass policies during test setup.
  This is acceptable in test helpers but not in actual tests.
  """
  def create_test_organization(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Organization",
      slug: "test-org-#{System.unique_integer([:positive])}"  # ✅ Unique per test
    }

    attrs = Map.merge(default_attrs, attrs)

    MyApp.Accounts.Organization
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!(authorize?: false)  # ✅ OK in test helpers
  end

  @doc """
  Create test user with organization context.

  Automatically creates membership with specified role.
  Returns user record with organization relationship.
  """
  def create_test_user(organization, attrs \\ %{}) do
    role = Map.get(attrs, :role, :admin)

    default_attrs = %{
      email: "test-#{System.unique_integer([:positive])}@example.com",
      name: "Test User",
      role: role
    }

    attrs =
      default_attrs
      |> Map.merge(attrs)
      |> Map.put(:organization_id, organization.id)

    # ✅ Create admin actor context to authorize user creation
    admin_actor = %{
      id: Ash.UUID.generate(),
      organization_id: organization.id,
      role: :admin,
      permissions: []
    }

    # User creation with role (membership created by after_action hook)
    MyApp.Accounts.User
    |> Ash.Changeset.for_create(:create, attrs, actor: admin_actor)
    |> Ash.create!()
  end

  @doc """
  Build actor context for authorization testing.

  Uses Auth.Helpers.build_actor for consistency with production code.
  This ensures tests use the same actor structure as the application.
  """
  def build_test_actor(user, organization \\ nil) do
    org_id = if organization, do: organization.id, else: user.organization_id

    # Load membership for the user
    import Ash.Query

    membership =
      MyApp.Accounts.Membership
      |> filter(user_id == ^user.id and organization_id == ^org_id)
      |> Ash.read_one!(authorize?: false)

    # Update user's organization_id if explicitly provided
    user_for_actor =
      if organization do
        Map.put(user, :organization_id, organization.id)
      else
        user
      end

    # ✅ Use production helper for consistency
    MyApp.Auth.Helpers.build_actor(user_for_actor, membership)
  end

  @doc """
  Create test connection with connection config.

  Uses test_connection_config() from config for consistency.
  """
  def create_test_connection(organization, attrs \\ %{}) do
    default_attrs = %{
      name: "Test Connection",
      engine_type: :postgres,
      connection_config: test_connection_config(),
      organization_id: organization.id
    }

    attrs = Map.merge(default_attrs, attrs)

    MyApp.Domain.Connection
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create!(authorize?: false)
  end

  @doc """
  Returns standard test database connection configuration.

  Centralized in config/test.exs for consistency across all tests.
  """
  def test_connection_config do
    :my_app
    |> Application.fetch_env!(:connection_test_config)
    |> Enum.into(%{})
  end

  @doc """
  Create test resource with optional sample data.

  Demonstrates composable helpers that build on each other.
  """
  def create_test_resource(connection, user, opts \\ []) do
    with_sample_data = Keyword.get(opts, :with_sample_data, false)
    actor = build_test_actor(user)

    resource_attrs = %{
      name: "Test Resource #{System.unique_integer([:positive])}",
      description: "Test resource",
      connection_id: connection.id
    }

    {:ok, resource} =
      MyApp.Domain.Resource
      |> Ash.Changeset.for_create(:create, resource_attrs, actor: actor)
      |> Ash.create()

    if with_sample_data do
      # Load versions and update with sample data
      resource = Ash.load!(resource, [:versions, :active_version], actor: actor)
      version = resource.active_version

      sample_data = %{
        items: [
          %{
            id: Ash.UUID.generate(),
            name: "Customer",
            properties: [
              %{name: "id", data_type: "integer"},
              %{name: "name", data_type: "string"}
            ]
          }
        ],
        relationships: []
      }

      {:ok, updated_version} =
        version
        |> Ash.Changeset.for_update(:update, %{data: sample_data}, actor: actor)
        |> Ash.update()

      Map.put(resource, :latest_version, updated_version)
    else
      resource
    end
  end

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Use authorize?: false in actual tests
  #
  # test "creates user" do
  #   User
  #   |> Ash.Changeset.for_create(:create, attrs)
  #   |> Ash.create!(authorize?: false)  # ❌ Bypasses important logic
  # end
  #
  # ✅ DO: Use it only in test helpers
  #
  # def create_test_user(...) do
  #   User |> ... |> Ash.create!(authorize?: false)  # ✅ OK in helper
  # end

  # ❌ DON'T: Create actors without membership
  #
  # def bad_build_actor(user) do
  #   %{
  #     id: user.id,
  #     organization_id: user.organization_id,
  #     role: :admin  # ❌ What if user is not admin?
  #   }
  # end
  #
  # ✅ DO: Load membership and use production helper
  #
  # def build_test_actor(user) do
  #   membership = load_membership(user)
  #   Auth.Helpers.build_actor(user, membership)  # ✅ Consistent with prod
  # end

  # ❌ DON'T: Hard-code test data
  #
  # def create_test_org do
  #   Organization |> ... |> Ash.create!(%{slug: "test-org"})
  #   # ❌ Fails if run twice (unique constraint)
  # end
  #
  # ✅ DO: Generate unique data
  #
  # def create_test_org do
  #   slug = "test-org-#{System.unique_integer([:positive])}"
  #   Organization |> ... |> Ash.create!(%{slug: slug})  # ✅ Always unique
  # end

  # ============================================================================
  # COMPOSABILITY PATTERNS
  # ============================================================================

  @doc """
  Create complete test context with all dependencies.

  Demonstrates composing helpers for complex setup.
  """
  def create_test_context(opts \\ []) do
    # Create base resources
    org = create_test_organization()
    user = create_test_user(org, opts[:user_attrs] || %{})
    actor = build_test_actor(user, org)
    connection = create_test_connection(org)

    # Optionally create resource
    resource =
      if opts[:with_resource] do
        create_test_resource(connection, user, with_sample_data: true)
      end

    # Return context map for use in tests
    %{
      organization: org,
      user: user,
      actor: actor,
      connection: connection,
      resource: resource
    }
  end

  # Usage in tests:
  #
  # setup do
  #   create_test_context(with_resource: true)
  # end
  #
  # test "uses complete context", %{actor: actor, resource: resource} do
  #   # All dependencies created automatically
  # end

  # ============================================================================
  # FACTORY PATTERN (Alternative)
  # ============================================================================

  # Some teams prefer ExMachina for factories:
  #
  # defmodule MyApp.Factory do
  #   use ExMachina.Ecto, repo: MyApp.Repo
  #
  #   def organization_factory do
  #     %MyApp.Accounts.Organization{
  #       name: "Test Org",
  #       slug: sequence(:slug, &"org-#{&1}")
  #     }
  #   end
  #
  #   def user_factory do
  #     %MyApp.Accounts.User{
  #       email: sequence(:email, &"user-#{&1}@example.com"),
  #       name: "Test User",
  #       organization: build(:organization)
  #     }
  #   end
  # end
  #
  # Usage:
  # user = insert(:user)
  # user_with_role = insert(:user, role: :admin)

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  # ✅ Make helpers flexible with optional attributes
  def flexible_helper(required_arg, optional_attrs \\ %{}) do
    default_attrs = %{field1: "default", field2: "default"}
    attrs = Map.merge(default_attrs, optional_attrs)
    # Create resource with merged attrs
  end

  # ✅ Return loaded resources when needed
  def create_with_relationships(attrs) do
    resource = create_resource(attrs)
    # ✅ Load relationships that tests commonly need
    Ash.load!(resource, [:relationship1, :relationship2])
  end

  # ✅ Provide cleanup helpers for E2E tests
  def cleanup_test_data(organization_id) do
    # Delete all test data for organization
    MyApp.Repo.query!("""
    DELETE FROM organizations WHERE id = $1
    """, [organization_id])
  end

  # ✅ Document helper behavior
  @doc """
  Create draft with active status.

  Automatically archives any existing active draft for the version
  to avoid unique constraint violations.

  Returns: Draft with status: :active
  """
  def create_test_draft(user, resource_version) do
    # Implementation...
  end
end
