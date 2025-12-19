---
description:
  Collaborative design workflow - refine ideas into well-structured
  specifications
argument-hint: "[feature description or idea]"
---

# /co-design - Collaborative Design Workflow

Interactive design command that helps you transform rough ideas into
production-ready specifications aligned with your project's architecture,
principles, and existing patterns.

## What This Command Does

The `/co-design` command orchestrates an **interactive design refinement
process** that:

1. **Explores your codebase** to understand existing patterns, design decisions,
   and related work
2. **Generates multiple design options** using the architect agent with
   objective quality scoring
3. **Refines interactively** through guided questions and architect
   consultations
4. **Creates structured specifications** as either Markdown TODOs or JSON user
   stories
5. **Optionally updates DESIGN/ documentation** when architectural decisions are
   made
6. **Suggests next steps** like running `/implement` to execute the plan

**Think of it as**: Having an expert design consultant who knows your codebase
deeply, presents you with well-researched options, answers your questions, and
documents the final decision.

## Usage

```bash
# Simple feature addition
/co-design Add webhook support for external notifications

# Refactoring request
/co-design Refactor the processing agent to use Reactor workflows

# Complex feature with context
/co-design Implement real-time collaboration on resource editing with conflict resolution

# Redesign request
/co-design Redesign the data connection UI to show health metrics

# Bug fix that needs design
/co-design Fix race condition in draft auto-save - need better state management
```

## How It Works

The command follows an **8-phase interactive workflow**:

### Phase 1: Parse Input & Scope

Extract the feature/idea from `$ARGUMENTS` and understand the request.

**What happens:**

- Parse user's description
- Identify the domain (accounts, agents, modeling, etc.)
- Determine scope (new feature, refactor, bug fix, redesign)

### Phase 2: Ask About DESIGN/ Updates

Prompt the user whether DESIGN/ documentation should be updated.

**Question asked:**

> "Does this change require updating DESIGN/ documentation (new patterns,
> architectural decisions, or significant design changes)?"
>
> Options:
>
> - **Yes** - Update DESIGN/ docs after specification is created
> - **No** - Only create implementation specification
> - **Unsure** - I'll decide based on architect's recommendations

**When to update DESIGN/:**

- New architectural patterns introduced
- Changes to core concepts (resources, workflows, jobs)
- Security or authorization model changes
- New integrations or external dependencies
- Significant refactoring affecting multiple domains

**When NOT to update DESIGN/:**

- Simple UI enhancements
- Bug fixes that don't change architecture
- Minor feature additions within existing patterns
- Internal refactoring without API changes

### Phase 3: Exploration

Invoke the **explorer agent** to gather comprehensive context.

**Explorer searches for:**

- Existing code patterns and implementations
- Related DESIGN/ documentation
- Relevant TODOs in IMPLEMENTATION/
- Test patterns and examples
- Skills guidance (@ash-framework, @reactor-oban, etc.)

**Explorer returns:**

- Structured report with relative file paths (from project root)
- Code snippets showing existing patterns
- Design documentation references
- Recommendations for the architect

**Time estimate**: 30-60 seconds for thorough exploration

### Phase 4: Initial Design Options

Invoke the **architect agent** with context from exploration.

**Architect presents:**

- 3-5 distinct solution approaches
- Objective quality scores (out of 10)
- Pros/cons for each option
- Complexity estimates
- Implementation time estimates

**Quality scoring criteria:**

- Design alignment (2 pts)
- Best practices from skills (2 pts)
- Maintainability & simplicity (2 pts)
- Security (2 pts)
- Test coverage (1 pt)
- Long-term sustainability (1 pt)

**Example output:**

```markdown
## Solution Options

### Option A: Oban Worker with Ash Action (Score: 8.5/10)

**Approach**: Create webhook endpoint that validates request and enqueues Oban
job... **Pros**: Reliable retries, actor context preserved, follows existing job
patterns... **Cons**: Adds latency for synchronous webhook responses...
**Complexity**: Medium **Estimated Time**: 3-4 hours

### Option B: Phoenix LiveView Sync (Score: 7/10)

...
```

### Phase 5: Interactive Refinement Loop

