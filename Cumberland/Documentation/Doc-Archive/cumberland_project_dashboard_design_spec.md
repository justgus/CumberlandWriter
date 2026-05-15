# Cumberland Writer — Project Dashboard Surface Design
Version: Locked working-surface specification  
Status: Approved concept baseline for dashboard mode

## 1. Purpose

The Project Dashboard is the project-scale working surface for Cumberland Writer.

It is not a card editor.  
It is not a manuscript editor.  
It is the writer's project instrument panel.

Its purpose is to let the writer:

- understand the state of the project at a glance
- resume work immediately
- see structural maturity and continuity
- see what is active in the current scene
- see unresolved issues that require attention
- see active narrative threads
- navigate into writing, structure, or corrective workflows quickly

This surface must remain useful at three project stages:

- early project
- mid-project
- late / well-formed project

The same layout grammar should remain stable while the density and meaning of the data change.

---

## 2. Design principles

### 2.1 Omit needless words
The surface should avoid redundant labels, explanatory copy, or repeated counts when meaning is already visible elsewhere.

### 2.2 Dense but readable
The dashboard may be busy if the density is useful. Decorative busyness is unacceptable. Informational density is desirable.

### 2.3 Show state, do not explain state
Whenever possible, project state should be conveyed through:

- geometry
- continuity
- weight
- position
- adjacency
- color
- iconography

### 2.4 Use text where text is the right tool
Text remains correct in places where the writer must act on a specific condition, especially in issue resolution workflows.

### 2.5 Preserve semantic separation
Different UI regions must represent different conceptual layers:

- project structure
- manuscript return flow
- current scene contents
- project cast
- project issues
- narrative threads

No two widgets should say the same thing in slightly different forms.

---

## 3. High-level layout

The dashboard consists of these regions:

### 3.1 Existing application shell
- left project sidebar
- top mode/action bar
- center dashboard canvas
- narrow right contextual strip
- bottom quick-action tray

### 3.2 Main dashboard regions
- project header and structure band (upper center-left)
- project status glyph (upper center-right)
- resume/return strip (lower center-left)
- cast shelf (lower right, upper subsection)
- issues shelf (lower right, middle subsection)
- thread shelf (lower right, lower subsection)

---

## 4. Region-by-region specification

## 4.1 Left sidebar
This remains part of the overall Cumberland shell, not a dashboard-specific invention.

Contains:
- current project selection
- other available projects
- card-type navigation

The dashboard assumes this shell already exists.

No special dashboard semantics beyond preserving access to the rest of the system.

---

## 4.2 Top mode/action bar
Contains:
- current surface title or mode indicator
- segmented control or mode switch between Dashboard and Writing
- Resume action
- Write action

This bar should stay visually stable between dashboard mode and writing mode.

### Interaction
- selecting Dashboard keeps user on project instrument panel
- selecting Writing moves to manuscript-oriented working surface
- Resume jumps to best resumption target
- Write enters manuscript surface at the active target

---

## 4.3 Project header
Purpose:
- identify project
- show basic project scale
- show broad drafting phase
- anchor the structure band

Contains:
- project title
- compact metadata line (example: scene count, chapter count, timeline count)
- small phase/status tokens (example: Planning, Drafting, Revision)
- recent-state token (example: last edited scene)
- outline maturity token

This region should remain concise and should not become a statistics dashboard.

---

## 4.4 Structure band
The structure band is a horizontal project-level contour.

It combines:

- named structure beats
- an action/pressure contour
- signal about where content is thick, thin, or broken
- current active locus

### Meaning
The contour is not a literal manuscript scrollbar.  
It is a structural field.

It answers:
- where the story structure is defined
- where content mass exists
- where structural coverage is thin
- where continuity breaks
- where the writer is currently working

### Visual rules
- line thickness increases where content mass is greater
- thinner spans indicate lightly developed regions
- actual breaks indicate continuity gaps or missing linkage
- beat nodes indicate known structural beats
- beat nodes may be hollow when defined but unwritten
- beat nodes may be solid when materially supported
- local ticks beneath a beat indicate scene density in that beat region
- the current locus is indicated with a focused halo or ring

