# Discrepancy Reports (DR) - Unverified Issues

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **0 open DRs** | **1 resolved, awaiting verification** | **4 verified**

---

## DR-0076: No Edge Creation UI in MurderBoardView

**Status:** 🟡 Resolved - Not Verified
**Platform:** All platforms
**Component:** MurderBoardView
**Severity:** High
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09

**Description:**
The MurderBoardView displays existing relationships (CardEdges) between cards but provides no user interface to create new edges directly on the board. Users expect to be able to drag from one node to another to create a relationship, but the node dragging gesture for repositioning supersedes any potential edge-creation gesture.

**Resolution:**
Implemented **Edge Handles** solution (Option 2):

### Edge Handle
- Small circular handle on the **trailing edge (right side center)** of each node
- Shows the card's kind accent color with an arrow icon
- Does not interfere with node dragging (separate gesture target)

### Drag Interaction
- Dragging from the edge handle initiates edge creation
- A **reference line** draws from the source card center to the cursor
- Line is **dashed** when over invalid targets, **solid green** when over valid targets
- Valid targets are highlighted with a colored border during drag

### RelationType Selection
- On drop over a valid target, a **RelationType picker sheet** appears
- Shows applicable relation types for the source→target kind combination
- Option to create a new RelationType if none are suitable
- Edge is created after selecting a RelationType

### Visual Feedback
- Edge handle scales up when its drag is active
- Target nodes show green highlight when hovered during drag
- Non-target nodes (including source) show muted highlight
- Arrow cursor indicator at the end of the drag line

**Files Created:**
- `Cumberland/Murderboard/EdgeCreationSystem.swift` - Edge creation state, handles, line layer, and sheet

**Files Modified:**
- `Cumberland/Murderboard/MurderBoardView.swift` - Added edge creation state, RelationType query, sheet presentation
- `Cumberland/Murderboard/MurderBoardOperations.swift` - Added edge creation handler functions
- `Cumberland/Murderboard/MurderBoardNodesLayer.swift` - Added edge creation state, hover detection, drop target highlighting
- `Cumberland/CanvasLayer.swift` - Added edge handles layer and creation line layer

**Test Steps:**
1. Open a card's MurderBoard with at least 2 nodes
2. Locate the edge handle (small circle) on the right side of any node
3. Drag from the edge handle toward another node
4. Observe the reference line follows the cursor
5. Observe target nodes highlight when hovered
6. Release over a valid target node
7. Verify RelationType picker sheet appears
8. Select a relation type and click "Create"
9. Verify the edge now appears on the board connecting the two nodes
10. Verify the edge also appears in CardRelationshipView for both cards

---

## DR-0077: No Search or Filter UI in All Cards List

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** MainAppView
**Severity:** High
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09

**Description:**
The "All Cards" view in the sidebar does not provide search or filter controls. Users cannot filter cards by type (Character, Location, etc.) or search by name/content. As the database grows, finding specific cards becomes increasingly difficult.

**Resolution:**
Replaced `.searchable()` modifier with custom inline header containing:

1. **Search TextField**: Custom search field in list header
   - Appears at top of ALL card lists (not just All Cards)
   - Magnifying glass icon, text field, clear button
   - Styled with rounded background
   - Searches name, subtitle, detailedText, author

2. **Kind Filter** (All Cards view only):
   - Filter icon (line.3.horizontal.decrease.circle) next to search field
   - Icon is filled when a filter is active
   - Dropdown menu shows "All Types" plus all card kinds
   - Checkmark indicates current selection
   - Filter works in combination with search

**Files Modified:**
- `Cumberland/MainAppView.swift:80` - Added `allCardsKindFilter` state variable
- `Cumberland/MainAppView.swift:213-216` - Removed `.searchable()` modifier
- `Cumberland/MainAppView.swift:783-790` - Added `cardsListHeader` section header to all card lists
- `Cumberland/MainAppView.swift:1044-1110` - Added `cardsListHeader` with TextField and filter Menu

