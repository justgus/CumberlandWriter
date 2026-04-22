# Project Writer Architecture Design

## Overview

This document describes the architectural design for Cumberland's Project Writer system, which transforms the application from a card/relationship editor into a full-fledged writing tool where worldbuilding can be performed alongside manuscript writing.

## Key Design Principles

### 1. Scene Reusability
Scenes can be reused across multiple projects (e.g., for flashbacks, alternate timelines, or shared universes). This means:
- Scene → Project relationships are **many-to-many**
- Scene → Chapter relationships are **many-to-many**
- A scene can exist independently without belonging to any chapter or project
- A scene's temporal position on a timeline is separate from its manuscript ordering

### 2. Flexible Hierarchy
The system supports flexible content organization:
- **Projects** can contain **Chapters** and **Scenes** directly
- **Chapters** can exist without scenes (for outlining)
- **Scenes** can exist without chapters (orphaned/unorganized scenes)
- **Scenes** can belong to multiple chapters across different projects

### 3. Two Ordering Systems

#### A. Timeline Order (Temporal/Ordinal)
- Managed by the existing Timeline system
- Uses `CardEdge.temporalPosition` for date-based positioning
- Uses `CardEdge.sortIndex` for ordinal positioning
- Represents **when events occur in the story world**
- Scenes can be out-of-manuscript-order on timeline (e.g., flashbacks)

#### B. Manuscript Order (Sequential)
- Managed by the new Project Writer system
- Represents **the order scenes appear in the final manuscript**
- Uses new `CardEdge` relationships with `sortIndex` for ordering
- Independent of timeline order

## Data Model Design

### Existing Models (No Changes)
- **Card** - Scenes, Chapters, Projects remain as Card entities with `.scenes`, `.chapters`, `.projects` kinds
- **CardEdge** - Already supports ordering via `sortIndex` and temporal positioning via `temporalPosition`
- **Timeline system** - Continues to manage temporal/ordinal scene ordering for story chronology

### New Relationships

#### 1. Scene → Project (Many-to-Many)
**Purpose**: Track which scenes are associated with a project

**Relationship Type**: `"belongs-to/contains-scene"`
- Forward: Scene belongs-to Project
- Inverse: Project contains-scene Scene

**Edge Properties**:
- `sortIndex`: Manuscript order position within the project (for scenes not in chapters)
- `chapterID`: Optional UUID indicating which chapter this scene belongs to in this project context
- `temporalPosition`: NOT used (timeline handles this)

**Implementation**: Create new `RelationType` with code `"belongs-to/contains-scene"`

#### 2. Chapter → Project (Many-to-Many)
**Purpose**: Track which chapters are associated with a project

**Relationship Type**: `"part-of/has-chapter"`
- Forward: Chapter part-of Project
- Inverse: Project has-chapter Chapter

**Edge Properties**:
- `sortIndex`: Chapter order within the project (1, 2, 3...)

**Implementation**: Create new `RelationType` with code `"part-of/has-chapter"`

#### 3. Scene → Chapter (Many-to-Many, Project-Scoped)
**Purpose**: Track scene membership in chapters, allowing same scene in multiple chapters

**Important**: This relationship is **project-scoped** via the Scene → Project edge's `chapterID` field.

**Implementation**: Use the existing `"part-of/has-scene"` relationship type, but the authoritative source for project-specific scene-chapter associations is the `chapterID` field on the Scene → Project edge.

### Implicit Project Timeline

Each project has an **implicit timeline** for manuscript assembly:
- When a project is created, we can optionally create a companion Timeline card
- However, the **manuscript order** is derived from Scene → Project edge `sortIndex` values
- The manuscript order is independent of timeline temporal positions
- Scenes appear in the manuscript in `sortIndex` order, grouped by chapter

### Manuscript Assembly Algorithm

```
For Project P:
1. Fetch all Chapter → Project edges, sorted by sortIndex
2. For each Chapter C in order:
   a. Fetch all Scene → Project edges where chapterID == C.id, sorted by sortIndex
   b. Append scene content to manuscript with chapter heading
3. Fetch all Scene → Project edges where chapterID == nil, sorted by sortIndex
4. Append orphan scene content to manuscript (optional section)
```

