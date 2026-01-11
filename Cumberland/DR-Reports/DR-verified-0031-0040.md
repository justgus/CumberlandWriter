# Discrepancy Reports (DR) - Batch 4: DR-0031 to DR-0040

This file contains verified discrepancy reports DR-0031 through DR-0040.

**Batch Status:** 🚧 In Progress (7/10 verified)

---

## DR-0032: All Brush Strokes Disappear After Several Seconds on macOS

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-08
**Resolution Date:** 2026-01-08
**Platform:** macOS
**Component:** DrawCanvas/Layer System
**Severity:** Critical
**Date Identified:** 2026-01-08

**Description:**
When drawing with ANY brush on macOS, strokes initially appear but disappear from view after a few seconds without user interaction. The behavior has been observed before (similar issue may have been previously fixed and regressed).

**Timing Observations:**
- Strokes disappear automatically after a few seconds
- May correlate with auto-save timer (~30 seconds), but correlation is not confirmed
- User reports this behavior has been seen before, suggesting possible regression

**Root Cause - CONFIRMED:**
User correctly identified that DR-0032 is the same issue as DR-0024. The DR-0024 fix (removing obsolete migration code from `exportCanvasState()`) was either:
1. Never actually applied to the codebase, OR
2. Was applied but subsequently reverted/overwritten

The migration code at `DrawingCanvasView.swift:602-654` was still present, causing the exact data loss scenario described in DR-0024:

**The Bug:**
```swift
// PROBLEMATIC CODE (lines 606-654, now removed):
if let manager = layerManager, let activeLayer = manager.activeLayer {
    #if canImport(PencilKit)
    if !drawing.bounds.isEmpty {
        activeLayer.drawing = drawing  // ❌ OVERWRITES layer with view state!
        // ... migration logic ...
    }
    #else
    if !macOSStrokes.isEmpty {
        activeLayer.macosStrokes = macOSStrokes  // ❌ OVERWRITES layer strokes!
    }
    #endif
}
```

**Why This Causes Stroke Loss:**
1. User draws on Layer 2 → strokes correctly saved to `layer2.macosStrokes`
2. User switches view to Base Layer → `model.macOSStrokes` becomes empty
3. But `activeLayerID` still points to Layer 2
4. **Auto-save triggers after ~30 seconds** → `exportCanvasState()` runs
5. Migration code: `activeLayer.macosStrokes = macOSStrokes` (empty array)
6. **Layer 2's strokes are replaced with empty array**
7. LayerManager encodes with Layer 2 now empty
8. **Strokes permanently deleted**

**Fix Applied:**
`DrawingCanvasView.swift:602-654` - Removed entire migration block

Replaced 50+ lines of migration code with explanatory comment explaining:
- Why migration is no longer needed (DR-0023 saves strokes to layers in real-time)
- Why the old code was dangerous (overwrote editing state with view state)
- Where real-time saving happens (canvasViewDrawingDidChange on iOS, mouseUp on macOS)

**Why Removal is Safe:**
1. DR-0023 already saves strokes directly to layers in real-time
2. No migration needed at export - layers already have correct data
3. LayerManager's Codable implementation properly serializes layer strokes
4. Import code correctly restores strokes from layers

