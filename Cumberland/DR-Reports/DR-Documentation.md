# Discrepancy Reports (DR) - Index

This is the main index for all Cumberland Discrepancy Reports. DRs track bugs and unintended system behavior.

> **Note:** For planned improvements and new features, see [Enhancement Requests (ER)](./ER-Documentation.md)
>
> **Overview of both systems:** [README.md](./README.md)

DRs are organized into separate files for easier navigation and maintenance.

## Organization

- **DR-unverified.md** - Active, unresolved issues currently being investigated
- **DR-verified-XXXX-YYYY.md** - Resolved and verified issues in batches

## Quick Reference

### Unverified DRs (Active Issues)

Currently: **2 unverified DRs** (1 Not Resolved, 1 Resolved - Not Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0032 | Insufficient Sandy Beach Area Around Water Brushes | DrawCanvas/BrushEngine Water Rendering | 🔴 Not Resolved |
| DR-0031 | Advanced Brush Rendering Not Executed on Any Platform (Critical Architecture Issue) | DrawCanvas/BrushEngine Integration | 🟡 Resolved - Not Verified (macOS) |

See: [DR-unverified.md](./DR-unverified.md)

### Verified DRs (Resolved Issues)

Currently: **35 verified DRs** | Next available DR: **DR-0037**

| Batch | DRs | File | Status |
|-------|-----|------|--------|
| Batch 1 | DR-0001 to DR-0010 | [DR-verified-0001-0010.md](./DR-verified-0001-0010.md) | ✅ All Verified |
| Batch 2 | DR-0011 to DR-0020 | [DR-verified-0011-0020.md](./DR-verified-0011-0020.md) | ✅ All Verified |
| Batch 3 | DR-0021 to DR-0030 | [DR-verified-0021-0030.md](./DR-verified-0021-0030.md) | ✅ All Verified |
| Batch 4 | DR-0031 to DR-0040 | [DR-verified-0031-0040.md](./DR-verified-0031-0040.md) | 🚧 In Progress (5/10 verified) |

## DR Summary

### DR-0001 to DR-0010 - Early Issues

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0001 | DrawCanvas paints white for black on iOS | MapWizardView / DrawCanvas | ✅ Resolved |
| DR-0002 | Toolbar brush type selection not responding on iOS | DrawingCanvasView | ✅ Resolved |
| DR-0003 | Brush size control has no effect on iOS | DrawingCanvasView | ✅ Resolved |
| DR-0004 | Drawing ink color set to black appears as white on macOS | DrawingCanvasView | ✅ Resolved |
| DR-0005 | Backlog cards not appearing in Backlog Sidebar | BacklogSidebarPanel | ✅ Resolved |
| DR-0006 | Swimlane title editing creates duplicate cards | SwimlaneViewer | ✅ Resolved |
| DR-0007 | Duplicate swimlane cards appear after edits | SwimlaneViewer | ✅ Resolved |
| DR-0008 | Deleted swimlane structure still displays in UI | StoryStructureView | ✅ Resolved |
| DR-0009 | Deleting cards from Backlog does not update Backlog count | BacklogSidebarPanel | ✅ Resolved |
| DR-0010 | CloudKit sync fails silently without user feedback | Multiple Components | ✅ Resolved |

### DR-0011 to DR-0020 - Terrain Generation and Interior Maps (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0011 | Draft map work not persisting between sessions | MapWizardView | ✅ Verified |
| DR-0012 | Map wizard loses work when app backgrounds on iOS | MapWizardView | ✅ Verified |
| DR-0013 | Drawing changes not auto-saved; data loss on crash | MapWizardView | ✅ Verified |
| DR-0014 | Interior map presets don't apply grid settings | MapWizardView | ✅ Verified |
| DR-0015 | Grid type picker not working for interior maps | MapWizardView | ✅ Verified |
| DR-0016 | Procedural terrain generation system | DrawCanvas | ✅ Verified |
| DR-0016.2 | No map scale UI with floating tool palette | ToolsTabView | ✅ Verified |
| DR-0016.3 | Changing map scale should reseed terrain | ToolsTabView | ✅ Verified |
| DR-0016.4 | Water base layer produces no water | TerrainPattern | ✅ Verified |
| DR-0016.5 | Terrain regenerates on every pan/zoom | DrawingCanvasView | ✅ Verified |
| DR-0017 | Welcome step redundant with method selection | MapWizardView | ✅ Verified |
| DR-0018 | Terrain composition profiles and UI improvements | TerrainPattern | ✅ Verified |
| DR-0018.1 | Map scale resets when changing base layer | BaseLayerButton | ✅ Verified |
| DR-0018.2 | Water % resets when changing base layer | BaseLayerButton | ✅ Verified |
| DR-0019 | Interior map scale changes don't affect floor pattern size | ToolsTabView, BaseLayerPatterns | ✅ Verified |
| DR-0020 | Interior floor material selection resets map scale | BaseLayerButton | ✅ Verified |

### DR-0021 to DR-0030 - Layer System and UI Polish (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0021 | Layer visibility toggle not working | LayerManager, DrawingCanvasView | ✅ Verified |
| DR-0022 | Interior surfaces regenerate during pan/zoom | ProceduralPatternView | ✅ Verified |
| DR-0023 | Strokes not added to layers with visibility control | DrawingCanvasView, LayerManager | ✅ Verified |
| DR-0024 | Strokes deleted when autosave runs | DrawingCanvasView, AutoSave | ✅ Verified |
| DR-0024b | iOS canvas layers do not all display at once | DrawingCanvasView, LayerCompositeView | ✅ Verified |
| DR-0025 | iOS eye icon has no effect on layer visibility | LayerCompositeView | ✅ Verified |
| DR-0026 | Switching from Base Layer deletes strokes (iOS) | DrawingCanvasView, ER-0002 | ✅ Verified |
| DR-0027 | Masking panel obscures non-active layers (iOS) | LayerCompositeView | ✅ Verified |
| DR-0028 | Strokes dim and invert colors when layer not selected (iOS) | LayerCompositeView | ✅ Verified |
| DR-0029 | Base layer image recalculated on visibility toggle | BaseLayerImageCache | ✅ Verified |
| DR-0030 | Missing "Add Card" UI on iOS/misplaced Settings | MainAppView, CumberlandApp | ✅ Verified |

### DR-0032 to DR-0035 - macOS Drawing and Documentation (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0032 | All Brush Strokes Disappear After Several Seconds on macOS | DrawCanvas/exportCanvasState | ✅ Verified |
| DR-0033 | Duplicate Default Story Structures in Structure List | CumberlandApp/Seeding | ✅ Verified |
| DR-0033.1 | "Novel" Structure Still Has Duplicate Entry After Deduplication | CumberlandApp/Deduplication | ✅ Verified |
| DR-0034 | iOS Crash When Adding Layer After Draft Restore | DrawCanvas/PencilKitCanvasView | ✅ Verified |
| DR-0035 | DRs 0019-0030 Missing from DR-Documentation.md Index | DR-Documentation.md | ✅ Verified |

## How to Use This Documentation

### Adding a New DR

1. Add entry to **DR-unverified.md**
2. Follow the standard DR template
3. Update this index with the new DR in the Unverified section

### Resolving a DR

1. Complete the fix and document in the DR entry
2. Move the DR from DR-unverified.md to the appropriate DR-verified batch file
3. Update this index to reflect the change
4. Mark status as ✅ Resolved

### Creating a New Batch

When a verified batch file contains 10 DRs, create a new batch file:
1. Create `DR-verified-00XX-00YY.md` for the next 10 DRs
2. Add new batch to the table above
3. Continue adding verified DRs to the new batch

**Example:** When DR-0030 is verified, create `DR-verified-0031-0040.md` for the next batch

## Statistics

- **Total DRs:** 37
- **Verified:** 35 (95%) ✅
- **Resolved - Not Verified:** 1 (3%) 🟡
- **Open:** 1 (3%) 🔴
- **Latest DR:** DR-0032 (2026-01-08 - Insufficient Sandy Beach Area - OPEN)

---

*Last Updated: 2026-01-08*
*Document Version: 3.8 (Added DR-0032 - water brush beach sizing issue)*
