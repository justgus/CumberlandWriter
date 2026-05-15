# Discrepancy Reports 0151-0160 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0151 through 0160.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## ✅ DR-0160: ER-0022 Phase 2 Incomplete - CumberlandApp.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-09
**Verified:** 2026-05-11
**Component:** CumberlandApp.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0132 (same file, CardEdge creation)

**Issue:** Creates Card() instances directly. App bootstrap and seed data bypasses CardRepository.

**Resolution:** 2026-05-09

**seedCalendarSystemsIfNeeded() Migration:**
- Added ServiceContainer initialization from ModelContext
- Created CalendarSystem using factory method CalendarSystem.gregorian()
- Inserted CalendarSystem via CalendarSystemRepository.insertCalendar()
- Created Card via CardRepository.createCard() instead of direct Card() instantiation
- Linked Card to CalendarSystem via calendarSystemRef property
- Added comprehensive error handling

**New CalendarSystemRepository Method:**
- Added insertCalendar() method for inserting pre-created CalendarSystem instances
- Useful for factory-created calendars like CalendarSystem.gregorian()
- Handles insert and save operations

**Files Modified:**
- CumberlandApp.swift:981 - Added ServiceContainer initialization
- CumberlandApp.swift:1003-1024 - Migrated Card creation to CardRepository.createCard()
- CumberlandApp.swift:1005 - Migrated CalendarSystem insertion to CalendarSystemRepository.insertCalendar()
- Data/CalendarSystemRepository.swift:50-63 - Added insertCalendar() method

**Status:** ✅ Resolved - Verified

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

## ✅ DR-0155: ER-0022 Phase 2 Incomplete - CardView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Verified:** 2026-05-14
**Component:** CardView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Core card display view bypasses CardRepository.

**Resolution:**
- No direct Card() instantiation found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0156: ER-0022 Phase 2 Incomplete - CitationViewer.swift Creates Cards Directly

**Reported:** 2026-04-27
**Verified:** 2026-05-14
**Component:** Citation/Views/CitationViewer.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:** Creates Card() instances directly. Citation system bypasses CardRepository.

**Resolution:**
- No direct Card() instantiation found in current code
- This DR appears to have been fixed in previous work
- View now properly uses repository pattern

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-14*
