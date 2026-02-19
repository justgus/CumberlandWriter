# Enhancement Requests (ER) — Verified Batch 31

---

## ER-0031: Enhance Existing Backlog Sidebar

**Status:** ✅ Implemented - Verified
**Component:** MurderBoard — Backlog Sidebar (`SidebarPanel.swift`, `MurderBoardView.swift`, `InvestigationBoardView.swift`)
**Priority:** P1
**Date Requested:** 2026-02-17
**Date Revised:** 2026-02-19
**Date Implemented:** 2026-02-19
**Date Verified:** 2026-02-19

**Rationale:**
The MurderBoard backlog sidebar (`SidebarPanel` in `Cumberland/SidebarPanel.swift`) displays cards not on the board with kind-based filtering, multi-select, and drag-to-canvas. However, it lacks detail navigation, swipe actions, and a richer per-row information display. This ER enhances the existing sidebar rather than rebuilding it.

Additionally, the **standalone MurderBoard app** (`MurderBoard/`) had no backlog sidebar at all. Its `InvestigationBoardView` provided only a canvas and an "Add Node" toolbar button for creating nodes from scratch. There was no way to browse existing nodes that aren't on the board, no sidebar toggle button, and no drag-from-sidebar-to-canvas workflow.

**Implementation Summary (Standalone MurderBoard App — 2026-02-19):**

Files modified:
- `MurderBoard/Model/InvestigationNode.swift:108-143` — Added `InvestigationNodeTransferData` (Codable, Sendable, Transferable), `UTType.investigationNodeReference`, and `InvestigationNode.transferData()` convenience factory
- `MurderBoard/DataSource/InvestigationDataSource.swift:266-269` — Changed `removeNode()` from `modelContext.delete(node)` to `node.board = nil` (soft-remove)
- `MurderBoard/DataSource/InvestigationDataSource.swift:110-116` — Implemented `backlogItems` to fetch nodes where `board == nil || board.id != currentBoardID` (per-board backlog with NULL handling)
- `MurderBoard/DataSource/InvestigationDataSource.swift:272-292` — Implemented `addNodes()` to re-attach orphaned nodes with angular position spread
- `MurderBoard/DataSource/InvestigationDataSource.swift:318-335` — Added `fetchBacklogNodes()` and `edgeCount(for:)` helper methods
- `MurderBoard/DataSource/InvestigationDataSource.swift` — Changed `createNode()` to not assign board (new nodes go to backlog)
- `MurderBoard/DataSource/InvestigationDataSource.swift` — Changed `edges(for:)` to be global — returns edges where both endpoints are in the provided node set, regardless of `edge.board`
- `MurderBoard/DataSource/InvestigationDataSource.swift` — Changed `createEdge` and `makeEdge` to not assign board to edges
- `MurderBoard/Views/InvestigationBoardView.swift:55-57` — Added sidebar state: `isSidebarVisible`, `selectedCategoryFilter`, `detailNode`, `selectedBacklogNodeIDs`
- `MurderBoard/Views/InvestigationBoardView.swift:61-78` — Added `backlogNodes` computed property and `addBacklogNodesToBoard()` helper
- `MurderBoard/Views/InvestigationBoardView.swift:125-136` — Added `.dropDestination` for `InvestigationNodeTransferData` with multi-select support
- `MurderBoard/Views/InvestigationBoardView.swift:167-185` — Integrated `InvestigationSidebarPanel` in ZStack
- `MurderBoard/Views/InvestigationBoardView.swift:293-302` — Added `.sheet(item: $detailNode)` for node detail inspection
- `MurderBoard/Views/InvestigationNodeView.swift` — Added `BoardNodeVisualSizesKey` preference reporting (required for gesture target registration)

Files created:
- `MurderBoard/Views/InvestigationSidebarPanel.swift` — Collapsible backlog sidebar with toggle button, category filter menu, node list with multi-select checkmarks, drag-to-canvas, edge count badges, info button for detail, tap-to-deselect empty space, glass effect styling
- `MurderBoard/Views/InvestigationNodeDetailSheet.swift` — Node detail sheet with category badge and "Add to Board" button

Key design decisions:
- Soft-remove via `node.board = nil` — no schema migration needed
- Per-board backlog: shows ALL nodes not on the current board (including orphans and nodes on other boards), with explicit `$0.board == nil || $0.board?.id != currentBoardID` predicate to handle SQL NULL semantics
- Edges are global relationships (not board-scoped) — if both endpoint nodes are on a board, the edge appears
- New nodes go to backlog by default (must be explicitly added to a board)
- Selection via dedicated checkmark button (not `.onTapGesture` on row) to preserve `.draggable` functionality
- Multi-select: selected nodes are batch-added when any selected node is dragged onto the board
- UTType without Info.plist — failable `UTType("...")` with `.json` fallback
- `blockInvestigationCanvasGestures()` duplicated for MurderBoard target (separate from Cumberland's `blockCanvasGestures()`)

---

*Verified: 2026-02-19*
