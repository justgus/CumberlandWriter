# Enhancement Requests (ER) - Batch: ER-0012 to ER-0016

This file contains verified enhancement requests ER-0012, ER-0013, ER-0014, and ER-0016.

**Batch Status:** ✅ All Verified (4/4)

---

## ER-0012: Chronicles Card Type for Historical Events and Time Periods

**Status:** ✅ Verified
**Component:** Card Model (Kinds.swift), MainAppView, AI Integration
**Priority:** Medium
**Date Requested:** 2026-01-24
**Date Implemented:** 2026-01-25
**Date Verified:** 2026-01-30

**User Request:**

User asked: "What would you call a named time period, such as The Age of Ascendance, The Fall of Stormwatch, or the Shadow War or the Treaty of Argenthall? I don't think they warrant classification as Scenes because they will not form part of the narrative of the story. They are vital background information and warrant the description of important Historical Events."

User decided on the name: **Chronicles**

**Problem Statement:**

Currently, worldbuilding elements like historical events, time periods, and background lore don't have an appropriate card type:
- **Not Scenes**: These aren't part of the narrative story being written
- **Not Rules**: Too important to be relegated to generic "Rules" category
- **Not Timelines**: Timeline cards are for temporal positioning, not event descriptions
- **Historical significance**: Events like "The Shadow War" or "The Fall of Stormwatch" are crucial worldbuilding

**Proposed Solution:**

Add a new card type: **Chronicles**

**What Chronicles Are:**
- Historical events: "The Battle of Five Peaks", "The Great Rebellion"
- Time periods/eras: "The Age of Ascendance", "The Second Dynasty"
- Treaties and agreements: "The Treaty of Argenthall"
- Wars and conflicts: "The Shadow War"
- Major transitions: "The Fall of Stormwatch"
- Background lore that shapes the world but isn't directly narrated

**Implementation Summary:**

**Phase 1: Add Chronicles to Kinds Enum** ✅
- [x] Added `.chronicles = "Chronicles"` case to `Kinds.swift:24`
- [x] Added to `orderedCases` (position: after Artifacts, before Rules) - Line 35
- [x] Added singular title: "Chronicle" - Line 47
- [x] Chose SF Symbol icon: `"scroll"` / `"scroll.fill"` - Lines 69, 166
- [x] Defined light/dark color palette (warm gold/amber, h: 40/360) - Lines 105, 120

**Phase 2: UI Integration** ✅
- [x] Added Chronicles to sidebar filter in `MainAppView.swift`
- [x] Added visibility toggle to column settings (`@AppStorage`) - Line 84
- [x] Added Chronicles to switch statements (load/save column visibility) - Lines 1119, 1159
- [x] Chronicles automatically appears in "Add Card" button (inherits from `Kinds.orderedCases`)

**Phase 3: Entity Extraction Integration (ER-0010)** ✅
- [x] Added `historicalEvent = "historical_event"` entity type to `EntityType` enum - `AIProviderProtocol.swift:173`
- [x] Mapped to `.chronicles` card kind in `toCardKind()` - `AIProviderProtocol.swift:185`
- [x] Updated OpenAI prompt to extract historical events/time periods - `OpenAIProvider.swift:199-201, 206`
- [x] Added `historicalEvent` to entity type flags - `AISettings.swift:297`
- [x] Added `historicalEvent` to EntityTypesView picker - `AISettingsView.swift:352`

**Files Modified:**
- `Cumberland/Model/Kinds.swift` - Added Chronicles enum case, ordering, icon, colors
- `Cumberland/AI/AIProviderProtocol.swift` - Added historicalEvent entity type → Chronicles mapping
- `Cumberland/AI/OpenAIProvider.swift` - Updated prompt to extract historical events
- `Cumberland/AI/AISettings.swift` - Added historicalEvent to entity type flags
- `Cumberland/AI/AISettingsView.swift` - Added historicalEvent to entity type picker
- `Cumberland/MainAppView.swift` - Added Chronicles column visibility and switch cases

