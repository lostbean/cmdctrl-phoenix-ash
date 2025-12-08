---
description:
  Complete feature implementation with design, code, review, and testing
argument-hint: "[feature description]"
---

# Implement Command

Complete feature implementation orchestrating architect, implementer,
code-reviewer, and qa-tester subagents.

## Overview

This command orchestrates a complete feature development workflow:

1. Architect designs and presents solution options
2. You approve the design
3. Architect updates DESIGN/ documentation
4. Implementer writes code and tests
5. Code reviewer validates quality
6. Address review findings if any
7. QA tester validates functionality
8. Git commit

## Usage

```bash
/implement Add email verification to user registration
/implement Add webhook support for external data updates
/implement Add audit logging for data modifications
/implement Optimize analytics query performance
```

## How It Works

**Feature to Implement**: $ARGUMENTS

**Workflow:**

1. **Invoke Architect**: Analyze feature requirements, present 3-5 design
   options
2. **User Approval**: You select which design approach to use
3. **Update Design Docs**: Architect updates DESIGN/ with approved design
4. **Invoke Implementer**: Write code and tests following the design
5. **Invoke Code Reviewer**: Review implementation quality
6. **Address Findings**: If reviewer finds issues, implementer fixes them
7. **Invoke QA Tester**: Validate feature works end-to-end
8. **Git Commit**: Commit feature with clear message

**Thin Orchestration**: This command coordinates the workflow. Subagents do all
the design, implementation, review, and testing work.

## Server Management During Implementation

**See**: `../../.claude/references/dev-app-management.md` for complete rules.

- Phoenix hot-reloads code automatically - changes apply immediately
- Never stop/start server or reset dev DB - ask user
- Use Tidewave MCP to verify: `project_eval`, `get_logs`, `execute_sql_query`
- Test DB resets OK: `MIX_ENV=test mix db.reset`

## Subagents Used

**Architect**: Designs feature and updates documentation **Implementer**: Writes
code and tests **Code Reviewer**: Reviews quality and adherence to patterns **QA
Tester**: Validates functionality end-to-end

## Examples

### Example 1: Authentication Feature

```bash
/implement Add email verification to user registration
```

**What happens:**

1. Architect analyzes authentication flow
2. Presents options: token-based, magic link, third-party service
3. You approve token-based approach
4. Architect updates DESIGN/concepts/authentication.md
5. Implementer creates:
   - `lib/your_app/accounts/verification_token.ex` resource
   - Email notification action
   - LiveView components for verification UI
   - Tests for verification flow
6. Code reviewer checks:
   - Actor context present
   - Multi-tenancy enforced
   - Error handling complete
   - Tests comprehensive
7. QA tester validates:
   - User can register and verify
   - Invalid tokens rejected
   - Expired tokens handled
8. Commits: "feat: add email verification to user registration"

### Example 2: Data Pipeline Feature

```bash
/implement Add webhook support for external data updates
```

**What happens:**

1. Architect designs webhook architecture
2. Presents options: Oban jobs, Phoenix channels, external service
3. You approve Oban-based approach
4. Architect updates DESIGN/concepts/jobs.md
5. Implementer creates:
   - Webhook resource with validation
   - Oban worker for processing
   - Signature verification
   - Retry logic
   - Tests for success and failure cases
6. Code reviewer validates security and idempotency
7. QA tester validates webhook flow end-to-end
8. Commits: "feat: add webhook support for external data updates"

### Example 3: Data Export Feature

```bash
/implement Add query result export to CSV
```

**What happens:**

1. Architect designs export architecture
2. Presents options: synchronous, async background job, streaming
3. You approve async Oban job for large results
4. Architect updates DESIGN/concepts/exports.md
5. Implementer creates:
   - Export action on query results
   - Oban worker for CSV generation
   - Download link in LiveView
   - Tests for export flow
6. Code reviewer checks actor context and file handling
7. QA tester validates export functionality
8. Commits: "feat: add CSV export for query results"

### Example 4: Performance Optimization

```bash
/implement Add caching layer for metadata
```

**What happens:**

1. Architect designs caching strategy
2. Presents options: ETS, Cachex, database caching, Redis
3. You approve Cachex with TTL
4. Architect updates DESIGN/architecture/data-layer.md
5. Implementer creates:
   - Cache module with Cachex
   - Cache warming strategy
   - Invalidation strategy
   - Performance tests
6. Code reviewer validates cache consistency
7. QA tester validates caching performance
8. Commits: "feat: add metadata caching layer"

### Example 5: UI Enhancement

```bash
/implement Add real-time progress tracking for data uploads
```

**What happens:**

