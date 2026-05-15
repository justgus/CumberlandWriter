# Enhancement Requests (ER) — Proposed

- Guidelines: [Cumberland/Documentation/ER-Reports/ER-Guidelines.md]

**Purpose:** This file contains enhancement requests that have been proposed and are awaiting scheduling or approval for active development. These are features we intend to implement in the near future.

**Status:** Currently **3 proposed ERs**

**Note:** All visionOS expansion ERs (ER-0042 through ER-0051) have been moved to ER-backlog.md for long-term planning.

---

## ER-0053: Manuscript Chapter/Scene Deletion Strategy with Content Preservation

**Status:** 🔵 Proposed
**Component:** ProjectWriter/ManuscriptWritingSurfaceView
**Priority:** High
**Date Requested:** 2026-04-25

**Rationale:**
When writers delete chapters or scenes from the Manuscript View, we need a deletion strategy that protects their work while maintaining a clean manuscript structure. Writers may later want to revisit deleted content, reuse scenes in different contexts, or restore accidentally deleted material. The current implementation allows deletion but doesn't address content preservation, versioning, or recovery.

**Current Behavior:**
- Chapter deletion uses `CardRepository.delete()` which properly cleans up relationships
- Scene deletion is not yet implemented in Manuscript View
- Deleted content is permanently removed from the database
- No recovery mechanism exists for deleted chapters or scenes
- Manuscript text disappears when parent chapter/scene is deleted

**Desired Behavior:**
Writers should be able to:
1. Delete chapters/scenes from the active manuscript view
2. Have deleted content preserved somewhere for later retrieval
3. Restore deleted content if needed
4. See a clear distinction between "active" and "archived" content
5. Optionally permanently delete content when truly no longer needed

**Key Design Questions to Explore:**

1. **Where should deleted content live?**
   - Option A: "Deleted Scenes" backlog (special category in sidebar)
   - Option B: "Archive" section within the project
   - Option C: Soft-delete flag on Card model (visible in special view)
   - Option D: Separate "Trash" container card

2. **What gets preserved when deleting?**
   - Scene text (`detailedText`)
   - Scene relationships (characters, locations, etc.)
   - Scene metadata (structure assignments, timeline positions)
   - Original chapter context
   - Deletion timestamp and reason

3. **How long is content preserved?**
   - Indefinitely (manual cleanup required)
   - Time-based expiration (e.g., 30 days)
   - Until project export/publish
   - User-configurable retention policy

4. **What about cascading deletes?**
   - If chapter is deleted, what happens to its scenes?
     - Move scenes to "Orphaned Scenes"?
     - Move entire chapter+scenes to archive together?
     - Prompt user for choice?
   - If scene is deleted, what happens to its relationships?
     - Preserve relationships for restoration?
     - Clean up relationships immediately?

5. **Recovery mechanism:**
   - Simple restore button (puts content back where it was)
   - Restore with new position (choose chapter/location)
   - Copy instead of move (keep in both places)
   - Review before restore (show preview of content)

6. **Version control considerations:**
   - Should we snapshot content before deletion?
   - Track edit history of scenes over time?
   - Allow comparison between current and deleted versions?
   - Integration with CloudKit sync

**Requirements:**
1. Deleted chapters/scenes must not appear in manuscript view
2. Deleted content must be recoverable by the writer
3. Content preservation must sync across devices (CloudKit compatible)
4. Deletion must be reversible without data loss
5. UI must clearly indicate deleted vs. active content
6. Performance must not degrade with large archives
7. Must handle cascading deletes (chapter → scenes) gracefully

**Components Affected:**
- **ManuscriptWritingSurfaceView.swift**: Deletion UI and behavior
- **Card.swift**: Possibly add soft-delete flag or archive status
- **CardRepository.swift**: Deletion and restoration methods
- **EdgeRepository.swift**: Relationship handling during delete/restore
- **MainAppView.swift**: Possibly add "Archive" or "Deleted" sidebar section
- **ManuscriptAssembler.swift**: Filter out deleted content from assembly

**Design Approach:**
[To be determined after discussion with user]

**Implementation Details:**
[Not yet implemented]

**Test Steps:**
[Will be defined once approach is chosen]

**Notes:**
- This is a critical UX decision that affects writer workflow significantly
- Need to research how other writing tools handle deletion (Scrivener, Ulysses, etc.)
- Consider phased implementation: Start with simple backlog, expand to version control later
- Must balance content safety with UI complexity
- CloudKit sync implications need careful consideration
- Related to broader versioning/history system (possible future ER)

**Open Questions:**
1. Should we implement simple backlog first, then add versioning later?
2. How do other writing applications handle this?
3. Should deletion be a "soft" operation by default with periodic hard-delete cleanup?
4. Do we need a "permanent delete" option for sensitive content?
5. Should archived content count against project statistics/word count?

---

## ER-0054: Project Dashboard View - Instrument Panel for Project Status

**Status:** 🔵 Proposed
**Component:** ProjectWriter/ProjectDashboardView
**Priority:** Medium
**Date Requested:** 2026-04-26

**Rationale:**
Writers need a high-level view of project status, structure progress, character distribution, and issues at a glance. The Project Dashboard serves as an "instrument panel" providing dense but readable information about the project's health and progress without requiring writers to dig through multiple views or menus.

**Current Behavior:**
According to `PROJECT-WRITER-ARCHITECTURE.md` Phase 4, the ProjectDashboardView has been implemented with:
- Status Glyph (three concentric rings showing timeline/chapter/scene status)
- Structure Band with beat visualization
- Return Strip (Last/Resume/Next navigation)
- Cast Shelf (character portraits)
- Issues Shelf (orphan detection)
- Thread Shelf (placeholder)
- Full data integration via `ProjectDashboardService`

However, the actual functionality and user experience need formal requirements documentation.

**Desired Behavior:**
The Project Dashboard should provide:

1. **At-a-glance project health** through visual instruments
2. **Quick navigation** to resume writing or jump to specific sections
3. **Issue awareness** showing orphaned scenes, missing structure elements
4. **Character tracking** showing which characters appear in the project
5. **Structure progress** visualizing completion of story beats
6. **Minimal cognitive load** through geometric shapes and position rather than text

**Requirements:**

### R1: Project Header
- Display project name (editable inline)
- Show project thumbnail/cover image
- Allow quick access to project settings

### R2: Structure Band
- Display selected story structure name (if any)
- Show structure beats as nodes along a horizontal band
- Show Scenes as different thicknesses of the story structure line.  
- Visualize narrative arc contour as Tufte-style background?  <what does this mean?>
- Indicate which beats have assigned scenes by varying the color of the structure line
- Allow clicking to open Structure Board
- Show "No structure defined" empty state with "Select Structure" button