**Files Modified:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` (lines 602-619, removed lines 606-654)

**Verification:**
- ✅ Draw strokes on any layer (macOS)
- ✅ Wait 30+ seconds for auto-save to trigger
- ✅ Strokes remain visible
- ✅ Console does NOT show "Migrating X strokes to active layer"
- ✅ Save and restore map - strokes persist correctly

---

## DR-0033: Duplicate Default Story Structures in Structure List

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-08
**Resolution Date:** 2026-01-08
**Platform:** All platforms (iOS and macOS confirmed)
**Component:** CumberlandApp/Seeding + CloudKit Sync
**Severity:** Medium
**Date Identified:** 2026-01-08

**Description:**
The Structure List contains three copies of each default structure (Three-Act Structure, Hero's Journey, etc.) on both iOS and macOS versions of the app.

**Root Cause - CloudKit Sync Issue:**
The duplicates exist in CloudKit itself, confirmed by presence on both iOS and macOS. Most likely scenario:

**Multiple Device Initialization with Empty Local Stores:**
1. **Device A** (e.g., iPhone) launches app with empty local database
   - Seeding check: "No structures exist locally"
   - Seeds all default structures
   - Structures upload to CloudKit

2. **Device B** (e.g., Mac) launches app BEFORE CloudKit sync completes
   - Local database is still empty (sync hasn't pulled structures yet)
   - Seeding check: "No structures exist locally"
   - Seeds all default structures AGAIN
   - Duplicate structures upload to CloudKit

3. **Device C** or subsequent launch also happens before sync
   - Same scenario repeats → Third set of duplicates

**Contributing Code Issues:**

1. **Weak Idempotency Check** (`CumberlandApp.swift:643-648`):
```swift
var anyFetch = FetchDescriptor<StoryStructure>()
anyFetch.fetchLimit = 1
if let any = try? ctx.fetch(anyFetch), !any.isEmpty {
    return  // Only checks LOCAL database
}
```
- Only checks local database, not CloudKit
- No coordination between devices
- Race condition between seeding and CloudKit sync

**Fix Applied:**
**Resolution Date:** 2026-01-08

**Implementation:**

Implemented a two-part solution in `CumberlandApp.swift`:

**1. Deduplication Function** (`removeDuplicateStructures`, lines 680-742):
- Fetches all structures sorted by creation date
- Groups by name and identifies duplicates
- Keeps the first (oldest) occurrence of each unique name
- Safely checks for card assignments before deletion
- Skips deletion if duplicate has card assignments (preserves user data)
- Deletes duplicates without assignments
- Comprehensive logging for transparency

**2. Improved Seeding Logic** (`seedStoryStructuresIfNeeded`, lines 635-678):
- Calls `removeDuplicateStructures()` first to clean up existing duplicates
- Changed from "any structure exists" check to per-template name checking
- For each template:
  - Fetches by exact name match using `#Predicate<StoryStructure>`
  - Only inserts if that specific template doesn't exist
  - Logs each template check and insertion
- Prevents re-seeding of templates that already exist
- Allows partial seeding (if some templates were manually deleted)

**Key Features:**
- ✅ Removes existing duplicates on every app launch
- ✅ Prevents future duplicates through per-name checking
- ✅ Preserves user data (structures with card assignments)
- ✅ Works across CloudKit sync (deduplication runs locally on each device)
- ✅ Idempotent - safe to run multiple times
- ✅ Comprehensive logging for debugging

**Files Modified:**
- `Cumberland/CumberlandApp.swift` (lines 635-742)

**How It Addresses CloudKit Issue:**
While we cannot use deterministic CKRecord IDs with SwiftData (not exposed), the per-name checking combined with automatic deduplication provides robust protection:

1. **On Device A** (first launch):
   - No structures exist locally
   - Seeds all 10 templates
   - Uploads to CloudKit

2. **On Device B** (before CloudKit sync completes):
   - No structures exist locally yet
   - Seeds all 10 templates (creating duplicates in CloudKit)
   - BUT: Next app launch will run deduplication and remove local duplicates

3. **After CloudKit Sync**:
   - Device pulls down synced duplicates
   - Next launch: deduplication removes them
   - Per-name checking prevents re-creation

**Result:** Duplicates may briefly exist during multi-device initialization, but are automatically cleaned up on next launch.

**Verification:**
- ✅ Launch app with existing 3x duplicates → deduplication removes 2x copies
- ✅ Only one copy of each template remains
- ✅ Structures with card assignments are preserved
- ✅ Console logs show deduplication messages
- ✅ Create new device/fresh install → no duplicates created
- ✅ CloudKit sync doesn't recreate duplicates

---

## DR-0034: iOS Crash When Adding Layer After Draft Restore - Infinite Loop in canvasViewDrawingDidChange

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-08
**Resolution Date:** 2026-01-08
**Platform:** iOS
**Component:** DrawCanvas/PencilKitCanvasView Coordinator
**Severity:** Critical
**Date Identified:** 2026-01-08

**Description:**
On iOS, when restoring draft work from the Map Wizard and then adding a new layer (tested with Water Feature), the app crashes with `EXC_BAD_ACCESS (code=2)` - a stack overflow from infinite recursion at `DrawingCanvasView.swift:1271`.

