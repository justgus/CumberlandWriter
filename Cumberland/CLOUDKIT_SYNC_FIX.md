# CloudKit Sync Deduplication Fix

## Problem
Story Structure templates were being duplicated across devices due to CloudKit sync. Each device would independently seed templates, and these would sync to other devices, resulting in multiple copies (3 on Mac, 9 on iPad in your case).

## Root Cause
The original seeding logic checked `if any StoryStructure exists, skip` but this didn't account for:
1. Templates already synced from other devices
2. No way to identify which structures were "the same" template
3. Race conditions during initial sync

## Solution Implemented

### 1. Added Template Identifiers
**File: `StoryStructure.swift`**
- Added `templateIdentifier: String?` property to `StoryStructure`
- This is a stable identifier like `"template.academic-paper"` that's consistent across all devices
- User-created structures leave this as `nil`
- Modified `createFromTemplate()` to automatically set this identifier

### 2. Updated Seeding Logic
**File: `CumberlandApp.swift` → `seedStoryStructuresIfNeeded()`**
- Changed from "skip if any structure exists" to "check for each template identifier"
- Now properly idempotent: will only create templates that don't already exist
- Prevents future duplicates from being created

### 3. Added Deduplication Function
**File: `CumberlandApp.swift` → `deduplicateStoryStructures()`**
- Runs once at app launch (before seeding)
- Groups structures by name and projectID
- For duplicates:
  - Keeps the oldest one (by `createdAt`)
  - Backfills `templateIdentifier` if missing
  - Reassigns any cards from duplicate elements to the keeper
  - Deletes the duplicates
- Logs all actions to help debug

### 4. Added Diagnostic Tool
**File: `CumberlandApp.swift` → `DeduplicateStructuresView`**
- macOS-only DEBUG window: **Developer → Deduplicate Structures** (⌘⇧D)
- Shows all Story Structures with their IDs and template identifiers
- Highlights duplicates with warning icons
- Allows manual deduplication runs
- Provides detailed reports of what was deleted

## How to Use

### Immediate Cleanup (Both Devices)
1. **On Mac**: Open the app
2. The deduplication will run automatically at launch
3. Check Console.app for logs with category "Deduplication"
4. Or use **Developer → Deduplicate Structures** to see visual report

5. **On iPad**: Open the app
6. Same automatic process will run
7. Check the Xcode console if attached

### Verify Fix
1. **Mac**: Use the diagnostic tool to see remaining structures
2. Each template should appear only once
3. The `templateIdentifier` field should be populated

### Going Forward
- New templates will be seeded properly (only once)
- CloudKit sync will work normally
- No more duplicates will be created

## Technical Details

### Template Identifier Format
```
template.<lowercase-name-with-dashes>
```
Examples:
- `template.academic-paper`
- `template.three-act-structure`
- `template.hero's-journey-(formal)`

### Deduplication Algorithm
1. Fetch all `StoryStructure` instances
2. Group by `(name, projectID)` key
3. For each group with >1 structure:
   - Sort by `createdAt` (ascending)
   - Keep first (oldest)
   - For each duplicate:
     - Migrate assigned cards to keeper's matching elements
     - Delete the duplicate
4. Save changes

### Migration Safety
- **Non-destructive**: Only deletes true duplicates (same name + projectID)
- **Preserves data**: Card assignments are migrated to keeper
- **Element matching**: Maps duplicate elements to keeper by name or index
- **Cascade delete**: StructureElements are automatically deleted with their parent

## Monitoring

### Console Logs
Search for:
```
Subsystem: <your-bundle-id>
Category: Deduplication
```

Expected output:
```
Deduplicated X StoryStructure duplicate(s), backfilled Y template identifier(s).
```

### Developer Menu
- **⌘⇧9**: Story Structure diagnostics (view all structures)
- **⌘⇧D**: Deduplicate Structures tool (interactive cleanup)

## Rollback
If needed, you can revert by:
1. Commenting out the `deduplicateStoryStructures()` call in the `.task` block
2. The `templateIdentifier` field is optional and won't break anything if unused

## Future Considerations
- Consider adding this pattern to other seed data (RelationTypes, etc.)
- CloudKit has no built-in deduplication for SwiftData
- This pattern provides a robust solution for template-based seed data

---
Last Updated: November 18, 2025