### R3: Status Glyph (Three Concentric Rings)
- **Outer Ring (Timeline)**: Show timeline events as angular spans
- **Middle Ring (Chapters)**: Show chapters as angular spans
  - Color indicates state: formed (1+ scenes) vs. thin-defined (0 scenes)
- **Inner Ring (Scenes)**: Show scenes as angular spans
  - Color indicates content state: formed (100+ words) vs. thin-defined
  - Highlight orphaned scenes (not in any chapter)
- **Center**: Show completion percentage or "Empty" state
- Rings should use 90% of circle (leaving gap for Begin/End markers)

### R4: Return Strip (Last / Resume / Next)
- **Last Node**: Previous working scene (if available)
- **Resume Node**: Recommended scene to continue work
- **Next Node**: Next structural opening or new scene
- Each node shows:
  - Scene title
  - Scene subtitle (optional)
  - Short excerpt (first 40-60 characters)
  - Icon or visual indicator
- Click node to navigate to that scene in Manuscript View
- Empty state: "No scenes yet" / "Create your first scene to begin"

### R5: Cast Shelf
- Display up to 8 character portraits in horizontal grid
- Show character names below portraits
- Use character thumbnail or initials if no image
- Click character to open card detail
- Empty state: "No characters linked to scenes yet"
- More indicator ("+3 more") if > 8 characters

### R6: Issues Shelf
- Detect and display project issues:
  - Orphaned scenes (scenes not in any chapter)
  - Orphaned chapters (chapters not linked to project)
  - Continuity gaps (future: timeline vs. manuscript mismatches)
- Each issue shows:
  - Icon indicating issue type
  - Count of affected items
  - Severity color (warning yellow, error red)
- Click issue to navigate to resolution UI
- Empty state: "No issues detected" with checkmark

### R7: Thread Shelf
- Display narrative threads (placeholder for future)
- Show thread tags with weight-based visual treatment
- Click thread to filter related scenes
- Empty state: "No threads defined yet"

### R8: Data Integration
- All data sourced from `ProjectDashboardService`
- Service uses `CardRepository` and `EdgeRepository` for queries
- Refresh dashboard when returning from Manuscript View
- Handle missing data gracefully (show empty states)

### R9: Performance
- Dashboard load time < 500ms for projects with 100+ scenes
- Use async data loading to prevent UI blocking
- Cache dashboard model until project data changes

### R10: Empty State Handling
- Each component must have appropriate empty state
- Empty states should guide users to next action
- Consistent empty state styling across all components

**Design Approach:**
The dashboard follows **instrument panel design principles**:
- Show state through geometry, continuity, weight, and position
- Use text only where necessary (labels, numbers, issue descriptions)
- Dense but readable information display
- Remain useful at early, mid, and late project stages
- Inspired by Tufte's information design principles

**Components Affected:**
- **ProjectWriter/ProjectDashboardView.swift**: Main UI implementation
- **Data/ProjectDashboardService.swift**: Data aggregation and transformation
- **Data/ProjectDashboardModels.swift**: Data structures for dashboard
- **Data/CardRepository.swift**: Scene/chapter/character queries
- **Data/EdgeRepository.swift**: Relationship queries for ring spans

**Implementation Details:**
[See PROJECT-WRITER-ARCHITECTURE.md Phase 4 for detailed implementation status]

**Test Steps:**
1. Create new project
2. Navigate to Dashboard tab
3. Verify all empty states display correctly
4. Create 1-2 chapters with scenes
5. Verify Status Glyph shows chapter/scene rings
6. Verify Resume Strip shows resume target
7. Add characters to scenes
8. Verify Cast Shelf displays characters
9. Create orphaned scene (not in chapter)
10. Verify Issues Shelf shows orphan count
11. Select story structure
12. Verify Structure Band displays beats and arc

**Notes:**
- Dashboard is view-only (no editing directly in dashboard)
- All editing actions navigate to appropriate view (Manuscript, Structure Board, Card Editor)
- Dashboard should feel like a "cockpit" providing situational awareness
- Visual design should support focus and quick scanning

---

## ER-0055: Manuscript Writing Surface View - Comprehensive Architecture

**Status:** 🔵 Proposed
**Component:** ProjectWriter/ManuscriptWritingSurfaceView
**Priority:** Critical
**Date Requested:** 2026-04-26

**Rationale:**
The Manuscript Writing Surface is the primary interface where writers compose their narrative. It must balance focus (distraction-free writing) with context awareness (scene tracking, entity detection, structural guidance). The current implementation has core features but lacks comprehensive cursor tracking, text persistence mapping, and dynamic context updates.

**Current Behavior:**
According to `PROJECT-WRITER-ARCHITECTURE.md` Phase 3, ManuscriptWritingSurfaceView has:
- Continuous text editor (currently using standard SwiftUI TextEditor)
- Chapter tab strip
- Scene map instrument
- Context gutter with potential card detection
- Quick action tray
- Chapter/scene creation with proper repository usage

**Missing/Broken:**
- Cursor position tracking
- Automatic scene detection based on cursor position
- Cursor placement when clicking chapter/scene
- Dynamic context updates as cursor moves
- Text-to-Card persistence mapping
- Proper NSTextView integration for full control

**Desired Behavior:**
A comprehensive dynamic writing surface that:

1. **Knows where the writer is** - Tracks cursor position and maps to scene
2. **Updates context automatically** - Shows relevant cards based on current scene
3. **Provides seamless navigation** - Jump to scenes/chapters with cursor placement
4. **Persists text correctly** - Maps edits to correct scene's `detailedText`
5. **Detects entities in real-time** - Suggests potential cards as writer types
6. **Fills available space** - Uses entire view area efficiently

**Requirements:**

### R1: Text Editor Component
- **MUST** provide cursor position tracking
- **MUST** support programmatic cursor placement
- **MUST** fill all available vertical/horizontal space
- **MUST** handle text changes without layout recursion errors
- **MUST** properly integrate with SwiftUI layout system
- **MUST** support undo/redo
- **MUST** use readable serif font (16pt)
- **MUST** provide scrolling with keyboard/trackpad

### R2: Cursor Position Tracking
- Track cursor position in characters from start of manuscript
- Debounce cursor position updates (max 60fps)
- Map cursor position to current scene boundary
- Update `activeSceneID` when cursor crosses scene boundary
- Update `activeChapterID` when cursor crosses chapter boundary
- Provide callback for cursor position changes: `onCursorPositionChanged: (Int) -> Void`

