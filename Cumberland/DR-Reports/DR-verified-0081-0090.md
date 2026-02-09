# Discrepancy Reports (DR) - Batch 9: DR-0081 to DR-0090

This file contains verified discrepancy reports DR-0081 through DR-0090.

**Batch Status:** 🚧 In Progress (1/10 verified)

---

## DR-0081: No Card Duplication UI

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** MainAppView / CardEditorView
**Severity:** Medium
**Date Identified:** 2026-02-08
**Date Resolved:** 2026-02-08
**Date Verified:** 2026-02-08

**Description:**
There was no UI to duplicate a card. CardOperationManager.duplicateCard() method existed per ER-0022 Phase 1, but no UI exposed it.

**Resolution:**
Added duplication UI in two places:
1. **Multi-select batch duplicate**: Duplicate button in multi-select toolbar
2. **Single-card duplicate**: "Duplicate" option in context menu (all platforms)

Features:
- Duplicates all properties: kind, name (+ " (Copy)"), subtitle, detailedText, originalImageData, epochDate, epochDescription
- Single-card duplicate auto-selects the new card
- Batch duplicate exits multi-select mode after completion
- Uses CardOperationManager.duplicateCard() when available

**Files Modified:**
- `Cumberland/MainAppView.swift:609-616` - Added Duplicate button to multi-select toolbar
- `Cumberland/MainAppView.swift:819-824` - Added Duplicate to macOS/iOS context menu
- `Cumberland/MainAppView.swift:800-805` - Added Duplicate to visionOS context menu
- `Cumberland/MainAppView.swift:1212-1262` - Added `duplicateSelectedCards()` and `duplicateCard()` helper functions

**Test Verification:**
- ✅ Right-click/long-press context menu shows "Duplicate" option
- ✅ Single duplicate creates new card with "(Copy)" suffix
- ✅ New card is auto-selected after single duplication
- ✅ Batch duplicate in multi-select mode works for multiple cards
- ✅ All card properties copied correctly (name, subtitle, description, image)

**Note:** Resolved together with DR-0079/DR-0080 (expanded multi-select actions).

---