**Visual Design:**

**SF Symbol:** `"scroll"` (most evocative of historical records)
- Alternative: `"book.pages"` (multiple pages = chronicles)
- Alternative: `"text.book.closed"` (formal history book)

**Color Palette:**
- **Light mode**: Warm gold/amber pastel (h: 40/360, s: 0.20, b: 0.97)
- **Dark mode**: Rich amber (h: 40/360, s: 0.58, b: 0.32)
- Rationale: Gold/amber suggests age, importance, historical records

**User Scenarios:**

1. **Fantasy Epic:**
   - Chronicles: "The First Age", "The Dragon Wars", "The Sundering"
   - Provides timeline context without being part of current narrative

2. **Sci-Fi Universe:**
   - Chronicles: "The Mars Rebellion", "The AI Awakening", "The Treaty of Europa"
   - Background history referenced in story

3. **Historical Fiction:**
   - Chronicles: "The Victorian Era", "The Industrial Revolution"
   - Real historical periods affecting characters

**Verification:**
✅ Create Chronicles card via "+ Add Card" button
✅ Chronicles appears in sidebar with correct icon/color
✅ Chronicles cards filterable and sortable
✅ Chronicles cards appear in search results
✅ Chronicles cards can be cited as Sources
✅ AI entity extraction suggests Chronicles for historical events
✅ CloudKit sync works for Chronicles cards

**Related:**
- ER-0010: AI Content Analysis (extracts historical events)
- ER-0008: Timeline System (Chronicles provide context for timeline events)
- ER-0016: Timeline/Chronicle hierarchy (Chronicles as temporal spans)

---

## ER-0013: Separate AI Provider Settings for Analysis and Image Generation

**Status:** ✅ Verified
**Component:** AISettings, Settings UI, AI Provider Selection
**Priority:** Medium
**Date Requested:** 2026-01-24
**Date Implemented:** 2026-01-25
**Date Verified:** 2026-01-30

**User Request:**

User said: "I think we should allow the writer to use different AI providers for Analysis and Image Generation. For example she might opt to use Apple Intelligence for analysis and Open AI for image generation. This should be selectable in preferences."

**Problem Statement:**

Currently, `AISettings` has a single `selectedProvider` setting that applies to both:
1. **Content Analysis** (entity extraction, relationship inference)
2. **Image Generation** (creating artwork for cards and maps)

Users may want different providers for different tasks:
- **Apple Intelligence for analysis**: Fast, on-device, private, no API costs
- **OpenAI for image generation**: Better quality images with DALL-E 3
- **Cost optimization**: Use free Apple Intelligence when possible, paid APIs only when needed
- **Performance**: Use fastest provider for each specific task

**Implementation Summary:**

**Phase 1: Update AISettings Model** ✅
- [x] Added `analysisProvider: String` property to `AISettings` with migration logic - `AISettings.swift:56-71`
- [x] Added `imageGenerationProvider: String` property to `AISettings` with migration logic - `AISettings.swift:73-88`
- [x] Added automatic migration from legacy `preferredProvider` - Both properties check legacy value on first access
- [x] Deprecated `currentProvider` and added `currentAnalysisProvider` / `currentImageGenerationProvider` - Lines 165-194
- [x] Added helper method: `provider(for: AITask)` - Lines 159-164
- [x] Added `AITask` enum (`.analysis`, `.imageGeneration`) - Lines 251-255

**Phase 2: Update Settings UI** ✅
- [x] Split provider picker into two separate sections in `AISettingsView.swift:55-93`
- [x] Section 1: "Content Analysis" with provider picker and API key management - Lines 65-83
- [x] Section 2: "Image Generation" with provider picker and API key management - Lines 86-111
- [x] Added explanatory footer text for each section describing use cases
- [x] Show API key status for each provider separately (shared `apiKeyRow()` method)