### R3: Scene Boundary Detection
- `ManuscriptAssembler` provides scene text ranges in `ManuscriptResult`
- Map cursor position to scene using `SceneInfo.textRange`
- Handle edge cases:
  - Cursor at exact scene boundary (assign to following scene)
  - Cursor in chapter heading (assign to first scene of chapter)
  - Cursor in orphaned scene (no chapter context)

### R4: Automatic Context Updates
- When cursor moves to new scene:
  1. Update `activeSceneID`
  2. Clear `sceneContext.potentialCards` for previous scene
  3. Load confirmed cards for new scene from relationships
  4. Trigger entity detection for new scene text
- Debounce context updates (wait 200ms after cursor stops moving)

### R5: Chapter/Scene Navigation
- **When clicking chapter tab:**
  - Set `activeChapterID`
  - Find first scene in chapter
  - Set `activeSceneID`
  - Move cursor to end of last scene in chapter
  - Scroll to make cursor visible

- **When clicking scene in Scene Map:**
  - Set `activeSceneID`
  - Set `activeChapterID` (if scene has chapter)
  - Move cursor to end of scene
  - Scroll to make cursor visible

### R6: Text-to-Card Persistence
- **Challenge**: Manuscript is continuous text, but scenes are separate Cards
- **Solution**:
  1. When text changes, determine which scene was edited (cursor position)
  2. Extract that scene's text from manuscript using `SceneInfo.textRange`
  3. Update corresponding Card's `detailedText` via `CardRepository`
  4. Debounce saves (500ms after typing stops)
- **Edge Cases**:
  - Typing across scene boundary → split edit between two scenes
  - Deleting scene separator → merge scenes (TBD: show warning?)
  - Pasting multi-scene text → distribute across scenes

### R7: Chapter/Scene Indicators
- **Chapter Tab Strip** (top):
  - Horizontal scrollable tabs
  - Active chapter highlighted
  - Click to jump to chapter
  - Long-press or right-click to rename
  - Context menu: Rename, Delete
  - Default name: "Chapter N" where N is 1-indexed

- **Scene Indicator Chip** (floating, below chapter bar):
  - Shows current scene name
  - Format: "Scene N • [Scene Name]"
  - Updates automatically as cursor moves
  - Minimal, non-intrusive design
  - Only shows when cursor is in a scene

- **Scene Map** (bottom):
  - Horizontal strip of scene markers
  - One marker per scene
  - Active scene highlighted
  - Click to jump to scene
  - Shows scene number and name

### R8: Context Gutter
- **Location** (right side, 320pt width):
  - Top: Location card (potential or confirmed)
  - Middle: Potential cards detected in current scene
  - Bottom: Confirmed cards linked to current scene

- **Updates**:
  - When cursor moves to new scene → reload for that scene
  - When text changes → re-run entity detection (debounced 500ms)
  - When potential card confirmed → move to confirmed section
  - When potential card dismissed → remove from list

- **Interaction**:
  - Click potential card → show confirm/dismiss menu
  - Click confirmed card → open card detail sheet
  - Visual distinction: potential (40% opacity, dashed border) vs. confirmed (full color, solid border)

### R9: Entity Detection
- Run `EntityDetectionService.detectEntities()` when:
  - Text changes (debounced 500ms)
  - Cursor moves to new scene
- Analyze only current scene's text (not entire manuscript)
- Detection strategies:
  - Exact match with existing card names
  - Fuzzy match (Levenshtein distance)
  - Capitalized phrases (NER-style)
  - Context keywords ("took the [artifact]", "arrived at [location]")
- Return `[PotentialCard]` sorted by confidence
- Remove potential cards when triggering text deleted

### R10: Empty States
- **No chapters/scenes**: Show welcome message with "Add Chapter" and "Add Scene" buttons
- **Empty scene**: Allow typing immediately, show scene indicator chip
- **No context cards**: Show minimal gutter with "Start writing to detect entities"

### R11: Manuscript Assembly
- Use `ManuscriptAssembler.assembleManuscript()` to generate:
  - Continuous text with chapter headings
  - Scene separators between scenes
  - Scene boundary metadata (`SceneInfo` with text ranges)
- Reload manuscript when:
  - Scene/chapter created
  - Scene/chapter deleted
  - Scene/chapter reordered
  - Switching to Manuscript View

### R12: Performance
- Text editor must handle manuscripts up to 100,000 words
- Cursor position updates must not lag (< 16ms per update)
- Entity detection must not block typing (run in background)
- Manuscript assembly must complete in < 200ms for 50 scenes

**Design Constraints:**
1. **Cannot use standard SwiftUI TextEditor** - No cursor tracking
2. **Must use NSTextView (macOS) / UITextView (iOS)** - Via `NSViewRepresentable` / `UIViewRepresentable`
3. **Must avoid layout recursion** - Don't trigger layout during makeNSView/updateNSView
4. **Must handle empty text** - Editor must appear even with zero-length manuscript
5. **Must handle missing scenes** - Graceful degradation if `ManuscriptAssembler` returns empty

**Components Affected:**
- **ProjectWriter/ManuscriptWritingSurfaceView.swift**: Main view implementation
- **ProjectWriter/ManuscriptTextEditor.swift**: Custom text editor component (NEW)
- **ProjectWriter/ManuscriptAssembler.swift**: Scene boundary calculation
- **ProjectWriter/EntityDetectionService.swift**: Entity detection logic
- **ProjectWriter/PotentialCard.swift**: SceneContext state management
- **Data/CardRepository.swift**: Scene text persistence

**Implementation Details:**
[To be implemented based on formal design]

**Test Steps:**
1. Create project with 2 chapters, 2 scenes each
2. Navigate to Manuscript View
3. Verify text editor fills available space
4. Type in first scene, verify cursor appears
5. Move cursor to second scene
6. Verify scene indicator updates
7. Verify context gutter reloads
8. Click Chapter 2 tab
9. Verify cursor moves to end of Chapter 2
10. Click Scene 3 in Scene Map
11. Verify cursor moves to Scene 3
12. Type character name "Alice"
13. Verify potential card appears in gutter (debounced)
14. Delete "Alice"
15. Verify potential card removed

**Open Questions:**
1. How should we handle typing across scene boundaries?
2. Should scene separators be editable or protected?
3. Should we auto-save on every text change or debounce?
4. How do we handle concurrent edits across devices (CloudKit)?
5. Should we support rich text (bold, italic) or plain text only?

