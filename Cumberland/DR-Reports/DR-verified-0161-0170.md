# Discrepancy Reports 0161-0170 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0161 through 0170.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## ✅ DR-0161: ER-0022 Phase 2 Incomplete - CardDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/CardDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0133 (same file, CardEdge creation)

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Resolution:** 2026-05-11

Resolved simultaneously with DR-0133. See DR-0133 for complete resolution details.

**Key Changes:**
- Preview migrated to use CardRepository.createCard() instead of direct Card() instantiation
- All repository operations properly handle errors with try! in preview context
- Preview uses ModelContainerFactory and ServiceContainer injection

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0162: ER-0022 Phase 2 Incomplete - DeveloperBoardsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/DeveloperBoardsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0195 (same file, direct board node deletion)

**Issue:** Creates Card() instances directly. Developer tools bypass CardRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Board Node Deletion:**
- Added comments noting direct deletion is for diagnostic/repair of orphan/duplicate nodes (lines 466, 483)
- These operations handle corrupted data and don't have repository equivalents

**Files Modified:**
- Diagnostic Views/DeveloperBoardsView.swift:466 - Added diagnostic comment
- Diagnostic Views/DeveloperBoardsView.swift:483 - Added diagnostic comment
- Diagnostic Views/DeveloperBoardsView.swift:499-523 - Migrated Preview to use CardRepository

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0163: ER-0022 Phase 2 Incomplete - DeveloperToolsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/DeveloperToolsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0197 (same file, direct edge and source deletion)

**Issue:** Creates Card() instances directly. Developer tools bypass CardRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Edge Deletion:**
- Replaced direct modelContext.delete(edge) with EdgeRepository.deleteEdge() for orphan edges (line 881)

**Source Deletion:**
- Added comment noting direct deletion is for diagnostic/repair of duplicate sources (line 1024)
- Source consolidation handles corrupted data

**Additional Query Removal (2026-05-11):**
- Replaced 4 @Query declarations with @State + QueryService
- Added getAllBoardNodes() method to QueryService
- Replaced FetchDescriptor usages with EdgeRepository and QueryService methods
- Added reloadData() method with .task modifier
- Added reloadData() calls after all data-modifying operations

**Files Modified:**
- Data/QueryService.swift:119-124 - Added getAllBoardNodes() method
- Diagnostic Views/DeveloperToolsView.swift:16-19 - Replaced @Query with @State
- Diagnostic Views/DeveloperToolsView.swift:101-109 - Added Group wrapper for .task
- Diagnostic Views/DeveloperToolsView.swift:111-119 - Added reloadData() method
- Diagnostic Views/DeveloperToolsView.swift:877-920 - Migrated validateAllRelationships to use repositories
- Diagnostic Views/DeveloperToolsView.swift:881-883 - Migrated orphan edge deletion to EdgeRepository.deleteEdge()
- Diagnostic Views/DeveloperToolsView.swift:1024 - Added diagnostic comment
- Diagnostic Views/DeveloperToolsView.swift:1055-1085 - Migrated Preview to use CardRepository

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0164: ER-0022 Phase 2 Incomplete - RecentEdgesDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/RecentEdgesDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0134 (same file, CardEdge creation)

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Resolution:** 2026-05-11

Resolved simultaneously with DR-0134. See DR-0134 for complete resolution details.

**Key Changes:**
- Preview migrated to use CardRepository.createCard() instead of direct Card() instantiation
- Updated to use ModelContainerFactory and ServiceContainer injection

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0165: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Resolution:** 2026-05-11

Resolved simultaneously with DR-0136. Preview now uses CardRepository and EdgeRepository for all data operations. Uses ModelContainerFactory.makeInMemoryContainer() and ServiceContainer for proper environment injection.

**Key Changes:**
- Preview:276: `let cardRepo = CardRepository(modelContext: ctx)`
- Preview:276-278: Creates cards via `cardRepo.createCard(kind:name:)`
- Preview:281: `let edgeRepo = EdgeRepository(modelContext: ctx)`
- Preview:282-283: Creates edges via `edgeRepo.createRelationship(from:to:relationType:)`

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0157: ER-0022 Phase 2 Incomplete - ImageAttributionViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Citation/Views/ImageAttributionViewer.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Attribution system bypasses CardRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Migrated two Preview functions to use CardRepository.createCard()
- Migrated both Previews to use ModelContainerFactory with full model list and ServiceContainer
- Added @MainActor in to Preview closures
- Build verified successful

