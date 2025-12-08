# Multi-File Upload Automation Pattern

## Overview

This guide documents the correct approach for automating multi-file CSV uploads
in E2E tests using Chrome DevTools MCP tools.

## The Problem

The MCP `upload_file` tool only supports uploading **one file at a time**. When
you need to upload multiple CSV files to a single data source, calling
`upload_file` multiple times **replaces** the previous selection instead of
appending files.

**Wrong Approach** ❌:

Attempting to call `upload_file` multiple times expecting files to accumulate:

```javascript
// This DOESN'T WORK - each call replaces the previous file
upload_file({ uid: "file_input", filePath: "campaigns.csv" });
upload_file({ uid: "file_input", filePath: "ad_spend.csv" }); // Replaces campaigns.csv
upload_file({ uid: "file_input", filePath: "ad_clicks.csv" }); // Replaces ad_spend.csv
```

## The Solution: Sequential Upload to Existing Data Source

**This is the recommended approach** for E2E testing. Upload files one at a time
and add them to the same existing data source.

### Pattern

1. **First Upload**: Create new data source with first file
2. **Subsequent Uploads**: Select existing data source and upload additional
   files
3. Repeat until all files uploaded to the same data source

### Advantages

- ✅ Uses standard `upload_file` tool (simple, reliable)
- ✅ Tests multi-file functionality (multiple files in one data source)
- ✅ No complex JavaScript required
- ✅ Works with current MCP tools

## Step-by-Step Example

### Upload 3 CSV Files to "Ad Platform" Data Source

#### Upload 1: Create Data Source with First File

```javascript
// Open upload modal
click({ uid: "upload_csv_button" });

// Select "Create new data source" mode
click({ uid: "create_new_radio" });

// Fill data source name
fill({ uid: "data_source_name_input", value: "Ad Platform" });

// Upload first file
upload_file({
  uid: "file_input",
  filePath: "test_data/e2e_campaign_roi/campaigns.csv",
});

// Submit
click({ uid: "upload_submit_button" });
wait_for({ text: "Upload complete!" });
```

**Result**: "Ad Platform" data source created with campaigns.csv

#### Upload 2: Add Second File to Existing Data Source

**Known Issue**: The data source dropdown may not refresh immediately.
**Workaround**: Navigate to a different page and back, or manually refresh.

```javascript
// Navigate away and back (workaround for dropdown caching bug)
click({ uid: "models_nav_link" });
click({ uid: "data_sources_nav_link" });

// Open upload modal
click({ uid: "upload_csv_button" });

// Select "Update existing data source" mode
click({ uid: "update_existing_radio" });

// Select data source from dropdown
click({ uid: "data_source_select" });
click({ uid: "ad_platform_option" }); // Look for this in snapshot

// Upload second file
upload_file({
  uid: "file_input",
  filePath: "test_data/e2e_campaign_roi/ad_spend.csv",
});

// Submit
click({ uid: "upload_submit_button" });
wait_for({ text: "Upload complete!" });
```

**Result**: "Ad Platform" now contains campaigns.csv + ad_spend.csv

#### Upload 3: Add Third File

```javascript
// Repeat pattern for third file
click({ uid: "upload_csv_button" });
click({ uid: "update_existing_radio" });
click({ uid: "data_source_select" });
click({ uid: "ad_platform_option" });

upload_file({
  uid: "file_input",
  filePath: "test_data/e2e_campaign_roi/ad_clicks.csv",
});

click({ uid: "upload_submit_button" });
wait_for({ text: "Upload complete!" });
```

**Result**: "Ad Platform" now contains all 3 files: campaigns.csv, ad_spend.csv,
ad_clicks.csv

## Finding UI Element UIDs

Take a snapshot after opening the upload modal to identify the UIDs:

```javascript
take_snapshot();
```

Look for:

- `create_new_radio` or similar - Radio button for "Create new data source"
- `update_existing_radio` or similar - Radio button for "Update existing data
  source"
- `data_source_name_input` - Text input for new data source name
- `data_source_select` - Dropdown to select existing data source
- `file_input` - File upload input
- `upload_submit_button` - Submit button

