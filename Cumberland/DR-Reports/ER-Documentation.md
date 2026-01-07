# Enhancement Requests (ER) - Index

This is the main index for all Cumberland Enhancement Requests. ERs track planned improvements, new features, and requirement changes to the system.

## Organization

- **ER-Guidelines.md** - Rules, templates, and workflow for ER management
- **ER-unverified.md** - Proposed and implemented-but-unverified enhancements
- **ER-verified-XXXX-YYYY.md** - Batches of verified enhancements

## Quick Reference

### Unverified ERs (Active & Proposed)

Currently: **2 active ERs**

| ER | Title | Component | Status | Date Implemented |
|----|-------|-----------|--------|------------------|
| ER-0003 | Integrate Exterior Brush System | DrawCanvas, BrushEngine, ToolPalette | 🟡 Implemented - Not Verified | 2026-01-07 |
| ER-0004 | Interior Brush Implementation | BrushRegistry, InteriorMapBrushSet | 🟡 Implemented - Not Verified | 2026-01-07 |

See: [ER-unverified.md](./ER-unverified.md)

### Verified ERs (Completed Enhancements)

| ER | Title | Component | Status | Date Verified |
|----|-------|-----------|--------|---------------|
| ER-0001 | Interior vs Exterior Canvas Differentiation | DrawCanvas, ToolsTabView, BaseLayerButton | ✅ Verified | 2026-01-03 |
| ER-0002 | Base Layer should not receive strokes | DrawingCanvasView, DrawingCanvasViewMacOS, LayerManager | ✅ Verified | 2026-01-06 |

See: [ER-verified-0001.md](./ER-verified-0001.md)

## ER Summary

### ER-0001 - Interior vs Exterior Canvas Differentiation

**Component:** DrawCanvas, ToolsTabView, BaseLayerButton, TerrainPattern
**Status:** 🟡 Implemented - Not Verified
**Priority:** High
**Date Requested:** 2026-01-01

**Summary:**
Differentiate between Interior and Exterior map types by:
- Filtering base layer dropdowns to show only relevant options (exterior terrains vs interior floors)
- Removing water percentage slider for interior maps
- Displaying scale in feet (interior) vs miles (exterior)
- Implementing fixed-scale floor patterns that don't change size with map scale
- Creating realistic 6-inch wood plank pattern for interior flooring

**Key Requirements:**
1. Context-aware base layer menu filtering
2. Interior-specific UI adjustments (scale units, hide water %)
3. Fixed-scale floor pattern rendering
4. Wood plank pattern generation
5. Map type persistence across save/load

## How to Use This Documentation

### Creating a New ER

1. Add entry to **ER-unverified.md** using the template from ER-Guidelines.md
2. Set status to 🔵 Proposed
3. Complete the analysis and design sections before implementing
4. Update this index with the new ER in the Unverified section

### Implementing an ER

1. Update status to 🟡 In Progress when starting work
2. Complete the implementation
3. Mark as 🟡 Implemented - Not Verified when code is ready
4. Provide clear test steps for user verification

### Verifying an ER

1. User tests the enhancement following the test steps
2. **Only user** can mark as ✅ Implemented - Verified
3. Move the ER from ER-unverified.md to appropriate batch file
4. Update this index to reflect the change

### Creating a New Batch

When a verified batch reaches ~10-15 ERs, create a new batch file:
1. Create `ER-verified-00XX-00YY.md`
2. Add new batch to the table above
3. Continue adding verified ERs to the new batch

## ER vs DR

Use the right system for the task:

| Scenario | System | Reason |
|----------|--------|--------|
| Bug or defect | DR | System not working as intended |
| Missing feature | ER | New requirement or capability |
| Performance issue | DR | System not meeting quality standards |
| UI/UX improvement | ER | Planned enhancement to user experience |
| Code refactoring | ER | Technical debt reduction or architecture improvement |
| Crash or error | DR | System failure |
| New workflow | ER | Adding new capability |

## Statistics

- **Total ERs:** 4
- **Verified:** 2 (50%)
- **Implemented - Not Verified:** 2
- **In Progress:** 0
- **Proposed:** 0
- **Latest ER:** ER-0004 (2026-01-07 - Implemented - Interior Brush System)

---

*Last Updated: 2026-01-07*
*Document Version: 1.3 (Implemented ER-0004 - Interior brush system enabled)*
