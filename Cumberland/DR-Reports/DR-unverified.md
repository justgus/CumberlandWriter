# Discrepancy Reports (DR) - Unverified Issues

- Guidelines: [Cumberland/DR-Reports/DR-Guidelines.md]

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **29 open DRs** (26 identified, 3 resolved awaiting verification)

## Recently Verified (2026-05-14)

The following DRs have been verified and archived:
- ✅ **DR-0155** → DR-verified-0151-0160.md - CardView.swift Creates Cards Directly
- ✅ **DR-0156** → DR-verified-0151-0160.md - CitationViewer.swift Creates Cards Directly
- ✅ **DR-0168** → DR-verified-0161-0170.md - CalendarSystemMigrationHelper.swift Creates Cards Directly
- ✅ **DR-0177** → DR-verified-0171-0180.md - CardEditorViewModel.swift Creates Cards Directly
- ✅ **DR-0179** → DR-verified-0171-0180.md - MurderBoardView.swift Creates Cards Directly

## Recently Verified (2026-05-13)

The following DRs have been verified and archived:
- ✅ **DR-0147** → DR-verified-0141-0150.md (Batch 15) - MurderBoardApp repository consolidation
- ✅ **DR-0149** → DR-verified-0211-0220.md (Batch 21) - AIImageInfoView.swift Card creation
- ✅ **DR-0150** → DR-verified-0211-0220.md (Batch 21) - ImageHistoryView.swift Card creation
- ✅ **DR-0151** → DR-verified-0211-0220.md (Batch 21) - SuggestionReviewView.swift Card creation
- ✅ **DR-0153** → DR-verified-0211-0220.md (Batch 21) - CardRelationshipHeader.swift Card creation
- ✅ **DR-0180** → DR-verified-0211-0220.md (Batch 21) - ReassignRelationTypeSheet.swift pattern violations
- ✅ **DR-0181** → DR-verified-0211-0220.md (Batch 21) - RelationTypesManagerView.swift Card creation
- ✅ **DR-0182** → DR-verified-0211-0220.md (Batch 21) - SceneProjectRelationDiagnosticsView.swift Card creation
- ✅ **DR-0192** → DR-verified-0211-0220.md (Batch 21) - CardRelationshipOperations.swift EdgeRepository migration
- ✅ **DR-0194** → DR-verified-0211-0220.md (Batch 21) - RelationTypesManagerView.swift Repository migration

## Previously Verified (2026-05-12)

The following DRs have been verified and archived:
- ✅ **DR-0140** → DR-verified-0131-0140.md (Batch 14) - RelationshipManager.swift EdgeRepository migration
- ✅ **DR-0176** → DR-verified-0171-0180.md (Batch 18) - CardOperationManager.swift Card creation migration
- ✅ **DR-0196** → DR-verified-0191-0200.md (Batch 19) - CitationManager.swift documentation enhancement
- ✅ **DR-0202** → DR-verified-0201-0210.md (Batch 20) - RelationTypeManager.swift edge cleanup
- ✅ **DR-0204** → DR-verified-0201-0210.md (Batch 20) - CardOperationManager.swift deletion migration
- ✅ **DR-0205** → DR-verified-0201-0210.md (Batch 20) - RelationshipManager.swift deletion migration

---

## 🔴 DR-0195: ER-0022 Phase 2 Incomplete - DeveloperBoardsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperBoardsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperBoardsView.swift:466,483 calls `modelContext.delete(n)` directly for board nodes instead of using BoardManager or appropriate repository.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0197: ER-0022 Phase 2 Incomplete - DeveloperToolsView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/DeveloperToolsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperToolsView.swift:881,1024 calls `modelContext.delete()` directly for edges and cards instead of using repositories.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0199: ER-0022 Phase 2 Incomplete - RelationshipAuditView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationshipAuditView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationshipAuditView.swift:586 calls `modelContext.delete(edge)` directly instead of using EdgeRepository.deleteRelationship().

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0200: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypesDiagnosticsView.swift:146,217 calls `modelContext.delete()` directly for relation types instead of using appropriate repository methods.

**Status:** 🔴 Identified - Not Resolved

---

## 🔴 DR-0206: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** ReassignRelationTypeSheet.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
ReassignRelationTypeSheet.swift:128 calls `modelContext.delete(source)` directly instead of using appropriate repository method.

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

## ✅ DR-0152: ER-0022 Phase 2 Incomplete - CardEditorAnalysisButton.swift Bypasses CardRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** CardEditor/CardEditorAnalysisButton.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Line 106 calls `modelContext.fetch(FetchDescriptor<Card>())` directly instead of using CardRepository.

