# Discrepancy Reports 0131-0140 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0131 through 0140.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## ✅ DR-0131: ER-0022 Phase 2 Incomplete - SuggestionEngine.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-06
**Verified:** 2026-05-09
**Component:** AI/ContentAnalysis/SuggestionEngine.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 582, 649) and performs direct modelContext queries. Never migrated to EdgeRepository.

**Resolution:** 2026-05-06

**SuggestionEngine.swift Migrations:**
- **createCards() method** (lines 505-529): Migrated to use `CardRepository.createCard()` instead of direct Card() instantiation and context.insert()
- **createRelationships() method** (lines 534-604): Migrated to use `EdgeRepository.createRelationship()` for bidirectional relationship creation instead of manual forward/reverse edge creation
- **relationshipExists() method** (lines 665-667): Simplified to use `EdgeRepository.exists()` instead of direct FetchDescriptor queries
- **findOrCreateRelationType() method** (lines 609-620): Updated to accept RelationTypeManager as parameter
- **ensureReverseEdge() method**: Removed entirely (44 lines) - EdgeRepository.createRelationship() handles reverse edges automatically

**Call Site Migrations:**
- **SuggestionReviewView.swift**: Added EdgeRepository, CardRepository, and RelationTypeManager environment dependencies, updated both createCards() and createRelationships() calls, migrated Card fetch from FetchDescriptor to CardRepository.fetchAll()
- **CardEditorViewModel.swift**: Added edgeRepository and relationTypeManager dependencies, updated createPendingRelationships() to use repositories, migrated Card fetch to CardRepository.fetchAll()

**Final Achievement:**
- ✅ ZERO direct Card() instantiations
- ✅ ZERO direct CardEdge() instantiations
- ✅ ZERO FetchDescriptor queries
- ✅ ZERO modelContext.fetch/insert calls
- ✅ Removed 44 lines of manual reverse edge creation code
- ✅ 100% repository pattern compliance
- ✅ Platform independence achieved

**Files Modified:**
- AI/ContentAnalysis/SuggestionEngine.swift (core engine)
- AI/Views/SuggestionReviewView.swift (UI caller)
- ViewModels/CardEditorViewModel.swift (view model caller)

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0132: ER-0022 Phase 2 Incomplete - CumberlandApp.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-09
**Verified:** 2026-05-11
**Component:** CumberlandApp.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0160 (same file, Card creation)

**Issue:** Creates CardEdge instances directly (lines 879, 1708). App bootstrap code bypasses EdgeRepository.

**Resolution:** 2026-05-09

**backfillSceneProjectStoriesEdgesIfNeeded() Migration:**
- Added ServiceContainer initialization from ModelContext
- Replaced direct CardEdge(from:to:type:) creation with EdgeRepository.createRelationship()
- Removed manual EdgeIntegrityMonitor.incrementCounts() calls (handled by repository)
- Removed manual ctx.save() (handled by repository)
- Added error handling for relationship creation

**FixIncompleteRelationshipsView (runRepair) Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Added guard statement to safely unwrap services
- Replaced direct CardEdge creation with EdgeRepository.insertSingleEdge() for legacy repair tool
- Replaced direct RelationType creation with RelationTypeManager.ensureRelationType()
- Added proper error handling for edge and type creation
- Fixed string interpolation syntax error

**New EdgeRepository Method:**
- Added insertSingleEdge() method for special cases like legacy repair tools
- Method creates single edge without automatic reverse (for repair scenarios)
- Includes EdgeIntegrityMonitor.incrementCounts() and save()

**Follow-up Refactoring (2026-05-11):**
- Migrated FixIncompleteRelationshipsView to use DataIntegrityManager.repairIncompleteRelationships()
- Simplified view to delegate all repair logic to DataIntegrityManager
- Returns structured RepairReport with detailed logging

**Files Modified:**
- CumberlandApp.swift:824 - Added ServiceContainer initialization
- CumberlandApp.swift:884-895 - Migrated backfill edge creation to EdgeRepository.createRelationship()
- CumberlandApp.swift:1540 - Added @Environment(\.services)
- CumberlandApp.swift:1650-1657 - Added services guard statement
- CumberlandApp.swift:1706-1713 - Migrated RelationType creation to RelationTypeManager
- CumberlandApp.swift:1721-1734 - Migrated edge creation to EdgeRepository.insertSingleEdge()
- CumberlandApp.swift:788-798 - Migrated FixIncompleteRelationshipsView.runRepair() to use DataIntegrityManager
- Data/EdgeRepository.swift:277-318 - Added insertSingleEdge() method

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0133: ER-0022 Phase 2 Incomplete - CardDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/CardDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0161 (same file, Card creation)

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Replaced direct FetchDescriptor query with EdgeRepository.fetchOutgoing(from:)
- Added guard statement to safely unwrap services

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Replaced direct CardEdge() instantiation with EdgeRepository.createRelationship()
- Replaced direct RelationType creation with RelationTypeManager.ensureRelationType()
- Updated to use ModelContainerFactory.makeInMemoryContainer() for preview container
- Added ServiceContainer injection for preview