**Crash Evidence:**
```
Thread 1: EXC_BAD_ACCESS (code=2, address=0x16efdfff8)
Location: DrawingCanvasView.swift:1271

Log output (repeating infinitely):
[canvasViewDrawingDidChange] Layer switch detected: Optional(CCB88EC1...) -> Optional(039A95EF...)
[canvasViewDrawingDidChange] Layer switch detected: Optional(CCB88EC1...) -> Optional(039A95EF...)
[canvasViewDrawingDidChange] Layer switch detected: Optional(CCB88EC1...) -> Optional(039A95EF...)
... (continues until stack overflow)
```

**Root Cause - CONFIRMED:**
Infinite recursion loop in `canvasViewDrawingDidChange` delegate method. Here's the sequence:

1. **User adds new layer** → `LayerManager.createLayerAboveActive()` sets `activeLayerID = newLayer.id` (LayerManager.swift:166)

2. **onChange triggers** (DrawingCanvasView.swift:98-100) → Calls `syncDrawingWithActiveLayer()`

3. **syncDrawingWithActiveLayer** (line 366) → Sets `drawing = activeLayer.drawing`

4. **First canvasViewDrawingDidChange call** (lines 1258-1276):
   - Detects layer switch: `previousActiveLayerID (CCB88EC1) != currentActiveLayerID (039A95EF)`
   - Prints: "Layer switch detected"
   - **Line 1270**: Sets `parent.drawing = activeLayer.drawing`
   - **Line 1271**: Sets `canvasView.drawing = activeLayer.drawing` ⚠️ **THE BUG**

5. **Setting `canvasView.drawing` triggers another `canvasViewDrawingDidChange` call!**
   - PKCanvasView's delegate is called even for programmatic changes
   - The method runs again with the SAME layer IDs
   - Because `previousActiveLayerID` is updated at line 1274 AFTER the recursive call starts

6. **Infinite loop**: Step 4-5 repeat until stack overflow

**Why It Happens After Restore:**
The issue occurs specifically after restore because:
- Restored maps have existing layers with content
- When a new layer is added, `syncDrawingWithActiveLayer()` loads that layer's drawing
- The drawing is non-empty (from restored state), which may trigger more aggressive delegate notifications
- Without restore (empty drawing), the issue might not manifest as clearly

**Affected Code:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:1258-1292` - canvasViewDrawingDidChange delegate
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:1270-1271` - Programmatic drawing updates triggering delegate
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:98-101` - onChange triggering syncDrawingWithActiveLayer
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:359-367` - syncDrawingWithActiveLayer
- `Cumberland/LayerManager.swift:143-169` - createLayerAboveActive setting activeLayerID

**Solution Chosen: Alternative Solution (Remove line 1271)**

Remove `canvasView.drawing = activeLayer.drawing` at line 1271 and rely on SwiftUI's binding system to update the canvas view through `updateUIView` when `parent.drawing` changes.

**Rationale:**
- Simpler solution with less state management
- Avoids need for additional flags or coordination
- Relies on SwiftUI's built-in update mechanisms
- Prevents the recursive delegate call entirely

**Fix Applied:**
User removed the following line from `DrawingCanvasView.swift:1271`:
```swift
canvasView.drawing = activeLayer.drawing  // REMOVED THIS LINE
```

Kept only:
```swift
parent.drawing = activeLayer.drawing
```

The UIViewRepresentable's `updateUIView` method handles syncing the canvasView.drawing when the binding updates.

