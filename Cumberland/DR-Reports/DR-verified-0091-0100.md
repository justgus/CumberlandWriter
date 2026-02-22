# Discrepancy Reports (DR) - Batch 10: DR-0091 to DR-0100

This file contains verified discrepancy reports DR-0091 through DR-0100.

**Batch Status:** 🚧 In Progress (8/10 verified)

---

## DR-0091: Custom Calendar Date Entry Does Not Update Temporal Position

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor
**Severity:** High
**Date Identified:** 2026-02-11
**Date Resolved:** 2026-02-11
**Date Verified:** 2026-02-11

**Description:**
Custom calendar division value entry did not correctly update the temporal position. The conversion function was hardcoded for the Imperial Meridian Calendar's specific division names. Additionally, the Gregorian calendar's variable-length months (28-31 days) caused incorrect date calculations through the uniform division-based conversion (336 days/year instead of 365.25).

**Resolution:**
- Rewrote `convertCalendarUnitsToDate()` to be fully generic — uses each division's `length` property to calculate hierarchically from largest to smallest, regardless of division names
- Rewrote `formatDateInCalendar()` to decompose dates generically using division lengths
- The onChange handler now uses `resolvedEpoch` (from DR-0089) so it no longer silently fails for standard calendars
- Standard calendars (Gregorian/Julian): Custom Calendar input mode toggle is hidden — the division-based conversion cannot handle variable-length months. The Standard Date fields (DR-0090) provide correct year/month/day entry.
- Custom Calendar mode remains available for fictional calendars with uniform division lengths
- All numeric TextFields use `.grouping(.never)` to prevent comma separators

**Algorithm:**
Walks divisions from largest (last) to smallest (first), accumulating: `total = total * divisions[i].length + values[i]`. The smallest unit's real-time duration is inferred from its name (second=1s, minute=60s, hour/segment=3600s).

**Files Modified:**
- `Cumberland/Timeline/SceneTemporalPositionEditor.swift` — `convertCalendarUnitsToDate()`, `formatDateInCalendar()`, dynamic help text, hidden toggle for standard calendars, `.grouping(.never)` on all numeric fields

**Related Issues:**
- DR-0089 (Gregorian calendar epoch auto-configuration) — resolved together
- DR-0090 (Standard date picker usability) — resolved together

---

## DR-0092: visionOS Settings Presented as Modal Sheet Instead of Window

**Status:** ✅ Resolved - Verified
**Platform:** visionOS
**Component:** visionOS, Settings, OrnamentViews
**Severity:** Medium
**Date Identified:** 2026-02-12
**Date Resolved:** 2026-02-12
**Date Verified:** 2026-02-12

**Description:**
On visionOS, tapping the Settings gear icon in the leading ornament opened a modal sheet with no dismiss controls. The ornament also displayed a close button (X) that was supposed to dismiss the Settings sheet but did not function correctly since it appeared before the sheet was opened.

**Resolution:**
- Added `Window("Settings", id: "settings")` scene definition in `CumberlandApp.swift` for visionOS
- Changed `SettingsOrnament` action from `showingSettings = true` (sheet toggle) to `openWindow(id: "settings")` (window open)
- Removed `onDismiss` parameter and close button from `SettingsOrnament` (windows have system dismiss controls)
- Removed visionOS branch from `.sheet(isPresented: $showingSettings)` in MainAppView

**Files Modified:**
- `CumberlandApp.swift` — Added visionOS Settings Window scene
- `MainAppView.swift` — Changed ornament action to `openWindow(id: "settings")`; removed visionOS branch from Settings sheet
- `visionOS/OrnamentViews.swift` — Simplified SettingsOrnament (removed dismiss button and `onDismiss` parameter)

---

## DR-0093: visionOS Developer Tools Presented as Modal Sheet Instead of Window

**Status:** ✅ Resolved - Verified
**Platform:** visionOS
**Component:** visionOS, Developer Tools, OrnamentViews
**Severity:** Medium
**Date Identified:** 2026-02-12
**Date Resolved:** 2026-02-12
**Date Verified:** 2026-02-12

**Description:**
On visionOS, the Developer Tools hammer icon in the leading ornament opened a modal sheet. The sheet included a toolbar Done button for dismissal, but the correct visionOS pattern is a standalone window. A `Window("Developer Tools", id: "dev.tools")` scene already existed in CumberlandApp.swift but was not being used — the ornament toggled a sheet boolean instead.

**Resolution:**
- Changed `DeveloperToolsOrnament` action from `showingDeveloperTools = true` to `openWindow(id: "dev.tools")`
- Removed optional `onDismiss` parameter and close button from `DeveloperToolsOrnament`
- Removed visionOS branch from `.sheet(isPresented: $showingDeveloperTools)` in MainAppView

**Files Modified:**
- `MainAppView.swift` — Changed ornament action to `openWindow(id: "dev.tools")`; removed visionOS branch from Developer Tools sheet
- `visionOS/OrnamentViews.swift` — Simplified DeveloperToolsOrnament (removed dismiss button and `onDismiss` parameter)

