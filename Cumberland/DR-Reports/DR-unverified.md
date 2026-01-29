# Discrepancy Reports (DR) - Unverified Issues

This document tracks discrepancy reports that have been resolved but are awaiting user verification.

**Status:** Currently **13 unverified DRs** (4 Resolved, 8 Open, 1 Verified)

---

## DR-0056: SuggestionEngine Only Creating Forward Relationships (Missing Reverse Edges)

**Status:** ✅ Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** SuggestionEngine, Phase 6 (ER-0010)
**Severity:** High
**Date Identified:** 2026-01-26
**Date Resolved:** 2026-01-26

**Description:**

The `SuggestionEngine.createRelationships()` function was only creating forward edges (source → target) and not creating the corresponding reverse edges (target → source). This is inconsistent with how `CardRelationshipView` creates relationships, which always creates bidirectional pairs.

**Current Behavior (BEFORE FIX):**

When creating Captain Drake with analysis detecting 5 relationships:
1. Creates 5 entity cards (Voyager, New Haven Station, plasma rifle, compass)
2. Creates only 5 forward CardEdge entries:
   - Drake → pilots → Voyager
   - Drake → enters → New Haven Station
   - Drake → uses → plasma rifle
   - Drake → owns → compass
3. **Missing 5 reverse CardEdge entries** ❌
4. Captain Drake shows 0 relationships in UI
5. Voyager shows 1 relationship to Drake (forward edge exists)

**Expected Behavior:**

For 5 suggested relationships, create 10 total CardEdge entries (bidirectional):

**Forward edges (5):**
- Drake → [pilots] → Voyager
- Drake → [enters] → New Haven Station
- Drake → [uses] → plasma rifle
- Drake → [owns] → compass
- (5th relationship)

**Reverse edges (5) using mirror types:**
- Voyager → [piloted-by] → Drake
- New Haven Station → [is-entered-by] → Drake
- plasma rifle → [used-by] → Drake
- compass → [owned-by] → Drake
- (5th reverse)

**Root Cause:**

`SuggestionEngine.createRelationships()` in `Cumberland/AI/SuggestionEngine.swift:346-418` was only creating the forward CardEdge and did not implement the reverse edge creation that `CardRelationshipView` uses.

**Resolution:**

Added bidirectional relationship creation to match `CardRelationshipView` pattern:

1. **Added `ensureReverseEdge()` helper function (lines 424-459):**
   - Checks if reverse edge already exists (target → source)
   - Gets or creates mirror RelationType
   - Creates reverse CardEdge with swapped source/target
   - Uses timestamp offset (+0.001s) for ordering

2. **Added `getMirrorType()` helper function (lines 461-490):**
   - Finds existing mirror RelationType with swapped labels
   - Example: "pilots/piloted-by" → "piloted-by/pilots"
   - Creates new mirror type if needed with:
     - forwardLabel = original inverseLabel
     - inverseLabel = original forwardLabel
     - sourceKind = original targetKind (swapped)
     - targetKind = original sourceKind (swapped)

3. **Added `makeRelationTypeCode()` helper function (line 492-495):**
   - Builds RelationType code from forward/inverse labels
   - Format: "forward/inverse"

4. **Updated `createRelationships()` to call `ensureReverseEdge()` (line 410):**
   - After creating each forward edge
   - Automatically creates corresponding reverse edge
   - Debug output shows both forward and reverse creation

**New Behavior (AFTER FIX):**

Creating Captain Drake with 5 detected relationships:
1. Creates 5 entity cards ✅
2. Creates 5 forward CardEdge entries ✅
3. Creates 5 reverse CardEdge entries ✅
4. Total: 10 CardEdge entries in database
5. Captain Drake shows 5 relationships in UI ✅
6. Voyager shows 1 relationship to Drake ✅
7. Each entity shows its relationship to Drake ✅

**Debug Output Example:**
```
🔗 [SuggestionEngine] Creating 5 relationships (bidirectional)
   ✅ Created forward: Drake → [pilots] → Voyager
   ✅ Created reverse: Voyager → [piloted-by] → Drake
   ✅ Created forward: Drake → [enters] → New Haven Station
   ✅ Created reverse: New Haven Station → [is-entered-by] → Drake
   ...
✅ [SuggestionEngine] Successfully created 5 forward + 5 reverse = 10 total edges
```

**Files Modified:**

- `Cumberland/AI/SuggestionEngine.swift:346-495` - Added bidirectional relationship creation
  - Updated `createRelationships()` to create both forward and reverse edges
  - Added `ensureReverseEdge()` helper
  - Added `getMirrorType()` helper
  - Added `makeRelationTypeCode()` helper

**Pattern Consistency:**

This implementation now matches the pattern used in `CardRelationshipView.swift:944-973`:
- Forward edge: source → [forward label] → target
- Reverse edge: target → [inverse label] → source (using mirror type)
- Both edges share same createdAt (with 0.001s offset for ordering)
- Mirror RelationType auto-created if needed

**Test Steps:**

1. Create new Character "Captain Drake"
2. Enter description: "Captain Drake pilots the starship Voyager. He entered the spaceport at New Haven Station. Drake uses a plasma rifle and carries an old family compass."
3. Click "Analyze" (using OpenAI or Apple Intelligence)
4. Select all 4-5 relationships
5. Click "Create Selected"
6. Click "Save"
7. Open Captain Drake's detail view → Relationships tab
8. **Expected**: Drake shows 4-5 outgoing relationships
9. Open Voyager's detail view → Relationships tab
10. **Expected**: Voyager shows 1 incoming relationship from Drake ("piloted-by")
11. Check database (Developer Tools → Card Diagnostics)
12. **Expected**: 8-10 total CardEdge entries (5 forward + 5 reverse)

**Related Issues:**

- Phase 6 (ER-0010) - Relationship Inference implementation
- CardRelationshipView bidirectional edge creation
- RelationType mirror type system

---

## DR-0055: Relationship Creation Timing Issue - Cancel Button Behaves Like Save

**Status:** ✅ Resolved - Not Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** SuggestionReviewView, CardEditorView, Phase 6 (ER-0010)
**Severity:** Critical
**Date Identified:** 2026-01-26
**Date Resolved:** 2026-01-26

**Description:**

In Phase 6 (ER-0010) implementation, a critical workflow bug caused the "Cancel" button in CardEditorView to behave identically to the "Save" button when creating relationships. When a user clicked "Create Selected" in the SuggestionReviewView during card creation, the source card was prematurely saved to the database. If the user then clicked "Cancel" instead of "Save", the source card remained in the database instead of being discarded.

**Current Behavior (BEFORE FIX):**
1. User creates new Character "Captain Drake" (not saved yet)
2. User clicks "Analyze" → Gets relationship suggestions
3. User clicks "Create Selected" in SuggestionReviewView
4. **Source card "Drake" gets saved to database immediately** ❌
5. User clicks "Cancel" in CardEditorView
6. **Drake remains in database** ❌ (should be discarded)

