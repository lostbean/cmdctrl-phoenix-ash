# Transactions Reference

**Deep dive into transactions and atomic operations in Ash Framework**

Transactions ensure data consistency by making multi-step operations
all-or-nothing: either all steps succeed or all rollback.

## Table of Contents

- [What are Transactions?](#what-are-transactions)
- [Transaction Patterns](#transaction-patterns)
- [Reactor Workflows](#reactor-workflows)
- [Atomicity and require_atomic?](#atomicity-and-require_atomic)
- [Error Handling](#error-handling)
- [Related Resources](#related-resources)

## What are Transactions?

Transactions wrap multiple database operations so they succeed or fail as a
unit. If any operation fails, all changes are rolled back.

### Why Use Transactions?

✅ **Data consistency**: Prevent partial updates ✅ **Error recovery**:
Automatic rollback on failure ✅ **Multi-step operations**: Coordinate related
changes ✅ **Financial operations**: Transfers, payments require atomicity

### When to Use Transactions

**Use `transaction? true` when**:

- Creating parent and child records together
- Multiple updates must all succeed or fail
- Financial operations (transfers, payments)
- State changes affecting multiple resources
- Publishing/versioning operations

**Don't need `transaction? true` when**:

- Single record CRUD (default behavior)
- Read-only operations
- Operations already atomic

**See**: [examples/transactions.ex](../examples/transactions.ex#L358-L378) for
decision guide

## Transaction Patterns

### Basic Transaction with transaction? true

```elixir
defmodule MyApp.Order do
  actions do
    create :create_with_items do
      transaction? true  # ✅ Critical for atomicity
      accept [:customer_id, :total]
      argument :items, {:array, :map}, allow_nil?: false

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
```

**See**: [examples/transactions.ex](../examples/transactions.ex#L18-L57) for
complete example

### Generic Actions as Transactions

Generic actions can execute complex workflows with transaction control:

```elixir
action :publish_item, :map do
  description "Publish draft item as new version"
  transaction? true  # ✅ Ensure all-or-nothing

  argument :draft_id, :uuid, allow_nil?: false
  argument :commit_message, :string, allow_nil?: false

  run fn input, context ->
    actor = Map.get(context, :actor)

    with {:ok, draft} <- load_draft(input, actor),
         {:ok, version} <- create_version(draft, input, actor),
         {:ok, draft} <- mark_published(draft, actor) do
      # All steps succeeded - transaction commits
      {:ok, %{draft: draft, version: version}}
    else
      {:error, reason} ->
        # Any failure - transaction rolls back
        {:error, reason}
    end
  end
end
```

**See**: [examples/transactions.ex](../examples/transactions.ex#L89-L120) for
generic action transactions

### Nested Transactions

Calling transactional actions from within transactions:

```elixir
defmodule MyApp.Organization do
  actions do
    create :create_with_admin do
      transaction? true  # ✅ Outer transaction

      change after_action(fn changeset, org, context ->
        actor = Map.get(context, :actor)

        # This action also has transaction? true
        # It joins the outer transaction automatically
        {:ok, user} =
          User
          |> Ash.Changeset.for_create(
            :create,  # Also transactional
            %{email: "admin@#{org.slug}.com", organization_id: org.id},
            actor: actor
          )
          |> Ash.create()

        {:ok, org}
      end)
    end
  end
end
```

**Key Point**: Ash handles nested transactions automatically - inner
transactions join the outer transaction.

**See**: [examples/transactions.ex](../examples/transactions.ex#L138-L172) for
nested transaction example

## Reactor Workflows

Reactor provides saga pattern for complex workflows with compensation (rollback)
logic.

### Basic Reactor Workflow with Compensation

```elixir
defmodule MyApp.UploadWorkflow do
  use Reactor

  input :file_path
  input :datastore_id
  input :actor

  # Step 1: Create namespace in datastore
  step :create_namespace do
    run fn arguments, context ->
      actor = Map.get(context, :actor)
      namespace = generate_unique_namespace()

      case create_namespace_in_datastore(datastore, namespace) do
        :ok -> {:ok, namespace}
        {:error, reason} -> {:error, reason}
      end
    end

    # ✅ Compensation: Delete namespace if later steps fail
    compensate fn namespace, _arguments ->
      delete_namespace_from_datastore(namespace)
      :ok
    end
  end

  # Step 2: Create Resource record
  step :create_resource do
    argument :namespace, result(:create_namespace)

    run fn arguments, context ->
      actor = Map.get(context, :actor)

      Resource
      |> Ash.Changeset.for_create(:create, %{namespace: arguments.namespace}, actor: actor)
      |> Ash.create()
    end

    # ✅ Compensation: Delete Resource
    compensate fn resource, %{actor: actor} ->
      resource
      |> Ash.Changeset.for_destroy(:destroy, %{}, actor: actor)
      |> Ash.destroy()

      :ok
    end
  end
end
```

**Key Points**:

- Compensation runs in **reverse order** if any step fails
- Each step can define compensation logic
- Compensation is for non-DB operations (DB operations auto-rollback)

**See**:

- [examples/transactions.ex](../examples/transactions.ex#L122-L183) for Reactor
  workflows
- [examples/reactor-workflows.ex](../examples/reactor-workflows.ex) for complete
  workflow patterns

### Compensation Order

Compensation functions run in **reverse order**:

```elixir
step :step1 do
  compensate fn -> cleanup_step1() end
end

step :step2 do
  compensate fn -> cleanup_step2() end
end

step :step3 do
  compensate fn -> cleanup_step3() end
end

# If step3 fails:
# 1. cleanup_step3() runs
# 2. cleanup_step2() runs
# 3. cleanup_step1() runs
```

**See**:
[examples/reactor-workflows.ex](../examples/reactor-workflows.ex#L468-L485) for
compensation patterns

## Atomicity and require_atomic?

### transaction? vs require_atomic?

**`transaction? true`**:

- Wraps entire action in DB transaction
- Multiple operations succeed/fail together
- Use for multi-step operations

**`require_atomic? false`**:

- Allows operation to not be done in single SQL statement
- Needed for external calls, complex validation
- Can still be wrapped in transaction

### Common Pattern: Both Together

```elixir
create :create do
  transaction? true        # ✅ Ensure atomicity across steps
  require_atomic? false    # ✅ Allow multi-step processing

  # Validate connection (external operation)
  validate {MyApp.ConnectionValidator, []}

  # Update status after validation
  change {MyApp.UpdateConnectionStatus, []}
end
```

**See**:

- [examples/transactions.ex](../examples/transactions.ex#L59-L87) for
  require_atomic? examples
- [examples/transactions.ex](../examples/transactions.ex#L380-L400) for
  comparison

## Error Handling

### Triggering Rollback

Return `{:error, reason}` from any step to trigger automatic rollback:

```elixir
action :transfer_funds, :map do
  transaction? true

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
```

**See**: [examples/transactions.ex](../examples/transactions.ex#L185-L240) for
error handling patterns

### Reactor Error Handling

```elixir
step :create_resource do
  max_retries 3  # ✅ Retry on transient failures

  run fn arguments, context ->
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
end
```

**See**:
[examples/reactor-workflows.ex](../examples/reactor-workflows.ex#L154-L194) for
workflow error handling

## Testing Transactions

### Test Complete Workflow

```elixir
test "workflow creates all resources" do
  inputs = %{data: data, actor: actor}
  context = %{actor: actor}

  assert {:ok, result} = Reactor.run(MyWorkflow, inputs, context)
  assert result.resource_id
end
```

### Test Rollback Behavior

```elixir
test "transaction rolls back on failure" do
  # Create scenario that causes failure
  assert {:error, _} = create_with_failure()

  # Verify no records created
  assert Ash.count!(Resource) == 0
end
```

**See**:

- [examples/transactions.ex](../examples/transactions.ex#L448-L473) for testing
  patterns
- [examples/reactor-workflows.ex](../examples/reactor-workflows.ex#L513-L532)
  for workflow testing

## Best Practices

1. **Use transaction? true for multi-step operations**: Ensure all-or-nothing
2. **Set require_atomic? false when needed**: For external calls, complex
   validation
3. **Return {:error, reason} to trigger rollback**: Automatic rollback on error
4. **Compensation for non-DB operations**: S3 uploads, API calls need manual
   cleanup
5. **Test rollback behavior**: Verify compensation runs correctly
6. **Keep transactions short**: Minimize lock time
7. **Idempotent compensation**: Safe to run multiple times

## Debugging Transactions

### Enable SQL Logging

```elixir
# In config/dev.exs
config :logger, level: :debug
```

See actual SQL statements and transaction boundaries.

### Steps to Debug

1. **Check error messages**: Ash provides detailed error info
2. **Verify actor passed**: All nested operations need actor
3. **Test steps individually**: Isolate failing operation
4. **Check require_atomic?**: May need to set to false
5. **Review after_action hooks**: Common source of issues
6. **Enable SQL logging**: See transaction behavior

**See**: [examples/transactions.ex](../examples/transactions.ex#L475-L497) for
debugging guide

## Related Resources

### Examples

- [examples/transactions.ex](../examples/transactions.ex) - Complete transaction
  examples
- [examples/reactor-workflows.ex](../examples/reactor-workflows.ex) - Workflow
  patterns with compensation
- [examples/actor-context.ex](../examples/actor-context.ex) - Actor in
  transactions

### Reference Docs

- [reference/actor-context.md](./actor-context.md) - Actor propagation in
  workflows
- [reference/resources.md](./resources.md) - Resource action atomicity
- [reference/policies.md](./policies.md) - Authorization in transactions

### Project Documentation

- {project_root}/DESIGN/architecture/reactor-patterns.md - Workflow architecture
- {project_root}/DESIGN/concepts/workflows.md - Workflow concepts
- {project*root}/lib/my_app/*/workflows/\_.ex - Real workflow examples

### External Resources

- [Reactor Documentation](https://hexdocs.pm/reactor/) - Official Reactor docs
- [Ash Actions](https://hexdocs.pm/ash/actions.html) - Action configuration

---

**Next Steps**:

- Study [examples/transactions.ex](../examples/transactions.ex) for transaction
  patterns
- Read [examples/reactor-workflows.ex](../examples/reactor-workflows.ex) for
  workflow examples
- Review
  [DESIGN/architecture/reactor-patterns.md](../../../../DESIGN/architecture/reactor-patterns.md)
  for architecture