**Files Modified:**
- Citation/Views/ImageAttributionViewer.swift:143-165 - Migrated "ImageAttributionViewer – Light" Preview
- Citation/Views/ImageAttributionViewer.swift:167-189 - Migrated "ImageAttributionViewer – Dark" Preview

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0158: ER-0022 Phase 2 Incomplete - SourceDetailEditor.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Citation/Views/SourceDetailEditor.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Source editor bypasses CardRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Migrated Preview to use CardRepository.createCard() within @Previewable @State closure
- Used ModelContainerFactory with full model list and ServiceContainer
- Build verified successful

**Files Modified:**
- Citation/Views/SourceDetailEditor.swift:257-278 - Migrated Preview to use CardRepository with closure initializer

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0159: ER-0022 Phase 2 Incomplete - SourceEditorSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Citation/Views/SourceEditorSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Source editor sheet bypasses CardRepository.

**Resolution:** 2026-05-11

**Business Logic Migration:**
- Migrated saveNew() business logic (lines 206-221) to use CardRepository.createCard()
- Added error handling for card creation failure - saves Source without card link if CardRepository fails
- Replaced direct Card() instantiation and modelContext.insert() with CardRepository pattern
- Build verified successful

**Files Modified:**
- Citation/Views/SourceEditorSheet.swift:206-221 - Migrated auto-card-creation logic to use CardRepository

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0166: ER-0022 Phase 2 Incomplete - FullSizeImageViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Images/FullSizeImageViewer.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Image viewer bypasses CardRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Migrated Preview to use CardRepository.createCard()
- Used ModelContainerFactory with full model list and ServiceContainer
- Added @MainActor in to Preview closure
- Build verified successful

**Files Modified:**
- Images/FullSizeImageViewer.swift:164-186 - Migrated Preview to use CardRepository

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0167: ER-0022 Phase 2 Incomplete - MainAppView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** MainAppView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Main app view bypasses CardRepository.

**Resolution:** 2026-05-11

**Business Logic Migration:**
- Migrated duplicateSelectedCards() fallback path (lines 1551-1568) to use CardRepository.createCard()
- Migrated duplicateCard() fallback path (lines 1592-1609) to use CardRepository.createCard()
- Both fallback paths now create CardRepository from modelContext and use repository pattern

**Preview Migration:**
- Migrated Preview (lines 1990-1997) to use ModelContainerFactory with full model list and ServiceContainer
- Added @MainActor in to Preview closure
- Build verified successful

**Files Modified:**
- MainAppView.swift:1551-1568 - Migrated duplicateSelectedCards() fallback to CardRepository
- MainAppView.swift:1592-1609 - Migrated duplicateCard() fallback to CardRepository
- MainAppView.swift:1990-1997 - Migrated Preview to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0168: ER-0022 Phase 2 Incomplete - CalendarSystemMigrationHelper.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-14
**Verified:** 2026-05-14
**Component:** Model/CalendarSystemMigrationHelper.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly and uses modelContext operations directly. Migration helper bypasses CardRepository and CalendarSystemRepository.

**Resolution:**
- Changed function signature from `migrateOrphanCalendarSystems(modelContext: ModelContext)` to `migrateOrphanCalendarSystems(services: ServiceContainer)`
- **Added** `fetchOrphanedCalendars()` method to CalendarSystemRepository (CalendarSystemRepository.swift:145-151)
- Migrated orphan calendar fetching from `modelContext.fetch(FetchDescriptor<CalendarSystem>())` to `calendarRepo.fetchOrphanedCalendars()`
- Migrated existing card fetching from `try? modelContext.fetch(existingCardsFetch)` to `cardRepo.fetchCalendarCards()`
- Migrated Card creation from direct `Card()` instantiation + `modelContext.insert()` to `cardRepo.createCard()`
- Removed redundant `modelContext.save()` call (createCard() already saves)
- Updated DataIntegrityManager.swift:253 to pass `services` instead of `context`
- **Zero direct modelContext operations remain in CalendarSystemMigrationHelper**

**Files Modified:**
- `Data/CalendarSystemRepository.swift:145-151` - Added fetchOrphanedCalendars() method
- `Model/CalendarSystemMigrationHelper.swift:25` - Updated function signature
- `Model/CalendarSystemMigrationHelper.swift:29-36` - Migrated to CalendarSystemRepository.fetchOrphanedCalendars()
- `Model/CalendarSystemMigrationHelper.swift:41-42` - Migrated to CardRepository.fetchCalendarCards()
- `Model/CalendarSystemMigrationHelper.swift:50-61` - Migrated to CardRepository.createCard()
- `Services/DataIntegrityManager.swift:253` - Updated function call

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-14*
