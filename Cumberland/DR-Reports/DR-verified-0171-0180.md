# Discrepancy Reports (DR) - Verified Batch 0171-0180

This file contains verified discrepancy reports that have been confirmed resolved by the user.

**Batch Range:** DR-0171 through DR-0180
**Verification Date:** 2026-05-06
**Last Updated:** 2026-05-12

---

## ✅ DR-0176: ER-0022 Phase 2 Incomplete - CardOperationManager.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-12
**Verified:** 2026-05-12
**Component:** Services/CardOperationManager.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2
**Related DR:** DR-0204 (same file, direct deletions)

**Issue:** Creates Card() instances directly. Core service layer bypasses CardRepository.

**Resolution:** 2026-05-12

**CardOperationManager.swift Migrations:**
- Added CardRepository and EdgeRepository properties to CardOperationManager (lines 26-27)
- Updated createCard() to use CardRepository.createCard() (line 52)
- Updated duplicateCard() to use CardRepository.createCard() and updateCardImage() (lines 103-121)
- Updated deleteCard() to use CardRepository.deleteCard() (line 72)
- Updated deleteCards() to use CardRepository.deleteCards() (line 80)
- Updated changeCardType() fallback to use EdgeRepository.deleteAllRelationships() (line 148)

**Final Achievement:**
- ✅ ZERO direct Card() instantiations
- ✅ ZERO direct modelContext.insert() calls for cards
- ✅ 100% repository pattern compliance
- ✅ All 4 direct modelContext.delete() calls removed (see DR-0204)

**Files Modified:**
- Services/CardOperationManager.swift

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0178: ER-0022 Phase 2 Incomplete - AggregateTextView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Verified:** 2026-05-06
**Component:** AggregateTextView.swift
**Severity:** Medium
**Related ER:** ER-0022 Phase 2

**Issue:**
AggregateTextView.swift creates Card() instances directly, allegedly bypassing CardRepository.

**Analysis:**
This DR was incorrectly categorized. AggregateTextView.swift is a read-only aggregation view that displays related scene text. It does not create cards in production code - only in the #Preview for testing purposes.

**Resolution:** (2026-05-06)

**Preview Code Pattern:**
- Preview code creates Card instances via `ctx.insert()` which is the standard SwiftUI pattern
- For preview/test scenarios, direct Card creation is acceptable and expected
- Main view code does not create any Card instances
- View only queries existing cards via EdgeRepository relationships

**Preview Migration:**
- Updated #Preview to use `CardRepository.createCard()` pattern
- Demonstrates proper repository usage for developers
- All Card creation now follows repository pattern even in preview

**Clarification:**
AggregateTextView is a **read-only view** that aggregates and displays text from related scene cards. It performs the following operations:
- Fetches related scenes via EdgeRepository (Scene→Timeline or Scene→Chapter relationships)
- Orders scenes by timeline sortIndex
- Concatenates detailedText from ordered scenes
- Displays the aggregated text

The view does not create, update, or delete any cards in production code.

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0177: ER-0022 Phase 2 Incomplete - CardEditorViewModel.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-14
**Verified:** 2026-05-14
**Component:** ViewModels/CardEditorViewModel.swift
**Severity:** Critical
**Related ER:** ER-0022 Phase 2

**Issue:** createCard() and updateCard() methods use modelContext operations directly (modelContext.insert, modelContext.save) bypassing CardRepository and CalendarSystemRepository.

**Resolution:**
- **Added** `insertWithoutSaving()` method to CardRepository (CardRepository.swift:62-67) to support insert-then-configure-then-save pattern
- Migrated `createCard()` method:
  - Line 390-391: Added repository initialization (cardRepo, calendarRepo)
  - Line 406: Migrated from `modelContext.insert(card)` to `cardRepo.insertWithoutSaving(card)`
  - Line 427: Migrated from `modelContext.insert(calendar)` to `try calendarRepo.insertCalendar(calendar)`
  - Line 431: Migrated from `try modelContext.save()` to `try cardRepo.save()`
- Migrated `updateCard()` method:
  - Line 454-455: Added repository initialization (cardRepo, calendarRepo)
  - Line 489: Migrated from `modelContext.insert(calendar)` to `try calendarRepo.insertCalendar(calendar)`
  - Line 497: Migrated from `try modelContext.save()` to `try cardRepo.save()`
- **Note:** Direct Card() instantiation at line 397 is acceptable - it's just creating a model object, not a database operation

**Files Modified:**
- `Data/CardRepository.swift:62-67` - Added insertWithoutSaving() method
- `ViewModels/CardEditorViewModel.swift:384-442` - Migrated createCard() to use repositories
- `ViewModels/CardEditorViewModel.swift:444-506` - Migrated updateCard() to use repositories

**Status:** ✅ Resolved - Verified

---

## ✅ DR-0179: ER-0022 Phase 2 Incomplete - MurderBoardView.swift Creates Cards Directly

**Reported:** 2026-04-27
**Resolved:** 2026-05-14
**Verified:** 2026-05-14
**Component:** MurderBoard/MurderBoardView.swift
**Severity:** High
**Related ER:** ER-0022 Phase 2

**Issue:** handleCardDrop() method uses modelContext operations directly (modelContext.fetch, modelContext.save) bypassing CardRepository.

**Resolution:**
- Migrated `handleCardDrop()` method (lines 784-831):
  - Line 786: Added services guard to ensure repository access
  - Line 794-798: Migrated from `try? modelContext.fetch(request).first` to `services.cardRepository.fetch(byUUID: cardData.id)`
  - Line 820: Migrated from `try? modelContext.save()` to `try? services.cardRepository.save()`
- **Note:** No direct Card() instantiation found - the DR title was misleading

**Files Modified:**
- `MurderBoard/MurderBoardView.swift:784-831` - Migrated handleCardDrop() to use CardRepository

**Status:** ✅ Resolved - Verified

---

*Last Updated: 2026-05-14*