**Notes:**
- This is the most complex component in the Project Writer system
- Requires deep integration between SwiftUI and AppKit/UIKit
- Text persistence mapping is critical for data integrity
- Performance is critical for writer experience

---

## ER-0056: Manuscript Text Editor - Widget-Based Architecture

**Status:** 🔵 Proposed
**Component:** ProjectWriter/ManuscriptTextEditor (entire system)
**Priority:** Critical
**Date Requested:** 2026-04-26
**Updated:** 2026-04-26 (Complete architectural redesign)

**Rationale:**
The manuscript is not a single continuous text document, but a structured collection of Scenes organized into Chapters. Each Scene is a separate Card in the database with its own `detailedText`. The "Manuscript Text Editor" is actually a vertically scrolling container holding Chapter Widgets, each containing Scene Widgets. This architecture:

1. **Maintains data integrity** - Each Scene Widget directly edits its Scene Card's `detailedText`
2. **Enables scene tracking** - Active Scene Widget indicates current writing context
3. **Supports scene manipulation** - Drag/drop scenes to reorder within/across chapters
4. **Allows seamless editing** - Appears as continuous text but maintains scene boundaries
5. **Enables entity detection** - Context updates per-scene as writer moves between widgets

**Architectural Principles:**

The manuscript text is **not stored as a single entity**. Instead:
- **Scene Cards** contain text in `Card.detailedText` (Plain Text, Markdown, or Rich Text)
- **Chapters** define ordering of scenes via `CardEdge.sortIndex`
- **Project** defines ordering of chapters via `CardEdge.sortIndex`
- **ManuscriptTextEditor** assembles these into a seamless vertical stack

**Current Behavior:**
Previous approach attempted a single NSTextView with cursor position mapping. This was fundamentally flawed because:
- No clear Scene Card ownership of text edits
- Complex cursor-to-scene mapping logic
- Layout recursion errors
- Text persistence ambiguity

**Desired Behavior:**
A widget-based vertical stack that:

1. **Appears seamless** - Looks like one continuous editor to the writer
2. **Maintains scene boundaries** - Each Scene Widget edits its own Scene Card
3. **Tracks active widget** - Always knows which scene is being edited
4. **Supports cross-widget navigation** - Arrow keys move between Scene Widgets
5. **Enables scene operations** - Select, drag, cut, copy, paste entire scenes
6. **Persists correctly** - Scene Widget text changes save directly to Scene Card

**Requirements:**

### R1: ManuscriptTextEditor Container (Top Level)
The ManuscriptTextEditor is a **ScrollView containing a VStack of Chapter Widgets**.

**Structure:**
```
ScrollView(.vertical) {
    VStack(spacing: 0) {
        ForEach(chapters) { chapter in
            ChapterWidget(chapter: chapter)
        }
    }
}
```

**Responsibilities:**
- Scroll management for entire manuscript
- Keyboard event routing (for cross-widget navigation)
- Overall layout and spacing
- Fill all available space in Manuscript Writing Surface

**NOT responsible for:**
- Text editing (handled by Scene Widgets)
- Scene-level operations (handled by Scene Widgets)
- Individual scene focus (handled by Scene Widgets)

### R2: Chapter Widget
A Chapter Widget is a **VStack containing Scene Widgets for all scenes in that chapter, plus a Chapter Selection Grip**.

**Structure:**
```swift
struct ChapterWidget: View {
    let chapter: Card  // Chapter card
    @Query var scenes: [Card]  // Scenes in this chapter, sorted by sortIndex
    @State private var isActive: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Scene widgets stack (leading to trailing)
            VStack(spacing: 0) {
                ForEach(scenes) { scene in
                    SceneWidget(scene: scene, chapter: chapter)
                }
            }

            // Chapter Selection Grip (trailing edge)
            ChapterSelectionGrip(chapter: chapter, sceneCount: scenes.count, isActive: isActive)
                .frame(width: 8)
        }
    }
}
```

**Responsibilities:**
- Query scenes for this chapter from CardRepository
- Order scenes by `sortIndex` on Scene → Project edges
- Layout Scene Widgets vertically with no gaps
- Display Chapter Selection Grip on trailing edge for chapter-level operations
- Track active state (is any scene in this chapter active?)
- Handle empty state (chapter with no scenes)

**Spatial Layout:**
- **Leading edge** (left): Scene Selection Grips (4pt each)
- **Center**: Scene text editors
- **Trailing edge** (right): Chapter Selection Grip (8pt)
- This mirrors the creation button layout: scenes on left, chapters on right

**Notes:**
- No visual chapter heading or separator in manuscript text
- Chapter Selection Grip provides visual indicator of chapter boundaries
- Chapter identity known through scene membership and grip
- Empty chapters show grip only (no scenes until added)

### R3: Scene Widget (Core Component)
A Scene Widget is a **text editor for a single Scene Card's `detailedText`**.

**Interface:**
```swift
struct SceneWidget: View {
    let scene: Card  // Scene card (kind = .scenes)
    let chapter: Card  // Parent chapter
    @State private var isActive: Bool = false
    @State private var sceneText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Selection grip (leading edge)
            SceneSelectionGrip(scene: scene, isActive: isActive)
                .frame(width: 4)

            // Text editor
            SceneTextEditor(
                text: $sceneText,
                scene: scene,
                isActive: $isActive,
                isFocused: $isFocused,
                onTextChanged: { newText in
                    saveSceneText(newText)
                },
                onNavigateUp: {
                    activatePreviousScene()
                },
                onNavigateDown: {
                    activateNextScene()
                }
            )
        }
    }
}
```

**Responsibilities:**
- Load scene text from `scene.detailedText` on appear
- Save scene text to `scene.detailedText` via CardRepository (debounced 500ms)
- Track active state (is this the scene being edited?)
- Handle focus (keyboard focus for this widget)
- Display selection grip for scene operations
- Notify parent when cursor navigates up/down out of bounds

**Active State:**
- Active scene = scene containing cursor
- Only ONE scene widget active at a time
- Active state updates Context Gutter
- Active state triggers entity detection

### R4: Scene Text Editor (NSTextView/UITextView Wrapper)
The actual text editing component for a single scene.

**Interface:**
```swift
struct SceneTextEditor: NSViewRepresentable { // or UIViewRepresentable
    @Binding var text: String
    let scene: Card
    @Binding var isActive: Bool
    @Binding var isFocused: Bool
    var onTextChanged: (String) -> Void
    var onNavigateUp: () -> Void  // Arrow up from first line
    var onNavigateDown: () -> Void  // Arrow down from last line
}
```

