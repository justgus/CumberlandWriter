# Discrepancy Reports (DR) - Batch 10: DR-0091 to DR-0100

This file contains verified discrepancy reports DR-0091 through DR-0100.

**Batch Status:** 🚧 In Progress (4/10 verified)

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

## DR-0092: visionOS Settings Presented as Modal Sheet Instead of Window

**Status:** ✅ Resolved - Verified
**Platform:** visionOS
**Component:** visionOS, Settings, OrnamentViews
**Severity:** Medium
**Date Identified:** 2026-02-12
**Date Resolved:** 2026-02-12
**Date Verified:** 2026-02-12

**Description:**
On visionOS, tapping the Settings gear icon in the leading ornament opened a modal sheet with no dismiss controls. The ornament also displayed a close button (X) that was supposed to dismiss the Settings sheet but did not function correctly since it appeared before the sheet was opened.

**Resolution:**
- Added `Window("Settings", id: "settings")` scene definition in `CumberlandApp.swift` for visionOS
- Changed `SettingsOrnament` action from `showingSettings = true` (sheet toggle) to `openWindow(id: "settings")` (window open)
- Removed `onDismiss` parameter and close button from `SettingsOrnament` (windows have system dismiss controls)
- Removed visionOS branch from `.sheet(isPresented: $showingSettings)` in MainAppView

**Files Modified:**
- `CumberlandApp.swift` — Added visionOS Settings Window scene
- `MainAppView.swift` — Changed ornament action to `openWindow(id: "settings")`; removed visionOS branch from Settings sheet
- `visionOS/OrnamentViews.swift` — Simplified SettingsOrnament (removed dismiss button and `onDismiss` parameter)

---

## DR-0093: visionOS Developer Tools Presented as Modal Sheet Instead of Window

**Status:** ✅ Resolved - Verified
**Platform:** visionOS
**Component:** visionOS, Developer Tools, OrnamentViews
**Severity:** Medium
**Date Identified:** 2026-02-12
**Date Resolved:** 2026-02-12
**Date Verified:** 2026-02-12

**Description:**
On visionOS, the Developer Tools hammer icon in the leading ornament opened a modal sheet. The sheet included a toolbar Done button for dismissal, but the correct visionOS pattern is a standalone window. A `Window("Developer Tools", id: "dev.tools")` scene already existed in CumberlandApp.swift but was not being used — the ornament toggled a sheet boolean instead.

**Resolution:**
- Changed `DeveloperToolsOrnament` action from `showingDeveloperTools = true` to `openWindow(id: "dev.tools")`
- Removed optional `onDismiss` parameter and close button from `DeveloperToolsOrnament`
- Removed visionOS branch from `.sheet(isPresented: $showingDeveloperTools)` in MainAppView

**Files Modified:**
- `MainAppView.swift` — Changed ornament action to `openWindow(id: "dev.tools")`; removed visionOS branch from Developer Tools sheet
- `visionOS/OrnamentViews.swift` — Simplified DeveloperToolsOrnament (removed dismiss button and `onDismiss` parameter)

---

## DR-0094: Image History Restore Does Not Update CardEditorView — Stale Image Overwrites Restored Version on Save

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** CardEditorViewModel, CardEditorSheets, ImageVersionManager
**Severity:** High
**Date Identified:** 2026-02-14
**Date Resolved:** 2026-02-14
**Date Verified:** 2026-02-14

**Description:**
When restoring a previous image version from the Image History sheet (ER-0017), the restored image was correctly written to the Card model and persisted in SwiftData. However, the CardEditorViewModel held a stale snapshot of the original image data loaded when the editor opened. Tapping Save caused the stale ViewModel data to overwrite the restored image.

**Root Cause:**
`CardEditorViewModel.loadCard()` creates a one-time snapshot of image data into local properties (`imageData`, `thumbnail`). When `ImageVersionManager.restoreVersion()` updates `Card.originalImageData` directly on the model, the ViewModel's snapshot remained stale. On save, `updateCard()` called `card.setOriginalImageData(imageData)` with the stale copy.

**Resolution:**
1. Added `reloadImageFromCard(_:)` method to CardEditorViewModel — refreshes `imageData` and `thumbnail` from the Card model
2. Added `onDismiss` handler to the ImageHistory sheet in CardEditorSheets — calls `reloadImageFromCard(card)` when the sheet closes

**Files Modified:**
- `Cumberland/ViewModels/CardEditorViewModel.swift` — Added `reloadImageFromCard(_:)` method
- `Cumberland/CardEditor/CardEditorSheets.swift` — Added `onDismiss` handler to image history sheet

---

*Last Updated: 2026-02-14*
