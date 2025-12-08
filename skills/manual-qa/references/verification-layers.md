# Verification Layers Reference

## Three-Layer Verification Approach

After each significant action, verify behavior across three layers:

1. **UI Layer** - Visual and interactive correctness
2. **Backend Layer** - Database state and application logs
3. **Integration Layer** - End-to-end workflow coherence

---

## UI Layer Verification

### Purpose

Verify that the user interface displays correctly, provides appropriate
feedback, and handles interactions properly.

### Verification Checklist

- [ ] **Visual Elements Display Correctly**
  - All expected elements visible
  - No layout issues or overlapping content
  - Correct styling applied
  - Images and icons load properly

- [ ] **User Feedback Appears**
  - Success messages show after successful actions
  - Error messages display for failures
  - Loading states visible during processing
  - Progress indicators update correctly

- [ ] **Interactive Elements Work**
  - Buttons clickable and responsive
  - Forms accept input correctly
  - Dropdowns and selects functional
  - Links navigate to correct destinations

- [ ] **Error Handling**
  - Validation errors appear inline
  - Error messages are user-friendly
  - Errors suggest remediation steps
  - Forms prevent invalid submission

- [ ] **No JavaScript Errors**
  - Console clean of errors
  - No unhandled promise rejections
  - Warnings only for expected conditions

### Tools to Use

```javascript
// Take text snapshot for verification
take_snapshot();

// Take visual screenshot for evidence
take_screenshot({ filePath: "./evidence/ui-state.png" });

// Check for JavaScript errors
list_console_messages({ types: ["error", "warn"] });

// Verify specific text present
wait_for({ text: "Expected Message" });
```

### Common UI Issues to Look For

**Layout Problems:**

- Overlapping elements
- Text overflow
- Missing scrollbars
- Incorrect alignment

**Missing Feedback:**

- No success confirmation after save
- No error message on failure
- No loading state during async operations
- No progress indicator for long operations

**Broken Interactions:**

- Buttons disabled when they should be enabled
- Forms not submitting
- Links not navigating
- Modals not closing

**Poor Error Messages:**

- Technical jargon (e.g., "500 Internal Server Error")
- No recovery guidance
- Vague errors (e.g., "Something went wrong")
- Missing context

---

## Backend Layer Verification

### Purpose

Verify that database state is correct, relationships are maintained, and
application logs don't contain unexpected errors.

### Verification Checklist

- [ ] **Database Records Correct**
  - Expected records created/updated
  - All required fields populated
  - Status fields reflect correct state
  - Timestamps accurate

- [ ] **Relationships Maintained**
  - Foreign keys point to correct records
  - No orphaned records
  - Many-to-many associations complete
  - Cascade deletes work correctly

- [ ] **Status Fields Accurate**
  - Record status matches UI state
  - Workflow states progress correctly
  - Flags and booleans set appropriately

- [ ] **No Unexpected Errors**
  - No errors in application logs
  - No database errors (constraints, syntax)
  - No timeout messages
  - Warnings only for expected conditions

- [ ] **Data Consistency**
  - No duplicate records when uniqueness expected
  - Counters and aggregates accurate
  - Computed fields calculated correctly
  - JSON/JSONB fields valid

### Tools to Use

```elixir
// Query database directly
tidewave.execute_sql_query({
  query: "SELECT * FROM table_name WHERE id = $1",
  arguments: [record_id]
})

// Execute application code
tidewave.project_eval({
  code: """
  # Query using Ash
  MyApp.Resource
  |> Ash.Query.filter(status == :active)
  |> Ash.read(authorize?: false)
  """
})

// Check application logs
tidewave.get_logs({ tail: 20, grep: "error|Error|ERROR" })

// Verify operation logged
tidewave.get_logs({ tail: 20, grep: "success|complete" })
```

### Common Backend Issues to Look For

**Data Inconsistencies:**

- Record status not matching UI state
- Missing required relationships
- Duplicate records
- Incorrect timestamps (future dates, zeros)

**Orphaned Records:**

```sql
-- Example: Find orphaned resources
SELECT COUNT(*)
FROM resources r
WHERE NOT EXISTS (
  SELECT 1 FROM organizations org
  WHERE org.id = r.organization_id
)
```

**Log Errors:**

- Database connection errors
- Query failures
- Constraint violations
- Timeout messages
- Stack traces

**Missing Data:**

- Expected records not created
- Fields null when they should have values
- JSON fields empty or malformed
- Relationships not established

---

## Integration Layer Verification

### Purpose

Verify that the complete workflow functions correctly from end to end, with all
layers working together seamlessly.

### Verification Checklist

- [ ] **End-to-End Flow Works**
  - User can complete entire workflow
  - All steps connect properly
  - State persists across steps
  - Navigation between steps smooth

- [ ] **State Synchronized**
  - UI reflects backend state
  - Database matches user actions
  - Real-time updates propagate
  - Caches invalidated appropriately

- [ ] **Multi-Feature Integration**
  - Features work together correctly
  - Data shared between features
  - Changes in one feature visible in another
  - No conflicts between features