**Test Steps:**
1. Navigate to any card kind in sidebar (e.g., "Characters")
2. Verify search field appears at top of list with magnifying glass icon
3. Type to search - verify cards filter in real-time
4. Click X button to clear search
5. Navigate to "All Cards" in sidebar
6. Verify search field AND filter icon appear in header
7. Click filter icon (lines symbol)
8. Select a card kind from dropdown
9. Verify icon becomes filled and only that type shows
10. Combine filter with search to narrow results further

---

## DR-0078: No Image Export UI

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardEditorView / Image Views
**Severity:** Medium
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-08
**Date Verified:** 2026-02-09

**Description:**
Users cannot export card images to files (PNG, JPEG). The ImageProcessingService has export capabilities per ER-0022 Phase 1, but no UI exposes this functionality.

**Resolution:**
Added export button to FullSizeImageViewer with platform-specific implementations:

**macOS:**
- Export menu with PNG and JPEG options
- NSSavePanel for file location selection
- Uses ImageProcessingService for format conversion

**iOS:**
- Export menu with PNG and JPEG options (saves to Photos)
- Share button for standard iOS share sheet
- UIActivityViewController for sharing

**Files Modified:**
- `Cumberland/Images/FullSizeImageViewer.swift:4-11` - Added imports for UniformTypeIdentifiers, AppKit/UIKit
- `Cumberland/Images/FullSizeImageViewer.swift:20-22` - Added export state variables
- `Cumberland/Images/FullSizeImageViewer.swift:37-47` - Added export button to toolbar overlay
- `Cumberland/Images/FullSizeImageViewer.swift:130-211` - Added exportButton view, exportImage(), shareImage(), currentImageData

**Test Steps:**
1. Open a card with an image
2. Long-press or double-tap image to open FullSizeImageViewer
3. Tap export button (download arrow icon) in top-left corner
4. **macOS**: Select "Export as PNG" or "Export as JPEG" → Choose save location
5. **iOS**: Select format to save to Photos, or tap "Share..." for share sheet
6. Verify exported image opens correctly in external app

---

## DR-0082: No Citation UI for Non-Image Citations on Cards

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardDetailTab / MainAppView / Source model
**Severity:** High
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09

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
3. Created `SourceDetailEditor` view with full bibliographic fields:
   - Title, Authors (synced to Card name/subtitle)
   - Publication Details: Container/Journal, Publisher, Year, Volume, Issue, Pages
   - Digital References: DOI, URL, Accessed Date
   - Additional Info: License, Notes
   - Chicago-style citation preview
4. Routed Source cards to SourceDetailEditor in MainAppView

### Part 3: Source-First Workflow
Created `SourceEditorSheet` for streamlined Source creation:

1. Sheet opens with all bibliographic fields immediately available
2. On save, automatically creates BOTH Source model AND linked Card
3. Wired "+" button in Sources sidebar to open SourceEditorSheet instead of generic card creation
4. Changed delete rule from `.cascade` to `.nullify` on `sourceRef` to fix SwiftData crash
5. Added explicit cleanup in `cleanupBeforeDeletion()` to delete linked Source when deleting Source card

### Part 4: Duplicate Source Prevention
Fixed duplicate Sources being created for repeated AI-generated content:

1. Added `fetchOrCreateSource()` method to `QuickAttributionSheetEditor` that checks for existing Source with matching title before creating new one
2. Updated `CitationEditor.createSource()` to check for existing sources with same title
3. If existing Source found, uses it instead of creating duplicate
4. Added "Consolidate Duplicate Sources" utility in Developer Tools to clean up existing duplicates:
   - Found in Data Integrity section
   - Shows count of duplicate sources before consolidation
   - Merges sources with identical titles (case-insensitive)
   - Moves all citations from duplicates to the primary source
   - Merges metadata from duplicates (fills in missing fields)
   - Preserves source with linked Card, most citations, and most metadata
   - Appends notes from duplicates if both have notes

### Part 5: Number Field Formatting
Fixed comma appearing in Year field (e.g., "1,949" instead of "1949"):