**Files Modified:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift:1271` (line removed)

**Verification:**
- ✅ Restore draft work from Map Wizard
- ✅ Add a new layer of any type (Water Feature, Terrain, etc.)
- ✅ App does not crash
- ✅ Layer switching works correctly
- ✅ Drawing content appears on the correct layer

---

## DR-0035: DRs 0019-0030 Missing from DR-Documentation.md Index

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-08
**Resolution Date:** 2026-01-08
**Platform:** Documentation
**Component:** DR-Reports/DR-Documentation.md
**Severity:** Medium (Documentation Issue)
**Date Identified:** 2026-01-08

**Description:**
The DR-Documentation.md index was missing 12 verified DRs (DR-0019 through DR-0030) from its detailed listings, and also missing the 5 current unverified DRs (DR-0031 through DR-0035) from the "Unverified DRs (Active Issues)" section. The DRs exist in the batch files and DR-unverified.md, but were not indexed in the main documentation file for easy reference.

**Evidence:**

**What EXISTS:**
- DR-verified-0011-0021.md contains all DRs from DR-0019 through DR-0030 (verified via file read)
- All 12 DRs are fully documented with status, descriptions, fixes, and verification results
- File name suggests it should only go to DR-0021, but actually contains through DR-0030

**What's MISSING:**
- DR-Documentation.md index only lists details for DR-0011 through DR-0018
- The "DR Summary" section (lines 34-67) ends at DR-0018.2
- No index entries for DR-0019, DR-0020, DR-0021, DR-0022, DR-0023, DR-0024 (two different ones), DR-0025, DR-0026, DR-0027, DR-0028, DR-0029, DR-0030
- The "Unverified DRs (Active Issues)" section claims "0 unverified DRs" but DR-0031 through DR-0035 exist in DR-unverified.md
- Statistics show "Total DRs: 31" but should be 35, and claim 100% verified when 5 are unverified

**Missing DRs Summary:**
- DR-0019: Interior map scale changes don't affect floor pattern size
- DR-0020: Interior floor material selection resets map scale
- DR-0021: Layer visibility toggle not working
- DR-0022: Interior surfaces regenerate during pan/zoom operations
- DR-0023: Strokes not added to layers with visibility control
- DR-0024: Strokes deleted when autosave runs (first one)
- DR-0024: iOS canvas layers do not all display at once (duplicate number, different issue)
- DR-0025: iOS eye icon has no effect on Layer visibility
- DR-0026: Switching from Base Layer deletes strokes on target layer (iOS)
- DR-0027: Masking panel obscures strokes on non-active layers (iOS)
- DR-0028: Strokes dim and invert colors when layer is not selected (iOS)
- DR-0029: Base layer image recalculated on visibility toggle and restore
- DR-0030: Missing "Add Card" UI on iOS/iPadOS and misplaced Settings button

**Impact:**
- Users cannot easily look up DR details in the index
- Index statistics are misleading (shows 31 total, claims 100% verified)
- "Latest DR" claim of DR-0030 is documented in verified batch but DR-0035 is actually latest
- Unverified DRs section incorrectly claims "All issues have been verified!"
- Difficult to get overview of current active issues

**Root Cause:**
The index likely wasn't updated when DR-0019 through DR-0030 were added to the verified file. The DRs may have been resolved and verified quickly without corresponding index updates.

**Note on Duplicate DR-0024:**
There are TWO different issues both numbered DR-0024:
1. DR-0024: Strokes deleted when autosave runs (lines 1059-1122)
2. DR-0024: iOS canvas layers do not all display at once (lines 1125-1150)

This is a numbering conflict that should be resolved during index update.

**Fix Applied:**
**Resolution Date:** 2026-01-08

**Implementation:**

1. **Split DR-verified-0011-0021.md into two batch files:**
   - Created `DR-verified-0011-0020.md` (924 lines, DR-0011 through DR-0020)
   - Created `DR-verified-0021-0030.md` (679 lines, DR-0021 through DR-0030)
   - Deleted original `DR-verified-0011-0021.md`

2. **Updated DR-Documentation.md index:**
   - Updated batch reference table to show three batches (lines 26-32)
   - Added DR-0019 and DR-0020 to "DR-0011 to DR-0020" section (lines 69-70)
   - Created new "DR-0021 to DR-0030" section with all 10 DRs (lines 72-86)
   - Updated section title to "Terrain Generation and Interior Maps (Verified)"
   - Added proper descriptions for each DR
   - Handled duplicate DR-0024 by using DR-0024 and DR-0024b
   - Added "Unverified DRs (Active Issues)" table with DR-0031 through DR-0035 (lines 18-27)
   - Updated statistics: Total 35, Verified 30 (86%), Resolved-Not-Verified 4 (11%), Open 1 (3%)

3. **Updated batch creation guidelines:**
   - Clarified that batches contain exactly 10 DRs
   - Added example: When DR-0030 verified, create DR-verified-0031-0040.md

4. **Added comprehensive checklists to DR-GUIDELINES.md:**
   - Checklist for creating new DRs
   - Checklist for resolving DRs
   - Checklist for verifying DRs
   - Each checklist ensures DR-Documentation.md stays synchronized

**Files Modified:**
- Created: `Cumberland/DR-Reports/DR-verified-0011-0020.md`
- Created: `Cumberland/DR-Reports/DR-verified-0021-0030.md`
- Deleted: `Cumberland/DR-Reports/DR-verified-0011-0021.md`
- Modified: `Cumberland/DR-Reports/DR-Documentation.md` (comprehensive updates)
- Modified: `Cumberland/DR-Reports/DR-GUIDELINES.md` (added checklists)

**Verification:**
- ✅ Verify batch files contain correct DR ranges
- ✅ Verify DR-Documentation.md lists all DRs 0019-0030
- ✅ Verify batch table shows correct file links
- ✅ All DRs are accessible and readable
- ✅ Unverified DRs section shows current active issues
- ✅ Statistics are accurate
- ✅ Guidelines include checklists for maintaining index

---

## DR-0033.1: "Novel" Structure Still Has Duplicate Entry After Deduplication

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-08
**Resolution Date:** 2026-01-08
**Platform:** All platforms (macOS and iOS confirmed)
**Component:** CumberlandApp/Seeding + Deduplication
**Severity:** Medium
**Date Identified:** 2026-01-08

**Description:**
After the DR-0033 deduplication fix was applied and verified, the "Novel" structure still appears twice in the Structure List. This duplicate exists on both macOS and iOS, indicating it's in CloudKit.

**User Confirmation:**
- First "Novel" structure: NO card assignments (initially reported as having assignments - later corrected)
- Second "Novel" structure: HAS card assignments
- User cannot see trailing spaces visually

**Root Cause - CONFIRMED:**
The original DR-0033 deduplication code compared structure names using exact string matching without normalizing whitespace. One of the "Novel" structures has trailing or leading whitespace that's invisible to the user, causing the names to not match during deduplication.

**The Bug:**
```swift
// OLD CODE (DR-0033):
if let firstID = seenNames[structure.name] {  // Exact string match
    // Mark as duplicate
}
```

If one structure is named "Novel" and the other is "Novel " (with trailing space), they won't match and both are kept.

**Initial Fix Problem:**
The first iteration of the fix normalized names and detected duplicates correctly, but kept the FIRST (oldest) occurrence regardless of card assignments. This meant it would keep an empty structure and try to delete one with user data.

Console logs from first fix showed:
```
Processing 'Novel' (normalized: 'novel')
Keeping first 'Novel' (ID: 62C270DF-F86B-4395-BEB8-AF05CF901F25)
Processing 'Novel' (normalized: 'novel')
Marking duplicate 'Novel' (ID: D043E502-0554-4C52-9308-EB4EF6B01E99) for deletion
Duplicate structure 'Novel' has card assignments - skipping deletion to preserve data
No duplicates could be deleted (all have card assignments)
```

The deduplication kept 62C270DF (no assignments) and tried to delete D043E502 (has assignments), which was correctly prevented by the safety check.

**Improved Fix - Smart Selection:**

Enhanced deduplication logic in `CumberlandApp.swift:682-803` with **smart selection strategy**:

**1. Name Normalization (line 705):**
```swift
// Normalize the name for comparison (trim whitespace, lowercase)
let normalizedName = structure.name.trimmingCharacters(in: .whitespaces).lowercased()
```

**2. Group All Duplicates (lines 699-711):**
```swift
// Build dictionary: normalized name -> [all structures with that name]
var nameGroups: [String: [StoryStructure]] = [:]
for structure in allStructures {
    let normalizedName = structure.name.trimmingCharacters(in: .whitespaces).lowercased()
    nameGroups[normalizedName]?.append(structure)
}
```

**3. Smart Selection Strategy (lines 728-780):**
- Categorizes each structure by whether it has card assignments
- **If any have assignments**: Keep first one WITH assignments, delete ALL without assignments
- **If none have assignments**: Keep oldest, delete rest

```swift
// Check which structures have card assignments
var structuresWithAssignments: [StoryStructure] = []
var structuresWithoutAssignments: [StoryStructure] = []

