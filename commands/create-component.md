---
description:
  Create or update Claude Code skills, commands, agents, and hooks following
  best practices
argument-hint: "[skill|agent|command|hook] [name] [description]"
---

# Create Component Command

Create or update Claude Code skills, commands, agents, and hooks with proper
structure, YAML frontmatter (or JSON for hooks), and DRY principles.

## Overview

This command guides you through creating well-structured Claude Code components:

1. Gather requirements (type, name, purpose, dependencies)
2. Generate proper directory structure
3. Create files with valid YAML frontmatter
4. Populate content following architecture principles
5. Validate structure and cross-references
6. Update indexes (README.md, skills index, etc.)

## Usage

```bash
/create-component skill ash-framework "Ash Framework patterns for resources and policies"
/create-component agent formatter "Code formatting specialist using mix format"
/create-component command format "Format code using prettier and mix format"
/create-component hook pre-write-format "Auto-format files before Write tool"
```

## How It Works

**Component Specification**: $ARGUMENTS

**Workflow:**

1. **Parse Arguments**: Extract component type, name, and description
2. **Gather Requirements**:
   - Ask about tools/dependencies needed (skills/agents)
   - Ask about event type and matcher pattern (hooks)
   - Identify related components for cross-references
   - Determine skill references (for agents/commands)
3. **Generate Structure**:
   - Create directory (skills) or file (agents/commands)
   - Create script file (hooks) in `.claude/hooks/`
   - Generate YAML frontmatter (skills/agents/commands)
   - Generate JSON configuration (hooks)
   - Create template files (SKILL.md, reference/, examples/)
4. **Populate Content**:
   - Add system prompt (for agents)
   - Add workflow section (for commands)
   - Add reference docs and examples (for skills)
   - Add bash script logic (for hooks)
   - Add cross-references to related components
5. **Validate**:
   - Check YAML/JSON syntax
   - Verify file structure
   - Test hook script execution (hooks only)
   - Ensure cross-references resolve
   - Run quality checklist
6. **Update Indexes**:
   - Update `.claude/skills/README.md` (for skills)
   - Update `.claude/settings.json` (for hooks)
   - Update `.claude/README.md` if needed
   - Note location of created files

**Thin Orchestration**: This command coordinates creation. The
@manage-code-agent skill provides all the patterns and guidelines.

## Subagents Used

This command primarily uses your direct guidance, referencing the
@manage-code-agent skill for:

- Structure templates
- YAML frontmatter formats
- Content guidelines
- Quality checklists
- Validation commands

## Examples

### Example 1: Creating a Framework Skill

```bash
/create-component skill typescript "TypeScript patterns and best practices for this project"
```

**What happens:**

1. Command parses: type=skill, name=typescript, description="TypeScript
   patterns..."
2. Asks for:
   - Which tools needed? (Read, Grep, Glob, etc.)
   - Related skills? (None for first skill)
   - Project-specific or generic? (Project-specific)
3. Creates structure:
   ```
   .claude/skills/typescript/
   ├── SKILL.md
   ├── examples/
   └── reference/
   ```
4. Generates SKILL.md with:
   - Valid YAML frontmatter
   - Standard sections (What, When, Core Principles, etc.)
   - Placeholders for content
5. Creates reference/ templates:
   - `reference/types.md` - TypeScript type patterns
   - `reference/interfaces.md` - Interface definitions
   - `reference/decorators.md` - Decorator usage
6. Creates examples/ templates:
   - `examples/types.ts` - Type examples
   - `examples/interfaces.ts` - Interface examples
7. Validates:
   - YAML syntax ✓
   - Directory structure ✓
   - File extensions ✓
8. Updates `.claude/skills/README.md`:
   - Adds typescript to Framework Skills table
   - Adds to skill combinations if relevant

### Example 2: Creating a Specialized Agent

```bash
/create-component agent formatter "Code formatting specialist using mix format and prettier"
```

**What happens:**

1. Command parses: type=agent, name=formatter, description="Code formatting..."
2. Asks for:
   - Which tools needed? (Read, Write, Bash)
   - Which skills to reference? (@elixir-testing, @ui-design)
   - What's the primary workflow? (Read code → Format → Write back)
3. Creates file: `.claude/agents/formatter.md`
4. Generates content:
   - YAML frontmatter with tools and model
   - System prompt: "You are a code formatting specialist..."
   - Workflow section with numbered steps
   - Quality criteria for formatting
   - Skill references section
   - Best practices
   - Example interaction
