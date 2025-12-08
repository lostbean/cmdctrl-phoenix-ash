# Issue Report Template

Use this template when creating issue reports during QA testing.

---

# Issue: {Brief Title}

**Status**: OPEN - Verified in Testing **Severity**: [Critical / High / Medium /
Low] **Priority**: [P0 / P1 / P2] **Date Found**: {YYYY-MM-DD} **Flow**: {Flow
name/number being tested}

---

## Git History Check (REQUIRED)

**Searched commits for**: "{search keywords}"

- [ ] No similar commits found in recent history
- [ ] Found related commits: {list commit hashes}
  - Verified issue still occurs despite these fixes
  - Checked current code at: {file:line}

**Search command used**:

```bash
git log --oneline --grep="{keywords}" -i -20
```

**Result**: {Summary of findings}

---

## Description

{Clear, concise description of the problem. Focus on what is wrong, not how to
fix it.}

---

## Current Behavior

{What happens now - be specific}

**Observed**:

- {Specific behavior 1}
- {Specific behavior 2}

**Evidence**:

- Snapshot excerpt: {paste relevant lines}
- Error message: `{exact error text}`
- Console output: {JavaScript errors if any}

---

## Expected Behavior

{What should happen according to design/requirements}

**Expected**:

- {Expected behavior 1}
- {Expected behavior 2}

**Reference**: {Link to design doc or requirement if available}

---

## Steps to Reproduce

1. {Preconditions: signed in as X, database state Y}
2. Navigate to {URL or UI location}
3. {Action 1 - be specific: "Click button with uid 'submit-button'"}
4. {Action 2}
5. Observe: {specific problematic result}

**Reproducible**: [Always / Sometimes / Rare] **Tested**: {number} times

---

## Verification (Three Layers)

### UI Layer

- **Visual State**: {What UI shows}
- **Console Errors**: {List JavaScript errors or "None"}
- **Screenshot**: {Path to screenshot file or "See snapshot below"}

```
{Paste relevant snapshot excerpt}
```

### Backend Layer

- **Database State**:

```sql
{Query used}
```

```
{Result showing problem}
```

- **Application Logs**:

```
{Relevant log entries from CURRENT session}
```

### Integration Layer

- **Workflow Impact**: {Does this break the complete flow? Can user continue?}
- **State Consistency**: {Is UI/backend in sync?}

---

## Impact

**Affects**:

- User Role(s): {Admin / Editor / Viewer / All}
- Feature Area: {Authentication / Data Upload / Analytics / etc.}
- Scope: {Single feature / Multiple features / System-wide}

**User Impact**:

- {How does this affect the user experience?}
- {Can users work around it?}
- {Does this block core functionality?}

**Workaround**: {If available, describe workaround. Otherwise: "None"}

---

## Recommended Solutions

### Option 1: {Approach Name}

{Description of solution approach with technical details}

```elixir
# Code example if relevant
def fix_example do
  # Implementation suggestion
end
```

**Analysis**:

- **Pros**: {Benefits of this approach}
- **Cons**: {Drawbacks or risks}
- **Files Affected**: {List file paths}
- **Estimated Effort**: {Time estimate}
- **Risk**: [Low / Medium / High]

### Option 2: {Alternative Approach}

{Description of alternative solution}

**Analysis**:

- **Pros**: {Benefits}
- **Cons**: {Drawbacks}
- **Files Affected**: {List file paths}
- **Estimated Effort**: {Time estimate}
- **Risk**: [Low / Medium / High]

**Recommended**: Option {1 or 2} - {Brief justification}

---

## References

**Related Code**:

- {file_path:line_number} - {Brief description}
- {file_path:line_number} - {Brief description}

**Related Commits** (if found in history):

- {commit_hash} - {Commit message}

**Design Documentation**:

- {Link to relevant design doc section}

**Test Plan**:

- {Link to test plan section}

**Related Issues**:

- {Link to related issue file if any}

---

## Technical Context

### Error Messages

```
{Full error messages from CURRENT logs}
```

### Stack Trace

```
{Stack trace if available}
```

### Database Schema

```sql
{Relevant table structure if needed}
```

### Configuration

```
{Relevant config if issue is configuration-related}
```

---

## Evidence Artifacts

**Screenshots**:

- {Path to screenshot 1}
- {Path to screenshot 2}

**Snapshots**:

```
{Full snapshot output if relevant}
```

**Logs**:

```
{Extended log excerpts if needed}
```

**Database Dump**:

```sql
{Relevant database query results}
```

---

## Testing Notes

**Environment**:

- Application Version: {git commit hash}
- Database State: {Fresh / Seeded / After Flow X}
- Browser: {Browser name and version}
- Screen Size: {If relevant to UI issue}

**Reproduction Rate**: {X out of Y attempts}

**Time to Reproduce**: {How long does it take to reproduce?}

**Intermittent**: {Yes / No} - {If yes, describe pattern}

---

## Severity Classification Guide

**Critical (P0)**:

- Application crashes
- Data loss or corruption
- Security vulnerabilities
- Core functionality completely broken
- Affects all users

**High (P1)**:

- Major features not working
- Poor error messages blocking users
- Significant UX issues
- Performance problems making app unusable
- Affects most users or critical workflows

**Medium (P2)**:

- Minor features not working
- Workarounds available
- Cosmetic issues affecting UX
- Edge cases with unclear handling
- Affects some users

**Low / Enhancement**:

- Nice-to-have improvements
- Minor cosmetic issues
- Optimization opportunities
- Documentation gaps
- Affects few users in rare scenarios

---

## Checklist Before Submitting

- [ ] Git history searched for similar issues
- [ ] Issue reproduced multiple times
- [ ] Evidence collected (screenshots, logs, queries)
- [ ] All three layers verified (UI, Backend, Integration)
- [ ] Current logs checked (not stale logs)
- [ ] Database state verified
- [ ] Reproduction steps tested
- [ ] Severity and priority assessed
- [ ] At least one solution suggested
- [ ] Workaround documented (if available)
- [ ] Related files identified

---

**Report Created By**: {Agent name or manual tester} **Report Date**:
{YYYY-MM-DD HH:MM} **Test Session**: {Session identifier if applicable}
