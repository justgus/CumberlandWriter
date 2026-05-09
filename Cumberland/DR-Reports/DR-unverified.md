# Discrepancy Reports (DR) - Unverified Issues

- Guidelines: [Cumberland/DR-Reports/DR-Guidelines.md]

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **75 open DRs**

---

## 🔴 DR-0132: ER-0022 Phase 2 Incomplete - CumberlandApp.swift Not Migrated

**Reported:** 2026-04-27
**Component:** CumberlandApp.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 879, 1708). App bootstrap code bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0133: ER-0022 Phase 2 Incomplete - CardDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Diagnostic Views/CardDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0134: ER-0022 Phase 2 Incomplete - RecentEdgesDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RecentEdgesDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0135: ER-0022 Phase 2 Incomplete - RelationshipAuditView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationshipAuditView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0136: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0137: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Not Migrated

**Reported:** 2026-04-27
**Component:** ReassignRelationTypeSheet.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Critical relationship management UI bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0138: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** RelationTypesManagerView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (line 265). Core relationship type management bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0139: ER-0022 Phase 2 Incomplete - SceneProjectRelationDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** SceneProjectRelationDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 343, 345). Diagnostic view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0140: ER-0022 Phase 2 Incomplete - RelationshipManager.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Services/RelationshipManager.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Core service layer bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0141: ER-0022 Phase 2 Incomplete - SettingsView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** SettingsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (line 1549). Settings view bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0142: ER-0022 Phase 2 Incomplete - Swimlane.swift Not Migrated

**Reported:** 2026-04-27
**Component:** Swimlane.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Swimlane feature bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0143: ER-0022 Phase 2 Incomplete - SwimlaneViewer.swift Not Migrated

**Reported:** 2026-04-27
**Component:** SwimlaneViewer.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 269, 307-309, 316-317, 326+). Swimlane feature bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---


## 🔴 DR-0145: ER-0022 Phase 2 Incomplete - ManuscriptWritingSurfaceView.swift Not Migrated

**Reported:** 2026-04-27
**Component:** ProjectWriter/ManuscriptWritingSurfaceView.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (line 967). Core manuscript writing feature bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0146: ER-0022 Phase 2 Incomplete - EdgeRepository.swift Still Has Direct Edge Creation

**Reported:** 2026-04-27
**Component:** Data/EdgeRepository.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** EdgeRepository's own helper methods (linkSceneToChapter, linkSceneToProject, linkChapterToProject) created edges directly until today. Should have used createRelationship() from the start.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0147: ER-0022 Phase 2 Incomplete - MurderBoard DataSource Not Migrated

