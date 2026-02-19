# Enhancement Requests (ER) — Verified Batch 33

---

## ER-0033: Wire Gesture Callbacks in MurderBoard App

**Status:** ✅ Implemented - Verified
**Component:** MurderBoard App — Interaction Layer (`InvestigationBoardView.swift`)
**Priority:** P1 (blocks ER-0031 verification — backlog remains empty without node removal)
**Date Requested:** 2026-02-17
**Date Revised:** 2026-02-19
**Date Implemented:** 2026-02-19
**Date Verified:** 2026-02-19

**Rationale:**
The `BoardEngine` package provides a complete gesture system (`MultiGestureHandler`, `BoardGestureIntegration`, `NodeGestureTarget`, etc.), but the standalone MurderBoard app did not wire the right-click/context-menu callbacks needed for node interaction. Without these, users could not remove a node from the board or access context menus.

**Implementation Summary (2026-02-19):**

Files modified:
- `MurderBoard/Views/InvestigationBoardView.swift:162-171` — Wired `onRightClickNode` and `onRightClickCanvas` callbacks to `BoardGestureIntegration`
- `MurderBoard/Views/InvestigationBoardView.swift:312-372` — Added `handleNodeRightClick()` and `handleCanvasRightClick()` methods using BoardEngine's `PopupMenu` system
- `MurderBoard/DataSource/InvestigationDataSource.swift:296-313` — Added `deleteNodePermanently()` (hard delete with edge cleanup) and `setPrimaryNode()` methods
- `MurderBoard/DataSource/InvestigationDataSource.swift:359-364` — Added `fetchOrphanedNode()` helper

Node context menu actions:
- "Remove from Board" — soft-remove to backlog (ER-0031)
- "Set as Primary" — sets `board.primaryNodeID`
- "Delete Permanently" — hard delete with edge cleanup

Canvas context menu actions:
- "Add Node Here" — opens `NodeEditorSheet`

**Notes:**
- Context menus use BoardEngine's `PopupMenu` system (same as Cumberland's `MurderBoardView`)
- Primary node cannot be removed from board or deleted (actions disabled)

---

*Verified: 2026-02-19*
