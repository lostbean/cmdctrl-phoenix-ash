defmodule MyApp.Example.UnitTest do
  @moduledoc """
  Example of a basic unit test pattern.

  Unit tests are:
  - Fast (no database, no external services)
  - Isolated (test one function/module)
  - Deterministic (same input = same output)

  Use for: Pure functions, validations, transformations, utility modules
  """

  use ExUnit.Case, async: true  # ✅ Async for fast parallel execution

  # Example module to test
  defmodule Calculator do
    def add(a, b), do: a + b
    def divide(_a, 0), do: {:error, :division_by_zero}
    def divide(a, b), do: {:ok, a / b}
  end

  # ============================================================================
  # ✅ CORRECT PATTERNS
  # ============================================================================

  describe "Calculator.add/2" do
    test "adds two positive numbers" do
      assert Calculator.add(2, 3) == 5
    end

    test "adds negative numbers" do
      assert Calculator.add(-5, -3) == -8
    end

    test "adds zero" do
      assert Calculator.add(10, 0) == 10
    end
  end

  describe "Calculator.divide/2" do
    test "divides two numbers successfully" do
      assert Calculator.divide(10, 2) == {:ok, 5.0}
    end

    test "returns error for division by zero" do
      assert Calculator.divide(10, 0) == {:error, :division_by_zero}
    end
  end

  # ============================================================================
  # ❌ ANTI-PATTERNS TO AVOID
  # ============================================================================

  # ❌ DON'T: Use async: false for unit tests (unless absolutely necessary)
  # Unit tests should be stateless and run in parallel
  #
  # defmodule BadUnitTest do
  #   use ExUnit.Case, async: false  # ❌ Slows down test suite
  # end

  # ❌ DON'T: Test multiple behaviors in one test
  #
  # test "calculator does everything" do
  #   assert Calculator.add(2, 3) == 5
  #   assert Calculator.divide(10, 2) == {:ok, 5.0}  # ❌ Test one thing per test
  # end

  # ❌ DON'T: Include database or external service calls in unit tests
  #
  # test "adds and saves to database" do
  #   result = Calculator.add(2, 3)
  #   Repo.insert!(%Result{value: result})  # ❌ This is an integration test
  # end

  # ============================================================================
  # BEST PRACTICES
  # ============================================================================

  # ✅ Group related tests with describe blocks
  describe "edge cases" do
    test "handles very large numbers" do
      assert Calculator.add(1_000_000, 2_000_000) == 3_000_000
    end

    test "handles floating point numbers" do
      result = Calculator.add(0.1, 0.2)
      # Use Float.round for floating point comparisons
      assert Float.round(result, 10) == Float.round(0.3, 10)
    end
  end

  # ✅ Use setup for common test data (when needed)
  describe "with setup" do
    setup do
      # Runs before each test in this describe block
      %{numbers: [1, 2, 3, 4, 5]}
    end

    test "sums list of numbers", %{numbers: numbers} do
      result = Enum.reduce(numbers, 0, &Calculator.add/2)
      assert result == 15
    end
  end

  # ✅ Test both success and error paths
  describe "error handling" do
    test "returns ok tuple on success" do
      assert {:ok, _} = Calculator.divide(10, 2)
    end

    test "returns error tuple on failure" do
      assert {:error, :division_by_zero} = Calculator.divide(10, 0)
    end
  end

  # ============================================================================
  # COVERAGE NOTES
  # ============================================================================

  # Unit tests should aim for high coverage (>80%) of:
  # - Pure functions
  # - Business logic
  # - Validations
  # - Transformations
  # - Error handling paths
  #
  # Don't aim for 100% coverage at the expense of test quality.
  # Focus on testing behavior, not implementation details.
end
