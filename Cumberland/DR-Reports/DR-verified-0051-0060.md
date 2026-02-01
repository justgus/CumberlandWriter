# Discrepancy Reports (DR) - Batch 6: DR-0051 to DR-0060

This file contains verified discrepancy reports DR-0051 through DR-0060.

**Batch Status:** 🚧 In Progress (4/10 verified)

---

## DR-0057: Calendar Extraction JSON Parser Fails on Null Length (Variable-Length Divisions)

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** CalendarSystemExtractor, AI Content Analysis (ER-0010)
**Severity:** Medium
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-01-30

**Description:**

The `CalendarSystemExtractor` JSON parser fails to parse calendar systems when time divisions have `null` for the `length` field. This occurs when OpenAI correctly identifies variable-length divisions like "Epochs" or "Eras" which don't have a fixed numeric length.

**Root Cause:**

The JSON parser expects all `TimeDivisionData.length` values to be integers. When OpenAI (correctly) returns `null` for variable-length divisions, the parser throws an error.

**Fix Applied:**

1. Ensured `TimeDivisionData.length` is optional (`Int?`)
2. Updated parser to handle `null` length values
3. Provided default when converting to `TimeDivision` model

**Files Modified:**
- `Cumberland/AI/CalendarSystemExtractor.swift`

**Verification:**
✅ Parser handles null length values correctly
✅ Variable-length divisions (Epochs, Eras) parse successfully
✅ Calendar system extraction works as expected

---

## DR-0058: SceneTemporalPositionEditor - Calendar Values Don't Persist When Saved

**Status:** ✅ Verified
**Platform:** All platforms (macOS specifically with window presentation)
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Critical
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-01-30

**Description:**

Calendar division values (Cycle, Season, Rotation, Segment) entered in the temporal editor were not persisting to the CardEdge's `temporalPosition` property.

**Root Causes & Fixes:**

**Fix #1:** SwiftUI binding issue
- Replaced custom `Binding()` with direct array subscript bindings: `$calendarDivisionValues[index]`
- Files: `Cumberland/SceneTemporalPositionEditor.swift:326-350`

**Fix #2:** Calendar conversion algorithm was fundamentally flawed
- Completely rewrote `convertCalendarUnitsToDate()` to handle Imperial Meridian Calendar structure
- Recognizes that Cycles and Seasons both count in Rotations (additive, not multiplicative)
- Converts to Segments (base unit) then to seconds
- Added extensive debug logging
- Files: `Cumberland/SceneTemporalPositionEditor.swift:389-453`

**Fix #3:** Calculated date display not updating
- Added explicit `displayedCalculatedDate` state variable
- Updated onChange handlers to trigger view updates
- Added calendar format display: "Cycle 1847, Season 0, Rotation 1, Segment 8"
- Shows both calendar format (primary) and Gregorian (reference)
- Files: `Cumberland/SceneTemporalPositionEditor.swift:156-187, 293-301, 397-425, 530-553`

**Fix #4:** Added extensive debugging logging (2026-01-29)
- Added initialization logging to show what values are loaded from edge
- Added save operation logging to track:
  - Edge context validity
  - Values before/after assignment
  - Save operation success/failure
  - Values after successful save
- Added window loading logging in TemporalEditorWindowView
- Files: `Cumberland/SceneTemporalPositionEditor.swift:62-96, 530-575`
- Files: `Cumberland/TemporalEditorWindowView.swift:54-87`

**Root Cause Identified:** Timeline missing epoch date (2026-01-29)
- Analysis of console logs revealed calendar conversion was never running
- The `onChange` handler checks: `if useCalendarInput, let calendar = timeline.calendarSystem, let epoch = timeline.epochDate`
- **The timeline.epochDate is nil**, causing the conversion to be skipped
- Without an epoch date, calendar values cannot be converted to absolute dates
- Calculated date defaults to today's date, which doesn't change when user enters values
- **Fix:** User must set the timeline's epoch date on the timeline card's back face (see DR-0063 for epoch date UI fix)

**Fix #5:** Added critical warnings for missing epoch date (2026-01-29)
- Initialization warns if epoch is missing: `⚠️ WARNING: Timeline has NO epoch date!`
- onChange handler logs why conversion failed
- Save operation shows critical warning: `⚠️⚠️⚠️ CRITICAL: Timeline has NO epoch date!`
- Files: `Cumberland/SceneTemporalPositionEditor.swift:90-95, 349-365, 552-560`

**Solution:**
1. Open timeline card (e.g., "Vex's Timeline")
2. Click ellipsis (⋯) → Flip to back face
3. Set **Epoch Date** field to a date (e.g., Jan 1, 1847 or today's date)
4. Set **Epoch Description** (e.g., "Beginning of Cycle 1847")
5. Save timeline
6. Try temporal editor again - calendar conversion now works

**Verification:**
✅ Calendar values entered in temporal editor persist correctly
✅ Calculated date updates in real-time showing calendar format
✅ Values survive save/reopen cycle
✅ Console logs show successful save operations
✅ Multi-Timeline Graph shows scene at correct position
✅ Epoch date warnings guide users to required setup

---

## DR-0059: SceneTemporalPositionEditor - Duration Field Redesigned for Calendar Units

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Medium
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

Duration UI was confusing with "Seconds:" field and preset picker ("15 minutes", "1 hour", etc.) User feedback: "There are no seconds in the calendar. Durations are measured in segments (hours)."

**Solution - Complete Redesign:**

**Removed:**
- Preset picker (all duration presets)
- "Seconds:" TextField
- Days/hours/minutes steppers
- All preset-related logic

**Added:**
- Calendar-aware label: "Segments:" (or calendar's smallest unit plural name)
- Direct TextField for entering duration in calendar units
- "Equivalent:" helper text showing standard time (e.g., "4 hours")
- Automatic conversion: segments × 3600 = seconds

**Example:**
- Input: User types "4" in "Segments:" field
- Calculation: 4 × 3600 = 14,400 seconds
- Display: "Equivalent: 4 hours"

**Files Modified:**
- `Cumberland/SceneTemporalPositionEditor.swift:60-62, 84-88, 197-256, 333-347`
- Removed preset enum, updateCustomDuration method, onChange handlers

**Verification:**
✅ Duration shows "Segments:" label with calendar-enabled timeline
✅ Entering "4" shows "Equivalent: 4 hours"
✅ Duration persists correctly (14,400 seconds)
✅ UI is clear and calendar-appropriate
✅ No confusing preset pickers

---

## DR-0060: Duration Presets Use "Hours" Instead of Calendar-Specific Term

**Status:** ✅ Verified - SUPERSEDED (fixed by complete redesign in DR-0059)
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Low
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

Duration presets used generic "hours" terminology instead of calendar-specific units like "segments". This DR was completely addressed by DR-0059's redesign which removed presets entirely and uses calendar-aware unit labels.

**Verification:**
✅ Issue completely resolved by DR-0059 redesign
✅ No more generic "hours" terminology
✅ Calendar-specific units used throughout

---

*Last Updated: 2026-01-30*
*Status: 4/10 DRs verified in this batch*
