# Discrepancy Reports 0141-0150 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0141 through 0150.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## DR-0144: ER-0022 Phase 2 Incomplete - SceneTemporalPositionEditor.swift Not Migrated

**Reported:** 2026-04-27
**Verified:** 2026-04-30
**Component:** Timeline/SceneTemporalPositionEditor.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0129 (Timeline feature migration)

**Issue:** Creates CardEdge instances directly and uses direct modelContext.save() calls. Timeline feature bypasses EdgeRepository.

**Resolution:** (2026-04-30)

**Save Operation Migrations:**

1. **save() function** (line 824) - Replaced `modelContext.save()` with `EdgeRepository.save()` after modifying edge temporal properties.

2. **clearPosition() function** (line 842) - Replaced `modelContext.save()` with `EdgeRepository.save()` after clearing temporal properties.

**Preview Migration:**

3. **Preview code** (lines 853-897) - Complete migration to repository pattern:
   - Cards created via `CardRepository.createCard()`
   - Edge creation via `EdgeRepository.createRelationship()`
   - Edge retrieval via `EdgeRepository.fetchOutgoing()` to set temporal properties
   - Added `ServiceContainer` injection for preview
   - Removed direct `Card()` instantiations (2 instances)
   - Removed direct `CardEdge()` instantiation (1 instance)
   - Removed direct `ctx.insert()` calls for Cards and Edges

**Architecture Improvements:**

- Added `@Environment(\.services)` to access EdgeRepository
- All `modelContext.save()` calls replaced with `EdgeRepository.save()`
- All direct Card/CardEdge instantiations eliminated from preview
- Proper error handling with guard statements

**Final Achievement:**
- ✅ ZERO direct CardEdge instantiations
- ✅ ZERO direct modelContext.save() calls
- ✅ 100% repository pattern compliance
- ✅ Platform independence achieved

**Files Modified:**
- `Timeline/SceneTemporalPositionEditor.swift:22` - Added `@Environment(\.services)`
- `Timeline/SceneTemporalPositionEditor.swift:824-830` - save() migration
- `Timeline/SceneTemporalPositionEditor.swift:842-849` - clearPosition() migration
- `Timeline/SceneTemporalPositionEditor.swift:853-897` - Preview migration

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0148: ER-0022 Phase 2 Incomplete - SuggestionEngine.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-06
**Verified:** 2026-05-09
**Component:** AI/ContentAnalysis/SuggestionEngine.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. AI suggestion system bypasses CardRepository.

**Resolution:** 2026-05-06
This issue was resolved as part of DR-0131. See DR-0131 for complete migration details.

**Summary:**
- Migrated createCards() method to use CardRepository.createCard()
- Removed direct Card() instantiation and context.insert() calls
- Updated all call sites (SuggestionReviewView, CardEditorViewModel)
- Achieved 100% repository pattern compliance

**Files Modified:**
- AI/ContentAnalysis/SuggestionEngine.swift (core engine)
- AI/Views/SuggestionReviewView.swift (UI caller)
- ViewModels/CardEditorViewModel.swift (view model caller)

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0141: ER-0022 Phase 2 Incomplete - SettingsView.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** SettingsView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (line 1549). Settings view bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Preview Migration:**
- Migrated Preview (lines 1536-1578) to use ModelContainerFactory, RelationTypeManager, CardRepository, EdgeRepository
- Preview now uses standard repository pattern with ServiceContainer injection
- Added @MainActor in to Preview closure
- Build verified successful

**Citation Query Migration:**
- Added @Environment(\.services) to ImagesSettingsPane (line 750)
- Migrated hasAnyImageAttribution() to use QueryService.hasCitations(for:kind:) instead of FetchDescriptor (lines 940-943)
- Added 3 Citation query methods to QueryService: getCitations(for:), getCitations(for:kind:), hasCitations(for:kind:)

**Files Modified:**
- SettingsView.swift:750 - Added @Environment(\.services) to ImagesSettingsPane
- SettingsView.swift:940-943 - Migrated hasAnyImageAttribution() to use QueryService
- SettingsView.swift:1536-1578 - Migrated Preview to use repositories
- Data/QueryService.swift:91-134 - Added Citation query methods

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0142: ER-0022 Phase 2 Incomplete - Swimlane.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** Swimlane.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly. Swimlane feature bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services)
- Migrated fetchCard(by:) to use CardRepository.fetch(byUUID:)
- Migrated defaultRelationType() to use RelationTypeManager.ensureRelationType()
- Migrated edgeFor(from:to:type:) to use EdgeRepository.fetchOutgoing() with in-memory filtering
- Migrated neighborIndicesForInsertion(at:) to use EdgeRepository.fetchIncoming() with manual sorting
- Migrated insertCardIntoLane() to use EdgeRepository.createRelationship() with sortIndex parameter
- Migrated removeCardFromLane() to use EdgeRepository.fetchOutgoing() and EdgeRepository.deleteEdge()

**Preview Migration:**
- Migrated both Preview functions to use ModelContainerFactory, RelationTypeManager, CardRepository, EdgeRepository
- Build verified successful

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0143: ER-0022 Phase 2 Incomplete - SwimlaneViewer.swift Not Migrated

**Reported:** 2026-04-27
**Resolved:** 2026-05-11
**Verified:** 2026-05-11
**Component:** SwimlaneViewer.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates CardEdge instances directly (lines 269, 307-309, 316-317, 326+). Swimlane feature bypasses EdgeRepository.

**Resolution:** 2026-05-11

**Main View Migration:**
- Added @Environment(\.services)
- Migrated orderedRelatedCards() to use EdgeRepository.fetchIncoming() with manual sorting and filtering
- Migrated defaultRelationType() to use RelationTypeManager.ensureRelationType()
- Migrated edgeExists() to use EdgeRepository.fetchOutgoing() with in-memory filtering
- Migrated relateCardAppend() to use CardRepository.fetch(byUUID:) and EdgeRepository.createRelationship() with sortIndex

**Preview Migration:**
- Migrated both Preview functions (Light and Dark) to use ModelContainerFactory, RelationTypeManager, CardRepository, EdgeRepository
- Added @MainActor in to Preview closures
- Build verified successful

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-11*
