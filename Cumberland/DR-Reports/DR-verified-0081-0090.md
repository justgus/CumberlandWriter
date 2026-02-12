# Discrepancy Reports (DR) - Batch 9: DR-0081 to DR-0090

This file contains verified discrepancy reports DR-0081 through DR-0090.

**Batch Status:** ✅ Complete (10/10 verified)

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

## DR-0084: ER-0022 Service Layer Compliance — Extracted Components Bypassing Services

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardRelationshipOperations, MurderBoardOperations, CardEditorSaveHandler
**Severity:** Medium (architectural — no user-visible bugs, violated ER-0022 layered architecture)
**Date Identified:** 2026-02-10
**Date Resolved:** 2026-02-10
**Date Verified:** 2026-02-10
**Related ER:** ER-0022 (Code Maintainability Refactoring)

**Description:**
Post-ER-0022 audit revealed that components extracted in Phases 3–4.5 were bypassing the service layer infrastructure (RelationshipManager, CardOperationManager, StructureRepository) established in Phase 1. The refactoring correctly extracted code from large view files into smaller components, but those components continued to call `modelContext` directly instead of routing through the new services.

**Root Cause:**
ER-0022 was executed in phases. The service layer was built first (Phase 1), but the view extraction (Phases 3–4.5) moved existing code as-is without retrofitting it to use those services. The result was a split architecture: services existed but weren't wired to the newly-extracted callers.

**Resolution:**
Updated `CardRelationshipOperations`, `MurderBoardOperations.createEdge`, and `CardEditorSaveHandler` to delegate write operations through `RelationshipManager`, `CardOperationManager`, and `StructureRepository` respectively. Added `@Environment(\.services)` to `CardRelationshipView`, `MurderBoardView`, and `CardEditorView`. All changes use a delegate-with-fallback pattern for resilience.

**Files Modified:**
- `Cumberland/CardRelationshipView.swift` — Added `@Environment(\.services)`, propagated to all 12 write callsites
- `Cumberland/CardRelationship/CardRelationshipOperations.swift` — Service delegation for `removeRelationship`, `cleanupAndDelete`, `changeCardType`
- `Cumberland/Murderboard/MurderBoardView.swift` — Added `@Environment(\.services)`
- `Cumberland/Murderboard/MurderBoardOperations.swift` — `createEdge` delegates to `RelationshipManager`
- `Cumberland/CardEditorView.swift` — Added `@Environment(\.services)`, passes `structureRepository`
- `Cumberland/CardEditor/CardEditorSaveHandler.swift` — Added `StructureRepository` injection, delegated structure CRUD

**Test Verification:**
- ✅ Relationship creation via drag in CardRelationshipView still works
- ✅ Remove relationship via toolbar button still works
- ✅ Card deletion via relationship view still works
- ✅ Card type change via relationship view still works
- ✅ Edge creation in MurderBoard drag-to-connect still works
- ✅ Creating a new Project card with a structure still works
- ✅ Editing an existing Project card's structure still works
- ✅ Build succeeded with no errors

---

## DR-0085: MurderBoard — All iOS Gestures Non-Functional (Tap, Drag, Drop, Long-Press)

**Status:** ✅ Resolved - Verified
**Platform:** iOS / iPadOS only
**Component:** SidebarPanel.swift / MultiGestureHandler.swift
**Severity:** Critical — MurderBoard completely non-interactive on iOS
**Date Identified:** 2026-02-10
**Date Resolved:** 2026-02-10
**Date Verified:** 2026-02-10

**User Report:**
> No drag events are being recognised for the MurderBoard on iOS. No console output. Cannot drop an entity onto the board. Cannot click select an entity on the board. Right click does not respond. Drag node does not respond. Drag edge to another node does not respond.

**Root Cause:**
`SidebarPanel.swift` applied `.contentShape(Rectangle())` to a `Color.clear` background on the full-width `HStack` wrapper — a wrapper that contains a `Spacer()` filling the entire canvas area. This made a completely transparent overlay covering the whole screen hittable on iOS.

On iOS, SwiftUI delivers touches to the topmost hittable view. The `SidebarPanel` ZStack layer sits above the `MurderBoardView` canvas layer in `MurderBoardView`'s main ZStack. Because the transparent full-screen overlay was hittable, it intercepted 100% of touches before they could reach the gesture system below — silently swallowing every tap, drag, long-press, and drop gesture.

The macOS implementation was unaffected because macOS uses `NSEvent` local monitors, which bypass SwiftUI hit testing entirely and receive input from the OS event stream directly.