**This is where collaboration happens.** The command uses `AskUserQuestion` to
guide you through refinement.

**First question:**

> "Which design option would you like to proceed with, or do you need
> clarification?"
>
> Options:
>
> - **Option A** - {Brief summary}
> - **Option B** - {Brief summary}
> - **Option C** - {Brief summary}
> - **Ask a question** - I need clarification or want to explore a variation

**If you ask a question**, the command:

1. Captures your question (free-form text via "Other" option)
2. Re-invokes architect with: original options + your specific question
3. Architect provides detailed clarification
4. Presents options again with updated information
5. Repeats until you approve an option

**Example questions you might ask:**

- "How does Option A handle duplicate webhooks?"
- "Can we combine the simplicity of Option B with the reliability of Option A?"
- "What if we need to support 1000 webhooks per second?"
- "Does Option C break any existing tests?"

**Loop continues** until you select an option to proceed with.

### Phase 6: Specification Format

Ask you what type of specification to create.

**Question asked:**

> "What type of specification should I create?"
>
> Options:
>
> - **Markdown TODO** - Implementation task list (IMPLEMENTATION/TODOs/\*.md)
> - **JSON User Story** - Formal user story with test steps
>   (DESIGN/user_stories/\*.json)
> - **Both** - Create both MD TODO and JSON user story

**If JSON selected**, follow-up questions:

- **Epic**: What epic does this belong to? (e.g., "Webhook Integration",
  "Modeling UX")
- **Priority**: critical / high / medium / low
- **Complexity**: simple / moderate / complex / very-complex

**Guidance:**

- **Use Markdown TODO for**: Bug fixes, refactoring, internal improvements,
  simple features
- **Use JSON User Story for**: User-facing features, complex workflows, features
  requiring E2E tests
- **Use Both for**: Major features that need both implementation tracking and
  user acceptance criteria

### Phase 7: Generate Specification

Invoke architect to write the final specification in chosen format.

#### Markdown TODO Format

Follows `IMPLEMENTATION/TODOs/` conventions:

**Naming pattern**: `{category}-{NNN}-{brief-description}.md`

**Categories:**

- `feature-` - New feature implementation
- `refactor-` - Code refactoring
- `bug-` - Bug fix
- `security-` - Security improvement
- `performance-` - Performance optimization
- `docs-` - Documentation update

**Structure:**

```markdown
# {Title}

**Created**: 2025-11-20 **Type**: Feature|Refactor|Bug|Security|Performance|Docs
**Status**: Open **Priority**: Critical|High|Medium|Low **Related**: Links to
related issues, PRs, or docs

---

## Description

Clear description of what needs to be implemented and why.

## Context

Background information, user request, design decisions made.

## Design Decision

Which architect option was selected and why (reference quality score).

## Implementation Plan

### Phase 1: {Name}

- [ ] Task with file path (`lib/your_app/...`)
- [ ] Another specific task

### Phase 2: {Name}

- [ ] Task
- [ ] Task

## Technical Details

- **Modules to create/modify**: List with paths
- **Ash Resources affected**: List
- **Database changes**: Yes/No - describe
- **Skills referenced**: @ash-framework, @reactor-oban, etc.

## Testing Strategy

- **Unit tests**: What to test
- **Integration tests**: What workflows
- **E2E tests**: Critical user flows (if applicable)

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Risks & Considerations

- Potential issue 1
- Potential issue 2

## Related Documentation

- DESIGN/path/to/doc.md
- Existing similar feature: {path}
```

#### JSON User Story Format

Follows `DESIGN/user_stories/schemas/user-story-with-tests.schema.json`:

**Naming pattern**: `{NN}-{kebab-case-epic-name}.json`

**Structure:**

```json
{
  "epic": "Epic Name",
  "description": "Brief epic description",
  "userStories": [
    {
      "id": "US-XXX",
      "title": "Story title",
      "narrative": {
        "as": "user role",
        "iWant": "capability",
        "soThat": "business value"
      },
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "priority": "high",
      "complexity": "moderate",
      "dependencies": [],
      "technicalContext": {
        "phoenixRoute": "/route/path",
        "liveviewModule": "YourAppWeb.ModuleLive",
        "ashResource": "YourApp.Domain.Resource",
        "ashActions": ["action.name"],
        "authentication": "required",
        "authorization": "policy details"
      },
      "testSteps": {
        "setup": [],
        "steps": [],
        "assertions": []
      }
    }
  ]
}
```

