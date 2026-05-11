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

*Last Updated: 2026-05-11*