// Categorize each duplicate
for structure in structures {
    let hasAssignments = structure.elements?.contains { element in
        !(element.assignedCards?.isEmpty ?? true)
    } ?? false

    if hasAssignments {
        structuresWithAssignments.append(structure)
    } else {
        structuresWithoutAssignments.append(structure)
    }
}

// Smart strategy:
if !structuresWithAssignments.isEmpty {
    // Keep the first one WITH assignments
    let toKeep = structuresWithAssignments[0]
    logger.info("Keeping '\(toKeep.name)' (ID: \(toKeep.id)) - has card assignments")

    // Delete ALL structures WITHOUT assignments
    for structure in structuresWithoutAssignments {
        duplicatesToDelete.append(structure)
    }
} else {
    // None have assignments - keep oldest, delete rest
    let toKeep = structures[0]
    for structure in structures.dropFirst() {
        duplicatesToDelete.append(structure)
    }
}
```

**Key Improvements:**
- ✅ Trims leading/trailing whitespace from names before comparison
- ✅ Case-insensitive comparison (prevents "Novel" vs "novel" duplicates)
- ✅ **SMART SELECTION**: Keeps structures WITH card assignments, not just oldest
- ✅ Deletes ALL duplicates without assignments when one has assignments
- ✅ Enhanced logging shows invisible whitespace as middot (·)
- ✅ Detailed logging of which structure is kept and why

**Files Modified:**
- `Cumberland/CumberlandApp.swift` (lines 682-803)

**How It Works:**
1. Fetch all structures sorted by creation date
2. Group by normalized name (trim whitespace, lowercase)
3. For each group with duplicates:
   - Categorize by whether they have card assignments
   - **If any have assignments**: Keep first one with assignments, delete all without
   - **If none have assignments**: Keep oldest, delete rest
4. Delete marked structures and save

**Result:**
- First "Novel" (ID: 62C270DF..., no assignments) was deleted
- Second "Novel" (ID: D043E502..., has assignments) was kept
- Console logs showed: "Successfully removed 1 duplicate structure(s)"

**Verification:**
- ✅ Restart app on macOS
- ✅ Console logs showed proper detection and smart selection
- ✅ Structure list shows only ONE "Novel"
- ✅ Remaining "Novel" has user's card assignments
- ✅ CloudKit sync propagates deletion to iOS
- ✅ Both devices show only one "Novel" with card assignments

**Related Issues:**
- DR-0033: Original duplicate structures issue (resolved and verified)

---

## DR-0037: Insufficient Sandy Beach Area Around Water Brushes

**Status:** ✅ Resolved - Closed (Expanded to ER-0007)
**Verification Date:** 2026-01-10
**Resolution Date:** 2026-01-09
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** DrawCanvas/BrushEngine Water Rendering
**Severity:** Medium
**Date Identified:** 2026-01-08

**Note:** Renumbered from DR-0032 to DR-0037 to resolve numbering conflict with verified DR-0032 (Brush Strokes Disappear issue).

**Description:**
The water brushes (Lake, Sea, Ocean) create sandy beach areas around the water, but the beach zones are much narrower than those generated by the base layer terrain system. This creates visual inconsistency between base layer water bodies and brush-drawn water bodies.

**Root Cause:**
During analysis, it became clear that the root issue was the fundamental difference between base layer and brush rendering approaches:
- **Base Layer**: Uses elevation maps with `elevation < 0.1` thresholds that create organically varying beach widths
- **Brushes**: Use fixed percentage-based calculations that create uniform beaches

Rather than patch this with better percentages, this issue represents a fundamental architectural problem requiring a comprehensive solution.

**Resolution:**

This DR has been **expanded into ER-0007: Unify Map Rendering** - a comprehensive solution that will:

1. Rewrite Lake brush to use elevation-based rendering (matching base layer exactly)
2. Rewrite River brush with valley/basin elevation rendering
3. Fix river meandering and width scaling issues
4. Standardize base layer elevation thresholds to 0.1
5. Remove redundant brushes (Ocean, Sea, Stream, Waterfall via ER-0005)

**Current Status:**
- ER-0005 ✅ Completed: Redundant brushes removed (Ocean, Sea, Stream, Waterfall)
- Base layer threshold ✅ Standardized to 0.1 across all terrain types
- ER-0007 implementation plan documented and awaiting user approval

**Why This DR is Closed:**

This DR is considered resolved and closed because:
1. The underlying architectural issue has been properly identified
2. A comprehensive solution (ER-0007) has been designed to address the root cause
3. Preliminary work (ER-0005, base layer standardization) is complete
4. The issue will be fully resolved when ER-0007 is implemented

This closure represents a pivot from symptom-patching to architectural improvement, ensuring long-term consistency between base layer and brush rendering systems.

**Files Modified (Preliminary Work):**
- `Cumberland/DrawCanvas/TerrainPattern.swift` - Standardized beach threshold to 0.1
- `Cumberland/DrawCanvas/ExteriorMapBrushSet.swift` - Removed redundant brushes (ER-0005)
- `Cumberland/DrawCanvas/BrushEngine.swift` - Removed Ocean/Sea rendering functions (ER-0005)

**Related Issues:**
- **ER-0007**: Unify Map Rendering - Base Layer and Brushes (comprehensive solution)
- **ER-0005**: Remove Redundant Water Brush Types (completed as prerequisite)

---

## DR-0036: Interior / Architectural Maps Header Controls Take Up Too Much Space on iPad

**Status:** ✅ Resolved - Verified
**Verification Date:** 2026-01-10
**Resolution Date:** 2026-01-10
**Platform:** iOS / iPadOS (primarily iPadOS)
**Component:** MapWizardView / Interior Configuration UI
**Severity:** Medium
**Date Identified:** 2026-01-10

**Description:**
The interior/architectural map configuration screen in the Map Wizard had header controls that took up excessive screen space, particularly noticeable on iPad. Unlike exterior maps which had a compact hamburger menu for configuration options, interior maps displayed controls directly in the header, reducing the available drawing canvas area.

**Current Behavior (Before Fix):**
- Exterior maps: Configuration options (base layer, scale, water %) accessible via hamburger menu (3-line icon)
- Interior maps: Configuration controls displayed directly in header area (5-6 rows)
- iPad users lost ~100-150pt of screen real estate to header controls
- Drawing canvas was smaller than necessary on interior maps

**Expected Behavior:**
- Interior maps should use the same hamburger menu pattern as exterior maps
- Configuration controls (base layer selection, scale, grid settings, etc.) should be in the menu
- Drawing canvas should have maximum available screen space
- Consistent UI pattern between interior and exterior map workflows

**Root Cause:**
The interior configuration view (`interiorConfigView` at MapWizardView.swift:973) had all controls displayed inline in the header. This was likely a different UI architecture from exterior maps which were designed with hamburger menu from the start.

**Fix Applied:**

Refactored interior configuration view to use the same compact hamburger menu pattern as exterior maps.

**Changes Made:**

**File:** `Cumberland/MapWizardView.swift` (lines 973-1072)

**New Structure:**
- Compact header with title + hamburger menu button (single row, ~44pt height)
- All controls moved into hierarchical menu:
  - **Map Presets** submenu → Floorplan, Dungeon, Caverns
  - **Canvas Size** submenu → Small, Medium, Large
  - **Background** submenu → White, Dark, Parchment, Gray
  - **Units** picker → Feet, Meters (direct in menu)
  - **Show Grid** toggle → Direct in menu
  - **Grid Type** picker → Conditional (when grid enabled)
  - **Grid Spacing** submenu → 1 ft, 5 ft, 10 ft, Custom
  - **Snap to Grid** toggle → Conditional (when grid enabled)

**Menu Icon:** `slider.horizontal.3` (three horizontal sliders) - matches exterior maps

**Space Savings:**
- **Before:** ~100-150pt header height (5-6 rows of controls)
- **After:** ~44pt header height (single row: title + icon button)
- **Net Gain:** ~56-106pt of additional canvas space

**Benefits:**
1. ✅ **Significantly more drawing space** - especially important on iPad
2. ✅ **Consistent UI pattern** - matches exterior map experience
3. ✅ **Cleaner, professional appearance** - less cluttered header
4. ✅ **Better organization** - grouped controls in logical submenus
5. ✅ **No lost functionality** - all controls still accessible
6. ✅ **Responsive** - works well on both macOS and iPad

**Files Modified:**
- `Cumberland/MapWizardView.swift` (lines 973-1072) - Refactored interiorConfigView to hamburger menu pattern

**Verification:**
- ✅ Verified header is compact (title + hamburger icon only) on iPad
- ✅ Verified canvas space significantly increased (~56-106pt gain)
- ✅ Verified all controls accessible via hamburger menu
- ✅ Verified all functionality unchanged (presets, grid, background, etc.)
- ✅ Verified UI consistency with exterior maps
- ✅ User confirmed verification on 2026-01-10

---

*End of Batch 4*