## Scene Ordering: Timeline vs. Manuscript

### Timeline Order (Existing System)
- **Purpose**: Show **when** events occur in the story world
- **Managed By**: `TimelineChartView`, `SceneTemporalPositionEditor`
- **Storage**: `CardEdge.temporalPosition` (Date) or `CardEdge.sortIndex` (ordinal) on Scene → Timeline edges
- **Use Case**: "Chapter 5, Scene 2 happens **before** Chapter 3, Scene 1 in the story chronology"

### Manuscript Order (New System)
- **Purpose**: Show **in what order** scenes appear to the reader
- **Managed By**: `ManuscriptWritingSurfaceView`, new scene ordering UI
- **Storage**: `CardEdge.sortIndex` on Scene → Project edges
- **Use Case**: "The flashback appears in Chapter 5 but depicts events from before Chapter 1"

### Example: Flashback Scene

**Scenario**: A flashback scene appears in Chapter 5 but depicts events from the story's beginning.

**Timeline Representation**:
- Scene "Origin Story" has `temporalPosition = Jan 1, 2023` (or `sortIndex = 1`)
- Scene appears on timeline at the very beginning

**Manuscript Representation**:
- Scene "Origin Story" has Scene → Project edge with:
  - `chapterID = Chapter5.id`
  - `sortIndex = 2` (second scene in Chapter 5)
- Scene appears in manuscript within Chapter 5

## Integration with Existing Systems

### Timeline System
- **No Changes Required**: Timeline system continues to manage temporal/ordinal scene ordering
- **Independent**: Timeline order and manuscript order are completely independent
- **Use Case**: Writers can use timelines to track story chronology while manuscript shows reading order

### ManuscriptAssembler
- **Current Location**: `Cumberland/ManuscriptAssembler.swift`
- **Current Purpose**: Assembles footnotes and bibliography from citations
- **New Purpose**: Should be moved to `Cumberland/ProjectWriter/` and extended to:
  1. Assemble manuscript text from scenes in manuscript order
  2. Maintain existing citation/bibliography functionality
  3. Handle chapter divisions and scene breaks
  4. Apply formatting and scene separators

### StoryStructure System
- **Integration**: Scenes can be assigned to structure beats (existing functionality)
- **Dashboard Display**: Show which beats have materialized scenes
- **Use Case**: Track progress through story structure as manuscript is written

## View Architecture

### ProjectDetailView (Implemented)
- Root view with tab control
- Switches between Manuscript and Dashboard
- Located at: `Cumberland/ProjectWriter/ProjectDetailView.swift`

### ManuscriptWritingSurfaceView (Implemented - Phase 3 in Progress)
Manuscript-first continuous writing surface with scene awareness.

**Key UI Components**:

1. **Chapter Tab Strip** (Top)
   - Horizontal scrollable tabs for each chapter
   - Active chapter highlighted
   - "Add Chapter" button on right
   - Clicking new chapter prompts for new scene creation

2. **Current Scene Chip** (Floating, upper left of manuscript canvas)
   - Shows active scene name and number
   - Subtle indicator, doesn't interrupt writing

3. **Manuscript Canvas** (Center, main area)
   - Continuous text editor (TextEditor)
   - Scene-aware underneath (tracks which scene is being edited)
   - Readable line width (max 800pt)
   - No visible scene boundaries while writing

4. **Context Gutter** (Right side, 80pt width)
   - **Top priority**: Location card (potential or confirmed)
   - **Below**: Potential cards (characters, artifacts detected in text)
   - **Below**: Confirmed cards (explicitly linked to scene)
   - Circle-based display with colored borders by kind
   - Click to confirm/dismiss potential cards
   - Click confirmed cards to view/edit

5. **Scene Map Instrument** (Bottom)
   - Horizontal strip of scene markers
   - Active scene highlighted
   - Click to jump between scenes
   - "Add Scene" button on left

6. **Quick Action Tray** (Bottom)
   - Scenes, Structure, Context, Notes, Focus buttons
   - Quick access to common writing tools

Located at: `Cumberland/ProjectWriter/ManuscriptWritingSurfaceView.swift`