**Files Modified:**
- Diagnostic Views/CardDiagnosticsView.swift:16 - Added @Environment(\.services)
- Diagnostic Views/CardDiagnosticsView.swift:85-97 - Migrated reloadForwardEdges() to use EdgeRepository.fetchOutgoing()
- Diagnostic Views/CardDiagnosticsView.swift:108-142 - Migrated Preview to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0134: ER-0022 Phase 2 Incomplete - RecentEdgesDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/RecentEdgesDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0164 (same file, Card creation)

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Replaced FetchDescriptor query with EdgeRepository.fetchRecentlyCreated(limit:50)

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Replaced direct CardEdge() instantiation with EdgeRepository.createRelationship()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Files Modified:**
- Diagnostic Views/RecentEdgesDiagnosticsView.swift:16 - Added services environment
- Diagnostic Views/RecentEdgesDiagnosticsView.swift:69-72 - Migrated to EdgeRepository.fetchRecentlyCreated()
- Diagnostic Views/RecentEdgesDiagnosticsView.swift:85-135 - Migrated Preview to repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0135: ER-0022 Phase 2 Incomplete - RelationshipAuditView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/RelationshipAuditView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0199 (same file, direct edge deletion)

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Duplicate Card Migration:**
- Replaced direct CardEdge() creation in deleteDuplicateCard() with EdgeRepository.insertSingleEdge()
- Used insertSingleEdge() for migrating edges from duplicate to primary card (lines 514, 537)
- Appropriate for one-way edge migration during repair operations

**Orphan Edge Repair:**
- Replaced direct modelContext.delete(edge) with EdgeRepository.deleteEdge()
- Used in repairOrphanEdges() function (line 586)

**Additional Query Removal (2026-05-11):**
- Replaced @Query private var allCards with @State + QueryService
- Replaced all FetchDescriptor usages with EdgeRepository and QueryService methods
- Updated comments to reference EdgeRepository instead of FetchDescriptor
- Added reloadData() method with .task modifier

**Files Modified:**
- Diagnostic Views/RelationshipAuditView.swift:21 - Replaced @Query with @State
- Diagnostic Views/RelationshipAuditView.swift:58-67 - Added reloadData() and .task
- Diagnostic Views/RelationshipAuditView.swift:408-414 - Migrated to EdgeRepository methods
- Diagnostic Views/RelationshipAuditView.swift:433-435 - Migrated to QueryService.getAllEdges()
- Diagnostic Views/RelationshipAuditView.swift:489-543 - Migrated all FetchDescriptor queries to repositories
- Diagnostic Views/RelationshipAuditView.swift:514-517 - Migrated outgoing edge creation to EdgeRepository.insertSingleEdge()
- Diagnostic Views/RelationshipAuditView.swift:537-540 - Migrated incoming edge creation to EdgeRepository.insertSingleEdge()
- Diagnostic Views/RelationshipAuditView.swift:586 - Migrated orphan edge deletion to EdgeRepository.deleteEdge()

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0136: ER-0022 Phase 2 Incomplete - RelationTypesDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Diagnostic Views/RelationTypesDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0165 (same file, Card creation), DR-0200 (same file, direct relation type deletion)

**Issue:** Creates CardEdge instances directly. Diagnostic view bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Replaced direct modelContext.delete(type) with RelationTypeManager.deleteRelationType() (lines 146, 217)

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Replaced direct CardEdge() instantiation with EdgeRepository.createRelationship()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Additional Query Removal (2026-05-11):**
- Replaced @Query private var types with @State + QueryService
- Replaced FetchDescriptor usages with QueryService.getAllRelationTypes()
- Added reloadData() method with .task modifier and manual sorting
- Added reloadData() call after duplicate removal