**Investigation path:**
1. Initial hypothesis (incorrect): Duplicate `.coordinateSpace(name:)` registration in `CanvasLayer.swift` — tested and confirmed no change in behavior.
2. Added `print()` diagnostics (`[MGH-iOS-DIAG]`, `[GHI-iOS-DIAG]`) to gesture system — only the `setupGestureHandler complete` message fired, proving the system was initialized correctly but zero gesture callbacks ever triggered.
3. Conclusion: something **above** the gesture layer in the ZStack was consuming all touches. Root cause identified in `SidebarPanel.swift`.

**Resolution:**
Removed the `.background(Color.clear.contentShape(Rectangle()))` modifier from `SidebarPanel`'s full-width `HStack`. The gesture-blocking purpose of that modifier (per DR-0083, preventing canvas scroll during sidebar scroll) is handled by the sidebar panel content itself via `.blockCanvasGestures()` — a `simultaneousGesture` modifier on the sidebar scroll view. The transparent full-screen overlay was never needed for that purpose.

```swift
// BEFORE (bug):
.allowsHitTesting(true)
.background(
    Color.clear
        .contentShape(Rectangle())
)

// AFTER (fix):
// DR-0083 / DR-0085: Allow hit testing only on the sidebar content itself.
// Do NOT use .contentShape(Rectangle()) on the full HStack — the Spacer() fills
// the entire canvas width and would swallow all touches on iOS
.allowsHitTesting(true)
```

Diagnostic `print()` statements added during investigation were removed from `MultiGestureHandler.swift` and `MurderBoardGestureTargets.swift` after the fix was confirmed. Both macOS and iOS builds pass cleanly.

**Files Modified:**
- `Cumberland/SidebarPanel.swift:58-64` — Removed `.background(Color.clear.contentShape(Rectangle()))` block
- `Cumberland/MultiGestureHandler.swift` — Removed all `[MGH-iOS-DIAG]` diagnostic prints
- `Cumberland/Murderboard/MurderBoardGestureTargets.swift` — Removed all `[GHI-iOS-DIAG]` diagnostic prints

**Test Verification:**
- ✅ Tap to select a node works on iOS
- ✅ Drag to move a node works on iOS
- ✅ Drag edge handle to another node triggers RelationType sheet on iOS
- ✅ Long-press on a node shows context menu on iOS
- ✅ Drag card from backlog sidebar onto canvas adds it to the board on iOS
- ✅ Two-finger pan scrolls the canvas on iOS
- ✅ macOS MurderBoard gestures unaffected
- ✅ Both macOS and iOS builds pass cleanly

---

## DR-0086: MurderBoard Canvas Unresponsive to Magic Keyboard Trackpad Pan (iPadOS)

**Status:** ✅ Resolved - Verified
**Platform:** iPadOS
**Component:** MultiGestureHandler / GestureOverlayView
**Severity:** High — MurderBoard canvas could not be panned via Magic Keyboard trackpad
**Date Identified:** 2026-02-10
**Date Resolved:** 2026-02-10
**Date Verified:** 2026-02-10

**Description:**
Two-finger pan on the MurderBoard canvas had no effect when using a Magic Keyboard trackpad on iPadOS. The sidebar ScrollView responded correctly to trackpad scroll, but the canvas did not pan at all. All other gestures (tap, drag, pinch) worked normally.

**Root Cause:**
Magic Keyboard trackpad delivers scroll input as `UIScrollEvent` (indirect pointer events), not as touch events. `UIPanGestureRecognizer` with `minimumNumberOfTouches = 2` never fires for these events. The `GestureOverlayView` (a `UIScrollView` subclass) used `isScrollEnabled = false`, which causes UIScrollView to drop scroll events after hit-testing — the `panGestureRecognizer` pipeline was never reached even though `point(inside:with:)` correctly returned `true` for scroll events.

**Resolution:**
Changed `GestureOverlayView` to use `isScrollEnabled = true` with a large virtual `contentSize` (100,000 × 100,000) and `contentOffset` initialized at center (50,000, 50,000). In `UIScrollViewDelegate.scrollViewDidScroll`, the delta from center is computed, `contentOffset` is reset back to center immediately (preventing any visible scrolling), and the delta is forwarded to `processTwoFingerPanChanged`. Scroll lifecycle is managed via `scrollViewWillBeginDragging` and `scrollViewDidEndDragging`. The sidebar exclusion rect check prevents the scroll delegate from panning the canvas when the pointer is over the sidebar.

**Files Modified:**
- `Cumberland/MultiGestureHandler.swift` — `GestureOverlayView` class (iOS section): `isScrollEnabled = true`, virtual contentSize, `scrollViewDidScroll` delegate implementation

**Test Verification:**
- ✅ Two-finger pan on Magic Keyboard trackpad pans the MurderBoard canvas
- ✅ Sidebar ScrollView still scrolls independently without panning canvas
- ✅ Touch gestures (tap, drag, pinch) unaffected
- ✅ Both macOS and iOS builds pass cleanly

---

## DR-0087: MurderBoard and CardSheetView Toolbar Items Left-Justified on macOS; iOS Segmented Picker Shows Text