### ProjectDashboardView (Implemented - Needs Data Layer)
- Project status instrument panel
- **Needs**: Connection to project data (scenes, chapters, structure)
- **Needs**: Issue detection (orphaned scenes, continuity gaps)
- Located at: `Cumberland/ProjectWriter/ProjectDashboardView.swift`

## Implementation Phases

### Phase 1: Data Model (Current Phase)
1. Create `RelationType` for `"belongs-to/contains-scene"` (Scene → Project)
2. Create `RelationType` for `"part-of/has-chapter"` (Chapter → Project)
3. Create helper methods on `Card` for:
   - `scenesInProject(projectID:) -> [Card]` (ordered by sortIndex)
   - `chaptersInProject(projectID:) -> [Card]` (ordered by sortIndex)
   - `scenesInChapter(chapterID:, projectID:) -> [Card]` (ordered by sortIndex)
4. Test data model with sample data

### Phase 2: Scene/Chapter Creation & Association
1. Update scene creation in `ManuscriptWritingSurfaceView` to create Scene → Project edges
2. Update chapter creation to create Chapter → Project edges
3. Implement scene drag-and-drop to assign to chapters
4. Implement scene ordering UI (similar to timeline reordering)
5. Implement orphaned scene detection

### Phase 3: Manuscript Assembly & Potential Cards ✅ COMPLETED

**Status**: Implemented and building successfully

1. **ManuscriptAssembler** ✅
   - Location: `Cumberland/ProjectWriter/ManuscriptAssembler.swift`
   - Assemble manuscript text from scenes in order ✅
   - Insert chapter headings ✅
   - Apply scene separators (configurable via `AssemblyOptions`) ✅
   - Maintain citation functionality ✅
   - Returns `ManuscriptResult` with scene info, word counts, and metadata ✅

2. **Manuscript Writing Surface** ✅
   - Connected to ManuscriptAssembler for content assembly ✅
   - Continuous text editor with scene awareness ✅
   - Chapter tab strip with active chapter tracking ✅
   - Scene map instrument for navigation ✅
   - Quick action tray (Scenes, Structure, Context, Notes, Focus) ✅
   - Empty state with "Add Chapter" and "Add Scene" buttons ✅

3. **Potential Card System** ✅
   - Created `PotentialCard` model (`ProjectWriter/PotentialCard.swift`) ✅
   - Created `SceneContext` observable class for state management ✅
   - Created `EntityDetectionService` for background text parsing ✅
   - Detection strategies implemented:
     - Exact match (existing card names) ✅
     - Fuzzy match (Levenshtein distance) ✅
     - Named Entity Recognition (capitalized phrases) ✅
     - Context keywords (pattern-based detection) ✅
   - Context Gutter displays potential and confirmed cards ✅
   - Visual differentiation: potential (greyed, 40% opacity) vs confirmed (full color) ✅
   - Confirm/dismiss actions via sheet menu ✅
   - Icon fallback for empty/generic names ("it", "that") ✅

4. **Scene/Chapter Creation** ✅
   - Chapter creation prompts for new scene (via confirmation dialog) ✅
   - Scene creation uses CardRepository.createCard() ✅
   - Edges created via EdgeRepository methods ✅
   - All modelContext operations through repositories (architectural compliance) ✅

### Phase 4: Dashboard Integration ✅ COMPLETED

**Status**: Implemented and building successfully
**Source of Truth**: `cumberland_project_dashboard_design_spec.md`

#### Implementation Summary
All dashboard components have been implemented with full data integration:

**Data Layer** (`Cumberland/Data/`):
- ✅ `ProjectDashboardModels.swift` - All dashboard data structures
- ✅ `ProjectDashboardService.swift` - Data aggregation and issue detection
- ✅ Full integration with CardRepository and EdgeRepository

**UI Layer** (`Cumberland/ProjectWriter/ProjectDashboardView.swift`):
- ✅ Status Glyph (three concentric rings) with data-driven rendering
- ✅ Structure Band with beat visualization
- ✅ Return Strip (Last/Resume/Next navigation nodes)
- ✅ Cast Shelf with character portraits
- ✅ Issues Shelf with orphan detection
- ✅ Thread Shelf (placeholder for future implementation)
- ✅ Empty state handling for all components

