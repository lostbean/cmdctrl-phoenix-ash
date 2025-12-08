# Sub-Agent Architecture

This Elixir/Phoenix/Ash project uses specialized sub-agents to efficiently
handle complex, multi-step tasks while managing context budget effectively.

## Overview

**Why Sub-Agents?**

- **Context Efficiency**: Each sub-agent gets a fresh 200K token budget
- **Focused Responsibility**: Single, clear purpose per agent
- **Parallel Execution**: Multiple agents can run concurrently
- **Cost Optimization**: Use cheaper models (like Haiku) for focused tasks

## Available Agents

### qa-tester

**Purpose**: Flexible QA testing - handles predefined flows, user-defined
scenarios, and bug reproductions

**Model**: Haiku (fast, cost-efficient)

**Tools**: Chrome DevTools MCP, Tidewave MCP, Write, Read, Glob, Bash

**When to Use**:

- PROACTIVELY when testing any flow from `DESIGN/workflows/`
- User requests to test a specific scenario or situation
- Verifying bug reproductions or fixes

**Location**: `.claude/agents/qa-tester.md`

**Invocation Examples**:

**Predefined Flow**:

```javascript
Task({
  subagent_type: "qa-tester",
  description: "Test Flow 2: Resource Management",
  prompt:
    "Test Flow 2 (Resource Management). Flow spec: @DESIGN/workflows/flow-02-resource-management.md. Database: seeded.",
});
```

**User-Defined Scenario**:

```javascript
Task({
  subagent_type: "qa-tester",
  description: "Test input validation",
  prompt: `Test this scenario:

**Objective**: Verify form with invalid input shows validation error
**Steps**: Submit form with invalid data
**Success Criteria**: Error shown, submission rejected
**Database**: Seeded, use test user credentials from seeds.exs`,
});
```

**Bug Reproduction**:

```javascript
Task({
  subagent_type: "qa-tester",
  description: "Verify navigation bug",
  prompt: `Reproduce bug: Navigation shows incorrect state.

**Steps**: Login → Navigate to page → Check state
**Expected**: Shows correct state
**Actual**: Incorrect/empty state
**Verify**: Does issue still exist?`,
});
```

## Agent File Format

All agent files use frontmatter format:

```markdown
---
name: agent-name
description: When to invoke this agent (be specific and action-oriented)
tools: tool1, tool2, tool3 # Optional - inherits all if omitted
model: haiku # Optional - haiku, sonnet, or inherit (default)
---

Your agent's system prompt goes here.

Define role, capabilities, workflow, constraints, and expected outputs. Be
specific with examples and patterns.
```

## Creating New Agents

### 1. Define Purpose

Agents should have **focused responsibilities** (but can be flexible within that
focus):

✅ Good: "Test user flows, scenarios, or bug reproductions with UI + backend
verification" ✅ Good: "Implement a specific feature phase with unit tests" ✅
Good: "Review code changes for a specific aspect (security, performance, style)"
❌ Bad: "Help with development tasks" (too broad) ❌ Bad: "Do anything the user
asks" (no focus)

### 2. Choose Model

**Haiku**: Fast, cheap - Good for focused tasks with clear instructions

- QA testing
- Code review
- File operations
- Data processing

**Sonnet**: Powerful, expensive - Use for complex reasoning

- Design decisions
- Architecture planning
- Complex refactoring
- Debugging hard issues

**Inherit**: Use orchestrator's model (default)

### 3. Limit Tools

Only grant tools necessary for the task:

```markdown
tools: Read, Write, Edit # File operations only tools: mcp**tidewave**_, Bash #
Backend inspection only tools: mcp**chrome-devtools**_ # UI testing only
```

Benefits:

- Better security
- Clearer focus
- Faster execution

### 4. Write Clear Instructions

Include:

- **Mission statement**: What is the agent's goal?
- **Workflow steps**: How should it approach the task?
- **Constraints**: What should it NOT do?
- **Output format**: What should it return?
- **Examples**: Show concrete patterns

