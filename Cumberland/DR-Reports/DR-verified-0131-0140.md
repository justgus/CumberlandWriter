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

*Last Updated: 2026-05-11*