### Example semantics
- thick span = many or substantial scenes exist in this structural region
- thin span = low substance, placeholder drafting, weak development
- break in line = detected continuity interruption or missing connective region
- solid beat dot = beat materially supported
- hollow beat dot = beat present in plan but not materially realized

### Interaction
- tap beat node: reveal beat detail or linked structural metadata
- double tap / activate beat node: jump to corresponding writing target
- hover: preview linked scenes/events/chapters
- long press / alternate action: open structure inspector or context menu

---

## 4.5 Project status glyph
The glyph is the core project status medallion.

It is not a decorative chart.
It is a compact semantic status instrument.

It consists of three concentric layers:

### 4.5.1 Outer ring — story timeline
This ring represents canonical story/event order only.

Properties:
- continuous ring with a top gap
- Begin and End markers at the gap
- event dots placed around the ring
- movement proceeds counterclockwise
- event/beat dots may be active or inactive
- active event may receive a subtle halo

Meaning:
- the story exists independently of manuscript completion
- this ring is about story-sequence truth, not drafting progress

### 4.5.2 Middle ring — chapter formation
This ring represents chapter-level structural realization.

Properties:
- continuous by default
- chapter span lengths vary proportionally with relative chapter extent
- solid dark arc = chapter materially formed
- grey arc = chapter defined but thin / placeholder-only / lightly realized
- true gap = actual continuity break or missing chapter linkage

Meaning:
- document structure exists here
- chapter maturity can be assessed independently from scene density

### 4.5.3 Inner ring — scene realization
This ring represents current projected scene order and manuscript realization.

Properties:
- continuous by default
- scene span lengths vary proportionally with scene extent or manuscript footprint
- solid dark arc = materially realized scene region
- grey arc = placeholder scenes, lightly realized scenes, scene shells, or low-substance scene spans
- true gap = actual missing projected continuity
- slight outer spill = orphan or weakly attached scene material

Meaning:
- this is the actual drafting layer
- this ring reflects current project projection, not abstract possibility

### 4.5.4 Active locus
The glyph should show one clear active locus.

This consists of:
- one active region on the chapter ring
- one tighter active region on the scene ring
- optional halo on the corresponding event dot

This trio identifies:
- active story region
- active chapter region
- active scene region

### 4.5.5 Semantic ladder
The glyph uses three important states:

- gap = absent, broken, or missing linkage
- grey = defined but thin / placeholder-only
- dark = present and materially formed

This rule should remain stable across dashboard states.

### Interaction
- tap event dot: reveal event detail
- tap chapter arc: reveal chapter data
- tap scene arc: reveal scene region data
- double tap active region: jump into writing surface
- hover: show structured tooltip for the selected ring segment

---

## 4.6 Right contextual strip
Purpose:
- show what is active now
- show mixed scene-local contents
- show orphan/health counts
- keep context close to the writing entry point

Contains:
- current chapter indicator
- current scene indicator
- current event indicator
- scene contents cluster
- orphan / unresolved counts
- compact footer action icons

This strip must remain narrow and not expand into a full inspector.

### 4.6.1 Scene contents cluster
This is not the same as cast.

This cluster shows what is active in the current scene.

Possible members:
- characters
- artifacts
- vehicles
- other scene-local cards if relevant

### Visual grammar
All items may use circles if desired, but card type is indicated by thick colored border.

Recommended mapping:
- character = blue border
- artifact = amber/brown border
- vehicle = green border
- event or other specialized type = distinct accent color if ever shown here

Optional additional signals:
- focus ring for POV or currently emphasized actor
- hover reveal for name/details

### Interaction
- tap item: reveal linked card detail
- double tap: open associated card
- hover: preview thumbnail, name, type, and current linkage

---

## 4.7 Cast shelf
Purpose:
- represent the static or project-level dramatis personae
- remain distinct from scene-local contents

This shelf is a calmer, smaller, more stable field of character portraits or monogram circles.

### Difference from scene contents
Cast shelf:
- project scope
- static or slowly changing
- lower urgency
- reference layer

Scene contents cluster:
- immediate scene scope
- dynamic
- higher urgency
- active drafting context

### Interaction
- tap portrait: open character card
- hover: show name/role/last-used info
- long press / alternate action: reveal relationships or quick actions

---