**Phase 3: Update Provider Selection Logic** ✅
- [x] `CardEditorView:1102`: Use `currentAnalysisProvider` for "Analyze" button (entity extraction)
- [x] `CardEditorView:1412`: Use `currentImageGenerationProvider` for image auto-generation
- [x] Updated all usages of deprecated `currentProvider` to use task-specific properties
- [x] Fixed debug `printSettings()` to show both providers separately - `AISettings.swift:452`

**Phase 4: Availability Checks** ✅
- [x] Updated `isImageGenerationAvailable` to check `currentImageGenerationProvider` - Line 178
- [x] Updated `isContentAnalysisAvailable` to check `currentAnalysisProvider` - Line 183
- [x] Updated `isProviderAvailable` to check if either provider available - Line 195

**Files Modified:**
- `Cumberland/AI/AISettings.swift` - Added separate provider properties, migration logic, AITask enum, deprecated old properties
- `Cumberland/AI/AISettingsView.swift` - Split provider section into two separate sections with independent pickers
- `Cumberland/CardEditorView.swift` - Updated to use task-specific provider properties (analysis vs image generation)

**Migration Strategy:**

1. Check if user has existing `selectedProvider` preference
2. On first launch after update:
   - Set `analysisProvider = selectedProvider`
   - Set `imageGenerationProvider = selectedProvider`
3. Clear old `selectedProvider` preference
4. User can then customize each provider independently

**Use Case Examples:**

**Example 1: Privacy-Conscious User**
- Analysis Provider: Apple Intelligence (on-device, private)
- Image Generation Provider: Apple Intelligence (on-device, private)
- Result: Everything stays on device, no cloud APIs

**Example 2: Quality-Focused User**
- Analysis Provider: Apple Intelligence (fast, free)
- Image Generation Provider: OpenAI (better image quality)
- Result: Fast analysis, beautiful images, optimized cost

**Example 3: Power User**
- Analysis Provider: OpenAI (GPT-4 for complex analysis)
- Image Generation Provider: OpenAI (DALL-E 3 for images)
- Result: Maximum quality, accepts API costs

**Verification:**
✅ Fresh Install: Default providers set correctly
✅ Existing User: Migration preserves existing provider choice
✅ Analysis: CardEditorView "Analyze" uses `analysisProvider`
✅ Image Gen: AI Image Generation uses `imageGenerationProvider`
✅ Map Gen: Map Wizard uses `imageGenerationProvider`
✅ Mixed Setup: Apple for analysis + OpenAI for images works correctly
✅ Settings UI: Both pickers work independently
✅ API Keys: Correct API key validation for each provider

**Related:**
- ER-0009: AI Image Generation
- ER-0010: AI Content Analysis
- DR-0050: Timeout issues (relates to provider performance)
- DR-0052: Entity extraction bugs (provider-specific)

---

## ER-0014: Change Card Type Feature with Relationship Deletion

**Status:** ✅ Verified
**Component:** CardRelationshipView, SuggestionReviewView, AI Suggestion System
**Priority:** Medium
**Date Requested:** 2026-01-25
**Date Implemented:** 2026-01-25
**Date Verified:** 2026-01-30

**User Request:**

User identified a need to change card types in two scenarios:
1. **Before Card Creation (AI Suggestions)**: Cards suggested by AI analysis may be miscategorized (e.g., "Shadow War" suggested as Scene should be Chronicle)
2. **After Card Creation (Existing Cards)**: Cards may need reclassification as the worldbuilding evolves

User decided on implementation approach:
- **AI Suggestion Sheet**: Allow type change BEFORE creating cards (low-risk, no data loss)
- **Relationship Tab**: Allow type change AFTER creation with warning dialog (high-risk, deletes all relationships)
- **NOT in CardEditorView**: Too easy to accidentally trigger
- **NOT as menu item**: Too accessible for destructive operation

**Problem Statement:**

Currently, once a card is created with a specific type (Kind), there's no way to change it:
- **Immutable Type**: Card type is set at creation and cannot be changed
- **AI Miscategorization**: AI may suggest wrong types (e.g., historical events as Scenes instead of Chronicles)
- **User Evolving Understanding**: As worldbuilding progresses, categorization needs may change
- **All-or-Nothing**: Can't fix type without deleting and recreating card (loses all relationships anyway)