**Configuration (macOS):**
- Font: Serif, 16pt (e.g., Georgia, Palatino, or system serif)
- Text inset: 60pt horizontal, 20pt vertical
- Background: `.textBackgroundColor` (or theme background)
- No scrollbars (scrolling handled by parent ScrollView)
- Allow undo/redo
- Support Plain Text, Markdown, or Rich Text (via scene metadata)
- Text wrapping enabled
- NO individual scene scrolling (scenes stack in parent scroll view)

**Configuration (iOS):**
- Font: Serif, 16pt
- Text inset: 60pt horizontal, 20pt vertical
- Background: `.systemBackground`
- Keyboard type: `.default`
- Allow undo/redo
- Autocorrection and spell checking enabled

**Text Change Handling:**
- When user types → update `text` binding
- Call `onTextChanged(newText)` callback
- Debounce save to Card (500ms after typing stops)
- Use `DispatchQueue.main.async` for all binding updates

**Arrow Key Navigation:**
- Detect when cursor on first line + arrow up pressed → call `onNavigateUp()`
- Detect when cursor on last line + arrow down pressed → call `onNavigateDown()`
- Parent widget handles activating previous/next scene

**Focus Management:**
- When `isFocused` becomes `true` → make text view first responder
- When `isFocused` becomes `false` → resign first responder
- Update `isActive` when editor receives/loses focus

### R5A: Chapter Selection Grip
A wider vertical UI element on the **trailing edge** (right side) of Chapter Widget for chapter-level operations.

**Visual Design:**
- Width: 8pt (wider than Scene Grip to distinguish hierarchy)
- Height: Full height of all scenes in chapter combined
- Color: Distinct from Scene Grip (e.g., 15% opacity of primary theme color)
- Position: Trailing edge (right) - mirrors "Create Chapter" button position
- Visible at all times (subtle when chapter not active)
- More prominent when any scene in chapter is active
- Highlight on hover

**Spatial Relationship:**
- Scene grips on leading edge (left) at 4pt each
- Chapter grip on trailing edge (right) at 8pt
- Creates visual hierarchy: scene-level (left) vs chapter-level (right)
- Matches creation button layout for intuitive operation scope
- Visual indicator at top/bottom showing chapter extent

**Interaction:**
- **Click**: Select entire chapter (all scene widgets)
- **Click + drag**: Drag chapter to reorder within project
- **Right-click**: Context menu:
  - Cut Chapter (all scenes move with it)
  - Copy Chapter (duplicates chapter + all scenes)
  - Duplicate Chapter (creates new chapter with copied scenes)
  - Delete Chapter (see ER-0053 for deletion strategy)
  - Insert Chapter Above/Below

**Selection Behavior:**
- When grip clicked → select all scenes in chapter
- All Scene Widgets in chapter show selection state
- Selection persists until user clicks elsewhere
- Selected chapter can be cut/copied/deleted via menu or keyboard shortcuts

**Notes:**
- Chapter Grip spans from first scene to last scene in chapter
- If chapter is empty, grip shows minimum height (e.g., 40pt) with "Empty Chapter" indicator
- Grip provides visual chapter boundary in otherwise seamless manuscript

### R5B: Scene Selection Grip
A narrow vertical UI element on the leading edge of Scene Widget for scene operations.

**Visual Design:**
- Width: 4pt (narrower than Chapter Grip)
- Height: Full height of scene text
- Color: Subtle, based on theme (e.g., 10% opacity of accent color)
- Invisible when scene not active and chapter not active
- Visible with gentle color when scene active
- Highlight on hover
- Inset slightly from Chapter Grip (visual hierarchy)

**Interaction:**
- **Click**: Select entire scene text
- **Click + drag**: Drag scene to reorder (within chapter or to different chapter)
- **Right-click**: Context menu:
  - Cut Scene
  - Copy Scene
  - Duplicate Scene
  - Delete Scene
  - Insert Scene Above/Below

**Selection Behavior:**
- When grip clicked → select all text in Scene Widget
- Selection persists until user clicks elsewhere
- Selected scene can be cut/copied/deleted via menu or keyboard shortcuts

**Visual Relationship:**
- Scene Grip on leading edge (left) at 4pt
- Chapter Grip on trailing edge (right) at 8pt
- Scene and Chapter grips on opposite sides (not adjacent)
- Leading edge: 4pt Scene Grip + 60pt text inset = 64pt from left
- Trailing edge: 60pt text inset + 8pt Chapter Grip = 68pt from right
- Clear visual hierarchy and spatial separation of operation scopes

### R6: Cross-Widget Navigation
Seamless navigation between Scene Widgets using arrow keys.

**Arrow Up from First Line:**
1. Scene Widget detects cursor on line 1 + up arrow pressed
2. Calls `onNavigateUp()` callback
3. Parent Chapter Widget (or container) identifies previous Scene Widget
4. Activates previous Scene Widget
5. Sets focus to previous widget
6. Moves cursor to last line of previous scene

**Arrow Down from Last Line:**
1. Scene Widget detects cursor on last line + down arrow pressed
2. Calls `onNavigateDown()` callback
3. Parent Chapter Widget (or container) identifies next Scene Widget
4. Activates next Scene Widget
5. Sets focus to next widget
6. Moves cursor to first line of next scene

**Edge Cases:**
- First scene in manuscript + arrow up → no-op (stay at line 1)
- Last scene in manuscript + arrow down → no-op (stay at last line)
- Empty scene → allow navigation through it

### R7: Text Format Support
Scene Widgets must support three text formats:

**Format 1: Plain Text** (Default)
- Simple UTF-8 string
- No formatting, no markup
- Direct storage in `Card.detailedText`

**Format 2: Markdown**
- Text stored as Markdown in `Card.detailedText`
- Editor shows raw Markdown syntax while editing
- Possible preview mode (future)
- Standard Markdown extensions (tables, footnotes, etc.)

**Format 3: Rich Text**
- Text stored as NSAttributedString data in `Card.detailedText` (encoded)
- Editor renders rich text (bold, italic, fonts, colors)
- Full NSTextView/UITextView rich text capabilities
- Toolbar for formatting (future)

**Format Selection:**
- Per-scene setting (stored in scene metadata or Card property)
- Default: Plain Text or Markdown (user preference)
- Can convert between formats with confirmation

### R8: Scene Creation and Deletion

