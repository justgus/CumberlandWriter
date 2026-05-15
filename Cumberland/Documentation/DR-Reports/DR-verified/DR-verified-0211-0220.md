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
- Updated #Preview to use ModelContainerFactory.makeInMemoryContainer() and ServiceContainer
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
- Updated ImageHistoryView_Previews to use ModelContainerFactory.makeInMemoryContainer() and ServiceContainer
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
- **Production Code**: Updated calendar card creation to use cardRepository.createCard() instead of direct Card() instantiation
- Removed direct modelContext.insert() call - CardRepository handles insertion
- **Preview Code**: Updated to use ModelContainerFactory and ServiceContainer with cardRepository.createCard()
- Added all required environment dependencies for preview (services, cardRepository, edgeRepository, relationTypeManager)

**Note:** This view was already partially migrated (has CardRepository, EdgeRepository, and RelationTypeManager environment properties), but calendar card creation was still using direct instantiation.

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
- Migrated preview code to use CardRepository
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
- **Additional fix:** Replaced direct edge mutation loop and modelContext.save() (lines 124-128) with EdgeRepository.reassignAllEdges()
- Added EdgeRepository.reassignAllEdges() method to properly handle bulk type reassignment
- Removed direct modelContext operations from view

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
CardRelationshipOperations.swift had direct edge creation bypassing EdgeRepository, with incorrect comments claiming "acceptable exception for direct edge creation".

**Resolution:**
- Fixed ensureReverseEdge() method (lines 199-231) to use EdgeRepository.ensureReverseEdgeOf() instead of direct edge creation
- Removed incorrect comments claiming "acceptable exception for direct edge creation"
- Added EdgeRepository.ensureReverseEdgeOf(forwardEdge:mirrorType:) method
- All edge operations now properly use EdgeRepository.insertSingleEdge()
- Removed direct modelContext.insert() and EdgeIntegrityMonitor calls
- No direct modelContext operations remain in this file

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
RelationTypesManagerView.swift:231-237 directly mutated edge types and called modelContext.save() instead of using repository methods.

**Resolution:**
- Fixed nullifyEdges() method (lines 231-237) to use EdgeRepository.nullifyAllEdges() instead of direct edge mutation and modelContext.save()
- Added EdgeRepository.nullifyAllEdges(ofType:) method to properly handle edge type nullification
- Removed all direct modelContext operations from view
- All relation type operations now properly use RelationTypeManager
- All edge operations now properly use EdgeRepository

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-13*
