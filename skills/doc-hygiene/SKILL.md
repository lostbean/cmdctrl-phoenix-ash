---
name: doc-hygiene
description: |
  Documentation meta-patterns and hygiene principles for maintaining
  documentation. Use this skill when creating or refactoring documentation to
  ensure single source of truth, progressive disclosure, and proper
  normalization. Essential for maintaining high-quality, interconnected
  documentation across design docs, skills, and project files.
---

# Documentation Hygiene Skill

**Master documentation meta-patterns for maintaining clean, DRY, and
discoverable documentation.**

## What is Documentation Hygiene?

Documentation hygiene is the practice of maintaining documentation using
database normalization principles, DRY (Don't Repeat Yourself), and progressive
disclosure patterns. Good documentation hygiene ensures:

- **Single Source of Truth**: Each concept documented exactly once
- **Progressive Disclosure**: Overview → summary → deep dive linking structure
- **Discoverability**: Clear navigation paths and cross-references
- **Maintainability**: Changes update in one place, propagate everywhere
- **Code-Doc Sync**: Documentation stays current with implementation

## When to Use This Skill

Use this skill when you need to:

- ✅ **Create new documentation** - Structure it properly from the start
- ✅ **Refactor existing docs** - Eliminate duplication and improve navigation
- ✅ **Review documentation changes** - Ensure adherence to hygiene principles
- ✅ **Establish documentation standards** - Define patterns for new
  contributors
- ✅ **Audit documentation quality** - Identify and fix hygiene violations
- ✅ **Sync docs with code** - Keep implementation and documentation aligned

## Core Principles

### 1. Single Source of Truth (DRY for Docs)

**Principle**: Every concept, pattern, or piece of information should be
documented in exactly one authoritative location.

**Why It Matters**:

- Changes update in one place instead of hunting down duplicates
- Reduces risk of contradictory information
- Makes documentation easier to maintain over time
- Forces clear ownership of concepts

**Implementation**:

```markdown
❌ BAD - Duplicated content:

## File: docs/features/user-management.md

Authentication uses JWT tokens with expiry and refresh mechanisms. Tokens are
signed with HS256 and include user claims...

## File: docs/features/api-auth.md

Authentication uses JWT tokens with expiry and refresh mechanisms. Tokens are
signed with HS256 and include user claims...

✅ GOOD - Single source with references:

## File: docs/concepts/authentication.md (AUTHORITATIVE)

Authentication uses JWT tokens with expiry and refresh mechanisms. Tokens are
signed with HS256 and include user claims... [Full details here]

## File: docs/features/user-management.md

User management uses JWT authentication. See
**[Authentication](../concepts/authentication.md)** for complete details.

## File: docs/features/api-auth.md

API endpoints use JWT authentication. See
**[Authentication](../concepts/authentication.md)** for complete details.
```

**When to Duplicate**:

- Never duplicate explanatory content
- DO repeat short context (1-2 sentences) with links to details
- DO include minimal working examples in multiple places if they serve different
  learning contexts

### 2. Progressive Disclosure

**Principle**: Structure information in layers - brief overview, summary, then
deep dive. Link to details instead of inlining everything.

**Why It Matters**:

- Readers get what they need without overwhelming detail
- Documents stay focused and scannable
- Easy to find both quick answers and comprehensive explanations
- Reduces cognitive load

**Information Hierarchy**:

```
Level 1: Overview (1-2 sentences)
    ↓ link to →
Level 2: Summary (1-2 paragraphs, key points)
    ↓ link to →
Level 3: Deep Dive (full explanation, examples, edge cases)
    ↓ link to →
Level 4: Reference Implementation (actual code)
```

**Implementation**:

```markdown
✅ GOOD - Progressive disclosure in README:

## Quick Start

- **Design Docs**: See `DESIGN/Overview.md` for architecture and patterns
- **Actor Context**: Critical security pattern in
  `DESIGN/concepts/actor-context.md`

[Links provide path to more detail]

## Key Architecture Patterns

### 1. Resource-Oriented Design

Model business domain as declarative Ash Resources with attributes,
relationships, actions, and policies in a single source of truth.

See **[Resources](./concepts/resources.md)** for detailed patterns and examples.

[Overview gives essence, link provides deep dive]
```

**Progressive Disclosure Template**:

```markdown
## [Topic Name]

[1-2 sentence overview of what this is and why it matters]

**Key Points**:

- Point 1 with essential detail
- Point 2 with essential detail
- Point 3 with essential detail

**Implementation**: [Brief example or pattern]

See **[Full Topic Details](./path/to/topic.md)** for:

- Complete implementation guide
- Edge cases and troubleshooting
- Advanced patterns
- Related concepts

## Related

- **[Related Topic 1](path)** - How it connects
- **[Related Topic 2](path)** - Why it matters
```

### 3. Normalization (Database Principles for Docs)

**Principle**: Break documentation into atomic, focused documents with clear
relationships, just like normalizing database tables.

**Why It Matters**:

- Each document has a single, clear purpose
- Updates are localized to relevant scope
- Relationships between concepts are explicit
- Easy to reorganize without breaking references

**Document Types** (like database entities):

1. **Concept Docs** - Fundamental ideas (`DESIGN/concepts/`)
2. **Resource Docs** - Domain entities (`DESIGN/resources/`)
3. **Architecture Docs** - System patterns (`DESIGN/architecture/`)
4. **Workflow Docs** - Process flows (`DESIGN/workflows/`)
5. **Reference Docs** - Lookup tables (`DESIGN/reference/`)
6. **Guide Docs** - How-to instructions (`.claude/skills/*/reference/`)

**Implementation**:

```markdown
❌ BAD - One giant file with everything:

## docs/everything.md (5000 lines)

- Concepts
- Features
- Architecture
- Workflows
- Examples
- Reference

✅ GOOD - Normalized structure:

docs/ ├── concepts/ │ ├── domain-model.md # Core domain concepts │ ├──
authentication.md # Auth patterns │ └── caching.md # Cache strategies ├──
features/ │ ├── user-management.md # User features │ └── order-processing.md #
Order features └── architecture/ ├── design-principles.md # Core principles └──
api-design.md # API patterns
```

**Naming Convention**:

- Use clear, descriptive names that indicate scope
- Match file names to primary concept
- Use directories to group related concepts
- Prefer `concept-name.md` over `concept_name.md`

### 4. Cross-Linking Patterns

**Principle**: Create a web of interconnected documents using consistent linking
patterns.

**Why It Matters**:

- Documents form a knowledge graph, not isolated islands
- Multiple entry points to same information
- Contextual navigation based on reader's journey
- Easier to discover related concepts

**Linking Syntax Standards**:

```markdown
✅ Absolute links within DESIGN/: See
**[Actor Context](../concepts/actor-context.md)** for details.

✅ Relative links from root files: See `DESIGN/concepts/actor-context.md` for
details.

✅ Links with context: See **[Resources](./concepts/resources.md)** for detailed
patterns and examples. [Explains WHAT the link provides, not just the title]

✅ Section links: See
**[Actor Context](../concepts/actor-context.md#propagation-patterns)** for
propagation patterns.

❌ Avoid bare URLs without context: See ../concepts/actor-context.md [No context
about what reader will find]

❌ Avoid vague link text: See [here](../concepts/actor-context.md) for more
info. [Link text should be descriptive]
```

**Cross-Reference Categories**:

1. **"See Also" References** - Related concepts at same level

   ```markdown
   ## Related Concepts

   - **[Workflows](./workflows.md)** - Multi-step operations with Reactor
   - **[Jobs](./jobs.md)** - Background processing with Oban
   ```

2. **"Deep Dive" References** - Link to more detailed explanation

   ```markdown
   See **[Complete Actor Context Guide](../concepts/actor-context.md)** for:

   - Propagation patterns
   - Testing strategies
   - Common pitfalls
   ```

3. **"Prerequisites" References** - Concepts to understand first

   ```markdown
   **Prerequisites**: Understand **[Resources](./resources.md)** and
   **[Actions](./actions.md)** before reading this guide.
   ```

4. **"Implementation" References** - Link to actual code

   ```markdown
   See `lib/my_app/accounts/resources/user.ex` for implementation.
   ```

5. **"Back References"** - Link from detailed doc back to overview
   ```markdown
   [Back to Overview](../../Overview.md) | [All Concepts](./README.md)
   ```

**Bidirectional Linking**: Always link in both directions when documents are
closely related:

```markdown
## DESIGN/concepts/resources.md

Resources work with actions to modify state. See **[Actions](./actions.md)** for
action patterns.

## DESIGN/concepts/actions.md

Actions are operations defined on resources. See **[Resources](./resources.md)**
for resource patterns.
```

### 5. Code and Diagram Placement in DESIGN/

**Principle**: `DESIGN/` docs primarily contain explanations, architecture, and
references. Code examples and diagrams are placed strategically based on their
level of abstraction.

> **IMPORTANT**: Low level or library specific diagrams and examples should be
> avoided in general (if needed place them with the skill). High level or
> mutlti-lib interactions should be placed within the design docs.

**Why It Matters**:

- Prevents code/diagrams in docs from going stale
- Ensures examples are runnable and testable (when in skills)
- Maintains clear separation of concerns: design = concepts, skills =
  implementation
- High-level design context remains readily available

**Implementation**:

````markdown
❌ BAD - Low-level code in design docs:

## docs/concepts/authentication.md

Here's how to authenticate:

```elixir
def verify_token(token) do
  case JWT.verify(token, secret()) do
    {:ok, claims} -> {:ok, claims}
    {:error, _} -> {:error, :invalid_token}
  end
end
```
````

✅ GOOD - Reference to skills for low-level code:

## docs/concepts/authentication.md

Authentication must be performed at entry points (controllers, API endpoints,
LiveView mounts) and credentials validated before granting access.

See `.claude/skills/phoenix-auth/SKILL.md` for complete authentication patterns
and runnable examples.

✅ GOOD - High-level, design-specific code in docs/examples/:

## docs/workflows/order-processing.md

The order processing workflow orchestrates several steps.

See
[Order Processing Example](../examples/workflows/order_processing_example.ex)
for a high-level overview of the workflow structure.

## docs/examples/workflows/order_processing_example.ex

```elixir
defmodule MyApp.OrderProcessing do
  use Reactor

  step :validate_order do
    # ...
  end

  step :process_payment do
    # ...
  end
end
```

````
**Where Code and Diagrams Live**:
- **docs/** or **DESIGN/**:
    - **High-level architectural diagrams** that explain the overall structure of your application and how its components interact.
    - **High-level code examples** related to *specific features of the design* (e.g., a simplified workflow structure, a high-level data transformation pipeline) should be placed in `docs/examples/` and linked from documentation.
- **.claude/skills/**: Patterns with minimal illustrative examples, low-level framework-specific code, and generic diagrams.
- **lib/**: Actual implementation (single source of truth).
- **test/**: Test examples showing usage.### 6. Template Structures

**Principle**: Use consistent templates for different document types to improve scannability and completeness.

#### Concept Document Template

```markdown
# [Concept Name]

**One-sentence description of what this concept is**

## Overview

[2-3 paragraphs explaining the concept, why it exists, and key benefits]

## Core Principles

### Principle 1: [Name]

[Explanation]

### Principle 2: [Name]

[Explanation]

## Key Patterns

### Pattern 1: [Name]

**Use when**: [Situation]

**Implementation**: [Brief description or reference to skill]

## Common Pitfalls

- ❌ **Don't [anti-pattern]** - [Why it's bad]
- ❌ **Don't [anti-pattern]** - [Why it's bad]

## Related Concepts

- **[Related 1](./path.md)** - How it connects
- **[Related 2](./path.md)** - Why it matters

## Implementation Details

See `.claude/skills/[skill-name]/reference/[topic].md` for complete implementation patterns.
````

#### Resource Document Template

```markdown
# [Domain] Resources

**Domain-level resources and their relationships**

## Overview

[Purpose of this domain and key resources]

## Resources

### [Resource Name]

**Purpose**: [What this resource represents]

**Key Attributes**:

- `attribute_name` - Description
- `attribute_name` - Description

**Relationships**:

- `belongs_to :other` - Description
- `has_many :items` - Description

**Key Actions**:

- `:create` - When to use
- `:custom_action` - Purpose

See `lib/my_app/[domain]/resources/[resource].ex` for implementation.

## Workflows

[How resources in this domain work together]

## Related Documentation

- **[Related concept](../concepts/name.md)** - Context
```

#### Skill SKILL.md Template

```markdown
---
name: skill-name
description: >
  What the skill does AND when to use it. Be specific about both.
allowed_tools:
  - Read
  - Grep
---

# [Skill Name] Skill

**One-sentence elevator pitch**

## What is [Skill Topic]?

[Explain the domain/framework/pattern this skill covers]

## When to Use This Skill

Use this skill when you need to:

- ✅ **Task 1** - Specific scenario
- ✅ **Task 2** - Specific scenario

## Core Principles

[Key patterns and best practices]

## Quick Reference

[Table or list of common tasks with links to details]

## File Organization

[Structure of this skill directory]

## Related Skills

- **[skill-name]** - When to use instead
```

#### Architecture Document Template

```markdown
# [Architecture Component]

**System-level pattern or design**

## Problem Statement

[What problem does this architecture solve?]

## Solution

[High-level approach]

## Architecture

[Diagram or structure description]

## Key Components

### Component 1

[Purpose and responsibilities]

### Component 2

[Purpose and responsibilities]

## Implementation Patterns

[Common patterns for using this architecture]

See `.claude/skills/[skill]/reference/` for implementation details.

## Trade-offs

**Benefits**:

- Benefit 1
- Benefit 2

**Costs**:

- Cost 1
- Cost 2

## Related Architecture

- **[Related](./other.md)** - How they interact
```

### 7. Documentation Sync Requirements

**Principle**: Documentation must stay synchronized with code changes.
Documentation updates happen in the same commit as code changes.

**Why It Matters**:

- Prevents documentation drift
- Makes code review more complete
- Documentation becomes part of definition of done
- Easier to track what changed and why

**What to Update**:

When you change code, update these in the SAME commit:

1. **Module documentation** (`@moduledoc`) - Purpose and usage
2. **Function documentation** (`@doc`) - Parameters, return values, examples
3. **DESIGN/ docs** - If architecture or concepts change
4. **CLAUDE.md** - If project-level patterns change
5. **Skills** - If framework usage patterns change
6. **README.md** - If setup or core features change

**Implementation**:

```bash
# ❌ BAD - Two separate commits
git commit -m "feat: add actor validation"
git commit -m "docs: update actor context docs"

# ✅ GOOD - Single commit with code + docs
git add lib/my_app/auth/validator.ex
git add DESIGN/concepts/actor-context.md
git add .claude/skills/ash-framework/reference/actor-context.md
git commit -m "feat: add actor validation with updated documentation"
```

**Doc Sync Checklist**:

```markdown
When making code changes, verify:

- [ ] Module `@moduledoc` updated
- [ ] Function `@doc` updated for public functions
- [ ] DESIGN/concepts/\*.md updated if concepts changed
- [ ] DESIGN/architecture/\*.md updated if architecture changed
- [ ] Relevant skill updated if patterns changed
- [ ] CLAUDE.md updated if project conventions changed
- [ ] All links still valid (no broken references)
- [ ] Examples still accurate and runnable
```

## DESIGN/ Refactor Guidelines

### Example Documentation Structure

```
docs/
├── overview.md              # Entry point, architecture overview
├── concepts/                # Core patterns and principles
├── features/                # Feature-specific documentation
├── architecture/            # System design and patterns
├── guides/                  # How-to guides and tutorials
├── workflows/               # User flows and business processes
├── ui/                      # UI patterns, design system
├── security/                # Auth, authorization, security
├── testing/                 # Testing strategies
└── reference/               # API reference, lookup docs
```

### Refactoring Best Practices

1. **Identify Duplication** - Search for repeated explanations

   ```bash
   # Find potential duplicates
   grep -r "authentication" docs/ | wc -l
   ```

2. **Create Authoritative Source** - Choose best location for each concept
   - Core patterns → `concepts/`
   - Domain-specific → `resources/` or domain directory
   - System design → `architecture/`

3. **Replace with References** - Link to authoritative source

   ```markdown
   # Before

   Long explanation of actor context...

   # After

   See **[Actor Context](../concepts/actor-context.md)** for details.
   ```

4. **Validate Links** - Ensure all cross-references work

   ```bash
   # Check for broken links (use appropriate tool)
   grep -r "\[.*\](.*\.md" docs/
   ```

5. **Test Navigation Paths** - Verify readers can find information
   - From Overview → specific topic
   - From topic → related topics
   - From implementation → design rationale

### Common Refactoring Patterns

**Pattern 1: Extract Repeated Section**

```markdown
# Before: Duplicated in multiple files

File A: [Long explanation of concept X] File B: [Same explanation of concept X]
File C: [Similar explanation of concept X]

# After: Single source + references

concepts/concept-x.md: [Authoritative explanation] File A: See
**[Concept X](../concepts/concept-x.md)** File B: See
**[Concept X](../concepts/concept-x.md)** File C: See
**[Concept X](../concepts/concept-x.md)**
```

**Pattern 2: Split Overly Large File**

```markdown
# Before: One file with multiple concerns

design-doc.md (3000 lines)

- Concept A
- Concept B
- Architecture C
- Workflow D

# After: Focused files with navigation

concepts/concept-a.md concepts/concept-b.md architecture/architecture-c.md
workflows/workflow-d.md overview.md (with links to all)
```

**Pattern 3: Add Progressive Disclosure**

```markdown
# Before: Everything at same level

## Topic

[Full detailed explanation in one place]

# After: Layered information

## Topic (Overview)

[Brief explanation]

See **[Topic Deep Dive](./topics/topic.md)** for:

- Detailed patterns
- Edge cases
- Examples

## topics/topic.md

[Full detailed explanation]
```

## Documentation Quality Checklist

Use this checklist when creating or reviewing documentation:

### Structure

- [ ] Clear, descriptive title
- [ ] One sentence summary at top
- [ ] Logical section hierarchy
- [ ] Table of contents for long docs (>3 screens)
- [ ] Appropriate document type (concept, resource, architecture, etc.)

### Content

- [ ] No duplicated content from other docs
- [ ] Progressive disclosure (overview → details)
- [ ] Links to related concepts
- [ ] Links to implementation (code files)
- [ ] Examples in skills, not in DESIGN/
- [ ] Clear ownership of information

### Navigation

- [ ] Links to parent/overview docs
- [ ] Links to related sibling docs
- [ ] Links to deeper detail docs
- [ ] All links tested and working
- [ ] Bidirectional links where appropriate

### Maintainability

- [ ] Updated in same commit as code changes
- [ ] No stale examples or patterns
- [ ] Clear file naming
- [ ] Proper directory organization
- [ ] Version-specific information marked

### Accessibility

- [ ] Scannable (headers, lists, tables)
- [ ] Search-friendly (good keywords)
- [ ] Multiple entry points (linked from multiple places)
- [ ] Clear context (reader knows where they are)

## Anti-Patterns to Avoid

### ❌ Copy-Paste Documentation

**Problem**: Same content duplicated across multiple files

**Why It's Bad**:

- Updates only fix one location, others go stale
- Contradictory information emerges
- Maintenance burden multiplies

**Solution**: Single source of truth with references

### ❌ Orphaned Documents

**Problem**: Document with no inbound links

**Why It's Bad**:

- Undiscoverable by readers
- Might as well not exist
- Contribution wasted

**Solution**: Link from Overview, related concepts, or parent docs

### ❌ Link Rot

**Problem**: Broken links due to file moves or renames

**Why It's Bad**:

- Breaks navigation paths
- Reader hits dead ends
- Degrades trust in documentation

**Solution**: Search and update links when moving/renaming files

### ❌ Explanation Overload

**Problem**: Every document explains everything in full detail

**Why It's Bad**:

- Readers overwhelmed with information
- Hard to find the key point
- Duplicates effort across docs

**Solution**: Brief context + link to authoritative source

### ❌ No Context Links

**Problem**: Links without explaining what reader will find

```markdown
❌ See [here](./link.md) ❌ Check out ./concepts/resources.md
```

**Solution**: Descriptive link text with context

```markdown
✅ See **[Resources](./concepts/resources.md)** for declarative domain modeling
patterns ✅ Review **[Actor Context](../concepts/actor-context.md#testing)** for
testing strategies
```

### ❌ Code in Design Docs

**Problem**: Implementation examples in DESIGN/ directory

**Why It's Bad**:

- Can't test or lint the code
- Examples go stale
- Violates separation of concerns

**Solution**: Reference code in skills or actual implementation files

### ❌ Inconsistent Templates

**Problem**: Each document uses different structure

**Why It's Bad**:

- Readers don't know where to find information
- Harder to identify missing sections
- Inconsistent quality

**Solution**: Use templates for document types

## Documentation Workflow

### Creating New Documentation

1. **Choose Document Type** - Concept, resource, architecture, workflow,
   reference?
2. **Select Location** - Which DESIGN/ subdirectory?
3. **Check for Duplication** - Does similar doc already exist?
4. **Use Template** - Start with appropriate template
5. **Write Single Source** - Focus on this topic only
6. **Add Cross-Links** - Link to related concepts
7. **Update Navigation** - Add links from Overview, parent docs
8. **Validate Links** - Test all references work

### Refactoring Existing Documentation

1. **Identify Problems** - Duplication, poor structure, missing links
2. **Choose Authoritative Source** - Where should each concept live?
3. **Extract and Consolidate** - Create single source documents
4. **Replace with References** - Update all duplicates to link
5. **Add Progressive Disclosure** - Layer information
6. **Improve Cross-Linking** - Add bidirectional references
7. **Update Navigation** - Ensure discoverability
8. **Validate Changes** - Test all links, verify no broken paths

### Reviewing Documentation Changes

1. **Check for Duplication** - Is this content already documented?
2. **Verify Single Source** - Is this the authoritative location?
3. **Validate Links** - Do all cross-references work?
4. **Assess Discoverability** - Can readers find this?
5. **Review Template Compliance** - Does it follow standards?
6. **Check Code Sync** - Updated with code changes?

## Examples: Good vs Bad

### Example 1: Actor Context Documentation

```markdown
❌ BAD - Duplicated across 5 files:

## DESIGN/agents/analytics-agent.md (200 lines about actor context)

## DESIGN/agents/model-editor-agent.md (200 lines about actor context)

## DESIGN/resources/accounts.md (150 lines about actor context)

## DESIGN/architecture/design-principles.md (100 lines about actor context)

## DESIGN/security/authorization.md (180 lines about actor context)

Total: 830 lines of duplicated content Update cost: 5 files to change
Consistency risk: High

✅ GOOD - Single source with references:

## DESIGN/concepts/actor-context.md (AUTHORITATIVE - 300 lines)

- Complete explanation
- All patterns
- Testing strategies
- Common pitfalls

## DESIGN/agents/analytics-agent.md

Analytics agents operate with actor context for multi-tenant security. See
**[Actor Context](../concepts/actor-context.md)** for complete patterns.

## DESIGN/agents/model-editor-agent.md

Model editor agents operate with actor context for multi-tenant security. See
**[Actor Context](../concepts/actor-context.md)** for complete patterns.

## DESIGN/resources/accounts.md

User and Organization resources provide actor context for authorization. See
**[Actor Context](../concepts/actor-context.md)** for propagation patterns.

## DESIGN/architecture/design-principles.md

### Agent as Secure Actor

Agents operate with actor context enforcing authorization. See
**[Actor Context](../concepts/actor-context.md)** for comprehensive guide.

## DESIGN/security/authorization.md

Authorization policies evaluate actor context. See
**[Actor Context](../concepts/actor-context.md)** for actor structure and
propagation.

Total: 300 lines of content + 5 short references Update cost: 1 file to change
Consistency risk: Low
```

### Example 2: Progressive Disclosure

```markdown
❌ BAD - All detail at once:

## CLAUDE.md

### Reactor Workflows

Reactor is a saga orchestration engine that manages multi-step workflows with
automatic compensation. It provides steps, dependencies, undo operations, error
handling, and context propagation.

[500 more lines of Reactor patterns, examples, edge cases...]

Reader trying to understand "Quick Start" gets overwhelmed.

✅ GOOD - Layered information:

## CLAUDE.md (Overview level)

### Reactor Workflows

Use Ash Reactor for multi-step operations with compensation actions. If any step
fails, preceding steps rollback automatically.

See **[Workflows](./DESIGN/concepts/workflows.md)** for patterns.

## DESIGN/concepts/workflows.md (Summary level)

# Workflows

Multi-step business processes orchestrated with Ash Reactor using saga patterns.
Reactor manages step dependencies and automatic rollback.

**Key Concepts**:

- Steps: Individual operations
- Dependencies: Execution order
- Compensation: Automatic rollback
- Context: Actor propagation

See **[Reactor Patterns](../architecture/reactor-patterns.md)** for:

- Complete implementation guide
- Advanced orchestration
- Error handling strategies

## DESIGN/architecture/reactor-patterns.md (Deep dive level)

# Reactor Patterns

[Full comprehensive guide with examples, patterns, edge cases...]

## .claude/skills/reactor-oban/SKILL.md (Implementation level)

[Runnable examples, code patterns, testing strategies...]
```

### Example 3: Cross-Linking

```markdown
❌ BAD - Isolated document:

## DESIGN/concepts/workflows.md

# Workflows

[Content about workflows] [No links to related concepts] [No links from
Overview.md to this document] [No links from other relevant docs]

Result: Orphaned, undiscoverable

✅ GOOD - Web of links:

## DESIGN/Overview.md

**Core Concepts**:

- [Workflows](./concepts/workflows.md) - Multi-step business processes

## DESIGN/concepts/workflows.md

# Workflows

**Prerequisites**: Understand **[Resources](./resources.md)** and
**[Actions](./actions.md)** before reading this guide.

[Content]

**Related Concepts**:

- **[Jobs](./jobs.md)** - Background job processing
- **[Actor Context](./actor-context.md)** - Security propagation in workflows

**Implementation**:

- See **[Reactor Patterns](../architecture/reactor-patterns.md)** for
  orchestration
- See `.claude/skills/reactor-oban/` for code examples

## DESIGN/concepts/jobs.md

Jobs execute asynchronously with Oban, often running Reactor workflows. See
**[Workflows](./workflows.md)** for workflow patterns.

## DESIGN/architecture/reactor-patterns.md

Reactor orchestrates multi-step workflows. See
**[Workflows](../concepts/workflows.md)** for conceptual overview.

Result: Discoverable from multiple entry points, clear relationships
```

## Tools and Commands

### Finding Duplication

```bash
# Search for concept mentions across docs
grep -r "authentication" docs/ | wc -l

# Find files with similar content
grep -l "Domain Model" docs/**/*.md

# Look for duplicated headings
grep -rh "^## " docs/ | sort | uniq -c | sort -rn
```

### Validating Links

```bash
# Extract all markdown links
grep -roh "\[.*\](.*\.md.*)" docs/

# Find potential broken links (files that don't exist)
# (Use appropriate link checker tool)
```

### Finding Orphans

```bash
# Files not linked from main index
comm -23 <(find docs/ -name "*.md" | sort) \
         <(grep -oh "([^)]*\.md)" docs/index.md | sort)
```

## Related Skills

- **manual-qa**: Testing documentation flows and user journeys
- **ash-framework**: Example of well-structured skill documentation
- **phoenix-liveview**: Cross-linking between skills and DESIGN/

## Summary

Good documentation hygiene means:

1. **DRY**: Document each concept once, link everywhere else
2. **Progressive**: Layer information from overview to deep dive
3. **Normalized**: Focused documents with clear relationships
4. **Linked**: Web of cross-references, not isolated islands
5. **Synced**: Updated with code in same commit
6. **Templated**: Consistent structure for document types
7. **Discoverable**: Multiple paths to same information

**Remember**: Documentation is code. Apply the same engineering discipline to
docs that you apply to implementation.
