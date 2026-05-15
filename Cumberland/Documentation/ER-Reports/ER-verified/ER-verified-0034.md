# Enhancement Requests (ER) — Verified Batch 34

---

## ER-0034: Multi-Board Support

**Status:** ✅ Implemented - Verified
**Component:** MurderBoard — Board Management, Navigation, Data Model
**Priority:** P1
**Date Requested:** 2026-02-17
**Date Revised:** 2026-02-18
**Date Implemented:** 2026-02-18
**Date Verified:** 2026-02-18

**Rationale:**
MurderBoard currently creates boards implicitly — one per Card, via `Board.fetchOrCreatePrimaryBoard(for:in:)` (`Board.swift:149-165`). Users cannot create standalone boards, browse boards, or manage multiple canvases. This ER adds first-class board management with a content/detail navigation pattern.

**Current Behavior:**
- The `Board` model already exists (`Cumberland/Model/Board.swift`) with: `id: UUID`, `name: String`, `primaryCard: Card?`, `backlogKindRaw: String?`, `zoomScale`, `panX`, `panY`, and a cascade relationship to `[BoardNode]`.
- `BoardNode` links a `Card` to a `Board` with position (`posX`, `posY`), `zIndex`, `pinned`, and optional `sizeOverrideRaw` (`Board.swift:56-92`).
- Boards are created automatically when a user opens MurderBoardView for a card, tied to that card via `primaryCard` (`Board.swift:149-165`). Users never see a boards list.
- `MurderBoardView` takes a `primary: Card` parameter and fetches/creates the board for that card (`MurderBoardView.swift:22`).
- Cumberland's `MainAppView.swift` already uses a three-column `NavigationSplitView` with `columnVisibility` persistence, selection-driven detail, and per-Kind tab memory.

**Desired Behavior:**
Users can create, rename, and delete standalone boards. A boards list (content pane) lets users select a board, which opens in the detail pane. Existing per-card boards are preserved and accessible.

**Requirements:**
1. **Boards list UI**: Scrollable list of all boards showing name, card count (`board.nodes?.count`), and primary card name (if any). CRUD operations: create new board, rename (inline or sheet), delete with confirmation.
2. **Content/detail navigation**: `NavigationSplitView` on iPad/macOS (following `MainAppView.swift` pattern). `NavigationStack` on iPhone. Board selection drives the detail pane.
3. **Standalone boards**: Users can create boards not tied to any card (`primaryCard == nil`). These are general-purpose canvases.
4. **Preserve existing per-card boards**: `Board.fetchOrCreatePrimaryBoard(for:in:)` continues to work. Per-card boards appear in the boards list with their auto-generated name (e.g., "Aria Board").
5. **Last-selected board persistence**: `@AppStorage("MurderBoard.lastSelectedBoardID")` restores selection on launch.
6. **Safe deletion**: Confirm before delete. Deleting a board cascades to its `BoardNode` entries (already configured: `Board.nodes` has `.cascade` delete rule). Cards themselves are NOT deleted — only their placement on that board. If the board has a `primaryCard`, warn that the card's board view will be regenerated on next access.

**Implementation Summary (2026-02-18):**

Scope: Standalone MurderBoard app only (Cumberland integration unchanged).

Files created:
- `MurderBoard/Views/MurderBoardRootView.swift` — Root NavigationSplitView (iPad/macOS/visionOS) / NavigationStack (iPhone) with board selection persistence via `@AppStorage("MurderBoard.lastSelectedBoardID")`, first-launch seeding, and placeholder view.
- `MurderBoard/Views/BoardsListView.swift` — Boards list with `@Query`, CRUD (create/rename/delete), swipe-to-delete, context menu, rename alert, delete confirmation dialog, last-board deletion guard, empty state via `ContentUnavailableView`.
- `MurderBoard/Views/BoardRowView.swift` — Row view showing board name, node count, primary node name.

Files modified:
- `MurderBoard/DataSource/InvestigationDataSource.swift` — Added `loadBoard(_:)` method for direct board assignment (3 lines).
- `MurderBoard/Views/InvestigationBoardView.swift` — Added `init(board:)` and `init()` initializers with `initialBoard` property; `.task` block branches on whether a board was injected or needs to be fetched/created.
- `MurderBoard/MurderBoardApp.swift` — Replaced `NavigationStack { InvestigationBoardView() }` with `MurderBoardRootView()`.

No schema changes. No migration required.

**Notes:**
- Multi-window support (one window per board) is out of scope for this ER. File separately after the core boards list and navigation are stable.
- No schema migration is required — `InvestigationBoard.primaryNodeID` is already optional, and standalone boards are valid in the current schema.
- This ER should be implemented before ER-0032's "persist filters per board" feature, which depends on board identity being user-visible.

---

*Verified: 2026-02-18*