**Status:** ✅ Resolved - Verified
**Platform:** macOS, iOS
**Component:** MurderBoardToolbar, CardSheetView, MainAppView
**Severity:** Medium — cosmetic/usability; toolbar items in wrong position
**Date Identified:** 2026-02-10
**Date Resolved:** 2026-02-10
**Date Verified:** 2026-02-10

**Description:**
Two related toolbar layout issues:

1. **macOS — left-justified toolbar items:** On macOS, `MurderBoardView` and `CardSheetView` both added `ToolbarItemGroup(placement: .primaryAction)` items as nested child views. macOS places nested child `.primaryAction` items to the LEFT of the parent view's `.primaryAction` items, resulting in the MurderBoard zoom controls and CardSheetView Focus Mode button appearing on the left side of the window toolbar instead of the right. MurderBoard also produced a second separate toolbar cluster to the right.

2. **iOS — segmented control shows text labels:** The tab picker segmented control on iOS used `Label(tab.title, systemImage:)` which renders both icon and text, making segments too wide and cluttered.

**Root Cause:**
On macOS, child/nested views that call `.toolbar { ToolbarItemGroup(placement: .primaryAction) }` have their items inserted to the left of the parent's `.primaryAction` items — this is AppKit/SwiftUI toolbar ordering behaviour for nested NavigationStack/NavigationSplitView hierarchies. The iOS picker used `Label` instead of `Image(systemName:)`.

**Resolution:**

1. **MurderBoard macOS:** Suppressed `.toolbar {}` on macOS entirely (`#if os(iOS) || os(visionOS)`). Replaced with an in-canvas bottom HUD overlay (`bottomZoomStrip`) styled as a capsule with `.ultraThinMaterial` background. The strip contains: minus button, slider, plus button, zoom% text field, divider, recenter, shuffle.

2. **CardSheetView macOS:** Suppressed `.toolbar { toolbarContent }` on macOS (`#if os(iOS) || os(visionOS)`). Moved the Focus Mode button to a `.overlay(alignment: .topTrailing)` in-view button with `.plain` button style, same keyboard shortcut and help text preserved.

3. **iOS picker:** Changed `Label(tab.title, systemImage:)` to `Image(systemName: tab.systemImage)` — icons only. Removed `ScrollView` wrapper (no longer needed with compact icon-only segments).

**Files Modified:**
- `Cumberland/Murderboard/MurderBoardView.swift` — Wrapped `.toolbar` in `#if os(iOS) || os(visionOS)`, added `bottomZoomStrip` to ZStack
- `Cumberland/Murderboard/MurderBoardToolbar.swift` — Added `#if os(macOS)` extension with `bottomZoomStrip(windowSize:)`
- `Cumberland/CardSheetView.swift` — Wrapped `.toolbar` in `#if os(iOS) || os(visionOS)`, added `#if os(macOS)` focus mode overlay button
- `Cumberland/MainAppView.swift` — iOS picker uses `Image(systemName:)` only, removed ScrollView wrapper

**Test Verification:**
- ✅ MurderBoard: zoom strip appears as bottom-center capsule HUD on macOS
- ✅ MurderBoard: window toolbar no longer shows left-justified zoom items on macOS
- ✅ CardSheetView: Focus Mode button appears as top-trailing in-view overlay on macOS
- ✅ CardSheetView: window toolbar no longer shows left-justified Focus Mode button
- ✅ iOS: segmented picker shows icons only, no text
- ✅ Both macOS and iOS builds pass cleanly

---

## DR-0088: MurderBoard Zoom Strip — Minus Button Requires Pixel-Precise Hit, Zoom TextField Clamps on Partial Input, iOS Zoom in Toolbar

**Status:** ✅ Resolved - Verified
**Platform:** macOS, iOS
**Component:** MurderBoardToolbar, MainAppView
**Severity:** Medium — controls unusable or behaved incorrectly
**Date Identified:** 2026-02-10
**Date Resolved:** 2026-02-10
**Date Verified:** 2026-02-10

**Description:**
Three follow-on issues after DR-0087's zoom strip implementation:

1. **Minus button hit area:** The minus (`−`) button in the macOS bottom zoom strip required pixel-precise clicking — only the 1–2px glyph line of the minus symbol registered as a hit. The `+` button had the same issue but was less noticeable because its two lines are slightly larger.

2. **Zoom TextField clamps on partial input:** The zoom percentage TextField bound directly to `zoomScale` via a computed `Binding`. Clearing the field transiently produced `"0"` or `""`, which clamped to the minimum zoom (20%). Typing "50" after clearing would clamp incorrectly at intermediate keystrokes.

3. **iOS zoom controls in system toolbar:** After DR-0087, iOS still had zoom controls in the system toolbar (`.primaryAction`), cluttering the navigation bar.

