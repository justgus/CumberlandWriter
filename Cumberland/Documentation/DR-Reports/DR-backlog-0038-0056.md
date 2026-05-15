# Discrepancy Reports (DR) - Archive 0038-0056

This document contains older DRs that are still open or closed. Moved from DR-unverified.md on 2026-01-29 to reduce file size.

**Status:** 6 DRs in this archive (5 Open, 1 Closed)

**Note:** DR-0055 and DR-0056 verified and moved to DR-verified-0051-0060.md (2026-02-01)
**Note:** DR-0039 closed as OBE - fixed by draft persistence improvements (2026-02-01)

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

**Status:** ⚪ Closed - OBE (Overtaken By Events)
**Platform:** macOS (likely affects all platforms)
**Component:** DrawCanvas / Draft Persistence / LayerManager
**Severity:** High (when active)
**Date Identified:** 2026-01-11
**Date Closed:** 2026-02-01

**Description:**

When restoring a draft interior/architectural map, the saved drawing strokes were not being properly decoded and restored. The draft restoration process showed that stroke data exists (LayerManager with 2 layers is decoded) but the strokes themselves were lost during the import process.

**Resolution:**

Closed as OBE (Overtaken By Events). This issue was resolved by subsequent draft persistence improvements implemented in DR-0011, DR-0012, DR-0013, and related draft restoration work. The current draft persistence system successfully saves and restores strokes, settings, and layer data.

**Impact:** Issue no longer present in current codebase.

---

*Archived: 2026-01-29*
*Original file: DR-unverified.md*