### Phase 8: Save & Next Steps

**Save the specification:**

1. Write to `IMPLEMENTATION/TODOs/{filename}` or
   `DESIGN/user_stories/{filename}.json`
2. **If JSON user story**: Automatically run
   `./scripts/validate_user_stories.sh`
   - **If validation fails**:
     - Display validation errors to user
     - Invoke architect again to fix the JSON based on error messages
     - Re-run validation
     - Repeat until validation passes
   - **If validation passes**: Proceed to next step
   - **Note**: Validation is blocking - command will not continue until user
     story is valid
3. If DESIGN/ update requested, invoke architect to update relevant docs
4. Show success message with file path

**Validation is automatic and required for JSON user stories** - the command
will not proceed until validation passes.

**Ask about implementation:**

> "Specification saved to: IMPLEMENTATION/TODOs/{filename}
>
> Would you like to run `/implement IMPLEMENTATION/TODOs/{filename}` now to
> start implementation?"
>
> Options:
>
> - **Yes, implement now** - Start /implement command
> - **No, I'll review first** - End command, user can run /implement manually
>   later
> - **Run /design first** - Update DESIGN/ docs before implementing

**If "Yes"**:

```bash
# Automatically invoke
/implement IMPLEMENTATION/TODOs/{filename}
```

**Success message:**

```
✅ Co-design complete!

📄 Specification: IMPLEMENTATION/TODOs/{filename} or DESIGN/user_stories/{filename}.json
🏗️ Design approach: Option {X} (Quality score: {N}/10)
✅ Validation: {Passed (for JSON) | N/A (for MD)}
📚 DESIGN/ docs: {Updated|Not updated}

Next steps:
- Review the specification
- Run /implement when ready
- Reference design decision in commit messages
```

## Subagents Used

### 1. Explorer Agent (@explorer)

- **Role**: Codebase research and context gathering
- **Model**: Haiku (fast, efficient)
- **Invoked**: Once in Phase 3
- **Returns**: Structured report with file paths, patterns, and recommendations

### 2. Architect Agent (@architect)

- **Role**: Design solution generation and refinement
- **Model**: Sonnet (high-quality reasoning)
- **Invoked**: Multiple times
  - Phase 4: Initial options
  - Phase 5: Clarifications (as needed)
  - Phase 7: Write specification
  - Phase 8: Update DESIGN/ (if requested)
- **Returns**: Scored design options, clarifications, specifications

## Examples

### Example 1: Simple UI Feature

```bash
/co-design Add "Export to CSV" button to the analytics chat results
```

**Flow:**

1. DESIGN/ update? → **No** (simple UI addition)
2. Explorer finds: Existing export patterns, CSV generation utilities
3. Architect presents 3 options:
   - Option A: Client-side CSV generation (7/10)
   - Option B: Server-side Oban job with download link (8.5/10)
   - Option C: LiveView temporary download (9/10)
4. You select: **Option C**
5. Format: **Markdown TODO**
6. Creates: `IMPLEMENTATION/TODOs/feature-001-csv-export-results.md`
7. Asks: Implement now? → **Yes**
8. Runs: `/implement IMPLEMENTATION/TODOs/feature-001-csv-export-results.md`

**Time**: ~2-3 minutes to specification

---

### Example 2: Complex Feature with Questions

```bash
/co-design Implement real-time collaboration on resource editing
```

**Flow:**

1. DESIGN/ update? → **Yes** (new architectural pattern)
2. Explorer finds: PubSub patterns, draft system, conflict resolution in agent
   state
3. Architect presents 4 options:
   - Option A: Operational Transforms (OT) (6/10 - complex)
   - Option B: Last-write-wins with PubSub notifications (7.5/10)
   - Option C: Draft per user with merge on publish (8.5/10)
   - Option D: CRDT-based field-level merging (7/10 - experimental)
