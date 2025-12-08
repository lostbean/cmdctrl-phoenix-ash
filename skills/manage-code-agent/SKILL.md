---
name: manage-code-agent
description:
  Manage Claude Code skills, commands, agents, and hooks. Use when creating or
  updating skills, commands, agents, or hooks.
---

# Manage Code Agent Skill

**Master the art of creating high-quality Claude Code skills, commands, and
agents.**

## What is This Skill?

This meta skill documents how to create and maintain Claude Code components
following best practices and architecture principles. It's your guide for
building composable, DRY, well-structured Claude Code extensions.

## When to Use This Skill

Use this skill when you need to:

- ✅ **Create a new skill** - Framework knowledge or project-specific patterns
- ✅ **Create a new command** - Slash command orchestrating workflows
- ✅ **Create a new subagent** - Specialized autonomous actor
- ✅ **Create a new hook** - Automated policy enforcement and validation
- ✅ **Update existing components** - Refactor for better structure
- ✅ **Validate component quality** - Ensure adherence to principles
- ✅ **Understand architecture** - Learn the composable layer system

## Architecture Principles

### 1. Composable & Separation of Concerns

Each component has a single, clear responsibility:

- **Skills**: Generic framework knowledge (single source of truth)
- **Subagents**: Specialized autonomous actors (reference skills)
- **Commands**: Thin orchestration layers (coordinate subagents)
- **Hooks**: Automated triggers for policy enforcement (cross-cutting concerns)