**Resolution:**
- Added `@Environment(\.services)` to view (line 20)
- Added guard for services availability in analyzeContent() method
- Migrated line 106 from `try modelContext.fetch(FetchDescriptor<Card>())` to `services.cardRepository.fetchAll()`
- **Note:** Temporary Card() instantiation at lines 97-102 is acceptable - it creates an in-memory object for analysis that's never inserted into the database

**Files Modified:**
- `CardEditor/CardEditorAnalysisButton.swift:20` - Added @Environment(\.services)
- `CardEditor/CardEditorAnalysisButton.swift:86-88` - Added services guard
- `CardEditor/CardEditorAnalysisButton.swift:108` - Migrated to CardRepository.fetchAll()

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0154: ER-0022 Phase 2 Incomplete - CardSheetView.swift Bypasses CardRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** CardSheetView.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Multiple modelContext.save() calls (lines 462, 474, 488, 491) instead of using CardRepository.save(). Preview code created Card() directly.

**Resolution:**
- Added `@Environment(\.services)` to view (line 41)
- Migrated commitName() to use `services?.cardRepository.save()` instead of `modelContext.save()` (line 462)
- Migrated commitSubtitle() to use `services?.cardRepository.save()` instead of `modelContext.save()` (line 474)
- Migrated saveDetailsIfDirty() to use `services?.cardRepository.save()` in both undo block and main save (lines 488, 491)
- Migrated Preview to use ModelContainerFactory, ServiceContainer, and CardRepository.createCard()
- Removed direct Card() instantiation and ctx.insert() from preview

**Files Modified:**
- `CardSheetView.swift:41` - Added @Environment(\.services)
- `CardSheetView.swift:462` - Migrated commitName() save
- `CardSheetView.swift:474` - Migrated commitSubtitle() save
- `CardSheetView.swift:488,491` - Migrated saveDetailsIfDirty() saves
- `CardSheetView.swift:796-827` - Migrated Preview to use repository pattern

**Verification:**
Zero direct modelContext.save/insert/delete/fetch operations remain in the file.

**Status:** ✅ Resolved - Verified

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

- **DR-0160:** ER-0022 Phase 2 Incomplete - CumberlandApp.swift Creates Cards Directly — ✅ Verified 2026-05-11 -> [Batch 16](./DR-verified-0151-0160.md)
- **DR-0132:** ER-0022 Phase 2 Incomplete - CumberlandApp.swift Not Migrated — ✅ Verified 2026-05-11 -> [Batch 14](./DR-verified-0131-0140.md)
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

## 🟡 DR-0191: ER-0022 Phase 2 Incomplete - CardEditorSaveHandler.swift Bypasses Repositories

**Reported:** 2026-04-27
**Component:** CardEditor/CardEditorSaveHandler.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CardEditorSaveHandler.swift:128,144 calls `modelContext.delete()` directly for structure and structure element deletions instead of using appropriate repository methods.

**Resolution:**
- CardEditorSaveHandler already uses repository pattern with defensive fallback
- Line 125-129: Prefers `repo.deleteStructure(existing)` when structureRepository available, falls back to direct deletion only when nil
- Line 141-145: Prefers `repo.deleteElement(oldEl)` when structureRepository available, falls back to direct deletion only when nil
- Initialized with structureRepository from services in CardEditorView.swift:99
- Fallback code is defensive programming for rare cases where services unavailable
- **Note:** DR description incorrectly mentioned "citation" - these are StoryStructure/StructureElement deletions, not citations

**Status:** 🟡 Resolved - Not Verified

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

## 🟡 DR-0208: ER-0022 Phase 2 Incomplete - CumberlandBoardDataSource.swift Bypasses Repository

**Reported:** 2026-04-27
**Component:** MurderBoard/CumberlandBoardDataSource.swift
**Severity:** High - MurderBoard bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CumberlandBoardDataSource.swift:134 calls `modelContext.delete(boardNode)` directly instead of using BoardManager or appropriate repository.

**Resolution:**
- No direct modelContext.delete() calls found in current code
- This DR appears to have been fixed in previous work
- CumberlandBoardDataSource now properly uses repository pattern

**Status:** 🟡 Resolved - Not Verified

---

## 🟡 DR-0209: ER-0022 Phase 2 Incomplete - MurderBoardView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Component:** MurderBoard/MurderBoardView.swift
**Severity:** High - MurderBoard bypasses EdgeRepository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
MurderBoardView.swift has 3 locations calling `modelContext.delete(e)` directly for edges instead of using EdgeRepository.deleteRelationship().

**Resolution:**
- No direct modelContext.delete() calls found in current code
- All edge operations now use repository pattern through services
- This DR appears to have been fixed in previous work

**Status:** 🟡 Resolved - Not Verified

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-04-27*