1. Added `.grouping(.never)` format to Year field in SourceEditorSheet
2. Added `.grouping(.never)` format to Year field in SourceDetailEditor

**Files Modified:**
- `Cumberland/CardDetailTab.swift` - Added `.citations` case
- `Cumberland/MainAppView.swift:673-681` - Route Source cards to SourceDetailEditor
- `Cumberland/MainAppView.swift:733-736` - Render CitationViewer for citations tab
- `Cumberland/Model/Card.swift:117-120` - Added `sourceRef` relationship with `.nullify` delete rule
- `Cumberland/Model/Card.swift` - Added Source cleanup in `cleanupBeforeDeletion()`
- `Cumberland/Model/Source.swift:30-33` - Added `sourceCard` back-reference
- `Cumberland/Citation/SourceDetailEditor.swift` - New file: full bibliographic editor
- `Cumberland/Citation/SourceEditorSheet.swift` - New file: Source-first creation workflow
- `Cumberland/Citation/QuickAttributionSheetEditor.swift:103-157` - Added `fetchOrCreateSource()` method
- `Cumberland/Citation/CitationEditor.swift:108-122` - Updated `createSource()` to check for existing sources
- `Cumberland/Diagnostic Views/DeveloperToolsView.swift` - Added Source query, duplicate detection, and consolidation function

**Test Steps:**

*Part 1: Citations Tab*
1. Open any card (Character, Scene, Location, etc.)
2. Verify "Citations" tab appears in tab bar (quote bubble icon)
3. Tap Citations tab
4. Verify CitationViewer displays with "Add Citation" button
5. Add citations of various kinds (Quote, Paraphrase, Data, Image)
6. Note: The citation "badges" are the caption-sized text labels (e.g., "Quote", "Paraphrase") shown next to each citation in the list

*Part 2: Source Cards*
1. Navigate to "Sources" in sidebar
2. Click "+" to create new Source
3. Verify SourceEditorSheet opens with all bibliographic fields
4. Fill in Title, Authors, Publisher, Year (verify no comma in year)
5. Click Create - verify both Source model and Card are created
6. Re-open the Source card - verify SourceDetailEditor shows all saved fields

*Part 3: Delete Source Cards*
1. Create a Source card (with or without bibliographic data)
2. Delete the Source card
3. Verify no crash occurs (fixed SwiftData snapshot error)

*Part 4: Duplicate Prevention (Future)*
1. Drop an AI-generated image onto a card
2. In the attribution dialog, enter "ChatGPT" as the source title
3. Drop another AI-generated image onto a different card
4. Enter "ChatGPT" again as source title
5. Verify in the Sources picker that only ONE "ChatGPT" source exists (not duplicated)

*Part 5: Consolidate Existing Duplicates*
1. Open Developer Tools (accessible from app menu or settings)
2. Navigate to "Data Integrity" section
3. Observe the "Source Integrity" group shows duplicate count (if any)
4. Click "Consolidate Duplicate Sources"
5. Confirm the action in the dialog
6. Verify the result message shows how many duplicates were consolidated
7. Navigate to Sources sidebar - verify duplicate titles are now consolidated
8. Check that citations from the former duplicates are now linked to the surviving source

---

## DR-0083: MurderBoard Backlog List Scroll Propagates to Canvas

**Status:** ✅ Resolved - Verified
**Platform:** macOS (trackpad two-finger scroll)
**Component:** MurderBoardView / MultiGestureHandler
**Severity:** Low
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-09

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

**Test Steps:**
1. Open a card's MurderBoard on macOS
2. Show the backlog sidebar (if hidden)
3. Position pointer over the backlog sidebar
4. Use two-finger scroll on trackpad
5. Verify backlog scrolls but canvas does NOT pan
6. Position pointer over canvas area (not sidebar)
7. Use two-finger scroll on trackpad
8. Verify canvas pans normally

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-02-09*
*DR-0077, DR-0078, DR-0082, DR-0083 verified | DR-0076 resolved - awaiting verification*