**Files Modified:**
- Diagnostic Views/RelationTypesDiagnosticsView.swift:17 - Replaced @Query with @State
- Diagnostic Views/RelationTypesDiagnosticsView.swift:63-76 - Added reloadData() and .task
- Diagnostic Views/RelationTypesDiagnosticsView.swift:146-149 - Migrated deleteType() to use RelationTypeManager.deleteRelationType()
- Diagnostic Views/RelationTypesDiagnosticsView.swift:177-179 - Migrated to QueryService.getAllRelationTypes()
- Diagnostic Views/RelationTypesDiagnosticsView.swift:217-220 - Migrated duplicate deletion to use RelationTypeManager.deleteRelationType()
- Diagnostic Views/RelationTypesDiagnosticsView.swift:249-298 - Migrated Preview to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0137: ER-0022 Phase 2 Incomplete - ReassignRelationTypeSheet.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** ReassignRelationTypeSheet.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Critical relationship management UI bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Migrated loadUsage() to use EdgeRepository.fetch(ofType:) instead of FetchDescriptor
- Migrated loadCandidates() to use QueryService.getAllRelationTypes() instead of FetchDescriptor
- Migrated reassign() to use EdgeRepository.fetch(ofType:) for fetching edges
- Migrated RelationType deletion to use RelationTypeManager.deleteRelationType() instead of modelContext.delete()

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Replaced direct RelationType() instantiation with RelationTypeManager.ensureRelationType()
- Replaced direct CardEdge() instantiation with EdgeRepository.createRelationship()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Files Modified:**
- ReassignRelationTypeSheet.swift:21 - Added @Environment(\.services)
- ReassignRelationTypeSheet.swift:99-103 - Migrated loadUsage() to EdgeRepository.fetch(ofType:)
- ReassignRelationTypeSheet.swift:107-111 - Migrated loadCandidates() to QueryService.getAllRelationTypes()
- ReassignRelationTypeSheet.swift:115-135 - Migrated reassign() to use EdgeRepository and RelationTypeManager
- ReassignRelationTypeSheet.swift:138-172 - Migrated Preview to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0138: ER-0022 Phase 2 Incomplete - RelationTypesManagerView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** RelationTypesManagerView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (line 265). Core relationship type management bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services) to access ServiceContainer
- Replaced @Query with @State + QueryService.getAllRelationTypes()
- Added reloadData() method with .task modifier
- Migrated usageCount() to use EdgeRepository.fetch(ofType:) instead of FetchDescriptor
- Migrated nullifyEdges() to use EdgeRepository.fetch(ofType:) instead of FetchDescriptor
- Migrated delete() to use RelationTypeManager.deleteRelationType() instead of modelContext.delete()
- Migrated deleteAllUnused() to use RelationTypeManager.deleteRelationType() instead of modelContext.delete()
- Added Task { await reloadData() } calls after delete operations

**Preview Migration:**
- Replaced direct Card() instantiation with CardRepository.createCard()
- Replaced direct RelationType() instantiation with RelationTypeManager.ensureRelationType()
- Replaced direct CardEdge() instantiation with EdgeRepository.createRelationship()
- Updated to use ModelContainerFactory.makeInMemoryContainer()
- Added ServiceContainer injection

**Files Modified:**
- RelationTypesManagerView.swift:16 - Added @Environment(\.services)
- RelationTypesManagerView.swift:19 - Replaced @Query with @State
- RelationTypesManagerView.swift:53-56 - Added .task { await reloadData() }
- RelationTypesManagerView.swift:107-113 - Added reloadData() method
- RelationTypesManagerView.swift:224-229 - Migrated usageCount() to EdgeRepository.fetch(ofType:)
- RelationTypesManagerView.swift:231-237 - Migrated nullifyEdges() to EdgeRepository.fetch(ofType:)
- RelationTypesManagerView.swift:239-243 - Migrated delete() to RelationTypeManager.deleteRelationType()
- RelationTypesManagerView.swift:249-256 - Migrated deleteAllUnused() to RelationTypeManager.deleteRelationType()
- RelationTypesManagerView.swift:260-298 - Migrated Preview to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0139: ER-0022 Phase 2 Incomplete - SceneProjectRelationDiagnosticsView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** SceneProjectRelationDiagnosticsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 343, 345). Diagnostic view bypasses EdgeRepository.

**Resolution:**
- Added @Environment(\.services)
- Migrated loadNonCanonicalEdges() to use QueryService.getAllEdges() with manual filtering and sorting
- Migrated normalizeAll() to use QueryService.getAllEdges()
- Migrated normalize() to use QueryService.getAllEdges()
- Migrated Preview to use ModelContainerFactory, RelationTypeManager, CardRepository, EdgeRepository
- Build verified successful

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0140: ER-0022 Phase 2 Incomplete - RelationshipManager.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Services/RelationshipManager.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0205 (same file, direct edge deletion)

**Issue:** Creates CardEdge instances directly. Core service layer bypasses EdgeRepository.

**Resolution:** 2026-05-12

**RelationshipManager.swift Migrations:**
- Added EdgeRepository property to RelationshipManager (line 26)
- Updated createRelationship() to use EdgeRepository.createRelationship() and insertSingleEdge() (lines 47-69)
- Removed obsolete createReverseEdge() method (31 lines removed)
- Updated removeRelationship() to use EdgeRepository.deleteRelationship() and deleteAllRelationships() (lines 90-105)
- Updated removeEdge() to use EdgeRepository.deleteEdge() (line 114)
- Updated removeAllEdges() to use EdgeRepository.deleteAllRelationships() and fetchAll() (lines 129-135)
- Updated all query methods to delegate to EdgeRepository (getOutgoingEdges, getIncomingEdges, getAllEdges, relationshipExists)

**Final Achievement:**
- ✅ ZERO direct CardEdge() instantiations
- ✅ ZERO direct modelContext.insert() calls for edges
- ✅ 100% repository pattern compliance
- ✅ All 7 direct modelContext.delete() calls removed (see DR-0205)

**Files Modified:**
- Services/RelationshipManager.swift

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-12*
