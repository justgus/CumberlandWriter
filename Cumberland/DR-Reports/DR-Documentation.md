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

Currently: **0 unverified DRs**

See: [DR-unverified.md](./DR-unverified.md)

### Verified DRs (Resolved Issues)

| Batch | DRs | File | Status |
|-------|-----|------|--------|
| Batch 1 | DR-0001 to DR-0010 | [DR-verified-0001-0010.md](./DR-verified-0001-0010.md) | ✅ All Verified |
| Batch 2 | DR-0011 to DR-0018 | [DR-verified-0011-0018.md](./DR-verified-0011-0018.md) | ✅ All Verified |

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

### DR-0011 to DR-0018 - Recent Work (Verified)

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

When a verified batch reaches ~10-15 DRs, create a new batch file:
1. Create `DR-verified-00XX-00YY.md`
2. Add new batch to the table above
3. Continue adding verified DRs to the new batch

## Statistics

- **Total DRs:** 18
- **Verified:** 18 (100%)
- **Unverified:** 0 (0%)
- **Latest DR:** DR-0018 (2026-01-01 - Verified)

---

*Last Updated: 2026-01-01*
*Document Version: 2.0 (Restructured for better organization)*