**Reported:** 2026-04-27
**Component:** MurderBoard/DataSource/InvestigationDataSource.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. MurderBoard data layer bypasses EdgeRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0149: ER-0022 Phase 2 Incomplete - AIImageInfoView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** AI/Views/AIImageInfoView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. AI image view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0150: ER-0022 Phase 2 Incomplete - ImageHistoryView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** AI/Views/ImageHistoryView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Image history view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0151: ER-0022 Phase 2 Incomplete - SuggestionReviewView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** AI/Views/SuggestionReviewView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Suggestion review UI bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0152: ER-0022 Phase 2 Incomplete - CardEditorAnalysisButton.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** CardEditor/CardEditorAnalysisButton.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Card editor feature bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0153: ER-0022 Phase 2 Incomplete - CardRelationshipHeader.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** CardRelationship/CardRelationshipHeader.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relationship UI bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0154: ER-0022 Phase 2 Incomplete - CardSheetView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** CardSheetView.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Core card editing sheet bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0155: ER-0022 Phase 2 Incomplete - CardView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** CardView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Core card display view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0156: ER-0022 Phase 2 Incomplete - CitationViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Citation/Views/CitationViewer.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Citation system bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0157: ER-0022 Phase 2 Incomplete - ImageAttributionViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Citation/Views/ImageAttributionViewer.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Attribution system bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0158: ER-0022 Phase 2 Incomplete - SourceDetailEditor.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Citation/Views/SourceDetailEditor.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Source editor bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0159: ER-0022 Phase 2 Incomplete - SourceEditorSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Citation/Views/SourceEditorSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Source editor sheet bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0160: ER-0022 Phase 2 Incomplete - CumberlandApp.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** CumberlandApp.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. App bootstrap and seed data bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0161: ER-0022 Phase 2 Incomplete - CardDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Diagnostic Views/CardDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0162: ER-0022 Phase 2 Incomplete - DeveloperBoardsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperBoardsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Developer tools bypass CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0163: ER-0022 Phase 2 Incomplete - DeveloperToolsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperToolsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Developer tools bypass CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0164: ER-0022 Phase 2 Incomplete - RecentEdgesDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RecentEdgesDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0165: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0166: ER-0022 Phase 2 Incomplete - FullSizeImageViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Images/FullSizeImageViewer.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Image viewer bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0167: ER-0022 Phase 2 Incomplete - MainAppView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** MainAppView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Main app view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0168: ER-0022 Phase 2 Incomplete - CalendarSystemMigrationHelper.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Model/CalendarSystemMigrationHelper.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Migration helper bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0169: ER-0022 Phase 2 Incomplete - ChapterWidget.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/ChapterWidget.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Manuscript widget bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0170: ER-0022 Phase 2 Incomplete - CustomStructureCreationSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/CustomStructureCreationSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Structure creation bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0171: ER-0022 Phase 2 Incomplete - ManuscriptTextEditor.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/ManuscriptTextEditor.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Manuscript editor bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0172: ER-0022 Phase 2 Incomplete - ProjectDashboardView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/ProjectDashboardView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Project dashboard bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0173: ER-0022 Phase 2 Incomplete - ProjectDetailView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/ProjectDetailView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Project detail view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0174: ER-0022 Phase 2 Incomplete - SceneWidget.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/SceneWidget.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Scene widget bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0175: ER-0022 Phase 2 Incomplete - StructureSelectionSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ProjectWriter/StructureSelectionSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Structure selection bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0176: ER-0022 Phase 2 Incomplete - CardOperationManager.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Services/CardOperationManager.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Core service layer bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0177: ER-0022 Phase 2 Incomplete - CardEditorViewModel.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ViewModels/CardEditorViewModel.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Core view model bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---


## 🔴 DR-0179: ER-0022 Phase 2 Incomplete - MurderBoardView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** MurderBoard/MurderBoardView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. MurderBoard feature bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0180: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** ReassignRelationTypeSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relation type reassignment bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0181: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** RelationTypesManagerView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relation type manager bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0182: ER-0022 Phase 2 Incomplete - SceneProjectRelationDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** SceneProjectRelationDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0183: ER-0022 Phase 2 Incomplete - SettingsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** SettingsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Settings view bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0184: ER-0022 Phase 2 Incomplete - Swimlane.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Swimlane.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Swimlane feature bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0185: ER-0022 Phase 2 Incomplete - SwimlaneViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** SwimlaneViewer.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Swimlane viewer bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0186: ER-0022 Phase 2 Incomplete - SceneTemporalPositionEditor.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Timeline/SceneTemporalPositionEditor.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Timeline editor bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0187: ER-0022 Phase 2 Incomplete - TimelineChartView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Component:** Timeline/TimelineChartView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Timeline chart bypasses CardRepository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0120: ER-0022 Phase 2 Systemic Failure - Repository Pattern Not Implemented

**Reported:** 2026-04-27
**Component:** Data/EdgeRepository.swift, Data/CardRepository.swift, entire codebase
**Severity:** Critical - Complete ER-0022 Phase 2 failure
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
ER-0022 Phase 2 created CardRepository and EdgeRepository classes but failed to:
1. Implement complete CRUD operations in repositories
2. Migrate codebase to use repositories
3. Verify migration completion

