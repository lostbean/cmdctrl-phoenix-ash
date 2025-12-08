# Async Testing Patterns

Understanding when to use `async: true` vs `async: false` is critical for fast,
reliable tests.

## Quick Decision Guide

```elixir
# Use async: true (default for most tests)
use ExUnit.Case, async: true

# Use async: false (only when necessary)
use MyApp.DataCase, async: false
```

### When to Use `async: true`

✅ Pure function tests ✅ Database tests (with Ecto Sandbox) ✅ Stateless
operations ✅ Independent test cases ✅ Most unit tests

### When to Use `async: false`

✅ PubSub subscriptions ✅ Named GenServers/Agents ✅ Global state modifications
✅ Timing-dependent tests ✅ Mox in global mode ✅ Application env changes

## Understanding Async Execution

### How Async Works

```elixir
# async: true - Tests in THIS module run in parallel with OTHER modules
defmodule UserTest do
  use ExUnit.Case, async: true

  test "test 1" do ... end  # Runs in parallel with other modules
  test "test 2" do ... end  # But sequential within this module
end

# async: false - Tests in THIS module run sequentially
defmodule PubSubTest do
  use ExUnit.Case, async: false

  test "test 1" do ... end  # Runs sequentially
  test "test 2" do ... end  # After test 1 completes
end
```

### Parallelism Limits

ExUnit defaults to `System.schedulers_online() * 2` concurrent tests:

- 4-core machine = 8 concurrent tests max
- 8-core machine = 16 concurrent tests max

Configure in `test/test_helper.exs`:

```elixir
ExUnit.start(max_cases: 4)  # Limit concurrent test modules
```

## Database Tests with Async

### ✅ CORRECT: Database tests CAN be async

```elixir
defmodule MyApp.DataPipeline.ResourceTest do
  use MyApp.DataCase, async: true  # ✅ Safe with Ecto Sandbox

  test "creates resource" do
    # Each test gets isolated DB transaction
    {:ok, resource} = create_test_resource()
    assert resource.name == "Test"
  end
end
```

**Why it works**: Ecto.Adapters.SQL.Sandbox provides per-test transaction
isolation.

### How Sandbox Works

```elixir
# test/support/data_case.ex
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
end
```

- **async: true**: Each test gets own connection
- **async: false**: Tests share connection in serial

**See**: [examples/integration-test.exs](../examples/integration-test.exs)

## PubSub Tests

### ❌ MUST USE async: false

```elixir
defmodule MyApp.Analytics.PubSubTest do
  use MyApp.DataCase, async: false  # ✅ Required for PubSub

  test "broadcasts completion event" do
    # Subscribe to channel
    Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:123")

    # Trigger broadcast
    Phoenix.PubSub.broadcast(
      MyApp.PubSub,
      "analytics_chat:123",
      {:prompt_completed, "prompt-id"}
    )

    # Assert message received
    assert_receive {:prompt_completed, "prompt-id"}, 1000
  end
end
```

**Why async: false**: PubSub state is global. Parallel tests would interfere
with each other's subscriptions.

**See**: [examples/async-false.exs](../examples/async-false.exs)

## GenServer Tests

### Named GenServers: async: false

```elixir
defmodule CounterTest do
  use ExUnit.Case, async: false  # ✅ Named GenServer is global

  defmodule Counter do
    use GenServer
    def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)
    def increment, do: GenServer.call(__MODULE__, :increment)
    @impl true
    def init(state), do: {:ok, state}
    @impl true
    def handle_call(:increment, _from, state), do: {:reply, state + 1, state + 1}
  end

  setup do
    {:ok, _pid} = Counter.start_link([])
    :ok
  end

  test "increments counter" do
    assert 1 = Counter.increment()
  end
end
```

### Anonymous GenServers: async: true OK

```elixir
defmodule AnonymousCounterTest do
  use ExUnit.Case, async: true  # ✅ Each test gets own process

  defmodule Counter do
    use GenServer
    def start_link(_), do: GenServer.start_link(__MODULE__, 0)  # No name
    # ...
  end

  test "increments counter" do
    {:ok, pid} = Counter.start_link([])
    # Use pid, not name
    assert 1 = GenServer.call(pid, :increment)
  end
end
```

**Pattern**: If GenServer is named, use async: false. If anonymous, async: true
is safe.

## Timing-Dependent Tests

### ❌ MUST USE async: false

```elixir
defmodule TimingTest do
  use ExUnit.Case, async: false  # ✅ Timing needs isolation

  @tag capture_log: true
  test "handles timeout" do
    task = Task.async(fn ->
      Process.sleep(100)
      :completed
    end)

    # Will timeout (intentional)
    assert catch_exit(Task.await(task, 50))
  end
end
```

**Why async: false**: Timing tests need predictable execution. Parallel tests
can cause unexpected timing variations.

## Performance Impact

### Benchmark Example

```elixir
# Test suite: 100 tests

# All async: true
# Time: 5.2 seconds
# Tests run on 8 cores in parallel

# All async: false
# Time: 28.4 seconds
# Tests run sequentially

# Mixed (80% async, 20% async: false)
# Time: 8.1 seconds
# Optimal balance
```

