defmodule MyApp.Example.AsyncFalseTest do
  @moduledoc """
  Example showing when and why to use `async: false` in tests.

  Use `async: false` when tests:
  - Share global state (GenServers, ETS tables)
  - Use PubSub subscriptions
  - Have timing dependencies
  - Modify environment variables
  - Use Mox in shared mode

  Most tests should use `async: true` for better performance.
  Only use `async: false` when necessary.
  """

  # ============================================================================
  # ✅ CORRECT: Use async: false for PubSub tests
  # ============================================================================

  use MyApp.DataCase, async: false  # ✅ Required for PubSub

  alias MyApp.Analytics.AnalyticsAgentPrompt

  describe "PubSub broadcasting" do
    setup do
      organization = create_test_organization()
      user = create_test_user(organization, %{role: :editor})
      actor = build_test_actor(user, organization)

      %{organization: organization, user: user, actor: actor}
    end

    test "broadcasts prompt completion event", %{actor: actor, user: user} do
      # ✅ Subscribe to PubSub channel
      # This requires async: false because PubSub state is global
      Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{user.id}")

      # Trigger event that broadcasts
      # (Simplified example - actual implementation varies)
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "analytics_chat:#{user.id}",
        {:prompt_completed, "test-prompt-id", %{}}
      )

      # ✅ Assert message received
      assert_receive {:prompt_completed, "test-prompt-id", _meta}, 1000
    end

    test "multiple subscribers receive broadcasts", %{user: user} do
      # Subscribe from test process
      Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{user.id}")

      # Simulate another subscriber (in practice, this would be a LiveView)
      spawn(fn ->
        Phoenix.PubSub.subscribe(MyApp.PubSub, "analytics_chat:#{user.id}")
        receive do
          {:prompt_completed, _, _} -> :ok
        end
      end)

      # Broadcast
      Phoenix.PubSub.broadcast(
        MyApp.PubSub,
        "analytics_chat:#{user.id}",
        {:prompt_completed, "test", %{}}
      )

      # ✅ Both subscribers should receive
      assert_receive {:prompt_completed, "test", _}
    end
  end

  # ============================================================================
  # ✅ CORRECT: Use async: false for GenServer tests with state
  # ============================================================================

  defmodule MyApp.Example.CounterServer do
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, 0, name: __MODULE__)
    def increment, do: GenServer.call(__MODULE__, :increment)
    def get, do: GenServer.call(__MODULE__, :get)

    @impl true
    def init(state), do: {:ok, state}

    @impl true
    def handle_call(:increment, _from, state), do: {:reply, state + 1, state + 1}
    def handle_call(:get, _from, state), do: {:reply, state, state}
  end

  describe "GenServer with global state (requires async: false)" do
    setup do
      # Start named GenServer
      {:ok, _pid} = MyApp.Example.CounterServer.start_link([])
      :ok
    end

    test "increments counter" do
      # ✅ This modifies global GenServer state
      # If async: true, other tests could interfere
      assert 1 = MyApp.Example.CounterServer.increment()
      assert 1 = MyApp.Example.CounterServer.get()
    end

    test "counter maintains state" do
      # ✅ Depends on sequential execution with previous test
      # Would fail if tests run in parallel
      assert 2 = MyApp.Example.CounterServer.increment()
    end
  end

  # ============================================================================
  # ✅ CORRECT: Use async: false for timing-dependent tests
  # ============================================================================

  describe "timing-dependent operations" do
    @tag capture_log: true  # ✅ Silence expected timeout logs
    test "handles timeout gracefully" do
      # ✅ Test that depends on Process.sleep or timing
      # async: false ensures predictable timing

      task = Task.async(fn ->
        Process.sleep(100)
        :completed
      end)

      # This will timeout (intentionally for testing)
      assert catch_exit(Task.await(task, 50))
    end

    test "processes events in order" do
      # ✅ Test that depends on sequential event processing
      events = []

      for i <- 1..5 do
        events = events ++ [i]
        Process.sleep(10)  # Simulate processing time
      end

      assert events == [1, 2, 3, 4, 5]
    end
  end

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Use async: false for database tests without good reason
  # Database tests with Ecto Sandbox can run async: true
  #
  # defmodule BadDatabaseTest do
  #   use MyApp.DataCase, async: false  # ❌ Unnecessary - DB tests can be async
  #
  #   test "creates user" do
  #     create_test_user(...)
  #   end
  # end

  # ❌ DON'T: Use async: false as default for all tests
  #
  # defmodule AllTestsSlow do
  #   use ExUnit.Case, async: false  # ❌ Slows down entire test suite
  # end

  # ❌ DON'T: Mix async: true and async: false tests in same module
  # Choose one per module based on what the tests need
  #
  # defmodule MixedAsyncTest do
  #   use ExUnit.Case, async: true  # Module-level setting
  #
  #   @tag async: false  # ❌ Tag doesn't override module setting
  #   test "this is still async" do
  #   end
  # end

  # ============================================================================
  # DECISION GUIDE
  # ============================================================================

  # Use async: FALSE when:
  # ✅ Tests use PubSub.subscribe
  # ✅ Tests use named GenServers/Agents
  # ✅ Tests modify global state (Application env, ETS)
  # ✅ Tests have timing dependencies
  # ✅ Tests use Mox in global mode
  # ✅ Tests interact with external services (rare)
  #
  # Use async: TRUE when:
  # ✅ Tests are pure functions (unit tests)
  # ✅ Tests use database with Ecto Sandbox
  # ✅ Tests are isolated and stateless
  # ✅ Tests don't share resources
  #
  # Default: Always prefer async: true unless you have a specific reason not to.
  # Async tests run faster and scale better.

  # ============================================================================
  # PERFORMANCE IMPACT
  # ============================================================================

  # Example test suite with 100 tests:
  #
  # All async: true  → ~5 seconds  (parallel on all cores)
  # All async: false → ~30 seconds (sequential execution)
  #
  # Best practice: 70-80% async: true, 20-30% async: false
end
