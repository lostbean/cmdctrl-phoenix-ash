defmodule AshSkill.Examples.Transactions do
  @moduledoc """
  Self-contained examples of transactions and atomic operations in Ash.

  Transactions ensure data consistency by making multi-step operations
  all-or-nothing: either all steps succeed or all rollback.

  ## Related Files
  - ../reference/transactions.md - Deep dive on transactions
  - DESIGN/architecture/reactor-patterns.md - Workflow patterns
  """

  # -----------------------------------------------------------------------------
  # Example 1: Basic Transaction with transaction? true
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Use transaction? true for multi-step operations.

  When transaction? true:
  - All database operations wrapped in DB transaction
  - If any step fails, all rollback automatically
  - Ensures data consistency
  """
  def example_basic_transaction do
    quote do
      defmodule MyApp.Order do
        actions do
          create :create_with_items do
            transaction? true  # ✅ Critical for atomicity
            accept [:customer_id, :total]
            argument :items, {:array, :map}, allow_nil?: false

            change fn changeset, context ->
              actor = Map.get(context, :actor)
              items = Ash.Changeset.get_argument(changeset, :items)

              changeset
            end

            # After order created, create order items
            change after_action(fn changeset, order, context ->
              actor = Map.get(context, :actor)
              items = Ash.Changeset.get_argument(changeset, :items)

              # Create all order items - all succeed or all rollback
              Enum.each(items, fn item ->
                {:ok, _} =
                  OrderItem
                  |> Ash.Changeset.for_create(
                    :create,
                    %{order_id: order.id, product_id: item["product_id"]},
                    actor: actor
                  )
                  |> Ash.create()
              end)

              {:ok, order}
            end)
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 2: Require Atomic False for Complex Operations
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Use require_atomic? false when operation can't be atomic.

  require_atomic? false needed when:
  - Making external API calls
  - Complex validations needing database queries
  - Operations that need to load related data
  - After-action hooks with side effects
  """
  def example_non_atomic do
    quote do
      defmodule MyApp.ExternalResource do
        actions do
          create :create do
            accept [:name, :connection_config]
            require_atomic? false  # ✅ Connection validation needs this

            # Validate connection (external operation)
            validate {MyApp.ConnectionValidator, []}

            # Update status after validation
            change {MyApp.UpdateConnectionStatus, []}
          end

          update :update do
            accept [:name, :connection_config]
            require_atomic? false  # ✅ Can't update atomically with validation

            validate {MyApp.ConnectionValidator, only_if_config_changed: true}
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 3: Generic Action as Transaction
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Generic action with transaction for complex workflow.

  Generic actions can return any data type and control transaction behavior.
  """
  def example_generic_action_transaction do
    quote do
      defmodule MyApp.Document do
        actions do
          action :save_as_version, :map do
            description "Save document as new version"
            transaction? true  # ✅ Ensure all-or-nothing

            argument :document_id, :uuid, allow_nil?: false
            argument :commit_message, :string, allow_nil?: false

            run fn input, context ->
              actor = Map.get(context, :actor)

              with {:ok, document} <- load_document(input, actor),
                   {:ok, version} <- create_version(document, input, actor),
                   {:ok, document} <- mark_saved(document, actor) do
                # All steps succeeded - transaction commits
                {:ok, %{document: document, version: version}}
              else
                {:error, reason} ->
                  # Any failure - transaction rolls back
                  {:error, reason}
              end
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 4: Reactor Workflow with Compensation
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Reactor workflow with compensation steps.

  Reactor provides saga pattern:
  - Each step can have compensate function
  - On failure, compensate functions run in reverse order
  - Allows rollback of non-transactional operations
  """
  def example_reactor_workflow do
    quote do
      defmodule MyApp.Workflows.ImportWorkflow do
        use Reactor

        # Define inputs
        input :file_path
        input :destination_id
        input :actor

        # Step 1: Create namespace in destination
        step :create_namespace do
          argument :destination_id, input(:destination_id)
          argument :actor, input(:actor)

          run fn %{destination_id: id, actor: actor}, _context ->
            destination = get_destination(id, actor)
            namespace = generate_namespace()

            case create_namespace_in_destination(destination, namespace) do
              :ok -> {:ok, namespace}
              {:error, reason} -> {:error, reason}
            end
          end

          # Compensation: Delete namespace if later step fails
          compensate fn namespace, _inputs ->
            delete_namespace_from_destination(namespace)
            :ok
          end
        end

        # Step 2: Create ImportJob record
        step :create_import_job do
          argument :namespace, result(:create_namespace)
          argument :actor, input(:actor)

          run fn %{namespace: namespace, actor: actor}, _context ->
            ImportJob
            |> Ash.Changeset.for_create(
              :create,
              %{name: "Upload", namespace: namespace},
              actor: actor
            )
            |> Ash.create()
          end

          # Compensation: Delete ImportJob if later step fails
          compensate fn import_job, %{actor: actor} ->
            import_job
            |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
            |> Ash.destroy()

            :ok
          end
        end

        # Step 3: Upload data to destination
        step :upload_data do
          argument :namespace, result(:create_namespace)
          argument :file_path, input(:file_path)

          run fn %{namespace: namespace, file_path: path}, _context ->
            upload_file_to_namespace(path, namespace)
          end

          # Compensation: Drop tables from destination
          compensate fn _result, %{namespace: namespace} ->
            drop_namespace_tables(namespace)
            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 5: Nested Transactions
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Calling transactional actions from within transactions.

  Ash handles nested transactions automatically:
  - Inner transaction joins outer transaction
  - All operations commit/rollback together
  """
  def example_nested_transactions do
    quote do
      defmodule MyApp.Organization do
        actions do
          create :create_with_admin do
            transaction? true  # ✅ Outer transaction
            accept [:name, :slug]

            change after_action(fn changeset, org, context ->
              actor = Map.get(context, :actor)

              # This action also has transaction? true
              # It joins the outer transaction automatically
              {:ok, user} =
                User
                |> Ash.Changeset.for_create(
                  :create,  # Also transactional
                  %{
                    email: "admin@#{org.slug}.com",
                    organization_id: org.id,
                    role: :admin
                  },
                  actor: actor
                )
                |> Ash.create()

              {:ok, org}
            end)
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 6: Conditional Rollback
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Rollback transaction based on business logic.

  Return {:error, reason} to trigger automatic rollback.
  """
  def example_conditional_rollback do
    quote do
      defmodule MyApp.Transfer do
        actions do
          action :transfer_funds, :map do
            transaction? true
            argument :from_account_id, :uuid, allow_nil?: false
            argument :to_account_id, :uuid, allow_nil?: false
            argument :amount, :decimal, allow_nil?: false

            run fn input, context ->
              actor = Map.get(context, :actor)

              with {:ok, from_account} <- get_account(input.from_account_id, actor),
                   :ok <- validate_balance(from_account, input.amount),
                   {:ok, _} <- debit_account(from_account, input.amount, actor),
                   {:ok, _} <- credit_account(input.to_account_id, input.amount, actor) do
                {:ok, %{success: true}}
              else
                {:error, :insufficient_funds} ->
                  # ✅ Error triggers automatic rollback
                  {:error, "Insufficient funds"}

                {:error, reason} ->
                  # ✅ Any error rolls back entire transaction
                  {:error, reason}
              end
            end
          end
        end

        defp validate_balance(account, amount) do
          if Decimal.compare(account.balance, amount) == :lt do
            {:error, :insufficient_funds}
          else
            :ok
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Example 7: Optimistic Locking with Transactions
  # -----------------------------------------------------------------------------

  @doc """
  ✅ CORRECT: Use version fields for optimistic locking.

  Optimistic locking prevents concurrent modification issues.
  """
  def example_optimistic_locking do
    quote do
      defmodule MyApp.Document do
        attributes do
          uuid_primary_key :id
          attribute :content, :string
          attribute :version, :integer, default: 1  # ✅ Version field
          timestamps()
        end

        actions do
          update :update do
            accept [:content]
            argument :expected_version, :integer, allow_nil?: false
            require_atomic? false

            # Check version matches before updating
            change fn changeset, context ->
              expected = Ash.Changeset.get_argument(changeset, :expected_version)
              current = Ash.Changeset.get_attribute(changeset, :version)

              if current != expected do
                Ash.Changeset.add_error(
                  changeset,
                  field: :version,
                  message: "Document was modified by another user"
                )
              else
                # Increment version
                Ash.Changeset.change_attribute(changeset, :version, current + 1)
              end
            end
          end
        end
      end
    end
  end

  # -----------------------------------------------------------------------------
  # Common Transaction Patterns
  # -----------------------------------------------------------------------------

  @doc """
  ## Pattern #1: When to Use Transactions

  ✅ Use transaction? true when:
  - Creating parent and child records together
  - Multiple updates must all succeed or fail
  - Financial operations (transfers, payments)
  - State changes affecting multiple resources
  - Publishing/versioning operations

  ❌ Don't need transaction? true when:
  - Single record CRUD (default behavior)
  - Read-only operations
  - Operations already atomic

  ## Pattern #2: Transaction vs require_atomic?

  **transaction? true**:
  - Wraps entire action in DB transaction
  - Multiple operations succeed/fail together
  - Use for multi-step operations

  **require_atomic? false**:
  - Allows operation to not be done in single SQL statement
  - Needed for external calls, complex validation
  - Can still be wrapped in transaction

  ```elixir
  # Both together is common:
  create :create do
    transaction? true  # Ensure atomicity
    require_atomic? false  # Allow multi-step processing
  end
  ```

  ## Pattern #3: Error Handling in Transactions

  ✅ Return {:error, reason} to trigger rollback:

  ```elixir
  with {:ok, step1} <- do_step1(actor),
       {:ok, step2} <- do_step2(step1, actor),
       {:ok, step3} <- do_step3(step2, actor) do
    {:ok, result}
  else
    {:error, reason} ->
      # Automatic rollback
      {:error, reason}
  end
  ```

  ## Pattern #4: Reactor Compensation Pattern

  ✅ Use compensation for non-DB operations:

  ```elixir
  step :upload_to_s3 do
    run fn input, _context ->
      # Upload file to S3
      S3.upload(input.file, input.bucket)
    end

    compensate fn result, _inputs ->
      # Delete file from S3 if later step fails
      S3.delete(result.key)
      :ok
    end
  end
  ```

  ## Pattern #5: Testing Transactions

  ✅ Test rollback behavior:

  ```elixir
  test "transaction rolls back on failure" do
    assert {:error, _} = create_with_failure()

    # Verify no records created
    assert Ash.count!(Resource) == 0
  end
  ```

  ## Pattern #6: Debugging Transaction Failures

  Steps to debug:

  1. **Enable SQL logging**: See actual SQL statements
     ```elixir
     config :logger, level: :debug
     ```

  2. **Check error messages**: Ash provides detailed error info
  3. **Verify actor passed**: All nested operations need actor
  4. **Test steps individually**: Isolate failing operation
  5. **Check require_atomic?**: May need to set to false
  6. **Review after_action hooks**: Common source of issues
  """
end
