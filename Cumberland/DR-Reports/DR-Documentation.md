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

**Archived Open DRs:**
See: [DR-archive-0038-0056.md](./DR-archive-0038-0056.md) for older open/unresolved DRs:
- DR-0055 (Resolved - Not Verified)
- DR-0054, DR-0043, DR-0041, DR-0040 (Open)
- DR-0038, DR-0039 (Archived Open)

**Current Unverified DRs:**
See: [DR-unverified.md](./DR-unverified.md)

### Verified DRs (Resolved Issues)

Currently: **52 verified DRs** (+ 1 closed/deferred) | Next available DR: **DR-0069**

| Batch | DRs | File | Status |
|-------|-----|------|--------|
| Batch 1 | DR-0001 to DR-0010 | [DR-verified-0001-0010.md](./DR-verified-0001-0010.md) | ✅ All Verified (10/10) |
| Batch 2 | DR-0011 to DR-0020 | [DR-verified-0011-0020.md](./DR-verified-0011-0020.md) | ✅ All Verified (10/10) |
| Batch 3 | DR-0021 to DR-0030 | [DR-verified-0021-0030.md](./DR-verified-0021-0030.md) | ✅ All Verified (10/10) |
| Batch 4 | DR-0031 to DR-0040 | [DR-verified-0031-0040.md](./DR-verified-0031-0040.md) | ✅ All Verified (10/10) |
| Batch 5 | DR-0041 to DR-0050 | [DR-verified-0041-0050.md](./DR-verified-0041-0050.md) | 🚧 In Progress (1/10 verified) |
| Batch 6 | DR-0051 to DR-0060 | [DR-verified-0051-0060.md](./DR-verified-0051-0060.md) | 🚧 In Progress (4/10 verified) |
| Batch 7 | DR-0061 to DR-0070 | [DR-verified-0061-0070.md](./DR-verified-0061-0070.md) | 🚧 In Progress (8/10 verified, 1 closed/deferred) |

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

### DR-0031 to DR-0056 - Advanced Brushes, macOS Drawing, OpenAI Integration, Relationships (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0031 | Advanced Brush Rendering Not Executed on Any Platform | DrawCanvas/BrushEngine Integration | ✅ Verified |
| DR-0032 | All Brush Strokes Disappear After Several Seconds on macOS | DrawCanvas/exportCanvasState | ✅ Verified |
| DR-0033 | Duplicate Default Story Structures in Structure List | CumberlandApp/Seeding | ✅ Verified |
| DR-0033.1 | "Novel" Structure Still Has Duplicate Entry After Deduplication | CumberlandApp/Deduplication | ✅ Verified |
| DR-0034 | iOS Crash When Adding Layer After Draft Restore | DrawCanvas/PencilKitCanvasView | ✅ Verified |
| DR-0035 | DRs 0019-0030 Missing from DR-Documentation.md Index | DR-Documentation.md | ✅ Verified |
| DR-0036 | Interior / Architectural Maps Header Controls Take Up Too Much Space on iPad | MapWizardView / Interior Configuration UI | ✅ Verified |
| DR-0037 | Insufficient Sandy Beach Area Around Water Brushes | DrawCanvas/BrushEngine Water Rendering | ✅ Resolved - Closed (Expanded to ER-0007) |
| DR-0042 | Apple Pencil Not Working with Gesture-Based Brushes on iOS | DrawingCanvasView / UIPanGestureRecognizer | ✅ Verified |
| DR-0050 | OpenAI Content Analysis Timeout with Default URLSession Settings | OpenAIProvider / Content Analysis | ✅ Verified |
| DR-0052 | OpenAI Entity Extraction Has Two Critical Bugs (0 Entities + Wrong Card Types) | OpenAIProvider / Content Analysis | ✅ Verified |
| DR-0056 | SuggestionEngine Only Creating Forward Relationships (Missing Reverse Edges) | SuggestionEngine, Phase 6 (ER-0010) | ✅ Verified |

