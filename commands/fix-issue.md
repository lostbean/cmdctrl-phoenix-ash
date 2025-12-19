---
description: |
  Systematic issue resolution with investigation, design, implementation, and
  testing
---

# Fix Issue Command

Systematic issue resolution orchestrating debugger, architect, implementer,
code-reviewer, and qa-tester subagents.

## Overview

This command orchestrates a complete issue resolution workflow:

1. You select an issue file from IMPLEMENTATION/TODOs/
2. Initial validation\*\*: Check if issue still exists or already fixed
3. Debugger investigates, reproduces, and finds root cause
4. Architect generates solution options sorted by quality
5. You approve the solution
6. Implementer fixes the issue and adds tests
7. Code reviewer validates the fix
8. Address review findings if any
9. Final validation\*\*: Verify fix resolves the issue before commit
10. Remove issue file and commit

## Usage

```bash
/fix-issue
```

The command will:

1. List available issues in IMPLEMENTATION/TODOs/
2. Let you select which issue to fix
3. Orchestrate the fix workflow

## How It Works

**Workflow:**

1. **Select Issue**: List issues in IMPLEMENTATION/TODOs/, you select one

2. **Phase 0: Initial Validation**
   - Check git history for recent commits related to issue
   - Determine if issue is testable via browser/MCP tools (UI flows, user
     actions)
   - If testable, invoke QA tester in validation mode:
     - Context: "Verify if [issue] still reproduces"
     - QA reports findings in completion message
     - Returns: PASS (cannot reproduce) | FAIL (still exists) | UNCLEAR
   - Decision:
     - If PASS: Ask user to confirm issue closure (may be already fixed)
     - If FAIL: Proceed to debugger investigation
     - If UNCLEAR: Proceed to debugger for deeper investigation

3. **Invoke Debugger**: Investigate issue, reproduce, identify root cause (use
   sub-agent)

4. **Invoke Architect**: Generate 3-5 solution options (sorted by quality) (use
   sub-agent)

5. **User Approval**: You select which solution to implement

6. **Invoke Implementer**: Fix issue, add tests to prevent regression (use
   sub-agent)

7. **Invoke Code Reviewer**: Review fix quality and completeness (use sub-agent)

8. **Address Findings**: If reviewer finds issues, implementer fixes them

9. **Phase 5: Final Validation**: (use sub-agent)
   - Determine if issue is testable end-to-end (same criteria as Phase 0)
   - If testable, invoke QA tester in validation mode:
     - Context: "Verify the fix resolves [original issue]"
     - If issue referenced specific test (e.g., "US-007 Test 3.2"), re-run that
       test
     - QA reports findings in completion message
     - Returns: PASS (fixed) | FAIL (not fixed) | new issues found
   - Decision:
     - If PASS: Proceed to commit
     - If FAIL: Return to implementer for revision
     - If new issues found: Create new issue files, but still commit original
       fix

10. **Remove Issue File**: Delete the issue file from IMPLEMENTATION/TODOs/

11. **Git Commit**: Commit fix with clear message

**Thin Orchestration**: This command coordinates the workflow. Subagents do all
the investigation, design, implementation, review, and testing work.

## Validation Phases (New)

### Phase 0: Initial Validation

**Purpose**: Avoid wasting time investigating issues that are already fixed.

**When to run**:

- Always run for issues that can be tested via UI/browser
- Skip for internal refactorings or code-only changes

**How to determine testability**:

- Issue describes UI behavior or user flows → Testable
- Issue references user story test case (e.g., "US-007 Test 3.2") → Testable
- Issue has "Steps to Reproduce" with URLs and clicks → Testable
- Issue is purely code/architecture/internal → Not testable (skip validation)

**Steps**:

1. **Check git history**:

   ```bash
   # Search commits for keywords from issue
   git log --oneline --all --grep="keyword1\|keyword2"

   # Or check recent commits in relevant areas
   git log --oneline -20 -- lib/your_app/area/
   ```

2. **If testable, invoke QA tester in validation mode**:

   > "You are in validation mode. Verify if issue [qa-issue-001] still
   > reproduces. Follow the reproduction steps in the issue file and report
   > Pass/Fail/Unclear in your completion message."