5. Validates:
   - YAML syntax ✓
   - Tools format (comma-separated) ✓
   - Skill references valid ✓
6. Notes: "Agent created at `.claude/agents/formatter.md`"

### Example 3: Creating an Orchestration Command

```bash
/create-component command format "Format all project files using formatter agent"
```

**What happens:**

1. Command parses: type=command, name=format, description="Format all..."
2. Asks for:
   - Arguments expected? (optional: [file-pattern])
   - Which subagents used? (formatter)
   - Workflow steps? (Find files → Invoke formatter → Report results)
3. Creates file: `.claude/commands/format.md`
4. Generates content:
   - YAML frontmatter with description and argument-hint
   - Overview section
   - Usage examples
   - How It Works with workflow
   - Subagents Used section
   - Examples section (3 scenarios)
   - Troubleshooting section
   - Best Practices
5. Validates:
   - YAML syntax ✓
   - Workflow uses $ARGUMENTS ✓
   - Subagents referenced correctly ✓
6. Notes: "Command created at `.claude/commands/format.md`"

### Example 4: Updating Existing Skill

```bash
/create-component skill ash-framework "Update with new Reactor patterns"
```

**What happens:**

1. Command detects: Skill already exists
2. Asks: "Update existing skill? (y/n)"
3. If yes:
   - Reviews current structure
   - Identifies what to update
   - Adds new reference docs or examples
   - Maintains existing cross-references
   - Validates updated structure
4. Reports changes made

### Example 5: Creating Meta Skill

```bash
/create-component skill security "Security patterns for authentication and authorization"
```

**What happens:**

1. Full skill creation workflow
2. Asks about security-specific patterns:
   - Authentication methods
   - Authorization patterns (references @ash-framework for policies)
   - Common vulnerabilities
   - Best practices
3. Creates comprehensive structure:
   - SKILL.md with security overview
   - reference/authentication.md
   - reference/authorization.md
   - reference/common-vulnerabilities.md
   - examples/auth-patterns.ex
   - examples/policy-examples.ex
4. Extensive cross-linking to @ash-framework for actor context

### Example 6: Creating a Skill with Mixed Code Examples and Diagrams

```bash
/create-component skill data-ingestion "Patterns for data ingestion and transformation pipelines"
```

**What happens:**

1. Command parses: type=skill, name=data-ingestion, description="Patterns for
   data ingestion and transformation pipelines"
2. Asks for:
   - Which tools needed? (Read, Write, Bash, WebFetch)
   - Related skills? (@reactor-oban, @ash-framework)
   - Key topics to cover? (Source connectors, data validation, transformation,
     loading, error handling)
3. Creates structure:
   ```
   .claude/skills/data-ingestion/
   ├── SKILL.md
   ├── examples/
   └── reference/
   ```
4. Generates SKILL.md with:
   - Valid YAML frontmatter
   - Standard sections
   - Placeholders for content
5. Creates reference/ templates:
   - `reference/source-connectors.md`
   - `reference/data-validation.md`
   - `reference/transformation.md`
6. Creates examples/ templates:
   - `examples/csv-ingestion.ex` (low-level, framework-specific)
   - `examples/json-transformation.ex` (low-level, framework-specific)
7. **Guides on placing high-level examples/diagrams**:
   - Suggests creating `DESIGN/examples/data-ingestion-pipeline.ex` for a
     high-level overview of the pipeline structure.
   - Suggests creating `DESIGN/examples/data-flow-diagram.mermaid` for a
     high-level data flow diagram.
   - Updates `DESIGN/data-pipeline/overview.md` to link to these high-level
     examples/diagrams.
8. Validates:
   - YAML syntax ✓
   - Directory structure ✓
   - File extensions ✓
9. Updates `.claude/skills/README.md`:
   - Adds `data-ingestion` to Framework Skills table.
10. Notes: "Skill created at `.claude/skills/data-ingestion/` with guidance for
    high-level design examples and diagrams."

### Example 7: Creating a Hook

```bash
/create-component hook pre-commit-test "Run tests before git commits"
```

**What happens:**

1. Command parses: type=hook, name=pre-commit-test, description="Run tests..."
2. Asks for:
   - Which event type? (PreToolUse)
   - Which tool to match? (Bash)
   - Implementation type? (Script file)
   - What should the hook do? (Run mix test before git commit)
