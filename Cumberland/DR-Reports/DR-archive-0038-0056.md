# Discrepancy Reports (DR) - Archive 0038-0056

This document contains older DRs that are still open or awaiting verification. Moved from DR-unverified.md on 2026-01-29 to reduce file size.

**Status:** 9 DRs in this archive (1 Verified, 1 Resolved, 7 Open)

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

Added bidirectional relationship creation to match `CardRelationshipView` pattern. See full details in original DR documentation.

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift:346-495`

---

## DR-0055: Relationship Creation Timing Issue - Cancel Button Behaves Like Save

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, CardEditorView, Phase 6 (ER-0010)
**Severity:** Critical
**Date Identified:** 2026-01-26
**Date Resolved:** 2026-01-26

**Description:**

In Phase 6 (ER-0010) implementation, a critical workflow bug caused the "Cancel" button in CardEditorView to behave identically to the "Save" button when creating relationships. See full details in original DR documentation.

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:15-31, 253-282, 479-498`
- `Cumberland/CardEditorView.swift:107-109, 1187-1198, 1336-1393`

---

## DR-0054: Edit Card Sheet on iOS - Save/Cancel Buttons Pushed Off-Screen

**Status:** 🔴 Open
**Platform:** iOS/iPadOS
**Component:** CardSheetView, CardEditorView
**Severity:** High
**Date Identified:** 2026-01-25
**Updated:** 2026-01-29 (User clarified root cause)

**Description:**

On iOS/iPadOS, when editing a card via the Edit Card sheet, the Save and Cancel buttons are pushed off the bottom of the sheet and are not accessible. The buttons exist in the code but the sheet layout is broken, making them impossible to reach.

**Root Cause:**

The buttons are not missing - they are being rendered but pushed outside the visible sheet bounds due to layout issues in CardSheetView or CardEditorView on iOS.

**Impact:** **High Severity** - Core editing functionality broken on iOS (cannot save or cancel edits).

---

## DR-0043: Duplicate RelationType Entries Created Despite Deduplication Logic

**Status:** 🔴 Open
**Platform:** All platforms
**Component:** RelationType / CumberlandApp seeding
**Severity:** Medium
**Date Identified:** 2026-01-24

**Description:**

Duplicate RelationType entries are appearing in the database despite the presence of deduplication logic in the seeding code.

**Affected Code:**
- `Cumberland/CumberlandApp.swift:517-554` - `seedRelationTypesIfNeeded`
- `Cumberland/CumberlandApp.swift:1299-1334` - `ensureMirrorType`

---

## DR-0041: Vegetation and Terrain Brushes Should Render as Area Fills

**Status:** 🔴 Open
**Platform:** All platforms
**Component:** BrushEngine / ExteriorMapBrushSet
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

Several exterior vegetation and terrain brushes currently render as line strokes but should render as area fills (similar to how the Marsh brush works).

**Affected Brushes:** Forest, Single Tree, Grassland, Plains, Jungle, Desert, Tundra, Farmland

---

## DR-0040: Brush Set Picker Text Overflow on iOS

**Status:** 🔴 Open
**Platform:** iOS/iPadOS only
**Component:** BrushGridView / Tool Palette
**Severity:** Medium
**Date Identified:** 2026-01-19

**Description:**

In the "Brushes for Generic" section of the tool palette on iOS, when a brush set is selected, the UI layout breaks with text overflowing into the section below.

---

## DR-0038: Draft Interior Drawing Settings Not Remembered Between View Loads

**Status:** 🔴 Open
**Platform:** All platforms
**Component:** MapWizardView / Draft Persistence
**Severity:** Medium
**Date Identified:** 2026-01-10

**Description:**

When working on interior/architectural maps in the Map Wizard, drawing settings such as snap to grid, grid type, grid size, and background color (parchment) are not remembered between view loads or app restarts.

**Affected Settings:**
1. Snap to Grid (toggle)
2. Grid Type (Square/Hex)
3. Grid Size (1 ft, 5 ft, 10 ft, Custom)
4. Background Color (White, Dark, Parchment, Gray)

---

## DR-0039: Saved Strokes/Settings Failed to Restore During Drawing Canvas Restoration

**Status:** 🔴 Open
**Platform:** macOS (likely affects all platforms)
**Component:** DrawCanvas / Draft Persistence / LayerManager
**Severity:** High
**Date Identified:** 2026-01-11

**Description:**

When restoring a draft interior/architectural map, the saved drawing strokes are not being properly decoded and restored. The draft restoration process shows that stroke data exists (LayerManager with 2 layers is decoded) but the strokes themselves are lost during the import process.

**Impact:** **Critical workflow blocker** - users cannot save work, data loss issue.

---

*Archived: 2026-01-29*
*Original file: DR-unverified.md*