---

## DR-0094: Image History Restore Does Not Update CardEditorView — Stale Image Overwrites Restored Version on Save

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardEditorViewModel, CardEditorSheets, ImageVersionManager
**Severity:** High
**Date Identified:** 2026-02-14
**Date Resolved:** 2026-02-14
**Date Verified:** 2026-02-14

**Description:**
When restoring a previous image version from the Image History sheet (ER-0017), the restored image was correctly written to the Card model and persisted in SwiftData. However, the CardEditorViewModel held a stale snapshot of the original image data loaded when the editor opened. Tapping Save caused the stale ViewModel data to overwrite the restored image.

**Root Cause:**
`CardEditorViewModel.loadCard()` creates a one-time snapshot of image data into local properties (`imageData`, `thumbnail`). When `ImageVersionManager.restoreVersion()` updates `Card.originalImageData` directly on the model, the ViewModel's snapshot remained stale. On save, `updateCard()` called `card.setOriginalImageData(imageData)` with the stale copy.

**Resolution:**
1. Added `reloadImageFromCard(_:)` method to CardEditorViewModel — refreshes `imageData` and `thumbnail` from the Card model
2. Added `onDismiss` handler to the ImageHistory sheet in CardEditorSheets — calls `reloadImageFromCard(card)` when the sheet closes

**Files Modified:**
- `Cumberland/ViewModels/CardEditorViewModel.swift` — Added `reloadImageFromCard(_:)` method
- `Cumberland/CardEditor/CardEditorSheets.swift` — Added `onDismiss` handler to image history sheet

---

## DR-0095: Map Wizard Cannot Save Drawn Map — "No map data available" After Clicking Continue

**Status:** ✅ Resolved - Verified
**Platform:** macOS (likely also iOS)
**Component:** Map Wizard, Drawing Canvas Export
**Severity:** High
**Date Identified:** 2026-02-16
**Date Resolved:** 2026-02-16
**Date Verified:** 2026-02-16

**Description:**
After drawing a map in the Map Wizard's Draw step and clicking "Continue" to proceed to the finalize step, the rendered map image briefly appeared then was replaced with "No map data available". The Save button was disabled.

**Root Cause:**
`exportAsImageData()` on macOS called `macosCanvasView?.exportAsImageData()`, but `macosCanvasView` is a `weak var` that becomes `nil` when SwiftUI destroys the `NSViewRepresentable` during step navigation. The stroke data persisted in the model but the export method had no fallback path. Similarly, `isEmpty` and `canSaveMap` relied on the dead view reference.

**Resolution:**
Added `renderFromModelData()` fallback method to `DrawingCanvasModel` that renders directly from persisted model data into a bitmap context when the NSView is deallocated. Also fixed `isEmpty` to check model data directly, and `exportCanvasAsPNG()` with the same fallback. On iOS, `exportAsImageData()` now calls `syncDrawingWithActiveLayer()` before exporting.

**Files Modified:**
- `Cumberland/DrawCanvas/DrawingCanvasView.swift` — `exportAsImageData()`, `exportCanvasAsPNG()`, `isEmpty`, `notifyStrokesChanged()`, new `renderFromModelData()`, `renderBaseLayerFill()`, `renderStrokeToContext()` methods

---

## DR-0096: BoardGestureIntegration Modifies @Binding State During View Body Evaluation

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** BoardEngine — BoardGestureIntegration, MultiGestureHandler
**Severity:** Medium
**Date Identified:** 2026-02-18
**Date Resolved:** 2026-02-18
**Date Verified:** 2026-02-18

**Description:**
SwiftUI purple triangle runtime warnings appeared at `BoardGestureIntegration.swift` lines 149 and 176, indicating state modification during view body evaluation. This is a SwiftUI pattern violation that causes undefined behavior.

**Root Cause:**
`setupAndReturnGestureHandler()` was called as a fallback from within the `body` computed property (line 136 of `BoardGestureIntegration.swift`) when `gestureHandler` was `nil`. This method directly assigned `gestureHandler = handler` (a `@Binding` property) and called `setupGestureHandler()` (which mutates additional `@Binding` properties), all during SwiftUI's view evaluation phase. SwiftUI prohibits state mutations during `body` evaluation.

**Resolution:**
Wrapped the `@Binding` mutations in `setupAndReturnGestureHandler()` inside `DispatchQueue.main.async` to defer them to the next run-loop tick. The handler object itself is returned immediately (synchronously) for use in the current frame's `.multiGestureHandler()` modifier, while the binding writes and target setup happen safely outside the view update cycle.

**Files Modified:**
- `Packages/BoardEngine/Sources/BoardEngine/Gestures/BoardGestureIntegration.swift` — `setupAndReturnGestureHandler()` (lines 147-158): wrapped `gestureHandler = handler` and `setupGestureHandler()` in `DispatchQueue.main.async { ... }`

**Related Issues:**
- Discovered during ER-0034 (Multi-Board Support) verification