## 4.8 Return strip
This is the writer's re-entry instrument.

It should answer:
- where was I
- where should I resume
- what is the next structurally meaningful target

### Structure
Three-node directional strip:

- Last
- Resume
- Next

### Hierarchy
The center Resume node is largest and most important.

Last and Next are smaller and quieter.

### Resume node contents
Must prioritize re-entry usefulness.

Recommended content:
- scene title
- compact subtitle
- last few words typed
- micro-icons for non-redundant context tokens

Do not repeat scene inventory counts if those already exist in the right contextual strip.

### Recommended micro-icons
Suitable tokens:
- linked event
- continuity warning
- note attached
- unresolved citation
- POV indicator
- other non-duplicated re-entry context

### Interaction
- tap Last: reopen previous working point
- tap Resume: resume at active writing target
- tap Next: jump to next structural opening
- hover Resume: show extended contextual preview

---

## 4.9 Issues shelf
Purpose:
- show actionable project problems
- act as a resolution surface
- remain readable and directly useful

Unlike decorative status labels, issues are allowed to use plain language.

### Good issue examples
- Orphan scene ×3
- Citation unresolved ×1
- Vehicle unassigned ×1
- Continuity gap ahead

### Visual treatment
- one row per issue
- subtle bullet or marker
- hyperlink-like text behavior
- optional underline on hover
- optional disclosure affordance

### Interaction
Clicking an issue should open a detail pane that allows resolution.

Detail pane may include:
- affected cards
- reason for flag
- suggested corrective actions
- jump-to actions
- direct fix actions where possible

---

## 4.10 Thread shelf
Purpose:
- show active narrative or thematic strands
- distinguish threads from timeline chronology
- distinguish threads from generic tags

Threads are not the same as events or timelines.

### Semantic role
Examples:
- Lantern thread
- Archive mystery
- Mira / Ari
- Crown reveal

These are narrative strands or active lines of concern.

### Visual treatment
The thread shelf should include:
- baseline
- small thread glyph at the left
- light tether/stem from the baseline to each thread tag
- thread-specific tag shape

### Thread tag shape
Thread lozenges must be visually distinct from ordinary lozenges.

Suggested shape features:
- small tail
- notch
- stitched entry point
- elongated asymmetry

The current recommended form:
- rounded lozenge body
- small left tail / notch
- tether from shelf baseline to the tag

This allows the writer to infer that these are connected strands, not generic labels.

### Interaction
- tap thread tag: focus thread
- double tap: reveal all linked scenes/events/cards in that thread
- hover: show thread scope, associated scenes, associated cards, current tension points

---

## 4.11 Quick-action tray
Bottom quick-action strip supports rapid mode/context actions.

Likely actions:
- Outline
- Timeline
- Cast
- Resume
- Write

These should remain icon-first and compact.

---

## 5. Stage behavior

The dashboard must remain structurally stable at all project phases.

## 5.1 Early project
Expected visual profile:
- more grey arcs in glyph
- more breaks in structure band
- more orphan issues
- fewer threads, less dense cast
- Resume may point into lightly formed scene shells

## 5.2 Mid-project
Expected visual profile:
- thicker structure contour in some regions
- one or more continuity warnings
- more active threads
- mixed solid and grey glyph arcs
- Resume points into active drafting regions

## 5.3 Late / well-formed project
Expected visual profile:
- mostly continuous glyph rings
- few or no issues
- stronger, more continuous structure band
- richer cast usage
- thread shelf reflects mature thematic strands
- Resume likely points into revision or ending work

---

## 6. Data model concepts

The dashboard should be driven by semantic state, not hand-authored geometry.

Below is pseudocode intended to be implementation-neutral.

### 6.1 Project dashboard model

```text
type ProjectDashboardModel:
    project_id
    title
    phase
    chapter_count
    scene_count
    timeline_count

    current_context: CurrentContext
    structure_band: StructureBandModel
    status_glyph: StatusGlyphModel
    return_strip: ReturnStripModel
    cast_shelf: CastShelfModel
    issues_shelf: IssuesShelfModel
    thread_shelf: ThreadShelfModel
    quick_actions: list<ActionModel>
```

### 6.2 Current context

