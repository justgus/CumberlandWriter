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

Currently: **0 open DRs** | **0 resolved, awaiting verification**

*All DRs from ER-0022 Phase 5 testing have been verified!*

**Recently Verified (2026-02-09):**
| DR | Title | Status |
|----|-------|--------|
| DR-0076 | No Edge Creation UI in MurderBoardView | ✅ Verified |
| DR-0077 | No Search or Filter UI in All Cards List | ✅ Verified |
| DR-0078 | No Image Export UI | ✅ Verified |
| DR-0082 | No Citation UI for Non-Image Citations | ✅ Verified |
| DR-0083 | MurderBoard Backlog Scroll Propagates to Canvas | ✅ Verified |

**Previously Verified (2026-02-08):**
| DR | Title | Status |
|----|-------|--------|
| DR-0079 | Multi-Select Only Performs Batch Image Generation | ✅ Verified |
| DR-0080 | No Multi-Card Deletion UI | ✅ Verified |
| DR-0081 | No Card Duplication UI | ✅ Verified |

**Archived Open DRs:**
See: [DR-archive-0038-0056.md](./DR-archive-0038-0056.md) for older open/closed DRs:
- DR-0043, DR-0041 (Open - deferred per user)
- DR-0038 (Open - deferred per user)
- DR-0039 (Closed - OBE)
- DR-0040 (Resolved - expanded scope, awaiting verification)

**Current Unverified DRs:**
See: [DR-unverified.md](./DR-unverified.md)

### Verified DRs (Resolved Issues)

Currently: **69 verified DRs** | Next available DR: **DR-0084**

**Latest DRs:**
- DR-0075: Cannot Reuse Original Prompt After Failed Visual Element Extraction (2026-02-05) - ✅ Verified
- DR-0074: Image Views Not Refreshing When Image Updated or Switched from History (2026-02-05) - ✅ Verified
- DR-0073: VisualElementReviewView Sheet Does Not Resize When Advanced Options Expanded (2026-02-04) - ✅ Verified

| Batch | DRs | File | Status |
|-------|-----|------|--------|
| Batch 1 | DR-0001 to DR-0010 | [DR-verified-0001-0010.md](./DR-verified-0001-0010.md) | ✅ All Verified (10/10) |
| Batch 2 | DR-0011 to DR-0020 | [DR-verified-0011-0020.md](./DR-verified-0011-0020.md) | ✅ All Verified (10/10) |
| Batch 3 | DR-0021 to DR-0030 | [DR-verified-0021-0030.md](./DR-verified-0021-0030.md) | ✅ All Verified (10/10) |
| Batch 4 | DR-0031 to DR-0040 | [DR-verified-0031-0040.md](./DR-verified-0031-0040.md) | ✅ All Verified (10/10) |
| Batch 5 | DR-0041 to DR-0050 | [DR-verified-0041-0050.md](./DR-verified-0041-0050.md) | 🚧 In Progress (1/10 verified) |
| Batch 6 | DR-0051 to DR-0060 | [DR-verified-0051-0060.md](./DR-verified-0051-0060.md) | 🚧 In Progress (8/10 verified) |
| Batch 7 | DR-0061 to DR-0070 | [DR-verified-0061-0070.md](./DR-verified-0061-0070.md) | 🚧 In Progress (6/10 verified) |
| Batch 8 | DR-0071 to DR-0080 | [DR-verified-0071-0080.md](./DR-verified-0071-0080.md) | 🚧 In Progress (9/10 verified) |
| Batch 9 | DR-0081 to DR-0090 | [DR-verified-0081-0090.md](./DR-verified-0081-0090.md) | 🚧 In Progress (3/10 verified) |

### Closed DRs (Not Verified)

These DRs were closed without verification for various reasons (external limitations, design changes, superseded by other work).

Currently: **4 closed DRs**