**Creating New Scene (End of Chapter):**
1. User clicks "+ Add Scene" or creates via quick action
2. `CardRepository.createCard(kind: .scenes, name: "New Scene")`
3. Link scene to chapter via EdgeRepository
4. Link scene to project via EdgeRepository (with `chapterID` and `sortIndex`)
5. Create Scene Widget for new scene
6. Append to Chapter Widget's VStack
7. Set focus to new Scene Widget
8. Move cursor to line 1 (empty scene)

**Creating New Scene (Specific Position):**
1. User right-clicks Scene Selection Grip → "Insert Scene Above/Below"
2. Create scene as above
3. Adjust `sortIndex` values to insert at correct position
4. Rebuild Chapter Widget's scene list
5. Focus new Scene Widget

**Deleting Scene:**
- **Not implemented in ER-0056** - See ER-0053 for deletion strategy
- Scene deletion requires preservation/archival system

### R9: Scene Cut, Copy, Paste

**Cut Scene:**
1. Select scene via Selection Grip or select all text
2. Cmd+X or Right-click → "Cut Scene"
3. Copy scene data to pasteboard (scene ID, text, metadata, source chapter ID)
4. Mark scene for deletion (pending ER-0053 implementation)
5. Remove Scene Widget from view
6. Recalculate `sortIndex` for remaining scenes in source chapter (close gaps)

**Copy Scene:**
1. Select scene via Selection Grip or select all text
2. Cmd+C or Right-click → "Copy Scene"
3. Copy scene data to pasteboard (text, metadata, format)

**Paste Scene:**
1. Select target position (between scenes or end of chapter)
2. Cmd+V or Right-click → "Paste Scene"
3. If pasteboard contains scene data:
   - Create new Scene Card via `CardRepository.createCard()`
   - Copy text to `detailedText` and metadata
   - Link to project via `EdgeRepository` with `chapterID` and `sortIndex`
   - **If pasting into SAME chapter:**
     - Insert at target position
     - Adjust `sortIndex` values for scenes at/after insertion point
   - **If pasting into DIFFERENT chapter (cross-chapter paste):**
     - Set `chapterID` to target chapter's ID
     - Set `sortIndex` to insertion position in target chapter
     - Adjust `sortIndex` values in target chapter for scenes at/after insertion point
     - Do NOT modify source chapter (scene already removed if cut, unchanged if copy)
   - Create Scene Widget at insertion point
   - Rebuild affected Chapter Widget(s)
   - Set focus to pasted Scene Widget
4. If pasteboard contains plain text:
   - Paste into active Scene Widget as text (normal paste behavior)

**Paste Text Into Scene:**
1. User pastes text into Scene Widget (Cmd+V)
2. Text inserted at cursor position in Scene Widget
3. Updated text saved to `scene.detailedText`
4. Entity detection triggered (debounced)

**Cross-Chapter Paste Details:**
- Scene → Project edge must update `chapterID` field
- Target chapter's scene list updated (query recalculates)
- Source chapter's scene list updated if cut (not if copy)
- Undo must reverse both chapter modifications
- Visual feedback: highlight target chapter during paste operation

### R10: Scene Drag and Drop

**Drag Scene:**
1. Click and hold Scene Selection Grip
2. Drag to new position (within chapter or different chapter)
3. Show drop indicator (line between scenes)
4. Visual feedback:
   - Dragged scene shows translucent preview
   - Source position shows empty space/placeholder
   - Drop location shows insertion line (blue highlight)
   - Invalid drop targets show red indicator or disabled state

**Drop Scene (Within Same Chapter):**
1. Release at drop location within same chapter
2. Calculate new `sortIndex` for dropped scene
3. Update Scene → Project edge `sortIndex` via `EdgeRepository`
4. Recalculate `sortIndex` for scenes between old and new positions
5. Rebuild Chapter Widget's scene list (re-query with new sort order)
6. Maintain focus on dragged scene
7. Scroll to keep dragged scene visible

**Drop Scene (Cross-Chapter):**
1. Release at drop location in different chapter
2. **Update Scene → Project edge:**
   - Change `chapterID` from source chapter ID to target chapter ID
   - Set new `sortIndex` for insertion position in target chapter
3. **Recalculate source chapter:**
   - Adjust `sortIndex` for remaining scenes (close gap)
   - Reload source Chapter Widget
4. **Recalculate target chapter:**
   - Adjust `sortIndex` for scenes at/after insertion point
   - Reload target Chapter Widget
5. Maintain focus on dragged scene in new location
6. Scroll to keep dragged scene visible
7. **Undo preparation:**
   - Record source chapter ID, source position, target chapter ID, target position
   - Store affected `sortIndex` values for rollback

**Validation Rules:**
- Cannot drag scene to invalid positions (e.g., between chapters and scenes)
- Cannot drag scene outside manuscript area
- Cannot drag to collapsed chapters (must expand first)
- Must have valid drop target (between scenes or at end of chapter)

**Visual States:**
- **Valid drop target**: Blue insertion line, chapter highlights
- **Invalid drop target**: Red indicator, cursor shows "forbidden" icon
- **Cross-chapter drag**: Both source and target chapters highlighted
- **During drag**: Source chapter shows gap, target chapter shows preview position

**Edge Cases:**
- Dragging last scene out of chapter → chapter becomes empty (allowed)
- Dragging scene into empty chapter → becomes first scene (sortIndex = 0)
- Dragging between non-adjacent chapters → handled as cross-chapter move
- Rapid consecutive drags → debounce updates, queue operations

**Performance Considerations:**
- Limit `sortIndex` recalculations to affected scenes only
- Batch database updates where possible
- Use optimistic UI updates (show change immediately, persist asynchronously)
- Handle large chapter sizes (100+ scenes) with virtualization if needed

### R13: Chapter Cut, Copy, Paste, Drag and Drop

**Cut Chapter:**
1. Select chapter via Chapter Selection Grip
2. Cmd+X or Right-click → "Cut Chapter"
3. Copy chapter data to pasteboard (chapter ID, all scene IDs, metadata)
4. Mark chapter and all scenes for deletion (pending ER-0053)
5. Remove Chapter Widget from view
6. Recalculate chapter ordering (close gaps in chapter sortIndex)

**Copy Chapter:**
1. Select chapter via Chapter Selection Grip
2. Cmd+C or Right-click → "Copy Chapter"
3. Copy chapter data to pasteboard (chapter Card, all scene Cards, structure)
4. Include all scene text and metadata

