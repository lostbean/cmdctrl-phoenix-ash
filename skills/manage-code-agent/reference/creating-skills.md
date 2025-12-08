# Creating Skills Reference

**Complete guide to creating high-quality Claude Code skills**

Skills are the foundation of the composable Claude Code system. They contain all
generic framework knowledge and serve as the single source of truth.

## Table of Contents

- [Skill Structure](#skill-structure)
- [YAML Frontmatter](#yaml-frontmatter)
- [Content Guidelines](#content-guidelines)
- [Progressive Disclosure](#progressive-disclosure)
- [Examples Directory](#examples-directory)
- [Reference Directory](#reference-directory)
- [Cross-Linking](#cross-linking)
- [Quality Checklist](#quality-checklist)
- [Real Examples](#real-examples)

## Skill Structure

Every skill follows this directory structure:

```
skill-name/
├── SKILL.md              # Main entry point with YAML frontmatter
├── examples/             # Self-contained, runnable code examples
│   ├── pattern-1.ex      # Example showing pattern 1
│   ├── pattern-2.ex      # Example showing pattern 2
│   └── ...
└── reference/            # Deep dive documentation
    ├── topic-1.md        # Detailed guide on topic 1
    ├── topic-2.md        # Detailed guide on topic 2
    └── ...
```

### File Naming Conventions

- **SKILL.md** - Always uppercase, entry point
- **examples/** - Lowercase, descriptive names, language extension
- **reference/** - Lowercase, kebab-case, .md extension

### Example: ash-framework skill

```
ash-framework/
├── SKILL.md
├── examples/
│   ├── actor-context.ex
│   ├── policies.ex
│   ├── resources.ex
│   ├── changesets.ex
│   ├── transactions.ex
│   └── reactor-workflows.ex
└── reference/
    ├── actor-context.md
    ├── policies.md
    ├── resources.md
    ├── changesets.md
    └── transactions.md
```

## YAML Frontmatter

Every SKILL.md must start with YAML frontmatter:

```yaml
---
name: skill-name
description: |
  What this skill covers (1-2 sentences explaining the topic).
  When to use it (key scenarios where this skill applies).
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash
---
```

### Frontmatter Fields

#### name (required)

- **Type**: String
- **Format**: kebab-case
- **Example**: `ash-framework`, `elixir-testing`, `ui-design`
- **Purpose**: Unique identifier for skill reference (e.g., @ash-framework)

#### description (required)

- **Type**: Multiline string (use `|`)
- **Format**: 2-4 sentences
- **Content**: MUST include both "what" and "when"
- **Example**:
  ```yaml
  description: |
    Ash Framework patterns for your application - use this skill when working with Ash resources,
    policies, actor context, changesets, transactions, or Reactor workflows. Essential for
    authorization, multi-tenancy, and resource-oriented design in this project.
  ```

#### allowed-tools (required)

- **Type**: List of strings
- **Values**: Standard tool names (Read, Write, Edit, Grep, Glob, Bash,
  WebFetch, etc.)
- **Purpose**: Defines which tools can be used when this skill is active
- **Guideline**: Include only tools actually needed

### YAML Validation

Check your YAML with:

```bash
# Extract and verify frontmatter
head -n 15 SKILL.md

# Or use a YAML validator
grep -A 15 "^---$" SKILL.md | yamllint -
```

## Content Guidelines

### SKILL.md Structure

The main SKILL.md file should follow this structure:

1. **Title and Tagline** - Clear, concise description
2. **What is {Framework}?** - Brief introduction (2-3 paragraphs)
3. **When to Use This Skill** - Bulleted list of scenarios
4. **Core Principles** - 3-5 key concepts with links to reference/
5. **Quick Reference** - Table linking to topics
6. **Project-Specific Conventions** - How we use it in this project
7. **File Organization** - Directory structure of the skill
8. **External Resources** - Official docs and related links
9. **Learning Path** - Beginner → Intermediate → Advanced
10. **Troubleshooting** - Common issues and solutions
11. **Related Skills** - Cross-references to other skills

### Writing Style

- **Active voice**: "Use actor context" not "Actor context should be used"
- **Imperative for actions**: "Pass actor explicitly" not "You should pass
  actor"
- **Clear examples**: Show both ✅ correct and ❌ incorrect
- **Concise**: Aim for clarity, not verbosity
- **Scannable**: Use headings, bullets, tables

### Content Depth in SKILL.md

**SKILL.md is an overview**, not a deep dive:

- ✅ **DO**: Link to reference/ for details
- ✅ **DO**: Show minimal inline examples (2-3 lines)
- ✅ **DO**: Use tables for quick reference
- ❌ **DON'T**: Include large code blocks
- ❌ **DON'T**: Duplicate content from reference/
- ❌ **DON'T**: Explain every detail

Example of good overview:

````markdown
### Actor Context is Sacred

**ALWAYS pass actor explicitly in every Ash operation:**

```elixir
# ✅ Correct
Ash.create(changeset, actor: user)

# ❌ Never in production
Ash.create(changeset, authorize?: false)
```
````

See: [reference/actor-context.md](reference/actor-context.md) |
[examples/actor-context.ex](examples/actor-context.ex)

````

## Progressive Disclosure

Structure content from high-level to detailed:

### Layer 1: SKILL.md (Overview)

- What the skill covers
- When to use it
- Core principles (brief)
- Quick reference table
- Links to deeper content

**Goal**: Answer "Should I use this skill?" in < 1 minute

### Layer 2: reference/*.md (Deep Dive)

- Comprehensive explanations
- Multiple examples
- Edge cases and pitfalls
- Debugging guides
- Best practices

**Goal**: Answer "How do I use this pattern?" with complete detail

### Layer 3: examples/*.ex (Runnable Code)

- Self-contained, executable examples
- Both correct and incorrect usage
- Common patterns from real code
- Well-commented

**Goal**: Answer "Show me working code" with copy-paste ready snippets

### Progressive Disclosure Example

**SKILL.md**:
```markdown
### Policies Enforce Security

Every resource has policies that check organization membership and user roles.

See: [reference/policies.md](reference/policies.md) | [examples/policies.ex](examples/policies.ex)
````

**reference/policies.md**:

```markdown
# Policies Reference

Detailed explanation of policy syntax, examples, debugging, testing, etc. (2000+
words with comprehensive coverage)
```

**examples/policies.ex**:

```elixir
# Self-contained policy examples
# 200-300 lines of runnable code
```

## Examples Directory

### Purpose

Provide self-contained, runnable code that demonstrates patterns.

### Guidelines

1. **One file per pattern** - Don't mix unrelated patterns
2. **Self-contained** - Include all necessary context
3. **Well-commented** - Explain what and why
4. **Show both ways** - Correct (✅) and incorrect (❌) usage
5. **Real patterns** - Based on actual project code, not invented
6. **Runnable** - Could be copied and executed

### Example File Structure

```elixir
# examples/actor-context.ex

# Actor Context Examples
# Demonstrates how to propagate actor context in Ash operations

# ============================================================================
# Building Actor Context
# ============================================================================

# ✅ CORRECT: Build actor from authenticated user
def build_actor_from_user(user) do
  %{
    id: user.id,
    organization_id: user.organization_id,
    role: user.role,
    permissions: user.permissions || []
  }
end

# ============================================================================
# Passing Actor in Actions
# ============================================================================

# ✅ CORRECT: Always pass actor explicitly
def create_with_actor(attrs, actor) do
  Resource
  |> Ash.Changeset.for_create(:create, attrs, actor: actor)
  |> Ash.create()
end

# ❌ FORBIDDEN: Never bypass authorization in production
def create_without_auth(attrs) do
  Resource
  |> Ash.Changeset.for_create(:create, attrs)
  |> Ash.create(authorize?: false)  # DON'T DO THIS!
end

# More examples...
```

### Naming Examples

- `actor-context.ex` - Shows actor propagation patterns
- `policies.ex` - Policy definition examples
- `transactions.ex` - Transaction patterns
- `reactor-workflows.ex` - Reactor workflow examples

## Reference Directory

### Purpose

Provide comprehensive deep-dives on specific topics within the skill.

### Guidelines

1. **One topic per file** - Focused, atomic content
2. **Comprehensive** - Cover all aspects of the topic
3. **Heavily linked** - Cross-reference related topics
4. **Well-structured** - Clear headings and table of contents
5. **Examples embedded** - Show patterns inline
6. **Troubleshooting** - Common issues and solutions

### Reference File Structure

````markdown
# Topic Name Reference

**Tagline describing the topic**

## Table of Contents

- [What is {Topic}?](#what-is-topic)
- [Core Concepts](#core-concepts)
- [Usage Patterns](#usage-patterns)
- [Common Pitfalls](#common-pitfalls)
- [Debugging](#debugging)
- [Related Resources](#related-resources)

## What is {Topic}?

Detailed explanation of the concept...

## Core Concepts

### Concept 1

Explanation with examples...

### Concept 2

More explanation...

## Usage Patterns

### Pattern 1: {Description}

```elixir
# Example code
```
````

**See**: [examples/pattern-1.ex](../examples/pattern-1.ex) for complete example

### Pattern 2: {Description}

```elixir
# Example code
```

## Common Pitfalls

### Pitfall #1: {Description}

❌ **Problem**: What goes wrong

✅ **Solution**: How to fix it

## Related Resources

### Examples

- [examples/file.ex](../examples/file.ex) - Description
- [examples/other.ex](../examples/other.ex) - Description

### Reference Docs

- [related-topic.md](./related-topic.md) - Description

### Project Documentation

- [DESIGN/concepts/topic.md](../../../../DESIGN/concepts/topic.md) - Description

### External Resources

- [Official Docs](https://example.com) - Description

````

### Cross-Linking Pattern

Every reference doc should have:

- **Upward links**: To SKILL.md
- **Lateral links**: To related reference/*.md files
- **Downward links**: To examples/*.ex files
- **External links**: To DESIGN/ docs and official documentation

**Minimum**: 3+ cross-references per document

## Cross-Linking

### Link Formats

#### Internal Skill Links

```markdown
<!-- Link to reference doc -->
See: [reference/actor-context.md](reference/actor-context.md)

<!-- Link to example -->
See: [examples/actor-context.ex](examples/actor-context.ex)

<!-- Link to specific section -->
See: [reference/policies.md#debugging](reference/policies.md#debugging-authorization-failures)
````

#### Links to Other Skills

```markdown
<!-- Link to other skill -->

See [@ash-framework](../ash-framework/SKILL.md) for Ash patterns.

<!-- Link to specific reference in other skill -->

See [Actor Context](@ash-framework:reference/actor-context.md)
```

#### Links to Project Docs

```markdown
<!-- Relative path from skill directory -->

See:
[DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md)

<!-- From reference/ subdirectory -->

See:
[DESIGN/security/authorization.md](../../../../../DESIGN/security/authorization.md)
```

#### External Links

```markdown
<!-- Official documentation -->

See: [Ash Framework Docs](https://hexdocs.pm/ash/)

<!-- Specific package docs -->

See: [Ash Policies](https://hexdocs.pm/ash/policies.html)
```

### Cross-Link Examples

From SKILL.md:

```markdown
### Actor Context is Sacred

**ALWAYS pass actor explicitly in every Ash operation.**

See: [reference/actor-context.md](reference/actor-context.md) |
[examples/actor-context.ex](examples/actor-context.ex)
```

From reference/actor-context.md:

```markdown
## Actor Structure

Actor context represents who is performing an operation.

**See**:

- [examples/actor-context.ex](../examples/actor-context.ex#L18-L31) - Building
  actor
- [DESIGN/concepts/actor-context.md](../../../../DESIGN/concepts/actor-context.md) -
  Architecture
- [reference/policies.md](./policies.md) - How policies use actor
- [@reactor-oban](../../reactor-oban/SKILL.md) - Actor in workflows
```

## Quality Checklist

Before committing a skill, verify:

### Structure

- [ ] Directory structure correct (SKILL.md, examples/, reference/)
- [ ] YAML frontmatter present and valid
- [ ] All required frontmatter fields complete

### Content

- [ ] SKILL.md is high-level overview (not deep dive)
- [ ] Description includes "what" AND "when"
- [ ] Core principles section present with 3-5 key concepts
- [ ] Quick reference table included
- [ ] Learning path (Beginner → Advanced) included
- [ ] Troubleshooting section present

### Examples

- [ ] At least 3 examples in examples/ directory
- [ ] Examples are self-contained and runnable
- [ ] Examples show both ✅ correct and ❌ incorrect usage
- [ ] Examples well-commented
- [ ] Examples based on real project code

### Reference

- [ ] At least 3 reference docs in reference/ directory
- [ ] Each reference doc has table of contents
- [ ] Reference docs include troubleshooting sections
- [ ] Reference docs are comprehensive

### Cross-Linking

- [ ] Minimum 3 cross-references in SKILL.md
- [ ] Each reference/\*.md has 3+ cross-references
- [ ] Links to examples/ from SKILL.md and reference/
- [ ] Links to DESIGN/ docs where relevant
- [ ] Links to official external docs included

### DRY Compliance

- [ ] No duplication between SKILL.md and reference/
- [ ] No duplication between reference/ files
- [ ] Examples not duplicated in reference/ (linked instead)
- [ ] Framework patterns not duplicated (referenced instead)

### Validation

- [ ] YAML syntax valid (no parsing errors)
- [ ] All internal links resolve correctly
- [ ] File paths are correct (relative paths work)
- [ ] No broken external links

## Real Examples

### Excellent Skill: ash-framework

**Structure**:

```
ash-framework/
├── SKILL.md              # 250 lines, overview only
├── examples/
│   ├── actor-context.ex  # 300 lines, comprehensive
│   ├── policies.ex       # 250 lines, policy patterns
│   ├── resources.ex      # 200 lines, resource definitions
│   ├── changesets.ex     # 180 lines, changeset patterns
│   ├── transactions.ex   # 150 lines, transaction examples
│   └── reactor-workflows.ex  # 200 lines, workflow patterns
└── reference/
    ├── actor-context.md  # 450 lines, complete guide
    ├── policies.md       # 400 lines, policy deep dive
    ├── resources.md      # 350 lines, resource guide
    ├── changesets.md     # 300 lines, changeset reference
    └── transactions.md   # 250 lines, transaction patterns
```

**What makes it excellent**:

- ✅ Clear progressive disclosure (overview → reference → examples)
- ✅ Extensive cross-linking (10+ links per doc)
- ✅ Self-contained examples
- ✅ Comprehensive coverage without duplication
- ✅ Strong link to project-specific patterns

### Good Skill: reactor-oban

**What it does well**:

- Clear separation of Reactor and Oban topics
- Examples show both patterns
- Reference docs link to Ash for authorization
- Troubleshooting section comprehensive

**Could improve**:

- More cross-references to phoenix-liveview for PubSub
- Additional examples for compensation patterns

## Common Mistakes

### Mistake #1: Duplication

❌ **Problem**: Copying content from reference/ into SKILL.md

✅ **Solution**: Link to reference/ instead of duplicating

### Mistake #2: Too Much Detail in Overview

❌ **Problem**: SKILL.md has 1000+ lines of detailed content

✅ **Solution**: Move details to reference/, keep SKILL.md high-level

### Mistake #3: Missing Cross-Links

❌ **Problem**: Isolated docs with no links to related content

✅ **Solution**: Add 3+ cross-references per document

### Mistake #4: Invented Examples

❌ **Problem**: Examples not based on real project code

✅ **Solution**: Extract patterns from actual codebase

### Mistake #5: Incomplete Frontmatter

❌ **Problem**: Missing required YAML fields

✅ **Solution**: Use template and verify all fields present

## Best Practices

1. **Start with real code** - Base skill on actual project patterns
2. **Document once** - Single source of truth, reference everywhere else
3. **Show both ways** - Correct (✅) and incorrect (❌) examples
4. **Link extensively** - Minimum 3 cross-references per doc
5. **Test examples** - Ensure code is self-contained and runnable
6. **Review existing skills** - Follow established patterns
7. **Keep it simple** - Clear structure, obvious organization
8. **Think in layers** - Overview → deep dive → code
9. **User-focused** - Answer "when" and "how" clearly
10. **Validate before committing** - Run through quality checklist

## Next Steps

- Review [creating-agents.md](./creating-agents.md) for subagent patterns
- Study [creating-commands.md](./creating-commands.md) for command orchestration
- Examine `.claude/skills/ash-framework/` for real examples
- Use `/create-component skill <name>` to generate template

---

**Remember**: Skills are the foundation. Make them excellent, and everything
else becomes easier.