#### Data Repository Integration
All dashboard data sourced from `Cumberland/Data/` repositories:
- **CardRepository**: Fetch scenes, chapters, characters, locations, artifacts
- **EdgeRepository**: Fetch relationships, manuscript order (sortIndex)
- **ProjectDashboardService**: Aggregates and transforms data into dashboard models

#### Dashboard Data Models (Following Design Spec Section 6)

1. **ProjectDashboardModel** (Root)
   - project: Card (kind = .projects)
   - currentContext: CurrentContext
   - structureBand: StructureBandModel
   - statusGlyph: StatusGlyphModel
   - returnStrip: ReturnStripModel
   - castShelf: CastShelfModel
   - issuesShelf: IssuesShelfModel
   - threadShelf: ThreadShelfModel

2. **CurrentContext**
   - activeChapterID: UUID?
   - activeSceneID: UUID?
   - activeEventID: UUID?
   - sceneContents: [Card] (characters, artifacts, vehicles in active scene)
   - orphanCounts: [OrphanCount]

3. **StructureBandModel**
   - Query: StoryStructure elements via CardRepository
   - beats: [StructureBeat] (structure elements assigned to project)
   - contourSegments: [ContourSegment] (derived from scene density)
   - activePosition: Double (normalized 0-1)
   - continuityBreaks: [Range<Double>]

4. **StatusGlyphModel** (Three Concentric Rings)
   - timelineRing: TimelineRing (outer - story/event order)
   - chapterRing: ChapterRing (middle - chapter formation)
   - sceneRing: SceneRing (inner - scene realization)
   - activeLocus: ActiveLocus

5. **ReturnStripModel** (Last / Resume / Next)
   - lastNode: ReturnNode (previous working scene)
   - resumeNode: ReturnNode (current recommended target)
   - nextNode: ReturnNode (next structural opening)

6. **CastShelfModel**
   - Query: Characters via `CardRepository.fetch(byKind: .characters)`
   - Filter: Characters linked to project scenes
   - characters: [Card]

7. **IssuesShelfModel**
   - Detect via CardRepository queries:
     - Orphaned scenes: `CardRepository.fetchOrphanedScenesInProject()`
     - Orphaned chapters: Chapters without "part-of/has-chapter" edge
     - Continuity gaps: Timeline vs. manuscript order mismatches
   - issues: [ProjectIssue]

8. **ThreadShelfModel**
   - threads: [NarrativeThread] (future: custom thread cards)

#### Implemented Components ✅

1. **Dashboard Data Service** (`Data/ProjectDashboardService.swift`) ✅
   - `@MainActor class ProjectDashboardService`
   - `init(modelContext: ModelContext)` - creates CardRepository and EdgeRepository instances
   - Location: `Cumberland/Data/ProjectDashboardService.swift`
   - `func buildDashboardModel(for project: Card) -> ProjectDashboardModel`
   - Methods:
     - `buildCurrentContext()` - active scene tracking and orphan counts
     - `buildStructureBand()` - structure beat visualization (placeholder)
     - `buildStatusGlyph()` - three concentric rings with chapter/scene spans
     - `buildReturnStrip()` - Last/Resume/Next navigation nodes
     - `buildCastShelf()` - character aggregation from project scenes
     - `buildIssuesShelf()` - orphan detection and issue reporting
     - `buildThreadShelf()` - narrative threads (placeholder)

2. **Issue Detection** ✅
   - `detectOrphanCounts()` - finds orphaned scenes and chapters
   - Orphaned scenes: Scenes linked to project but not assigned to any chapter
   - Orphaned chapters: Chapters not linked to project via "part-of/has-chapter" edge
   - Returns `[OrphanCount]` with issue type and count

3. **Ring Span Calculation** ✅
   - `buildChapterRing()` - calculates chapter spans with angular distribution
     - 90% of circle (leaves gap at top for Begin/End markers)
     - Start angle: π * 0.55 (~100°)
     - State classification: `.formed` (2+ scenes), `.thinDefined` (0-1 scenes)
   - `buildSceneRing()` - calculates scene spans with content state
     - Same angular distribution as chapter ring
     - State classification: `.formed` (100+ words), `.thinDefined` (< 100 words)
     - Orphan detection: `isOrphanSpill` flag for scenes without valid chapter
   - `buildTimelineRing()` - timeline events (placeholder, no events yet)