This is a **systemic implementation failure** of ER-0022 Phase 2, not just a single bug.

**Scope of Failure:**
- CardRepository missing: updateCard(), updateCardKind(), updateCardImage()
- EdgeRepository missing: createRelationship(), deleteRelationship(), updateRelationType(), moveRelationship(), updateSortIndex(), updateSortIndices()
- 72+ locations create CardEdge() directly (bypassing EdgeRepository)
- 50+ locations create Card() directly (bypassing CardRepository)
- 30+ locations call modelContext.delete() directly (bypassing repositories)

**Impact:**
- Bidirectional relationships broken (Scene→Chapter exists, Chapter→Scene doesn't)
- No data integrity guarantees anywhere
- No centralized business logic
- Every view implements its own data access patterns
- Estimated **1 month of work** to complete ER-0022 Phase 2 properly

**Breakdown into Sub-DRs:**
- DR-0121: CardRepository missing update methods
- DR-0122: EdgeRepository missing createRelationship()
- DR-0123: EdgeRepository missing deleteRelationship()
- DR-0124: EdgeRepository missing updateRelationType()
- DR-0125: EdgeRepository missing moveRelationship()
- DR-0126: EdgeRepository missing reorder methods
- DR-0127: CardRelationshipOperations not migrated
- DR-0128: MurderBoardView not migrated
- DR-0129: TimelineChartView not migrated
- DR-0130: 60+ additional files not migrated

**Root Cause:**
ER-0022 Phase 2 was marked complete without:
- Implementing full CRUD operations
- Searching codebase for direct instantiations
- Migrating existing code
- Verification testing

**Status:** 🔴 Identified - ER-0022 Phase 2 Must Be Reopened and Completed

---

## Recently Verified

- **DR-0148:** ER-0022 Phase 2 Incomplete - SuggestionEngine.swift Creates Cards Directly — ✅ Verified 2026-05-09 -> [Batch 15](./DR-verified-0141-0150.md)
- **DR-0131:** ER-0022 Phase 2 Incomplete - SuggestionEngine.swift Not Migrated — ✅ Verified 2026-05-09 -> [Batch 14](./DR-verified-0131-0140.md)
- **DR-0178:** ER-0022 Phase 2 Incomplete - AggregateTextView.swift Creates Cards Directly — ✅ Verified 2026-05-06 -> [Batch 18](./DR-verified-0171-0180.md)
- **DR-0130:** ER-0022 Phase 2 Incomplete - AggregateTextView.swift Not Migrated — ✅ Verified 2026-05-06 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0126:** ER-0022 Phase 2 Incomplete - EdgeRepository Missing Reorder Methods — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0125:** ER-0022 Phase 2 Incomplete - EdgeRepository Missing moveRelationship() — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0124:** ER-0022 Phase 2 Incomplete - EdgeRepository Missing updateRelationType() — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0123:** ER-0022 Phase 2 Incomplete - EdgeRepository Missing deleteRelationship() — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0122:** ER-0022 Phase 2 Incomplete - EdgeRepository Missing createRelationship() — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0121:** ER-0022 Phase 2 Incomplete - CardRepository Missing Update Methods — ✅ Verified 2026-04-29 -> [Batch 13](./DR-verified-0121-0130.md)
- **DR-0119:** Structure Sheet Layout Issues — ✅ Verified 2026-04-23 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0118:** Project Writer UI/UX Improvements — ✅ Verified 2026-04-23 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0117:** Project Writer Views Missing Dark Mode Theming — ✅ Verified 2026-04-23 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0116:** UserDefaults Bloat from AppKit Auto-Persistence (4MB, 2000+ Keys) — ✅ Verified 2026-04-23 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0115:** SearchEngineTests — 4 Tests Fail in Suite but Pass Individually — ✅ Verified 2026-04-23 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0114:** CalendarExtractionTests Disabled via `#if false` — Re-enable with Container Fix — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0113:** EntityExtractionTests Disabled via `#if false` — Re-enable with API Fixes — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0112:** ImageGenerationWorkflowTests Disabled via `#if false` — Re-enable with Type and Container Fixes — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0111:** VisualElementExtractorTests — Optional Comparison Bug and Compound Word Match — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0110:** KeychainHelperTests — Keychain Operations Fail in Hosted Test Environment — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0109:** CardModelTests — normalizedSearchText Not Updated After Property Mutation — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0108:** AISettingsTests — Not Meeting Expectations — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0107:** AIImageGeneratorTests — Test Expects Success From Placeholder Implementation — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0106:** AIProviderTests — analyzeText Test String Below 25-Word Minimum — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0105:** Test Infrastructure — Migrate Factories to Service Managers — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0104:** BoardManager Service — Centralize Board/BoardNode CRUD — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0103:** RelationTypeManager Service — Centralize RelationType CRUD — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0102:** TestFixtures Crash on context.insert() — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0101:** Theme Color Swatches Not Visible in Settings Picker — ✅ Verified 2026-02-27 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0099:** iOS/visionOS Targets Missing File Memberships — Build Failures — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0100:** Auxiliary Windows Restore on App Launch Instead of Main UI — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0098:** Complete Relationship Loss for Single Card — ✅ Verified 2026-02-22 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0096:** BoardGestureIntegration Modifies @Binding State During View Body Evaluation — ✅ Verified 2026-02-18 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0095:** Map Wizard Cannot Save Drawn Map — ✅ Verified 2026-02-16 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0094:** Image History Restore Does Not Update CardEditorView — ✅ Verified 2026-02-14 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0092:** visionOS Settings Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0093:** visionOS Developer Tools Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)