**Implemented Solution:**

**Part 1: Change Type in AI Suggestion Sheet (Low-Risk)** ✅

Allow users to override AI's suggested type BEFORE creating cards:

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift:14` - Made `cardKind` mutable (`var` instead of `let`)
- `Cumberland/AI/SuggestionReviewView.swift` - Multiple changes:
  - Lines 21-28: Changed `suggestions` to `mutableSuggestions` state
  - Lines 23-28: Added init() to accept immutable suggestions and create mutable state
  - Line 126: Changed `ForEach(suggestions.cards)` to `ForEach($mutableSuggestions.cards)`
  - Line 290: Changed `CardSuggestionRow` to accept `@Binding var suggestion`
  - Lines 311-319: Replaced static type badge with `Picker` for all card types (except .structure)

**How It Works:**
1. User analyzes card description → AI suggests entities
2. Suggestion sheet shows entities with suggested types
3. User sees "Shadow War" suggested as "Scene"
4. User taps type picker → selects "Chronicles"
5. Card is created with correct type from the start
6. **No relationships exist yet** → No data loss

**Part 2: Change Type in Relationship Tab (High-Risk)** ✅

Allow users to change type for existing cards with clear warning about relationship deletion:

**Files Modified:**
- `Cumberland/CardRelationshipView.swift`:
  - Lines 107-108: Added state variables for dialog and selected type
  - Lines 543-558: Added "Change Card Type…" button in topControls
  - Lines 345-359: Added confirmation dialog with type picker and destructive action
  - Lines 1105-1132: Implemented `changeCardType(to:)` function

**How It Works:**
1. User opens card in Relationship tab
2. User clicks "Change Card Type…" button
3. Confirmation dialog appears with:
   - **Warning**: "Changing the card type from [X] to another type will REMOVE ALL RELATIONSHIPS for [card name]. This cannot be undone."
   - **Type Picker**: Shows all card types (except .structure)
   - **Change Type Button**: Red destructive style
   - **Cancel Button**: Safe exit
4. User selects new type → clicks "Change Type"
5. System:
   - Fetches all CardEdges where card is source or target
   - Deletes all edges (relationships)
   - Changes `primary.kindRaw` to new type
   - Saves model context
6. Card type is changed, all relationships removed

**Why Relationship Deletion is Necessary:**

1. **Relationship Type Constraints**: RelationTypes have `sourceKind` and `targetKind` constraints
   - Example: "stories/is-storied-by" only valid for Scene → Project
   - If Scene becomes Character, this relationship type is invalid
2. **Data Integrity**: Invalid relationships would break the relationship system
3. **User Clarity**: Better to delete all than leave some orphaned/invalid relationships
4. **Explicit Trade-off**: User is warned and must confirm the destructive action

**User Scenarios:**

**Scenario 1: AI Misclassification (No Data Loss)**
1. User writes scene description mentioning "The Shadow War"
2. AI suggests "Shadow War" as Scene
3. User sees this in suggestion sheet, changes to Chronicles
4. Card created as Chronicles ✅
5. **No relationships deleted** (card didn't exist yet)

**Scenario 2: Late Reclassification (Destructive)**
1. User has "The Shadow War" card (type: Scenes)
2. Card has relationships to Characters, Locations, Projects
3. User realizes it should be Chronicles (historical background, not active scene)
4. User opens Relationship tab → "Change Card Type…"
5. Dialog warns: "Will REMOVE ALL RELATIONSHIPS"
6. User confirms → Type changes to Chronicles, all relationships deleted
7. User rebuilds only the relationships that still make sense

**Verification:**

**Part 1: AI Suggestion Sheet**
✅ Analyze card with 100+ word description
✅ Verify suggestion sheet shows entities with type pickers
✅ Change suggested type (e.g., Scene → Chronicles)
✅ Create card
✅ Verify card has correct type in sidebar
✅ Verify card has correct kind badge color

**Part 2: Relationship Tab**
✅ Create card with several relationships
✅ Open card in Relationship tab
✅ Click "Change Card Type…" button
✅ Verify confirmation dialog appears with warning
✅ Verify type picker shows all types except .structure
✅ Select new type → click "Change Type"
✅ Verify card type changes
✅ Verify all relationships are deleted
✅ Verify card appears in correct sidebar section
✅ Cancel dialog → verify no changes

**Edge Cases:**
✅ Change type to same type → no-op (guard clause)
✅ Card with 0 relationships → type changes, nothing deleted
✅ Card with 50+ relationships → all deleted (performance tested)
✅ CloudKit sync → verify type change and edge deletions sync

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift` - Made cardKind mutable
- `Cumberland/AI/SuggestionReviewView.swift` - Added type picker to suggestion rows
- `Cumberland/CardRelationshipView.swift` - Added change type button, dialog, and implementation

