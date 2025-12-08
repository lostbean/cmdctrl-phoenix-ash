# Creating Hooks Reference

**Complete guide to creating high-quality Claude Code hooks**

Hooks are automated triggers that execute bash commands or LLM evaluations at
specific points in Claude Code's workflow, enabling policy enforcement,
validation, and context injection.

## Table of Contents

- [Hook Purpose](#hook-purpose)
- [Hook vs Other Components](#hook-vs-other-components)
- [Configuration Structure](#configuration-structure)
- [Hook Types](#hook-types)
- [Command-Based Hooks](#command-based-hooks)
- [Prompt-Based Hooks](#prompt-based-hooks)
- [Matcher Patterns](#matcher-patterns)
- [Input and Output](#input-and-output)
- [Script Structure](#script-structure)
- [Integration Patterns](#integration-patterns)
- [Security Considerations](#security-considerations)
- [Quality Checklist](#quality-checklist)
- [Real Examples](#real-examples)
- [Common Mistakes](#common-mistakes)
- [Best Practices](#best-practices)

## Hook Purpose

### What Hooks Do

Hooks provide **automated policy enforcement** and **validation** without manual
intervention:

- ✅ **Pre-validation** - Check tool calls before execution
- ✅ **Post-validation** - Verify results after execution
- ✅ **Context injection** - Add information to prompts or sessions
- ✅ **Policy enforcement** - Block unauthorized operations
- ✅ **Automatic formatting** - Clean up code before commits
- ✅ **Environment setup** - Configure session state

### What Hooks Are NOT

- ❌ **Not user-facing** - Run automatically, no user invocation
- ❌ **Not documentation** - Pure configuration, no markdown
- ❌ **Not orchestrators** - Single-purpose triggers, not workflows
- ❌ **Not replacements for agents** - Complement, don't replace

## Hook vs Other Components

| Aspect         | Hooks                    | Skills              | Agents                 | Commands            |
| -------------- | ------------------------ | ------------------- | ---------------------- | ------------------- |
| **Purpose**    | Automated triggers       | Framework knowledge | Autonomous workers     | Orchestration       |
| **Location**   | `.claude/settings*.json` | `.claude/skills/`   | `.claude/agents/`      | `.claude/commands/` |
| **Format**     | JSON configuration       | SKILL.md directory  | Single .md file        | Single .md file     |
| **Execution**  | Automatic on events      | Referenced          | Invoked by commands    | User `/command`     |
| **User Input** | None (reactive)          | None (reference)    | Indirect (via command) | Direct              |
| **Content**    | Bash/prompts             | Docs + examples     | System prompt          | Workflow steps      |

**Key Insight**: Hooks are **cross-cutting concerns** that apply automatically
across all workflows.

## Configuration Structure

### Settings File Hierarchy

Hooks are configured in JSON settings files with three levels:

1. **User**: `~/.claude/settings.json` - Personal, across all projects
2. **Project**: `.claude/settings.json` - Shared with team (committed)
3. **Local**: `.claude/settings.local.json` - Personal, not committed

**Precedence**: Local → Project → User (most specific wins)

### JSON Format

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/script.sh",
            "timeout": 30000
          }
        ]
      }
    ]
  }
}
```

### Key Fields

- **EventName**: Hook event type (see [Hook Types](#hook-types))
- **matcher**: Tool pattern to match (see [Matcher Patterns](#matcher-patterns))
- **type**: Either `"command"` (bash) or `"prompt"` (LLM)
- **command**: Bash command to execute
- **timeout**: Max execution time in milliseconds (default: 60000)

## Hook Types

### Tool-Related Events

#### PreToolUse

**When**: After Claude creates tool parameters, before processing

**Use Cases**:

- Validate tool inputs before execution
- Modify tool parameters
- Block unauthorized tool calls
- Auto-format before writes

**Input Fields**:

- `toolName`: Name of the tool (e.g., "Write", "Bash")
- `input`: Tool parameters as JSON object
- `isMcp`: Boolean, true if MCP tool

**Example Matcher**: `"Write"`, `"Bash"`, `"mcp__*"`

#### PostToolUse

**When**: Immediately after successful tool execution

**Use Cases**:

- Validate outputs
- Log tool usage
- Trigger follow-up actions
- Verify file integrity

**Input Fields**:

- `toolName`: Name of the tool
- `input`: Original tool parameters
- `output`: Tool execution result

**Example Matcher**: `"Bash"`, `"Edit"`

#### PermissionRequest

**When**: User sees permission dialog

**Use Cases**:

- Auto-approve trusted operations
- Block dangerous operations
- Log permission requests

**Input Fields**:

- `toolName`: Tool requiring permission
- `input`: Tool parameters

**Output Decision**: `"allow"` or `"block"`

### Workflow Events

#### UserPromptSubmit

**When**: User submits a prompt, before Claude processes

**Use Cases**:

- Inject project context
- Validate prompt content
- Add warnings or reminders

**Input Fields**:

- `message`: User's submitted text

**Special Behavior**: stdout becomes conversation context

#### Stop

**When**: Main agent finishes execution

**Use Cases**:

- Decide whether to continue automatically
- Summarize session
- Prompt for next action

**Input Fields**:

- `stopReason`: Why execution stopped
- `transcript_path`: Path to conversation

**Output Decision**: `"continue": true` or `false`

#### SubagentStop

**When**: Subagent completes task

**Use Cases**:

- Validate subagent output
- Decide continuation
- Log subagent results

**Input Fields**:

- `stopReason`: Why subagent stopped
- `agentType`: Subagent type

### Session Management

#### SessionStart

**When**: Session initializes or resumes

**Use Cases**:

- Load project context
- Set environment variables
- Display welcome message

**Input Fields**:

- `session_id`: Unique session identifier
- `cwd`: Current working directory

**Special Behavior**: stdout becomes conversation context

#### SessionEnd

**When**: Session terminates

**Use Cases**:

- Cleanup operations
- Save session state
- Final logging

**Input Fields**:

- `session_id`: Session that ended

### Other Events

#### Notification

**When**: Claude Code shows a notification

**Matchers**:

- `permission_prompt`: Permission dialog shown
- `idle_prompt`: Idle state prompt
- `auth_success`: Authentication succeeded

**Use Cases**:

- Track workflow state
- Log events
- Trigger external systems

#### PreCompact

**When**: Before context compaction

**Use Cases**:

- Log compaction events
- Preserve important context

## Command-Based Hooks

### Structure

```json
{
  "type": "command",
  "command": ".claude/hooks/my-hook.sh",
  "timeout": 30000
}
```

### Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields using jq
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty')
COMMAND=$(echo "$INPUT" | jq -r '.input.command // empty')

# Your validation logic here
if [[ "$COMMAND" =~ dangerous-pattern ]]; then
  echo "Blocked dangerous operation" >&2
  exit 2  # Exit code 2 blocks operation
fi

# Allow operation
exit 0
```

### Exit Codes

- **0**: Success, allow operation
- **2**: Block operation, send stderr to Claude as system message
- **Other**: Non-blocking error, logged but doesn't block

### Environment Variables

Available in all hooks:

- `CLAUDE_PROJECT_DIR`: Project root directory
- `CLAUDE_CODE_REMOTE`: True if remote session

## Prompt-Based Hooks

### Structure

```json
{
  "type": "prompt",
  "prompt": "Analyze this tool call and decide if it should continue...",
  "timeout": 10000
}
```

### Supported Events

Currently only:

- `Stop`
- `SubagentStop`

### LLM Evaluation

Claude Haiku receives:

1. Your custom prompt
2. Hook input as JSON

Returns structured JSON:

```json
{
  "decision": "approve",
  "reason": "Task completed successfully",
  "continue": true,
  "stopReason": "optional",
  "systemMessage": "optional"
}
```

### When to Use

- **Command hooks**: Fast, deterministic, simple logic
- **Prompt hooks**: Complex decisions, natural language analysis

## Matcher Patterns

### Exact Match

Match specific tool by exact name:

```json
{
  "matcher": "Write",
  "hooks": [...]
}
```

Matches: `Write` tool only

### Regex Patterns

Match multiple tools with regex:

```json
{
  "matcher": "Write|Edit",
  "hooks": [...]
}
```

Matches: `Write` OR `Edit` tools

### Wildcards

Match all tools:

```json
{
  "matcher": "*",
  "hooks": [...]
}
```

Matches: All tools (use cautiously)

### MCP Tools

Match MCP tools with wildcards:

```json
{
  "matcher": "mcp__*",
  "hooks": [...]
}
```

Matches: All MCP tools

```json
{
  "matcher": "mcp__github__*",
  "hooks": [...]
}
```

Matches: All GitHub MCP tools

### Advanced Patterns

```json
{
  "matcher": "^mcp__tidewave__(execute_sql|project_eval)$",
  "hooks": [...]
}
```

Matches: Only specific tidewave tools

## Input and Output

### stdin Format

All hooks receive JSON via stdin with common fields:

```json
{
  "session_id": "uuid",
  "transcript_path": "/path/to/transcript",
  "cwd": "/current/working/directory",
  "permission_mode": "ask|auto",
  "hook_event_name": "PreToolUse",
  // Event-specific fields...
  "toolName": "Write",
  "input": {
    "file_path": "/path/to/file",
    "content": "file content"
  }
}
```

### Reading Input

**Bash**:

```bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName')
```

**Python**:

```python
import json, sys
input_data = json.load(sys.stdin)
tool = input_data.get('toolName')
```

### stdout Usage

**Most events**: Shown only in verbose mode

**Special events**: Becomes conversation context

- `UserPromptSubmit`
- `SessionStart`

### stderr Usage

**Exit code 2**: stderr sent to Claude as system message (blocks operation)

**Other exit codes**: stderr logged but not shown

### JSON Response

Optional structured output:

```json
{
  "continue": true,
  "systemMessage": "Warning: Large file detected",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {
      "file_path": "/modified/path"
    }
  }
}
```

Print to stdout as last statement.

## Script Structure

### File Organization

**Recommended**:

```
.claude/
├── hooks/
│   ├── pre-commit-test.sh
│   ├── session-start-context.sh
│   └── shared/
│       └── common.sh
└── settings.json
```

### Shared Logic

Create reusable functions:

**.claude/hooks/shared/common.sh**:

```bash
#!/usr/bin/env bash

# Extract field from stdin JSON
get_field() {
  local field=$1
  echo "$INPUT" | jq -r ".$field // empty"
}

# Check if command contains pattern
contains_pattern() {
  local pattern=$1
  local command=$(get_field "input.command")
  [[ "$command" =~ $pattern ]]
}
```

**Usage in hooks**:

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/shared/common.sh"

INPUT=$(cat)
if contains_pattern "git commit"; then
  # Your logic
fi
```

### Error Handling

Always use:

```bash
set -euo pipefail

# Exit on undefined variables
# Exit on command failure
# Exit on pipe failure
```

### Debugging

Add debug output:

```bash
if [[ "${DEBUG_HOOKS:-}" == "true" ]]; then
  echo "Debug: tool=$TOOL_NAME" >&2
  echo "Debug: input=$INPUT" >&2
fi
```

Run with: `DEBUG_HOOKS=true claude`

## Integration Patterns

### With Skills

Hooks can reference skill validation patterns:

**Example**: Hook validates Ash actor context before Write

```bash
# Check that code includes actor parameter
if grep -q "actor: user" "$FILE_CONTENT"; then
  echo "✅ Actor context present" >&2
else
  echo "❌ Missing actor context - see @ash-framework skill" >&2
  exit 2
fi
```

### With Agents

Hooks apply to agent tool calls automatically:

**Example**: SessionStart loads context for implementer agent

```bash
cat <<EOF
## Context for Implementation

Current sprint goals:
- Implement hooks system
- Update create-component command

See @manage-code-agent skill for patterns.
EOF
```

### With Commands

Hooks integrate into command workflows seamlessly:

**Example**: PreToolUse validates before `/implement` writes code

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-code.sh"
          }
        ]
      }
    ]
  }
}
```

### With DESIGN/

DESIGN docs can reference hook patterns:

**DESIGN/security/authorization.md**:

```markdown
## Actor Context Enforcement

A PreToolUse hook validates that all Ash operations include actor context:

See `.claude/hooks/validate-actor.sh` for implementation.
```

## Security Considerations

### ⚠️ Critical Warnings

**Malicious hooks can cause serious damage**:

- Execute arbitrary commands
- Leak sensitive data
- Modify files destructively
- Bypass authorization

**Never run untrusted hooks**

### Input Validation

Always validate and quote inputs:

**❌ Dangerous**:

```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.input.file_path')
cat $FILE_PATH  # Command injection risk!
```

**✅ Safe**:

```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.input.file_path // empty')
if [[ -z "$FILE_PATH" ]]; then
  echo "Missing file_path" >&2
  exit 1
fi
cat "$FILE_PATH"  # Quoted, safe
```

### Path Traversal

Block attempts to escape project:

```bash
# Normalize path
REAL_PATH=$(realpath "$FILE_PATH" 2>/dev/null || echo "")

# Ensure within project
if [[ ! "$REAL_PATH" =~ ^"$CLAUDE_PROJECT_DIR" ]]; then
  echo "Path outside project: $FILE_PATH" >&2
  exit 2
fi
```

### Sensitive Files

Exclude sensitive files from operations:

```bash
SENSITIVE_PATTERNS=(
  ".env"
  "*.key"
  "*.pem"
  "credentials.json"
  ".claude/settings.local.json"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == $pattern ]]; then
    echo "Blocked operation on sensitive file" >&2
    exit 2
  fi
done
```

### Command Injection

Never use `eval` or unquoted variables:

**❌ Never**:

```bash
COMMAND=$(echo "$INPUT" | jq -r '.input.command')
eval $COMMAND  # Extremely dangerous!
```

**✅ Validate instead**:

```bash
COMMAND=$(echo "$INPUT" | jq -r '.input.command')
if [[ "$COMMAND" =~ ^(git|mix|npm)[[:space:]] ]]; then
  # Allowed command
  exit 0
else
  echo "Command not in allowlist" >&2
  exit 2
fi
```

### Best Practices Summary

1. **Validate all inputs** - Never trust data
2. **Quote variables** - Prevent injection
3. **Use absolute paths** - Avoid ambiguity
4. **Block path traversal** - Stay in project
5. **Exclude sensitive files** - Protect secrets
6. **Test in safe environment** - Sandbox first
7. **Review hook code** - Audit before use
8. **Limit scope** - Specific matchers only

## Quality Checklist

### Configuration

- [ ] **JSON syntax valid** - No parsing errors
- [ ] **Event names correct** - Valid hook types
- [ ] **Matchers properly formatted** - Exact, regex, or wildcard
- [ ] **Commands executable** - Scripts exist and `chmod +x`
- [ ] **Paths absolute or relative to project** - No ambiguity
- [ ] **Timeout specified** - For long-running hooks

### Security

- [ ] **Input validation present** - Check all fields
- [ ] **Variables quoted** - `"$VAR"` not `$VAR`
- [ ] **No command injection** - No `eval` or unquoted
- [ ] **Path traversal blocked** - Validate paths
- [ ] **Sensitive files excluded** - `.env`, `*.key`, etc.
- [ ] **Exit codes correct** - 0=allow, 2=block

### Testing

- [ ] **Hook tested in isolation** - Works standalone
- [ ] **Edge cases covered** - Missing fields, empty values
- [ ] **Error handling verified** - Fails gracefully
- [ ] **Performance acceptable** - Under timeout
- [ ] **No side effects** - Idempotent where possible

### Documentation

- [ ] **Hook purpose clear** - Comment at top of script
- [ ] **Usage documented** - How to configure
- [ ] **Dependencies noted** - Required tools (jq, etc.)
- [ ] **Examples provided** - Sample inputs/outputs

## Real Examples

### Example 1: Auto-format on Write

**Hook**: Format files before writing

**.claude/settings.json**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/auto-format.sh",
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

**.claude/hooks/auto-format.sh**:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

# Extract file path and content
FILE_PATH=$(echo "$INPUT" | jq -r '.input.file_path // empty')
CONTENT=$(echo "$INPUT" | jq -r '.input.content // empty')

# Format Elixir files
if [[ "$FILE_PATH" =~ \.exs?$ ]]; then
  echo "🎨 Formatting $FILE_PATH with mix format" >&2

  # Save content to temp file
  TEMP_FILE=$(mktemp)
  echo "$CONTENT" > "$TEMP_FILE"

  # Format with mix
  mix format "$TEMP_FILE" 2>&1 >&2

  # Return formatted content
  FORMATTED=$(cat "$TEMP_FILE")
  rm "$TEMP_FILE"

  # Output modified input
  echo "$INPUT" | jq --arg new_content "$FORMATTED" \
    '.hookSpecificOutput.updatedInput.content = $new_content'
  exit 0
fi

# Not Elixir, pass through
exit 0
```

### Example 2: Test Validation Before Commit

**Hook**: Run tests before git commits

**.claude/settings.json**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-commit-test.sh",
            "timeout": 300000
          }
        ]
      }
    ]
  }
}
```

**.claude/hooks/pre-commit-test.sh**:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.input.command // empty')

# Only check git commit commands
if [[ ! "$COMMAND" =~ ^git[[:space:]]+commit ]]; then
  exit 0
fi

echo "🧪 Running tests before commit..." >&2

# Run failed tests first (faster feedback)
if mix test --failed --max-failures 1 2>&1 >&2; then
  echo "✅ Tests passed - proceeding with commit" >&2
  exit 0
else
  echo "❌ Tests failed - blocking commit" >&2
  echo "Fix failing tests before committing" >&2
  exit 2  # Block the commit
fi
```

### Example 3: Session Context Loading

**Hook**: Load project context on session start

**.claude/settings.json**:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/session-start-context.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

**.claude/hooks/session-start-context.sh**:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

# Output context (stdout becomes conversation context)
cat <<EOF
## Session Context

**Project**: Your Application
**Stack**: Phoenix LiveView, Ash Framework, Oban

### Quick Links
- Design: DESIGN/Overview.md
- Skills: .claude/skills/README.md
- Commands: .claude/README.md

### Recent Focus
- Hooks system integration
- Component creation

### Workflow Commands
- \`/design\` - Architecture review
- \`/implement\` - Feature implementation
- \`/review\` - Code review
- \`/qa\` - End-to-end testing
EOF
```

### Example 4: MCP Tool Permission Control

**Hook**: Control MCP tool access by organization

**.claude/settings.json**:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__github__*",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/github-permission.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

**.claude/hooks/github-permission.sh**:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')
OWNER=$(echo "$INPUT" | jq -r '.input.owner // empty')

# Allow only our organization
ALLOWED_ORGS=("my-org" "my-team")

if [[ " ${ALLOWED_ORGS[@]} " =~ " ${OWNER} " ]]; then
  echo "✅ GitHub operation allowed for $OWNER" >&2
  exit 0
else
  echo "❌ GitHub operation blocked for $OWNER" >&2
  echo "Only allowed organizations: ${ALLOWED_ORGS[*]}" >&2
  exit 2  # Block operation
fi
```

## Common Mistakes

### Mistake #1: Unquoted Variables

**Problem**: Command injection vulnerability

**❌ Wrong**:

```bash
FILE=$(echo "$INPUT" | jq -r '.input.file_path')
cat $FILE
```

**✅ Correct**:

```bash
FILE=$(echo "$INPUT" | jq -r '.input.file_path')
cat "$FILE"
```

### Mistake #2: Missing Input Validation

**Problem**: Hook crashes on unexpected input

**❌ Wrong**:

```bash
COMMAND=$(echo "$INPUT" | jq -r '.input.command')
# Use COMMAND without checking
```

**✅ Correct**:

```bash
COMMAND=$(echo "$INPUT" | jq -r '.input.command // empty')
if [[ -z "$COMMAND" ]]; then
  echo "Missing command field" >&2
  exit 1
fi
```

### Mistake #3: Blocking All Operations

**Problem**: Hook blocks critical tools

**❌ Wrong**:

```json
{
  "matcher": "*",
  "hooks": [
    {
      "type": "command",
      "command": "always-block.sh"
    }
  ]
}
```

**✅ Correct**:

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "command",
      "command": "validate-writes.sh"
    }
  ]
}
```

### Mistake #4: Long-Running Hooks

**Problem**: Hooks time out, block workflow

**❌ Wrong**:

```bash
# No timeout, runs entire test suite
mix test
```

**✅ Correct**:

```bash
# Fast feedback, limited scope
mix test --failed --max-failures 1
```

### Mistake #5: Incorrect Exit Codes

**Problem**: Hook always allows operation

**❌ Wrong**:

```bash
if invalid_condition; then
  echo "Error!" >&2
  exit 1  # Doesn't block!
fi
```

**✅ Correct**:

```bash
if invalid_condition; then
  echo "Error!" >&2
  exit 2  # Blocks operation
fi
```

## Best Practices

### 1. Start Simple

Begin with read-only hooks that log:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName')
echo "Tool called: $TOOL" >> /tmp/claude-hooks.log
exit 0
```

Once working, add validation logic.

### 2. Test in Safe Environment

Create a test project:

```bash
mkdir ~/claude-hook-test
cd ~/claude-hook-test
# Configure hook
# Test with safe operations
```

Never test on production first.

### 3. Quote All Variables

**Always**:

```bash
cat "$FILE"
cd "$DIR"
echo "$MESSAGE"
```

### 4. Validate Inputs

**Every field**:

```bash
FIELD=$(echo "$INPUT" | jq -r '.path.to.field // empty')
if [[ -z "$FIELD" ]]; then
  echo "Missing field" >&2
  exit 1
fi
```

### 5. Use Absolute Paths

**Relative to project**:

```bash
SCRIPT_DIR="$CLAUDE_PROJECT_DIR/.claude/hooks"
source "$SCRIPT_DIR/shared/common.sh"
```

### 6. Handle Errors Gracefully

**Fail safely**:

```bash
set -euo pipefail

cleanup() {
  rm -f "$TEMP_FILE"
}
trap cleanup EXIT

# Your logic
```

### 7. Document Intent

**At top of every hook**:

```bash
#!/usr/bin/env bash
# Hook: PreToolUse - Validate Ash actor context
# Blocks writes that don't include actor parameter
#
# Requires: jq
# Timeout: 5s
# Exit: 0=allow, 2=block

set -euo pipefail
# ...
```

### 8. Monitor Performance

**Time operations**:

```bash
START=$(date +%s)

# Your logic

END=$(date +%s)
DURATION=$((END - START))

if [[ $DURATION -gt 10 ]]; then
  echo "Warning: Hook took ${DURATION}s" >&2
fi
```

### 9. Use Specific Matchers

**Prefer**:

```json
{ "matcher": "Write|Edit" }
```

**Over**:

```json
{ "matcher": "*" }
```

### 10. Version Control Hooks

**Commit hooks with project**:

```bash
git add .claude/hooks/
git add .claude/settings.json
git commit -m "Add pre-commit validation hook"
```

## Summary

Hooks are powerful automation tools that:

- ✅ Enforce policies automatically
- ✅ Validate operations before execution
- ✅ Inject context into workflows
- ✅ Integrate seamlessly with skills/agents/commands

Key principles:

1. **Security first** - Validate, quote, test
2. **Start simple** - Log first, validate later
3. **Be specific** - Targeted matchers, not wildcards
4. **Fail safely** - Block only when certain
5. **Document well** - Clear purpose and usage

**Remember**: Hooks complement skills/agents/commands - they don't replace them.

## Cross-References

- [Creating Skills](./creating-skills.md) - Hook validation can reference skills
- [Creating Agents](./creating-agents.md) - Hooks apply to agent tool calls
- [Creating Commands](./creating-commands.md) - Hooks integrate into workflows
- [@manage-code-agent skill](../SKILL.md) - Parent skill documentation
- [Hook examples](../examples/hook-config.json) - Sample configurations
- [Claude Code Hooks Docs](https://code.claude.com/docs/en/hooks) - Official
  documentation
