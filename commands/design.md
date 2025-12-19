---
description: Architect-driven design review and documentation update
argument-hint: "[design challenge description]"
---

# Design Command

Architect-driven design review and documentation update using the architect
subagent.

## Overview

This command invokes the architect subagent to:

1. Analyze your design challenge
2. Present 3-5 solution options (sorted by quality)
3. Update DESIGN/ documentation after you approve

## Usage

```bash
/design Add email verification to user registration
/design Add real-time updates to feature X
/design How should we handle webhook retry logic?
```

## How It Works

**Workflow:**

1. **Receive Challenge**: $ARGUMENTS contains your design challenge
2. **Invoke Architect**: Launch architect subagent to analyze and generate
   options
3. **Review Options**: Architect presents 3-5 solutions sorted by quality
4. **User Selection**: You choose which option to implement
5. **Update Docs**: Architect updates DESIGN/ using doc-hygiene skill

**Thin Orchestration**: This command only coordinates the workflow. The
architect subagent does all the heavy lifting.

## Architect Subagent

The architect subagent:

- Analyzes design challenges in context of existing architecture
- Evaluates options against quality criteria (design alignment, best practices,
  maintainability)
- Sorts solutions by quality score
- Updates design documentation using doc-hygiene skill
- Follows DRY, KISS, and project conventions

## Examples

### Example 1: Feature Design

```bash
/design Add email verification to user registration
```

**What happens:**

1. Architect analyzes current authentication flow
2. Reviews existing patterns in DESIGN/concepts/authentication.md
3. Presents options (e.g., token-based, magic link, third-party service)
4. You select preferred approach
5. Architect updates DESIGN/concepts/authentication.md with new flow

### Example 2: Refactoring Architecture

```bash
/design Refactor resource workflow to support versioning
```

**What happens:**

1. Architect reviews current workflow implementation
2. Analyzes immutability pattern and version control
3. Presents options for versioning support
4. You approve solution
5. Architect updates DESIGN/concepts/resources.md

### Example 3: Integration Design

```bash
/design Add webhook support for external data updates
```

**What happens:**

1. Architect reviews job processing patterns (Oban)
2. Evaluates retry logic, idempotency, security
3. Presents webhook architecture options
4. You select approach
5. Architect updates DESIGN/architecture/ with webhook patterns

### Example 4: Performance Optimization

```bash
/design Optimize query execution for large datasets
```

**What happens:**

1. Architect analyzes current query execution flow
2. Reviews caching, connection pooling, query optimization
3. Presents optimization strategies
4. You choose approach
5. Architect updates DESIGN/architecture/data-layer.md

### Example 5: Security Enhancement

```bash
/design Add audit logging for all data modifications
```

**What happens:**

1. Architect reviews actor context and multi-tenancy
2. Analyzes audit trail requirements
3. Presents logging architecture options
4. You approve solution
5. Architect updates DESIGN/architecture/security.md

## Skills Used

**doc-hygiene**: Maintains design documentation consistency

- Keeps docs DRY (no duplication)
- Ensures completeness without excessive detail
- Uses generic patterns over specific implementations
- Updates related docs when architecture changes

## Troubleshooting

### Architect Gives Generic Solutions

**Problem**: Solutions don't fit your specific codebase patterns

**Solution**: Provide more context in your challenge:

```bash
/design Add rate limiting - we use Ash policies for authz, prefer similar for rate limiting
```

### Documentation Not Updated

**Problem**: Architect analyzed but didn't update docs

**Solution**: Explicitly request doc updates:

```bash
/design Update DESIGN/ to reflect new webhook architecture discussed earlier
```

### Too Many Options

**Problem**: Architect presents 7+ options, hard to choose

**Solution**: Request fewer options with specific constraints:

```bash
/design Add caching - only options that work with Phoenix LiveView and maintain actor context
```

### Wrong Documentation Files Updated

**Problem**: Architect updated wrong section of DESIGN/

**Solution**: Specify target documentation:

```bash
/design Add batch processing - update DESIGN/concepts/jobs.md
```

### Design Doesn't Align with Codebase

**Problem**: Proposed design conflicts with existing patterns

**Solution**: This shouldn't happen - architect analyzes existing patterns. If
it does, provide feedback:

```
The proposed solution bypasses actor context, which violates our security model. Please revise.
```

## Quality Criteria

The architect evaluates solutions using these criteria (in priority order):

1. **Design Alignment** - Follows existing patterns in DESIGN/
2. **Best Practices** - Uses Ash/Phoenix/Elixir idioms correctly
3. **Long-term Maintainability** - Easy to extend, test, understand
4. **Security** - Proper actor context, authorization, multi-tenancy
5. **Simplicity** - KISS principle, minimal complexity
6. **Performance** - Efficient queries, proper caching, scalable

## Integration with Other Commands

**Design → Implement Flow:**

```bash
/design Add OAuth provider support
# Review architect's solution
# Approve option
/implement Add OAuth provider support (use Option 1 from design)
```

**Design → Refactor Flow:**

```bash
/design How to refactor agent tool execution for better observability?
# Review options
# Approve approach
/refactor lib/your_app/agents/tool_executor.ex
```

## Best Practices

### Be Specific

**Good:**

```bash
/design Add PostgreSQL connection pooling with health checks and graceful shutdown
```

**Too Vague:**

```bash
/design Make database better
```

### Reference Existing Patterns

**Good:**

```bash
/design Add data export - prefer Oban job pattern like we use for background processing
```

**Generic:**

```bash
/design Add data export feature
```

### Specify Constraints

**Good:**

```bash
/design Add file storage - must support multi-tenancy and work with existing actor context
```

**Missing Context:**

```bash
/design Add file storage
```

## Success Criteria

Command succeeds when:

- ✅ Architect presents quality-sorted options
- ✅ You select preferred solution
- ✅ DESIGN/ documentation updated
- ✅ Updates follow doc-hygiene principles
- ✅ Solution aligns with existing architecture

## Remember

> **Architect first. Implement second.**

Good design saves time during implementation. Use this command before starting
complex features or major refactorings.

**Think deeply. Design carefully. Document thoroughly.**

---

## Execute

**Design Challenge:** $ARGUMENTS

Follow the workflow above to handle this design challenge.
