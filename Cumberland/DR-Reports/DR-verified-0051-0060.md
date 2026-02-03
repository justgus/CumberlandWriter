# Discrepancy Reports (DR) - Batch 6: DR-0051 to DR-0060

This file contains verified discrepancy reports DR-0051 through DR-0060.

**Batch Status:** 🚧 In Progress (8/10 verified)

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

## DR-0055: Relationship Creation Timing Issue - Cancel Button Behaves Like Save

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, CardEditorView, Phase 6 (ER-0010)
**Severity:** Critical
**Date Identified:** 2026-01-26
**Date Resolved:** 2026-01-26
**Date Verified:** 2026-02-01

**Description:**

In Phase 6 (ER-0010) implementation, a critical workflow bug caused the "Cancel" button in CardEditorView to behave identically to the "Save" button when creating cards with pending relationships from AI content analysis.

**Root Cause:**

The relationship creation timing was incorrect - relationships were being created immediately when the card editor opened, rather than when the user clicked "Save". This meant that clicking "Cancel" still left the relationships in the database, making Cancel behave like Save.

**Fix Applied:**

Modified the workflow to properly defer relationship creation until save:

1. **SuggestionReviewView** - Pass pending relationships to CardEditorView via closure
2. **CardEditorView** - Accept `pendingRelationships` parameter and store them
3. **Save Logic** - Create relationships only when user clicks "Save" button
4. **Cancel Logic** - Discard pending relationships when user clicks "Cancel"

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:15-31, 253-282, 479-498` - Pass pending relationships
- `Cumberland/CardEditorView.swift:107-109, 1187-1198, 1336-1393` - Handle deferred relationships

**Verification:**
✅ Cancel button properly discards relationships
✅ Save button creates relationships as expected
✅ Workflow matches user expectations
✅ No orphaned relationships created

---

## DR-0056: SuggestionEngine Only Creating Forward Relationships (Missing Reverse Edges)

**Status:** ✅ Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** SuggestionEngine, Phase 6 (ER-0010)
**Severity:** High
**Date Identified:** 2026-01-26
**Date Resolved:** 2026-01-26
**Date Verified:** 2026-02-01

**Description:**

The `SuggestionEngine.createRelationships()` function was only creating forward edges (source → target) and not creating the corresponding reverse edges (target → source). This is inconsistent with how `CardRelationshipView` creates relationships, which always creates bidirectional pairs.

**Current Behavior (BEFORE FIX):**

When creating Captain Drake with analysis detecting 5 relationships:
1. Creates 5 entity cards (Voyager, New Haven Station, plasma rifle, compass)
2. Creates only 5 forward CardEdge entries:
   - Drake → pilots → Voyager
   - Drake → enters → New Haven Station
   - Drake → uses → plasma rifle
   - Drake → owns → compass
3. **Missing 5 reverse CardEdge entries** ❌
4. Captain Drake shows 0 relationships in UI
5. Voyager shows 1 relationship to Drake (forward edge exists)

**Expected Behavior:**

For 5 suggested relationships, create 10 total CardEdge entries (bidirectional):

**Forward edges (5):**
- Drake → [pilots] → Voyager
- Drake → [enters] → New Haven Station
- Drake → [uses] → plasma rifle
- Drake → [owns] → compass
- (5th relationship)

**Reverse edges (5) using mirror types:**
- Voyager → [piloted-by] → Drake
- New Haven Station → [is-entered-by] → Drake
- plasma rifle → [used-by] → Drake
- compass → [owned-by] → Drake
- (5th reverse)

**Root Cause:**

`SuggestionEngine.createRelationships()` in `Cumberland/AI/SuggestionEngine.swift:346-418` was only creating the forward CardEdge and did not implement the reverse edge creation that `CardRelationshipView` uses.

**Fix Applied:**

Added bidirectional relationship creation to match `CardRelationshipView` pattern:

1. For each relationship suggestion, create both forward and reverse CardEdge entries
2. Use mirror RelationType for reverse edges
3. Ensure both cards show the relationship from their perspective
4. Maintain consistency with manual relationship creation

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift:346-495` - Added bidirectional edge creation

**Verification:**
✅ Forward relationships created correctly
✅ Reverse relationships created with mirror types
✅ Both source and target cards show relationships in UI
✅ Relationship count matches expected (2× suggestions)
✅ Consistent with manual relationship creation workflow

---

## DR-0054: Edit Card Sheet on iOS - Save/Cancel Buttons Pushed Off-Screen

**Status:** ✅ Verified
**Platform:** iOS/iPadOS
**Component:** CardEditorView
**Severity:** High
**Date Identified:** 2026-01-25
**Date Resolved:** 2026-02-01
**Date Verified:** 2026-02-01

**Description:**

On iOS/iPadOS, when editing a card via the Edit Card sheet, the Save and Cancel buttons were pushed off the bottom of the sheet and were not accessible. The buttons existed in the code but the sheet layout was broken, making them impossible to reach.

**Root Cause:**

The `CardEditorView` body wrapped all content in a `VStack` (line 238) with Save/Cancel buttons at the bottom (lines 334-347), but there was no `ScrollView` wrapper. When the content exceeded the iOS sheet height (set to `.presentationDetents([.large])`), the bottom buttons were pushed outside the visible area.

**Fix Applied:**