**Root Cause:**
1. SwiftUI's hit testing for `.plain` buttons only counts pixels where the label actually renders. A thin `Image(systemName: "minus")` with no explicit content shape has a nearly zero-area hit region.
2. The binding's `set` closure fired on every keystroke including intermediate states, immediately clamping to the valid range.
3. iOS zoom controls were not moved to the HUD overlay as part of DR-0087.

**Resolution:**

1. **Hit area:** Added `.contentShape(Rectangle())` to the `Image` inside both minus and plus button labels, making the entire 16×16 pt frame hittable.

2. **Zoom TextField:** Extracted a `ZoomTextField` private struct with a local `@State var draft: String`. Draft commits only on Return or focus loss. External zoom changes sync the display via `.onChange(of: zoomScale)` only when not editing. Invalid input resets to current zoom on commit.

3. **iOS zoom overlay:** Added `#if os(iOS)` `bottomZoomStrip` extension. Updated `MurderBoardView.swift` to include the strip on `os(macOS) || os(iOS)`. Changed toolbar condition from `#if os(iOS) || os(visionOS)` to `#if os(visionOS)` only.

**Files Modified:**
- `Cumberland/Murderboard/MurderBoardToolbar.swift` — `.contentShape(Rectangle())` on minus/plus labels; `ZoomTextField` struct; iOS `bottomZoomStrip` extension
- `Cumberland/Murderboard/MurderBoardView.swift` — Bottom strip condition `os(macOS) || os(iOS)`; toolbar suppressed on iOS

**Test Verification:**
- ✅ Minus button responds to clicks anywhere in its visible area on macOS
- ✅ Clearing zoom TextField and typing "50" sets zoom to 50% correctly
- ✅ Invalid input resets to current zoom on commit
- ✅ iOS MurderBoard shows bottom zoom HUD overlay instead of toolbar zoom items
- ✅ Both macOS and iOS builds pass cleanly

---

## DR-0089: Gregorian Calendar Requires Manual Epoch Setting

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardEditorTimelineSection, SceneTemporalPositionEditor, CardEditorViewModel
**Severity:** Medium
**Date Identified:** 2026-02-11
**Date Resolved:** 2026-02-11
**Date Verified:** 2026-02-11

**Description:**
When a user creates a timeline and assigns a Gregorian calendar system, the system requires manually setting an epoch date (to 01/01/0001) before temporal positioning works. For standard Gregorian calendars, this is unnecessary — the epoch is well-known and should be auto-configured.

**Resolution:**
- Added `isStandardCalendar` computed property to `CalendarSystem` that detects "Gregorian" and "Julian" calendars by name
- Added `standardEpochDate` computed property that returns January 1, 0001 for standard calendars
- `CardEditorTimelineSection` shows read-only epoch info for standard calendars instead of manual configuration
- `SceneTemporalPositionEditor` uses `resolvedEpoch` that falls back to `standardEpochDate`
- `CardEditorViewModel.validate()` auto-sets epoch for standard calendars; ordinal timelines (no calendar) are always valid; custom calendars require explicit epoch
- `createCard()`/`updateCard()`/`saveToCard()` all auto-set epoch for standard calendars as safety net

**Files Modified:**
- `Cumberland/Model/CalendarSystem.swift` — `isStandardCalendar`, `standardEpochDate`
- `Cumberland/CardEditor/CardEditorTimelineSection.swift` — Auto-epoch, read-only UI for standard calendars
- `Cumberland/Timeline/SceneTemporalPositionEditor.swift` — `resolvedEpoch`, all epoch references updated
- `Cumberland/ViewModels/CardEditorViewModel.swift` — `validate()`, `createCard()`, `updateCard()`, `saveToCard()`

---

## DR-0090: Standard Date Picker Has No Year Input — Unusable for Historical Dates

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor
**Severity:** High
**Date Identified:** 2026-02-11
**Date Resolved:** 2026-02-11
**Date Verified:** 2026-02-11

**Description:**
The "Standard Date" input mode used a `.graphical` DatePicker requiring month-by-month navigation. Unusable for timelines spanning centuries or millennia.

**Resolution:**
- Replaced `.graphical` DatePicker with custom date entry fields:
  - Year: TextField with `.number.grouping(.never)` + Stepper (1-9999)
  - Month: Picker with full month names
  - Day: Picker auto-adjusting for month/year
  - Time: Hour (00-23) and Minute (00-59) pickers
- Date preview in long format, day auto-clamps on month change
- All numeric TextFields use `.grouping(.never)` to prevent comma separators

**Files Modified:**
- `Cumberland/Timeline/SceneTemporalPositionEditor.swift` — `standardDateInputFields`, `assembledDate`, `syncDateFromComponents`, `daysInMonth`, input state properties

---

*Last Updated: 2026-02-11*