| Batch | DRs | File | Reason |
|-------|-----|------|--------|
| Closed 061-070 | DR-0069 | [DR-closed-061-070.md](./DR-closed-061-070.md) | External limitation (AI provider safety filters) |
| Closed 071-080 | DR-0071, DR-0072, DR-0073 | [DR-closed-071-080.md](./DR-closed-071-080.md) | Will be addressed by ER-0021 (DR-0071), Verified and closed (DR-0072, DR-0073) |

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
| DR-0055 | Relationship Creation Timing Issue - Cancel Button Behaves Like Save | SuggestionReviewView, CardEditorView, Phase 6 (ER-0010) | ✅ Verified |
| DR-0056 | SuggestionEngine Only Creating Forward Relationships (Missing Reverse Edges) | SuggestionEngine, Phase 6 (ER-0010) | ✅ Verified |

### DR-0040 to DR-0068 - iOS Layout, Temporal Editor Phase 2 & AI Analysis Fixes (Verified)

| DR | Title | Component | Status |
|----|-------|-----------|--------|
| DR-0040 | Button Text Overflow on iOS (Icon-Only Button Solution) | CardEditorView, BrushGridView / Tool Palette | ✅ Verified |
| DR-0054 | Edit Card Sheet on iOS - Save/Cancel Buttons Pushed Off-Screen | CardEditorView | ✅ Verified |
| DR-0055 | Relationship Creation Timing Issue - Cancel Button Behaves Like Save | SuggestionReviewView, CardEditorView, Phase 6 (ER-0010) | ✅ Verified |
| DR-0056 | SuggestionEngine Only Creating Forward Relationships (Missing Reverse Edges) | SuggestionEngine, Phase 6 (ER-0010) | ✅ Verified |
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

- **Total DRs:** 83 (documented)
- **Verified:** 69 (83.1%) ✅
- **Resolved - Not Verified:** 0 (0%) 🟡
- **Open:** 3 (3.6%) 🔴
  - DR-0043 (Duplicate RelationType entries) - deferred per user
  - DR-0041 (Vegetation brushes should render as area fills) - deferred per user
  - DR-0038 (Draft interior drawing settings not remembered) - deferred per user
  - All 3 in archive
- **Closed/Deferred:** 5 (6.0%) ⚪
  - DR-0071 (closed 2026-02-03 - Will be addressed by ER-0021: AI Visual Element Extraction)
  - DR-0069 (closed 2026-02-03 - Known Issue: OpenAI safety filter limitation, external)
  - DR-0060 (superseded by DR-0059 redesign, now verified)
  - DR-0067 (closed, deferred to ER-0020 - Dynamic AI Relationship Extraction)
  - DR-0039 (closed - OBE, fixed by draft persistence improvements)
- **Latest DR:** DR-0083 (2026-02-08 - MurderBoard Backlog Scroll Propagates to Canvas) ✅ Verified
- **Latest Verified:** DR-0076/0077/0078/0082/0083 (2026-02-09 - ER-0022 Phase 5 UI fixes) ✅ Verified

**Recent Activity:**
- 2026-02-09: **VERIFIED 5 DRs** (DR-0076, DR-0077, DR-0078, DR-0082, DR-0083) - ER-0022 Phase 5 Complete! ✅
  - **DR-0076:** Edge creation UI with bidirectional edge support, sheet(item:) pattern fix
  - **DR-0077:** Search/filter UI in All Cards list
  - **DR-0078:** Image export UI in FullSizeImageViewer
  - **DR-0082:** Citations tab for all card kinds, Source-first workflow
  - **DR-0083:** Gesture isolation for backlog sidebar scroll
  - **ALL ER-0022 PHASE 5 DRS NOW VERIFIED!** 🎊
- 2026-02-08: **VERIFIED 3 DRs** (DR-0079, DR-0080, DR-0081) - Batch Operations & Duplication UI ✅
  - **DR-0079:** Expanded multi-select toolbar with Delete, Duplicate, and Generate Images buttons
  - **DR-0080:** Added batch deletion with confirmation dialog
  - **DR-0081:** Added single-card and batch duplication via context menu and toolbar
  - All changes in `MainAppView.swift` using CardOperationManager
  - User verified all functionality working correctly