**Paste Chapter:**
1. Select target position (between chapters or end of manuscript)
2. Cmd+V or Right-click → "Paste Chapter"
3. If pasteboard contains chapter data:
   - Create new Chapter Card via `CardRepository.createCard(kind: .chapters)`
   - For each scene in chapter:
     - Create new Scene Card
     - Copy scene text and metadata
     - Link to project with new chapter ID
   - Link chapter to project with appropriate sortIndex
   - Create Chapter Widget with all Scene Widgets
   - Rebuild manuscript view
   - Set focus to first scene of pasted chapter
4. Handle chapter ordering:
   - Insert at target position
   - Adjust sortIndex for chapters at/after insertion point
   - Update all affected Chapter → Project edges

**Drag Chapter:**
1. Click and hold Chapter Selection Grip
2. Drag to new position in manuscript
3. Visual feedback:
   - Entire Chapter Widget shows translucent preview
   - Source position shows empty space
   - Drop location shows thick insertion line (8pt, matches grip width)
   - Invalid drop targets disabled

**Drop Chapter:**
1. Release at drop location
2. Calculate new chapter sortIndex
3. Update Chapter → Project edge via `EdgeRepository`
4. Recalculate chapter sortIndex for chapters between old and new positions
5. **Do NOT modify scene edges** (scenes stay with their chapter)
6. Rebuild manuscript view with new chapter order
7. Maintain focus on dragged chapter's last active scene
8. Scroll to keep chapter visible

**Chapter Selection Grip Context Menu:**
- Cut Chapter (Cmd+X)
- Copy Chapter (Cmd+C)
- Paste Chapter (Cmd+V) - only if pasteboard has chapter data
- Delete Chapter (requires ER-0053)
- Duplicate Chapter
- Insert Chapter Above
- Insert Chapter Below
- Rename Chapter
- Chapter Properties

**Special Considerations:**

**When cutting/pasting chapters:**
- All scenes move with chapter (batch operation)
- Scene → Project edges maintain `chapterID` reference to chapter
- Chapter structure preserved (scene order, metadata)
- Undo must restore entire chapter with all scenes

**When dragging chapters:**
- Scenes do not change position relative to chapter
- Only chapter-level sortIndex changes
- More efficient than moving individual scenes

**Validation:**
- Cannot paste chapter inside another chapter (only between chapters)
- Cannot drag chapter to invalid positions
- Empty chapters allowed (chapter with no scenes)

**Edge Cases:**
- Last chapter in manuscript → can still drag/cut
- Single chapter manuscript → cutting leaves empty manuscript
- Pasting chapter with 50+ scenes → batch create efficiently
- Rapid chapter reordering → debounce updates

### R11: Active Scene Tracking

**Purpose:** Always know which scene the writer is editing.

**Mechanism:**
- Only ONE Scene Widget has `isActive = true` at a time
- Active state set when:
  - User clicks in Scene Widget
  - Scene Widget receives keyboard focus
  - Navigation moves to Scene Widget
- Active state cleared when different scene activated

**Consequences of Active State:**
- Update `activeSceneID` in ManuscriptWritingSurfaceView
- Reload Context Gutter for active scene
- Trigger entity detection for active scene
- Highlight active scene in Scene Map instrument
- Update scene indicator chip

### R12: Text Persistence

**Save Strategy:**
- Debounce text changes (500ms after typing stops)
- Save to `scene.detailedText` via `CardRepository.save()`
- Use async saves to avoid blocking UI
- Handle save conflicts (if scene edited on multiple devices)

**Load Strategy:**
- Load `scene.detailedText` when Scene Widget appears
- Handle empty scenes (empty string)
- Decode format (Plain Text, Markdown, Rich Text)

**CloudKit Sync:**
- Card changes sync automatically via SwiftData + CloudKit
- Each scene is independent Card → independent sync
- No manuscript-level sync required

**Design Approach:**

**Widget Hierarchy:**
```
ManuscriptTextEditor (ScrollView)
└── VStack
    ├── ChapterWidget (HStack) — Chapter 1
    │   ├── VStack (Scene Stack)
    │   │   ├── SceneWidget (HStack) — Scene 1-1
    │   │   │   ├── SceneSelectionGrip (leading, 4pt)
    │   │   │   └── SceneTextEditor (NSTextView/UITextView)
    │   │   ├── SceneWidget (HStack) — Scene 1-2
    │   │   │   ├── SceneSelectionGrip (leading, 4pt)
    │   │   │   └── SceneTextEditor
    │   │   └── ...
    │   └── ChapterSelectionGrip (trailing, 8pt)
    ├── ChapterWidget (HStack) — Chapter 2
    │   ├── VStack (Scene Stack)
    │   │   ├── SceneWidget (HStack) — Scene 2-1
    │   │   │   ├── SceneSelectionGrip (leading, 4pt)
    │   │   │   └── SceneTextEditor
    │   │   └── ...
    │   └── ChapterSelectionGrip (trailing, 8pt)
    └── ...
```

**Spatial Layout (Left to Right):**
```
┌────┬──────────────────────────────────────────────┬────┐
│ 4pt│          Scene Text (60pt insets)            │ 8pt│
│Scene│                                              │Chap│
│Grip│                                              │Grip│
└────┴──────────────────────────────────────────────┴────┘
 ↑                                                     ↑
Leading Edge                                   Trailing Edge
(Scene operations)                         (Chapter operations)
```

**Key Design Decisions:**

1. **No Single Text Buffer**: Each Scene Widget maintains its own text state
2. **Direct Card Mapping**: Scene Widget text = Scene Card `detailedText` (1:1)
3. **Seamless Appearance**: No visible scene boundaries, looks continuous
4. **Focus Management**: `@FocusState` determines active scene
5. **Minimal Scrolling**: Only parent ScrollView scrolls, not individual scenes
6. **Dual Selection Grips**:
   - Scene Selection Grip (4pt, leading edge) for scene operations
   - Chapter Selection Grip (8pt, trailing edge) for chapter operations
7. **Spatial Operation Mapping**:
   - Leading edge (left) = scene-level (mirrors "Create Scene" button)
   - Trailing edge (right) = chapter-level (mirrors "Create Chapter" button)
8. **Visual Hierarchy**: Grip width indicates scope (4pt scene < 8pt chapter)

**Components Affected:**
- **ProjectWriter/ManuscriptTextEditor.swift**: Container and Chapter Widget
- **ProjectWriter/SceneWidget.swift**: Scene Widget (NEW)
- **ProjectWriter/SceneTextEditor.swift**: NSTextView wrapper (NEW)
- **ProjectWriter/SceneSelectionGrip.swift**: Scene selection UI element (NEW)
- **ProjectWriter/ChapterSelectionGrip.swift**: Chapter selection UI element (NEW)
- **ProjectWriter/ManuscriptWritingSurfaceView.swift**: Hosts ManuscriptTextEditor
- **Data/CardRepository.swift**: Scene text persistence
- **Data/EdgeRepository.swift**: Chapter/scene edge management for cross-chapter operations

