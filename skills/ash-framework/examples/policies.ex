defmodule AshSkill.Examples.Policies do
  @moduledoc """
  Self-contained examples of Ash Framework authorization policies.

  Policies are the gatekeepers for all resource access in MyApp.
  They enforce multi-tenant isolation and role-based permissions.

  ## Related Files
  - ../reference/policies.md - Deep dive on policy patterns
  - DESIGN/security/authorization.md - Authorization architecture
  - lib/my_app/policies/base_policy.ex - Reusable policy macros
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Multi-Tenant Read Policy
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Multi-tenant read policy with organization check.

  This policy:
  - Checks if user belongs to same organization as resource
  - Allows any role (admin, editor, viewer) to read
  - Automatically filters queries by organization_id
  """
  def example_read_policy do
    quote do
      policies do
        policy action_type(:read) do
          # Check organization membership
          authorize_if expr(organization_id == ^actor(:organization_id))
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Role-Based Create Policy
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Create policy with role and organization checks.

  Only editors and admins can create resources in their organization.

  IMPORTANT: For create actions, use changing_attributes or argument checks
  because the record doesn't exist yet for relationship-based filters.
  """
  def example_create_policy do
    quote do
      policies do
        policy action_type(:create) do
          # Forbid viewers from creating
          forbid_if expr(^actor(:role) not in [:admin, :editor])
          # Verify creating in actor's organization
          authorize_if changing_attributes(organization_id: [to: {:_actor, :organization_id}])
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Role-Based Update Policy
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Update policy combining organization and role checks.

  Editors and admins can update resources in their organization.
  """
  def example_update_policy do
    quote do
      policies do
        policy action_type(:update) do
          authorize_if expr(
            organization_id == ^actor(:organization_id) and
            ^actor(:role) in [:admin, :editor]
          )
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Admin-Only Destroy Policy
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Destroy policy restricted to admins.

  Only organization admins can delete resources.
  """
  def example_destroy_policy do
    quote do
      policies do
        policy action_type(:destroy) do
          authorize_if expr(
            organization_id == ^actor(:organization_id) and
            ^actor(:role) == :admin
          )
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Complete Resource with Standard Policies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Full resource with standard multi-tenant policies.

  This is the most common pattern in your application:
  - Read: All roles in organization
  - Create: Editors and admins
  - Update: Editors and admins
  - Destroy: Admins only
  """
  def example_connection_resource do
    quote do
      defmodule MyApp.Connection do
        use Ash.Resource,
          domain: MyApp.DataPipeline,
          data_layer: AshPostgres.DataLayer,
          authorizers: [Ash.Policy.Authorizer]

        postgres do
          table "connections"
          repo MyApp.Repo
        end

        attributes do
          uuid_primary_key :id
          attribute :name, :string, allow_nil?: false
          timestamps()
        end

        relationships do
          belongs_to :organization, MyApp.Organization do
            allow_nil?: false
            attribute_writable? true
          end
        end

        actions do
          defaults [:read, :destroy]

          create :create do
            accept [:name, :organization_id]
          end

          update :update do
            accept [:name]
          end
        end

        policies do
          # Read: All roles in organization
          policy action_type(:read) do
            authorize_if expr(organization_id == ^actor(:organization_id))
          end

          # Create: Editors and admins in organization
          policy action_type(:create) do
            forbid_if expr(^actor(:role) not in [:admin, :editor])
            authorize_if changing_attributes(organization_id: [to: {:_actor, :organization_id}])
          end

          # Update: Editors and admins in organization
          policy action_type(:update) do
            authorize_if expr(
              organization_id == ^actor(:organization_id) and
              ^actor(:role) in [:admin, :editor]
            )
          end

          # Destroy: Admins only in organization
          policy action_type(:destroy) do
            authorize_if expr(
              organization_id == ^actor(:organization_id) and
              ^actor(:role) == :admin
            )
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Ownership-Based Policies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Policies based on resource ownership.

  Users can update/delete resources they created.
  Admins can update/delete any resource in organization.
  """
  def example_ownership_policies do
    quote do
      policies do
        # Read: All users in organization
        policy action_type(:read) do
          authorize_if expr(organization_id == ^actor(:organization_id))
        end

        # Update: Owner OR admin
        policy action_type(:update) do
          # Owner can update
          authorize_if expr(created_by_id == ^actor(:id))
          # OR admin in same org can update
          authorize_if expr(
            organization_id == ^actor(:organization_id) and
            ^actor(:role) == :admin
          )
        end

        # Destroy: Owner OR admin
        policy action_type(:destroy) do
          authorize_if expr(created_by_id == ^actor(:id))
          authorize_if expr(
            organization_id == ^actor(:organization_id) and
            ^actor(:role) == :admin
          )
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 7: Action-Specific Policies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Policies for specific named actions.

  Use action(:action_name) for policies on specific actions.
  """
  def example_action_specific_policies do
    quote do
      policies do
        # General read policy
        policy action_type(:read) do
          authorize_if expr(organization_id == ^actor(:organization_id))
        end

        # Specific action policy overrides general policy
        policy action(:load_for_authentication) do
          # System actor only
          authorize_if actor_attribute_equals(:system?, true)
        end

        # Invite action - admins only
        policy action(:invite) do
          authorize_if expr(^actor(:role) == :admin)
          authorize_if changing_attributes(organization_id: [to: {:_actor, :organization_id}])
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 8: Self-Modification Prevention
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Prevent users from deleting themselves.

  Use forbid_if to explicitly block certain conditions.
  """
  def example_self_modification_prevention do
    quote do
      policies do
        # Users cannot delete themselves
        policy action_type(:destroy) do
          forbid_if expr(id == ^actor(:id))
          # Admins can delete other users in org
          authorize_if expr(
            organization_id == ^actor(:organization_id) and
            ^actor(:role) == :admin
          )
        end

        # Users can update their own profile
        policy action_type(:update) do
          authorize_if expr(id == ^actor(:id))
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 9: System Actor Policies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Allow system actor for authentication bootstrap.

  System actor has system?: true flag and is used ONLY for:
  - Loading user during authentication
  - Creating organization during registration
  """
  def example_system_actor_policies do
    quote do
      policies do
        # General read requires organization membership
        policy action_type(:read) do
          # Allow system actor for auth bootstrap
          authorize_if actor_attribute_equals(:system?, true)
          # OR normal user in organization
          authorize_if expr(organization_id == ^actor(:organization_id))
        end

        # Specific action for system actor
        policy action(:load_for_authentication) do
          authorize_if actor_attribute_equals(:system?, true)
        end

        # Bootstrap create action (registration)
        policy action(:bootstrap_create) do
          authorize_if actor_attribute_equals(:system?, true)
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 10: Bypassing Authentication for Public Actions
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Bypass policies for authentication actions.

  Authentication actions (register, sign_in) need to bypass normal policies.
  """
  def example_authentication_bypass do
    quote do
      policies do
        # Bypass for authentication interactions
        bypass AshAuthentication.Checks.AshAuthenticationInteraction do
          authorize_if always()
        end

        # Specific authentication actions
        policy action(:register_with_password) do
          authorize_if always()
        end

        policy action(:sign_in_with_password) do
          authorize_if always()
        end

        # Normal policies for other actions
        policy action_type(:read) do
          authorize_if expr(organization_id == ^actor(:organization_id))
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 11: Nested Relationship-Based Policies
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Check organization through nested relationships.

  For resources related through multiple levels, use relates_to_actor_via
  with a path.

  IMPORTANT: This only works for read/update/destroy. For create actions,
  use actor checks or changing_attributes instead.
  """
  def example_nested_relationship_policies do
    quote do
      policies do
        # Read draft if it belongs to actor's organization (via version -> resource -> connection)
        policy action_type(:read) do
          authorize_if relates_to_actor_via([
            :version,
            :resource,
            :connection,
            :organization
          ])
        end

        # For create, use actor check (record doesn't exist yet)
        policy action_type(:create) do
          authorize_if expr(^actor(:role) in [:admin, :editor])
        end

        # Update: Owner only
        policy action_type(:update) do
          authorize_if expr(created_by_id == ^actor(:id))
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 12: NotFound vs Forbidden for Security
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Return NotFound instead of Forbidden for cross-tenant access.

  This prevents information leakage about resource existence.

  Implementation is in application code, not policies.
  Policies return Forbidden, but code should convert to NotFound.
  """
  def example_notfound_conversion do
    """
    # In application code:
    def get_resource(id, actor) do
      case Resource |> Ash.get(id, actor: actor) do
        {:ok, resource} ->
          {:ok, resource}

        {:error, %Ash.Error.Forbidden{}} ->
          # ✅ Convert Forbidden to NotFound for security
          {:error, :not_found}

        {:error, error} ->
          {:error, error}
      end
    end
    """
  end

  # -----------------------------------------------------------------------------
  # Common Policy Patterns
  # -----------------------------------------------------------------------------

  @doc """
  ## Common Pattern #1: Multiple Policy Blocks (OR Logic)

  Multiple policy blocks for the same action create OR logic:

  ```elixir
  # User can read if EITHER condition is true
  policy action_type(:read) do
    # Admin in organization
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) == :admin
    )
  end

  policy action_type(:read) do
    # OR owner of record
    authorize_if expr(id == ^actor(:id))
  end
  ```

  ## Common Pattern #2: Single Policy Block (AND Logic)

  Multiple authorize_if in one block creates AND logic:

  ```elixir
  # WRONG - This creates AND logic (all must be true)
  policy action_type(:update) do
    authorize_if relates_to_actor_via(:organization)  # Must be in org
    authorize_if expr(^actor(:role) in [:admin, :editor])  # AND must be editor
  end

  # CORRECT - Combine in single expression
  policy action_type(:update) do
    authorize_if expr(
      organization_id == ^actor(:organization_id) and
      ^actor(:role) in [:admin, :editor]
    )
  end
  ```

  ## Common Pattern #3: Organization Resource (Special Case)

  Organization resource IS the organization, not a child:

  ```elixir
  policies do
    # For Organization resource, check if actor belongs to THIS organization
    policy action_type(:read) do
      authorize_if expr(id == ^actor(:organization_id))
    end

    policy action_type(:update) do
      authorize_if expr(
        id == ^actor(:organization_id) and
        ^actor(:role) in [:admin, :editor]
      )
    end
  end
  ```

  ## Common Pattern #4: Create Action Policies

  Create actions can't use relates_to_actor_via because record doesn't exist:

  ```elixir
  # ❌ WRONG - Can't use relationship filters on create
  policy action_type(:create) do
    authorize_if relates_to_actor_via(:organization)  # Error!
  end

  # ✅ CORRECT - Use changing_attributes or actor checks
  policy action_type(:create) do
    authorize_if actor_present()  # Simple check
  end

  # ✅ CORRECT - Verify organization_id matches
  policy action_type(:create) do
    authorize_if changing_attributes(
      organization_id: [to: {:_actor, :organization_id}]
    )
  end
  ```

  ## Common Pattern #5: Debugging Authorization Failures

  Steps to debug policy failures:

  1. **Check actor is passed**: `actor: user` in all operations
  2. **Verify actor structure**: Contains id, organization_id, role
  3. **Check resource organization_id**: Matches actor's organization_id
  4. **Review policy conditions**: All expressions evaluate to true
  5. **Test policy logic**: Use simple policies first, then add complexity
  6. **Check action type**: Policy applies to the action being called
  7. **Review logs**: Ash logs policy evaluation in debug mode

  Enable policy debugging:
  ```elixir
  # In config/dev.exs
  config :ash, :show_policy_breakdowns?, true
  ```
  """
end