3. **Parse validation outcome**:
   - ✅ PASS (cannot reproduce) → Likely already fixed
   - ❌ FAIL (still reproduces) → Confirmed, proceed to debugging
   - ⚠️ UNCLEAR → Needs deeper investigation

4. **Make decision**:

   ```
   If PASS:
     Ask user: "Validation shows issue may be fixed. Close issue? [Y/n]"
     If Yes: Remove issue file, done
     If No: Proceed to debugger (user knows something we don't)

   If FAIL:
     Proceed to debugger (Phase 1)

   If UNCLEAR:
     Proceed to debugger (Phase 1)
   ```

### Phase 5: Final Validation

**Purpose**: Ensure fix actually resolves the issue before committing.

**When to run**:

- Same testability criteria as Phase 0
- If testable via UI/browser → Run validation
- If code-only change → Skip (unit tests are sufficient)

**Steps**:

1. **Determine scope**:
   - If issue references specific test case → Re-run that exact test
   - Otherwise → Follow original reproduction steps

2. **Invoke QA tester in validation mode**:

   > "You are in validation mode. Verify the fix resolves issue [qa-issue-001].
   > Follow the original reproduction steps and confirm issue is now fixed.
   > Report Pass/Fail/Unclear in your completion message."

3. **Parse validation outcome**:
   - ✅ PASS → Fix verified, proceed to commit
   - ❌ FAIL → Fix incomplete, return to implementer
   - ⚠️ New issues found → Create new issue files, proceed with current commit

4. **Make decision**:

   ```
   If PASS:
     Remove issue file
     Commit fix

   If FAIL:
     Implementer revises fix
     Re-run code review
     Re-run this validation step

   If new issues found:
     Orchestrator creates new issue files from QA findings
     Original fix is good, commit it
     New issues tracked separately
   ```

## Subagents Used

**Debugger**: Investigates and reproduces issues, identifies root cause

**Architect**: Designs solution options, evaluates quality

**Implementer**: Fixes issue and adds regression tests

**Code Reviewer**: Validates fix quality and completeness

**QA Tester**: Tests fix end-to-end (two modes):

- **Validation mode** (Phase 0 & 5): Focused validation of specific issue/test
- **Full QA mode**: Comprehensive testing (used by `/qa` command)

## Server Management During Issue Resolution

**See**: `../references/dev-app-management.md` for complete rules.

- If Tidewave MCP available, app is at http://localhost:4000
- Phoenix hot-reloads during investigation - changes apply immediately
- Use Tidewave/Chrome MCP to verify fixes: `get_logs`, `execute_sql_query`,
  `take_snapshot`
- Never stop/start server or reset dev DB - ask user

## Solution Quality Criteria

The architect evaluates solutions using these criteria (in priority order).
These align with conventions in **[CLAUDE.md](../../CLAUDE.md)**:

1. **Design Alignment** - Follows existing architecture patterns from DESIGN/
2. **Best Practices** - Uses Ash/Phoenix/Elixir idioms correctly
3. **Long-term Maintainability** - Easy to extend, test, and understand
4. **Security** - Proper actor context, authorization, multi-tenancy
5. **Simplicity** - KISS principle, minimal code changes
6. **Performance** - Efficient queries, proper caching, scalable

Solutions are sorted by quality score - best design alignment first. See
**[CLAUDE.md](../../CLAUDE.md)** for detailed development conventions and common
pitfalls to avoid.

## Examples

### Example 1: UI Bug Fix

**Issue File**:
`IMPLEMENTATION/TODOs/flow-03-issue-1-empty-model-banner-incorrect.md`

**What happens:**

1. Debugger reproduces the issue:
   - Navigate to model page
   - Observe empty model banner shows wrong state
   - Inspect LiveView assigns
   - Check backend data source queries
2. Debugger identifies root cause: Banner component not updating when data
   sources change
3. Architect presents options:
   - Option A: Add PubSub subscription to banner component (best)
   - Option B: Poll for updates every 5 seconds
   - Option C: Refresh page on data source changes
