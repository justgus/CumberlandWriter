# Discrepancy Reports (DR) - Verified Batch 0171-0180

This file contains verified discrepancy reports that have been confirmed resolved by the user.

**Batch Range:** DR-0171 through DR-0180
**Verification Date:** 2026-05-06

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

*Last Updated: 2026-05-06*
