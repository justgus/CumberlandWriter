# Discrepancy Reports (DR) - Batch 9: DR-0081 to DR-0090

This file contains verified discrepancy reports DR-0081 through DR-0090.

**Batch Status:** 🚧 In Progress (3/10 verified)

---

## DR-0081: No Card Duplication UI

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** MainAppView / CardEditorView
**Severity:** Medium
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-08
**Date Verified:** 2026-02-08

**Description:**
There was no UI to duplicate a card. CardOperationManager.duplicateCard() method existed per ER-0022 Phase 1, but no UI exposed it.

**Resolution:**
Added duplication UI in two places:
1. **Multi-select batch duplicate**: Duplicate button in multi-select toolbar
2. **Single-card duplicate**: "Duplicate" option in context menu (all platforms)

Features:
- Duplicates all properties: kind, name (+ " (Copy)"), subtitle, detailedText, originalImageData, epochDate, epochDescription
- Single-card duplicate auto-selects the new card
- Batch duplicate exits multi-select mode after completion
- Uses CardOperationManager.duplicateCard() when available

**Files Modified:**
- `Cumberland/MainAppView.swift:609-616` - Added Duplicate button to multi-select toolbar
- `Cumberland/MainAppView.swift:819-824` - Added Duplicate to macOS/iOS context menu
- `Cumberland/MainAppView.swift:800-805` - Added Duplicate to visionOS context menu
- `Cumberland/MainAppView.swift:1212-1262` - Added `duplicateSelectedCards()` and `duplicateCard()` helper functions

**Test Verification:**
- ✅ Right-click/long-press context menu shows "Duplicate" option
- ✅ Single duplicate creates new card with "(Copy)" suffix
- ✅ New card is auto-selected after single duplication
- ✅ Batch duplicate in multi-select mode works for multiple cards
- ✅ All card properties copied correctly (name, subtitle, description, image)

**Note:** Resolved together with DR-0079/DR-0080 (expanded multi-select actions).

---

## DR-0082: No Citation UI for Non-Image Citations on Cards

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardDetailTab / MainAppView / Source model
**Severity:** High
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09
**Date Verified:** 2026-02-09

**Description:**
The citation system (Source, Citation, CitationKind) is fully implemented with Quote, Paraphrase, Data, and Image types, but the only exposed UI is for Image Attributions. Users cannot add Quote, Paraphrase, or Data citations to cards. Additionally, Source cards in the sidebar were not connected to the Source model used by the citation system.

**Resolution:**

### Part 1: Citations Tab
Added `.citations` tab to card detail views, exposing the existing `CitationViewer` component:

1. Added `case citations = "Citations"` to `CardDetailTab` enum
2. Added citations to `allowedTabs(for:)` - available for ALL card kinds
3. Wired `CitationViewer(card:)` in MainAppView's detail tab switch
4. visionOS ornament picker automatically picks up new tab

### Part 2: Source Card ↔ Source Model Bridge
Connected Card (kind=.sources) to the Source model for citation integration:

1. Added `sourceRef: Source?` relationship to Card model
2. Added `sourceCard: Card?` back-reference to Source model
3. Created `SourceDetailEditor` view with full bibliographic fields
4. Routed Source cards to SourceDetailEditor in MainAppView

### Part 3: Source-First Workflow
Created `SourceEditorSheet` for streamlined Source creation with automatic Card creation.

### Part 4: Duplicate Source Prevention
Added `fetchOrCreateSource()` method and "Consolidate Duplicate Sources" utility in Developer Tools.

### Part 5: Number Field Formatting
Fixed comma appearing in Year field with `.grouping(.never)` format.

**Files Modified:**
- `Cumberland/CardDetailTab.swift` - Added `.citations` case
- `Cumberland/MainAppView.swift` - Route Source cards to SourceDetailEditor, render CitationViewer for citations tab
- `Cumberland/Model/Card.swift` - Added `sourceRef` relationship with `.nullify` delete rule
- `Cumberland/Model/Source.swift` - Added `sourceCard` back-reference
- `Cumberland/Citation/SourceDetailEditor.swift` - New file: full bibliographic editor
- `Cumberland/Citation/SourceEditorSheet.swift` - New file: Source-first creation workflow
- `Cumberland/Citation/QuickAttributionSheetEditor.swift` - Added `fetchOrCreateSource()` method
- `Cumberland/Citation/CitationEditor.swift` - Updated `createSource()` to check for existing sources
- `Cumberland/Diagnostic Views/DeveloperToolsView.swift` - Added Source consolidation function

**Test Verification:**
- ✅ Citations tab appears for all card kinds
- ✅ Can add Quote, Paraphrase, Data citations
- ✅ Source cards show SourceDetailEditor with bibliographic fields
- ✅ Duplicate sources are prevented/consolidated
- ✅ Year field displays without comma

---

## DR-0083: MurderBoard Backlog List Scroll Propagates to Canvas

**Status:** ✅ Resolved - Verified
**Platform:** macOS (trackpad two-finger scroll)
**Component:** MurderBoardView / MultiGestureHandler
**Severity:** Low
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09
**Date Verified:** 2026-02-09

**Description:**
When scrolling the backlog sidebar list in MurderBoardView using macOS trackpad two-finger scroll, the scroll gesture also affects the main canvas, causing unwanted panning of the murder board. This occurs because the pointer is technically hovering over both the sidebar and the canvas simultaneously.

**Resolution:**
Implemented gesture exclusion zones in MultiGestureHandler to block scroll wheel events when the pointer is in the sidebar region:

1. Added `gestureExclusionZones` array to MultiGestureHandler
2. Added `setGestureExclusionZones()` and `clearGestureExclusionZones()` public methods
3. Added `isPointInExclusionZone()` check function
4. Modified scroll wheel event monitor to reject events when pointer is in exclusion zone
5. Added `updateGestureExclusionZones()` to MurderBoardView that sets/clears zones based on sidebar visibility

**Files Modified:**
- `Cumberland/MultiGestureHandler.swift:306-311` - Added gestureExclusionZones property and setGestureExclusionZones()
- `Cumberland/MultiGestureHandler.swift:313-317` - Added clearGestureExclusionZones()
- `Cumberland/MultiGestureHandler.swift:319-327` - Added isPointInExclusionZone()
- `Cumberland/MultiGestureHandler.swift:989-995` - Modified scroll wheel monitor to check exclusion zones
- `Cumberland/Murderboard/MurderBoardView.swift:244-253` - Added onChange handlers for sidebar and gesture handler
- `Cumberland/Murderboard/MurderBoardView.swift:256-276` - Added updateGestureExclusionZones() function

**Test Verification:**
- ✅ Scrolling backlog sidebar does not pan canvas
- ✅ Scrolling over canvas area still pans normally
- ✅ Sidebar visibility toggle updates exclusion zones

---

