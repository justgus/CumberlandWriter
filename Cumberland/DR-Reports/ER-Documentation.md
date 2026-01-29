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

Currently: **10 unverified ERs** (3 Proposed, 1 In Progress, 3 Implemented - Not Verified, 3 Verified Awaiting Move)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0008 | Time-Based Timeline System with Custom Calendars and Multi-Timeline Visualization | Timeline System, Card Model, TimelineChartView | 🟡 Implemented - Not Verified |
| ER-0009 | AI Image Generation for Cards (Apple Intelligence and Third-Party APIs) | Card Image System, Settings, MapWizard, Image Import | 🟡 Implemented - Not Verified |
| ER-0010 | AI Assistant for Content Analysis and Structured Data Extraction | Card Editors, AI System, Relationship Manager, Settings | 🟡 Implemented - Not Verified |
| ER-0011 | Image Sharing and Linking Between Cards | Card Model, CardEditorView, Image Management | 🔵 Proposed |
| ER-0012 | Chronicles Card Type for Historical Events and Time Periods | Card Model, MainAppView, AI Integration | ✅ Verified (awaiting move) |
| ER-0013 | Separate AI Provider Settings for Analysis and Image Generation | AISettings, Settings UI, AI Provider Selection | ✅ Verified (awaiting move) |
| ER-0014 | Change Card Type Feature with Relationship Deletion | CardRelationshipView, SuggestionReviewView | ✅ Verified (awaiting move) |
| ER-0015 | Improve Empty Analysis Results Message | SuggestionReviewView, SuggestionEngine | 🔵 Proposed |
| ER-0016 | Timeline/Chronicle/Scene Proper Hierarchy and Multi-Timeline Graph Redesign | MultiTimelineGraphView, Card Model, CardEditorView | 🟡 In Progress (Phase 1 Implemented) |
| ER-0017 | AI Image Generation - Batch Processing and History Management | AI System, Card Image Management | 🔵 Proposed |

See: [ER-unverified.md](./ER-unverified.md)

### Verified ERs (Completed Enhancements)

Currently: **10 verified ERs** (7 in batches, 3 awaiting move) | Next available ER: **ER-0018**

| Batch | ERs | File | Status |
|-------|-----|------|--------|
| Batch 1 | ER-0001 to ER-0002 | [ER-verified-0001.md](./ER-verified-0001.md) | ✅ All Verified |
| Batch 2 | ER-0003, ER-0005, ER-0006 | [ER-verified-0002.md](./ER-verified-0002.md) | ✅ All Verified |
| Batch 4 | ER-0004 | [ER-verified-0004.md](./ER-verified-0004.md) | ✅ Verified |
| Batch 7 | ER-0007 | [ER-verified-0007.md](./ER-verified-0007.md) | ⚠️ Partially Verified (Lake ✅, River needs revision) |

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

### ER-0004 - Interior Brush System

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0004 | Interior Brush Implementation | BrushRegistry, InteriorMapBrushSet, BrushEngine | ✅ Verified |

### ER-0007 - Map Rendering Unification

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0007 | Unify Map Rendering - Base Layer and Brushes Should Produce Identical Features | BrushEngine, TerrainPattern, BaseLayerRendering | ⚠️ Partially Verified (Lake ✅, River needs future revision) |

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

- **Total ERs:** 17
- **Verified:** 10 (58.8%) ✅
  - In batches: 7
  - Awaiting move: 3 (ER-0012, ER-0013, ER-0014)
- **Implemented - Not Verified:** 3 (17.6%) 🟡
  - ER-0008 (Timeline System)
  - ER-0009 (AI Image Generation)
  - ER-0010 (AI Content Analysis)
- **In Progress:** 1 (5.9%) 🟡
  - ER-0016 (Phase 1 complete)
- **Proposed:** 3 (17.6%) 🔵
  - ER-0011, ER-0015, ER-0017
- **Latest ER:** ER-0017 (2026-01-29 - Proposed - AI Batch Generation & History)

**Recent Activity:**
- 2026-01-29: Created ER-0017 for deferred batch/history features from ER-0009
- 2026-01-29: Marked ER-0008, ER-0009, ER-0010 as Implemented - Not Verified (Phases 1-8 complete)
- 2026-01-29: Closed ER-0006 (regression resolved separately)

---

*Last Updated: 2026-01-29*
*Document Version: 3.0 (Major update: ER-0008/0009/0010 implementation complete, ER-0017 created)*