4. You approve Option A
5. Implementer:
   - Adds PubSub subscription in banner component
   - Updates component on data source events
   - Adds test for banner updates
6. Code reviewer validates PubSub async safety
7. QA tester validates banner updates in real-time
8. Issue file removed
9. Commits: "fix: update empty model banner when data sources change"

### Example 2: Data Integrity Issue

**Issue File**:
`IMPLEMENTATION/TODOs/flow-02-issue-1-upload-missing-organization.md`

**What happens:**

1. Debugger reproduces:
   - Upload CSV file
   - Check database for organization_id
   - Find some uploads missing organization_id
2. Debugger identifies root cause: After-action hook not receiving actor context
3. Architect presents options:
   - Option A: Pass actor in after-action metadata (best - follows Ash patterns)
   - Option B: Query organization_id from user in hook
   - Option C: Add database default for organization_id
4. You approve Option A
5. Implementer:
   - Updates after-action to use actor from context
   - Adds validation to ensure organization_id present
   - Adds regression test
6. Code reviewer validates actor context pattern
7. QA tester validates uploads have correct organization
8. Issue file removed
9. Commits: "fix: ensure upload after-action receives actor context"

### Example 3: Authorization Issue

**Issue File**: `IMPLEMENTATION/TODOs/security-issue-cross-tenant-access.md`

**What happens:**

1. Debugger reproduces:
   - User A tries to access User B's data
   - System allows access (security bug!)
   - Check resource policies
2. Debugger identifies root cause: Missing policy for cross-tenant reads
3. Architect presents options:
   - Option A: Add relates_to_actor_via(:organization) policy (best)
   - Option B: Filter by organization_id in action
   - Option C: Add application-level check
4. You approve Option A
5. Implementer:
   - Adds organization policy to resource
   - Updates policy tests
   - Verifies all multi-tenant resources have policy
6. Code reviewer validates all resources protected
7. QA tester validates cross-tenant access blocked
8. Issue file removed
9. Commits: "fix: add organization policy to prevent cross-tenant access"

### Example 4: Performance Issue

**Issue File**: `IMPLEMENTATION/TODOs/flow-04-issue-2-analytics-query-slow.md`

**What happens:**

1. Debugger reproduces:
   - Run analytics query
   - Observe 10+ second execution time
   - Check query plan and logs
2. Debugger identifies root cause: N+1 queries loading related data
3. Architect presents options:
   - Option A: Use Ash preloading with query optimization (best)
   - Option B: Add caching layer
   - Option C: Denormalize data
4. You approve Option A
5. Implementer:
   - Adds preload to query action
   - Optimizes database query plan
   - Adds performance test
6. Code reviewer validates query efficiency
7. QA tester validates query performance (<1 second)
8. Issue file removed
9. Commits: "fix: optimize analytics query with proper preloading"

### Example 5: Test Failure

**Issue File**: `IMPLEMENTATION/TODOs/test-failure-analytics-agent-timeout.md`

**What happens:**

1. Debugger investigates:
   - Run failing test
   - Check logs for error
   - Identify async timeout issue
2. Debugger identifies root cause: Test using `async: true` with PubSub
3. Architect presents options:
   - Option A: Set `async: false` for PubSub tests (best - follows test
     patterns)
   - Option B: Mock PubSub in tests
   - Option C: Increase timeout
4. You approve Option A
5. Implementer:
   - Sets `async: false` for affected tests
   - Adds comment explaining why
   - Verifies tests pass consistently
6. Code reviewer validates test configuration
7. QA tester runs test suite multiple times
8. Issue file removed
9. Commits: "fix: disable async for PubSub tests"

## Troubleshooting

### Cannot Reproduce Issue

**Problem**: Debugger or initial validation cannot reproduce the issue

**Solution**:

1. **Phase 0 should have caught this** - If validation ran and couldn't
   reproduce, issue is likely fixed
2. Check git commits between when issue was reported and now
3. Verify environment matches issue description (database state, user role,
   etc.)
4. Ask user if issue is still valid
5. If truly fixed, remove issue file and document which commit likely fixed it

### Root Cause Unclear

