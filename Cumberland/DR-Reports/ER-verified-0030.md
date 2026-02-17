# ER-0030: Select and Delete Relation Edges on Murderboard

**Status:** ✅ Verified
**Component:** Murderboard / BoardEngine
**Priority:** Medium
**Date Requested:** 2026-02-17
**Date Implemented:** 2026-02-17
**Date Verified:** 2026-02-17

## Summary

Added the ability to select and delete relationship edges directly on the Murderboard canvas. Users can click/tap an edge line to select it (with glow highlight and type label), right-click to get a delete popup, or press Delete/Backspace to trigger deletion with a confirmation dialog.

## Implementation Details

### Files Modified

**BoardEngine package:**

1. **`BoardEdgesLayer.swift`** — Added `selectedEdgeSourceTarget` parameter. Selected edge renders with a 12pt accent-color glow behind it and 5pt stroke width (vs 3pt normal). Made `DisplayedEdge` struct and `displayedEdges()` method public so the selection layer can reuse the same deduplication logic. Added `typeCode` to `DisplayedEdge`.

2. **`BoardCanvasView.swift`** — Added `selectedEdgeSourceTarget` and `onSelectEdge` parameters. Added `BoardEdgeSelectionLayer` to the Z-stack between edges layer and nodes layer.

3. **`BoardGestureIntegration.swift`** — Added `onCanvasBackgroundTap` callback (clears edge selection on background tap) and `onRightClickCanvas` callback (routes canvas right-clicks to edge hit-testing).

4. **`CanvasGestureTarget.swift`** — Now handles `.rightClick` gesture events (previously ignored). Calls `onRightClick` callback with location and coordinate info so canvas-level right-clicks can be processed for edge hit-testing.

**New file:**

5. **`BoardEdgeSelectionLayer.swift`** — Invisible hit-test overlay with 24pt-wide transparent `Path` strokes over each displayed edge. Uses `ForEach` + `onTapGesture` for tap-to-select. Shows the relationship type label (formatted from typeCode) at the midpoint of the selected edge. Uses `BoardEdgesLayer.displayedEdges()` for deduplication parity with the rendering layer.

**Cumberland Murderboard:**

6. **`MurderBoardView.swift`** — Added `selectedEdgeSourceTarget`, `selectedEdgeTypeCode`, and `showDeleteEdgeConfirmation` state properties. Added helper methods: `selectNode()`, `selectEdge()`, `clearEdgeSelection()`, `requestEdgeDeletion()`, `performEdgeDeletion()`, `deleteEdgePairDirectly()`, `handleCanvasRightClick()`, and `distanceFromPointToLineSegment()`. Selection is mutually exclusive (selecting a node clears edge selection and vice versa). Right-click on edges uses the existing `PopupMenu` system with distance-from-line-segment hit-testing (16pt threshold). Deletion deferred via `Task { @MainActor }` to avoid SwiftData snapshot crashes. Keyboard shortcuts: Delete/Backspace triggers deletion confirmation, Escape clears edge selection.

### Key Design Decisions

- **Hybrid approach**: Option A (invisible hit-test overlay) for tap-to-select, Option B (point-distance calculation) for right-click via the PopupMenu system. SwiftUI `.contextMenu` was not viable because the NSEvent monitors in `MultiGestureHandler` intercept right-clicks before the SwiftUI responder chain.
- **Edge selection uses source/target UUID pair** rather than edge ID because `CumberlandEdge.edgeID` is non-deterministic. The undirected pair is stable and matches deduplication logic.
- **Deferred deletion** via `Task { @MainActor }` avoids `_FullFutureBackingData` SwiftData snapshot crash during same-runloop `@Query` re-evaluation.
- **Mirror type code handling**: Direct modelContext deletion computes mirror code by swapping slash-separated parts (e.g., "owns/owned-by" -> "owned-by/owns").
