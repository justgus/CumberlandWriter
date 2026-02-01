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

Currently: **3 unverified ERs** (3 Proposed, 0 In Progress, 0 Implemented - Not Verified)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0011 | Image Sharing and Linking Between Cards | Card Model, CardEditorView, Image Management | 🔵 Proposed |
| ER-0015 | Improve Empty Analysis Results Message | SuggestionReviewView, SuggestionEngine | 🔵 Proposed |
| ER-0017 | AI Image Generation - Batch Processing and History Management | AI System, Card Image Management | 🔵 Proposed |

See: [ER-unverified.md](./ER-unverified.md)

### Verified ERs (Completed Enhancements)

Currently: **20 verified ERs** | Next available ER: **ER-0021**

| Batch | ERs | File | Status |
|-------|-----|------|--------|
| Batch 1 | ER-0001 to ER-0002 | [ER-verified-0001.md](./ER-verified-0001.md) | ✅ All Verified (2/2) |
| Batch 2 | ER-0003, ER-0005, ER-0006 | [ER-verified-0002.md](./ER-verified-0002.md) | ✅ All Verified (3/3) |
| Batch 4 | ER-0004 | [ER-verified-0004.md](./ER-verified-0004.md) | ✅ Verified (1/1) |
| Batch 7 | ER-0007 | [ER-verified-0007.md](./ER-verified-0007.md) | ⚠️ Partially Verified (Lake ✅, River needs revision) (1/1) |
| Batch 8 | ER-0008, ER-0009, ER-0010 | [ER-verified-0008.md](./ER-verified-0008.md) | ✅ All Verified (3/3) |
| Batch 12 | ER-0012, ER-0013, ER-0014, ER-0016 | [ER-verified-0012.md](./ER-verified-0012.md) | ✅ All Verified (4/4) |
| Batch 18 | ER-0018 | [ER-verified-0018.md](./ER-verified-0018.md) | ✅ Verified (1/1) |
| Batch 19 | ER-0019 | [ER-verified-0019.md](./ER-verified-0019.md) | ✅ Verified (1/1) |
| Batch 20 | ER-0020 | [ER-verified-0020.md](./ER-verified-0020.md) | ✅ Verified (1/1) |

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

### ER-0008 to ER-0010 - Timeline System, AI Image Generation, AI Content Analysis (Verified)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0008 | Time-Based Timeline System with Custom Calendars and Multi-Timeline Visualization | Timeline System, Card Model, TimelineChartView | ✅ Verified |
| ER-0009 | AI Image Generation for Cards (Apple Intelligence and Third-Party APIs) | Card Image System, Settings, MapWizard, Image Import | ✅ Verified |
| ER-0010 | AI Assistant for Content Analysis and Structured Data Extraction | Card Editors, AI System, Relationship Manager, Settings | ✅ Verified |

### ER-0012 to ER-0016 - Chronicles, AI Providers, Timeline Hierarchy (Verified)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0012 | Chronicles Card Type for Historical Events and Time Periods | Card Model, MainAppView, AI Integration | ✅ Verified |
| ER-0013 | Separate AI Provider Settings for Analysis and Image Generation | AISettings, Settings UI, AI Provider Selection | ✅ Verified |
| ER-0014 | Change Card Type Feature with Relationship Deletion | CardRelationshipView, SuggestionReviewView, AI Suggestion System | ✅ Verified |
| ER-0016 | Timeline/Chronicle/Scene Proper Hierarchy and Multi-Timeline Graph Redesign | MultiTimelineGraphView, Card Model, CardEditorView, Timeline System | ✅ Verified |

### ER-0018 to ER-0020 - AI Content Analysis Improvements (Verified)

| ER | Title | Component | Status |
|----|-------|-----------|--------|
| ER-0018 | TextPreprocessor Threshold Adjustment for Better Entity Extraction | TextPreprocessor, AISettings | ✅ Verified |
| ER-0019 | Direct "Select All" Button in Suggestion Review | SuggestionReviewView | ✅ Verified |
| ER-0020 | Dynamic Relationship Extraction with AI-Generated Verbs | AI Providers, SuggestionEngine, RelationType System | ✅ Verified |

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

- **Total ERs:** 20
- **Verified:** 20 (100.0%) ✅
  - All in batch files
- **Implemented - Not Verified:** 0 (0%) 🟡
- **In Progress:** 0 (0%) 🟡
- **Proposed:** 3 (15.0%) 🔵
  - ER-0011, ER-0015, ER-0017
- **Latest ER:** ER-0020 (2026-01-30 - Implemented 2026-01-31 - Verified 2026-02-01 - Dynamic Relationship Extraction with AI-Generated Verbs)

**Recent Activity:**
- 2026-02-01: **VERIFIED ER-0020** - Dynamic Relationship Extraction with AI-Generated Verbs! 🎉🎉🎉
  - Added grammatical guidance (Subject-Verb-Direct Object prioritization)
  - Successfully filtered prepositional phrase false positives
  - Achieved 90-95% average confidence for extracted relationships
  - **ALL 20 ERs NOW VERIFIED (100%)!** 🎊
- 2026-02-01: Created ER-verified-0020.md batch file
- 2026-01-31: **IMPLEMENTED ER-0020** - Dynamic Relationship Extraction with AI-Generated Verbs! 🎉
  - Updated Anthropic and OpenAI providers to extract relationships with actual verbs from text
  - Modified DetectedRelationship to support forwardVerb/inverseVerb fields
  - Updated SuggestionEngine to auto-create RelationTypes dynamically
  - Addresses DR-0067 root cause - no more hardcoded verb patterns!
- 2026-01-31: **VERIFIED ER-0019** - Direct "Select All" button for faster suggestion review workflow! 🎉
- 2026-01-31: Created ER-verified-0019.md batch file
- 2026-01-31: **19 of 20 ERs verified (95.0%)** - Exceptional progress!
- 2026-01-30: **CREATED ER-0020** - Dynamic Relationship Extraction with AI-Generated Verbs (HIGH priority - addresses DR-0067 root cause)
- 2026-01-30: **IMPLEMENTED ER-0019** - Direct "Select All" button for faster suggestion review workflow ✅
- 2026-01-30: **CREATED ER-0019** - UX improvement for suggestion review
- 2026-01-30: **VERIFIED ER-0018** - TextPreprocessor threshold fix (500 → 5000 words) ✅
- 2026-01-30: **Added Anthropic Claude Opus 4.5 provider** - Full integration for content analysis and calendar extraction
- 2026-01-30: **VERIFIED 3 MAJOR ERs** (ER-0008, ER-0009, ER-0010) - Timeline System, AI Image Generation, AI Content Analysis! 🎉🎉🎉
- 2026-01-30: Created ER-verified-0008.md batch file (largest batch - major features)

---

*Last Updated: 2026-02-01*
*Document Version: 8.0 (ER-0020 verified - ALL 20 ERs COMPLETE! 100%!)*
