# Discrepancy Reports (DR) - Batch 7: DR-0061 to DR-0070

This file contains verified discrepancy reports DR-0061 through DR-0070.

**Batch Status:** 🚧 In Progress (6/10 verified)

---

## DR-0061: SceneTemporalPositionEditor Sheet Renders as Blank 100x100 Square on Initial Display (macOS)

**Status:** ✅ Verified
**Platform:** macOS
**Component:** SceneTemporalPositionEditor, TimelineChartView, ER-0016 Phase 2
**Severity:** High
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

When opening the SceneTemporalPositionEditor sheet, it initially renders as a blank 100x100 pixel square. Content only appears after clicking away from app and returning. User also reports ViewBridge error: `Error Domain=com.apple.ViewBridge Code=18 "NSViewBridgeErrorCanceled"`.

**Fix Attempts (All Failed):**

**Attempt 1:** Added explicit `.frame(minWidth: 560, minHeight: 640)` to sheet
- Result: Sheet sized correctly but content still blank

**Attempt 2:** Added Form layout hints (`.frame(maxWidth: .infinity)`, `.layoutPriority(1)`)
- Result: No change, still fails

**Attempt 3:** Replaced Form with ScrollView + VStack
- Result: Still fails on first render

**Root Cause:**
SwiftUI sheet presentation has known bugs on macOS with complex content. ViewBridge error suggests view hierarchy initialization issues.

**Solution Implemented:**

Replaced `.sheet()` with WindowGroup-based presentation on macOS only:

1. **Created TemporalEditorRequest data structure** (`AppModel.swift:42-56`)
   - Stores sceneID and timelineID for window presentation
   - Codable, Hashable, Identifiable for WindowGroup binding

2. **Created TemporalEditorWindowView wrapper** (`TemporalEditorWindowView.swift`)
   - Fetches Card and CardEdge entities from modelContext
   - Wraps SceneTemporalPositionEditor in window
   - Posts notification when window closes to trigger data reload

3. **Added WindowGroup for temporal editor** (`CumberlandApp.swift:289-296`)
   - Binds to AppModel.TemporalEditorRequest
   - Default size: 560x640
   - Includes modelContainer and preferredColorScheme

4. **Modified TimelineChartView presentation** (`TimelineChartView.swift`)
   - Added `@Environment(\.openWindow)` on macOS (line 16-18)
   - Replaced sheet with onChange handler that opens window (lines 223-246)
   - Added onReceive for window close notification (lines 182-189)
   - iOS/iPadOS continues using sheet presentation (lines 204-220)

5. **Added notification mechanism** (`TemporalEditorWindowView.swift:12-15`)
   - `.temporalEditorDidClose` notification
   - Posted on window dismiss
   - TimelineChartView listens and reloads data

**Files Modified:**
- `Cumberland/AppModel.swift:42-56` - Added TemporalEditorRequest struct
- `Cumberland/TemporalEditorWindowView.swift` - New file (window wrapper)
- `Cumberland/CumberlandApp.swift:289-296` - Added WindowGroup
- `Cumberland/TimelineChartView.swift:16-18, 182-189, 204-246` - Platform-conditional presentation

**Verification:**
✅ Window opens immediately with full content visible (no blank square)
✅ No ViewBridge errors in console
✅ Temporal position and duration editing works correctly
✅ Timeline view reloads when window closes
✅ Values persist correctly across open/close cycles
✅ iOS/iPadOS continue to use sheet presentation without issues

---

## DR-0062: SceneTemporalPositionEditor Has Duplicate Save Buttons (Done + Save)

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** SceneTemporalPositionEditor, ER-0016 Phase 2
**Severity:** Low
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

The SceneTemporalPositionEditor view had two buttons that both save and dismiss:
1. "Done" button in header (line 112)
2. "Save" button in footer action buttons (line 330)

Both called `saveAndDismiss()`, creating confusion about which button to use.

**Root Cause:**

Redundant "Done" button was left in header when footer action buttons were added.

**Fix Applied:**

Removed "Done" button from header, keeping only the "Save" button in the footer alongside "Cancel" and "Clear Position" buttons.

**Files Modified:**
- `Cumberland/SceneTemporalPositionEditor.swift:100-118` - Removed Done button and HStack wrapper from header

**Code Changes:**

```swift
// BEFORE:
HStack {
    VStack(alignment: .leading, spacing: 4) {
        Text("Temporal Position")
            .font(.title2.bold())
        Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    Spacer()
    Button("Done") {
        saveAndDismiss()
    }
    .keyboardShortcut(.defaultAction)
    .buttonStyle(.borderedProminent)
}

// AFTER:
VStack(alignment: .leading, spacing: 4) {
    Text("Temporal Position")
        .font(.title2.bold())
    Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
```

**Result:**

✅ Single "Save" button in footer
✅ Clear action button layout: Cancel | Clear Position | Save
✅ No confusion about which button to use

**Verification:**
✅ Only one "Save" button appears (in footer)
✅ No "Done" button in header
✅ Footer has three buttons: Cancel, Clear Position, and Save
✅ UI is clear and unambiguous

---

## DR-0063: Timeline Epoch Date UI Unclear/Not Persisting

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** CardEditorView, Timeline Configuration Panel, ER-0016 Phase 2
**Severity:** High
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