---

## 🔴 DR-0188: ER-0022 Phase 2 Incomplete - Swimlane.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Swimlane.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
Swimlane.swift:472 calls `modelContext.delete(e)` directly instead of using EdgeRepository.deleteRelationship().

**Impact:**
- Bypasses centralized edge deletion logic
- Reverse relationships may not be deleted
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Location:** `Swimlane.swift:472`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0189: ER-0022 Phase 2 Incomplete - SourcesView.swift Bypasses Repositories

**Reported:** 2026-04-27
**Component:** SourcesView.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
SourcesView.swift:127,130 calls `modelContext.delete()` directly for citations and sources instead of using appropriate repository methods.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks executed
- Violates single-responsibility principle

**Locations:**
- `SourcesView.swift:127` (citation)
- `SourcesView.swift:130` (source)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0190: ER-0022 Phase 2 Incomplete - StoryStructureView.swift Bypasses StructureRepository

**Reported:** 2026-04-27
**Component:** StoryStructureView.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
StoryStructureView.swift:160 calls `modelContext.delete(item)` directly instead of using StructureRepository deletion methods.

**Impact:**
- Bypasses centralized structure deletion logic
- No cleanup for associated elements
- Violates single-responsibility principle

**Location:** `StoryStructureView.swift:160`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0191: ER-0022 Phase 2 Incomplete - CardEditorSaveHandler.swift Bypasses Repositories

**Reported:** 2026-04-27
**Component:** CardEditor/CardEditorSaveHandler.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CardEditorSaveHandler.swift:128,144 calls `modelContext.delete()` directly for citation and structure element deletions instead of using appropriate repository methods.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks executed
- Violates single-responsibility principle

**Locations:**
- `CardEditor/CardEditorSaveHandler.swift:128` (citation)
- `CardEditor/CardEditorSaveHandler.swift:144` (structure element)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0192: ER-0022 Phase 2 Incomplete - CardRelationshipOperations.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** CardRelationship/CardRelationshipOperations.swift
**Severity:** Critical - Multiple edge deletions bypass repository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CardRelationshipOperations.swift has 6 locations calling `modelContext.delete()` directly for edges and cards instead of using EdgeRepository.deleteRelationship() and CardRepository.delete().

