---
description: Comprehensive code quality review using code-reviewer subagent
argument-hint: "[file|directory|commit]"
---

# Review Command

Comprehensive code quality review using the code-reviewer subagent.

## Overview

This command invokes the code-reviewer subagent to analyze code and provide a
structured quality report with findings and recommendations.

## Usage

```bash
/review                                      # Review recent changes
/review lib/your_app/data_pipeline/         # Review directory
/review lib/your_app/accounts/user.ex       # Review specific file
/review HEAD~3..HEAD                         # Review last 3 commits
/review feature-branch                       # Review branch
```

## How It Works

**Workflow:**

1. **Target**: $ARGUMENTS specifies what to review (defaults to recent changes)
2. **Invoke Code Reviewer**: Launch code-reviewer subagent with target
3. **Review Report**: Receive structured report with findings
4. **Optional Fix**: Optionally invoke implementer to address issues

**Thin Orchestration**: This command only launches the code reviewer. The
subagent does all analysis and reporting.

## Code Reviewer Subagent

The code-reviewer subagent:

- Analyzes code quality across multiple dimensions
- Checks adherence to project patterns
- Identifies security issues
- Evaluates test coverage
- Provides actionable recommendations
- Generates structured reports

## Examples

### Example 1: Review Recent Changes

```bash
/review
```

**What happens:**

1. Code reviewer analyzes uncommitted changes + recent commits
2. Checks code quality, tests, documentation
3. Returns structured report with findings

**Sample Report:**

```markdown
## Code Review Report

**Target**: Recent changes (last 2 commits + working directory) **Reviewed**: 5
files, 247 lines changed

### Summary

- ✅ Code Quality: Good
- ⚠️ Test Coverage: Needs improvement
- ✅ Documentation: Complete
- ⚠️ Security: Minor issues

### Findings

#### High Priority

1. **Missing actor context in changeset** (lib/your_app/modeling/model.ex:45)
   - Issue: Operation missing `actor: user` parameter
   - Fix: Add explicit actor context

2. **No test coverage for error case** (lib/your_app/agents/tool_executor.ex:89)
   - Issue: Error path not tested
   - Fix: Add test for invalid tool execution

#### Medium Priority

...
```

### Example 2: Review Specific File

```bash
/review lib/your_app/agents/analytics_agent.ex
```

**What happens:**

1. Code reviewer analyzes analytics_agent.ex module
2. Checks against Ash/Phoenix/Elixir best practices
3. Reviews prompt generation, tool execution, error handling
4. Provides detailed feedback on improvements

### Example 3: Review Directory

```bash
/review lib/your_app/data_pipeline/
```

**What happens:**

1. Code reviewer analyzes all files in data_pipeline/
2. Checks consistency across modules
3. Identifies shared patterns and duplications
4. Suggests architectural improvements

### Example 4: Review Commit Range

```bash
/review HEAD~5..HEAD
```

**What happens:**

1. Code reviewer analyzes last 5 commits
2. Reviews changes in context of codebase
3. Validates commit follows conventions
4. Checks for regression risks

### Example 5: Pre-Merge Review

```bash
/review feature/add-email-verification
```

**What happens:**

1. Code reviewer analyzes entire feature branch
2. Compares against main branch
3. Validates feature completeness
4. Checks test coverage for new code
5. Identifies merge risks

## Review Dimensions

The code reviewer evaluates:

### 1. Code Quality

- Readability and clarity
- Function complexity
- Code duplication
- Naming conventions
- Code organization

### 2. Best Practices

- Ash resource patterns
- Phoenix LiveView conventions
- Elixir idioms
- Error handling
- Pattern matching usage

### 3. Security

- Actor context present
- Authorization checks
- Multi-tenancy enforcement
- SQL injection risks
- Input validation

### 4. Testing

- Test coverage
- Test quality
- Edge cases covered
- Integration tests present
- Async safety

### 5. Documentation

- Module docs complete
- Function docs clear
- Complex logic explained
- Design docs updated

### 6. Performance

- N+1 query risks
- Inefficient operations
- Missing indexes
- Caching opportunities

## Troubleshooting

### Review Too Generic

**Problem**: Code reviewer provides surface-level feedback

**Solution**: Request specific focus:

```bash
/review lib/your_app/agents/ - focus on security and actor context
```

### False Positives

**Problem**: Code reviewer flags intentional design decisions

**Solution**: This is useful! Either:

1. Acknowledge and document why it's intentional
2. Reconsider if the design is actually correct

Example: Code reviewer flags `authorize?: false` - this should almost never be
used in production.

### Missing Context

**Problem**: Reviewer doesn't understand broader architecture

**Solution**: Provide context in request:

```bash
/review lib/your_app/connections/pool.ex - this uses a special lifecycle for long-lived connections
```

### Too Many Findings

**Problem**: Report has 50+ findings, overwhelming

**Solution**: Focus review on priority areas:

```bash
/review lib/your_app/ - only high/critical priority issues
```

### Not Actionable

**Problem**: Findings don't suggest specific fixes

**Solution**: Request action items:

```bash
/review lib/your_app/modeling/ - provide specific fix recommendations
```

## Review Report Structure

Standard code review report includes:

```markdown
## Code Review Report

**Target**: {what was reviewed} **Scope**: {files/commits reviewed} **Date**:
{when reviewed}

### Summary

- Code Quality: {score/status}
- Test Coverage: {score/status}
- Documentation: {score/status}
- Security: {score/status}
- Performance: {score/status}

### Findings

#### Critical (P0)

{Issues that must be fixed before merge}

#### High Priority (P1)

{Issues that should be fixed soon}

#### Medium Priority (P2)

{Issues that should be addressed eventually}

#### Low Priority

{Nice-to-have improvements}

### Recommendations

{Specific actions to take}

### Positive Observations

{Things done well - learn from these}
```

## Integration with Other Commands

**Review → Fix Flow:**

```bash
/review lib/your_app/agents/
# See finding: "Missing error handling in tool execution"
/fix-issue  # Create issue and fix
```

**Review → Refactor Flow:**

```bash
/review lib/your_app/data_pipeline/
# See finding: "Code duplication across validators"
/refactor lib/your_app/data_pipeline/ - consolidate validation logic
```

**Implement → Review Flow:**

```bash
/implement Add webhook support for external events
/review lib/your_app/webhooks/
# Validate implementation quality
```

## Best Practices

### Review Early and Often

**Good:**

```bash
# Review after each feature
/implement Add OAuth support
/review lib/your_app/auth/
```

**Too Late:**

```bash
# Review after 10 features implemented
/review lib/your_app/
```

### Review Before Merging

**Good:**

```bash
/review feature/add-analytics-dashboard
# Fix any findings
# Then merge
```

**Risky:**

```bash
# Merge without review
# Deal with issues in production
```

### Review Your Own Code

**Good:**

```bash
# After implementation, review your changes
/review
# Self-review before asking others
```

**Missing Step:**

```bash
# Implement and immediately commit
# No self-review
```

### Focus Reviews

**Good:**

```bash
/review lib/your_app/agents/tool_executor.ex - focus on error handling
```

**Too Broad:**

```bash
/review lib/ - check everything
```

## When to Review

**Before Committing:**

- Self-review to catch obvious issues
- Verify tests pass
- Check documentation updated

**Before Pull Request:**

- Review entire feature branch
- Validate against acceptance criteria
- Check for security issues

**During Code Review:**

- Use as second opinion
- Identify issues human reviewer might miss
- Validate best practices

**After Bug Fix:**

- Ensure fix is complete
- Check for similar issues elsewhere
- Validate test coverage added

## Success Criteria

Review succeeds when:

- ✅ All code analyzed
- ✅ Findings categorized by priority
- ✅ Specific recommendations provided
- ✅ Positive patterns identified
- ✅ Report is actionable

## Limitations

Code reviewer cannot:

- ❌ Understand business requirements
- ❌ Know what's in your head
- ❌ Test runtime behavior
- ❌ Validate user experience
- ❌ Replace human judgment

Code reviewer can:

- ✅ Spot common mistakes
- ✅ Check against best practices
- ✅ Identify security issues
- ✅ Find code duplication
- ✅ Suggest improvements

## Remember

> **Review rigorously. Address findings. Maintain quality.**

Code review catches issues before they reach production. Use it early and often.

**Catch issues early. Fix them quickly. Learn continuously.**