User reports that when editing a timeline's back face, they can set the "Epoch Description" text field but the actual "Epoch Date" (Date value) remains nil. The DatePicker appears to show today's date but never actually sets the `epochDate` property.

**Root Cause:**

The DatePicker Binding uses `epochDate ?? Date()` in the getter, which **displays** today's date even when `epochDate` is nil. However, the setter is only called when the user actively clicks and changes the date. If the user sees today's date and doesn't interact with it (expecting it to auto-accept), the `epochDate` property remains nil.

**User Experience:**
1. User selects calendar system
2. DatePicker appears showing today's date (from `?? Date()` fallback)
3. User assumes this date is set and proceeds
4. **But `epochDate` is still nil** because they never clicked the picker
5. Calendar conversion silently fails due to missing epoch

**Fix Applied:**

**Fix #1: Enhanced UI (CardEditorView.swift:900-930):**
1. Added bold heading: "Epoch Date (Required for calendar conversion)"
2. Added warning message when epochDate is nil: "⚠️ Warning: No epoch date set..."
3. Improved help text explaining the epoch concept
4. Wrapped in VStack for better layout

**Fix #2: Auto-Initialization (CardEditorView.swift:936-942):**
Added `.onChange(of: selectedCalendar)` that automatically sets `epochDate = Date()` when a calendar is first selected. This ensures the displayed date is actually stored.

**Fix #3: Debug Logging:**
- DatePicker getter logs when value is read (shows if nil vs actual date)
- DatePicker setter logs when value changes
- onChange logs auto-initialization
- Create/save operations log the final epoch date value
- Files: `CardEditorView.swift:903-911, 936-942, 1379-1386, 1445-1452`

**Code Changes:**

```swift
// BEFORE:
if selectedCalendar != nil {
    DatePicker("Epoch Date", selection: Binding(...))
        .datePickerStyle(.compact)
    TextField("Epoch Description (optional)", text: $epochDescription)
    Text("The epoch is the starting point...")
}

// AFTER:
if selectedCalendar != nil {
    VStack(alignment: .leading, spacing: 8) {
        Text("Epoch Date (Required for calendar conversion)")
            .font(.subheadline.bold())

        DatePicker("Epoch Date", selection: Binding(
            get: {
                let current = epochDate ?? Date()
                print("📅 [CardEditorView] DatePicker get: \(epochDate == nil ? "nil" : current)")
                return current
            },
            set: { newValue in
                print("📅 [CardEditorView] DatePicker set: \(newValue)")
                epochDate = newValue
            }
        ))

        if epochDate == nil {
            Text("⚠️ Warning: No epoch date set...")
                .foregroundStyle(.orange)
        }

        TextField("Epoch Description (optional)", text: $epochDescription)
        Text("The epoch is the starting point/zero-date for this timeline. Example: Jan 1, 1847")
    }
}
.onChange(of: selectedCalendar) { oldValue, newValue in
    // Auto-initialize epoch date when calendar is first selected
    if newValue != nil && oldValue == nil && epochDate == nil {
        epochDate = Date()
        print("📅 [CardEditorView] Auto-initialized epochDate to today: \(epochDate!)")
    }
}
```

**Files Modified:**
- `Cumberland/CardEditorView.swift:900-942, 1379-1386, 1445-1452`

**Verification:**
✅ DatePicker auto-initializes to today's date when calendar selected
✅ Console shows auto-initialization message
✅ No orange warning appears (date is set)
✅ Date can be changed if desired
✅ Epoch date persists correctly when timeline saved
✅ Calendar temporal positioning works in SceneTemporalPositionEditor
✅ UI clearly indicates when epoch date is required

---

## DR-0064: Timeline Tab Freezes When Epoch Date Far from Scene Dates

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** TimelineChartView, ER-0016 Phase 2
**Severity:** Critical
**Date Identified:** 2026-01-29
**Date Resolved:** 2026-01-29
**Date Verified:** 2026-01-30

**Description:**

When opening the Timeline tab for a timeline with an epoch date far in the past (e.g., 1847) but scenes positioned in the present (e.g., 2026), the app freezes at 100% CPU during Chart rendering. The view fails to initialize and becomes completely unresponsive.

**Affected Timeline:**
- Vex's Timeline: epoch date 1847-01-01, scenes at 2026-01-29
- Display range: 179 years (1847 to 2026)

**Root Cause:**

The TimelineChartView was forcing the epoch date into the display range:

```swift
let epochDate = timeline.epochDate ?? minDate
let displayMinDate = min(epochDate, minDate)  // Forces epoch into range
let displayMaxDate = max(epochDate.addingTimeInterval(86400), maxDate)
```

When the epoch is set to a historical date (1847) but scenes exist in modern times (2026), this creates an extremely wide date range (179 years). The SwiftUI Charts component attempts to calculate axis ticks, positions, and render the entire range, causing:
- Infinite loop in axis calculations
- Memory overflow from generating tick marks
- UI thread freeze during layout

**Diagnostic Process:**

Added comprehensive logging throughout TimelineChartView body and temporalChartArea. Console output showed:
```
📊 [TimelineChartView] temporalChartArea: displayMinDate = 1847-01-01 12:56:15 +0000, displayMaxDate = 2026-01-30 00:49:51 +0000
📊 [TimelineChartView] temporalChartArea: about to return Chart view
[FREEZE - no further output]
```