---

## DR-0097: Edge Selection Hit-Testing Unreliable — Clicks on Edges Frequently Fail to Select

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (macOS, iOS, visionOS)
**Component:** BoardEngine — BoardEdgeSelectionLayer, CanvasGestureTarget, BoardGestureIntegration
**Severity:** High
**Date Identified:** 2026-02-19
**Date Resolved:** 2026-02-19
**Date Verified:** 2026-02-19

**Description:**
Clicking on edges to select them was extremely difficult in both Cumberland's MurderBoard and the standalone MurderBoard app. Users often needed many clicks before an edge was selected, and sometimes edges could never be selected at all.

**Root Cause:**
`BoardEdgeSelectionLayer` used SwiftUI `.onTapGesture` on invisible `strokedPath` shapes overlaying each edge. However, `BoardGestureIntegration` applies a `DragGesture(minimumDistance: 0)` to the entire canvas, which captured the touch first. The edge `.onTapGesture` could only fire in the rare cases where the drag gesture didn't claim the interaction — making edge selection unreliable and inconsistent.

Additionally, the `strokedPath()` approach used a fixed view-space width (24pt) which scaled poorly with zoom level and had inconsistent hit zones depending on line angle.

**Resolution:**
Integrated edge hit-testing into the `MultiGestureHandler` tap flow so it goes through the same gesture system as node selection:

1. Added `edgeHitTest` and `onSelectEdge` callbacks to `CanvasGestureTarget`
2. When the canvas receives a tap, it first checks if the tap is near an edge using a proper perpendicular point-to-line-segment distance calculation with 20 world-unit tolerance
3. If an edge is within tolerance, `onSelectEdge` fires; otherwise falls through to deselect
4. Added `pointToSegmentDistance()` geometry helper — standard closest-point-on-segment algorithm
5. `BoardGestureIntegration` wires the hit-test closure using `BoardEdgesLayer.displayedEdges()` for edge geometry
6. Both `MurderBoardView` and `InvestigationBoardView` pass `onSelectEdge` to the gesture integration

**Files Modified:**
- `Packages/BoardEngine/Sources/BoardEngine/Gestures/CanvasGestureTarget.swift` — Added `edgeHitTest`, `onSelectEdge` callbacks; tap handler checks edges before deselecting
- `Packages/BoardEngine/Sources/BoardEngine/Gestures/BoardGestureIntegration.swift` — Added `onSelectEdge` parameter; wired `edgeHitTest` closure with point-to-segment distance; added `pointToSegmentDistance()` helper
- `Cumberland/Murderboard/MurderBoardView.swift` — Passes `onSelectEdge` to `BoardGestureIntegration`
- `MurderBoard/Views/InvestigationBoardView.swift` — Passes `onSelectEdge` to `BoardGestureIntegration`

---

## DR-0098: Complete Relationship Loss for Single Card

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardEdge / SwiftData Relationships
**Severity:** Critical

**Description:**
All CardEdge relationships for a single Card ("Alyson", a primary character) were spontaneously deleted. The card had edges to Scenes, Characters, a Project, the World, Timelines, and a MurderBoard. All edges were lost in a single event while all other cards' relationships remained intact.

**Root Cause:**
SwiftData's in-memory `@Relationship` arrays (`card.outgoingEdges`, `card.incomingEdges`) can transiently desynchronize from persisted edge records — arrays report empty while edges exist in SQLite. If any code path acts on the stale empty arrays (cascade delete, cleanup routine), actual persisted edges could be deleted.

Confirmed during ER-0035 testing: "DC Metro Area" showed 41/41 edges via FetchDescriptor but 0/0 via relationship arrays. The desync self-corrected on app relaunch.

**Resolution:**
Addressed across two ERs:

1. **ER-0035** (Verified) — Diagnostic tools: `[EdgeAudit]` logging on all edge deletion paths, `RelationshipAuditView` using FetchDescriptor, `changeCardType()` safety guard
2. **ER-0036** (Verified) — Live sentinel system: `cachedOutgoingEdgeCount`/`cachedIncomingEdgeCount` on Card, maintained by centralized RelationshipManager, desync detection at view entry points via `EdgeIntegrityMonitor`, `CumberlandBoardDataSource` FetchDescriptor fallback when arrays are empty but cached counts are non-zero

**Verification Notes:**
- Sentinel cached counts remain stable (41,41) even when SwiftData arrays desync to (0,0)
- `CumberlandBoardDataSource.edges(for:)` fallback correctly uses FetchDescriptor when desync detected
- Relationship arrays self-correct on fresh view load (SwiftData re-faults)
- All edge creation/deletion paths instrumented with increment/decrement
- RelationshipAuditView confirms integrity with fetch, array, and cached count columns

**Fix Date:** 2026-02-21
**Verification Date:** 2026-02-22

**Related Issues:**
- ER-0035: Relationship Diagnostic Tools and Safety Guards (verified)
- ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery (verified)

---

*Last Updated: 2026-02-22*