```text
type CurrentContext:
    active_chapter_id
    active_scene_id
    active_event_id
    scene_contents: list<SceneContentItem>
    orphan_counts: list<OrphanCount>
```

```text
type SceneContentItem:
    card_id
    card_type
    display_label
    thumbnail_ref
    is_focus
```

```text
type OrphanCount:
    issue_type
    count
```

### 6.3 Structure band

```text
type StructureBandModel:
    beats: list<StructureBeat>
    contour_segments: list<ContourSegment>
    active_position_fraction
    continuity_breaks: list<Range>
```

```text
type StructureBeat:
    beat_id
    label
    normalized_position
    is_defined
    is_materialized
    attached_scene_count
```

```text
type ContourSegment:
    start_fraction
    end_fraction
    visual_weight
    state
```

```text
enum ContourState:
    formed
    thin
    broken
```

### 6.4 Status glyph

```text
type StatusGlyphModel:
    timeline_ring: TimelineRing
    chapter_ring: ChapterRing
    scene_ring: SceneRing
    active_locus: ActiveLocus
```

```text
type TimelineRing:
    begin_marker
    end_marker
    direction
    events: list<TimelineEventNode>
```

```text
type TimelineEventNode:
    event_id
    normalized_angle
    is_active
    is_major
```

```text
type ChapterRing:
    spans: list<ChapterSpan>
```

```text
type SceneRing:
    spans: list<SceneSpan>
```

```text
type ChapterSpan:
    chapter_id
    start_angle
    end_angle
    state
```

```text
type SceneSpan:
    scene_id
    start_angle
    end_angle
    state
    is_orphan_spill
```

```text
enum GlyphSpanState:
    formed
    thin_defined
    missing
```

```text
type ActiveLocus:
    event_id
    chapter_id
    scene_id
    event_angle
    chapter_span
    scene_span
```

### 6.5 Return strip

```text
type ReturnStripModel:
    last_node: ReturnNode
    resume_node: ReturnNode
    next_node: ReturnNode
```

```text
type ReturnNode:
    target_id
    target_type
    title
    subtitle
    excerpt
    context_tokens: list<ContextToken>
```

```text
type ContextToken:
    token_type
    value
```

### 6.6 Cast shelf

```text
type CastShelfModel:
    characters: list<CastCharacter>
    summary_text
```

```text
type CastCharacter:
    character_id
    display_label
    thumbnail_ref
```

### 6.7 Issues shelf

```text
type IssuesShelfModel:
    issues: list<ProjectIssue>
```

```text
type ProjectIssue:
    issue_id
    issue_type
    display_text
    severity
    linked_targets: list<object_id>
    resolution_actions: list<ActionModel>
```

### 6.8 Thread shelf

```text
type ThreadShelfModel:
    threads: list<NarrativeThread>
```

```text
type NarrativeThread:
    thread_id
    label
    linked_scene_ids
    linked_event_ids
    linked_card_ids
    weight
```

---

## 7. Geometry generation pseudocode

## 7.1 Normalizing chapter and scene spans

```text
function normalize_spans(units):
    total_extent = sum(unit.extent for unit in units if unit.is_present)

    current = 0
    spans = []

    for unit in units:
        if not unit.is_present:
            spans.append({
                unit_id: unit.id,
                start_fraction: current,
                end_fraction: current,
                state: missing
            })
            continue

        size = unit.extent / total_extent
        start_fraction = current
        end_fraction = current + size

        spans.append({
            unit_id: unit.id,
            start_fraction: start_fraction,
            end_fraction: end_fraction,
            state: unit.state
        })

        current = end_fraction

    return spans
```

## 7.2 Detecting continuity breaks

```text
function detect_continuity_breaks(ordered_units):
    breaks = []

    for i from 0 to length(ordered_units) - 2:
        current = ordered_units[i]
        next = ordered_units[i + 1]

        if current.expected_successor_id != next.id:
            breaks.append({
                after_id: current.id,
                before_id: next.id
            })

    return breaks
```

## 7.3 Mapping normalized span to ring angles

```text
function map_fraction_to_angle(fraction, start_angle, sweep_angle):
    return start_angle + (fraction * sweep_angle)
```