Execution completed all date calculations successfully but froze when attempting to render the Chart view itself.

**Fix Applied:**

Changed display range to focus on scenes, not try to fit the entire timeline (epoch to latest scene) in one view:

```swift
// BEFORE:
let epochDate = timeline.epochDate ?? minDate
let displayMinDate = min(epochDate, minDate)  // Forces epoch into range
let displayMaxDate = max(epochDate.addingTimeInterval(86400), maxDate)
// Result: Tries to show 179-year range (1847 to 2026) → freeze

// AFTER:
// Use scene dates for display range (don't force epoch into range if it's far away)
let displayMinDate = minDate
let displayMaxDate = max(minDate.addingTimeInterval(86400), maxDate) // At least 1 day range
// Result: Shows where scenes are, user can scroll/zoom to see epoch
```

**Design Rationale:**

The timeline view should focus on the interesting content (scenes), not try to auto-fit potentially huge date ranges. Users can:
- **Scroll** to navigate to other dates (including the epoch)
- **Zoom out** to see larger time spans
- **Zoom in** to see details

The epoch date remains important for:
- Calendar-to-date conversions in SceneTemporalPositionEditor
- Reference point for the timeline
- Available via scrolling if needed

This approach prevents crashes from extreme date ranges while maintaining full timeline functionality.

**Files Modified:**
- `Cumberland/TimelineChartView.swift:816-821` - Display range calculation

**Verification:**
✅ Timeline tab renders instantly without freezing
✅ Shows scenes in their actual date range (2026)
✅ No CPU spike or UI freeze
✅ Temporal positioning works correctly
✅ Calendar conversions work (epoch date still used for calculations)
✅ Can scroll/zoom to explore different time periods
✅ Handles extreme date ranges gracefully

---

## DR-0065: Calendar Deletion Crash - Missing @Relationship Decorator

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** CalendarSystem Model, SwiftData Relationships
**Severity:** Critical
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-01-31

**Description:**

When deleting a Calendar card (kind=.calendars), the app crashed with:
```
Thread 1: Fatal error: Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<Cumberland.CalendarSystem>
```

This is a critical crash that prevents users from deleting calendar systems.

**Root Cause:**

The `CalendarSystem.calendarCard` property was declared as a plain property instead of being properly configured as the inverse side of a SwiftData relationship. Additionally, the `timelines` relationship was missing a proper delete rule.

**SwiftData Relationship Pattern:**

In SwiftData, bidirectional relationships follow this pattern:
- **Primary side:** Has `@Relationship(deleteRule: .X, inverse: \OtherType.property)`
- **Inverse side:** Plain property with NO `@Relationship` decorator

**Fix Applied:**

1. Added `@Relationship(deleteRule: .nullify)` to `CalendarSystem.timelines` (CalendarSystem.swift:44-46)
2. Kept `CalendarSystem.calendarCard` as a plain property (CalendarSystem.swift:51) - correct pattern for inverse side
3. Created Developer Tool for repairing existing broken calendars (CalendarSystemCleanupView)

**Files Modified:**
- `Cumberland/Model/CalendarSystem.swift:40-51` - Fixed relationship declarations
- `Cumberland/Developer/CalendarSystemCleanupView.swift` - NEW: Developer repair tool
- `Cumberland/CumberlandApp.swift` - Added Developer menu item

**Verification:**
✅ Calendar deletion works without crashing (after running developer tool on existing data)
✅ New calendars created with proper structure
✅ Developer tool successfully repairs broken calendars

**Related Issues:**
- ER-0008: Timeline System implementation (introduced CalendarSystem model)
- DR-0068: Calendar insertion bug (separate but related issue)

---

## DR-0066: Relationships Not Created When Analyzing Existing (Saved) Cards

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, AI Content Analysis
**Severity:** High
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-01-31

**Description:**

When running AI content analysis on an **existing, already-saved card**, detected relationships were not being created. Entity cards and calendars were created successfully, but **zero relationships were created**.

**Root Cause:**

The relationship creation logic in `SuggestionReviewView.swift` always deferred relationships involving the source card, regardless of whether that card already existed in the database or was being newly created.