4. **Structure Band** ✅
   - `buildStructureBand()` - returns placeholder (empty beats, no contour segments)
   - Future: Will query StoryStructure elements and calculate content density
   - Empty state: Shows "No structure defined" message

5. **Cast Shelf** ✅
   - `buildCastShelf()` - aggregates characters from project scenes
   - Queries all scenes in project via CardRepository
   - Finds characters linked to those scenes via EdgeRepository
   - Returns `[CastCharacter]` with ID, display label, and thumbnail data

6. **Return Strip** ✅
   - `buildReturnStrip()` - finds resume target (first scene or placeholder)
   - Empty state: "No scenes yet" / "Create your first scene to begin"
   - Normal state: Resume node with scene title, subtitle, and excerpt

7. **UI Components in ProjectDashboardView** ✅
   - Structure Band (horizontal contour with beat nodes and segments)
   - Status Glyph (three concentric rings):
     - Outer: Timeline events (empty for now)
     - Middle: Chapter spans with state colors
     - Inner: Scene spans with state colors and orphan highlighting
     - Center: Completion percentage or "Empty" state
   - Return Strip (Last / Resume / Next nodes with conditional layout)
   - Cast Shelf (character grid with portraits, max 8 shown)
   - Issues Shelf (issue rows with icons and severity colors)
   - Thread Shelf (thread tags with weight-based borders)
   - All components have empty state handling

### Phase 5: Story Structure Integration (In Design)

**Status**: Design phase
**Design Document**: `Cumberland/Documentation/STORY-STRUCTURE-INTEGRATION-DESIGN.md`

Key design questions being addressed:
1. How should writers select a story structure for their project?
2. Where should structure selection UI appear? (Dashboard, Writing Surface, both?)
3. How should we preserve scene assignments when switching structures?
4. Should we use proportional mapping or semantic mappings between structures?

