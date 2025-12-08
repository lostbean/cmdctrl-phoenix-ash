# Creating Agents Reference

**Complete guide to creating high-quality Claude Code subagents**

Subagents are specialized autonomous actors that do focused work. They reference
skills for framework knowledge and follow clear workflows.

## Table of Contents

- [Agent Purpose](#agent-purpose)
- [File Structure](#file-structure)
- [YAML Frontmatter](#yaml-frontmatter)
- [System Prompt](#system-prompt)
- [Workflow Definition](#workflow-definition)
- [Skill References](#skill-references)
- [Quality Checklist](#quality-checklist)
- [Real Examples](#real-examples)

## Agent Purpose

### What Subagents Do

Subagents are specialized workers with single responsibilities:

- **Architect** - Generate design options, update DESIGN/ docs
- **Implementer** - Write code and tests following designs
- **Code Reviewer** - Validate quality and adherence to patterns
- **Debugger** - Investigate issues and root causes
- **QA Tester** - Execute end-to-end tests

### What Subagents Are NOT

- ❌ **Not orchestrators** - Commands orchestrate, agents execute
- ❌ **Not knowledge stores** - Skills contain knowledge, agents reference it
- ❌ **Not generalists** - Each agent has a focused specialty

### Autonomy vs Orchestration

**Autonomous**: Subagent makes decisions within its domain

```markdown
The code-reviewer subagent decides what issues are critical vs minor
```

**Orchestrated**: Command coordinates between subagents

```markdown
The /implement command invokes architect, then implementer, then code-reviewer
```

## File Structure

Each subagent is a single `.md` file in `.claude/agents/`:

```
.claude/agents/
├── architect.md
├── implementer.md
├── code-reviewer.md
├── debugger.md
└── qa-tester.md
```

### File Naming

- **Format**: kebab-case
- **Extension**: `.md`
- **Descriptive**: Name should indicate role (e.g., `code-reviewer` not
  `reviewer`)

## YAML Frontmatter

Every subagent file starts with YAML frontmatter:

```yaml
---
name: agent-name
description: |
  What this agent does (1-2 sentences explaining the role).
  When it's invoked (key scenarios where this agent is used).
tools: Read, Write, Edit, Grep, Glob, WebFetch, mcp__tidewave__get_docs
model: inherit
---
```

### Frontmatter Fields

#### name (required)

- **Type**: String
- **Format**: kebab-case
- **Example**: `architect`, `code-reviewer`, `qa-tester`
- **Purpose**: Unique identifier for agent

#### description (required)

- **Type**: Multiline string (use `|`)
- **Format**: 2-4 sentences
- **Content**: MUST include both "what" and "when"
- **Example**:
  ```yaml
  description: |
    Design architect that reviews current design, generates multiple solution options
    sorted by quality, and updates DESIGN/ documentation. Invoked for design decisions,
    refactoring, and feature planning.
  ```

#### tools (required)

- **Type**: Comma-separated string (NOT a list)
- **Format**: `Tool1, Tool2, Tool3`
- **Example**: `Read, Write, Edit, Grep, Glob`
- **Purpose**: Defines which tools this agent can use
- **Note**: Different format than skills (string not list)

#### model (optional)

- **Type**: String
- **Values**: `inherit` (most common), specific model name
- **Default**: Inherits from parent/session
- **Example**: `inherit`
- **Purpose**: Allows agent to use different model if needed

### YAML Validation

```bash
# Extract and verify frontmatter
head -n 10 .claude/agents/architect.md

# Check format
grep -A 10 "^---$" .claude/agents/architect.md
```

## System Prompt

After frontmatter, define the agent's system prompt:

### Structure

```markdown
---
name: agent-name
description: |
  What this agent does and when it's invoked.
tools: Read, Write, Edit, Grep, Glob
model: inherit
---

# Agent Name

You are a {role} specializing in {specialty}. Your role is to {primary
responsibility}.

## Your Workflow

When given {input}, follow this systematic approach:

### 1. First Step

- What to do first
- How to gather information
- Which tools to use

### 2. Second Step

- What to do next
- How to process information
- Expected output

### 3. Third Step

- Final actions
- Deliverables
- Success criteria

## Quality Criteria for {Agent Work}

Score/evaluate against these criteria:

### Criterion 1 (X points)

- What to check
- How to evaluate
- What good looks like

### Criterion 2 (Y points)

- More criteria
- Specific measures
- Standards to meet

## Skill References

Reference these skills for patterns:

### @skill-name

Brief description of what patterns to use from this skill.

### @other-skill

Another skill and its relevant patterns.

## Best Practices

### Practice 1

Guideline with reasoning

### Practice 2

Another guideline

## Example Interaction

**User**: "Example request"

**You should**:

1. Step 1 - What to do
2. Step 2 - What to do next
3. Step 3 - Final action

## Key Principles

- **Principle 1**: Brief explanation
- **Principle 2**: Another principle
- **Principle 3**: More guidance
```

### System Prompt Guidelines

1. **Clear role definition** - State who the agent is
2. **Workflow steps** - Numbered, sequential process
3. **Quality criteria** - How to evaluate work
4. **Skill references** - Which skills to consult
5. **Best practices** - Key guidelines
6. **Example interactions** - Show expected behavior
7. **Key principles** - Core values

### Writing Style

- **Direct instructions** - "You are...", "Follow this approach..."
- **Imperative verbs** - "Analyze", "Generate", "Present"
- **Specific actions** - "Read DESIGN/ docs" not "Understand the design"
- **Clear deliverables** - "Present 3-5 options" not "Think about options"

## Workflow Definition

Define a clear, repeatable workflow:

### Good Workflow Example

```markdown
## Your Workflow

When given a design challenge, follow this systematic approach:

### 1. Understand Current State

- Read relevant DESIGN/ documentation to understand existing architecture
- Review related code files to see current implementation patterns
- Examine tests to understand behavior and edge cases
- Check for related skills in `.claude/skills/` for established patterns
- Use MCP tools to understand dependencies

### 2. Generate Solution Options

- Create 3-5 distinct solution approaches
- Each option should represent a meaningfully different strategy
- Consider both incremental improvements and bold alternatives
- Think beyond the obvious first solution

### 3. Score Against Quality Criteria

Apply the quality criteria framework to each option:

- Calculate a quality score out of 10
- Document specific strengths and weaknesses
- Be objective and data-driven in scoring

### 4. Sort and Present

- Sort options by quality score (best first)
- Present complete trade-off analysis for each
- Include complexity and time estimates
- Never assume user preferences - let them decide

### 5. Update Documentation

After user selects an option:

- Update affected DESIGN/ documents
- Add cross-references to relevant skills
- Follow doc-hygiene principles
- Update related docs together for consistency
```

### Workflow Best Practices

1. **Numbered steps** - Clear sequence
2. **Specific actions** - Concrete, not vague
3. **Tool usage** - When to use which tools
4. **Deliverables** - What output expected
5. **Conditions** - When to do what

### Conditional Workflows

```markdown
### 3. Analyze Issue Type

**If syntax error**:

- Check language syntax
- Verify imports
- Run linter

**If runtime error**:

- Check stack trace
- Review related code
- Examine test output

**If logic error**:

- Understand expected behavior
- Trace actual behavior
- Identify divergence point
```

## Skill References

Agents must reference skills, not duplicate them:

### Reference Pattern

```markdown
## Skill References

Reference these skills for {agent domain} patterns:

### @ash-framework

Ash resource patterns, actions, relationships, policies, calculations,
aggregates, validations, and changes. Core resource-oriented design principles.

### @reactor-oban

Reactor workflow patterns, step composition, error handling, compensation, and
Oban integration. Workflow-as-saga architecture.

### @doc-hygiene

Documentation standards, structure, cross-referencing, and synchronization.
Keeping docs clean and maintainable.
```

### How to Reference Skills

**In system prompt**:

```markdown
For Ash policy patterns, see [@ash-framework](@ash-framework).
```

**In workflow steps**:

```markdown
### 2. Review Best Practices

- Check @ash-framework for resource patterns
- Review @reactor-oban for workflow structure
- Consult @doc-hygiene for documentation standards
```

**In quality criteria**:

```markdown
### Best Practices from Skills (2 points)

- Follows @ash-framework patterns (resources, actions, policies)
- Uses @reactor-oban correctly for workflows
- Applies @phoenix-liveview conventions
```

### Never Duplicate Skills

❌ **DON'T**:

````markdown
## Ash Resource Patterns

Resources have attributes, relationships, and actions:

```elixir
defmodule MyResource do
  use Ash.Resource
  ...
end
```
````

````

✅ **DO**:
```markdown
## Framework Patterns

Follow patterns from these skills:

### @ash-framework
See @ash-framework for resource definitions, policy patterns, and actor context.
````

## Quality Checklist

Before committing a subagent, verify:

### Structure

- [ ] Single .md file in .claude/agents/
- [ ] YAML frontmatter present and valid
- [ ] All required frontmatter fields complete
- [ ] Tools specified correctly (comma-separated string)

### System Prompt

- [ ] Clear role definition ("You are...")
- [ ] Workflow section with numbered steps
- [ ] Quality criteria defined
- [ ] Skill references present
- [ ] Best practices section included
- [ ] Example interaction shown
- [ ] Key principles listed

### Content Quality

- [ ] Description includes "what" AND "when"
- [ ] Workflow is specific and actionable
- [ ] Quality criteria are measurable
- [ ] Skill references comprehensive (3+ skills)
- [ ] No duplication of skill content
- [ ] Best practices are clear and justified

### DRY Compliance

- [ ] No framework patterns duplicated (referenced instead)
- [ ] No code examples (link to skills)
- [ ] Skills referenced for all framework knowledge
- [ ] Project-specific guidance only (not generic)

### Validation

- [ ] YAML syntax valid
- [ ] Skill references resolve correctly
- [ ] Tools list is accurate
- [ ] Workflow is complete and logical

## Real Examples

### Excellent Agent: architect

**Location**: `.claude/agents/architect.md`

**What makes it excellent**:

- ✅ Clear role: "Design architect specializing in options generation"
- ✅ Systematic workflow: Understand → Generate → Score → Present → Update
- ✅ Quality criteria: 10-point framework with specific measures
- ✅ Extensive skill references: @ash-framework, @reactor-oban,
  @phoenix-liveview, @doc-hygiene
- ✅ Clear deliverables: "Present 3-5 options sorted by quality score"
- ✅ Example interaction showing expected behavior
- ✅ No duplication: All framework knowledge referenced from skills

**Key sections**:

```markdown
## Your Workflow

1. Understand Current State
2. Generate Solution Options
3. Score Against Quality Criteria
4. Sort and Present
5. Update Documentation

## Quality Criteria for Scoring

- Design Alignment (2 points)
- Best Practices from Skills (2 points)
- Maintainability and Simplicity (2 points)
- Security (2 points)
- Test Coverage (1 point)
- Long-term Sustainability (1 point)

## Skill References

### @ash-framework

### @reactor-oban

### @phoenix-liveview

### @doc-hygiene
```

### Good Agent: code-reviewer

**What it does well**:

- Clear quality framework (Critical, Suggestions, Positive)
- References multiple skills for patterns
- Specific examples of what to check
- Structured output format

**Could improve**:

- More detailed workflow steps
- Example interaction showing review process

### Good Agent: implementer

**What it does well**:

- References ALL skills for comprehensive patterns
- Clear implementation principles
- Step-by-step workflow

**Could improve**:

- More specific quality criteria
- Better example interactions

## Common Mistakes

### Mistake #1: Duplicating Skill Content

❌ **Problem**: Agent includes framework patterns instead of referencing skills

✅ **Solution**: Reference skills for all framework knowledge

### Mistake #2: Vague Workflow

❌ **Problem**: "Analyze the problem and provide solution"

✅ **Solution**: Specific numbered steps with clear actions

### Mistake #3: Missing Quality Criteria

❌ **Problem**: No guidance on how to evaluate work quality

✅ **Solution**: Define measurable criteria with point values

### Mistake #4: Incorrect Tools Format

❌ **Problem**: `tools: [Read, Write]` (YAML list)

✅ **Solution**: `tools: Read, Write` (comma-separated string)

### Mistake #5: Too General

❌ **Problem**: "You are a helpful assistant"

✅ **Solution**: "You are an Elixir code reviewer specializing in Ash Framework
patterns"

## Best Practices

1. **Single responsibility** - Each agent does one thing well
2. **Reference skills** - Never duplicate framework knowledge
3. **Clear workflow** - Numbered, specific, actionable steps
4. **Quality criteria** - Measurable standards for evaluation
5. **Example interactions** - Show expected behavior
6. **Appropriate tools** - Only include needed tools
7. **Specific deliverables** - Clear output expectations
8. **Skill-backed** - Reference 3+ skills minimum
9. **Project-aware** - Link to DESIGN/ docs where relevant
10. **Autonomous within domain** - Make decisions, don't just suggest

## Agent Design Patterns

### Pattern 1: Analyzer Agents

**Examples**: debugger, architect (analysis phase)

**Characteristics**:

- Read-heavy (Read, Grep, Glob tools)
- Multi-step investigation
- Structured output format
- References skills for patterns

**Workflow**:

1. Gather information
2. Analyze patterns
3. Identify issues/options
4. Present findings

### Pattern 2: Generator Agents

**Examples**: architect (generation phase), implementer

**Characteristics**:

- Write-heavy (Write, Edit tools)
- Creation or modification
- Quality criteria application
- Skill-guided implementation

**Workflow**:

1. Understand requirements
2. Reference skill patterns
3. Generate content/code
4. Validate against criteria

### Pattern 3: Validator Agents

**Examples**: code-reviewer, qa-tester

**Characteristics**:

- Inspection tools (Read, Grep)
- Checklist-based evaluation
- Structured feedback format
- Skill-based quality standards

**Workflow**:

1. Read content/code
2. Check against criteria
3. Identify issues
4. Report findings

## Advanced Topics

### Coordinating Multiple Skills

When agent needs multiple skills:

```markdown
## Skill References

### @ash-framework

For resource patterns, policies, and actor context.

### @reactor-oban

For workflow patterns and background jobs.

### @phoenix-liveview

For real-time UI patterns and PubSub.

### @elixir-testing

For test strategies and patterns.

## Your Workflow

### 2. Apply Framework Patterns

- Check @ash-framework for resource structure
- Review @reactor-oban if workflow needed
- Consult @phoenix-liveview for UI components
- Reference @elixir-testing for test patterns
```

### Conditional Skill Usage

```markdown
### 3. Reference Appropriate Skills

**If working with domain logic**:

- See @ash-framework for resource patterns
- Check @reactor-oban for workflows

**If working with UI**:

- See @phoenix-liveview for component patterns
- Check @ui-design for styling

**If working with tests**:

- See @elixir-testing for test strategies
- Check specific framework skills for test examples
```

### MCP Tool Integration

```markdown
tools: Read, Write, Edit, Grep, Glob, mcp**tidewave**get_docs,
mcp**tidewave**get_source_location

## Your Workflow

### 1. Understand Current State

- Read relevant DESIGN/ documentation
- Review code files to see implementation
- Use `mcp__tidewave__get_docs` to understand module APIs
- Use `mcp__tidewave__get_source_location` to find definitions
```

## Testing Agents

### Manual Testing

1. **Invoke agent** from command or directly
2. **Verify workflow** - Does it follow steps?
3. **Check output** - Matches expected format?
4. **Validate skills** - Are skills referenced correctly?
5. **Review quality** - Does it apply quality criteria?

### Integration Testing

Test agent in command workflows:

```bash
# Test architect in design workflow
/design Add feature X

# Test implementer in implement workflow
/implement Add feature Y

# Test code-reviewer in review workflow
/review lib/some_module.ex
```

## Next Steps

- Review [creating-commands.md](./creating-commands.md) for command patterns
- Study [creating-skills.md](./creating-skills.md) for skill structure
- Examine `.claude/agents/architect.md` for real example
- Use `/create-component agent <name>` to generate template

---

**Remember**: Agents are workers, not knowledge stores. Reference skills, define
workflows, apply criteria.