See: [reference/architecture-principles.md](#) for deep dive

### 2. Single Source of Truth (DRY)

**Never duplicate content.** Skills are the foundation. Everything else
references skills:

```markdown
<!-- ❌ BAD: Duplicating Ash policy patterns in subagent -->

## Ash Policies

Policies use `authorize_if` and `forbid_if`...

<!-- ✅ GOOD: Reference skill instead -->

For Ash policy patterns, see [@ash-framework](../skills/ash-framework/SKILL.md).
```

See: [reference/dry-principles.md](#) for patterns

### 3. Progressive Disclosure

Structure content from high-level → detailed:

- **SKILL.md**: Overview, when to use, quick reference
- **reference/\*.md**: Deep dives with comprehensive examples
- **examples/\*.ex**: Self-contained runnable code

Users read only what they need, saving tokens and cognitive load.

See: [reference/progressive-disclosure.md](#) for structure

### 4. Normalization & High Linkage

Break content into atomic topics. Link extensively:

- Each concept documented once
- 3+ cross-references per document
- Bidirectional links between related topics
- Links to external official docs

See: [reference/cross-linking.md](#) for patterns

### 5. Human in the Loop

Commands orchestrate but don't decide:

- Architect presents options, user selects
- QA tester reports findings, user approves
- Commands ask when uncertain, don't assume

See: [reference/human-in-loop.md](#) for examples

### 6. Simplicity (KISS)

Keep it clean. Keep it lean. Keep it simple:

- Clear, concise language
- Minimal complexity
- Self-explanatory structure
- Obvious file organization

See: [reference/simplicity.md](#) for guidelines

## Component Types

### Skills

**Purpose**: Generic framework knowledge as single source of truth

**Structure**:

```
skill-name/
├── SKILL.md              # Main entry point
├── examples/             # Self-contained code
└── reference/            # Deep dive docs
```

**See**: [reference/creating-skills.md](reference/creating-skills.md) for
complete guide

### Subagents

**Purpose**: Specialized autonomous actors that do the work

**Structure**: Single `.md` file with YAML frontmatter

**See**: [reference/creating-agents.md](reference/creating-agents.md) for
complete guide

### Commands

**Purpose**: Thin orchestration coordinating subagents

**Structure**: Single `.md` file with YAML frontmatter

**See**: [reference/creating-commands.md](reference/creating-commands.md) for
complete guide

### Hooks

**Purpose**: Automated policy enforcement and validation triggers

**Structure**: JSON configuration in settings files + bash scripts in
`.claude/hooks/`

**See**: [reference/creating-hooks.md](reference/creating-hooks.md) for complete
guide

## Quick Reference

### YAML Frontmatter Formats

#### Skills

```yaml
---
name: skill-name
description: |
  What this skill covers (1-2 sentences).
  When to use it (key scenarios).
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

#### Subagents

```yaml
---
name: agent-name
description: |
  What this agent does (1-2 sentences).
  When it's invoked (key scenarios).
tools: Read, Write, Edit, Grep, Glob
model: inherit
---
```

#### Commands

```yaml
---
description: What this command does and when to use it
argument-hint: "[required-arg] [optional-arg]"
---
```

#### Hooks

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

### Quality Checklist

Before committing any Claude Code component:

- [ ] **YAML frontmatter complete** - All required fields present
      (skills/agents/commands)
- [ ] **JSON syntax valid** - No parsing errors (hooks)
- [ ] **Description includes "what" AND "when"** - Purpose and usage clear
- [ ] **Examples are self-contained** - Can be run independently
- [ ] **Cross-references present** - 3+ links to related content
- [ ] **No code duplication** - References instead of copies
- [ ] **Progressive disclosure** - Overview → details
- [ ] **File structure correct** - Follows established patterns
- [ ] **Validation passes** - YAML/JSON syntax correct, links valid
- [ ] **Security reviewed** - Hook scripts validated for injection/traversal
      (hooks only)

See: [reference/quality-checklist.md](#) for complete criteria

## Validation Commands

### Check YAML Syntax

```bash
# Verify YAML frontmatter is valid
grep -A 20 "^---$" /path/to/file.md | head -n 30
```

### Verify Cross-References

```bash
# Find all markdown links in a file
grep -o '\[.*\](.*\.md)' /path/to/file.md

# Check if referenced files exist
grep -o '(\.\./.*\.md)' /path/to/file.md | sed 's/[()]//g'
```

### Validate File Structure

```bash
# Check skill structure
ls -R .claude/skills/skill-name/

# Verify required files exist
[ -f SKILL.md ] && [ -d reference ] && echo "✅ Structure valid" || echo "❌ Missing files"
```

See: [reference/validation.md](#) for comprehensive checks

## File Organization

```
.claude/
├── skills/               # Framework knowledge (Layer 1)
│   ├── README.md         # Skills index
│   ├── skill-name/
│   │   ├── SKILL.md      # Main entry point
│   │   ├── examples/     # Runnable code
│   │   └── reference/    # Deep dives
│   └── ...
├── agents/               # Specialized workers (Layer 2)
│   ├── architect.md
│   ├── implementer.md
│   ├── code-reviewer.md
│   └── ...
├── commands/             # Orchestration (Layer 3)
│   ├── implement.md
│   ├── review.md
│   ├── design.md
│   └── ...
├── hooks/                # Automation scripts (Cross-cutting)
│   ├── pre-commit-test.sh
│   ├── session-start-context.sh
│   └── ...
├── settings.json         # Project hooks configuration
└── README.md             # Complete guide
```

## External Resources

### Official Documentation

- **Claude Code Docs**: https://docs.anthropic.com/en/docs/claude-code
- **YAML Frontmatter Spec**: Claude Code documentation for YAML schema
- **File Structure Requirements**: Claude Code best practices guide

### Project Documentation

- **Project documentation**: Check your application's architecture and design
  docs
- **Team conventions**: Review project README and development guides
- **.claude/README.md**: Complete Claude Code setup guide

### Related Skills

- **@doc-hygiene**: Documentation best practices, DRY principles
- **@ash-framework**: Example of well-structured skill
- **@reactor-oban**: Example of framework skill patterns

## Learning Path

### Beginner: Understanding Structure

1. Read this SKILL.md - High-level overview
2. Study [reference/creating-skills.md](reference/creating-skills.md) - How to
   create skills
3. Examine `.claude/skills/ash-framework/` - Real-world example
4. Create a simple skill for practice

### Intermediate: Building Components

1. Read [reference/creating-agents.md](reference/creating-agents.md) - Subagent
   patterns
2. Study `.claude/agents/architect.md` - Well-structured agent
3. Read [reference/creating-commands.md](reference/creating-commands.md) -
   Command orchestration
4. Create a command that coordinates subagents

### Advanced: Refactoring

1. Study refactor plan principles in IMPLEMENTATION/
2. Apply DRY principles to existing components
3. Add progressive disclosure to documentation
4. Enhance cross-linking across components

## Troubleshooting

### YAML Frontmatter Errors

**Error**: Component not recognized by Claude Code

**Check**:

1. YAML starts and ends with `---` markers
2. Indentation is consistent (2 spaces)
3. Multiline strings use `|` or `>` correctly
4. No special characters breaking YAML

See: [reference/troubleshooting.md](#)

### File Structure Issues

**Error**: Files not found when referenced

**Check**:

1. Path references are relative or absolute correctly
2. File extensions match (.md not .markdown)
3. Directory structure matches expectations
4. Case-sensitive naming correct

### Cross-Reference Breaks

**Error**: Links don't resolve

**Check**:

1. Relative paths are correct (../ for parent)
2. Referenced files actually exist
3. Anchor links match heading names
4. Special characters in headings encoded

## Best Practices

### Creating Skills

1. **Start with real code** - Base examples on actual project code
2. **One pattern, one location** - Document once, reference everywhere
3. **Show both ways** - ✅ Correct and ❌ Incorrect examples
4. **Link extensively** - 3+ cross-references per doc
5. **Test examples** - Ensure code is self-contained and runnable

### Creating Subagents

1. **Reference skills** - Never duplicate framework knowledge
2. **Define clear role** - Single responsibility
3. **Specify tools** - Only what's needed
4. **Document workflow** - Step-by-step process
5. **Include examples** - Show expected interactions

### Creating Commands

1. **Thin orchestration** - Coordinate, don't implement
2. **Clear workflow** - Numbered steps
3. **Multiple examples** - Show various use cases
4. **Troubleshooting** - Common issues and solutions
5. **Success criteria** - Define what "done" means

### Creating Hooks

1. **Security first** - Validate inputs, quote variables, test safely
2. **Start simple** - Log-only hooks before validation logic
3. **Specific matchers** - Target exact tools, not wildcards
4. **Fast execution** - Keep under timeout limits
5. **Document intent** - Clear comments in scripts

## Success Criteria

A well-crafted Claude Code component:

- ✅ **Clear purpose** - Obvious what it does and when to use
- ✅ **Complete YAML** - All frontmatter fields present
- ✅ **DRY structure** - No duplication, references instead
- ✅ **Progressive disclosure** - Overview → details
- ✅ **Extensive linking** - 3+ cross-references
- ✅ **Self-contained examples** - Runnable code snippets
- ✅ **Validated** - YAML syntax, file structure, links checked

## Remember

> **Keep it clean. Keep it lean. Keep it simple.**

Good Claude Code components are obvious, maintainable, and composed. Follow the
principles, use the templates, validate the structure.

**Think in layers. Reference don't duplicate. Link extensively.**

---

**Next Steps**:

- Read [reference/creating-skills.md](reference/creating-skills.md) to create
  your first skill
- Study [reference/creating-agents.md](reference/creating-agents.md) for
  subagent patterns
- Review [reference/creating-commands.md](reference/creating-commands.md) for
  command orchestration
- Learn [reference/creating-hooks.md](reference/creating-hooks.md) for automated
  validation
- Use `/create-component` command for guided creation