Current StoryStructure implementation:
- ✅ StoryStructure model with `projectID` field (1:1 with projects)
- ✅ StructureElement model with many-to-many scene assignments
- ✅ Structure Board for Kanban-style scene organization
- ✅ Predefined templates (Three-Act, Hero's Journey, Save the Cat, etc.)
- ❌ No UI to select structure during project creation
- ❌ No UI to change project structure from Project Writer
- ❌ No structure preservation when switching

Proposed solutions in design document:
- Structure selector in Project Dashboard (Structure Band header)
- Structure indicator in Manuscript Writing Surface
- Proportional position mapping algorithm for structure switching
- Clear warnings before structure changes
- Manual reassignment available via Structure Board

### Phase 6: Timeline Integration (Future)
1. Add button to jump from manuscript scene to timeline position
2. Add button to jump from timeline scene to manuscript position
3. Highlight scenes in timeline that are out-of-manuscript-order

## Potential Card System

### Overview
The Potential Card system enables real-time entity detection while writing, suggesting cards that may be referenced in the scene text without interrupting the writer's flow.

### Key Principles
1. **Non-Interrupting**: All updates happen in background, no modal dialogs or alerts
2. **Context-Aware**: Tracks potential cards per scene
3. **Confirmable**: Writer can promote potential cards to confirmed cards with a click
4. **Dismissible**: Writer can dismiss false positives
5. **Auto-Created**: New scenes automatically get a Location potential card

### Data Model

#### PotentialCard Struct
```swift
struct PotentialCard: Identifiable, Hashable {
    let id: UUID
    let kind: Kinds  // .characters, .artifacts, .locations, etc.
    let name: String
    let confidence: Float  // 0.0 to 1.0
    let textRange: Range<String.Index>?  // Where detected in scene text
    let sceneID: UUID  // Which scene this belongs to
    var dismissed: Bool = false  // User dismissed this suggestion

    // Associated confirmed card (if confirmed)
    var confirmedCardID: UUID?
}
```

#### SceneContext (State Management)
```swift
@Observable
class SceneContext {
    var activeSceneID: UUID?
    var potentialCards: [PotentialCard] = []
    var confirmedCards: [Card] = []

    func addPotentialCard(_ card: PotentialCard)
    func confirmPotential(_ potential: PotentialCard, asCard card: Card)
    func dismissPotential(_ potential: PotentialCard)
    func clearForNewScene()
}
```

### Text Parsing Service

**Purpose**: Background service that parses scene text and detects entity mentions.

#### EntityDetectionService
```swift
@MainActor
class EntityDetectionService {
    private let modelContext: ModelContext

    // Parse text and return detected entities
    func detectEntities(in text: String, sceneID: UUID) async -> [PotentialCard] {
        // 1. Tokenize text (split into words/phrases)
        // 2. Match against existing card names (fuzzy matching)
        // 3. Detect capitalized noun phrases (potential new entities)
        // 4. Classify by pattern (character names, artifact references, etc.)
        // 5. Return sorted by confidence
    }

    // Check if text likely references a character
    private func isLikelyCharacterName(_ text: String) -> Bool

    // Check if text likely references an artifact
    private func isLikelyArtifactName(_ text: String) -> Bool

    // Check if text likely references a location
    private func isLikelyLocationName(_ text: String) -> Bool
}
```

#### Detection Strategies
1. **Exact Match**: Text matches existing card name exactly (high confidence)
2. **Fuzzy Match**: Text similar to existing card name (medium confidence)
3. **Capitalization Pattern**: Capitalized words in text (character names, proper nouns)
4. **Context Keywords**: Phrases like "took the [artifact]", "arrived at [location]"
5. **Previously Mentioned**: Entity mentioned earlier in same scene (higher confidence)

### Context Gutter Display

**Visual Hierarchy** (Top to Bottom):
1. **Location Card** (Always shown first)
   - Potential: Semi-transparent with dashed border
   - Confirmed: Solid border
2. **Potential Cards** (Detected entities)
   - Sorted by confidence (highest first)
   - Semi-transparent circles with dashed border
   - Click to confirm or dismiss
3. **Confirmed Cards** (Explicitly linked)
   - Solid circles with kind-colored border
   - Click to view/edit card detail

**Interaction Patterns**:
- **Click potential card**: Show menu with options:
  - "Confirm as [Existing Card Name]" (if fuzzy match found)
  - "Create New [Kind]"
  - "Dismiss"
- **Click confirmed card**: Open card detail sheet
- **Drag from gutter**: Future feature - drag card into text to insert reference

### Scene Creation Workflow

#### Creating New Scene
```swift
func createNewScene() {
    // 1. Create scene card
    let newScene = Card(kind: .scenes, name: "New Scene", ...)

    // 2. Link to active chapter and project
    createEdge(from: newScene, to: activeChapter, type: "part-of/has-scene")
    createEdge(from: newScene, to: project, type: "belongs-to/contains-scene")

    // 3. Clear scene context
    sceneContext.clearForNewScene()

    // 4. Auto-create Location potential card
    let locationPotential = PotentialCard(
        kind: .locations,
        name: "Scene Location",
        confidence: 1.0,
        sceneID: newScene.id
    )
    sceneContext.addPotentialCard(locationPotential)

    // 5. Set as active scene
    activeSceneID = newScene.id
}
```

#### Creating New Chapter
```swift
func createNewChapter() {
    // 1. Create chapter card
    let newChapter = Card(kind: .chapters, name: "New Chapter", ...)

    // 2. Link to project
    createEdge(from: newChapter, to: project, type: "part-of/has-chapter")

    // 3. Set as active chapter
    activeChapterID = newChapter.id

    // 4. PROMPT: Ask if new scene should be created
    // Show alert: "Create first scene for this chapter?"
    // If yes -> call createNewScene()
}
```

### Real-Time Updates

**Text Change Handling**:
```swift
// In ManuscriptWritingSurfaceView
@State private var manuscriptText: String = "" {
    didSet {
        // Debounce text parsing (wait 500ms after typing stops)
        textParseTask?.cancel()
        textParseTask = Task {
            try await Task.sleep(for: .milliseconds(500))
            await updatePotentialCards()
        }
    }
}

private func updatePotentialCards() async {
    guard let activeSceneID else { return }

    // Parse text in background
    let detected = await entityDetectionService.detectEntities(
        in: manuscriptText,
        sceneID: activeSceneID
    )

    // Update scene context (non-interrupting)
    await MainActor.run {
        sceneContext.potentialCards = detected.filter { !$0.dismissed }
    }
}
```

### Integration Points

1. **ManuscriptWritingSurfaceView**:
   - Add `@State private var sceneContext = SceneContext()`
   - Add `@StateObject private var entityDetectionService: EntityDetectionService`
   - Update Context Gutter to read from `sceneContext`
   - Add text change handler for real-time parsing

2. **Context Gutter**:
   - Display location card (potential or confirmed) at top
   - Display potential cards with confirm/dismiss actions
   - Display confirmed cards with tap-to-view action

3. **Scene/Chapter Creation**:
   - Update `createNewScene()` to clear context and add Location potential
   - Update `createNewChapter()` to prompt for new scene creation

## Migration Strategy

### For Existing Data
- **Existing Scenes**: Continue to work with timeline system
- **New Scene → Project associations**: Created on-demand when scenes are added to projects
- **No breaking changes**: All existing functionality remains intact

### For New Projects
- When a new project is created, writer can optionally:
  1. Create an implicit timeline for chronology tracking
  2. Start with chapter/scene structure directly
  3. Mix both approaches

## Benefits of This Design

1. **Flexibility**: Scenes can be reused across projects
2. **Independence**: Timeline order and manuscript order are separate concerns
3. **Non-Breaking**: Existing timeline and scene systems continue to work
4. **Intuitive**: Writers can think about chronology (timeline) and reading order (manuscript) separately
5. **Powerful**: Supports complex narrative structures (flashbacks, parallel timelines, etc.)

## Open Questions

1. **Scene Text Storage**: Should scene text be stored in `Card.detailedText` or in a separate manuscript-specific field?
   - **Recommendation**: Use `Card.detailedText` for now, consider separate field if formatting needs diverge

2. **Chapter Text**: Should chapters have their own text content (e.g., chapter intro text)?
   - **Recommendation**: Yes, store in `Card.detailedText` for chapter cards

3. **Scene Separators**: What visual separator to use between scenes in continuous manuscript?
   - **Recommendation**: Use standard "* * *" separator, make configurable per project

4. **Draft States**: Should scenes track draft states (first draft, revised, final)?
   - **Recommendation**: Add later as scene metadata, not critical for MVP

## Current Implementation Status (As of 2026-04-22)

### Completed Files ✅

**Core Views**:
- ✅ `ProjectWriter/ProjectDetailView.swift` - Tab switcher between Manuscript and Dashboard
- ✅ `ProjectWriter/ManuscriptWritingSurfaceView.swift` - Full writing surface with all Phase 3 features
- ✅ `ProjectWriter/ProjectDashboardView.swift` - Complete dashboard with all Phase 4 components
- ✅ `ProjectWriter/StructureSelectionSheet.swift` - Story structure selection UI (Phase 5)

**Data Layer**:
- ✅ `Data/ProjectDashboardModels.swift` - All dashboard data structures (extended with arc data)
- ✅ `Data/ProjectDashboardService.swift` - Data aggregation and transformation (extended with arc generation)
- ✅ `Data/StructureMappingService.swift` - Intelligent scene mapping between structures (Phase 5)
- ✅ `Data/CardRepository.swift` - Extended with `createCard()` method
- ✅ `Data/EdgeRepository.swift` - Extended with scene/chapter linking methods

**Manuscript Assembly**:
- ✅ `ProjectWriter/ManuscriptAssembler.swift` - Moved from root, extended with assembly logic

**Potential Cards**:
- ✅ `ProjectWriter/PotentialCard.swift` - Model and SceneContext
- ✅ `ProjectWriter/EntityDetectionService.swift` - Background text parsing

**Story Structure System** (Phase 5 & 7):
- ✅ `Model/NarrativeArc.swift` - Protocol and 13 arc implementations
- ✅ `Model/CustomArc.swift` - User-defined arcs with Catmull-Rom splines
- ✅ `Model/StoryStructure.swift` - Extended with `narrativeArc` and `customArc` properties
- ✅ `ProjectWriter/NarrativeArcVisualization.swift` - Tufte-style arc renderer
- ✅ `ProjectWriter/CustomArcEditorView.swift` - Interactive arc editor with draggable controls
- ✅ `ProjectWriter/CustomStructureCreationSheet.swift` - Multi-step custom structure wizard

**Integration**:
- ✅ `MainAppView.swift` - Routes project cards to ProjectDetailView

**Test Coverage**:
- ✅ `CumberlandTests/Model/NarrativeArcTests.swift` - 17 test cases for all arc functions
- ✅ `CumberlandTests/Data/StructureMappingTests.swift` - 8 test cases for mapping algorithms
- ✅ `CumberlandTests/Model/CustomArcTests.swift` - 26 test cases for custom arc system

### Architecture Compliance ✅

**Repository Pattern**:
- All modelContext operations go through CardRepository or EdgeRepository
- No direct modelContext.insert() or modelContext.save() in views
- Services in Data layer instantiate repositories directly

**Empty State Handling**:
- ProjectDashboardView: All components show appropriate empty states
- ManuscriptWritingSurfaceView: Welcome screen with "Add Chapter" and "Add Scene" buttons
- Context Gutter: Minimal display when no active scene
- Chapter Tab Strip: Shows only "+ Add Chapter" button when empty
- Scene Map: Shows only "+ Add Scene" button when empty

### Completed Phases

**Phase 1: Data Model & Repository Layer** ✅
- Scene/Chapter/Project relationships via CardEdge
- Repository pattern for all data operations
- Manuscript assembly algorithm

**Phase 2: Scene and Chapter Creation** ✅
- Scene creation UI and logic
- Chapter creation and management
- Card repository integration

**Phase 3: Manuscript Writing Surface** ✅
- Continuous vertical text editor
- Scene-aware editing with context detection
- Right context gutter with potential cards
- Chapter tabs and scene map instruments
- Quick action tray

**Phase 4: Project Dashboard** ✅
- Structure Band with arc visualization
- Status Glyph (three concentric rings)
- Return Strip (Last/Resume/Next)
- Cast Shelf, Issues Shelf, Thread Shelf
- Dense, instrument-style information display

**Phase 5: Story Structure Integration** ✅ COMPLETED (2026-04-21)
- ✅ Narrative arc functions for all 13 predefined structures
- ✅ Tufte-style arc visualization in Dashboard
- ✅ Arc-based scene mapping algorithm (70% tension + 30% slope)
- ✅ Structure selection UI (accessible from Dashboard and Writing Surface)
- ✅ Intelligent structure switching with scene preservation
- ✅ Comprehensive test coverage (25 test cases)
- See: `NARRATIVE-ARC-FUNCTIONS.md` and `STORY-STRUCTURE-INTEGRATION-DESIGN.md`

**Phase 7: Custom Story Structures** ✅ COMPLETED (2026-04-22)
- ✅ CustomArc model with Catmull-Rom spline interpolation
- ✅ Visual arc editor with draggable control points
- ✅ Multi-step custom structure creation wizard
  - Name & description input
  - Beat definition (add/edit/remove)
  - Interactive arc design
  - Preview and confirmation
- ✅ StoryStructure extended with `customArcData` persistence
- ✅ Integration with structure selection UI ("Create Custom" button)
- ✅ Control point manipulation with boundary protection
- ✅ Comprehensive test coverage (26 test cases for CustomArc)
- See: `NARRATIVE-ARC-FUNCTIONS.md` Phase 5 section

### Pending Work

**Phase 6: Timeline Integration** (Future):
- Jump from manuscript to timeline and vice versa
- Highlight out-of-order scenes
- Temporal position vs. manuscript position visualization

**Polish & Enhancement**:
- Scene reordering UI (drag-and-drop in Scene Map)
- Chapter reordering UI (drag-and-drop in Chapter Tab Strip)
- Structure Board quick-access from Dashboard
- Narrative threads implementation (currently placeholder)
- Hover states and tooltips for arc visualization

## Summary

This design preserves the powerful timeline system for tracking story chronology while adding a separate manuscript ordering system that respects the reading order. Scenes can be reused across projects, and the relationship between chronology (timeline) and reading order (manuscript) is explicit and independent.
