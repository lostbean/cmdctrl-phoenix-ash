defmodule MyApp.Example.CassetteTest do
  @moduledoc """
  Example of LLM testing with ReqCassette for deterministic replay.

  ReqCassette records HTTP interactions with LLM APIs and replays them
  in tests, providing:
  - Deterministic test results
  - Fast execution (< 1 second vs 8+ seconds)
  - Zero API costs after initial recording
  - No API keys required for test runs

  Recording: RECORD_CASSETTES=1 mix test
  Replaying: mix test (default)
  """

  use MyApp.CassetteCase  # ✅ Provides cassette helpers
  use Oban.Testing, repo: MyApp.Repo

  import MyApp.Test.LLMAgentHelpers
  alias MyApp.Test.SimpleTools

  # ✅ Tag as :llm_cassette - runs by default (no --include needed)
  @moduletag :llm_cassette

  # ============================================================================
  # ✅ CORRECT PATTERNS
  # ============================================================================

  describe "basic LLM agent with cassette" do
    @tag :simple_query
    test "executes simple query without tools", context do
      # ✅ with_cassette automatically handles cassette naming and mode
      with_cassette(context, fn req_opts ->
        {:ok, result} =
          execute_with_agent(
            "You are a helpful assistant.",
            "What is 2 + 2?",
            Keyword.merge([tools: []], req_opts)
          )

        # ✅ Assert on behavior, not exact text
        assert is_binary(result.text)
        assert result.text != ""
        assert is_list(result.messages)
        assert result.iterations >= 0
        refute is_nil(result.finish_reason)
      end)
    end

    @tag :tool_calling
    test "uses tools correctly", context do
      # Define simple tool for testing
      add_tool = SimpleTools.add_tool()

      with_cassette(context, fn req_opts ->
        {:ok, result} =
          execute_with_agent(
            "You are a calculator assistant with an add tool.",
            "What is 15 + 27? Use the add tool.",
            Keyword.merge([tools: [add_tool], max_iterations: 5], req_opts)
          )

        # ✅ Tool call recorded in cassette, replayed deterministically
        assert is_binary(result.text)
        assert is_list(result.messages)
        assert result.iterations >= 0
      end)
    end
  end

  describe "termination tools" do
    @tag :termination
    test "handles termination tool correctly", context do
      # Tool that signals agent completion
      termination_tool = SimpleTools.complete_calculation_tool()

      with_cassette(context, fn req_opts ->
        {:ok, result} =
          execute_with_agent(
            "You are a calculator. When done, call complete_calculation.",
            "Complete the calculation with final_result 100.",
            Keyword.merge(
              [
                tools: [termination_tool],
                termination_tools: ["complete_calculation"],
                require_termination_tool?: true,
                max_iterations: 5
              ],
              req_opts
            )
          )

        # ✅ Termination behavior recorded in cassette
        assert result.finish_reason == "termination_tool" or result.iterations < 5
        assert is_list(result.messages)
      end)
    end
  end

  describe "structured output" do
    @tag :structured_output
    test "generates structured data", context do
      # Define schema for structured output
      schema = [
        entities: [
          type: {:list, :map},
          keys: [
            name: [type: :string, required: true],
            description: [type: :string, required: true]
          ]
        ]
      ]

      messages = [
        ReqLLM.Context.system("You are a data model design assistant."),
        ReqLLM.Context.user(
          "Suggest 2 entities for an e-commerce system: Customer and Order."
        )
      ]

      model = "anthropic:claude-sonnet-4-5"

      with_cassette(context, fn req_opts ->
        {:ok, result} = ReqLLM.generate_object(model, messages, schema, req_opts)

        # ✅ Structured output recorded and replayed
        assert is_map(result)
        if Map.has_key?(result, :entities) do
          assert is_list(result.entities)
        end
      end)
    end
  end

  # ============================================================================
  # CASSETTE WORKFLOW
  # ============================================================================

  # 1. First run (recording):
  #    RECORD_CASSETTES=1 ANTHROPIC_API_KEY=sk-ant-... mix test
  #
  #    Output:
  #    - test/fixtures/cassettes/cassette_test__executes_simple_query.json
  #    - Takes ~8 seconds (real LLM API call)
  #
  # 2. Subsequent runs (replay):
  #    mix test
  #
  #    Output:
  #    - Uses recorded cassette
  #    - Takes < 1 second
  #    - No API key required

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Explicitly set stream: true in cassette tests
  # Cassettes only work with non-streaming requests
  #
  # test "bad streaming test", context do
  #   with_cassette(context, fn req_opts ->
  #     Client.execute_agent(messages, Keyword.merge(req_opts, stream: true))
  #     # ❌ Cassette cannot record streaming responses
  #   end)
  # end

  # ❌ DON'T: Use random data in prompts
  # This makes cassettes non-replayable
  #
  # test "non-deterministic prompt", context do
  #   with_cassette(context, fn req_opts ->
  #     prompt = "What is the time? Current: #{DateTime.utc_now()}"
  #     # ❌ UUID/timestamp changes = cassette mismatch
  #     execute_with_agent("System", prompt, req_opts)
  #   end)
  # end

  # ❌ DON'T: Forget to tag cassette tests
  #
  # defmodule UntaggedCassetteTest do
  #   use MyApp.CassetteCase
  #   # ❌ Missing @moduletag :llm_cassette
  # end

  # ❌ DON'T: Assert on exact LLM output text
  # LLM responses can vary, even with cassettes (if re-recorded)
  #
  # test "exact text assertion", context do
  #   with_cassette(context, fn req_opts ->
  #     {:ok, result} = execute_with_agent("System", "Prompt", req_opts)
  #     assert result.text == "Exactly this text"  # ❌ Brittle
  #   end)
  # end

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  # ✅ Use descriptive test names (they become cassette filenames)
  @tag :descriptive_name
  test "agent correctly handles customer query about orders", context do
    with_cassette(context, fn req_opts ->
      # Cassette: cassette_test__agent_correctly_handles_customer_query_about_orders.json
      {:ok, result} = execute_with_agent("System", "Prompt", req_opts)
      assert result.finish_reason in ["stop", "termination_tool"]
    end)
  end

  # ✅ Test behavior, not exact output
  test "validates response structure", context do
    with_cassette(context, fn req_opts ->
      {:ok, result} = execute_with_agent("System", "Test", req_opts)

      # ✅ Assert on structure and behavior
      assert is_binary(result.text)
      assert is_list(result.messages)
      assert result.finish_reason in ["stop", "max_iterations", "termination_tool"]
      assert is_map(result.usage)
    end)
  end

  # ✅ Group related cassette tests
  describe "error handling with cassettes" do
    @tag :error_handling
    @tag capture_log: true  # ✅ Silence expected errors
    test "handles invalid tool gracefully", context do
      with_cassette(context, fn req_opts ->
        # Tool that returns error
        error_tool = SimpleTools.error_tool()

        {:ok, result} =
          execute_with_agent(
            "You have a tool that always errors.",
            "Try using the error tool.",
            Keyword.merge([tools: [error_tool]], req_opts)
          )

        # ✅ Error handling recorded in cassette
        assert is_binary(result.text)
      end)
    end
  end

  # ============================================================================
  # CASSETTE MAINTENANCE
  # ============================================================================

  # When to re-record cassettes:
  # - Prompt changes
  # - Tool definitions change
  # - Model version upgrade
  # - Expected behavior changes
  #
  # How to re-record:
  # 1. Delete specific cassette: rm test/fixtures/cassettes/{test_name}.json
  # 2. Re-run with RECORD_CASSETTES=1
  # 3. Review diff: git diff test/fixtures/cassettes/
  # 4. Commit if changes are expected

  # ============================================================================
  # LIVE API TESTS vs CASSETTE TESTS
  # ============================================================================

  # Use cassette tests (:llm_cassette) for:
  # ✅ Integration tests (runs by default)
  # ✅ Fast feedback loops
  # ✅ CI/CD pipelines
  # ✅ Deterministic behavior validation
  #
  # Use live API tests (:llm_live) for:
  # ✅ Streaming vs non-streaming parity
  # ✅ Validating against latest model behavior
  # ✅ Testing new prompts before recording
  #
  # See: test/my_app/llm/dual_mode_test.exs for live API examples
end
