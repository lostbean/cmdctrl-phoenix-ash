# Creating Commands Reference

**Complete guide to creating high-quality Claude Code slash commands**

Commands are thin orchestration layers that coordinate subagents to accomplish
complex workflows. They don't do the work—they coordinate who does what and
when.

## Table of Contents

- [Command Purpose](#command-purpose)
- [File Structure](#file-structure)
- [YAML Frontmatter](#yaml-frontmatter)
- [Command Structure](#command-structure)
- [Workflow Definition](#workflow-definition)
- [Examples Section](#examples-section)
- [Troubleshooting](#troubleshooting)
- [Quality Checklist](#quality-checklist)
- [Real Examples](#real-examples)

## Command Purpose

### What Commands Do

Commands orchestrate workflows by:

- **Coordinating subagents** - Invoke architect, implementer, code-reviewer,
  qa-tester
- **Managing user interaction** - Prompt for input, present options, get
  approval
- **Sequencing steps** - Define order of operations
- **Handling branches** - Conditional logic based on outcomes
- **Ensuring completeness** - All steps executed successfully

### What Commands Are NOT

- ❌ **Not implementers** - Don't write code or design solutions
- ❌ **Not knowledge stores** - Don't contain framework patterns
- ❌ **Not decision makers** - Present options, user decides
- ❌ **Not thick orchestrators** - Minimal logic, just coordination

### Thin Orchestration Principle

**Good (Thin)**:

```markdown
1. Invoke architect to generate design options
2. User selects preferred option
3. Architect updates DESIGN/ docs
4. Invoke implementer to write code
```

**Bad (Thick)**:

```markdown
1. Analyze current architecture (hundreds of lines of analysis logic)
2. Generate design options (reimplementing architect work)
3. Update documentation (doing implementer's job)
```

**Key**: Commands coordinate, subagents execute.

## File Structure

Each command is a single `.md` file in `.claude/commands/`:

```
.claude/commands/
├── implement.md
├── review.md
├── design.md
├── refactor.md
├── fix-issue.md
└── qa.md
```

### File Naming

- **Format**: kebab-case
- **Extension**: `.md`
- **Descriptive**: Name matches command usage (e.g., `implement.md` for
  `/implement`)

### Command Invocation

Users invoke with slash syntax:

```bash
/implement Add feature X
/review lib/module.ex
/design Add webhook support
/qa Test user registration
```

## YAML Frontmatter

Every command file starts with YAML frontmatter:

```yaml
---
description: What this command does and when to use it (1-2 sentences)
argument-hint: "[required-arg] [optional-arg]"
---
```

### Frontmatter Fields

#### description (required)

- **Type**: String
- **Format**: 1-2 sentences
- **Content**: What command does AND when to use
- **Example**:
  ```yaml
  description: Complete feature implementation with design, code, review, and testing
  ```

#### argument-hint (required)

- **Type**: String
- **Format**: Shell-style argument syntax
- **Purpose**: Show users what arguments expected
- **Example**:
  ```yaml
  argument-hint: "[feature description]"
  argument-hint: "[file|directory|commit]"
  argument-hint: "[test flow description]"
  ```

### Argument Hint Patterns

**Single required argument**:

```yaml
argument-hint: "[feature description]"
```

**Multiple required arguments**:

```yaml
argument-hint: "[source-file] [target-file]"
```

**Optional arguments**:

```yaml
argument-hint: "[file] [--flag]"
```

**Multiple choice**:

```yaml
argument-hint: "[file|directory|commit]"
```

### YAML Validation

```bash
# Extract frontmatter
head -n 5 .claude/commands/implement.md

# Verify format
grep -A 3 "^---$" .claude/commands/implement.md | head -n 5
```

## Command Structure

After frontmatter, structure command documentation:

### Standard Structure

````markdown
---
description: Command description
argument-hint: "[arguments]"
---

# Command Name

Brief description of what command does.

## Overview

High-level explanation of the command's purpose and workflow:

1. Step 1 - What happens
2. Step 2 - What happens next
3. Step 3 - Final step
4. Output/Result

## Usage

```bash
/command-name argument examples
/command-name another example
/command-name complex example with details
```
````

## How It Works

**Input**: $ARGUMENTS

**Workflow:**

1. **Step Name**: What happens in this step
   - Substep details
   - Expected output

2. **Next Step**: What happens next
   - More details
   - Deliverables

3. **Final Step**: Completion
   - Final actions
   - Success criteria

**Thin Orchestration**: This command coordinates the workflow. Subagents do all
the work.

## Subagents Used

List which subagents are involved:

**Subagent Name**: What this subagent does in the workflow

## Examples

Multiple detailed examples showing different use cases.

### Example 1: {Use Case}

```bash
/command-name specific example
```

**What happens:**

1. Detailed step-by-step walkthrough
2. What each subagent does
3. Expected intermediate outputs
4. Final deliverable

### Example 2: {Another Use Case}

{Similar structure}

## Troubleshooting

Common issues and solutions.

### Problem Title

**Problem**: Description of issue

**Solution**: How to resolve it

## Best Practices

Guidelines for using the command effectively.

## Integration with Other Commands

How this command works with other workflows.

## Remember

> **Key principle or reminder**

Final guidance for users.

````

## Workflow Definition

### Good Workflow Structure

```markdown
## How It Works

**Feature to Implement**: $ARGUMENTS

**Workflow:**

1. **Invoke Architect**: Analyze feature requirements, present 3-5 design options
2. **User Approval**: You select which design approach to use
3. **Update Design Docs**: Architect updates DESIGN/ with approved design
4. **Invoke Implementer**: Write code and tests following the design
5. **Invoke Code Reviewer**: Review implementation quality
6. **Address Findings**: If reviewer finds issues, implementer fixes them
7. **Invoke QA Tester**: Validate feature works end-to-end
8. **Git Commit**: Commit feature with clear message

**Thin Orchestration**: This command coordinates the workflow. Subagents do all the design, implementation, review, and testing work.
````

### Workflow Best Practices

1. **Use $ARGUMENTS** - Show where user input goes
2. **Number steps** - Clear sequence
3. **Name subagents** - Explicit about who does what
4. **User interaction** - Call out when user input needed
5. **Thin orchestration note** - Emphasize coordination role
6. **Success criteria** - Clear completion state

### Conditional Workflows

```markdown
**Workflow:**

1. **Run Initial Tests**: Verify current state

2. **Branch Based on Results**:

   **If tests pass**:
   - Proceed with refactoring
   - Invoke implementer

   **If tests fail**:
   - Invoke debugger to investigate
   - Fix failing tests first
   - Then proceed

3. **Continue with remaining steps...**
```

### Sequential vs Parallel

**Sequential** (most common):

```markdown
1. **Step 1**: Do first thing
2. **Step 2**: Do second thing (depends on step 1)
3. **Step 3**: Do third thing (depends on step 2)
```

**Parallel** (rare in commands):

```markdown
1. **Parallel Analysis**:
   - Invoke debugger to analyze issue
   - Invoke code-reviewer to check code quality
   - Invoke architect to review design

2. **Synthesize Results**: Combine findings from all analyses
```

## Examples Section

Provide multiple detailed examples:

### Example Structure

````markdown
### Example 1: {Use Case Category}

```bash
/command-name Specific example command
```
````

**What happens:**

1. {First step with specific details}
2. {Second step - what subagent does}
3. {Third step - expected output}
4. {Final step - deliverable}

**Example output**:

- {Specific artifact created}
- {Another artifact}
- {Final result}

````

### Multiple Examples Pattern

Provide 3-5 examples covering:

1. **Simple case** - Straightforward usage
2. **Complex case** - Multi-step with branches
3. **Edge case** - Handling unusual situation
4. **Integration** - Working with other commands
5. **Error handling** - When things go wrong

### Example from /implement

```markdown
### Example 1: Authentication Feature

```bash
/implement Add email verification to user registration
````

**What happens:**

1. Architect analyzes authentication flow
2. Presents options: token-based, magic link, third-party service
3. You approve token-based approach
4. Architect updates DESIGN/concepts/authentication.md
5. Implementer creates:
   - `lib/my_app/accounts/verification_token.ex` resource
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

````

### Good Example Characteristics

- ✅ **Specific input** - Actual command with realistic argument
- ✅ **Step-by-step** - Numbered sequence
- ✅ **Subagent actions** - What each subagent does
- ✅ **Intermediate outputs** - What gets created at each step
- ✅ **Final deliverable** - Clear end result

## Troubleshooting

### Troubleshooting Structure

```markdown
## Troubleshooting

### Problem Title

**Problem**: Clear description of the issue users might encounter

**Solution**: Step-by-step resolution
````

### Example Troubleshooting Entries

````markdown
### Design Options Unclear

**Problem**: Architect's options don't match your vision

**Solution**: Provide more specific requirements:

```bash
/implement Add rate limiting - prefer Ash policy-based approach over third-party middleware
```
````

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

````

### Coverage

Include troubleshooting for:

- **User input issues** - Unclear or missing arguments
- **Workflow problems** - Steps not executing correctly
- **Subagent issues** - Agent not performing as expected
- **Integration problems** - Conflicts with other commands
- **Quality issues** - Output doesn't meet standards

## Quality Checklist

Before committing a command, verify:

### Structure
- [ ] Single .md file in .claude/commands/
- [ ] YAML frontmatter present and valid
- [ ] All required frontmatter fields complete

### Content
- [ ] Description clear (what AND when)
- [ ] argument-hint accurate and helpful
- [ ] Overview section explains purpose
- [ ] Usage examples present
- [ ] How It Works section with workflow
- [ ] Subagents listed and described
- [ ] Examples section (3+ examples)
- [ ] Troubleshooting section
- [ ] Best Practices section
- [ ] Integration section (if applicable)

### Workflow Quality
- [ ] Uses $ARGUMENTS to show input
- [ ] Steps are numbered and sequential
- [ ] Subagents explicitly named
- [ ] User interaction points called out
- [ ] Thin orchestration emphasized
- [ ] Success criteria clear

### Examples Quality
- [ ] 3+ detailed examples
- [ ] Examples cover different use cases
- [ ] Step-by-step walkthrough included
- [ ] Expected outputs shown
- [ ] Real-world scenarios used

### Troubleshooting Quality
- [ ] 3+ common issues covered
- [ ] Problems clearly described
- [ ] Solutions actionable
- [ ] Examples included

### Best Practices
- [ ] Guidelines relevant and specific
- [ ] Based on real usage patterns
- [ ] Clear dos and don'ts

## Real Examples

### Excellent Command: /implement

**Location**: `.claude/commands/implement.md`

**What makes it excellent**:
- ✅ Clear workflow: architect → user approval → implementer → code-reviewer → qa-tester
- ✅ User in the loop: User approves design before implementation
- ✅ Thin orchestration: Each step delegates to subagent
- ✅ 5 detailed examples covering different feature types
- ✅ Comprehensive troubleshooting (5 scenarios)
- ✅ Best practices section with clear guidelines
- ✅ Integration with other commands shown
- ✅ Success criteria defined

**Key sections**:
```markdown
## How It Works
**Feature to Implement**: $ARGUMENTS

**Workflow:**
1. **Invoke Architect**: Analyze requirements, present options
2. **User Approval**: Select design approach
3. **Update Design Docs**: Architect updates DESIGN/
4. **Invoke Implementer**: Write code and tests
5. **Invoke Code Reviewer**: Review quality
6. **Address Findings**: Fix issues if any
7. **Invoke QA Tester**: Validate functionality
8. **Git Commit**: Commit with clear message

**Thin Orchestration**: Subagents do all work
````

### Good Command: /design

**What it does well**:

- Clear purpose: Get design options
- Simple workflow: Invoke architect, user decides
- Good examples showing different design challenges

**Could improve**:

- More troubleshooting scenarios
- Integration examples with /implement

### Good Command: /qa

**What it does well**:

- Clear testing workflow
- Good examples of test scenarios
- Explains MCP tool usage

**Could improve**:

- More detail on QA tester workflow
- Troubleshooting for common test failures

## Common Mistakes

### Mistake #1: Doing Work in Command

❌ **Problem**: Command contains implementation logic

```markdown
1. **Analyze Code**: Read files, check patterns, evaluate quality
   - Loop through all files
   - Run quality checks
   - Generate report
```

✅ **Solution**: Delegate to subagent

```markdown
1. **Invoke Code Reviewer**: Review quality and adherence to patterns
```

### Mistake #2: No User Interaction

❌ **Problem**: Command makes all decisions

```markdown
1. Architect generates design
2. Automatically use first option
3. Implement without approval
```

✅ **Solution**: Human in the loop

```markdown
1. Architect presents 3-5 design options
2. User selects preferred option
3. Proceed with selected design
```

### Mistake #3: Vague Workflow

❌ **Problem**: Unclear steps

```markdown
1. Design the solution
2. Implement it
3. Test it
```

✅ **Solution**: Specific actions

```markdown
1. **Invoke Architect**: Generate design options sorted by quality
2. **User Approval**: Select which design approach to use
3. **Invoke Implementer**: Write code following selected design
4. **Invoke QA Tester**: Validate functionality end-to-end
```

### Mistake #4: Missing Examples

❌ **Problem**: Only abstract description

✅ **Solution**: 3+ concrete examples

### Mistake #5: No Troubleshooting

❌ **Problem**: No guidance when things go wrong

✅ **Solution**: Common issues with solutions

## Best Practices

1. **Thin orchestration** - Coordinate, don't implement
2. **User in loop** - Present options, user decides
3. **Clear workflow** - Numbered steps with subagent names
4. **Multiple examples** - 3-5 covering different scenarios
5. **Comprehensive troubleshooting** - Common issues and solutions
6. **Use $ARGUMENTS** - Show where user input goes
7. **Success criteria** - Define completion clearly
8. **Integration guidance** - How to use with other commands
9. **Best practices section** - Dos and don'ts
10. **Real scenarios** - Base examples on actual usage

## Command Patterns

### Pattern 1: Linear Workflow

**Example**: /review

```markdown
1. Invoke code-reviewer
2. Present findings
3. Done
```

**Characteristics**:

- Simple sequence
- No branching
- Single subagent

### Pattern 2: Iterative Workflow

**Example**: /implement

```markdown
1. Design
2. Implement
3. Review
4. If issues found → Fix and goto 3
5. QA test
6. If bugs found → Fix and goto 3
7. Done
```

**Characteristics**:

- Feedback loops
- Multiple subagents
- Iteration until quality

### Pattern 3: Approval Workflow

**Example**: /design

```markdown
1. Architect generates options
2. User selects
3. Architect updates docs
4. Done
```

**Characteristics**:

- Human decision point
- Options presentation
- Action based on choice

### Pattern 4: Investigation Workflow

**Example**: /fix-issue

```markdown
1. User selects issue
2. Debugger investigates
3. Architect designs fix
4. User approves
5. Implementer fixes
6. Code reviewer validates
7. QA tester verifies
8. Done
```

**Characteristics**:

- Analysis phase
- Design phase
- Implementation phase
- Multiple approvals

## Advanced Topics

### Conditional Branching

```markdown
**Workflow:**

1. **Check Current State**

2. **Branch Based on Status**:

   **If feature branch exists**:
   - Continue on existing branch
   - Invoke implementer

   **If no feature branch**:
   - Create new branch
   - Invoke architect first
   - Then implementer

3. **Continue with common steps...**
```

### Error Handling

```markdown
**Workflow:**

1. **Invoke Implementer**: Write code

2. **Handle Errors**:

   **On success**:
   - Proceed to code review

   **On failure**:
   - Report error to user
   - User decides: retry, modify, or abort

3. **If proceeding: Invoke Code Reviewer**
```

### Integration Points

````markdown
## Integration with Other Commands

**Design → Implement Flow:**

```bash
/design Add OAuth provider support
# Review and approve option
/implement Add OAuth provider support (use approved design)
```
````

**Implement → Review → Refactor Flow:**

```bash
/implement Add webhook retry logic
/review lib/my_app/webhooks/
# If review suggests improvements
/refactor lib/my_app/webhooks/handler.ex
```

```

## Testing Commands

### Manual Testing

1. **Invoke command** with test argument
2. **Verify workflow** - Steps execute in order?
3. **Check subagents** - Correct agents invoked?
4. **Validate output** - Expected artifacts created?
5. **Test branching** - Conditional logic works?

### User Testing

1. **Give command to user** with example
2. **Observe usage** - Clear what to do?
3. **Collect feedback** - Confusing points?
4. **Iterate** - Improve based on feedback

## Updating Commands

### When to Update

- **New subagent available** - Integrate into workflow
- **User feedback** - Address confusion or issues
- **Pattern emerges** - Add to best practices
- **Integration opportunity** - Link with other commands

### Update Checklist

- [ ] Workflow still accurate
- [ ] Examples up to date
- [ ] Troubleshooting covers new issues
- [ ] Best practices reflect current patterns
- [ ] Integration section current

## Next Steps

- Review [creating-skills.md](./creating-skills.md) for skill structure
- Study [creating-agents.md](./creating-agents.md) for subagent patterns
- Examine `.claude/commands/implement.md` for real example
- Use `/create-component command <name>` to generate template

---

**Remember**: Commands orchestrate, subagents execute. Keep it thin, keep it clear, keep user in control.
```