**Problem**: Debugger cannot identify root cause

**Solution**:

1. Add more debugging steps
2. Check logs and database state
3. Use Tidewave to inspect runtime state
4. Use phoenix-observability skill to query agent traces and LLM performance
   data
5. If stuck, ask user for more context

### Solution Options All Poor

**Problem**: Architect's options all have low quality scores

**Solution**:

1. Debugger may have misidentified root cause - re-investigate
2. Issue may require design discussion - use `/design` command first
3. Problem may be systemic - needs larger refactoring

### Fix Introduces New Issues

**Problem**: Code reviewer finds the fix creates new problems

**Solution**:

1. Implementer revises fix
2. Architect may need to propose alternative solution
3. Code reviewer re-reviews
4. Repeat until fix is clean

### QA Finds Issue Still Exists

**Problem**: QA tester still reproduces the original issue

**Solution**:

1. Debugger re-investigates (root cause may be different)
2. Implementer may have incomplete fix
3. Repeat workflow until issue truly resolved

## Issue File Convention

Issues are stored in:

```
IMPLEMENTATION/TODOs/{category}-issue-{N}-{brief-description}.md
```

Categories:

- `flow-{NN}` - Issues from QA flow testing
- `security` - Security issues
- `performance` - Performance issues
- `bug` - General bugs
- `test-failure` - Test failures

## Integration with Other Commands

**QA → Fix Flow:**

```bash
/qa Test analytics chat flow
# QA finds issue, creates issue file
/fix-issue
# Select and fix the issue
```

**Review → Fix Flow:**

```bash
/review lib/your_app/agents/
# Review finds security issue
# Create issue file manually
/fix-issue
```

**Fix → Refactor Flow:**

```bash
/fix-issue
# Fix reveals larger code quality issues
/refactor lib/your_app/modeling/
```

## Best Practices

### One Issue at a Time

**Good:**

```bash
/fix-issue
# Fix one issue completely
# Then move to next
/fix-issue
```

**Too Much:**

```bash
# Try to fix multiple issues simultaneously
# Gets confusing and error-prone
```

### Prioritize by Severity

**Good:** Fix issues in priority order:

1. Critical (P0) - Security, data corruption
2. High (P1) - Major functionality broken
3. Medium (P2) - UX issues with workarounds
4. Low - Nice-to-have improvements

**Random:** Fix issues in random order regardless of severity

### Add Regression Tests

**Good:**

- Implementer adds test that would have caught this issue
- Prevents issue from recurring

**Missing:**

- Fix issue without adding test
- Issue might reoccur later

### Validate Fix Thoroughly

**Good:**

- QA tester validates fix end-to-end
- Checks edge cases
- Verifies no new issues introduced

**Insufficient:**

- Quick manual check
- No comprehensive validation

## Success Criteria

Issue fix succeeds when:

- ✅ Issue reproduced by debugger
- ✅ Root cause identified
- ✅ Solution approved by you
- ✅ Fix implemented with tests
- ✅ Code review passes
- ✅ QA validation passes
- ✅ Issue file removed
- ✅ Changes committed

## Git Commit Format

**BEFORE committing, run `./scripts/pre-commit.sh` and ensure it passes:**

- ✅ No errors
- ✅ No warnings
- ✅ Clean logs

If pre-commit fails, fix all issues before committing.

```bash
fix: {brief description of fix}

Resolves issue in {area/component}

{Explain root cause}
{Explain solution approach}
{Note any important details}
```

**IMPORTANT:** Do NOT add commit footers like `Co-Authored-By` or
`🤖 Generated with Claude Code`.

Example:

```bash
fix: ensure upload after-action receives actor context

Resolves issue where uploads were missing organization_id

Root cause: After-action hook not receiving actor from metadata
Solution: Pass actor explicitly in after-action metadata
Added regression test to prevent recurrence
```

## Remember

> **Investigate thoroughly. Design carefully. Fix completely. Validate
> rigorously.**

Good issue resolution starts with understanding the root cause. Don't guess -
investigate, reproduce, and diagnose before fixing.

**Understand deeply. Fix correctly. Prevent recurrence.**