4. You ask: **"Can Option C handle 10 simultaneous editors?"**
5. Architect clarifies: Provides detailed analysis of concurrency, scaling
   considerations
6. You ask: **"What if we combine Option C with conflict detection from Option
   D?"**
7. Architect presents: **Option E: Hybrid approach** (9/10)
8. You select: **Option E**
9. Format: **Both** (MD TODO + JSON user story)
   - Epic: "Real-Time Collaboration"
   - Priority: High
   - Complexity: Very Complex
10. Creates:
    - `IMPLEMENTATION/TODOs/feature-002-realtime-collaboration.md`
    - `DESIGN/user_stories/11-realtime-collaboration.json`
11. Updates: `DESIGN/architecture/collaboration-patterns.md` (new doc)
12. Asks: Implement now? → **No, I'll review first**

**Time**: ~5-7 minutes with questions

---

### Example 3: Refactoring Request

```bash
/co-design Refactor processing agent to use Reactor workflows instead of manual transaction handling
```

**Flow:**

1. DESIGN/ update? → **Unsure** → Architect recommends **Yes** (significant
   pattern change)
2. Explorer finds: Existing Reactor patterns in workflow code, agent transaction
   code, compensation examples
3. Architect presents 3 options:
   - Option A: Gradual migration (low risk, 7.5/10)
   - Option B: Full reactor rewrite (high value, 9/10)
   - Option C: Hybrid - Reactor for new tools only (pragmatic, 8/10)
4. You select: **Option B**
5. Format: **Markdown TODO**
6. Creates: `IMPLEMENTATION/TODOs/refactor-001-processing-agent-reactor.md`
7. Updates: `DESIGN/architecture/reactor-patterns.md` with new agent workflow
   pattern
8. Asks: Implement now? → **Run /design first** → Runs `/design` to expand
   architecture docs
9. Then prompts: Now run `/implement`? → **Yes**

**Time**: ~4 minutes

---

### Example 4: Bug Fix Requiring Design

```bash
/co-design Fix race condition in draft auto-save causing data loss
```

**Flow:**

1. DESIGN/ update? → **No** (bug fix)
2. Explorer finds: Draft lifecycle, auto-save implementation, related bug TODOs
3. Architect presents 3 options:
   - Option A: Debounce with version checking (8/10)
   - Option B: Optimistic locking with retry (9/10)
   - Option C: Queue-based save serialization (7.5/10)
4. You select: **Option B**
5. Format: **Markdown TODO**
6. Creates: `IMPLEMENTATION/TODOs/bug-003-draft-race-condition.md`
7. Asks: Implement now? → **Yes**

**Time**: ~2 minutes

---

### Example 5: Major Feature with E2E Tests

```bash
/co-design Add multi-factor authentication (MFA) support with TOTP and backup codes
```

**Flow:**

1. DESIGN/ update? → **Yes** (security architecture change)
2. Explorer finds: Auth patterns, session handling, Ash authentication resources
3. Architect presents 5 options (security requires thorough analysis)
4. You ask: **"Does Option A comply with OWASP recommendations?"**
5. Architect confirms: Provides OWASP alignment analysis
6. You select: **Option A**
7. Format: **JSON User Story** (user-facing + E2E tests needed)
   - Epic: "Multi-Factor Authentication"
   - Priority: Critical
   - Complexity: Complex
8. Creates: `DESIGN/user_stories/12-mfa-authentication.json`
   - Includes 15 test steps for E2E validation
   - Browser interaction flows for TOTP setup
   - Database assertions for backup codes
9. Validates: Runs `./scripts/validate_user_stories.sh` → **✅ Passes**
10. Updates:
    - `DESIGN/security/authentication.md`
    - `DESIGN/resources/user.md`
11. Asks: Implement now? → **No, need security review**

**Time**: ~6-8 minutes with security analysis

## Integration with Other Commands

### Before /co-design

**When to use `/design` instead:**

- You already know the solution approach
- You just need DESIGN/ documentation updated
- No exploration or options needed

**When to use `/co-design` instead:**

- You have a rough idea but need research
- Multiple solution approaches are possible
- You want interactive refinement
- You need both DESIGN/ docs AND implementation spec

