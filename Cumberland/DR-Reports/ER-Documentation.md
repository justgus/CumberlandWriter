# Enhancement Requests (ER) - Index

This is the main index for all Cumberland Enhancement Requests. ERs track planned improvements, new features, and requirement changes to the system.

> **Note:** For bugs and unintended behavior, see [Discrepancy Reports (DR)](./DR-Documentation.md)
>
> **Overview of both systems:** [README.md](./README.md)

ERs are organized into separate files for easier navigation and maintenance.

## Organization

- **ER-unverified.md** - Proposed, in-progress, and implemented-but-unverified enhancements
- **ER-verified-XXXX.md** - Verified enhancements in batches

## Quick Reference

### Unverified ERs (Active & Proposed)

Currently: **2 unverified ERs** (1 Proposed, 1 Implemented - Not Verified)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0007 | Unify Map Rendering - Base Layer and Brushes | BrushEngine, TerrainPattern | 🔵 Proposed |
| ER-0004 | Interior Brush Implementation | BrushRegistry, InteriorMapBrushSet, BrushEngine | 🟡 Implemented - Not Verified (macOS complete, iOS pending) |

See: [ER-unverified.md](./ER-unverified.md)

### Verified ERs (Completed Enhancements)

Currently: **5 verified ERs** | Next available ER: **ER-0008**

| Batch | ERs | File | Status |
|-------|-----|------|--------|
| Batch 1 | ER-0001 to ER-0002 | [ER-verified-0001.md](./ER-verified-0001.md) | ✅ All Verified |
| Batch 2 | ER-0003, ER-0005, ER-0006 | [ER-verified-0002.md](./ER-verified-0002.md) | ✅ All Verified |

## ER Summary

### ER-0001 to ER-0002 - Core Canvas Features

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0001 | Interior vs Exterior Canvas Differentiation | DrawCanvas, ToolsTabView, BaseLayerButton | ✅ Verified |
| ER-0002 | Base Layer Should Not Receive Strokes | DrawingCanvasView, DrawingCanvasViewMacOS, LayerManager | ✅ Verified |

### ER-0003, ER-0005, ER-0006 - Brush System Integration

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0003 | Integrate Exterior Brush System | DrawCanvas, BrushEngine, ToolPalette | ✅ Verified |
| ER-0005 | Remove Redundant Water Brush Types | ExteriorMapBrushSet | ✅ Verified |
| ER-0006 | Display Working Indicator During Base Layer Rendering | MapWizardView, BaseLayerButton, ToolsTabView | ✅ Verified |

## How to Use This Documentation

### Adding a New ER

1. Add entry to **ER-unverified.md**
2. Follow the standard ER template
3. Update this index with the new ER in the Unverified section

### Implementing an ER

1. Update status to 🟡 In Progress when starting work
2. Complete the implementation
3. Mark as 🟡 Implemented - Not Verified when code is ready
4. Provide clear test steps for user verification

### Verifying an ER

1. User tests the enhancement following the test steps
2. **Only user** can mark as ✅ Implemented - Verified
3. Move the ER from ER-unverified.md to the appropriate ER-verified batch file
4. Update this index to reflect the change
5. Mark status as ✅ Verified

### Creating a New Batch

When a verified batch file contains multiple ERs (flexible batching), create a new batch file:
1. Create `ER-verified-00XX.md` for the next batch
2. Add new batch to the table above
3. Continue adding verified ERs to the new batch

**Example:** When ER-verified-0002.md has sufficient content, create `ER-verified-0003.md` for the next batch

## Statistics

- **Total ERs:** 7
- **Verified:** 5 (71%) ✅
- **Implemented - Not Verified:** 1 (14%) 🟡
- **In Progress:** 0 (0%)
- **Proposed:** 1 (14%) 🔵
- **Latest ER:** ER-0007 (2026-01-09 - Proposed - Unify Map Rendering)

---

*Last Updated: 2026-01-10*
*Document Version: 2.2 (Re-implemented ER-0004 - macOS pattern-based rendering complete)*
