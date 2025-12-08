---
description: Quality-driven code refactoring with architect guidance
argument-hint: "[file|directory to refactor]"
---

# Refactor Command

Quality-driven code refactoring using architect and implementer subagents.

## Overview

This command orchestrates a complete refactoring workflow:

1. Architect analyzes code and presents refactoring options
2. You approve the approach
3. Implementer executes refactoring with updated tests
4. Code reviewer verifies improvements
5. QA tester validates no regressions
6. Git commit

## Usage

```bash
/refactor lib/your_app/agents/tool_executor.ex
/refactor lib/your_app/data_pipeline/
/refactor lib/your_app_web/live/analytics_live.ex
```

## How It Works

**Workflow:**

1. **Target Code**: $ARGUMENTS specifies file or directory to refactor
2. **Invoke Architect**: Analyze code quality, identify issues, present
   refactoring options
3. **User Approval**: You select which approach to use
4. **Invoke Implementer**: Execute refactoring and update tests
5. **Invoke Code Reviewer**: Review changes for quality improvements
6. **Address Findings**: If reviewer finds issues, implementer fixes them
7. **Invoke QA Tester**: Run regression tests
8. **Git Commit**: Commit refactored code

**Thin Orchestration**: This command coordinates the subagents. Subagents do the
analysis, refactoring, review, and testing.

## Subagents Used

**Architect**: Analyzes code quality and designs refactoring approach
**Implementer**: Executes refactoring and updates tests **Code Reviewer**:
Verifies improvements and identifies remaining issues **QA Tester**: Validates
no regressions introduced

## Examples

### Example 1: Refactor Single Module

```bash
/refactor lib/your_app/agents/tool_executor.ex
```

**What happens:**

1. Architect analyzes tool_executor.ex
2. Identifies issues: complex conditionals, unclear error handling, missing
   specs
3. Presents options: extract functions, add pattern matching, improve error
   handling
4. You approve approach
5. Implementer refactors code and updates tests
6. Code reviewer verifies improvements
7. QA tester runs agent execution tests
8. Commits: "refactor: simplify tool executor with pattern matching"

### Example 2: Refactor Directory

```bash
/refactor lib/your_app/data_pipeline/
```

**What happens:**

1. Architect analyzes all data_pipeline modules
2. Identifies patterns: duplicated validation logic, inconsistent error handling
3. Presents options: extract shared modules, standardize error types, add
   behaviors
4. You approve consolidation approach
5. Implementer refactors directory structure and tests
6. Code reviewer checks consistency
7. QA tester validates data pipeline flows
8. Commits: "refactor: consolidate data pipeline validation logic"

### Example 3: Refactor for Performance

```bash
/refactor lib/your_app/query_executor.ex - focus on performance
```

**What happens:**

1. Architect analyzes query execution performance
2. Identifies bottlenecks: N+1 queries, missing indexes, inefficient joins
3. Presents optimization options
4. You approve caching + query optimization
5. Implementer refactors with performance improvements
6. Code reviewer verifies correctness maintained
7. QA tester runs performance benchmarks
8. Commits: "refactor: optimize query executor with caching"

### Example 4: Extract Reusable Pattern

```bash
/refactor lib/your_app_web/live/ - extract shared LiveView patterns
```

**What happens:**

1. Architect analyzes LiveView modules
2. Identifies duplicated patterns: auth checks, assign helpers, PubSub
   subscriptions
3. Presents options: create shared helpers, extract LiveView components, add
   **using** macro
4. You approve component extraction
5. Implementer creates components and refactors LiveViews
6. Code reviewer checks all LiveViews use new components
7. QA tester validates UI flows
8. Commits: "refactor: extract shared LiveView components"

### Example 5: Improve Test Structure

```bash
/refactor test/your_app/agents/ - improve test organization
```

**What happens:**

1. Architect analyzes test structure
2. Identifies issues: test duplication, missing setup helpers, unclear test
   names
3. Presents options: extract test helpers, use setup blocks, improve naming
4. You approve helper extraction
5. Implementer refactors tests with shared helpers
6. Code reviewer verifies tests still pass
7. QA tester runs full test suite
8. Commits: "refactor: extract agent test helpers"

## Refactoring Principles

The architect follows these principles:

1. **Preserve Behavior** - Functionality must remain identical
2. **Improve Quality** - Code should be cleaner, clearer, more maintainable
3. **Maintain Tests** - Update tests to match refactored code
4. **Keep Actor Context** - Never remove authorization checks
5. **Follow Patterns** - Use existing project conventions
6. **KISS Principle** - Simplify, don't add complexity

## Troubleshooting

### Refactoring Breaks Tests

**Problem**: Tests fail after refactoring

**Solution**:

1. Code reviewer should catch this before commit
2. If tests fail, implementer fixes them
3. QA tester validates all tests pass before commit

### Unclear What to Refactor

**Problem**: File is large, unclear focus area

**Solution**: Add specific guidance:

```bash
/refactor lib/your_app/agents/analytics_agent.ex - focus on prompt generation logic
```

### Refactoring Changes Behavior

**Problem**: Implementer accidentally changed functionality

**Solution**:

1. Code reviewer verifies behavior preserved
2. QA tester runs regression tests
3. If behavior changed, implementer reverts and tries again

### Too Aggressive Refactoring

**Problem**: Architect proposes rewriting everything

**Solution**: Request incremental approach:

```bash
/refactor lib/your_app/modeling/ - incremental refactoring only, no rewrites
```

### Missing Test Updates

**Problem**: Tests don't reflect refactored code

**Solution**:

1. Code reviewer checks test coverage
2. Implementer updates tests to match new structure
3. QA tester validates test quality

## Quality Criteria

Refactoring improves code on these dimensions:

1. **Readability** - Easier to understand
2. **Maintainability** - Easier to modify
3. **Testability** - Easier to test
4. **Performance** - More efficient (if optimization refactoring)
5. **Consistency** - Follows project patterns
6. **Documentation** - Better module/function docs

## Anti-Patterns to Avoid

The architect will avoid these refactoring anti-patterns:

- ❌ Bypassing authorization with `authorize?: false`
- ❌ Removing actor context from Ash operations
- ❌ Changing transaction boundaries
- ❌ Removing multi-tenancy safeguards
- ❌ Making behavior changes (not refactoring)
- ❌ Adding unnecessary abstraction
- ❌ Premature optimization without profiling

## Integration with Other Commands

**Design → Refactor Flow:**

```bash
/design How to refactor resource lifecycle?
# Review options, approve approach
/refactor lib/your_app/resources/lifecycle.ex
```

**Review → Refactor Flow:**

```bash
/review lib/your_app/data_pipeline/
# See quality issues in report
/refactor lib/your_app/data_pipeline/ - address issues from review
```

**Refactor → QA Flow:**

```bash
/refactor lib/your_app_web/live/dashboard_live.ex
# Refactoring complete
/qa Test dashboard flow end-to-end
```

## Best Practices

### Start Small

**Good:**

```bash
/refactor lib/your_app/agents/tool_executor.ex
```

**Too Big:**

```bash
/refactor lib/your_app/
```

### Be Specific About Goals

**Good:**

```bash
/refactor lib/your_app/llm/client.ex - simplify error handling
```

**Too Vague:**

```bash
/refactor lib/your_app/llm/client.ex - make it better
```

### Refactor When You Have Tests

**Good:**

- Tests exist → refactor safely with regression checks

**Risky:**

- No tests → refactoring might break things silently

If no tests exist, write them first:

```bash
/implement Add test coverage for lib/your_app/validators/validator.ex
/refactor lib/your_app/validators/validator.ex
```

## Success Criteria

Refactoring succeeds when:

- ✅ Code quality improved
- ✅ All tests pass
- ✅ No behavior changes
- ✅ Code reviewer approves
- ✅ QA tester validates no regressions
- ✅ Changes committed

## Git Commit Format

```bash
refactor: {brief description}

{Explain what was refactored and why}
{List key improvements}
```

Example:

```bash
refactor: extract shared LiveView authentication logic

- Created AuthLive component for consistent auth checks
- Reduced code duplication across 5 LiveView modules
- Improved test coverage with shared test helpers
```

## Remember

> **Refactor with confidence. Review with rigor. Test thoroughly.**

Good refactoring makes code better without changing behavior. Use architect
guidance, execute carefully, review thoroughly, and test completely.

**Improve quality. Preserve functionality. Maintain velocity.**
