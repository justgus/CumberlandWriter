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

*Last Updated: 2026-05-11*