3. Creates script: `.claude/hooks/pre-commit-test.sh`
4. Generates script content:
   - Shebang and error handling (set -euo pipefail)
   - Read JSON input from stdin
   - Extract command field using jq
   - Check if command matches git commit pattern
   - Run mix test if match found
   - Exit 0 (allow) or 2 (block) based on test results
5. Makes script executable: `chmod +x .claude/hooks/pre-commit-test.sh`
6. Generates JSON configuration:
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
7. Validates:
   - Script file exists ✓
   - Script is executable ✓
   - JSON syntax valid ✓
   - No security vulnerabilities (quoted variables, input validation) ✓
8. Updates `.claude/settings.json`:
   - Adds hook configuration to PreToolUse section
   - Merges with existing hooks if present
9. Tests hook:
   - Runs test command to verify script works
   - Checks exit codes correct
10. Notes: "Hook created at `.claude/hooks/pre-commit-test.sh` and configured in
    `.claude/settings.json`"

## Implementation Workflow

This command follows these detailed steps:

### 1. Parse Arguments

```markdown
Extract from $ARGUMENTS:

- Component type (skill|agent|command|hook)
- Component name (kebab-case)
- Description (used in YAML frontmatter or hook comment)
```

### 2. Gather Requirements

**For Skills**:

- Tools needed (Read, Write, Edit, Grep, Glob, Bash, WebFetch, etc.)
- Framework (generic) or project-specific
- Related skills for cross-referencing
- Key topics to cover (becomes reference/\*.md files)

**For Agents**:

- Tools needed
- Skills to reference (at least 3)
- Primary workflow steps
- Quality criteria to apply

**For Commands**:

- Arguments expected
- Subagents to coordinate
- Workflow steps and branches
- Integration with other commands

**For Hooks**:

- Event type (PreToolUse, PostToolUse, SessionStart, etc.)
- Matcher pattern (exact tool name, regex, or wildcard)
- Implementation type (script file or inline command)
- Hook logic (validation, formatting, logging, etc.)
- Timeout requirement (based on expected execution time)

### 3. Generate Structure

**For Skills**:

```bash
mkdir -p .claude/skills/{name}/examples
mkdir -p .claude/skills/{name}/reference
touch .claude/skills/{name}/SKILL.md
```

**For Agents**:

```bash
touch .claude/agents/{name}.md
```

**For Commands**:

```bash
touch .claude/commands/{name}.md
```

**For Hooks**:

```bash
touch .claude/hooks/{name}.sh
chmod +x .claude/hooks/{name}.sh
```

### 4. Create YAML Frontmatter (or JSON Configuration for Hooks)

**Skills**:

```yaml
---
name: { name }
description: |
  {description provided}
  {when to use based on requirements}
allowed-tools:
  - { tools from requirements }
---
```

**Agents**:

```yaml
---
name: { name }
description: |
  {description provided}
  {when invoked based on requirements}
tools: { comma-separated tools }
model: inherit
---
```

**Commands**:

```yaml
---
description: { description provided }
argument-hint: "{arguments from requirements}"
---
```

**Hooks** - JSON Configuration:

```json
{
  "hooks": {
    "{EventType}": [
      {
        "matcher": "{tool-pattern}",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/{name}.sh",
            "timeout": {timeout-ms}
          }
        ]
      }
    ]
  }
}
```

**Hooks** - Bash Script Template:

```bash
#!/usr/bin/env bash
# Hook: {EventType} - {description}
#
# {Hook logic description}

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract relevant fields
# {Field extraction logic}

# Hook logic
# {Validation/formatting/logging code}

# Exit codes:
# 0 = allow operation
# 2 = block operation
exit 0
```

### 5. Populate Content

**Skills** - Create full structure:

- SKILL.md with all standard sections
- reference/\*.md for each topic (3-5 files)
- examples/\*.ex for code patterns (3-5 files)

**Agents** - Create complete prompt:

- System prompt defining role
- Workflow section with numbered steps
- Quality criteria
- Skill references
- Best practices
- Example interaction

**Commands** - Create full documentation:

- Overview and usage
- How It Works workflow
- Subagents used
- Examples (3-5 scenarios)
- Troubleshooting
- Best Practices