**Impact:**
- Reverse relationships not deleted (data integrity failure)
- EdgeIntegrityMonitor counts not updated
- Card cleanup hooks not executed
- Violates single-responsibility principle

**Locations:**
- `CardRelationship/CardRelationshipOperations.swift:330` (edge)
- `CardRelationship/CardRelationshipOperations.swift:334` (edge)
- `CardRelationship/CardRelationshipOperations.swift:348` (edge)
- `CardRelationship/CardRelationshipOperations.swift:352` (edge)
- `CardRelationship/CardRelationshipOperations.swift:371` (card)
- `CardRelationship/CardRelationshipOperations.swift:401` (edge)

**Status:** 🔴 Identified - Not Resolved

---


## 🔴 DR-0194: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** RelationTypesManagerView.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypesManagerView.swift:235,247 calls `modelContext.delete()` directly for relation types instead of using appropriate repository methods.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for edges using this relation type
- Violates single-responsibility principle

**Locations:**
- `RelationTypesManagerView.swift:235` (type)
- `RelationTypesManagerView.swift:247` (type)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0195: ER-0022 Phase 2 Incomplete - DeveloperBoardsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperBoardsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperBoardsView.swift:466,483 calls `modelContext.delete(n)` directly for board nodes instead of using BoardManager or appropriate repository.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for board nodes
- Violates single-responsibility principle

**Locations:**
- `Diagnostic Views/DeveloperBoardsView.swift:466` (node)
- `Diagnostic Views/DeveloperBoardsView.swift:483` (node)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0196: ER-0022 Phase 2 Incomplete - CitationManager.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Citation/Services/CitationManager.swift
**Severity:** High - Service bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CitationManager.swift:70 calls `modelContext.delete(citation)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks for citations
- Violates single-responsibility principle

**Location:** `Citation/Services/CitationManager.swift:70`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0197: ER-0022 Phase 2 Incomplete - DeveloperToolsView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperToolsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperToolsView.swift:881,1024 calls `modelContext.delete()` directly for edges and cards instead of using repositories.

**Impact:**
- Reverse relationships not deleted
- Card cleanup hooks not executed
- EdgeIntegrityMonitor counts not updated

**Locations:**
- `Diagnostic Views/DeveloperToolsView.swift:881` (edge)
- `Diagnostic Views/DeveloperToolsView.swift:1024` (duplicate card)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0198: ER-0022 Phase 2 Incomplete - StructureSelectionSheet.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** ProjectWriter/StructureSelectionSheet.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
StructureSelectionSheet.swift:502 calls `modelContext.delete(current)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for structure elements
- Violates single-responsibility principle

**Location:** `ProjectWriter/StructureSelectionSheet.swift:502`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0199: ER-0022 Phase 2 Incomplete - RelationshipAuditView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationshipAuditView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationshipAuditView.swift:586 calls `modelContext.delete(edge)` directly instead of using EdgeRepository.deleteRelationship().

**Impact:**
- Reverse relationships not deleted
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Location:** `Diagnostic Views/RelationshipAuditView.swift:586`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0200: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypesDiagnosticsView.swift:146,217 calls `modelContext.delete()` directly for relation types instead of using appropriate repository methods.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for edges using these types
- Violates single-responsibility principle

**Locations:**
- `Diagnostic Views/RelationTypesDiagnosticsView.swift:146` (type)
- `Diagnostic Views/RelationTypesDiagnosticsView.swift:217` (duplicate)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0201: ER-0022 Phase 2 Incomplete - SuggestionFeedback.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Model/SuggestionFeedback.swift
**Severity:** Medium - Model cleanup bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
SuggestionFeedback.swift:194 calls `modelContext.delete(feedback)` directly in cleanup method instead of using appropriate repository.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks executed
- Violates single-responsibility principle