UIDs will vary based on the component structure, so always take a snapshot
first.

## Known Issues

### Dropdown Caching Bug (Issue #008)

**Problem**: After creating a new data source, it doesn't immediately appear in
the "Update existing data source" dropdown.

**Workaround**: Navigate to a different page and back before the next upload:

```javascript
// After creating data source
wait_for({ text: "Upload complete!" });

// Navigate away
click({ uid: "models_nav_link" });

// Navigate back
click({ uid: "data_sources_nav_link" });

// Now proceed with next upload - dropdown will show new data source
```

**Status**: HIGH severity bug, awaiting fix. See
`IMPLEMENTATION/TODOs/qa-issue-008-data-source-dropdown-not-refreshed.md`

## Verification

After uploading all files, verify the data source contains the correct number of
tables/files:

```sql
-- Check data source exists
SELECT id, name FROM data_sources WHERE name = 'Ad Platform';

-- Check table count
SELECT COUNT(*) as table_count
FROM data_source_tables
WHERE data_source_id = (SELECT id FROM data_sources WHERE name = 'Ad Platform');
```

**Expected**: 3 tables for "Ad Platform" (campaigns, ad_spend, ad_clicks)

## Complete Example: Upload 11 Files for 3 Data Sources

### Ad Platform (3 files)

1. Create "Ad Platform" + campaigns.csv
2. Navigate away/back (workaround)
3. Update "Ad Platform" + ad_spend.csv
4. Update "Ad Platform" + ad_clicks.csv

### Sales (4 files)

1. Navigate away/back (workaround)
2. Create "Sales" + customers.csv
3. Navigate away/back (workaround)
4. Update "Sales" + orders.csv
5. Update "Sales" + order_items.csv
6. Update "Sales" + products.csv

### Web Analytics (4 files)

1. Navigate away/back (workaround)
2. Create "Web Analytics" + sessions.csv
3. Navigate away/back (workaround)
4. Update "Web Analytics" + page_views.csv
5. Update "Web Analytics" + events.csv
6. Update "Web Analytics" + conversions.csv

**Total**: 11 file uploads creating 3 data sources, each with multiple files

## Phoenix LiveView Considerations

Data source upload is typically configured with:

```elixir
|> allow_upload(:csv_files,
  accept: ~w(.csv),
  max_entries: 5,        # Allows up to 5 files
  max_file_size: 100_000_000,
  auto_upload: true
)
```

This means:

- Maximum 5 files can be selected/uploaded to a data source
- Each file must be under 100 MB
- Only `.csv` files are accepted
- Files are uploaded automatically when form is submitted

## Troubleshooting

### "Data source not found in dropdown"

**Problem**: You created a data source but can't find it in the dropdown.

**Solution**: Use the navigation workaround (Issue #008):

1. Navigate to a different page (e.g., Models)
2. Navigate back to Data Sources
3. Open upload modal - dropdown should now show new data source

### "Upload button disabled"

**Problem**: Can't click submit button.

**Solution**: Ensure you've:

1. Selected a mode (Create new OR Update existing)
2. Filled in data source name (if creating new) OR selected from dropdown (if
   updating)
3. Selected a file
4. Take snapshot to verify button UID and state

### "File not uploading"

**Problem**: File selection works but upload doesn't start.

**Solution**:

1. Verify you clicked submit button
2. Check console for JavaScript errors
3. Ensure file path is correct (relative to cwd or absolute)
4. Take snapshot to verify UI state

## Summary

**Key Takeaways:**

1. Use **sequential upload to existing data source** pattern
2. Upload files one at a time to the same data source
3. Use navigation workaround for dropdown caching bug (Issue #008)
4. Always take snapshots to identify correct UIDs
5. Verify uploads via database queries

**Pattern**:

1. Create new data source with first file
2. Navigate away and back (workaround)
3. Select existing data source and upload next file
4. Repeat steps 2-3 for all remaining files

This pattern is simple, reliable, and works with standard MCP tools. No complex
JavaScript required!
