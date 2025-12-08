defmodule AshSkill.Examples.Changesets do
  @moduledoc """
  Self-contained examples of Ash changesets and validation patterns.

  Changesets represent pending changes to resources with validations,
  transformations, and constraints applied before persistence.

  ## Related Files
  - ../reference/resources.md - Resource patterns
  - DESIGN/concepts/resources.md - Resource architecture
  - lib/my_app/**/resources/*.ex - Real examples
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Changeset Creation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Create changeset for resource action.

  Changesets are created via:
  - for_create - New records
  - for_update - Existing records
  - for_destroy - Delete operations
  """
  def example_basic_changeset do
    """
    # Create changeset
    changeset =
      MyResource
      |> Ash.Changeset.for_create(:create, %{name: "Test"}, actor: actor)

    # Update changeset
    changeset =
      resource
      |> Ash.Changeset.for_update(:update, %{name: "New Name"}, actor: actor)

    # Destroy changeset
    changeset =
      resource
      |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)

    # Execute changeset
    case Ash.create(changeset) do
      {:ok, resource} -> {:ok, resource}
      {:error, error} -> {:error, error}
    end
    """
  end

  # -----------------------------------------------------------------------------
  # Example 2: Accessing Changeset Fields
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Access changeset fields with get_attribute/2 and get_argument/2.

  NEVER use bracket syntax on changesets.
  """
  def example_accessing_fields do
    quote do
      # ✅ CORRECT: Access attributes
      name = Ash.Changeset.get_attribute(changeset, :name)
      status = Ash.Changeset.get_attribute(changeset, :status)

      # ✅ CORRECT: Access arguments
      entity_data = Ash.Changeset.get_argument(changeset, :entity)
      force = Ash.Changeset.get_argument(changeset, :force)

      # ❌ WRONG: Bracket syntax doesn't work
      # name = changeset[:name]  # Error!
      # name = changeset.attributes[:name]  # Wrong!
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Setting Changeset Fields
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Modify changeset with change_attribute and force_change_attribute.

  - change_attribute: Normal change, respects constraints
  - force_change_attribute: Bypasses normal validation
  """
  def example_setting_fields do
    quote do
      # ✅ Normal attribute change
      changeset =
        changeset
        |> Ash.Changeset.change_attribute(:status, :active)
        |> Ash.Changeset.change_attribute(:updated_by_id, actor.id)

      # ✅ Force change (for system-set fields)
      changeset =
        Ash.Changeset.force_change_attribute(
          changeset,
          :created_at,
          DateTime.utc_now()
        )

      # ✅ Conditional change
      changeset =
        if should_update? do
          Ash.Changeset.change_attribute(changeset, :flag, true)
        else
          changeset
        end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Changeset Context
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Set context during changeset creation, not after.

  CRITICAL: Context set via set_context/2 may be lost during
  action processing. Always set during for_create/for_update.
  """
  def example_changeset_context do
    quote do
      # ✅ CORRECT: Context set during creation
      changeset =
        MyResource
        |> Ash.Changeset.for_create(
          :create,
          %{name: "Test"},
          actor: actor,
          context: %{skip_validation: true, source: "import"}
        )

      # ❌ WRONG: Context may be lost
      changeset =
        MyResource
        |> Ash.Changeset.for_create(:create, %{name: "Test"}, actor: actor)
        |> Ash.Changeset.set_context(%{skip_validation: true})

      # Access context in change function:
      change fn changeset, context ->
        skip_validation = Map.get(context, :skip_validation, false)
        # ...
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Embedded Resource Validation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Always validate embedded resources before creating structs.

  CRITICAL: Create changeset for embedded resource to get proper validation.
  """
  def example_embedded_validation do
    quote do
      # ✅ CORRECT: Validate before struct creation
      change fn changeset, context ->
        entity_data = Ash.Changeset.get_argument(changeset, :entity)

        case Ash.Changeset.for_create(EmbeddedEntity, :create, entity_data) do
          %{valid?: true} ->
            # Validation passed - safe to create struct
            entity = struct(EmbeddedEntity, entity_data)
            Ash.Changeset.change_attribute(changeset, :entity, entity)

          %{valid?: false} = entity_changeset ->
            # Add validation errors with context
            Enum.reduce(entity_changeset.errors, changeset, fn error, acc ->
              Ash.Changeset.add_error(acc,
                field: :"entity.#{error.field}",
                message: "Entity validation failed: #{error.message}"
              )
            end)
        end
      end

      # ❌ WRONG: Creating struct without validation
      change fn changeset, context ->
        entity_data = Ash.Changeset.get_argument(changeset, :entity)
        # No validation!
        entity = struct(EmbeddedEntity, entity_data)
        Ash.Changeset.change_attribute(changeset, :entity, entity)
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Changeset Validations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Add validations to changeset for data integrity.

  Validations run during changeset processing and prevent invalid data.
  """
  def example_validations do
    quote do
      defmodule MyResource do
        actions do
          create :create do
            accept [:name, :email, :age]

            # Built-in validations
            validate present(:name)
            validate present(:email)

            # Regex validation
            validate match(:email, ~r/@/) do
              message "must be a valid email"
            end

            # Numeric validation
            validate compare(:age, greater_than_or_equal_to: 18) do
              message "must be 18 or older"
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

            # Conditional validation
            validate present(:phone_number), where: [
              attribute_equals(:contact_method, :phone)
            ]
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 7: Adding Errors to Changesets
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Add errors to changeset to prevent invalid operations.

  Errors make changeset invalid and prevent persistence.
  """
  def example_adding_errors do
    quote do
      change fn changeset, context ->
        actor = Map.get(context, :actor)

        cond do
          is_nil(actor) ->
            # Add error with message
            Ash.Changeset.add_error(changeset, "Actor context is required")

          not authorized?(actor) ->
            # Add error with field and message
            Ash.Changeset.add_error(changeset,
              field: :organization_id,
              message: "not authorized for this organization"
            )

          true ->
            changeset
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 8: Changeset Argument Validation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Validate action arguments before processing.

  Arguments are inputs to actions that aren't stored on the resource.
  """
  def example_argument_validation do
    quote do
      defmodule MyResource do
        actions do
          update :add_entity do
            argument :entity_data, :map, allow_nil?: false
            argument :force, :boolean, default: false

            # Validate argument presence
            change fn changeset, context ->
              entity_data = Ash.Changeset.get_argument(changeset, :entity_data)

              if is_nil(entity_data) or entity_data == %{} do
                Ash.Changeset.add_error(
                  changeset,
                  field: :entity_data,
                  message: "entity_data is required"
                )
              else
                changeset
              end
            end

            # Validate argument structure
            change fn changeset, context ->
              entity_data = Ash.Changeset.get_argument(changeset, :entity_data)

              required_fields = [:name, :type]

              missing_fields =
                Enum.filter(required_fields, fn field ->
                  is_nil(Map.get(entity_data, field))
                end)

              if missing_fields != [] do
                Ash.Changeset.add_error(
                  changeset,
                  field: :entity_data,
                  message: "missing required fields: #{inspect(missing_fields)}"
                )
              else
                changeset
              end
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 9: Changeset Composition
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Chain changeset operations for complex transformations.

  Changesets can be piped through multiple transformations.
  """
  def example_changeset_composition do
    quote do
      change fn changeset, context ->
        actor = Map.get(context, :actor)

        changeset
        |> validate_actor(actor)
        |> set_defaults(actor)
        |> apply_business_logic()
        |> track_changes(actor)
      end

      defp validate_actor(changeset, nil) do
        Ash.Changeset.add_error(changeset, "Actor required")
      end

      defp validate_actor(changeset, _actor), do: changeset

      defp set_defaults(changeset, actor) do
        changeset
        |> Ash.Changeset.change_attribute(:created_by_id, actor.id)
        |> Ash.Changeset.change_attribute(:status, :active)
      end

      defp apply_business_logic(changeset) do
        # Complex transformation logic
        changeset
      end

      defp track_changes(changeset, actor) do
        # Add to audit log
        changeset
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 10: Conditional Changeset Operations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Conditionally apply changes based on context or data.
  """
  def example_conditional_changes do
    quote do
      change fn changeset, context ->
        force = Ash.Changeset.get_argument(changeset, :force, false)
        actor = Map.get(context, :actor)

        changeset =
          if force do
            # Skip validation when forced
            Ash.Changeset.set_context(changeset, %{skip_validation: true})
          else
            changeset
          end

        changeset =
          if actor.role == :admin do
            # Admins can set any status
            changeset
          else
            # Non-admins limited to specific statuses
            status = Ash.Changeset.get_attribute(changeset, :status)

            if status not in [:draft, :submitted] do
              Ash.Changeset.add_error(changeset,
                field: :status,
                message: "only admins can set status to #{status}"
              )
            else
              changeset
            end
          end

        changeset
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Common Changeset Patterns
  # -----------------------------------------------------------------------------

  @doc """
  ## Pattern #1: Changeset vs Struct

  ✅ Changeset: Pending changes with validation
  - Use for creating/updating resources
  - Contains errors, validations, transformations
  - Must be executed via Ash.create/update/destroy

  ✅ Struct: Actual resource data
  - Result of successful changeset execution
  - Read from database
  - Can be passed to for_update/for_destroy

  ```elixir
  # Changeset
  changeset = MyResource |> Ash.Changeset.for_create(:create, attrs, actor: actor)

  # Execute to get struct
  {:ok, struct} = Ash.create(changeset)

  # Use struct for updates
  changeset = struct |> Ash.Changeset.for_update(:update, changes, actor: actor)
  ```

  ## Pattern #2: Accessing vs Changing

  ✅ Reading changeset data:
  - `get_attribute/2` - Get attribute value
  - `get_argument/2` - Get argument value
  - `get_context/1` - Get entire context

  ✅ Modifying changeset:
  - `change_attribute/3` - Set attribute
  - `force_change_attribute/3` - Force set (bypass constraints)
  - `set_context/2` - Add context (during creation only!)
  - `add_error/2` - Add validation error

  ## Pattern #3: Validation Error Messages

  ✅ Provide clear, actionable error messages:

  ```elixir
  # ✅ Good
  Ash.Changeset.add_error(changeset,
    field: :email,
    message: "must be a valid email address"
  )

  # ❌ Bad
  Ash.Changeset.add_error(changeset, "invalid")
  ```

  ## Pattern #4: UUID Preservation

  ✅ Preserve UUIDs during copy/fork operations:

  ```elixir
  defp ensure_uuid(data) do
    case Map.get(data, :id) do
      nil -> Map.put(data, :id, Ash.UUID.generate())
      _existing -> data  # ✅ Preserve existing
    end
  end
  ```

  ## Pattern #5: Testing Changesets

  ✅ Test validation logic:

  ```elixir
  test "validates required fields" do
    changeset =
      MyResource
      |> Ash.Changeset.for_create(:create, %{}, actor: actor)

    assert changeset.valid? == false
    assert Enum.any?(changeset.errors, fn err ->
      err.field == :name and String.contains?(err.message, "required")
    end)
  end
  ```

  ## Pattern #6: Debugging Changeset Errors

  Steps to debug:

  1. **Inspect changeset.valid?**: false means errors exist
  2. **Check changeset.errors**: List of error maps
  3. **Review validations**: Ensure all required fields provided
  4. **Check actor**: Properly structured with id, organization_id, role
  5. **Verify action accepts fields**: accept list includes all changed fields
  6. **Test incrementally**: Add changes one at a time
  """
end