- 2026-02-08: **CREATED 8 NEW DRs** (DR-0076 through DR-0083) - ER-0022 Phase 5 Manual Testing Results 🔴
  - **DR-0076:** No edge creation UI in MurderBoardView (High)
  - **DR-0077:** No search/filter UI in All Cards list (High)
  - **DR-0078:** No image export UI (Medium)
  - **DR-0079:** Multi-select only performs batch image generation (Medium) → 🟡 RESOLVED
  - **DR-0080:** No multi-card deletion UI (Medium) → 🟡 RESOLVED
  - **DR-0081:** No card duplication UI (Medium) → 🟡 RESOLVED
  - **DR-0082:** No citation UI for non-image citations (High)
  - **DR-0083:** MurderBoard backlog scroll propagates to canvas (Low)
  - These issues represent missing UI for existing backend services (ER-0022 Phases 1-2)
- 2026-02-04: **VERIFIED DR-0072 & DR-0073** - ER-0021 Extraction Quality & UI Issues Complete! ✅
  - **DR-0072:** Visual element extraction returning full sentences instead of targeted phrases
    - Phase 1: Rewrote with specific patterns (too aggressive - missed details)
    - Phase 2: Added fallback extraction (issues: eyes included "nose,", facial features blank)
    - Phase 3: Refined boundary detection and comma-list handling (partial fix)
    - Phase 4 (CURRENT): Found root cause - facial features extraction was never implemented!
      - Added missing facial features extraction with keywords (chin, nose, jaw, etc.)
      - Eyes: Stops at comma before "eyes" to extract "bright green eyes" correctly
      - Fallback: Recognizes comma-separated lists for "strong chin, short nose"
      - All visual elements now extracted properly
  - **DR-0073:** VisualElementReviewView sheet not resizing when advanced options expanded
    - Phase 1 (failed): Frame sizing only
    - Phase 2 (failed): Presentation sizing modifiers (sheets are modal, cannot resize)
    - Phase 3 (CURRENT): Re-laid out UI to fit in standard modal sheet
      - Changed segmented pickers to compact menu pickers (dropdown style)
      - Horizontal layout: labels left, pickers right
      - Fits in 600×650pt sheet without clipping
  - BUILD SUCCEEDED - ✅ BOTH DRs VERIFIED AND CLOSED
- 2026-02-03: **CLOSED 2 DRs** (DR-0071, DR-0069) - All Active DRs Now Resolved! 🎊
  - **DR-0071:** Apple Image Playground portrait-only limitation
    - Closed as "Will be addressed by ER-0021" (AI-Powered Visual Element Extraction)
    - ER-0021 will provide cinematic framing and visual element extraction to work around Image Playground limitations
    - Fundamental Apple API limitation, cannot be fixed in Cumberland alone
  - **DR-0069:** AI Provider Safety Filter False Positives
    - Closed as "Known Issue (External Limitation)"
    - OpenAI's DALL-E 3 safety filters are external to Cumberland
    - Cannot be fixed by user or developer - requires OpenAI changes
    - Workarounds documented: use different character names, switch to Apple Intelligence, or remove name from prompt
  - **ALL ACTIVE DRS NOW CLOSED OR VERIFIED!** 🎊
    - 59 verified (80.8%)
    - 5 closed/deferred (6.8%)
    - 4 open (deferred per user request, archived)
    - **0 active unresolved issues**
- 2026-02-03: **VERIFIED 6 ISSUES** (ER-0017, DR-0070, DR-0072, DR-0073, DR-0066, DR-0068) - Batch Image Generation and AI Analysis Complete! 🎉
  - **DR-0073:** Regenerate Image Uses Old Prompt Instead of Updated Description
    - Fixed prompt pre-fill logic in CardEditorView to always generate fresh prompts from current description
    - Users' updated descriptions now properly reflected in regeneration prompts
  - **DR-0066:** Relationships Not Created When Analyzing Existing (Saved) Cards
    - Fixed relationship deferral logic to check if source card is persistent
    - Existing cards now create relationships immediately instead of deferring indefinitely
  - **DR-0068:** Calendar Insertion Bug - Inserting Both Card and CalendarSystem
    - Fixed SwiftData cascade relationship insertion pattern
    - Removed double-insertion that caused calendar deletion crashes