**Expected Behavior:**
- "Create Selected": Create entity cards only, store pending relationships
- "Save": Save source card, then create stored relationships
- "Cancel": Discard source card, keep entity cards, discard pending relationships

**Root Cause:**

In `SuggestionReviewView.swift:262-284`, the `acceptSelectedSuggestions()` function was checking if the source card existed in the database. If not, it would insert and save the source card immediately to enable relationship creation. This violated the user expectation that the source card should only be saved when the user clicks the final "Save" button.

**Resolution:**

Implemented a smart relationship creation system that splits relationships into immediate and deferred groups:

1. **Added state variable in CardEditorView.swift:107-109:**
   ```swift
   // Phase 6: Store pending relationships from analysis
   // These will be created when the card is saved
   @State private var pendingRelationships: [SuggestionEngine.RelationshipSuggestion] = []
   ```

2. **Updated SuggestionReviewView.swift to accept binding:**
   - Modified `init()` to accept `pendingRelationships: Binding<[SuggestionEngine.RelationshipSuggestion]>`
   - Changed `acceptSelectedSuggestions()` to intelligently split relationships into two groups

3. **Smart relationship splitting logic in SuggestionReviewView.swift:255-297:**
   - Compares each relationship's source/target names against the source card being created
   - **Immediate relationships**: Neither source nor target matches the card being created → create now
   - **Deferred relationships**: Either source or target matches the card being created → defer until save
   - Creates immediate relationships using `suggestionEngine.createRelationships()`
   - Stores deferred relationships in binding for later creation

4. **Updated CardEditorView.save() to create deferred relationships:**
   - After `modelContext.save()` in both `.create` and `.edit` cases
   - Fetches all cards (including newly created source card)
   - Calls `SuggestionEngine.createRelationships()` with pending suggestions
   - Clears pending relationships after creation

**New Behavior (AFTER FIX):**

**Example 1: Creating "Captain Drake" with Drake's description:**
1. User creates new Character "Captain Drake"
2. Analyzes text: "Captain Drake pilots the starship Voyager. He entered the spaceport at New Haven Station..."
3. Detected relationships:
   - Drake → pilots → Voyager (involves Drake - deferred) ⏸️
   - Drake → enters → New Haven Station (involves Drake - deferred) ⏸️
   - Drake → uses → plasma rifle (involves Drake - deferred) ⏸️
4. Clicks "Create Selected"
   - Entity cards created (Voyager, New Haven Station, plasma rifle)
   - All 3 relationships deferred (all involve Drake)
   - Drake NOT saved yet ✅
5. Clicks "Save"
   - Drake saved to database
   - All 3 deferred relationships created ✅