- [ ] **Real-Time Updates Work**
  - PubSub events broadcast correctly
  - Live updates appear in UI
  - Multi-tab synchronization works
  - WebSocket connections stable

- [ ] **Session Management**
  - User sessions persist correctly
  - Authentication maintained
  - Session data accurate
  - Logout clears state properly

- [ ] **Multi-Tenancy Enforced**
  - Organization isolation maintained
  - No cross-tenant data leakage
  - Queries scoped to correct organization
  - Policies enforce boundaries

- [ ] **RBAC Permissions Enforced**
  - Admin actions blocked for non-admins
  - Editor permissions respected
  - Viewer can only read
  - Tool access filtered by role

### Integration Test Scenarios

**Upload → Query Flow:**

```javascript
// 1. Upload CSV file
// 2. Verify data source created (backend)
// 3. Navigate to analytics (UI)
// 4. Query newly uploaded data
// 5. Verify results include new data (integration)
```

**Edit → View Flow:**

```javascript
// 1. Edit model and save new version
// 2. Verify version incremented (backend)
// 3. Switch to chat mode (UI)
// 4. Verify old chats still work
// 5. Create new chat with new version (integration)
```

**Role Change → Access Flow:**

```javascript
// 1. Admin creates new user as Editor
// 2. Verify membership role in database (backend)
// 3. Login as new user (UI)
// 4. Attempt to access connection settings
// 5. Verify access denied (integration)
```

### Common Integration Issues to Look For

**State Desynchronization:**

- UI shows "saved" but database unchanged
- Counter displays wrong number
- Cache shows stale data
- Real-time updates don't appear

**Broken Workflows:**

- Step 2 fails after step 1 succeeds
- Navigation broken between steps
- State lost during transition
- Required data missing in later steps

**Multi-Tenant Leakage:**

```elixir
// Test: Can user A see user B's data?
tidewave.project_eval({
  code: """
  # Login as user A
  user_a = get_user("user-a@org1.com")

  # Try to read org B's resources
  org_b_id = get_org_id("org-b")

  MyApp.Resource
  |> Ash.Query.filter(organization_id == ^org_b_id)
  |> Ash.read(actor: user_a)
  # Expected: {:ok, []} or {:error, Forbidden}
  """
})
```

**RBAC Bypass:**

- Viewer can modify data
- Editor can access admin features
- Tool filtering not applied
- Direct API calls bypass checks

---

## Verification Template

Use this template after each significant action:

```markdown
### Verification: [Action Name]

**UI Layer:**

- [ ] Expected elements visible
- [ ] User feedback displayed
- [ ] No JavaScript errors
- Evidence: [Link to snapshot/screenshot]

**Backend Layer:**

- [ ] Database record correct
- [ ] Status field accurate
- [ ] No errors in logs
- Evidence: [Query result]

**Integration Layer:**

- [ ] Workflow continues smoothly
- [ ] State synchronized across layers
- [ ] No permission violations
- Evidence: [End-to-end test result]

**Result:** ✅ PASS / ❌ FAIL

**Issues Found:** [List any issues or "None"]
```

---

## Quick Reference

### When to Verify Each Layer

**After Every User Action:**

- UI Layer ✅ (quick snapshot)
- Backend Layer ⚠️ (if state change expected)
- Integration Layer ❌ (only at workflow milestones)

**After Workflow Completion:**

- UI Layer ✅
- Backend Layer ✅
- Integration Layer ✅

**After Error Condition:**

- UI Layer ✅ (error message displayed)
- Backend Layer ✅ (no partial corruption)
- Integration Layer ⚠️ (recovery path available)

### Minimal Verification (Fast)

```javascript
// UI: Take snapshot
take_snapshot();

// Backend: Quick query
tidewave.execute_sql_query({
  query: "SELECT status FROM records WHERE id = $1",
  arguments: [id],
});

// Integration: Verify next step accessible
click({ uid: "next-step-button" });
```

### Comprehensive Verification (Thorough)

```javascript
// UI: Snapshot + screenshot + console check
take_snapshot();
take_screenshot({ filePath: "./evidence/step-complete.png" });
list_console_messages({ types: ["error", "warn"] });

// Backend: Multiple queries + logs
tidewave.execute_sql_query({
  query: "SELECT * FROM records WHERE id = $1",
  arguments: [id],
});
tidewave.execute_sql_query({
  query: "SELECT COUNT(*) FROM relationships WHERE record_id = $1",
  arguments: [id],
});
tidewave.get_logs({ tail: 30, grep: "error|success" });

// Integration: Complete subsequent workflow
// ... execute next 2-3 steps to confirm continuity ...
```

---

## Summary

- **Always verify UI layer** after user-facing actions
- **Verify backend layer** when state changes expected
- **Verify integration layer** at workflow milestones
- **Use minimal verification** during exploratory testing
- **Use comprehensive verification** for issue reproduction
- **Document evidence** at each layer for issue reports