### Identifying Slow Tests

```bash
# Run with trace to see slow tests
mix test --trace

# Output:
# UserTest
#   * test creates user (0.1ms)
#   * test validates email (0.05ms)
#
# PubSubTest (async: false)
#   * test broadcasts event (150ms)  # Slow!
```

**Action**: Investigate why test is slow. Can it be made async?

## Common Patterns

### Pattern 1: Database Tests (async: true)

```elixir
defmodule MyApp.Accounts.UserTest do
  use MyApp.DataCase, async: true  # ✅ DB tests with sandbox

  test "creates user", %{organization: org} do
    # Isolated transaction per test
  end
end
```

### Pattern 2: PubSub Tests (async: false)

```elixir
defmodule MyApp.RealtimeTest do
  use MyApp.DataCase, async: false  # ✅ PubSub is global

  test "broadcasts update" do
    Phoenix.PubSub.subscribe(...)
    assert_receive ...
  end
end
```

### Pattern 3: Integration Tests (async: true usually)

```elixir
defmodule MyApp.WorkflowTest do
  use MyApp.DataCase, async: true  # ✅ If no global state

  test "complete workflow" do
    # Multiple Ash operations in transaction
  end
end
```

### Pattern 4: LLM Cassette Tests (async: true)

```elixir
defmodule MyApp.LLM.CassetteTest do
  use MyApp.CassetteCase  # Async by default

  @moduletag :llm_cassette

  test "agent execution", context do
    with_cassette(context, fn req_opts ->
      # Cassettes are file-based, safe for async
    end)
  end
end
```

## Debugging Async Issues

### Symptoms of Async Problems

1. **Intermittent failures**
   - Sometimes pass, sometimes fail
   - Fail more often on faster machines
   - Fail less often with `mix test --trace`

2. **Race conditions**
   - Tests interfere with each other
   - Assertion failures on shared state
   - Unexpected process messages

3. **Resource conflicts**
   - Port conflicts
   - File conflicts
   - Named process conflicts

### Diagnosis Steps

1. **Run tests sequentially**

   ```bash
   mix test --trace  # Slows down execution
   ```

   - If test passes, likely async issue

2. **Run single test**

   ```bash
   mix test test/path/to/test.exs:42
   ```

   - If passes alone but fails in suite, async issue

3. **Check for global state**
   - Named processes?
   - PubSub subscriptions?
   - Application env modifications?
   - File system access?

### Solutions

1. **Use async: false**

   ```elixir
   use ExUnit.Case, async: false
   ```

2. **Isolate state per test**

   ```elixir
   setup do
     # Create anonymous process per test
     {:ok, pid} = MyServer.start_link()
     %{server: pid}
   end
   ```

3. **Use unique identifiers**
   ```elixir
   topic = "test_topic_#{System.unique_integer()}"
   Phoenix.PubSub.subscribe(MyApp.PubSub, topic)
   ```

## Best Practices

### ✅ DO

- Default to `async: true` for new tests
- Use `async: false` only when necessary
- Document why async: false is needed
- Keep async: false tests fast
- Group async: false tests together
- Use unique names/IDs in tests

### ❌ DON'T

- Use async: false for all tests
- Mix async: true and false in same module
- Rely on test execution order
- Use sleep() for synchronization
- Modify global state in async tests
- Share data between test cases

## Module-Level vs Test-Level

### Module-Level (Recommended)

```elixir
defmodule MyTest do
  use ExUnit.Case, async: true  # ✅ Module-level setting

  test "test 1" do ... end
  test "test 2" do ... end
end
```

### Test-Level (Not Supported)

```elixir
defmodule MyTest do
  use ExUnit.Case, async: true

  @tag async: false  # ❌ Doesn't work
  test "specific test" do ... end
end
```

**Note**: async is a module-level setting. To mix async and non-async tests, use
separate modules.

## Advanced Patterns

### Conditional Async Based on Environment

```elixir
defmodule ConditionalAsyncTest do
  @async if System.get_env("CI"), do: false, else: true
  use ExUnit.Case, async: @async

  # CI runs sequentially for stability
  # Local runs async for speed
end
```

### Custom Data Case for PubSub

```elixir
defmodule MyApp.PubSubCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use MyApp.DataCase, async: false  # Force async: false
      import Phoenix.PubSub
    end
  end
end

# Usage
defmodule MyPubSubTest do
  use MyApp.PubSubCase  # Automatically async: false
end
```

## Related Documentation

- **Examples**: See [examples/async-false.exs](../examples/async-false.exs)
- **Strategy**: See [70-20-10-strategy.md](70-20-10-strategy.md)
- **ExUnit Docs**: https://hexdocs.pm/ex_unit/ExUnit.html#configure/1

## External Resources

- [ExUnit Async Testing](https://hexdocs.pm/ex_unit/ExUnit.Case.html#module-async-tests)
- [Ecto Sandbox Guide](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html)
- [Testing Async Code in Elixir](https://www.youtube.com/watch?v=uV8TdMGn-wk)