**Hooks** - Create script and configuration:

- Bash script with input validation
- JSON configuration for settings file
- Security checks (quote variables, validate paths)
- Documentation comments
- Test cases

**Guidance for Code Snippets and Diagrams**:

- **High-level code examples** related to _specific features of the design_
  should be placed in `DESIGN/examples/` and linked from `DESIGN/` documents.
- **Low-level framework-specific code** should be placed under the skills
  (`.claude/skills/{skill}/examples/`) and linked from `DESIGN/` documents.
- **High-level architectural diagrams** that explain the overall structure of
  your application and how its components interact should remain in the
  `DESIGN/` files.
- **Low-level implementation diagrams** that illustrate generic framework
  patterns should be moved to the skills (`.claude/skills/{skill}/reference/`).

### 6. Add Cross-References

**In SKILL.md**:

- Link to reference/\*.md files
- Link to examples/\*.ex files
- Link to related skills
- Link to DESIGN/ docs
- Link to external official docs

**In reference/\*.md**:

- Link back to SKILL.md
- Link to other reference/\*.md
- Link to examples/\*.ex
- Link to DESIGN/ docs
- Link to related skills

**In agents**:

- Reference skills (not duplicate content)
- Link to DESIGN/ docs for project patterns

**In commands**:

- Reference subagents used
- Link to related commands
- Show integration examples

### 7. Validate

Run validation checks:

```bash
# YAML syntax
grep -A 15 "^---$" {file} | head -n 20

# File structure (skills)
ls -R .claude/skills/{name}/

# Cross-references resolve
grep -o '\[.*\](.*\.md)' {file}

# Quality checklist items
```

From @manage-code-agent skill's quality checklist:

- [ ] YAML frontmatter complete
- [ ] Description includes "what" AND "when"
- [ ] Examples are self-contained
- [ ] Cross-references present (3+ per doc)
- [ ] No code duplication
- [ ] Progressive disclosure structure
- [ ] File structure correct
- [ ] Validation passes

### 8. Update Indexes

**For skills**: Update `.claude/skills/README.md`:

```markdown
| [skill-name](./skill-name/SKILL.md) | Purpose | When to Use |
```

**For all**: Optionally update `.claude/README.md` if significant addition

## Validation Checklist

The command runs these validations:

### Structure Validation

- [ ] Directory/file created in correct location
- [ ] YAML frontmatter markers present (---...---)
- [ ] Required files exist (SKILL.md, reference/, examples/ for skills)
- [ ] File naming follows conventions (kebab-case, .md extension)

### YAML Validation

- [ ] name field present (skills/agents)
- [ ] description field present and multiline
- [ ] tools/allowed-tools field present and formatted correctly
- [ ] argument-hint present (commands)
- [ ] No YAML syntax errors

### Content Validation

- [ ] Description includes "what" AND "when"
- [ ] Standard sections present
- [ ] Cross-references exist (3+ per doc)
- [ ] No framework content duplication
- [ ] Examples are self-contained (skills)
- [ ] Workflow is numbered and specific (agents/commands)

### Link Validation

- [ ] Internal links use correct relative paths
- [ ] Skill references use @ syntax correctly
- [ ] External links are complete URLs
- [ ] No broken links (files exist)

## Troubleshooting

### Invalid YAML Frontmatter

**Problem**: YAML parsing errors when component loaded

**Solution**:

1. Check `---` markers at start and end
2. Verify indentation (2 spaces)
3. Use `|` for multiline strings
4. Quote strings with special characters
5. Test with: `grep -A 15 "^---$" file.md | yamllint -`

### Missing Cross-References

**Problem**: Component feels isolated, no links to related content

**Solution**:

1. Add minimum 3 cross-references per document
2. Link to related skills with @ syntax
3. Link to DESIGN/ docs for project patterns
4. Add examples/ and reference/ links in SKILL.md

### Directory Structure Wrong

**Problem**: Files created in wrong location

**Solution**:

1. Skills: `.claude/skills/{name}/`
2. Agents: `.claude/agents/{name}.md`
3. Commands: `.claude/commands/{name}.md`
4. Delete and recreate in correct location

### Skill Not in Index

**Problem**: New skill not discoverable

**Solution**: Update `.claude/skills/README.md`:

```markdown
| [new-skill](./new-skill/SKILL.md) | Purpose description | When to use it |
```

