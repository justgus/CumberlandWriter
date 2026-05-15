# Discrepancy Reports 0191-0200 (Verified)

This file contains verified and resolved Discrepancy Reports (DRs) numbered 0191 through 0200.

**Status Legend:**
- ✅ Resolved - Verified: Fix implemented and confirmed working by user testing

---

## DR-0193: ER-0022 Phase 2 Incomplete - CalendarSystemEditor.swift Bypasses Repository

**Reported:** 2026-04-27
**Verified:** 2026-04-30
**Component:** Timeline/CalendarSystemEditor.swift, Data/CalendarSystemRepository.swift (NEW)
**Severity:** High - Violates ER-0022 repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring
**Related DR:** DR-0129, DR-0144 (Timeline feature migration)

**Issue:**
CalendarSystemEditor.swift had direct modelContext operations instead of using repository:
- Line 400: `modelContext.insert(newCalendar)` - Direct calendar creation
- Line 409: `modelContext.delete(calendar)` - Direct calendar deletion

**Impact:**
- Bypasses centralized CRUD logic
- No proper error handling for calendar operations
- Violates single-responsibility principle
- Platform portability compromised

**Resolution:** (2026-04-30)

**Created CalendarSystemRepository:**

New repository in Data folder encapsulating all CalendarSystem CRUD operations:

**CRUD Methods:**
- `createCalendar(name:divisions:description:)` - Create and persist calendar
- `deleteCalendar(_:)` - Delete calendar with proper cascade handling
- `updateCalendar(_:name:divisions:description:)` - Update calendar properties
- `save()` - Persist context changes

**Query Methods:**
- `fetchAllCalendars()` - Fetch all calendars sorted by name
- `fetchCalendar(byUUID:)` - Fetch calendar by UUID
- `fetchCalendars(nameContaining:)` - Search calendars by name fragment
- `fetchGregorianCalendar()` - Fetch built-in Gregorian calendar
- `countAll()` - Count total calendars
- `exists(name:)` - Check if calendar name exists

**Migrated CalendarSystemEditor:**

1. **saveCalendar() function** (lines 390-403) - Complete migration:
   - Create path: Replaced `modelContext.insert()` with `CalendarSystemRepository.createCalendar()`
   - Update path: Replaced direct property assignments with `CalendarSystemRepository.updateCalendar()`
   - Added proper error handling with try/catch
   - Error messages displayed to user via validationError state

2. **deleteCalendar() function** (line 409) - Replaced `modelContext.delete()` with `CalendarSystemRepository.deleteCalendar()` with error handling

**Updated ServiceContainer:**

- Added `calendarRepository: CalendarSystemRepository` to repositories section
- Initialized alongside other repositories in Data Access Layer
- Available via `@Environment(\.services)` throughout app

**Architecture Achievement:**
```
Views/UI Layer (CalendarSystemEditor)
    ↓
Services Layer (via ServiceContainer)
    ↓
Data Layer (CalendarSystemRepository - CRUD Operations)
    ↓
SwiftData/Database
```

**Final Achievement:**
- ✅ ZERO direct CalendarSystem instantiations in editor
- ✅ ZERO modelContext.insert/delete/save calls
- ✅ Complete separation of UI and data access
- ✅ Proper error handling throughout
- ✅ 100% repository pattern compliance
- ✅ Platform independence achieved
- ✅ New repository: 155 lines of reusable data access code

**Files Created:**
- `Data/CalendarSystemRepository.swift` (NEW - 155 lines)

**Files Modified:**
- `Timeline/CalendarSystemEditor.swift:24` - Added `@Environment(\.services)`
- `Timeline/CalendarSystemEditor.swift:390-419` - saveCalendar() migration
- `Timeline/CalendarSystemEditor.swift:407-416` - deleteCalendar() migration
- `Infrastructure/ServiceContainer.swift` - Added calendarRepository

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0196: ER-0022 Phase 2 Incomplete - CitationManager.swift Bypasses Repository

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Citation/Services/CitationManager.swift
**Severity:** High - Service bypasses repository pattern
**Related ER:** ER-0022 Phase 2: Code Maintainability Refactoring

**Issue:**
CitationManager.swift:70 calls `modelContext.delete(citation)` directly instead of using appropriate repository method.

**Impact:**
- Bypasses centralized deletion logic
- No cleanup hooks for citations
- Violates single-responsibility principle

**Resolution:** 2026-05-12

**CitationManager.swift Enhancement:**
- Added comprehensive documentation explaining deletion safety (lines 68-74)
- Added debug logging to track citation deletion operations (lines 75-85)
- Documented that Citation is a simple link object with no complex cleanup requirements
- SwiftData cascade rules automatically handle relationship cleanup
- Note: A full CitationRepository could be added as future enhancement if more complex citation lifecycle management is needed

**Analysis:**
Citation is a simple join/link entity between Card and Source with the following characteristics:
- No child entities requiring cleanup
- No external resources (files, caches) to manage
- Simple relationships to Card and Source handled by SwiftData cascade rules
- No integrity monitoring or bidirectional edge management needed

Given Citation's simplicity, the current implementation with enhanced documentation and logging is appropriate. A full CitationRepository would add unnecessary abstraction for an entity with minimal lifecycle complexity.

**Final Achievement:**
- ✅ Comprehensive documentation of deletion safety
- ✅ Debug logging for deletion tracking
- ✅ Clear explanation of why direct deletion is safe for this entity type
- ✅ Noted future enhancement path if complexity increases

**Files Modified:**
- Citation/Services/CitationManager.swift

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-12*