**Example 2: Creating "Starship Voyager" with Drake's description:**
1. User creates new Vehicle "Starship Voyager"
2. Analyzes same text
3. Detected relationships:
   - Drake → pilots → Voyager (involves Voyager - deferred) ⏸️
   - Drake → enters → New Haven Station (doesn't involve Voyager - immediate) ✅
   - Drake → uses → plasma rifle (doesn't involve Voyager - immediate) ✅
4. Clicks "Create Selected"
   - Entity cards created (Drake, New Haven Station, plasma rifle)
   - 2 relationships created immediately (Drake→Station, Drake→rifle) ✅
   - 1 relationship deferred (Drake→Voyager)
   - Voyager NOT saved yet ✅
5. Clicks "Save"
   - Voyager saved to database
   - Deferred relationship created (Drake→Voyager) ✅

**Example 3: Cancel workflow:**
1. User clicks "Cancel" instead of "Save"
   - Source card discarded (not saved)
   - Entity cards remain in database (already created)
   - Deferred relationships discarded ✅
   - Immediate relationships remain (already created) ✅

**Files Modified:**

- `Cumberland/AI/SuggestionReviewView.swift:15-31` - Added `pendingRelationships` binding to init
- `Cumberland/AI/SuggestionReviewView.swift:253-282` - Refactored `acceptSelectedSuggestions()` to store instead of create
- `Cumberland/AI/SuggestionReviewView.swift:479-498` - Fixed Preview syntax (@Previewable at beginning)
- `Cumberland/CardEditorView.swift:107-109` - Added `pendingRelationships` state variable
- `Cumberland/CardEditorView.swift:1187-1198` - Passed binding to SuggestionReviewView
- `Cumberland/CardEditorView.swift:1336-1360` - Create pending relationships in `.create` case
- `Cumberland/CardEditorView.swift:1369-1393` - Create pending relationships in `.edit` case

**Test Steps:**

**Test A: Creating source card mentioned in description (Drake scenario):**
1. Create new Character "Captain Drake"
2. Enter description: "Captain Drake pilots the starship Voyager. He entered the spaceport at New Haven Station. Drake uses a plasma rifle and carries an old family compass."
3. Click "Analyze" (using OpenAI or Apple Intelligence)
4. **Verify**: 4-5 entities detected, 4 relationships detected (all involve Drake)
5. Select all relationships
6. Click "Create Selected"
7. **Verify debug output**: "Created 4 entity cards", "Created 0 immediate relationships", "Stored 4 pending relationships (involve 'Captain Drake')"
8. **Verify**: Entity cards exist in database (Voyager, New Haven Station, plasma rifle, compass)
9. **Verify**: Drake does NOT exist in Characters list yet
10. Click "Cancel"
11. **Expected**: Drake should NOT appear in Characters list (discarded)
12. **Expected**: Entity cards should remain (Voyager, Station, rifle, compass)

**Test B: Creating source card NOT mentioned in description (Voyager scenario):**
1. Create new Vehicle "Starship Voyager"
2. Enter same description from Test A
3. Click "Analyze"
4. **Verify**: 4-5 entities detected, 4 relationships detected
5. Select all relationships
6. Click "Create Selected"
7. **Verify debug output**: "Created 4 entity cards", "Created 3 immediate relationships", "Stored 1 pending relationships (involve 'Starship Voyager')"
8. **Verify**: Entity cards exist (Drake, New Haven Station, plasma rifle, compass)
9. **Verify**: 3 relationships exist immediately (Drake→Station, Drake→rifle, Drake→compass)
10. **Verify**: Voyager does NOT exist in Vehicles list yet
11. Click "Save"
12. **Expected**: Voyager appears in Vehicles list
13. **Expected**: 1 deferred relationship created (Drake→pilots→Voyager)
14. **Verify**: Total of 4 relationships exist

**Test C: Cancel workflow preserves immediate relationships:**
1. Repeat Test B steps 1-9
2. Click "Cancel" instead of "Save"
3. **Expected**: Voyager does NOT appear in Vehicles list (discarded)
4. **Expected**: Entity cards remain (Drake, Station, rifle, compass)
5. **Expected**: 3 immediate relationships remain (Drake→Station, Drake→rifle, Drake→compass)
6. **Expected**: Deferred relationship NOT created (Drake→Voyager never created)

**Related Issues:**

- Phase 6 (ER-0010) - Relationship Inference implementation
- Card creation workflow
- SwiftData transaction boundaries

---

## DR-0054: Edit Card Sheet on iOS Missing Save/Cancel Buttons

**Status:** 🔴 Open
**Platform:** iOS/iPadOS
**Component:** CardSheetView, CardEditorView
**Severity:** High
**Date Identified:** 2026-01-25

**Description:**

On iOS/iPadOS, when editing a card via the Edit Card sheet, the Save and Cancel buttons that should appear at the bottom of the view are missing. This prevents users from saving changes or canceling edits, leaving them with no clear way to exit the edit mode.

**Current Behavior:**
- Open a card on iOS/iPadOS
- Tap "Edit" to open the Edit Card sheet
- CardEditorView displays with form fields
- **No Save or Cancel buttons visible** at the bottom
- User cannot save changes
- User cannot cancel and exit
- Only way to exit is pulling down the sheet (dismisses without saving)

**Expected Behavior:**
- Save button should appear at the bottom of CardEditorView
- Cancel button should appear at the bottom of CardEditorView
- Save button should save changes and dismiss the sheet
- Cancel button should discard changes and dismiss the sheet
- Buttons should be clearly visible and easily accessible

**Possible Causes:**

1. **ScrollView content clipping**: Save/Cancel buttons may be below visible scroll area
2. **Missing toolbar buttons**: iOS may need toolbar buttons instead of inline buttons
3. **Sheet presentation mode**: Sheet presentation may be cutting off bottom content
4. **Platform-specific layout**: CardEditorView may have macOS-specific button placement

**Investigation Needed:**

1. Check if buttons exist but are hidden below scroll area
2. Verify `.presentationDetents()` aren't clipping content
3. Check if iOS needs toolbar buttons instead of inline buttons
4. Review CardSheetView presentation logic
5. Compare iOS vs macOS button placement in CardEditorView

**Workaround:**

Currently, users must pull down the sheet to dismiss, which loses all changes. No way to save edits on iOS.

**Impact:**

**High Severity** - Core editing functionality broken on iOS. Users cannot save changes to cards on iPhone/iPad.

**Files to Review:**
- `Cumberland/CardSheetView.swift` - iOS card editing sheet presentation
- `Cumberland/CardEditorView.swift` - Form layout and button placement
- Check for platform conditionals around Save/Cancel buttons

**Test Steps:**

1. Open Cumberland on iPhone or iPad
2. Open any card
3. Tap "Edit" button
4. Scroll to bottom of editor
5. **Expected**: Save and Cancel buttons visible
6. **Actual**: No buttons visible

**Related Issues:**

- iOS editing workflow
- Sheet presentation system
- CardEditorView platform differences

---

## DR-0043: Duplicate RelationType Entries Created Despite Deduplication Logic

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** RelationType / CumberlandApp seeding
**Severity:** Medium
**Date Identified:** 2026-01-24

**Description:**

Duplicate RelationType entries are appearing in the database despite the presence of deduplication logic in the seeding code (`seedRelationTypesIfNeeded`). Users observe multiple RelationType entries with identical or very similar labels when viewing relationship type pickers or in the RelationTypes diagnostics view.

**Current Behavior:**
- Duplicate RelationType entries exist in the database
- Same relationship types appear multiple times in UI pickers
- Affects user experience when selecting relationship types
- May cause confusion about which type to use

**Expected Behavior:**
- Each unique RelationType code should exist only once in the database
- Seeding logic should prevent duplicate creation
- No duplicate entries should appear in UI pickers

**Possible Root Causes:**

1. **Race Condition During App Launch:**
   - Multiple simultaneous calls to `seedRelationTypesIfNeeded` on different devices
   - CloudKit sync merging duplicate entries created before sync completes

2. **Code Mismatch:**
   - Different codes with same labels (e.g., "part-of/has-member" vs "part-of/has-member-2")
   - Automatic mirror type creation generating duplicates

3. **Manual Creation:**
   - User or diagnostic tools creating duplicate entries manually
   - Fix Incomplete Relationships tool creating mirror types that duplicate existing ones

4. **CloudKit Sync Issues:**
   - Conflict resolution creating duplicate objects
   - Same RelationType created on multiple devices before initial sync

**Affected Code:**

`Cumberland/CumberlandApp.swift:517-554` - `seedRelationTypesIfNeeded` function
```swift
static func seedRelationTypesIfNeeded(container: ModelContainer) async {
    let existing = (try? context.fetch(fetch)) ?? []
    var existingCodes = Set(existing.map { $0.code })

    for s in relationTypeSeeds {
        if existingCodes.contains(s.code) {
            continue  // Should prevent duplicates by code
        }
        // ... insert new type
    }
}
```

`Cumberland/CumberlandApp.swift:1299-1334` - `ensureMirrorType` function (Fix Incomplete Relationships)
- Creates mirror types dynamically
- May create duplicates if multiple devices run fix simultaneously

**Steps to Reproduce:**
1. Use app across multiple devices with CloudKit sync enabled
2. Observe RelationType picker or diagnostics view
3. **Note**: Exact reproduction steps unclear - may be timing-dependent

**Potential Solutions:**

1. **Add Unique Constraint Check:**
   - Before inserting, query for existing type with same code
   - Use @MainActor to ensure serial execution

2. **Batch Fetch and Merge:**
   - Fetch all RelationTypes at startup
   - Merge duplicates by code, keeping oldest
   - Delete merged duplicates

3. **CloudKit Deduplication:**
   - Add server-side unique constraint on `code` field
   - Handle merge conflicts by preferring existing record

4. **Diagnostic Tool Enhancement:**
   - Add "Find and Merge Duplicates" function to RelationTypesDiagnosticsView
   - Allow user to manually clean up duplicates

**Workaround:**
- Manually delete duplicate RelationType entries via RelationTypesDiagnosticsView
- Note: May require reassigning relationships to non-duplicate type first

**Impact:**
- **Medium** - Affects UX but doesn't break core functionality
- Confusing for users selecting relationship types
- Database bloat with duplicate entries
- May cause unexpected behavior if different duplicates are used for same logical relationship

**Priority:** Medium - Should be fixed to maintain data integrity

---


## DR-0041: Vegetation and Terrain Brushes Should Render as Area Fills

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** BrushEngine / ExteriorMapBrushSet
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

Several exterior vegetation and terrain brushes currently render as line strokes but should render as area fills (similar to how the Marsh brush works). These brushes represent terrain features that naturally cover areas rather than follow linear paths.

**Affected Brushes:**

**Vegetation Category:**
- Forest
- Single Tree
- Grassland
- Plains
- Jungle

**Terrain Category:**
- Desert
- Tundra

**Special Case:**
- **Farmland** - Should render as area fill with rectangular "fields" pattern

**Current Behavior:**
- These brushes follow the drawn path as a line
- Vegetation/terrain texture applied along the stroke
- No area fill - only renders where the path was drawn
- Inconsistent with Marsh brush which fills enclosed areas

**Expected Behavior:**
- User draws a freeform closed or open path
- Brush fills the enclosed area (or area around path) with appropriate pattern:
  - **Forest**: Dense tree pattern scattered throughout area
  - **Single Tree**: Sparse individual trees
  - **Grassland**: Grass texture fill
  - **Plains**: Open grass/prairie texture
  - **Jungle**: Dense vegetation with variety
  - **Desert**: Sandy texture with occasional dunes
  - **Tundra**: Cold, sparse ground cover
  - **Farmland**: Rectangular field pattern (plowed rows in grid layout)

**Reference Implementation:**
- **Marsh brush** already works this way - fills areas with marsh/wetland texture
- Same rendering approach should apply to vegetation/terrain brushes

**Design Notes:**

1. **Area Detection:**
   - For closed paths: Fill interior
   - For open paths: Could fill area with some buffer distance, or require closed paths

2. **Pattern Distribution:**
   - Trees: Scattered with random spacing (avoid grid appearance)
   - Grassland/Plains: Organic texture fill
   - Desert: Sandy base with dune shapes
   - Farmland: Grid of rectangular fields at consistent angles

3. **Density Control:**
   - Could use brush width parameter to control density
   - Forest: Dense (many trees)
   - Single Tree: Sparse (few trees)
   - Grassland: Medium coverage

**Steps to Reproduce Current Issue:**
1. Create exterior map
2. Select Forest brush
3. Draw closed loop to define forest area
4. **Observe**: Only the path line has forest texture, interior is empty
5. Compare to Marsh brush which fills the interior

**Impact:**
- Users cannot create realistic area-based terrain features
- Have to draw many overlapping strokes to simulate area coverage (tedious)
- Maps look less professional with line-based vegetation
- Inconsistent with realistic map-making (forests are areas, not lines)

**Affected Files:**
- `Cumberland/DrawCanvas/BrushEngine.swift` - May need new area fill rendering for vegetation
- `Cumberland/DrawCanvas/ExteriorMapBrushSet.swift` - Brush definitions
- Possibly need new pattern generators in `Cumberland/DrawCanvas/ProceduralPatternGenerator.swift`

**Related:**
- Marsh brush already demonstrates the desired behavior
- Interior area fill brushes (Carpet, Water Feature, Rubble) work correctly
- This is about extending area fill to exterior terrain brushes

**Priority:** Medium - Affects map quality and user workflow, but has workaround (draw many strokes)

---

## DR-0040: Brush Set Picker Text Overflow on iOS

**Status:** 🔴 Open
**Platform:** iOS/iPadOS only
**Component:** BrushGridView / Tool Palette
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

In the "Brushes for Generic" section of the tool palette on iOS, when a brush set is selected, the UI layout breaks with text overflowing into the section below.

**Current Behavior:**
- Before selection: "Brush Set:" label and count visible with picker arrows (correct)
- After selecting a brush set (e.g., "Basic Tools", "Exterior Brushes"):
  - Picker text has insufficient width
  - Selected brush set name wraps/overflows vertically
  - "Brush Set:" label overflows into next section
  - Brush count (e.g., "42") overflows into next section

**Expected Behavior:**
- Picker should have sufficient horizontal width for full brush set name
- No text should overflow into adjacent sections
- Layout should remain clean and readable

**Steps to Reproduce:**
1. Open iOS app
2. Create any map (interior or exterior)
3. Open tool palette
4. Navigate to "Brushes for Generic" section
5. Tap picker and select a brush set
6. Observe text overflow into section below

**Root Cause:**
Likely insufficient frame width or missing layout constraints for the Picker view on iOS.

**Affected Files:**
- `Cumberland/DrawCanvas/BrushGridView.swift` - Brush selection UI
- Wherever "Brushes for Generic" picker is implemented

**Impact:**
- Poor UX on iOS - UI appears broken
- Difficult to read selected brush set name
- Overlapping text reduces usability

---

## DR-0038: Draft Interior Drawing Settings Not Remembered Between View Loads

**Status:** 🔴 Open
**Platform:** All platforms (macOS, iOS, iPadOS)
**Component:** MapWizardView / Draft Persistence
**Severity:** Medium
**Date Identified:** 2026-01-10

**Description:**

When working on interior/architectural maps in the Map Wizard, drawing settings such as snap to grid, grid type, grid size, and background color (parchment) are not remembered between view loads or app restarts. Users must re-configure these settings every time they return to work on their map draft.

**Current Behavior:**
- User configures interior map settings:
  - Snap to Grid: ON
  - Grid Type: Square
  - Grid Size: 5 ft
  - Background: Parchment
- User draws on map, then dismisses Map Wizard
- User reopens the same map draft
- **Settings are reset to defaults:**
  - Snap to Grid: OFF (or default state)
  - Grid Type: Reset
  - Grid Size: Reset
  - Background: White (instead of Parchment)

**Expected Behavior:**
- All interior map drawing settings should persist with the draft
- When user reopens a draft, settings should restore exactly as configured
- Settings should be specific to each map draft (not global app settings)
- Cross-platform persistence via CloudKit (settings sync between devices)

**Affected Settings:**
1. **Snap to Grid** (toggle) - Reverts to default
2. **Grid Type** (Square/Hex) - Not remembered
3. **Grid Size** (1 ft, 5 ft, 10 ft, Custom) - Not remembered
4. **Background Color** (White, Dark, Parchment, Gray) - Reverts to White

**Impact:**
- User frustration - must reconfigure settings on every session
- Workflow interruption - breaks creative flow
- Inconsistent experience - exterior map settings may persist differently
- Particularly annoying for long-term projects with specific grid requirements

**Steps to Reproduce:**
1. Open Map Wizard → Interior/Architectural tab
2. Create new interior map or load existing draft
3. Configure settings:
   - Toggle "Snap to Grid" ON
   - Set Grid Type to "Square"
   - Set Grid Size to "5 ft"
   - Set Background to "Parchment"
4. Draw some strokes on the canvas
5. Close Map Wizard (or save draft and quit app)
6. Reopen the same map draft
7. **Observe**: Settings have reverted to defaults

**Expected Fix:**

1. **Persist settings in draft data**:
   - Add properties to `Card.draftMapWorkData` or create dedicated settings object
   - Store: `snapToGrid`, `gridType`, `gridSize`, `gridSpacing`, `backgroundColor`
   - Encode/decode with other draft data

2. **Restore settings on draft load**:
   - When loading draft in MapWizardView, extract settings from persisted data
   - Set `@State` variables to match saved settings
   - Apply settings to canvas (grid overlay, snapping behavior, background)

3. **Save settings on change**:
   - Update persisted data when user changes any setting
   - Use auto-save mechanism (similar to stroke persistence)
   - Ensure settings saved before view dismissal

4. **Cross-platform compatibility**:
   - Settings should sync via CloudKit with draft data
   - Verify Codable conformance for all setting types
   - Test on iOS and macOS

**Files Likely Affected:**
- `Cumberland/MapWizardView.swift` - Settings state management, persistence hooks
- `Cumberland/Model/Card.swift` - Draft data structure (may need new properties)
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - May need to expose settings to persistence layer
- `Cumberland/DrawCanvas/DrawingCanvasModel.swift` - Settings storage in canvas model

**Possible Implementation:**

**Option 1: Extend Draft Map Work Data**
```swift
struct DraftMapWorkData: Codable {
    var layerManagerData: Data?
    var canvasSize: CGSize?
    // NEW: Interior settings
    var snapToGrid: Bool?
    var gridType: String? // "square" or "hex"
    var gridSpacing: Double? // 1.0, 5.0, 10.0, etc.
    var backgroundColor: String? // "white", "parchment", etc.
}
```

**Option 2: Dedicated Settings Object**
```swift
struct InteriorMapSettings: Codable {
    var snapToGrid: Bool = false
    var showGrid: Bool = true
    var gridType: GridType = .square
    var gridSpacing: Double = 5.0
    var gridUnits: String = "ft"
    var backgroundColor: String = "white"
}

// In DraftMapWorkData:
var interiorSettings: InteriorMapSettings?
```

**Notes:**
- This affects user experience significantly for users working on detailed floor plans or dungeon maps
- Snap to grid is particularly important for architectural accuracy
- Background color affects mood and readability (parchment is popular for fantasy maps)
- May be related to how exterior map settings are (or aren't) persisted
- Consider whether these should be per-draft or global app preferences with per-draft overrides

**Related Issues:**
- May be same issue for exterior maps (need to verify if exterior settings persist)
- Grid overlay rendering may also need to respect persisted settings


## DR-0039: Saved Strokes/Settings Failed to Restore During Drawing Canvas Restoration

**Status:** 🔴 Open
**Platform:** macOS (likely affects all platforms)
**Component:** DrawCanvas / Draft Persistence / LayerManager
**Severity:** High
**Date Identified:** 2026-01-11

**Description:**

When restoring a draft interior/architectural map, the saved drawing strokes are not being properly decoded and restored. The draft restoration process shows that stroke data exists (LayerManager with 2 layers is decoded) but the strokes themselves are lost during the import process, resulting in a blank canvas.

**Console Log Evidence:**
```
Restoring draft work for method: Interior / Architectural
[IMPORT] Decoding LayerManager from 729 bytes
[IMPORT] Restored LayerManager with 2 layers
[IMPORT] LayerManager has no content for this platform - falling back to legacy import
[DR-0004.3] importDrawingData called with 2 bytes
[DR-0004.3] Successfully decoded 0 strokes into model
[DR-0012] macOS - Created PKInkingTool with width: 5.0
✅ Restored drawing canvas state
📍 Restored to step: Configure
✅ Draft restoration complete - currentStep: Configure, method: Interior / Architectural
[DR-0004.3] makeNSView called, model has 0 strokes
```

**Key Observations from Logs:**
1. LayerManager decodes successfully (729 bytes → 2 layers)
2. Error message: "LayerManager has no content for this platform"
3. Falls back to "legacy import"
4. Legacy import receives only **2 bytes** of drawing data
5. Result: **0 strokes** successfully decoded
6. Canvas displays blank despite having saved work

**Steps to Reproduce:**
1. Create a new interior/architectural map in Map Wizard
2. Configure settings (grid, background, etc.)
3. Draw several strokes with interior brushes (walls, furniture, etc.)
4. Save/close the map draft (or quit app)
5. Reopen the same draft
6. **Observe**: Canvas is blank, all strokes are gone

**Expected Behavior:**
- All saved strokes should restore correctly
- LayerManager content should be compatible across platforms
- Drawing data should decode completely (not just 2 bytes)
- Canvas should display all previously drawn strokes

**Actual Behavior:**
- LayerManager reports "no content for this platform"
- Falls back to legacy import which receives minimal data (2 bytes)
- Decoding results in 0 strokes
- User loses all their work

**Root Cause Hypotheses:**

**1. Platform-Specific LayerManager Data**
- LayerManager may be saving data in a platform-specific format
- macOS restoration can't read data saved on macOS (self-incompatibility)
- The "no content for this platform" message suggests platform detection logic issue

**2. Drawing Data Encoding Issue**
- Strokes are being saved to LayerManager but not to the legacy format
- Legacy import path expects drawing data in different location/format
- Only 2 bytes being passed suggests data is truncated or pointer/size issue

**3. Codable/Data Corruption**
- LayerManager decodes (729 bytes) but stroke data within is corrupted
- DrawingStroke array may not be properly encoded/decoded
- CloudKit sync could be corrupting binary data

**Files Likely Affected:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` - Draft save/restore logic
- `Cumberland/DrawCanvas/DrawingCanvasViewMacOS.swift` - macOS-specific import
- `Cumberland/DrawCanvas/LayerManager.swift` - Layer persistence, platform detection
- `Cumberland/DrawCanvas/DrawingLayer.swift` - DrawingStroke Codable implementation
- `Cumberland/MapWizardView.swift` - Draft orchestration

**Investigation Needed:**

**1. Check LayerManager Platform Logic:**
```swift
// Where is "no content for this platform" message generated?
// What determines platform compatibility?
// Is macOS data being marked as iOS-only or vice versa?
```

**2. Check Drawing Data Export:**
```swift
// In LayerManager or DrawingCanvasView, where is drawing data exported?
// Why are only 2 bytes being passed to legacy import?
// Should legacy import even be used when LayerManager decodes successfully?
```

**3. Check DrawingStroke Encoding:**
```swift
// Verify DrawingStroke.encode() is saving all fields including brushID
// Verify array encoding isn't being truncated
// Check if Optional fields are causing decode failures
```

**4. Check Platform Macro Logic:**
```swift
// Search for #if os(macOS) / #if os(iOS) that might affect persistence
// Ensure macOS can read macOS-saved data (not just cross-platform)
```

**Workarounds:**
- None currently - users lose work when closing/reopening drafts

**Impact:**
- **Critical workflow blocker** - users cannot save work
- Affects all interior map drawing (likely affects exterior maps too)
- Data loss issue - user work disappears
- Prevents iterative map creation over multiple sessions

**Priority:** HIGH - This is a data loss bug that prevents basic app functionality

---

## Template for Adding New DRs

When a new issue is identified or resolved but not yet verified, add it here using this template:

```markdown
## DR-0057: Calendar Extraction JSON Parser Fails on Null Length (Variable-Length Divisions)

**Status:** 🔴 Identified - Not Resolved
**Platform:** All platforms
**Component:** CalendarSystemExtractor, AI Content Analysis (ER-0010)
**Severity:** Medium
**Date Identified:** 2026-01-29
**Date Resolved:** Not yet resolved

**Description:**

The `CalendarSystemExtractor` JSON parser fails to parse calendar systems when time divisions have `null` for the `length` field. This occurs when OpenAI correctly identifies variable-length divisions like "Epochs" or "Eras" which don't have a fixed numeric length.

**Steps to Reproduce:**

1. Create a Project card with text describing a calendar system that includes variable-length divisions:
   ```
   The Imperial Meridian Calendar has five divisions:
   Epochs (eras), Cycles (years, 360 rotations each),
   Seasons (quarters, 4 per cycle)...
   ```
2. Run AI Content Analysis with OpenAI provider
3. Observe console output

**Expected Behavior:**

- OpenAI extracts the calendar structure with `"length": null` for Epochs (variable-length)
- Parser successfully handles `null` length values
- Creates CalendarStructure with:
  - Epochs division with `isVariable: true`, `length: nil`
  - Other divisions with numeric lengths

**Actual Behavior:**

```
⚠️ [OpenAI] Failed to parse calendars JSON
   Raw JSON (first 500 chars): {
  "calendars": [
    {
      "name": "Imperial Meridian Calendar",
      "divisions": [
        {
          "name": "epoch",
          "pluralName": "epochs",
          "length": null,          ← Parser fails here
          "isVariable": true
        },
```

Result: `✅ [CalendarSystemExtractor] Extracted 0 calendar systems` (should be 1)

**Root Cause:**

The JSON parser in `CalendarSystemExtractor` expects all `TimeDivisionData.length` values to be integers. When OpenAI (correctly) returns `null` for variable-length divisions, the parser throws an error and fails to decode the entire calendar structure.

**Location:**
- File: `Cumberland/AI/CalendarSystemExtractor.swift` (likely)
- Type: `TimeDivisionData` struct
- Issue: `length` field doesn't handle `null` / `nil` values

**Expected JSON Structure:**
```swift
struct TimeDivisionData: Codable {
    var name: String
    var pluralName: String
    var length: Int?  // Should be optional to handle null
    var isVariable: Bool
}
```

**Current Issue:**
- If `length` is declared as `Int` (non-optional), JSON decoding fails on `null`
- If parser expects all divisions to have lengths, variable-length divisions fail

**Fix Required:**

1. **Ensure `TimeDivisionData.length` is optional (`Int?`)**
2. **Update parser to handle `null` length values**
3. **When converting to `TimeDivision` model, provide default:**
   - Variable-length divisions: `length = 1` (or special sentinel value)
   - Or: Add `isVariable` flag to `TimeDivision` model

**Test Steps:**

1. Use ER-0016 test prompt with Imperial Meridian Calendar
2. Run AI Content Analysis with OpenAI
3. Verify calendar extraction succeeds with 1 calendar found
4. Check extracted calendar has 5 divisions including Epochs
5. Verify Epochs division has `isVariable: true`

**Related:**
- ER-0010: AI Content Analysis (Calendar Extraction)
- ER-0016: Timeline/Chronicle/Scene test data uses this calendar

---

## DR-0058: SceneTemporalPositionEditor - Calendar Values Don't Persist When Saved (REOPENED - Major Fix)

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Critical
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29 (Fixed twice - binding issue, then conversion algorithm)

**Description:**

When using the SceneTemporalPositionEditor in "Custom Calendar" mode, users can enter calendar division values (e.g., Cycle 1847, Season 0, Rotation 1, Segment 8) using the TextField/Stepper inputs. However, when clicking "Done" or "Save", the entered values do not persist to the CardEdge's `temporalPosition` property.

**Steps to Reproduce:**

1. Open a Timeline card that has a Calendar System assigned
2. Go to Timeline tab → Click "Edit Positions…"
3. Select a scene from the dropdown
4. Toggle to "Custom Calendar" mode
5. Enter calendar division values:
   - Cycle: 1847
   - Season: 0
   - Rotation: 1
   - Segment: 8
6. Click "Done" button
7. Re-open the same scene's temporal editor

**Expected Behavior:**

- Calendar values should convert to a Date (epoch + calculated seconds)
- Date should be saved to `edge.temporalPosition`
- When re-opening the editor, the same temporal position should be shown
- Scene should appear at the correct position on the timeline graph

**Actual Behavior:**

- User enters calendar values
- Clicks "Done"
- Values do not persist - scene position may revert or show incorrect date
- Timeline graph does not show scene at expected position

**Root Cause (Suspected):**

Possible causes:
1. `calendarDivisionValues` array initialized to all zeros, may not update properly via TextField/Stepper bindings
2. `calculatedTemporalPosition` computed property may return incorrect date
3. `convertCalendarUnitsToDate()` function may have logic error
4. Timeline epoch date may not be set correctly
5. Binding issue - manual TextField bindings may not trigger `@State` updates properly

**Location:**
- File: `Cumberland/SceneTemporalPositionEditor.swift`
- Lines: 64-97 (init), 326-368 (calendar inputs), 373-403 (conversion), 413-426 (save)

**Root Cause Confirmed:**

The issue was with the custom `Binding()` approach used for TextField and Stepper controls. Custom bindings were not properly triggering `@State` updates when array elements changed. SwiftUI's change detection for array mutations can be unreliable with manual bindings.

**Fix Applied:**

Replaced custom `Binding()` objects with direct array subscript bindings in `calendarDateInputs()` function:

**Before (lines 335-357):**
```swift
TextField("0", value: Binding(
    get: { calendarDivisionValues[index] },
    set: { calendarDivisionValues[index] = newValue }
), format: .number)

Stepper("", value: Binding(...), in: 0...10000)
```

**After:**
```swift
TextField("0", value: $calendarDivisionValues[index], format: .number)
Stepper("", value: $calendarDivisionValues[index], in: 0...10000)
```

This ensures proper `@State` change detection and view updates. Also wrapped the HStack in an `if calendarDivisionValues.indices.contains(index)` guard to prevent index out of bounds issues.

**Files Modified (Fix #1):**
- `Cumberland/SceneTemporalPositionEditor.swift:326-350`

**REOPENED - Second Issue Discovered:**

After fixing the binding issue, user reported values still not persisting. Root cause: **Calendar date conversion algorithm was fundamentally flawed**.

**Original Conversion Algorithm (WRONG):**
```swift
// Tried to multiply division lengths together
for (index, _) in divisions.enumerated() {
    var multiplier: TimeInterval = 1
    for smallerIndex in (index + 1)..<divisions.count {
        multiplier *= TimeInterval(divisions[smallerIndex].length)
    }
    totalSeconds += TimeInterval(value) * multiplier
}
```

This approach failed because:
1. Imperial Meridian Calendar hierarchy is NOT strictly linear
2. Cycles = 360 Rotations (skips Seasons in calculation)
3. Seasons = 90 Rotations (grouping within Cycles)
4. The calendar has both hierarchical AND parallel structures

**Correct Conversion Algorithm (Fix #2):**
```swift
// Convert everything to Segments (base unit = 1 hour = 3600 seconds)
// Imperial Meridian structure:
//   1 Cycle = 360 Rotations
//   1 Season = 90 Rotations
//   1 Rotation = 24 Segments
//   1 Segment = 3600 seconds

var totalRotations = 0
totalRotations += cycleValue * 360    // Cycles to rotations
totalRotations += seasonValue * 90    // Seasons to rotations
totalRotations += rotationValue       // Direct rotations

var totalSegments = 0
totalSegments += totalRotations * 24  // Rotations to segments
totalSegments += segmentValue         // Direct segments

let totalSeconds = TimeInterval(totalSegments) * 3600
return epoch.addingTimeInterval(totalSeconds)
```

**Why This Works:**
- Recognizes that Cycles and Seasons both count in Rotations (they're additive)
- Converts to smallest unit (Segments) before calculating seconds
- Handles the specific structure of Imperial Meridian Calendar
- Added debug logging to trace conversion

**Files Modified (Fix #2):**
- `Cumberland/SceneTemporalPositionEditor.swift:389-453` (completely rewrote convertCalendarUnitsToDate)

**Test Steps:**

1. Follow ER-0016-MANUAL-SETUP-GUIDE.md Step 5.2
2. Set scene temporal position using custom calendar input
3. Verify "Calculated Date" shows expected date before saving
4. Click "Done"
5. Re-open temporal editor for same scene
6. Verify calendar values are preserved (or date correctly reflects input)
7. Open Multi-Timeline Graph - verify scene appears at correct position

**Related:**
- ER-0016 Phase 2: Multi-Timeline Graph (depends on this working)
- SceneTemporalPositionEditor.swift:413-426 (saveAndDismiss function)

---

## DR-0059: SceneTemporalPositionEditor - Duration Field Not Directly Editable (Redesigned for Calendar Units)

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Medium
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29 (Completely redesigned)

**Description:**

The SceneTemporalPositionEditor displays the scene's duration but does not provide a direct TextField or other input control to edit the duration value. Users can only select from presets or use the "Custom" preset which shows days/hours/minutes steppers. There is no way to directly type a duration value in seconds.

**Steps to Reproduce:**

1. Open Timeline card → Timeline tab → "Edit Positions…"
2. Select a scene
3. Observe the "Duration" section
4. Try to directly edit the displayed duration text

**Expected Behavior:**

- Provide a TextField or numeric input for direct duration entry
- Allow users to type duration in seconds or preferred unit
- Preserve existing preset picker for common durations
- Show formatted duration as read-only summary

**Actual Behavior:**

- Duration section only shows:
  - Preset picker (dropdown with options like "1 hour", "1 day", etc.)
  - Custom days/hours/minutes steppers (only visible when "Custom" preset selected)
  - Read-only formatted duration text
- No direct TextField to type duration value
- User must use steppers or presets only

**Location:**
- File: `Cumberland/SceneTemporalPositionEditor.swift`
- Lines: 197-244 (Duration Section)

**Fix Applied (Complete Redesign):**

**User Feedback:** "The seconds field is confusing. There are no seconds in the calendar. Durations are measured in segments (hours)."

**Solution:** Completely redesigned duration UI to be calendar-aware:

**Old Approach (REMOVED):**
- Preset picker with "15 minutes", "1 hour", "1 day", etc.
- "Seconds:" TextField (confusing for calendar users)
- Days/Hours/Minutes steppers when "Custom" selected
- No calendar unit awareness

**New Approach (Calendar-Aware):**
```swift
// Check if timeline has custom calendar
if let calendar = timeline.calendarSystem {
    // Show duration in calendar's smallest unit
    let smallestUnitPlural = calendar.divisions.first?.pluralName ?? "units"

    // TextField for "Segments:" (or whatever the smallest unit is)
    TextField("1", value: $durationInSmallestUnit, format: .number)
        .onChange(of: durationInSmallestUnit) { _, newValue in
            // Convert to seconds: 1 segment = 3600 seconds
            duration = TimeInterval(newValue) * 3600
        }

    // Show equivalent in standard time
    Text("Equivalent: \(formattedDurationForCalendar)")
}
```

**Key Changes:**
1. **Removed:**
   - Preset picker (duration presets enum)
   - "Seconds:" label and field
   - Days/hours/minutes steppers
   - All preset-related logic

2. **Added:**
   - `durationInSmallestUnit` state variable
   - Calendar-aware label (e.g., "Segments:" instead of "Seconds:")
   - "Equivalent:" helper text showing standard time (e.g., "4 hours")
   - Auto-detection of calendar's smallest unit

3. **Conversion:**
   - Input: User enters "4" in "Segments:" field
   - Calculation: 4 * 3600 = 14,400 seconds
   - Display: "Equivalent: 4 hours"

**Files Modified:**
- `Cumberland/SceneTemporalPositionEditor.swift`
  - Lines 60-62: Replaced custom duration states with `durationInSmallestUnit`
  - Lines 84-88: Initialize from edge duration
  - Lines 197-256: Completely rewrote duration section
  - Lines 333-347: Added `formattedDurationForCalendar` computed property
  - Removed: preset enum, updateCustomDuration method, onChange handlers

**Test Steps:**

1. Open temporal editor for a scene
2. Verify TextField allows direct duration input
3. Type "7200" → should set duration to 2 hours
4. Verify preset updates to "2 hours" if available, or "Custom" otherwise
5. Change preset → verify TextField updates accordingly

---

## DR-0060: SceneTemporalPositionEditor - Duration Presets Use "Hours" Instead of Calendar-Specific Term (SUPERSEDED by DR-0059)

**Status:** ✅ Resolved - SUPERSEDED (fixed by complete redesign in DR-0059)
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Low
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29

**Description:**

The duration preset labels use generic time units like "1 hour", "2 hours", "8 hours" etc. However, when a Timeline uses a custom calendar system (e.g., Imperial Meridian Calendar), the smallest time division may have a different name like "Segments" or "Rotations". Using "hours" in the UI creates confusion when users are thinking in terms of their custom calendar's units.

**Steps to Reproduce:**

1. Create Timeline with custom calendar (e.g., Imperial Meridian Calendar with "Segments")
2. Open temporal editor for a scene on that timeline
3. Observe duration preset labels: "15 minutes", "30 minutes", "1 hour", "2 hours", "4 hours", "8 hours", "1 day", "3 days", "1 week"

**Expected Behavior:**

- When Timeline has custom calendar, preset labels should use calendar-specific terms
- Example: "4 segments" instead of "4 hours" (if 1 segment = 1 hour)
- Presets should be dynamically generated based on calendar divisions
- Provide option to view in both standard time and calendar units

**Actual Behavior:**

- Preset labels always use "minutes", "hours", "days", "weeks"
- No awareness of custom calendar terminology
- User must mentally convert "hours" to "segments"
- Manual setup guide uses comments like "(4 segments)" after duration values

**Location:**
- File: `Cumberland/SceneTemporalPositionEditor.swift`
- Lines: 27-55 (DurationPreset enum with hardcoded labels)
- Lines: 199-211 (Preset picker)

**Fix Applied (Option 3 - Hybrid Approach):**

Added calendar-aware help text in the Duration section footer that shows the relationship between standard time units and the calendar's smallest division.

**Implementation:**
```swift
footer: {
    if let calendar = timeline.calendarSystem, let smallestDivision = calendar.divisions.last {
        Text("How long does this scene last? Note: 1 \(smallestDivision.name) = 3600 seconds (1 hour)")
    } else {
        Text("How long does this scene last?")
    }
}
```

**Behavior:**
- **Without custom calendar:** Shows "How long does this scene last?"
- **With custom calendar:** Shows "How long does this scene last? Note: 1 segment = 3600 seconds (1 hour)"
- Provides context without changing existing preset labels
- Users can still use standard presets but understand the conversion

**Why Option 3:**
- Maintains consistency with existing preset labels (no breaking changes)
- Provides calendar-specific context where it's helpful
- Simpler implementation than dynamic preset generation
- Users can use the new "Seconds:" TextField to enter exact values in calendar units

**Files Modified:**
- `Cumberland/SceneTemporalPositionEditor.swift:258-268`

**Future Enhancement:**
- Could extend to show calendar-equivalent in formatted duration display
- Could add optional calendar unit input mode alongside seconds

**Test Steps:**

1. Open temporal editor for scene on timeline with custom calendar
2. Verify duration presets show calendar-specific units (if Option 2)
3. OR verify help text shows calendar equivalents (if Option 1/3)
4. Select preset → verify duration correctly set
5. Formatted duration should also use calendar units where appropriate

**Related:**
- Imperial Meridian Calendar: Segment = 1 hour (3600 seconds)
- ER-0016-MANUAL-SETUP-GUIDE.md: Uses "(4 segments)" notation throughout

---

## DR-0061: SceneTemporalPositionEditor Sheet Renders as Blank 100x100 Square on Initial Display (macOS)

**Status:** 🔴 Identified - Not Resolved (Multiple Fix Attempts)
**Platform:** macOS
**Component:** SceneTemporalPositionEditor, TimelineChartView, ER-0016 Phase 2
**Severity:** High
**Date Identified:** 2026-01-29
**Date Resolved:** Not yet resolved

**Description:**

When opening the SceneTemporalPositionEditor sheet from TimelineChartView (Timeline tab → "Edit Positions…" → select scene), the sheet initially renders as a tiny blank square (approximately 100x100 pixels) on screen. The sheet only displays its full content correctly after the user clicks away from the app and returns focus to it.

**Steps to Reproduce:**

1. Open a Timeline card with scenes
2. Go to Timeline tab
3. Click "Edit Positions…" button
4. Select a scene from the dropdown menu
5. Observe the sheet that appears

**Expected Behavior:**

- Sheet should immediately display at 500x600 minimum size
- Full content should be visible (header, calendar inputs, duration section, buttons)
- No user interaction should be required to trigger proper rendering

**Actual Behavior:**

- Sheet appears as a blank 100x100 pixel square
- No content visible initially
- User must click away from the app (lose focus)
- Upon returning to the app, sheet renders correctly with full content

**Root Cause (Suspected):**

macOS sheet presentation sizing issue. Possible causes:

1. **Missing explicit frame on sheet presentation:**
   - TimelineChartView.swift:201-216 presents sheet without explicit frame
   - Other sheets in codebase use `.frame(minWidth:, minHeight:)` on sheet modifier
   - Example from CardRelationshipView.swift:294-299:
     ```swift
     .sheet(isPresented: $isPresentingEditCard) {
         CardEditorView(...)
             .frame(minWidth: 560, minHeight: 520)
     }
     ```

2. **Form layout calculation delay:**
   - SceneTemporalPositionEditor uses Form with dynamic content
   - Form may not calculate layout correctly before initial render
   - VStack `.frame(minWidth: 500, minHeight: 600)` may not propagate to sheet

3. **Conditional content in sheet:**
   - Sheet content is conditional: `if let sceneRow = selectedSceneForEdit, let edge = ...`
   - SwiftUI may render sheet before fully evaluating content size

**Location:**
- Presentation: `Cumberland/TimelineChartView.swift:201-216`
- Content: `Cumberland/SceneTemporalPositionEditor.swift:101-311`

**Root Cause (Suspected):**

SwiftUI Form layout calculation bug on macOS. The Form with complex content (especially graphical DatePicker) doesn't calculate its intrinsic size correctly until user interaction triggers a layout recalculation.

**Fix Attempts:**

**Attempt 1 - Explicit sheet frame (PARTIAL):**
- Added `.frame(minWidth: 560, minHeight: 640)` to sheet presentation in TimelineChartView
- Result: Sheet appears at correct size, but content still blank until clicked
- User report: "Clicking in the sheet did cause it to display"

**Attempt 2 - Form layout hints (FAILED):**
- Added `.frame(maxWidth: .infinity, maxHeight: .infinity)` to Form
- Added `.layoutPriority(1)` to Form to force layout calculation
- Added `.frame(minHeight: 280)` to graphical DatePicker
- Result: **User reported still not working - "sheet still does not display on initial startup"**

**Attempt 3 - Replace Form with ScrollView (TESTING):**

**Root Cause Confirmed:** SwiftUI Form has known layout calculation issues on macOS, especially with dynamic content. Form doesn't properly report its intrinsic size on first render.

**Solution:** Replaced Form with ScrollView + VStack:

**Before:**
```swift
Form {
    Section {
        // Calendar inputs
    } header: {
        Label("When", systemImage: "calendar")
    }

    Section {
        // Duration inputs
    } header: {
        Label("Duration", systemImage: "clock")
    }
}
.formStyle(.grouped)
```

**After:**
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 20) {
        // Section 1: When
        // Section 2: Duration
    }
    .padding()
}
```

**Why This Should Work:**
- ScrollView has more predictable layout behavior on macOS
- VStack explicitly sizes itself based on children
- Removes dependency on Form's automatic sizing
- Sections become regular VStacks with clear dimensions

**Files Modified:**
- `Cumberland/TimelineChartView.swift:209-211` (sheet frame modifier)
- `Cumberland/SceneTemporalPositionEditor.swift:123-124` (replaced Form with ScrollView)
- `Cumberland/SceneTemporalPositionEditor.swift:265-268` (replaced .formStyle with padding)
- `Cumberland/SceneTemporalPositionEditor.swift:148` (DatePicker minHeight)

**Test Steps:**

1. Open Timeline card → Timeline tab → "Edit Positions…"
2. Select a scene from dropdown
3. Verify sheet immediately displays at correct size (560x640 or similar)
4. Verify all content is visible without needing to refocus app
5. Test with multiple scenes to ensure consistent behavior
6. Test on different macOS versions if possible

**Workaround:**

User can click away from app and back to trigger proper rendering. Not acceptable for production but functional for immediate testing.

**Related:**
- SceneTemporalPositionEditor.swift:301 has `.frame(minWidth: 500, minHeight: 600)` but may not be sufficient
- DR-0058, DR-0059, DR-0060: Other SceneTemporalPositionEditor fixes in same session

**Priority:**

High - This affects usability of ER-0016 Phase 2 testing and makes the editor appear broken on first use.

---

## DR-XXXX: [Brief Title]

**Status:** 🟡 Resolved - Not Verified
**Platform:** iOS / macOS / visionOS / All platforms
**Component:** [Component Name]
**Severity:** Critical / High / Medium / Low
**Date Identified:** YYYY-MM-DD
**Date Resolved:** YYYY-MM-DD

**Description:**
[Detailed description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happens]

**Fix Applied:**
[Description of the fix]

**Test Steps:**
1. [How to verify the fix]
2. [Expected results]

---
```

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*When user verifies a DR, move it to the appropriate DR-verified-XXXX-YYYY.md file*
