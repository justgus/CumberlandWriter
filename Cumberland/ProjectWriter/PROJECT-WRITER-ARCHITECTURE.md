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

### ManuscriptWritingSurfaceView (Implemented - Needs Data Layer)
- Continuous text editor with scene awareness
- **Needs**: Connection to Scene → Project edges for manuscript ordering
- **Needs**: Chapter tab strip to switch between chapters
- **Needs**: Scene map showing scenes in manuscript order
- Located at: `Cumberland/ProjectWriter/ManuscriptWritingSurfaceView.swift`

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

### Phase 3: Manuscript Assembly
1. Move `ManuscriptAssembler.swift` to `ProjectWriter/` folder
2. Extend `ManuscriptAssembler` to:
   - Assemble manuscript text from scenes in order
   - Insert chapter headings
   - Apply scene separators
   - Maintain citation functionality
3. Connect to `ManuscriptWritingSurfaceView` TextEditor

### Phase 4: Dashboard Integration
1. Populate `ProjectDashboardModel` from actual project data
2. Implement issue detection:
   - Orphaned scenes (not in any chapter)
   - Orphaned chapters (not in any project)
   - Continuity gaps (timeline vs. manuscript mismatches)
3. Connect dashboard data to UI

### Phase 5: Timeline Integration
1. Add button to jump from manuscript scene to timeline position
2. Add button to jump from timeline scene to manuscript position
3. Highlight scenes in timeline that are out-of-manuscript-order

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

## Files to Create/Modify

### New Files
- ✅ `ProjectWriter/ProjectDetailView.swift` (Created)
- ✅ `ProjectWriter/ManuscriptWritingSurfaceView.swift` (Created)
- ✅ `ProjectWriter/ProjectDashboardView.swift` (Created)
- ✅ `ProjectWriter/PROJECT-WRITER-ARCHITECTURE.md` (This file)
- [ ] `ProjectWriter/SceneOrderingSheet.swift` (Similar to `ReorderScenesSheet` in TimelineChartView)
- [ ] `ProjectWriter/ChapterSceneAssociationManager.swift` (Helper for managing associations)

### Files to Move
- [ ] Move `ManuscriptAssembler.swift` from `Cumberland/` to `Cumberland/ProjectWriter/`

### Files to Modify
- ✅ `MainAppView.swift` (Modified - routes project cards to ProjectDetailView)
- [ ] `Model/RelationType.swift` or initialization code (Add new relationship types)
- [ ] `Model/Card.swift` (Add helper methods for scene/chapter queries)
- [ ] `ProjectWriter/ManuscriptAssembler.swift` (Extend with manuscript assembly logic)
- [ ] `ProjectWriter/ManuscriptWritingSurfaceView.swift` (Connect to data layer)
- [ ] `ProjectWriter/ProjectDashboardView.swift` (Connect to data layer)

## Summary

This design preserves the powerful timeline system for tracking story chronology while adding a separate manuscript ordering system that respects the reading order. Scenes can be reused across projects, and the relationship between chronology (timeline) and reading order (manuscript) is explicit and independent.