### After /co-design

**Typical next command: `/implement`**

```bash
# Co-design creates the spec
/co-design Add webhook support

# Then implement the spec
/implement IMPLEMENTATION/TODOs/feature-001-webhook-support.md
```

**Or: `/review` the specification**

```bash
/review IMPLEMENTATION/TODOs/feature-001-webhook-support.md
```

**Or: `/design` to expand DESIGN/ docs first**

```bash
# If you selected "No" to DESIGN/ updates but changed your mind
/design Update webhook architecture documentation based on feature-001 spec
```

### During /implement

**If implementation reveals design issues:**

1. Pause /implement
2. Run `/co-design` with refined understanding
3. Update specification
4. Resume `/implement` with updated spec

### With /fix-issue

**When a bug needs design thinking:**

```bash
# Instead of going straight to /fix-issue
/co-design Fix the [complex bug] - need better approach

# Then use the spec with /fix-issue
/fix-issue IMPLEMENTATION/TODOs/bug-XXX-description.md
```

## Troubleshooting

### "Explorer found too many files"

**Symptom**: Explorer returns 50+ files, context gets overwhelming

**Solution**:

- More specific request: Instead of "add API endpoint", say "add REST API for
  resource export"
- Explorer will filter to most relevant results
- Architect will still receive focused context

### "Architect options are all similar"

**Symptom**: All 3-5 options feel like variations of the same approach

**Cause**: Problem space is well-constrained by existing patterns

**Solution**:

- This is actually good! Means clear best practice exists
- Ask: "Are there alternative approaches outside our current patterns?"
- Architect will explain if deviation is warranted or not

### "I don't like any of the options"

**Symptom**: All architect options miss the mark

**Solution**:

1. Choose "Ask a question" option
2. Explain what you're looking for: "I want something more like [X]"
3. Architect will generate new options based on your direction
4. Can repeat multiple times until satisfied

### "Specification is too vague"

**Symptom**: Generated spec lacks detail you expected

**Cause**: `/co-design` creates high-level specs, not detailed task breakdowns

**Solution**:

- This is by design! `/implement` will add the detailed tasks
- If you need more detail now: Run `/implement` in plan mode
- Or: Edit spec manually before running `/implement`

### "JSON validation fails"

**Symptom**: `./scripts/validate_user_stories.sh` reports schema errors during
Phase 8

**Cause**: Generated user story doesn't match schema perfectly

**Solution**:

- Command automatically runs validation and shows you the errors
- Architect will be asked to fix the JSON automatically
- If auto-fix fails, command will provide the error details
- You can then edit the JSON file manually and the command will re-validate
- Validation must pass before proceeding to next steps

### "Don't know if I should update DESIGN/"

**Symptom**: Unsure whether this change warrants documentation

**Guideline**:

- **Yes** if: New pattern, architectural change, affects multiple domains
- **No** if: Bug fix, minor feature, internal refactoring
- **When in doubt**: Select "Unsure" and architect will recommend

### "Want to change specification format after creation"

**Symptom**: Created MD TODO but now want JSON user story (or vice versa)

**Solution**:

```bash
# Just run co-design again with same description
/co-design [same feature description]

# When asked for format, choose the other option
# Architect will recognize similarity and adapt previous design
```

### "Exploration takes too long"

**Symptom**: Phase 3 explorer agent runs for 2+ minutes

**Cause**: Very broad search or large codebase area

**Solution**:

- This is rare with Haiku model (usually <60 seconds)
- If it happens: Explorer is being thorough, wait it out
- Future optimization: Add scope hints to request (e.g., "in modeling domain
  only")

## Best Practices

### ✅ DO

- **Be specific in your request**: "Add CSV export to analytics chat" > "Export
  feature"
- **Ask questions during refinement**: Architect loves clarifying! Don't settle
  for unclear options
- **Reference quality scores**: "Why is Option B scored lower?" → You'll learn
  about trade-offs
- **Create JSON for user-facing features**: E2E test steps are invaluable
- **Update DESIGN/ for architectural changes**: Keep documentation in sync
- **Review specs before implementing**: Take 2 minutes to read before /implement
- **Combine with other commands**: `/co-design` → `/review` → `/implement` is a
  great flow

### ❌ DON'T

- **Don't skip exploration**: Even if you think you know the codebase, explorer
  finds surprises
- **Don't auto-approve first option**: Higher-scored options are better, but
  trade-offs matter
- **Don't create duplicate TODOs**: Explorer will find existing TODOs - check
  for duplicates first
- **Don't expect implementation details**: This creates specs, not code. Use
  `/implement` for that
- **Don't ignore architect recommendations**: Quality scores are objective and
  research-based
- **Don't worry about JSON validation**: Command automatically validates user
  stories for you
- **Don't mix concerns**: One feature per co-design session. Break large work
  into multiple specs

### 🎯 PRO TIPS

**Tip 1: Use for knowledge transfer**

```bash
# Even if you know the solution, use co-design to document it
/co-design Add caching layer to data source schema queries

# Architect will document best practices and patterns
# Future developers learn from the spec
```

**Tip 2: Iterate on complex features**

```bash
# Break complex work into phases
/co-design Phase 1: Add webhook receiver endpoint
# ... implement ...

/co-design Phase 2: Add webhook delivery retry logic
# ... implement ...

# Each phase builds on previous, specs stay focused
```

**Tip 3: Use "Both" format for major features**

```markdown
# Create both MD TODO (for you) and JSON user story (for stakeholders/QA)

Format: Both

# You get: Implementation task list

# Stakeholders get: User story with acceptance criteria

# QA gets: E2E test steps
```

**Tip 4: Combine with git branches**

```bash
# Start feature branch before co-design
git checkout -b feature/webhook-support

# Run co-design and implement
/co-design Add webhook support
/implement IMPLEMENTATION/TODOs/feature-001-webhook-support.md

# Commits reference the spec
git commit -m "feat(webhooks): implement receiver endpoint

Implements feature-001-webhook-support.md specification.
Uses Option B (Oban worker pattern) for reliability."
```

**Tip 5: Use for design reviews**

```bash
# Already wrote code but want validation?
/co-design Validate my webhook implementation approach

# Architect will present options
# You can see how your approach compares to best practices
# Refactor if needed
```

## Success Criteria

You know `/co-design` succeeded when:

- ✅ **Exploration was comprehensive**: Relevant patterns, docs, and TODOs
  identified
- ✅ **Options were well-researched**: Quality scores make sense, trade-offs are
  clear
- ✅ **You made an informed decision**: Felt confident choosing an option
- ✅ **Specification is actionable**: `/implement` can execute it without
  ambiguity
- ✅ **DESIGN/ docs are updated** (if needed): Architectural changes are
  documented
- ✅ **Next steps are clear**: You know exactly what to do next
- ✅ **Aligned with project principles**: Follows KISS, DRY, actor context,
  multi-tenancy, etc.

**Deliverables checklist:**

- [ ] Specification file in IMPLEMENTATION/TODOs/ or DESIGN/user_stories/
- [ ] (If JSON) Validation passed automatically via
      `./scripts/validate_user_stories.sh`
- [ ] (If Yes) DESIGN/ documentation updated
- [ ] Clear design decision documented (which option, why)
- [ ] Recommendations captured (what to watch out for)
- [ ] Next steps identified (implement, review, design)

---

## Command Summary

```
/co-design [feature/idea/refactor description]

Phases:
  1. Parse & Scope
  2. Ask about DESIGN/ updates
  3. Explore codebase (explorer agent)
  4. Present design options (architect agent)
  5. Refine interactively (Q&A loop)
  6. Choose specification format
  7. Generate specification (architect agent)
  8. Save & suggest next steps

Output:
  - IMPLEMENTATION/TODOs/{category}-{NNN}-{description}.{md|json}
  - (Optional) DESIGN/ documentation updates

Next:
  - /implement {spec} - Execute the plan
  - /design - Expand DESIGN/ documentation
  - /review {spec} - Code review the specification
```

**When in doubt, co-design it out!** 🎨

---

## Execute

**Feature/Idea:** $ARGUMENTS

Follow the workflow above to co-design this feature or idea.