**Implementation Phases:**

**Phase 1: Scene Text Editor** (Core Component)
- Implement `SceneTextEditor` as NSViewRepresentable/UIViewRepresentable
- Text binding with Card `detailedText`
- Arrow key navigation detection
- Focus management
- Plain Text support only (Markdown/Rich Text in later phases)

**Phase 2: Scene Widget**
- Implement `SceneWidget` with Selection Grip
- Active state tracking
- Text save debouncing (500ms)
- Focus coordination

**Phase 3: Chapter Widget**
- Implement `ChapterWidget` with scene query
- Scene ordering by `sortIndex`
- VStack layout

**Phase 4: Container**
- Implement `ManuscriptTextEditor` container
- ScrollView with chapter stack
- Keyboard event routing for cross-widget navigation

**Phase 5: Scene Operations**
- Scene Selection Grip interaction
- Cut/Copy/Paste scenes (within chapter)
- Drag and drop reordering (within chapter)
- Cross-chapter scene operations

**Phase 6: Chapter Operations**
- Chapter Selection Grip interaction
- Cut/Copy/Paste chapters
- Drag and drop chapter reordering
- Chapter duplication

**Phase 7: Format Support**
- Markdown editing mode
- Rich Text editing mode
- Format conversion

**Test Steps:**

**Basic Editing and Navigation:**
1. Create project with 1 chapter, 2 scenes
2. Navigate to Manuscript View
3. Verify both Scene Widgets appear stacked vertically
4. Click in first scene, verify focus
5. Type text in first scene
6. Verify text saves to first scene's Card
7. Press arrow down to last line, press down again
8. Verify focus moves to second scene, cursor at line 1
9. Type text in second scene
10. Press arrow up to first line, press up again
11. Verify focus moves to first scene, cursor at last line

**Scene Selection and Operations:**
12. Click Scene Selection Grip (4pt) for first scene
13. Verify entire scene text selected
14. Right-click Scene Selection Grip
15. Verify context menu appears
16. Create third scene
17. Verify third Scene Widget appears at bottom

**Scene Drag and Drop (Within Chapter):**
18. Drag first scene to third position (within same chapter)
19. Verify scene reordered correctly
20. Verify `sortIndex` updated in database

**Cross-Chapter Scene Operations:**
21. Create second chapter with one scene
22. Verify Chapter Widget appears below first chapter
23. Drag scene from chapter 1 to chapter 2
24. Verify scene moves to chapter 2
25. Verify scene's `chapterID` updated to chapter 2
26. Verify `sortIndex` recalculated in both chapters
27. Cut scene from chapter 2
28. Paste scene into chapter 1
29. Verify scene appears in chapter 1 with correct positioning
30. Verify `chapterID` updated back to chapter 1

**Chapter Selection and Operations:**
31. Click Chapter Selection Grip (8pt) for chapter 1
32. Verify entire chapter selected (visual feedback)
33. Right-click Chapter Selection Grip
34. Verify chapter context menu appears
35. Copy chapter 1
36. Paste chapter at end of manuscript
37. Verify new chapter created with all scenes duplicated
38. Verify scene text copied correctly
39. Drag chapter 2 to first position
40. Verify chapter order updated
41. Verify all scenes remain with their chapters

**Performance and Edge Cases:**
42. Create chapter with 20 scenes
43. Verify scrolling performance acceptable
44. Verify text editing remains responsive
45. Cut entire chapter
46. Verify chapter and all scenes removed from view
47. Undo cut operation
48. Verify chapter and all scenes restored
49. Drag scene between non-adjacent chapters
50. Verify cross-chapter operation completes correctly

**Acceptance Criteria:**
- ✅ All Scene Widgets visible and properly sized
- ✅ All Chapter Widgets visible with proper hierarchy
- ✅ No layout recursion errors
- ✅ No "modifying state during view update" warnings
- ✅ Text edits save to correct Scene Card
- ✅ Cross-widget navigation with arrow keys works
- ✅ Active scene tracking accurate
- ✅ Context Gutter updates when active scene changes
- ✅ Scene Selection Grip (4pt) allows scene selection
- ✅ Chapter Selection Grip (8pt) allows chapter selection
- ✅ Scene drag and drop functional (within chapter)
- ✅ Scene drag and drop functional (cross-chapter)
- ✅ Scene cut/copy/paste works correctly
- ✅ Cross-chapter scene operations update `chapterID` correctly
- ✅ Chapter drag and drop functional
- ✅ Chapter cut/copy/paste works correctly
- ✅ `sortIndex` recalculation correct for all operations
- ✅ Performance good with 10+ chapters, 50+ scenes per chapter
- ✅ Undo/redo works for all operations
- ✅ Visual feedback clear during drag operations

**Notes:**
- This architecture completely resolves text-to-Card mapping ambiguity
- Each Scene Widget is self-contained and independently focusable
- Scrolling managed at top level for smooth continuous feel
- Scene boundaries invisible except via Scene Selection Grip (4pt, leading edge)
- Chapter boundaries visible via Chapter Selection Grip (8pt, trailing edge)
- **Spatial operation mapping**:
  - Leading edge (left): Scene operations (4pt grip) → mirrors "Create Scene" button
  - Trailing edge (right): Chapter operations (8pt grip) → mirrors "Create Chapter" button
  - Intuitive left-to-right hierarchy: scene (fine-grained) to chapter (coarse-grained)
- Visual hierarchy: Grip width indicates scope (4pt scene < 8pt chapter)
- Entity detection runs per-scene (scoped to active Scene Widget)
- Undo/redo scoped appropriately:
  - Text edits: per Scene Widget
  - Scene operations: per scene with edge updates
  - Chapter operations: entire chapter with all scenes
  - Cross-chapter operations: both source and target chapters
- Cross-chapter operations require special handling:
  - Update `chapterID` on Scene → Project edge
  - Recalculate `sortIndex` in both source and target chapters
  - Maintain scene order within chapter during chapter moves
- This is a novel approach not commonly seen in writing apps
- Two-tier selection system (scene and chapter grips) provides intuitive hierarchy
- Grips on opposite edges (not adjacent) prevents accidental clicks on wrong scope
- Batch operations (chapter cut/paste) more efficient than individual scene operations

---

*Last Updated: 2026-04-26*