Use **proactive language**:

- "PROACTIVELY check git history before reporting"
- "Use snapshots PROACTIVELY to verify state"
- "IMMEDIATELY create issue files when found"

### 5. Test and Iterate

1. Create agent file in `.claude/agents/`
2. Invoke via orchestrator
3. Review results
4. Refine instructions
5. Commit to version control

## Orchestration Patterns

### Sequential (Simple)

Execute agents one at a time:

```javascript
// Flow 1
Task({
  subagent_type: "qa-flow-tester",
  description: "Test Flow 1",
  prompt: "Test Flow 1...",
});
// Wait for completion

// Flow 2
Task({
  subagent_type: "qa-flow-tester",
  description: "Test Flow 2",
  prompt: "Test Flow 2...",
});
```

**Benefits**:

- Simple coordination
- Clear progress tracking
- Easy debugging

### Parallel (Advanced)

Launch multiple agents in single message:

```javascript
// All 3 in one message
Task({ subagent_type: "qa-flow-tester", description: "Flow 2", prompt: "..." });
Task({ subagent_type: "qa-flow-tester", description: "Flow 3", prompt: "..." });
Task({ subagent_type: "qa-flow-tester", description: "Flow 4", prompt: "..." });
```

**Benefits**:

- 3-4x faster execution
- Efficient resource usage

**Complexity**:

- Requires coordination (e.g., browser tabs)
- Harder error recovery
- More complex progress tracking

## Context Budget Strategy

### Without Sub-Agents

```
Main thread: 100K per flow × 7 flows = 700K tokens ❌
Result: Exhaust context after 2-3 flows
```

### With Sub-Agents

```
Orchestrator: ~10K setup + 7×2K launches = ~24K tokens ✅
Each agent: Fresh 200K budget, uses ~40-60K
Total capacity: 1.4M tokens across all agents ✅
Result: Can test all 7 flows comfortably
```

### Orchestrator Efficiency

**Orchestrator should**:

- ✅ Discover flows (glob)
- ✅ Track progress (TodoWrite)
- ✅ Launch agents (compact prompts)
- ✅ Aggregate results (read issue files)

**Orchestrator should NOT**:

- ❌ Take snapshots directly
- ❌ Execute test steps
- ❌ Read large files (let agents do it)
- ❌ Explore application state

## Best Practices

1. **Focus over Flexibility**: Narrow scope = better results
2. **Proactive Behavior**: Encourage action with explicit language
3. **Tool Minimalism**: Fewer tools = clearer purpose
4. **Example-Driven**: Show patterns, don't just describe
5. **Version Control**: Track agent evolution in git
6. **Cost-Aware**: Use Haiku when possible, Sonnet when necessary

## Examples

### QA Testing

- **Agent**: qa-flow-tester (Haiku)
- **Orchestrator**: /qa-manual
- **Pattern**: Sequential or parallel per flow/scenario
- **Flexibility**: Handles predefined flows, custom scenarios, bug reproductions
- **Context**: ~24K orchestrator + 7×50K agents = ~374K total

### Feature Implementation

- **Agent**: phase-implementer (Sonnet)
- **Orchestrator**: /implement-phase
- **Pattern**: Sequential with checkpoints
- **Context**: ~30K orchestrator + 5×100K agents = ~530K total

### Code Review

- **Agent**: code-reviewer (Haiku)
- **Orchestrator**: /review-pr
- **Pattern**: Parallel per file category
- **Context**: ~15K orchestrator + 4×40K agents = ~175K total

## Related Documentation

- **Testing Strategy**: `.claude/context/testing-strategy.md`
- **Agent Architecture**: `.claude/context/agent-architecture.md`
- **MCP Tools Guide**: `.claude/context/mcp-tools-guide.md`
- **Usage Rules**: `AGENTS.md` (framework patterns from package authors)

---

**Philosophy**: Keep agents focused, instructions clear, and workflows simple.