1. Architect designs progress tracking
2. Presents options: polling, PubSub, Phoenix channels
3. You approve PubSub-based approach
4. Architect updates DESIGN/architecture/liveview.md
5. Implementer creates:
   - Progress events in upload workflow
   - PubSub publisher
   - LiveView subscriber with progress bar
   - Tests for progress updates
6. Code reviewer checks PubSub async safety
7. QA tester validates progress UI
8. Commits: "feat: add real-time progress for uploads"

## Implementation Principles

These principles are defined in **[CLAUDE.md](../../CLAUDE.md)** (see
Development Conventions and Common Pitfalls sections). The implementer follows:

1. **Actor Context** - Always pass explicit actor
2. **Multi-Tenancy** - Enforce organization isolation
3. **Transactions** - Use `transaction? true` for multi-step ops
4. **Test First** - Write tests before or with implementation
5. **Clean Code** - KISS principle, readable, maintainable
6. **Documentation** - Update module/function docs

See **[CLAUDE.md](../../CLAUDE.md)** for detailed migration workflow, daily
commands, and framework-specific conventions.

## Troubleshooting

### Design Options Unclear

**Problem**: Architect's options don't match your vision

**Solution**: Provide more specific requirements:

```bash
/implement Add rate limiting - prefer Ash policy-based approach over third-party middleware
```

### Implementation Incomplete

**Problem**: Implementer didn't complete all aspects

**Solution**: Code reviewer should catch this. If not, provide feedback:

```
The implementation is missing error handling for network failures. Please add.
```

### Tests Failing

**Problem**: Implementer's tests don't pass

**Solution**: Code reviewer validates tests pass. If they fail:

1. Implementer fixes failing tests
2. QA tester re-validates

### Review Finds Major Issues

**Problem**: Code reviewer finds security or design problems

**Solution**:

1. Implementer addresses high-priority findings
2. Code reviewer re-reviews
3. Repeat until quality acceptable
4. Then proceed to QA testing

### QA Finds Bugs

**Problem**: QA tester finds issues in implementation

**Solution**:

1. Implementer fixes bugs
2. Adds regression tests
3. QA tester re-validates
4. Repeat until feature works correctly

## Quality Criteria

Feature implementation must meet:

1. **Functional** - Feature works as designed
2. **Tested** - Comprehensive test coverage
3. **Secure** - Actor context, authorization, validation
4. **Maintainable** - Clean, documented, follows patterns
5. **Performant** - No obvious performance issues
6. **Documented** - Design docs and code docs updated

## Integration with Other Commands

**Design → Implement Flow:**

```bash
/design Add OAuth provider support
# Review and approve option
/implement Add OAuth provider support (use approved design)
```

**Implement → Review → Refactor Flow:**

```bash
/implement Add webhook retry logic
/review lib/your_app/webhooks/
# If review suggests improvements
/refactor lib/your_app/webhooks/handler.ex
```

**Implement → QA Flow:**

```bash
/implement Add analytics dashboard
/qa Test analytics dashboard with various query types
```

## Best Practices

### Be Specific

**Good:**

```bash
/implement Add PostgreSQL query timeout with configurable limit and error handling
```

**Too Vague:**

```bash
/implement Make queries faster
```

### One Feature at a Time

**Good:**

```bash
/implement Add email verification
# Wait for completion
/implement Add password reset
```

**Too Much:**

```bash
/implement Add email verification, password reset, OAuth, 2FA, and SSO
```

### Reference Existing Patterns

**Good:**

```bash
/implement Add export job - use same Oban pattern as other background jobs
```

**Generic:**

```bash
/implement Add export feature
```

## Success Criteria

Implementation succeeds when:

- ✅ Feature designed by architect
- ✅ Design approved by you
- ✅ DESIGN/ docs updated
- ✅ Code and tests written
- ✅ Code review passes
- ✅ QA testing passes
- ✅ Changes committed

## Git Commit Format

**BEFORE committing, run `./scripts/pre-commit.sh` and ensure it passes:**

- ✅ No errors
- ✅ No warnings
- ✅ Clean logs

If pre-commit fails, fix all issues before committing.

```bash
feat: {brief feature description}

{Explain what the feature does}
{Note any important design decisions}
{Reference any related issues or docs}
```

**IMPORTANT:** Do NOT add commit footers like `Co-Authored-By` or
`🤖 Generated with Claude Code`.

Example:

```bash
feat: add email verification to user registration

- Implemented token-based verification flow
- Added email notification with verification link
- Updated authentication design docs
- Comprehensive test coverage for verification workflow

Follows pattern from DESIGN/concepts/authentication.md
```

## Remember

> **Design first. Implement carefully. Review thoroughly. Test completely.**

Good implementation starts with good design. Use the architect to explore
options before writing code.

**Think before coding. Code with quality. Validate with rigor.**