The deferral mechanism was designed for new cards being created (where the card doesn't exist yet), but it incorrectly also deferred for existing saved cards. Since existing cards aren't "saved again," the deferred relationships were never executed.

**Fix Applied:**

Modified `SuggestionReviewView.swift:415-456` to check if source card is persistent before deferring:

```swift
let sourceCardIsPersistent = existingCards.contains(where: { $0.id == sourceCard.id })

if sourceCardIsPersistent {
    // Source card already exists - all relationships can be created immediately
    immediateRelationships = selectedRelationships
} else {
    // Source card hasn't been saved yet - defer relationships involving it
    // [existing deferral logic]
}
```

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:415-456` - Fixed relationship deferral logic

**Verification:**
✅ Relationships created correctly when analyzing existing saved cards
✅ Relationships still properly deferred for new unsaved cards
✅ Bidirectional relationships work in both scenarios

**Related Issues:**
- ER-0010: AI Content Analysis implementation
- ER-0019: Select All button (used during testing)

---

## DR-0067: Relationship Inference Not Detecting Patterns (Multiple Bugs) - CLOSED, DEFERRED TO ER-0020

**Status:** ⚪ Closed - Deferred to ER-0020
**Platform:** All platforms
**Component:** RelationshipInference, AI Content Analysis Phase 6
**Severity:** High (Mitigated)
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30 (Partially - temporary fix applied)
**Date Closed:** 2026-01-31
**Deferred To:** ER-0020 (Dynamic Relationship Extraction with AI-Generated Verbs)

**Description:**

When running AI content analysis on text with clear relationship patterns, very few relationships were being detected even though entities were correctly identified. Initial issue showed **zero relationships**, later improved to **5 relationships** after fixes.

**Root Causes (Multiple):**

### Bug 1: Substring Matching
Entity matching used substring matching, causing false positives:
- "Silver Era" falsely matching in "Silverpeak Mountains"

### Bug 2: Overly Aggressive Fuzzy Matching
Word-by-word fuzzy matching was always enabled, matching too broadly.

### Bug 3: Missing Relationship Patterns
Pattern trigger list was incomplete - missing common narrative verbs like "discovered", "led by", "works at", etc.

**Partial Fix Applied:**

### Fix 1: Word-Boundary Matching (Lines 410-429)
Added regex-based word boundary matching to prevent substring matches.

### Fix 2: Conditional Fuzzy Matching (Lines 260-269, 374-408)
Made fuzzy matching conditional - only enabled for text >800 words.

### Fix 3: Added Missing Relationship Patterns (Lines 195-242)
Added three new relationship patterns: discovered, leads, works-at.

**Files Modified:**
- `Cumberland/AI/RelationshipInference.swift:195-242, 260-269, 374-408, 410-429`

**Closure Rationale:**

While the fixes improved relationship detection (0 → 5 relationships), they expose a **fundamental limitation** of the hardcoded pattern-matching approach:

1. **Arbitrary and Arduous:** Must manually add every verb in English (and future languages)
2. **Never Complete:** Authors use creative verbs not in our list ("forges", "betrays", "consecrates")
3. **Defeats Flexibility:** Built a flexible RelationType system, but hardcoded patterns bypass it
4. **Language Locked:** English-only, would need separate patterns for other languages

**User Quote:**
> "I think that it will be arduous and arbitrary if we have to add all the verbs in english to our source code in order to determine the relationships between cards. One of the reasons I built the flexible system was so we wouldn't have to."

**Deferred To:**

**ER-0020: Dynamic Relationship Extraction with AI-Generated Verbs**
- Use AI providers (Claude, GPT-4) to extract relationships dynamically
- AI returns actual verbs from text ("wields", "discovered", "consecrated")
- Handles any verb naturally without hardcoded lists
- Supports complex grammar (prepositional phrases, indirect objects)
- Multilingual ready
- Properly leverages the flexible RelationType system

**Current Status:**
- Partial mitigation in place (5+ relationships detected vs 0)
- Full solution requires ER-0020 implementation
- Temporary fixes remain as fallback for when AI is unavailable

**Related Issues:**
- ER-0020: Dynamic Relationship Extraction with AI-Generated Verbs (HIGH priority)
- ER-0010: Phase 6 Relationship Inference implementation
- DR-0066: Relationship creation bug (fixed)

---

## DR-0068: Calendar Insertion Bug - Inserting Both Card and CalendarSystem

**Status:** ✅ Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, SwiftData Relationship Insertion
**Severity:** Critical
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-01-31

**Description:**

**NEW calendars** created after DR-0065 fix still crashed when deleted! Same error as DR-0065:
```
Thread 1: Fatal error: Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<Cumberland.CalendarSystem>
```

This revealed DR-0065's fix (relationship declarations) was correct, but there was a **second bug** in how calendars are **inserted** into the database.

**Root Cause:**

The calendar creation code was **explicitly inserting both** the `Card` AND the `CalendarSystem`:

```swift
// INCORRECT
modelContext.insert(calendarCard)      // Insert card
modelContext.insert(calendarSystem)    // ❌ ALSO insert system - WRONG!
```

In SwiftData, when you have a **cascade relationship**, you should only insert the **owning entity**. SwiftData automatically handles inserting related entities through the relationship.

**What Was Happening:**
1. Card has cascade relationship to CalendarSystem
2. Code sets `calendarCard.calendarSystemRef = calendarSystem`
3. `modelContext.insert(calendarCard)` → SwiftData inserts Card AND CalendarSystem (via cascade)
4. `modelContext.insert(calendarSystem)` → SwiftData tries to insert CalendarSystem AGAIN
5. Result: Inconsistent state causing crashes on deletion

**Fix Applied:**

Modified `SuggestionReviewView.swift:385-404` to insert only the Card:

```swift
calendarCard.calendarSystemRef = calendarSystem

// Insert ONLY the card - SwiftData handles cascade insertion automatically
modelContext.insert(calendarCard)
// ❌ REMOVED: modelContext.insert(calendarSystem)
```

**Pattern:**
- Create both objects ✅
- Link them via relationship property ✅
- Insert ONLY the owning object ✅
- SwiftData handles cascade insertion ✅

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:385-404` - Removed explicit CalendarSystem insertion

**Verification:**
✅ New calendars can be deleted without crashing
✅ Calendar creation works correctly
✅ Follows standard SwiftData cascade pattern

**Why This Bug Was Separate from DR-0065:**
- DR-0065 fixed relationship **declarations** (missing deleteRule, proper inverse)
- DR-0068 fixed **insertion logic** (double-inserting related entities)
- Both bugs independently caused the same crash symptom
- Both fixes required for calendars to work correctly

**Related Issues:**
- DR-0065: Calendar deletion crash (relationship declarations fix)
- ER-0008: Timeline System implementation (introduced CalendarSystem model)

---

*Last Updated: 2026-01-31*
*Status: 8/10 DRs verified in this batch (DR-0067 closed and deferred to ER-0020)*
## DR-0070: Image Generation Provider Picker Does Not Show Saved Setting

**Status:** ✅ Resolved - Verified
**Platform:** All platforms (macOS, iOS, iPadOS, visionOS)
**Component:** SettingsView, AISettingsPane
**Severity:** Medium
**Date Identified:** 2026-02-03
**Date Resolved:** 2026-02-03
**Date Verified:** 2026-02-03

**Description:**

When a user sets OpenAI as the image generation provider, saves the setting, and later uses image generation, the pickers show "Apple Intelligence" instead of "OpenAI" in multiple locations:
1. Settings → AI Settings → Image Generation Provider picker
2. Card Editor → AI Image Generation Panel → AI Provider picker

The setting IS correctly saved (OpenAI is used for generation when called programmatically), but the UI doesn't reflect the saved value in these pickers.

**Expected Behavior:**
1. User goes to Settings → AI Settings
2. Changes "Image Generation Provider" picker from "Apple Intelligence" to "OpenAI"
3. Closes Settings
4. Reopens Settings → AI Settings
5. **Expected:** Picker shows "OpenAI" (the saved value)

**Actual Behavior:**
1-4. Same as above
5. **Actual:** Picker shows "Apple Intelligence" (the default, not the saved value)
6. OpenAI IS being used for generation (setting works correctly)
7. Only the UI display is wrong

**Root Cause:**

In `SettingsView.swift:850-851`, the provider pickers use `@State` instead of `@AppStorage`:

```swift
// INCORRECT - @State is initialized once and doesn't sync with UserDefaults
@State private var analysisProvider: String = AISettings.shared.analysisProvider
@State private var imageGenerationProvider: String = AISettings.shared.imageGenerationProvider
```

**The Problem:**
- `@State` is initialized with the current value when the view is created
- `@State` does NOT automatically sync with UserDefaults
- The `onChange` handler (lines 901-904) writes TO UserDefaults but doesn't read FROM it
- Result: UI shows initial/default value, not the persisted value

**Why It Works For Writing:**
- Lines 901-904: `onChange(of: imageGenerationProvider)` correctly writes to `AISettings.shared.imageGenerationProvider`
- The setting IS saved and works correctly for actual generation
- But the UI never reads the saved value on subsequent views

**Comparison With Other Settings:**

Other parts of the codebase correctly use `@AppStorage` for UserDefaults-backed settings:

```swift
// Example: MapWizardView.swift uses @AppStorage correctly
@AppStorage("mapWizard_showGrid") private var showGrid: Bool = true
```

**Fix:**

Change `@State` to `@AppStorage` in SettingsView.swift:850-851:

```swift
// SettingsView.swift:850-851 - BEFORE
@State private var analysisProvider: String = AISettings.shared.analysisProvider
@State private var imageGenerationProvider: String = AISettings.shared.imageGenerationProvider

// SettingsView.swift:850-851 - AFTER
@AppStorage(AISettings.Keys.analysisProvider)
private var analysisProvider: String = AISettings.Defaults.analysisProvider

@AppStorage(AISettings.Keys.imageGenerationProvider)
private var imageGenerationProvider: String = AISettings.Defaults.imageGenerationProvider
```

**Benefits of @AppStorage:**
- Automatically syncs with UserDefaults (read AND write)
- No need for manual `onChange` handlers for simple persistence
- UI always shows current saved value
- Reactive updates across views

**Alternative (If Keeping @State):**

If `@State` must be kept for some reason, add `.onAppear` to refresh from UserDefaults:

```swift
.onAppear {
    analysisProvider = AISettings.shared.analysisProvider
    imageGenerationProvider = AISettings.shared.imageGenerationProvider
}
```

But `@AppStorage` is the cleaner, more SwiftUI-idiomatic solution.

**Files to Modify:**
- `Cumberland/SettingsView.swift:850-851` - Change @State to @AppStorage
- `Cumberland/SettingsView.swift:877-880` - Can remove onChange handler (automatic with @AppStorage)
- `Cumberland/SettingsView.swift:901-904` - Can remove onChange handler (automatic with @AppStorage)

**Test Steps:**

**Test 1: Settings Picker**
1. Open Settings → AI Settings
2. Note current "Image Generation Provider" selection (likely "Apple Intelligence")
3. Change to "OpenAI" (or any provider different from current)
4. Close Settings
5. Reopen Settings → AI Settings
6. **Verify:** Picker shows "OpenAI" (the saved value) ✅

**Test 2: AI Image Generation Panel Picker**
7. Open any card (character, location, etc.)
8. Click "Generate Image…" button
9. AI Image Generation Panel appears
10. **Verify:** "AI Provider" picker shows "OpenAI" (the saved value) ✅
11. Close panel without generating
12. Go to Settings and change provider to "Apple Intelligence"
13. Reopen the AI Image Generation Panel
14. **Verify:** "AI Provider" picker now shows "Apple Intelligence" ✅

**Test 3: Batch Generation**
15. Select multiple cards using "Select" button
16. Click "Generate Images"
17. **Verify:** Console logs show "OpenAI DALL-E 3" as provider (or whatever is saved in settings) ✅
18. **Verify:** Images generate using the correct provider ✅

**Resolution:**

Implemented multiple fixes to ensure proper provider selection and display:

**Files Modified:**
- `Cumberland/SettingsView.swift:850-854` - Added `needsInitialLoad` flag and reactive `hasAPIKey` dictionary
- `Cumberland/SettingsView.swift:938-952` - Added `.task` for initial load + `.onAppear` for subsequent loads
- `Cumberland/SettingsView.swift:945-949` - Added `loadAPIKeyStatus()` to reactively load API key availability
- `Cumberland/SettingsView.swift:1149-1152` - Update `hasAPIKey` state when saving API keys
- `Cumberland/SettingsView.swift:1161-1164` - Update `hasAPIKey` state when deleting API keys
- `Cumberland/MainAppView.swift:1170` - Set batch queue provider from AISettings.shared
- `Cumberland/AI/AIImageGenerationView.swift:301` - **Reload provider in .onAppear to show saved value**

**Implementation:**

**1. Reactive State Management:**
```swift
// SettingsView.swift:850-854
@State private var analysisProvider: String = AISettings.shared.analysisProvider
@State private var imageGenerationProvider: String = AISettings.shared.imageGenerationProvider
@State private var needsInitialLoad: Bool = true
@State private var hasAPIKey: [String: Bool] = [:]  // Reactive API key status
```

**2. Initial Load + Subsequent Loads:**
```swift
// SettingsView.swift:938-952
.task {
    if needsInitialLoad {
        analysisProvider = AISettings.shared.analysisProvider
        imageGenerationProvider = AISettings.shared.imageGenerationProvider
        loadAPIKeyStatus()
        needsInitialLoad = false
    }
}
.onAppear {
    analysisProvider = AISettings.shared.analysisProvider
    imageGenerationProvider = AISettings.shared.imageGenerationProvider
    loadAPIKeyStatus()
}
```

**3. API Key Status Loading:**
```swift
// SettingsView.swift:945-949
private func loadAPIKeyStatus() {
    for provider in providers {
        let key = providerKey(for: provider)
        hasAPIKey[key] = KeychainHelper.shared.hasAPIKey(for: key)
    }
}
```

**4. AI Image Generation Panel Reload:**
```swift
// AIImageGenerationView.swift:301
.onAppear {
    // Reload provider from settings (DR-0070: ensure picker shows saved value)
    selectedProvider = AISettings.shared.imageGenerationProvider

    // ... rest of onAppear logic ...
}
```

This ensures:
- Settings UI refreshes from UserDefaults on every view appearance
- API key status is loaded reactively and updated when keys are added/removed
- Batch generation uses the correct provider from AISettings.shared
- **AI Image Generation Panel picker loads and displays the saved provider**

**Related Issues:**
- ER-0009: AI Image Generation implementation
- ER-0017: Batch Image Generation (batch generation provider fix - same root cause)
- DR-0069: AI safety filter false positives (discovered while testing OpenAI provider)
- DR-0072: Batch generation server errors (discovered while testing batch generation)

**Notes:**
- This is a UI binding bug, not a data persistence bug
- The setting IS being saved correctly (generation uses correct provider when called programmatically)
- Affected three different UI locations (all now fixed):
  1. Settings → AI Settings → Image Generation Provider picker ✅
  2. AI Image Generation Panel → AI Provider picker ✅
  3. Batch Generation → provider parameter ✅
- Also affects `analysisProvider` picker in Settings (same fix pattern)
- Root cause: `@State` initialized once, never reloaded from UserDefaults on view appearance

---
## DR-0066: Relationships Not Created When Analyzing Existing (Saved) Cards

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, AI Content Analysis
**Severity:** High
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-02-03

**Description:**

When running AI content analysis on an **existing, already-saved card**, detected relationships are not being created. User reported analyzing "Professor Elara Moonwhisper" scene text and accepting all suggestions - entity cards and calendar were created successfully, but **zero relationships were created**.

**Root Cause:**

The relationship creation logic in `SuggestionReviewView.swift` (lines 415-450) has a bug where it **always defers** relationships involving the source card, regardless of whether that card already exists in the database or is being newly created.

**Original Logic:**
```swift
// Always defers relationships involving source card
let sourceCardName = sourceCard.name.lowercased()
for relationship in selectedRelationships {
    if sourceMatches || targetMatches {
        deferredRelationships.append(relationship)  // Always deferred!
    }
}
```

**The Issue:**
- Deferral was designed for when you're **creating a new card** and analyzing its text **before saving**
- In that case, the source card doesn't exist yet, so relationships must wait until card is saved
- However, the code **also defers** when analyzing an **existing card** that's already in the database
- Since the card is never "saved again" (it's already saved), the deferred relationships are **never created**

**Example Scenario (Bug):**
1. User creates and saves a scene card: "Professor Elara's First Lecture"
2. User adds detailed text about Elara, students, location, etc.
3. User clicks "Analyze Content with AI"
4. AI detects: Professor Elara (character), Lecture Hall (location), relationships
5. User accepts all suggestions via "Select All" → "Create Selected"
6. **Result:** Entity cards created ✅, Calendar created ✅, **Relationships NOT created** ❌
7. **Why:** Relationships like "Professor Elara appears-in Professor Elara's First Lecture" were deferred
8. **Problem:** Scene card already exists - it won't be saved again, so deferred relationships never execute

**Fix Applied:**

Modified `SuggestionReviewView.swift:415-456` to check if source card is persistent before deferring:

```swift
// Check if source card already exists in database
let sourceCardIsPersistent = existingCards.contains(where: { $0.id == sourceCard.id })

if sourceCardIsPersistent {
    // Source card already exists - all relationships can be created immediately
    immediateRelationships = selectedRelationships
} else {
    // Source card hasn't been saved yet - defer relationships involving it
    for relationship in selectedRelationships {
        if sourceMatches || targetMatches {
            deferredRelationships.append(relationship)
        } else {
            immediateRelationships.append(relationship)
        }
    }
}
```

**Logic After Fix:**
- **If source card exists** (in `existingCards` array) → Create ALL relationships immediately ✅
- **If source card doesn't exist** (being created) → Defer relationships involving source card, create others immediately ✅

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:415-456` - Fixed relationship deferral logic

**Test Steps:**

1. Create a scene card: "Test Scene" with detailed text about characters/locations
2. **Save the card** (critical - card must already exist)
3. Click "Analyze Content with AI" from the toolbar
4. Review suggestions panel appears with entities and relationships
5. Click "Select All" → "Create Selected"
6. Check the Relationships tab on the scene card
7. **Verify:** Relationships were created (e.g., "Character X appears-in Test Scene")
8. Check created entity cards (characters, locations)
9. **Verify:** They have reverse relationships back to the scene

**Debug Output:**

When analyzing existing card:
```
ℹ️ [SuggestionReviewView] Source card 'Professor Elara's First Lecture' is persistent - creating all relationships immediately
✅ [SuggestionReviewView] Created 5 entity cards
✅ [SuggestionReviewView] Created 1 calendar cards
✅ [SuggestionReviewView] Created 12 immediate relationships
📋 [SuggestionReviewView] Stored 0 pending relationships
```

When analyzing new (unsaved) card:
```
ℹ️ [SuggestionReviewView] Source card 'New Scene' not yet saved - deferring 8 relationships
✅ [SuggestionReviewView] Created 5 entity cards
✅ [SuggestionReviewView] Created 0 calendar cards
✅ [SuggestionReviewView] Created 4 immediate relationships
📋 [SuggestionReviewView] Stored 8 pending relationships (involve 'New Scene')
```

**Related Issues:**
- ER-0010: AI Content Analysis implementation
- ER-0019: Select All button (used to trigger this discovery)
- Phase 6: Bidirectional relationship creation

**Notes:**

- This bug has existed since Phase 6 relationship creation was implemented
- Only affects analysis of **existing, saved cards** - new cards work correctly
- Bug discovered when user tested with "Professor Elara Moonwhisper" test text
- User correctly identified: "no pending should have been necessary"
- Fix ensures relationships are created based on source card persistence, not just involvement

---

## DR-0068: Calendar Insertion Bug - Inserting Both Card and CalendarSystem

**Status:** ✅ Resolved - Verified
**Platform:** All platforms
**Component:** SuggestionReviewView, SwiftData Relationship Insertion
**Severity:** Critical
**Date Identified:** 2026-01-30
**Date Resolved:** 2026-01-30
**Date Verified:** 2026-02-03

**Description:**

**NEW calendars** created after DR-0065 fix still crash when deleted! User reported:

> "motherfucker! Thread 1: Fatal error... This one was created after the fix! just last round."

Same error as DR-0065:
```
Thread 1: Fatal error: Unexpected backing data for snapshot creation:
SwiftData._FullFutureBackingData<Cumberland.CalendarSystem>
```

This revealed DR-0065's fix (relationship declarations) was correct, but there was a **second bug** in how calendars are **inserted** into the database.

**Root Cause:**

The calendar creation code in `SuggestionReviewView.swift` was **explicitly inserting both** the `Card` AND the `CalendarSystem`:

```swift
// INCORRECT (SuggestionReviewView.swift:385-404 - before fix)
let calendarSystem = CalendarSystem(...)
let calendarCard = Card(...)

calendarCard.calendarSystemRef = calendarSystem  // Link them

modelContext.insert(calendarCard)      // Insert card
modelContext.insert(calendarSystem)    // ❌ ALSO insert system - WRONG!
```

**The Problem:**

In SwiftData, when you have a **cascade relationship**, you should only insert the **owning entity**. SwiftData automatically handles inserting related entities through the relationship.

From `Card.swift:113-114`:
```swift
@Relationship(deleteRule: .cascade, inverse: \CalendarSystem.calendarCard)
var calendarSystemRef: CalendarSystem?
```

The `.cascade` delete rule means:
- Card **owns** CalendarSystem
- When Card is deleted, CalendarSystem is also deleted
- When Card is **inserted**, CalendarSystem should be **automatically inserted** via the relationship

**What Was Happening:**
1. Code creates `CalendarSystem` object
2. Code creates `Card` object
3. Code sets `calendarCard.calendarSystemRef = calendarSystem` (establishes relationship)
4. Code calls `modelContext.insert(calendarCard)` → SwiftData inserts Card AND CalendarSystem (via cascade)
5. Code calls `modelContext.insert(calendarSystem)` → SwiftData tries to insert CalendarSystem AGAIN
6. Result: CalendarSystem is in inconsistent state with duplicate insertion
7. Later deletion fails because SwiftData can't create snapshot for deletion

**Why DR-0065 Fix Didn't Prevent This:**
- DR-0065 fixed the relationship **declarations** (missing deleteRule, proper inverse setup)
- But the **insertion code** was still wrong (double-inserting)
- Both bugs needed to be fixed for calendars to work correctly

**Fix Applied:**

Modified `SuggestionReviewView.swift:385-404` to insert only the Card:

```swift
// Phase 7.5: Create CalendarSystem
let calendarSystem = CalendarSystem(
    name: detected.name,
    divisions: divisions
)

// Phase 7.5: Create Calendar CARD
let calendarCard = Card(
    kind: .calendars,
    name: detected.name,
    subtitle: "\(detected.monthsPerYear) months, \(detected.daysPerMonth ?? 0) days/month",
    detailedText: detected.context
)

// Link card to system (sets up bidirectional relationship)
calendarCard.calendarSystemRef = calendarSystem

// Insert ONLY the card - SwiftData will automatically insert the related CalendarSystem
// This is correct because Card has the @Relationship decorator with cascade delete
modelContext.insert(calendarCard)

// ❌ REMOVED: modelContext.insert(calendarSystem)
```

**Pattern:**
- **Create both objects** ✅
- **Link them via relationship property** ✅
- **Insert ONLY the owning object** ✅
- **SwiftData handles cascade insertion** ✅

**Files Modified:**
- `Cumberland/AI/SuggestionReviewView.swift:385-404` - Removed explicit CalendarSystem insertion

**Test Steps:**

1. Create a scene card with text mentioning a calendar system
2. Add this text:
   ```
   The Lunara Calendar has 13 months of 28 days each. The year begins with the Festival of New Stars.
   Each month is named after a constellation visible during that time.
   ```
3. Click "Analyze Content with AI" (use Anthropic provider)
4. Review Suggestions panel should show calendar in "Calendar Systems to Add" section
5. Select all and create
6. **Verify:** Calendar card appears in Calendars sidebar
7. Navigate to the calendar card
8. **CRITICAL TEST:** Delete the calendar card (Cmd+Delete or Delete menu)
9. **Verify:** App does NOT crash ✅
10. **Verify:** Calendar is removed from the list ✅

**User Verification:**
User tested immediately after fix and confirmed:
> "verified. it didn't crash!"

**Related Issues:**
- DR-0065: Calendar deletion crash (relationship declarations fix)
- ER-0008: Timeline System implementation (introduced CalendarSystem model)
- ER-0016: Temporal Editor (uses CalendarSystem for scene dating)

**Implementation Notes:**

**Why This Bug Was Separate from DR-0065:**
- DR-0065 was about **relationship structure** (missing deleteRule, proper inverse)
- DR-0068 is about **insertion logic** (double-inserting related entities)
- Both bugs independently caused the same crash symptom
- Fixing DR-0065 alone didn't fix the problem - insertion logic also needed correction

**SwiftData Pattern:**
This fix follows the standard SwiftData pattern for cascade relationships used throughout the codebase:

**Example 1: Board/BoardNode (Board.swift:40-42)**
```swift
// Board side (owning)
@Relationship(deleteRule: .cascade, inverse: \BoardNode.board)
var nodes: [BoardNode]? = []

// Insertion code (BoardView.swift)
let board = Board(...)
let node = BoardNode(...)
board.nodes?.append(node)  // Link them
modelContext.insert(board) // Insert ONLY board
// ❌ NOT: modelContext.insert(node)
```

**Example 2: Card/Citation (Card.swift:90-91)**
```swift
// Card side (owning)
@Relationship(deleteRule: .cascade, inverse: \Citation.card)
var citations: [Citation]? = []

// Insertion code (CitationGenerator.swift)
let card = Card(...)
let citation = Citation(...)
card.citations?.append(citation)  // Link them
modelContext.insert(card)          // Insert ONLY card
// ❌ NOT: modelContext.insert(citation)
```

**Rule:** When you have a cascade relationship, insert only the parent/owning entity. SwiftData handles the rest.

**Notes:**

- This bug was discovered immediately after DR-0065 fix when testing with a newly created calendar
- User correctly identified: "This one was created after the fix! just last round."
- This demonstrates that DR-0065 fix was necessary but not sufficient
- Calendar functionality now requires BOTH fixes to work correctly:
  - DR-0065: Proper relationship declarations
  - DR-0068: Correct insertion pattern

---