### DR-0057 to DR-0068 - Temporal Editor Phase 2 & AI Analysis Fixes (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0057 | Calendar Extraction JSON Parser Fails on Null Length | CalendarSystemExtractor, AI Content Analysis | ✅ Verified |
| DR-0058 | SceneTemporalPositionEditor Calendar Values Don't Persist | SceneTemporalPositionEditor, ER-0016 Phase 2 | ✅ Verified |
| DR-0059 | SceneTemporalPositionEditor Duration Field Redesigned for Calendar Units | SceneTemporalPositionEditor, ER-0016 Phase 2 | ✅ Verified |
| DR-0060 | Duration Presets Use "Hours" Instead of Calendar-Specific Term | SceneTemporalPositionEditor, ER-0016 Phase 2 | ✅ Verified (Superseded by DR-0059) |
| DR-0061 | SceneTemporalPositionEditor Sheet Renders as Blank 100x100 Square (macOS) | SceneTemporalPositionEditor, TimelineChartView | ✅ Verified |
| DR-0062 | SceneTemporalPositionEditor Has Duplicate Save Buttons | SceneTemporalPositionEditor, ER-0016 Phase 2 | ✅ Verified |
| DR-0063 | Timeline Epoch Date UI Unclear/Not Persisting | CardEditorView, Timeline Configuration Panel | ✅ Verified |
| DR-0064 | Timeline Tab Freezes When Epoch Date Far from Scene Dates | TimelineChartView, ER-0016 Phase 2 | ✅ Verified |
| DR-0065 | Calendar Deletion Crash - Missing @Relationship Decorator | CalendarSystem Model, SwiftData Relationships | ✅ Verified |
| DR-0066 | Relationships Not Created When Analyzing Existing (Saved) Cards | SuggestionReviewView, AI Content Analysis | ✅ Verified |
| DR-0067 | Relationship Inference Not Detecting Patterns (Multiple Bugs) | RelationshipInference, AI Content Analysis Phase 6 | ⚪ Closed - Deferred to ER-0020 |
| DR-0068 | Calendar Insertion Bug - Inserting Both Card and CalendarSystem | SuggestionReviewView, SwiftData Relationship Insertion | ✅ Verified |

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

- **Total DRs:** 68 (documented)
- **Verified:** 52 (76.5%) ✅
- **Resolved - Not Verified:** 1 (1.5%) 🟡
  - DR-0055 (in archive)
- **Open:** 6 (8.8%) 🔴
  - Active: DR-0054, DR-0040, DR-0041, DR-0043 (in archive)
  - Archived: DR-0038, DR-0039
- **Closed/Deferred:** 2 (2.9%) ⚪
  - DR-0060 (superseded by DR-0059 redesign, now verified)
  - DR-0067 (closed, deferred to ER-0020 - Dynamic AI Relationship Extraction)
- **Latest DR:** DR-0068 (2026-01-30 - Calendar Insertion Bug) ✅ Verified (2026-01-31)

**Recent Activity:**
- 2026-01-31: **VERIFIED 3 DRs** (DR-0065, DR-0066, DR-0068) - Calendar and AI analysis fixes! 🎉
- 2026-01-31: **CLOSED DR-0067** - Deferred to ER-0020 (Dynamic AI Relationship Extraction) - Proper long-term solution
- 2026-01-31: Cleared DR-unverified.md - **ALL DRs resolved or archived!** 🎉
- 2026-01-30: **CREATED & RESOLVED DR-0068** - Calendar insertion bug (double-insert causing crash) ⚠️ CRITICAL
- 2026-01-30: **CREATED & RESOLVED DR-0067** - Relationship inference not detecting patterns (3 separate bugs) - HIGH severity
- 2026-01-30: **CREATED & RESOLVED DR-0066** - Relationships not created when analyzing existing (saved) cards - HIGH severity bug in AI content analysis
- 2026-01-30: **CREATED & RESOLVED DR-0065** - Calendar deletion crash (missing @Relationship decorator) ⚠️ CRITICAL
- 2026-01-30: **VERIFIED 8 DRs** (DR-0057 through DR-0064) - Temporal Editor Phase 2 complete! 🎉
- 2026-01-30: Created batch files DR-verified-0051-0060.md and DR-verified-0061-0070.md
- 2026-01-30: Cleared DR-unverified.md after verifying DR-0057 through DR-0064
- 2026-01-29: Created DR-0064 (timeline freeze with 179-year range) - **CRITICAL FIX**
- 2026-01-29: DR-0063 root cause found - **DatePicker showing date but not setting property**
- 2026-01-29: DR-0058 root cause identified - **timeline missing epoch date** (added critical warnings)

---

*Last Updated: 2026-01-31*
*Document Version: 7.0 (DR-0065, 0066, 0068 verified; DR-0067 closed/deferred to ER-0020)*
