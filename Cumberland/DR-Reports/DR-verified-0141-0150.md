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

*Last Updated: 2026-04-30*
