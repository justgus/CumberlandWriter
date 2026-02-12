# Discrepancy Reports (DR) - Batch 10: DR-0091 to DR-0100

This file contains verified discrepancy reports DR-0091 through DR-0100.

**Batch Status:** 🚧 In Progress (1/10 verified)

---

## DR-0091: Custom Calendar Date Entry Does Not Update Temporal Position

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor
**Severity:** High
**Date Identified:** 2026-02-11
**Date Resolved:** 2026-02-11
**Date Verified:** 2026-02-11

**Description:**
Custom calendar division value entry did not correctly update the temporal position. The conversion function was hardcoded for the Imperial Meridian Calendar's specific division names. Additionally, the Gregorian calendar's variable-length months (28-31 days) caused incorrect date calculations through the uniform division-based conversion (336 days/year instead of 365.25).

**Resolution:**
- Rewrote `convertCalendarUnitsToDate()` to be fully generic — uses each division's `length` property to calculate hierarchically from largest to smallest, regardless of division names
- Rewrote `formatDateInCalendar()` to decompose dates generically using division lengths
- The onChange handler now uses `resolvedEpoch` (from DR-0089) so it no longer silently fails for standard calendars
- Standard calendars (Gregorian/Julian): Custom Calendar input mode toggle is hidden — the division-based conversion cannot handle variable-length months. The Standard Date fields (DR-0090) provide correct year/month/day entry.
- Custom Calendar mode remains available for fictional calendars with uniform division lengths
- All numeric TextFields use `.grouping(.never)` to prevent comma separators

**Algorithm:**
Walks divisions from largest (last) to smallest (first), accumulating: `total = total * divisions[i].length + values[i]`. The smallest unit's real-time duration is inferred from its name (second=1s, minute=60s, hour/segment=3600s).

**Files Modified:**
- `Cumberland/Timeline/SceneTemporalPositionEditor.swift` — `convertCalendarUnitsToDate()`, `formatDateInCalendar()`, dynamic help text, hidden toggle for standard calendars, `.grouping(.never)` on all numeric fields

**Related Issues:**
- DR-0089 (Gregorian calendar epoch auto-configuration) — resolved together
- DR-0090 (Standard date picker usability) — resolved together

---

*Last Updated: 2026-02-11*
