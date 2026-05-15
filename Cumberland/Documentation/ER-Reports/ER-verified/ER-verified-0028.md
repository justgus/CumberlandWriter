# Enhancement Requests - Verified Batch (ER-0028)

This batch contains verified enhancement requests for the Timeline System Consolidation.

---

## ER-0028: Consolidate Timeline System into Dedicated Folder

**Status:** ✅ Implemented - Verified
**Component:** Timeline System Organization
**Priority:** Low
**Date Requested:** 2026-02-03
**Date Started:** 2026-02-11
**Date Implemented:** 2026-02-11
**Date Verified:** 2026-02-11
**Dependencies:** None

**Rationale:**

Timeline-related view files were scattered across the main Cumberland/ folder. Consolidating into the existing `Cumberland/Timeline/` folder improves organization and makes the timeline system easier to navigate.

**Previous State:**
- 5 timeline views in `Cumberland/` root (scattered among 50+ other files)
- 2 timeline views already in `Cumberland/Timeline/`

**New State:**
```
Cumberland/Timeline/ (7 files, consolidated)
├── CalendarDetailEditor.swift      (moved from root)
├── CalendarSystemEditor.swift      (already here)
├── CalendarSystemPicker.swift      (already here)
├── MultiTimelineGraphView.swift    (moved from root)
├── SceneTemporalPositionEditor.swift (moved from root)
├── TemporalEditorWindowView.swift  (moved from root)
└── TimelineChartView.swift         (moved from root)
```

**Files Left in Place (by design):**
- `Model/CalendarSystem.swift` — SwiftData model, stays with schema/migration files
- `Model/CalendarSystemCleanup.swift` — data cleanup utility tied to model layer
- `Model/CalendarSystemMigrationHelper.swift` — migration helper tied to model layer
- `CardEditor/CardEditorTimelineSection.swift` — extracted subview of CardEditorView (ER-0022)
- `AI/ContentAnalysis/CalendarSystemExtractor.swift` — AI extraction (ER-0027)
- `Developer/CalendarSystemCleanupView.swift` — developer diagnostic tool

**Implementation Details:**
1. Moved 5 timeline view files from Cumberland/ root to existing Timeline/ folder
2. Updated `project.pbxproj` `membershipExceptions` for both iOS and visionOS targets
3. No code changes required — Swift doesn't use path-based imports

**Build Status:**
- ✅ macOS: BUILD SUCCEEDED
- ✅ iOS: BUILD SUCCEEDED

**Verification:** ✅ User verified 2026-02-11

---

*Last Updated: 2026-02-11*