- 2026-02-03: **VERIFIED 3 ISSUES** (ER-0017, DR-0070, DR-0072) - Batch Image Generation Complete! 🎉
  - **ER-0017:** AI Image Generation - Batch Processing and History Management
    - All 3 phases verified and working (multi-select, version history, history UI)
    - Batch generation with queue management and rate limiting
    - Image version history with restore/compare/export features
  - **DR-0070:** Image Generation Provider Picker Does Not Show Saved Setting
    - Fixed provider picker display in Settings, AI Image Generation Panel, and batch generation
    - Added reactive state management with .onAppear handlers
  - **DR-0072:** Batch Image Generation Fails with OpenAI Server Errors
    - Implemented 20-second rate limiting (3 requests/minute)
    - Added automatic retry logic with exponential backoff for server/network errors
    - Smart prompt generation avoids content filters for weapon-named artifacts
    - Enhanced error messages with helpful tips
- 2026-02-03: **IDENTIFIED 3 NEW DRs** (DR-0069, DR-0070, DR-0071, DR-0072, DR-0073) - AI Image Generation Issues 🔴
  - **DR-0073:** Regenerate image uses old prompt instead of updated description - 🟡 Resolved
  - **DR-0072:** Batch generation server errors/timeouts - ✅ Verified
  - **DR-0071:** Apple Image Playground requires person selection, unusable for landscapes/artifacts/vehicles
    - High severity - Affects 70-80% of card types (non-character entities)
    - Fundamental limitation of Apple's Image Playground design
    - Proposed: Warning dialog, recommend OpenAI for non-portraits
  - **DR-0070:** Image provider picker doesn't show saved setting - ✅ Verified
  - **DR-0069:** OpenAI safety filter rejects legitimate character names (e.g., "Evilin")
    - High severity - Blocks content creation for certain character names
    - Proposed: Enhanced error messages, multi-provider fallback, prompt preprocessing
- 2026-02-02: **VERIFIED DR-0040** - Icon-only buttons on iOS! 🎉
  - CardEditorView image action buttons now icon-only on iOS
  - BrushGridView brush set picker uses Menu for proper icon-only display
  - Files: CardEditorView.swift (lines 267-316), BrushGridView.swift (lines 59-110)
- 2026-02-01: **VERIFIED DR-0054** - iOS Edit Sheet ScrollView fix! 🎉
- 2026-02-01: **EXPANDED & RESOLVED DR-0040** - Icon-only buttons on iOS
  - Scope expanded: CardEditorView image action buttons + BrushGridView brush set picker
  - Solution: Icon-only buttons on iOS with tooltips, full labels on macOS
  - BrushGridView: Changed from Picker to Menu on iOS for proper icon-only display
- 2026-02-01: **VERIFIED 2 DRs** (DR-0055, DR-0056) - Relationship creation workflow fixes! 🎉
- 2026-02-01: **CLOSED DR-0039** - OBE (fixed by draft persistence improvements DR-0011/0012/0013)
- 2026-01-31: **VERIFIED 3 DRs** (DR-0065, DR-0066, DR-0068) - Calendar and AI analysis fixes! 🎉
- 2026-01-31: **CLOSED DR-0067** - Deferred to ER-0020 (Dynamic AI Relationship Extraction)
- 2026-01-30: **VERIFIED 8 DRs** (DR-0057 through DR-0064) - Temporal Editor Phase 2 complete! 🎉

---

*Last Updated: 2026-02-09*
*Document Version: 14.4 (DR-0076/0077/0078/0082/0083 verified - ER-0022 Phase 5 complete)*