**Location:** `Model/SuggestionFeedback.swift:194`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0202: ER-0022 Phase 2 Incomplete - RelationTypeManager.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Services/RelationTypeManager.swift
**Severity:** High - Service bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypeManager.swift:96 calls `modelContext.delete(type)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for edges using this type
- Violates single-responsibility principle

**Location:** `Services/RelationTypeManager.swift:96`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0204: ER-0022 Phase 2 Incomplete - CardOperationManager.swift Bypasses Repositories

**Reported:** 2026-04-27
**Component:** Services/CardOperationManager.swift
**Severity:** Critical - Service layer bypasses repositories
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CardOperationManager.swift has 4 locations calling `modelContext.delete()` directly for cards and edges instead of using CardRepository.delete() and EdgeRepository.deleteRelationship().

**Impact:**
- Service layer duplicates repository logic
- Reverse relationships not deleted
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Locations:**
- `Services/CardOperationManager.swift:74` (card)
- `Services/CardOperationManager.swift:87` (card)
- `Services/CardOperationManager.swift:154` (edge)
- `Services/CardOperationManager.swift:158` (edge)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0205: ER-0022 Phase 2 Incomplete - RelationshipManager.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Services/RelationshipManager.swift
**Severity:** Critical - Service layer bypasses EdgeRepository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationshipManager.swift has 7 locations calling `modelContext.delete()` directly for edges instead of using EdgeRepository.deleteRelationship().

**Impact:**
- Service layer duplicates EdgeRepository logic
- Reverse relationships not deleted (data integrity failure)
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Locations:**
- `Services/RelationshipManager.swift:140` (edge)
- `Services/RelationshipManager.swift:144` (edge)
- `Services/RelationshipManager.swift:159` (edge)
- `Services/RelationshipManager.swift:163` (edge)
- `Services/RelationshipManager.swift:178` (edge)
- `Services/RelationshipManager.swift:208` (edge)
- `Services/RelationshipManager.swift:216` (edge)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0206: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** ReassignRelationTypeSheet.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
ReassignRelationTypeSheet.swift:128 calls `modelContext.delete(source)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks executed
- Violates single-responsibility principle

**Location:** `ReassignRelationTypeSheet.swift:128`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0207: ER-0022 Phase 2 Incomplete - MainAppView.swift Bypasses CardRepository

**Reported:** 2026-04-27
**Component:** MainAppView.swift
**Severity:** Critical - Main view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
MainAppView.swift has 3 locations calling `modelContext.delete()` directly for cards instead of using CardRepository.delete().

**Impact:**
- Bypasses centralized card deletion logic
- Card cleanup hooks not executed
- Violates single-responsibility principle

**Locations:**
- `MainAppView.swift:1100` (card)
- `MainAppView.swift:1114` (item - structure element)
- `MainAppView.swift:1514` (card)

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0208: ER-0022 Phase 2 Incomplete - CumberlandBoardDataSource.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** MurderBoard/CumberlandBoardDataSource.swift
**Severity:** High - MurderBoard bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CumberlandBoardDataSource.swift:134 calls `modelContext.delete(boardNode)` directly instead of using BoardManager or appropriate repository.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup for board node relationships
- Violates single-responsibility principle

**Location:** `MurderBoard/CumberlandBoardDataSource.swift:134`

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0209: ER-0022 Phase 2 Incomplete - MurderBoardView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** MurderBoard/MurderBoardView.swift
**Severity:** High - MurderBoard bypasses EdgeRepository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
MurderBoardView.swift has 3 locations calling `modelContext.delete(e)` directly for edges instead of using EdgeRepository.deleteRelationship().

**Impact:**
- Reverse relationships not deleted
- EdgeIntegrityMonitor counts not updated
- Violates single-responsibility principle

**Locations:**
- `MurderBoard/MurderBoardView.swift:978` (edge)
- `MurderBoard/MurderBoardView.swift:1002` (edge)
- `MurderBoard/MurderBoardView.swift:1018` (edge)

**Status:** 🔴 Identified - Not Resolved

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-04-27*