```text
function build_ring_spans(normalized_spans, start_angle, sweep_angle):
    output = []

    for span in normalized_spans:
        output.append({
            unit_id: span.unit_id,
            start_angle: map_fraction_to_angle(span.start_fraction, start_angle, sweep_angle),
            end_angle: map_fraction_to_angle(span.end_fraction, start_angle, sweep_angle),
            state: span.state
        })

    return output
```

## 7.4 Determining grey vs solid vs gap

```text
function classify_unit_state(unit):
    if not unit.exists_in_structure:
        return missing

    if unit.content_mass == 0:
        return thin_defined

    if unit.content_mass < unit.material_threshold:
        return thin_defined

    return formed
```

## 7.5 Orphan scene spill

```text
function derive_scene_spill(scene):
    if scene.has_valid_parent_chapter:
        return false

    if scene.is_projected_into_manuscript_order == false:
        return true

    return true
```

---

## 8. Interaction pseudocode

## 8.1 Resume action

```text
function resolve_resume_target(project):
    if project.last_active_scene exists and project.last_active_scene.is_writable:
        return project.last_active_scene

    if project.current_target_scene exists:
        return project.current_target_scene

    return first_unfinished_structural_target(project)
```

## 8.2 Issue click behavior

```text
function on_issue_selected(issue_id):
    issue = load_issue(issue_id)
    detail_pane = build_issue_detail_pane(issue)
    open_detail_pane(detail_pane)
```

```text
function build_issue_detail_pane(issue):
    return {
        title: issue.display_text,
        linked_targets: issue.linked_targets,
        explanation: explain_issue(issue),
        actions: issue.resolution_actions
    }
```

## 8.3 Thread click behavior

```text
function on_thread_selected(thread_id):
    thread = load_thread(thread_id)
    focus_thread(thread)
    reveal_linked_objects(thread.linked_scene_ids, thread.linked_event_ids, thread.linked_card_ids)
```

## 8.4 Glyph segment interaction

```text
function on_glyph_segment_selected(segment):
    if segment.type == timeline_event:
        reveal_event_detail(segment.event_id)

    if segment.type == chapter_span:
        reveal_chapter_detail(segment.chapter_id)

    if segment.type == scene_span:
        reveal_scene_region_detail(segment.scene_id)
```

---

## 9. State derivation rules

## 9.1 Chapter extent
Chapter ring span should be proportional to the chapter's relative extent in project structure so far.

Possible extent sources:
- projected manuscript footprint
- scene count weighted by scene size
- normalized chapter word count
- hybrid structural extent score

## 9.2 Scene extent
Scene ring span should be proportional to the scene's current projected manuscript or structural footprint.

Possible extent sources:
- scene word count
- projected contribution in manuscript order
- normalized scene importance weighting

## 9.3 Thin-defined state
Use when:
- card exists
- placeholder exists
- note shell exists
- chapter/scene is structurally present
- but materially insufficient content exists

## 9.4 Missing state
Use when:
- required structure is absent
- expected continuity is not present
- chapter linkage is missing
- projected manuscript continuity is broken

---

## 10. Accessibility and usability notes

- All icon-only or mark-heavy regions must expose accessible names
- Hover/tooltip or focus reveal must clarify semantics when needed
- Color must not be the only indicator of type or state
- Thread tags, issue rows, and scene contents should all have keyboard/focus affordances
- Click targets must be generous enough for desktop and touch use where applicable

---

## 11. Things intentionally not on this dashboard

The dashboard should not become:
- a giant metrics page
- a word-count trophy board
- a full inspector
- a duplicate manuscript view
- a duplicate timeline editor

It is a navigation, state, and readiness surface.

---

## 12. Next phase: writing mode surface

The writing mode surface should be designed as a complementary partner to this dashboard.

The dashboard answers:
- What is this project doing?
- Where is it thin, broken, or active?
- Where should I go?

Writing mode should answer:
- What am I writing right now?
- What surrounds this scene in manuscript order?
- What cards, references, threads, and events are locally relevant?
- How do I stay in flow without losing structure?

Writing mode should preserve visual continuity with dashboard mode, especially:
- top shell
- action model
- current-context awareness
- shared project identity

But the center of gravity must shift from project instrument panel to manuscript immersion.

End of locked dashboard specification.
