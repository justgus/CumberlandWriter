# Discrepancy Reports 0211-0220 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0211 through 0220.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## ✅ DR-0149: ER-0022 Phase 2 Incomplete - AIImageInfoView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** AI/Views/AIImageInfoView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. AI image view bypasses CardRepository.

**Resolution:** Migrated preview code to use CardRepository:
- Updated #Preview to use ModelContainerFactory.makeInMemoryContainer() and ServiceContainer (lines 267-276)
- Replaced direct Card() instantiation with cardRepository.createCard()
- Main view is read-only and displays AI image information - no card creation in production code

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0150: ER-0022 Phase 2 Incomplete - ImageHistoryView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** AI/Views/ImageHistoryView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Image history view bypasses CardRepository.

**Resolution:** Migrated preview code to use CardRepository:
- Updated ImageHistoryView_Previews to use ModelContainerFactory.makeInMemoryContainer() and ServiceContainer (lines 563-575)
- Replaced direct Card() instantiation and context.insert() with cardRepository.createCard()
- Main view is read-only and displays image version history - no card creation in production code

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0151: ER-0022 Phase 2 Incomplete - SuggestionReviewView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** AI/Views/SuggestionReviewView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Suggestion review UI bypasses CardRepository.

**Resolution:** Migrated both production and preview code to use CardRepository:
- **Production Code (line 496)**: Updated calendar card creation to use cardRepository.createCard() instead of direct Card() instantiation
- Removed direct modelContext.insert() call - CardRepository handles insertion
- **Preview Code (line 905)**: Updated to use ModelContainerFactory and ServiceContainer with cardRepository.createCard()
- Added all required environment dependencies for preview (services, cardRepository, edgeRepository, relationTypeManager)

**Note:** This view was already partially migrated in DR-0131 (has CardRepository, EdgeRepository, and RelationTypeManager environment properties), but calendar card creation was still using direct instantiation.

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0153: ER-0022 Phase 2 Incomplete - CardRelationshipHeader.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** CardRelationship/CardRelationshipHeader.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relationship UI bypasses CardRepository.

**Resolution:**
- Migrated preview code to use CardRepository (line 132)
- Updated #Preview to use ModelContainerFactory.makeInMemoryContainer() and ServiceContainer
- Replaced direct Card() instantiation with cardRepository.createCard()
- Main view is display-only - no card creation in production code

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0180: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** ReassignRelationTypeSheet.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relation type reassignment bypasses CardRepository.

**Resolution:**
- No direct Card() instantiation found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0181: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** RelationTypesManagerView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Relation type manager bypasses CardRepository.

**Resolution:**
- No direct Card() instantiation found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0182: ER-0022 Phase 2 Incomplete - SceneProjectRelationDiagnosticsView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** SceneProjectRelationDiagnosticsView.swift
**Severity:** Low
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Diagnostic view bypasses CardRepository.

**Resolution:**
- No direct Card() instantiation found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0192: ER-0022 Phase 2 Incomplete - CardRelationshipOperations.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** CardRelationship/CardRelationshipOperations.swift
**Severity:** Critical - Multiple edge deletions bypass repository
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CardRelationshipOperations.swift has 6 locations calling `modelContext.delete()` directly for edges and cards instead of using EdgeRepository.deleteRelationship() and CardRepository.delete().

**Resolution:**
- No direct modelContext.delete() calls found in current code
- All edge deletions now use repository pattern through RelationshipManager/EdgeRepository
- All card deletions now use repository pattern through CardOperationManager/CardRepository
- This DR appears to have been fixed in previous work

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0194: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** RelationTypesManagerView.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypesManagerView.swift:235,247 calls `modelContext.delete()` directly for relation types instead of using appropriate repository methods.

**Resolution:**
- No direct modelContext.delete() calls found in current code
- All relation type deletions now use repository pattern through RelationTypeManager
- This DR appears to have been fixed in previous work

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0195: ER-0022 Phase 2 Incomplete - DeveloperBoardsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** Diagnostic Views/DeveloperBoardsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperBoardsView.swift:466,483 calls `modelContext.delete(n)` directly for board nodes instead of using BoardManager or appropriate repository.

**Resolution:**
- Added @Environment(\.services) property to access ServiceContainer
- Updated removeOrphanNodes() method to use boardManager.removeNode() instead of direct deletion
- Updated fixDuplicateNodes() method to use boardManager.removeNode() instead of direct deletion
- Both methods now properly use repository pattern through BoardManager

**Locations Fixed:**
- `Diagnostic Views/DeveloperBoardsView.swift:467` (removeOrphanNodes)
- `Diagnostic Views/DeveloperBoardsView.swift:484` (fixDuplicateNodes)

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0197: ER-0022 Phase 2 Incomplete - DeveloperToolsView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** Diagnostic Views/DeveloperToolsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
DeveloperToolsView.swift:881,1024 calls `modelContext.delete()` directly for edges and cards instead of using repositories.

**Resolution:**
- Edge deletions already fixed: validateAllRelationships() now uses edgeRepo.deleteEdge() (line 899)
- Card deletions: No direct card deletions found in current code
- Source deletions: Line 1043 still uses direct deletion for consolidating duplicate sources
  - This is acceptable for diagnostic/repair tool
  - No SourceRepository exists yet
  - Documented with clear comment explaining reasoning
- View already has @Environment(\.services) for repository access

**Note:** Remaining direct deletion of Source objects at line 1043 is intentional for one-time diagnostic repair of duplicates.

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0199: ER-0022 Phase 2 Incomplete - RelationshipAuditView.swift Bypasses EdgeRepository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** Diagnostic Views/RelationshipAuditView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationshipAuditView.swift:586 calls `modelContext.delete(edge)` directly instead of using EdgeRepository.deleteRelationship().

**Resolution:**
- No direct modelContext.delete() calls found in current code
- All edge deletions now use repository pattern through services
- View properly uses @Environment(\.services) for repository access
- This DR appears to have been fixed in previous work

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0200: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Medium - Diagnostic view bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
RelationTypesDiagnosticsView.swift:146,217 calls `modelContext.delete()` directly for relation types instead of using appropriate repository methods.

**Resolution:**
- No direct modelContext.delete() calls found in current code
- All relation type deletions now use repository pattern through services
- View properly uses RelationTypeManager for all operations
- This DR appears to have been fixed in previous work

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0206: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-13
**Verified:** 2026-05-13
**Component:** ReassignRelationTypeSheet.swift
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
ReassignRelationTypeSheet.swift:128 calls `modelContext.delete(source)` directly instead of using appropriate repository method.

**Resolution:**
- No direct modelContext.delete() calls found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-13*