### Agent Tools Format Incorrect

**Problem**: Agent tools field as YAML list instead of string

**Solution**: Change from:

```yaml
tools:
  - Read
  - Write
```

To:

```yaml
tools: Read, Write, Edit
```

## Best Practices

### For Skills

1. **Start with real patterns** - Base on actual project code
2. **Progressive disclosure** - Overview → reference → examples
3. **Extensive linking** - 3+ cross-references per doc
4. **Self-contained examples** - Runnable code snippets
5. **Show both ways** - ✅ Correct and ❌ Incorrect

### For Agents

1. **Single responsibility** - One clear role
2. **Reference skills** - Never duplicate framework knowledge
3. **Clear workflow** - Numbered, specific steps
4. **Quality criteria** - Measurable standards
5. **Example interactions** - Show expected behavior

### For Commands

1. **Thin orchestration** - Coordinate, don't implement
2. **User in loop** - Present options, user decides
3. **Clear workflow** - Step-by-step with subagent names
4. **Multiple examples** - 3-5 covering different scenarios
5. **Comprehensive troubleshooting** - Common issues with solutions

### For Hooks

1. **Security first** - Validate all inputs, quote variables, test safely
2. **Start simple** - Log-only hooks before complex validation
3. **Specific matchers** - Target exact tools, avoid wildcards
4. **Fast execution** - Keep under timeout limits
5. **Document intent** - Clear comments explaining hook purpose

## Integration with Other Commands

### Create Then Implement Flow

```bash
# Create new skill
/create-component skill database "Database patterns for this project"

# Use skill in implementation
# (implementer agent can now reference @database skill)
/implement Add database connection pooling
```

### Create Then Review Flow

```bash
# Create new agent
/create-component agent security-reviewer "Security-focused code review"

# Use in review command (update /review to invoke security-reviewer)
/review lib/auth/
```

### Iterative Creation

```bash
# Create initial skill
/create-component skill api-design "API design patterns"

# Later, expand it
/create-component skill api-design "Add GraphQL patterns"
# (detects existing, offers to update)
```

## Quality Criteria

Components created by this command must meet:

1. **Functional** - Component works as designed
2. **Valid** - YAML/JSON syntax correct, no parsing errors
3. **Complete** - All required sections present
4. **DRY** - No duplication, references instead
5. **Linked** - 3+ cross-references per doc (skills/agents/commands only)
6. **Discoverable** - Added to indexes
7. **Clear** - Purpose and usage obvious
8. **Maintainable** - Follows established patterns
9. **Secure** - Input validation, quoted variables (hooks only)

## Success Criteria

Component creation succeeds when:

- ✅ Files created in correct locations
- ✅ YAML/JSON frontmatter valid
- ✅ Content follows architecture principles
- ✅ Cross-references present and valid (except hooks)
- ✅ Structure matches component type
- ✅ Scripts executable (hooks only)
- ✅ Security validated (hooks only)
- ✅ Indexes updated
- ✅ Validation checks pass
- ✅ Quality checklist complete

## Remember

> **Keep it clean. Keep it lean. Keep it simple.**

Use @manage-code-agent skill for all patterns. Follow architecture principles.
Validate before committing.

**Structure correctly. Reference extensively. Validate thoroughly.**

## Reference

See [@manage-code-agent](@manage-code-agent) skill for complete guidelines on:

- [Creating Skills](../skills/manage-code-agent/reference/creating-skills.md)
- [Creating Agents](../skills/manage-code-agent/reference/creating-agents.md)
- [Creating Commands](../skills/manage-code-agent/reference/creating-commands.md)
- [Creating Hooks](../skills/manage-code-agent/reference/creating-hooks.md)

---

**Quick Reference:**

| Component | Location                     | Structure                         | Configuration                    |
| --------- | ---------------------------- | --------------------------------- | -------------------------------- |
| Skill     | `.claude/skills/{name}/`     | SKILL.md + reference/ + examples/ | name, description, allowed-tools |
| Agent     | `.claude/agents/{name}.md`   | Single file                       | name, description, tools, model  |
| Command   | `.claude/commands/{name}.md` | Single file                       | description, argument-hint       |
| Hook      | `.claude/hooks/{name}.sh`    | Script + JSON config              | JSON in settings.json            |

---

## Execute

**Component Specification:** $ARGUMENTS

Follow the workflow above to create this component.