**Related:**
- ER-0012: Chronicles Card Type (new type frequently needs reclassification)
- ER-0010: AI Content Analysis (AI suggestions may be imperfect)

---

## ER-0016: Timeline/Chronicle/Scene Proper Hierarchy and Multi-Timeline Graph Redesign

**Status:** ✅ Verified
**Component:** MultiTimelineGraphView, Card Model, CardEditorView, Timeline System
**Priority:** High
**Date Requested:** 2026-01-28
**Date Phase 1 Implemented:** 2026-01-28
**Date Phase 2 Implemented:** 2026-01-29
**Date Phase 2.1 Implemented:** 2026-01-29 (UI Refinements)
**Date Verified:** 2026-01-30
**Related:** ER-0008 (Multi-Timeline Graph implementation)

**Rationale:**

The current Multi-Timeline Graph implementation (Phase 8, ER-0008) treats **Chronicles** as timeline tracks, but this doesn't match the proper conceptual model for worldbuilding. The correct hierarchy should be:

- **Timeline** = Character's Point of View / Lifeline
  - Represents a character's entire narrative arc
  - Example: "Commander Vex's Timeline" (everything from Vex's perspective)

- **Chronicle** = Historical Event / Campaign
  - A specific event or period in the world's history
  - Has temporal bounds (start and end dates)
  - Can appear in MULTIPLE character timelines (different perspectives on the same event)
  - Example: "The Northern Campaign" appears in Vex's, Kael's, and Lyra's timelines

- **Scene** = Specific Moment
  - A discrete event within a chronicle or standalone
  - Has temporal position and duration
  - Example: "Fleet Departure" within "The Northern Campaign"

**Key Insight:** Chronicles are like "War of the Roses (1455-1485)" - historical events with temporal bounds that appear in multiple character storylines. They are NOT the primary organizational structure for timelines.

**Visual Design - Multi-Timeline Graph**

```
Timeline Track: "Vex's Timeline"
├─[═══════ The Northern Campaign ═══════]  ← Chronicle lozenge (span)
│   ├─┊ Fleet Departure                    ← Scene tick inside chronicle
│   ├─┊ Border Skirmish
│   └─┊ Station Assault
└─┊ Intelligence Briefing                   ← Scene tick outside chronicle

Timeline Track: "Kael's Timeline"
├─[═══════ The Northern Campaign ═══════]  ← Same chronicle, different timeline
│   ├─┊ Cargo Deal
│   └─┊ Outpost Delivery
└─┊ Black Market Deal                       ← Standalone scene
```

**Implementation Progress:**

### ✅ Phase 1: Enable Chronicles to Use Calendars - IMPLEMENTED (2026-01-28)

**Changes Made:**

1. **CardEditorView.swift** - Updated back face options panel
   - Line 612: Changed condition from `mode.kind == .timelines` to `mode.kind == .timelines || mode.kind == .chronicles`
   - Line 619: Dynamic title based on kind ("Timeline Options" vs "Chronicle Options")
   - Uses same `timelineConfigurationPanel` for both kinds

2. **CardEditorView.swift** - Updated create mode save logic
   - Line 1379: Extended condition to save calendar settings for Chronicles
   - Chronicles now persist `calendarSystem`, `epochDate`, and `epochDescription`

3. **CardEditorView.swift** - Updated edit mode save logic
   - Line 1445: Extended condition to update calendar settings for Chronicles
   - Chronicles can modify calendar system and epoch after creation

**What This Enables:**
- Chronicles can now select a calendar system (just like Timelines)
- Chronicles can set epoch date and description (when the chronicle begins)
- Supports flexible brainstorming workflow (create Chronicles before or after calendars)

**Files Modified:**
- `Cumberland/CardEditorView.swift` (3 changes)

---

### ✅ Phase 2: Multi-Timeline Graph Redesign - IMPLEMENTED (2026-01-29)

**Changes Made:**

1. **Updated Data Models** - New structures for proper hierarchy
   - `TimelineTrack`: Now includes `chronicles: [ChronicleSpan]` and `scenes: [SceneMarker]`
   - `ChronicleSpan`: Represents chronicle temporal span with `start`, `duration`, and nested `scenes`
   - `SceneMarker`: Represents scene marker with `position`, optional `duration`, and `parentChronicle`

2. **Updated Query Logic** (`loadData()`)
   - Fetches **only Timelines** using the calendar (not Chronicles as tracks)
   - For each Timeline, fetches Chronicles related via Chronicle→Timeline edges
   - For each Timeline, fetches Scenes related via Scene→Timeline edges
   - Checks Scene→Chronicle relationships to determine scene grouping
   - Groups scenes under their parent chronicles

3. **Updated Rendering** (`chartArea`)
   - **Layer 1**: Chronicle lozenges as semi-transparent `RectangleMark` spanning start to end
   - **Layer 2**: Scene markers as small `BarMark` with labels on top
   - Scenes within chronicles rendered at 80% opacity
   - Standalone scenes rendered at full opacity
   - Increased track height to 80 pixels to accommodate chronicles

**What This Enables:**
- ✅ Timelines = character storylines (horizontal tracks)
- ✅ Chronicles = temporal spans within timelines (lozenges)
- ✅ Scenes = markers at specific positions (inside or outside chronicles)
- ✅ Same chronicle can appear on multiple timelines with different temporal bounds
- ✅ Scenes can be standalone or grouped under chronicles
- ✅ Proper worldbuilding conceptual model (characters → timelines → chronicles → scenes)

**Files Modified:**
- `Cumberland/MultiTimelineGraphView.swift` (complete redesign of data models and rendering)

---

### ✅ Phase 2.1: Multi-Timeline Graph UI Refinements - IMPLEMENTED (2026-01-29)

**User Feedback Issues Addressed:**

After initial Phase 2 implementation, user testing revealed several UI/rendering issues:

1. **Missing timeline name column** - No clear labeling of which timeline is which
2. **No horizontal lines for timeline tracks** - Tracks were implicit, hard to visually separate
3. **Chronicle lozenges not visible** - Rendering issues made them invisible
4. **Scene boxes collapsed when zoomed out** - Very short durations became invisible dots
5. **No minimum scene width** - Need 1-2 pixel minimum regardless of duration
6. **Initial zoom tried to fit everything** - Unnecessary, should use nominal zoom
7. **Label clipping on leftmost scenes** - Chart bounds cut off scene labels

**Changes Made:**

1. **Added Left Column for Timeline Names** (MultiTimelineGraphView.swift:257-275)
   - Created fixed-width left sidebar (150pt) with timeline names and color dots
   - Properly aligned with chart tracks
   - Uses `.thinMaterial` background for visual separation
   - Divider between column and chart area

2. **Added Horizontal Timeline Track Lines** (MultiTimelineGraphView.swift:284-288)
   - `RuleMark` with 60pt `lineWidth` and 10% opacity creates visible track backgrounds
   - Color-coded to match timeline colors
   - Provides clear visual separation between timelines

3. **Enhanced Chronicle Lozenges Visibility** (MultiTimelineGraphView.swift:290-307)
   - Increased opacity from 0.2 to 0.3 for better visibility
   - Added explicit `height: .fixed(40)` to ensure consistent rendering
   - Enhanced label styling with `.primary` foreground and `.medium` font weight
   - Improved background material for chronicle labels

4. **Guaranteed Minimum Scene Bar Width** (MultiTimelineGraphView.swift:312-322)
   - Implemented minimum display duration of 2 hours (7200 seconds)
   - Formula: `max(actualDuration, minDisplayDuration)` ensures visibility
   - Scene bars now have fixed height of 12pt for consistency
   - Prevents scenes from collapsing to invisible dots when zoomed out

5. **Nominal Initial Zoom Level** (MultiTimelineGraphView.swift:553-559)
   - Changed from auto-fit to nominal `.month` zoom level
   - Scroll position starts at earliest event (left-aligned)
   - User can still use "Fit All" button if desired
   - Provides more usable initial view instead of trying to show everything

6. **Extended Chart Bounds to Prevent Label Clipping** (MultiTimelineGraphView.swift:270-274)
   - Added 5% padding on both sides of the date range
   - Prevents scene labels from being cut off at chart edges
   - Formula: `padding = totalSpan * 0.05`
   - Also considers chronicle bounds when calculating date range

7. **Improved Y-Axis Grid Lines** (MultiTimelineGraphView.swift:346-350)
   - Added subtle dashed grid lines between tracks (30% opacity)
   - Helps visually separate timelines without overwhelming the chart
   - Uses 2-2 dash pattern for subtlety

**What This Fixes:**
- ✅ Clear timeline identification with left column names
- ✅ Visual separation of timeline tracks with horizontal background lines
- ✅ Chronicle lozenges now clearly visible with proper size and opacity
- ✅ Scene bars maintain minimum 2-hour display width (never collapse to dots)
- ✅ Nominal zoom provides usable initial view (user controls fit-all)
- ✅ Scene labels no longer clipped at chart edges
- ✅ Overall improved readability and visual hierarchy

**Files Modified:**
- `Cumberland/MultiTimelineGraphView.swift` (comprehensive UI refinements)

---

## Verification Summary

✅ **Phase 1 Verified:**
- Chronicles can select calendar systems
- Chronicle Options panel appears on back face
- Epoch date and description persist correctly

✅ **Phase 2 Verified:**
- Multi-Timeline Graph now queries only Timelines as tracks
- Chronicles appear as temporal spans (lozenges) within timeline tracks
- Scenes appear as markers inside chronicles or standalone on tracks
- Same chronicle can appear on multiple timelines with different bounds
- Proper hierarchical conceptual model implemented

✅ **Phase 2.1 Verified:**
- Timeline names appear in left column with color dots
- Horizontal track lines provide clear visual separation
- Chronicle lozenges are clearly visible with proper size and labels
- Scene bars maintain minimum width and never collapse
- Initial nominal zoom provides usable view
- Scene labels no longer clipped at chart edges
- Overall improved readability and visual hierarchy

**Benefits:**
- ✅ Matches proper worldbuilding conceptual model
- ✅ Chronicles can appear in multiple character timelines
- ✅ Scenes can be grouped under chronicles or standalone
- ✅ Supports flexible, non-linear brainstorming workflow
- ✅ Visual clarity (timelines = tracks, chronicles = spans, scenes = markers)
- ✅ Professional-quality visualization for complex multi-character narratives

**Related:**
- ER-0008: Timeline System (builds on Phase 8 Multi-Timeline Graph)
- ER-0012: Chronicles Card Type (enables Chronicles as worldbuilding entities)
- DR-0057 through DR-0064: Temporal editor fixes (enable calendar-based positioning)

---

*Last Updated: 2026-01-30*
*Status: All 4 ERs verified*