Wrapped the entire `VStack` in a `ScrollView` so content becomes scrollable when it's taller than the sheet:

```swift
var body: some View {
    let kind = mode.kind

    // DR-0054: Wrap in ScrollView so content is accessible on iOS when sheet is smaller than content
    ScrollView {
        VStack(spacing: 16) {
            // ... all content ...

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(isEditing ? "Save" : "Create") { save() }
            }
        }
        .padding()
    }
    .frame(minWidth: 520)
    // ...
}
```

**Files Modified:**
- `Cumberland/CardEditorView.swift:235-350` - Wrapped VStack in ScrollView

**Verification:**
✅ Sheet opens with card content visible on iOS
✅ Scrolling reveals Save and Cancel buttons at bottom
✅ All content is accessible via scrolling
✅ Buttons function correctly (Save persists changes, Cancel dismisses)

---

## DR-0040: Button Text Overflow on iOS (Icon-Only Button Solution)

**Status:** ✅ Verified
**Platform:** iOS/iPadOS only
**Component:** CardEditorView, BrushGridView / Tool Palette
**Severity:** Medium
**Date Identified:** 2026-01-19
**Date Resolved:** 2026-02-01
**Date Verified:** 2026-02-02
**Scope Expanded:** 2026-02-01

**Description:**

On iOS/iPadOS, button text labels are too long to fit in the limited space (20-50 pixels) allocated to buttons in compact UI areas. This affects:

1. **CardEditorView**: Image action buttons ("Choose Image", "Generate Image", "Copy Image", "Paste Image", "Remove Image")
2. **BrushGridView**: Brush set picker showing brush set names ("Basic Tools", "Exterior Maps", "Interior Maps")

The problem is not text wrapping, but that there's simply too much text for the available space.

**Root Cause:**

Buttons were using full text labels (`Label("Choose Image…", systemImage: "photo.on.rectangle")`) on iOS where screen space is limited. The buttons already have appropriate SF Symbols icons, making the text redundant on small screens.

**Fix Applied:**

### 1. CardEditorView - Icon-Only Image Action Buttons (lines 267-316)

Made image action buttons icon-only on iOS while keeping full labels on macOS:

```swift
Button {
    isImportingImage = true
} label: {
    #if os(iOS)
    Image(systemName: "photo.on.rectangle")
    #else
    Label("Choose Image…", systemImage: "photo.on.rectangle")
    #endif
}
.help("Choose Image")
```

Applied to all five image action buttons:
- Choose Image → `photo.on.rectangle`
- Generate Image → `wand.and.stars`
- Copy Image → `doc.on.doc`
- Paste Image → `doc.on.clipboard`
- Remove Image → `trash`

### 2. BrushGridView - Icon-Only Brush Set Picker (lines 59-110)

Replaced Picker with Menu on iOS to show icon-only button, using `MapType.icon` property:

```swift
HStack {
    #if !os(iOS)
    Text("Brush Set:")
        .font(.caption)
        .foregroundStyle(.secondary)
    #endif

    #if os(iOS)
    // Use Menu instead of Picker on iOS for icon-only button
    Menu {
        ForEach(availableBrushSets()) { brushSet in
            Button {
                brushRegistry.setActiveBrushSet(id: brushSet.id)
                // Update canvas state if needed
                if let selectedBrush = brushRegistry.selectedBrush {
                    canvasState.updateToolFromBrush(selectedBrush)
                }
            } label: {
                Label(brushSet.name, systemImage: brushSet.mapType.icon)
            }
        }
    } label: {
        // Show only the icon for the selected brush set
        Image(systemName: brushSet.mapType.icon)
            .font(.subheadline)
    }
    #else
    // Use Picker on macOS with full labels
    Picker("", selection: ...) {
        ForEach(availableBrushSets()) { brushSet in
            Label(brushSet.name, systemImage: brushSet.mapType.icon)
                .tag(brushSet.id)
        }
    }
    .pickerStyle(.menu)
    #endif
}
```

**Why Menu instead of Picker**: SwiftUI's Picker with `.pickerStyle(.menu)` always displays the selected item's full label, even with `.labelsHidden()`. Using Menu gives us full control over the button appearance (icon-only) while menu items still show full text.

Brush set icons (from `MapType.icon`):
- Exterior Maps → `map.fill`
- Interior Maps → `house.fill`
- Hybrid → `square.split.2x2.fill`
- Custom → `paintpalette.fill`

### 3. Retained Line Wrapping for Filter Text

Kept the earlier line wrapping fix for the "Filtered for [layer] layer" text as additional safety.

**Files Modified:**
- `Cumberland/CardEditorView.swift:267-316` - Icon-only image action buttons on iOS
- `Cumberland/DrawCanvas/BrushGridView.swift:59-110` - Icon-only brush set picker on iOS (Menu instead of Picker)

**Verification:**
✅ CardEditorView image buttons show only icons on iOS (no text labels)
✅ BrushGridView brush set picker shows only icon on iOS (no text)
✅ All five image action buttons are visible and properly spaced
✅ Brush set picker icon updates to match selected brush set type
✅ Menu items show icons with names in dropdown when opened
✅ Layout is clean with no text overflow
✅ All buttons function correctly

---

*Last Updated: 2026-02-02*
*Status: 8/10 DRs verified in this batch*
