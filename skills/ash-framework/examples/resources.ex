defmodule AshSkill.Examples.Resources do
  @moduledoc """
  Self-contained examples of Ash Resource definitions.

  Resources are the foundation of Ash Framework - declarative domain models
  that define attributes, relationships, actions, and policies in one place.

  ## Related Files
  - ../reference/resources.md - Deep dive on resource patterns
  - DESIGN/concepts/resources.md - Resource architecture
  - lib/my_app/**/resources/*.ex - Real resource examples
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Resource Structure
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Minimal resource with essential elements.

  Every resource needs:
  - use Ash.Resource with domain and data_layer
  - Primary key (usually uuid_primary_key)
  - At least one action (usually defaults [:read])
  - Policies for authorization
  """
  def example_basic_resource do
    quote do
      defmodule MyApp.BasicResource do
        use Ash.Resource,
          domain: MyApp.MyDomain,
          data_layer: AshPostgres.DataLayer,
          authorizers: [Ash.Policy.Authorizer]

        postgres do
          table "basic_resources"
          repo MyApp.Repo
        end

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          timestamps()
        end

        actions do
          defaults [:read]
        end

        policies do
          policy action_type(:read) do
            authorize_if always()
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Multi-Tenant Resource
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with organization-scoped multi-tenancy.

  Multi-tenant resources:
  - Have belongs_to :organization relationship
  - Organization is required (allow_nil?: false)
  - Policies check organization_id
  - Database has foreign key with on_delete behavior
  """
  def example_multi_tenant_resource do
    quote do
      defmodule MyApp.Connection do
        use Ash.Resource,
          domain: MyApp.DataPipeline,
          data_layer: AshPostgres.DataLayer,
          authorizers: [Ash.Policy.Authorizer]

        postgres do
          table "connections"
          repo MyApp.Repo

          references do
            reference :organization, on_delete: :delete
          end
        end

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          attribute :status, :atom, default: :active
          timestamps()
        end

        relationships do
          belongs_to :organization, MyApp.Organization do
            allow_nil?: false
            attribute_writable? true
          end

          has_many :data_sources, MyApp.DataSource do
            destination_attribute :connection_id
          end
        end

        actions do
          defaults [:read, :destroy]

          create :create do
            accept [:name, :status, :organization_id]
          end

          update :update do
            accept [:name, :status]
          end
        end

        policies do
          policy action_type(:read) do
            authorize_if expr(organization_id == ^actor(:organization_id))
          end

          policy action_type(:create) do
            forbid_if expr(^actor(:role) not in [:admin, :editor])
            authorize_if changing_attributes(
              organization_id: [to: {:_actor, :organization_id}]
            )
          end

          policy action_type(:update) do
            authorize_if expr(
              organization_id == ^actor(:organization_id) and
              ^actor(:role) in [:admin, :editor]
            )
          end

          policy action_type(:destroy) do
            authorize_if expr(
              organization_id == ^actor(:organization_id) and
              ^actor(:role) == :admin
            )
          end
        end

        identities do
          identity :unique_name_per_org, [:name, :organization_id]
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Resource with Custom Actions
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with custom actions beyond CRUD.

  Custom actions can:
  - Accept specific arguments
  - Have custom validations
  - Execute complex business logic
  - Return custom data structures (for generic actions)
  """
  def example_custom_actions do
    quote do
      defmodule MyApp.User do
        use Ash.Resource,
          domain: MyApp.Accounts,
          data_layer: AshPostgres.DataLayer

        attributes do
          uuid_primary_key :id
          attribute :email, :string, allow_nil?: false
          attribute :name, :string
          attribute :role, :atom
          timestamps()
        end

        actions do
          defaults [:read]

          # Custom create action with specific logic
          create :invite do
            description "Invite a new user (admin only)"
            accept [:email, :name, :organization_id]
            argument :role, :atom, allow_nil?: false

            validate present(:email)
            validate present(:name)

            # Send invitation email after creation
            change after_action(fn changeset, user, context ->
              send_invitation_email(user)
              {:ok, user}
            end)
          end

          # Custom update action
          update :update_last_seen do
            accept []
            change set_attribute(:last_seen_at, &DateTime.utc_now/0)
          end

          # Generic action returning custom data
          action :get_statistics, :map do
            description "Get user statistics"

            argument :user_id, :uuid, allow_nil?: false

            run fn input, context ->
              # Can return any data structure
              {:ok, %{
                total_logins: 42,
                last_login: DateTime.utc_now()
              }}
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Resource with Validations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with various validation types.

  Validations ensure data integrity:
  - present/1 - Field must have value
  - match/2 - Field must match regex
  - Custom validation functions
  - Validation modules
  """
  def example_validations do
    quote do
      defmodule MyApp.Connection do
        actions do
          create :create do
            accept [:name, :engine_type, :connection_config]

            # Built-in validations
            validate present(:name)
            validate present(:engine_type)
            validate present(:connection_config)

            # Regex validation
            validate match(:name, ~r/^[a-zA-Z0-9_-]+$/) do
              message "must contain only letters, numbers, underscores, and hyphens"
            end

            # Custom validation function
            validate fn changeset, _context ->
              name = Ash.Changeset.get_attribute(changeset, :name)

              if String.length(name) < 3 do
                {:error, field: :name, message: "must be at least 3 characters"}
              else
                :ok
              end
            end

            # Validation module
            validate {MyApp.Validations.ValidConnectionConfig, field: :connection_config}
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Resource with Change Functions
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with change functions for transformations.

  Changes modify the changeset during action processing:
  - Set computed values
  - Transform input
  - Create related records
  - Trigger side effects
  """
  def example_changes do
    quote do
      defmodule MyApp.Draft do
        actions do
          create :create do
            accept [:name, :version_id]

            # Change function to set created_by_id from actor
            change fn changeset, context ->
              case Map.get(context, :actor) do
                nil ->
                  Ash.Changeset.add_error(changeset, "Actor required")

                actor ->
                  changeset
                  |> Ash.Changeset.change_attribute(:created_by_id, actor.id)
                  |> Ash.Changeset.change_attribute(:status, :active)
              end
            end

            # After-action hook to create related record
            change after_action(fn changeset, draft, context ->
              actor = Map.get(context, :actor)

              # Create audit log
              {:ok, _log} =
                AuditLog
                |> Ash.Changeset.for_create(:create, %{
                  resource_type: "draft",
                  resource_id: draft.id,
                  action: "created",
                  user_id: actor.id
                }, actor: actor)
                |> Ash.create()

              {:ok, draft}
            end)
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Embedded Resources
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Embedded resources for nested data.

  Embedded resources:
  - Don't have their own table
  - Are stored as JSON in parent resource
  - Can have their own attributes and validations
  - Used for component data that doesn't exist independently
  """
  def example_embedded_resource do
    quote do
      # Embedded resource definition
      defmodule MyApp.Property do
        use Ash.Resource,
          data_layer: :embedded

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          attribute :type, :atom, allow_nil?: false
          attribute :data_type, :atom
          attribute :description, :string
        end

        actions do
          defaults [:create, :read, :update, :destroy]
        end
      end

      # Parent resource using embedded resource
      defmodule MyApp.Entity do
        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false

          # Embedded resource as attribute
          attribute :properties, {:array, MyApp.Property}, default: []
        end

        actions do
          create :create do
            # CRITICAL: Validate embedded data before creating struct
            change fn changeset, context ->
              property_data = Ash.Changeset.get_argument(changeset, :property)

              case MyApp.Property
                   |> Ash.Changeset.for_create(:create, property_data) do
                %{valid?: true} ->
                  # Safe to create struct
                  property = struct(MyApp.Property, property_data)
                  properties = [property | (changeset.data.properties || [])]

                  Ash.Changeset.change_attribute(changeset, :properties, properties)

                %{valid?: false} = prop_changeset ->
                  # Add validation errors
                  Enum.reduce(prop_changeset.errors, changeset, fn error, acc ->
                    Ash.Changeset.add_error(acc, error)
                  end)
              end
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 7: Resource with Calculations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with calculated attributes.

  Calculations derive values from existing data:
  - Computed on read (not stored)
  - Can use Ash.Query expressions
  - Can have custom calculation functions
  """
  def example_calculations do
    quote do
      defmodule MyApp.AnalyticsChat do
        calculations do
          # Simple expression calculation
          calculate :prompt_count, :integer, expr(count(prompts))

          # Calculation with custom function
          calculate :last_activity, :utc_datetime do
            calculation fn records, _context ->
              Enum.map(records, fn chat ->
                last_prompt =
                  Enum.max_by(chat.prompts || [], & &1.inserted_at, fn -> nil end)

                {:ok, last_prompt && last_prompt.inserted_at}
              end)
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 8: Resource with Aggregates
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with aggregates from relationships.

  Aggregates summarize related data:
  - count, sum, avg, min, max
  - list (collect values)
  - first, last
  """
  def example_aggregates do
    quote do
      defmodule MyApp.Organization do
        aggregates do
          # Count related records
          count :user_count, :users

          # Max value from related records
          max :last_user_login, :users, :last_seen_at

          # Collect unique values
          list :user_roles, :users, :role do
            uniq? true
          end

          # Sum numeric values
          sum :total_storage_bytes, :uploads, :size_bytes
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 9: Resource with Identities
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with uniqueness constraints.

  Identities enforce uniqueness:
  - Can be composite (multiple fields)
  - Can be conditional (with where clause)
  - Create database unique indexes
  """
  def example_identities do
    quote do
      defmodule MyApp.Connection do
        identities do
          # Composite uniqueness within organization
          identity :unique_name_per_org, [:name, :organization_id]
        end
      end

      defmodule MyApp.Draft do
        identities do
          # Conditional uniqueness (partial index)
          identity :unique_active_per_version, [:version_id] do
            where expr(status == :active)
          end
        end

        postgres do
          # Map identity to SQL for partial index
          identity_wheres_to_sql unique_active_per_version: "status = 'active'"
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 10: Resource with Error Handling
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Resource with custom error handling.

  Error handlers transform database/system errors into user-friendly messages.
  """
  def example_error_handling do
    quote do
      defmodule MyApp.Draft do
        actions do
          create :create do
            # Custom error handler for unique constraint violations
            error_handler fn changeset, error ->
              case error do
                %Ecto.ConstraintError{constraint: "drafts_unique_active_per_version"} ->
                  Ash.Changeset.add_error(
                    changeset,
                    field: :version_id,
                    message: "only one active draft allowed per version"
                  )

                # Check for error in Ash.Error.Unknown wrapper
                %Ash.Error.Unknown{errors: [%Ash.Error.Unknown.UnknownError{error: error_string}]}
                when is_binary(error_string) ->
                  if String.contains?(error_string, "drafts_unique_active_per_version") do
                    Ash.Changeset.add_error(
                      changeset,
                      field: :version_id,
                      message: "only one active draft allowed per version"
                    )
                  else
                    error
                  end

                _ ->
                  error
              end
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Common Resource Patterns
  # -----------------------------------------------------------------------------

  @doc """
  ## Pattern #1: UUID-Based Identity vs Name-Based Description

  ✅ Use UUIDs as immutable identifiers:
  - Primary keys are UUIDs
  - Foreign keys use UUIDs
  - Tool parameters use UUIDs

  ✅ Names are descriptive, mutable labels:
  - Can be duplicated (no unique constraint on name alone)
  - User-friendly
  - Can be changed without breaking references

  ```elixir
  identities do
    # ✅ Unique within organization (UUID + name)
    identity :unique_name_per_org, [:name, :organization_id]
  end

  # ❌ AVOID: Unique name globally
  # identity :unique_name, [:name]
  ```

  ## Pattern #2: Immutability Pattern

  ✅ Core data is immutable (versioned):
  - Version records are never updated
  - Edits create new versions
  - Chat sessions lock to specific versions

  ✅ Drafts are temporary workspaces:
  - Mutable until saved
  - Publishing creates immutable version
  - Discarding deletes draft

  ## Pattern #3: Context Setting in Actions

  ✅ CRITICAL: Set context during changeset creation:

  ```elixir
  # ✅ CORRECT
  Resource
  |> Ash.Changeset.for_create(
    :create,
    attrs,
    actor: actor,
    context: %{skip_validation: true}  # Set here
  )
  |> Ash.create()

  # ❌ WRONG - May be lost
  Resource
  |> Ash.Changeset.for_create(:create, attrs, actor: actor)
  |> Ash.Changeset.set_context(%{skip_validation: true})  # Too late
  |> Ash.create()
  ```

  ## Pattern #4: Relationship Configuration

  ✅ Configure relationships for data integrity:

  ```elixir
  relationships do
    belongs_to :organization, MyApp.Organization do
      allow_nil?: false  # Required
      attribute_writable? true  # Can set via attributes
    end

    has_many :children, MyApp.Child do
      destination_attribute :parent_id
    end
  end

  postgres do
    references do
      reference :organization, on_delete: :delete  # Cascade
    end
  end
  ```

  ## Pattern #5: Action Atomicity

  ✅ Use `transaction? true` for multi-step operations:

  ```elixir
  action :complex_operation, :map do
    transaction? true  # Ensures atomicity

    run fn input, context ->
      # All operations succeed or all rollback
    end
  end
  ```

  ✅ Use `require_atomic? false` when:
  - Action needs external API calls
  - Complex validation requires database queries
  - Using after_action hooks with side effects

  ```elixir
  update :update do
    require_atomic? false  # Can't be done in single SQL statement
  end
  ```
  """
end
