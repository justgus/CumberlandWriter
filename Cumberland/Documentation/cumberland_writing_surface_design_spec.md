# Cumberland Writer — Writing Surface Design
Version: Locked working-surface specification  
Status: Approved concept baseline for writing mode

## 1. Purpose

The Writing Surface is the manuscript-first working mode for Cumberland Writer.

It is the companion to the Project Dashboard.

The dashboard answers:
- What is the project doing?
- Where is it thin, broken, or active?
- Where should I go?

The writing surface answers:
- What am I writing right now?
- Where am I in the manuscript?
- What scene am I in?
- What contextual objects are active here?
- How do I continue writing without losing project structure?

The writing surface is **continuous manuscript first, scene-aware underneath**.

That means:
- the manuscript is primary
- the writer reads and writes in continuous vertical flow
- scene boundaries exist, but remain quiet
- project/scene metadata must not crowd the manuscript

---

## 2. Design principles

## 2.1 Manuscript first
The text body is the center of gravity.

No contextual element should compete visually with the manuscript unless the writer explicitly reveals or activates it.

## 2.2 Scene-aware underneath
Scenes remain important, but scene boundaries should be expressed subtly through:
- spacing
- tone shifts
- separator lines
- active-scene emphasis marks
- scene map instrumentation
- current-scene chip

The writing surface should not feel like a stack of cards.

## 2.3 Preserve re-entry and orientation
The writer must always be able to recover:
- current chapter
- current scene
- current structural location
- active contextual objects

But those cues should not overtake the text.

## 2.4 Compress persistent context
The writing surface may keep a narrow context gutter, but it should be much lighter than the dashboard.

## 2.5 Creation must be immediate
The writing surface must allow:
- quick creation of a new chapter
- quick creation of a new scene

These are common operations and should be available directly in the manuscript-oriented UI.

---

## 3. High-level layout

The writing surface contains:

- existing application shell / left sidebar
- top mode/action bar
- central manuscript canvas
- narrow right context gutter
- chapter tab strip at top of manuscript
- scene map instrument above bottom tray
- bottom quick action tray

---

## 4. Region-by-region specification

## 4.1 Left shell sidebar
The existing Cumberland project shell remains present.

Contains:
- current project
- project list
- card-type navigation

Important constraint:
the writing-surface-specific **scene map must not live in the sidebar**.

The writing surface uses the sidebar only as a stable application shell.

---

## 4.2 Top mode/action bar
Same overall shell logic as dashboard mode.

Contains:
- project mode title
- Dashboard / Writing switch
- Focus action
- Write action

The bar should remain visually stable between dashboard mode and writing mode.

---

## 4.3 Central manuscript canvas
This is the primary writing region.

The manuscript is presented as a continuous vertically scrolling composition of the project text.

It is assembled from project order, not from isolated independent scene cards.

### Core properties
- continuous scrolling
- chapter transitions preserved
- scene transitions preserved
- writing insertion cursor active in manuscript body
- scene-local context remains available but secondary

### Content that may appear here
- chapter headings or chapter entry positions
- continuous scene text
- citations / reference anchors
- footnotes or linked notes if supported
- subtle current-scene awareness signals

---

## 4.4 Chapter tab strip
A tab strip sits at the top of the manuscript region.

This strip answers:
- what chapter am I currently in
- what other chapters exist
- where can I jump structurally

### Tab behavior
- tabs may overlap significantly
- full width for every chapter name is not required
- context makes overlapping acceptable
- the active chapter tab should be fully or most clearly readable
- inactive tabs may be more compressed

### Label behavior
Preferred labels:
- `Chapter 1`
- `Chapter 2`
- etc.

Or, if the writer supplied chapter names:
- `An Unexpected Party`
- `The Ring Awakens`
- `The Council of Elrond`
- etc.

The active chapter should be most readable; other chapter names may be partially occluded or compressed.

### Automatic selection
As the writer scrolls through manuscript content:
- the top tab strip automatically updates
- the tab corresponding to the current chapter becomes selected

### Interaction
- tap chapter tab: jump to that chapter
- drag/scroll manuscript: tab updates automatically
- optional long press / alternate action: reveal chapter actions or chapter context

---

## 4.5 Add Chapter control
A chapter-creation control is placed at the far right of the chapter tab strip.

It must **not** be a bare plus sign only.

It should visually suggest:
- chapter container
- tab logic
- insertion of a structural unit

Recommended form:
- tab-like button with plus
- small stacked-tab cue with plus

### Chapter creation rule
Creating a new chapter:
- creates the new chapter
- automatically creates its first attached scene
- moves focus into that newly created scene
- clears the right-side context gutter until scene-local context exists

This means chapter creation is also implicitly scene creation.

---

## 4.6 Scene awareness inside manuscript flow
The writing surface is scene-aware, but not scene-framed.

### Accepted scene signals
- subtle background tone shifts between scenes
- quiet separator rules
- small active-scene emphasis mark
- current-scene chip
- scene map instrument
- manuscript-local anchors

### Rejected behavior
- heavy boxed scene cards
- oversized scene title labels on every separator
- loud repeated scene headers
- card-like framing of each scene

---

## 4.7 Scene separators
Scene separators should be quiet.

Recommended treatment:
- thin horizontal separator rule
- optional slightly stronger mark for active scene
- no repeated scene-border labels in the main manuscript flow

This follows the design principle of reducing verbal interruption in the writing stream.

---

## 4.8 Current-scene chip
A small floating chip may remain near the manuscript header region.

Purpose:
- identify the active scene quickly
- give the writer an at-a-glance scene label without occupying large space

Recommended content:
- scene number
- scene title or short label

Example:
`Scene 13 • Lantern room`

This chip is lighter than a header and should not dominate the manuscript.

---

## 4.9 Right context gutter
The right side in writing mode is a **compressed context gutter**, not a full inspector.

It should use far less width than the earlier dashboard-like treatment.

### Final direction
The right gutter should consist primarily of **objects/cards/circles**, not a text-heavy rail.

The manuscript wins the width.

### Signed object column
The preferred form is a signed vertical column of colored circles.

Each circle represents a local contextual object relevant to the active scene.

### Card/object type encoding
Border or ring color indicates type.

Suggested mapping:
- character = blue
- artifact = amber/brown
- vehicle = green
- event = purple
- note/reference = note accent
- thread = muted thread accent

### Active context
One or more circles may show focus state:
- active ring
- stronger outline
- positional prominence

### Optional companion text
Companion labels may exist only when truly necessary, but the target direction is:
- mostly pure object/circle gutter
- labels on hover, tap, or reveal
- not permanently consuming width

### Empty-state rule
When the current scene is newly created and has no context objects yet:
- the right gutter remains visible
- previously linked scene objects are cleared
- stale context must never persist
- empty state may show only faint placeholder circles or a quiet empty gutter

The writer should immediately understand:
“I am now in a fresh scene with no scene-local context yet.”

---

## 4.10 Margin anchors
Small colored anchors may appear in the manuscript margin.

These are not duplicates of the right gutter.

They represent **local linked-card anchors** tied to specific places in the text.

Possible meanings:
- event link
- artifact link
- character relevance
- note/reference anchor

### Distinction from right gutter
- right gutter = what is active in the scene now
- margin anchors = where context touches the manuscript locally

### Interaction
- tap anchor: reveal local linked detail
- hover: preview linked item
- alternate action: jump to linked card

---

## 4.11 Scene map instrument
The scene map lives above the bottom quick-action tray, not in the sidebar.

Purpose:
- provide quick manuscript-scale scene awareness
- show current active scene
- allow quick scene navigation
- host scene creation control

### Appearance
- horizontal instrument strip
- baseline with scene marks
- current scene highlighted
- compact and quiet

### Interaction
- tap scene mark: jump to scene
- drag or scroll manuscript: current mark updates
- hover: reveal scene summary if desired

---

## 4.12 Add Scene control
A scene-creation control is placed at the far left of the scene map instrument.

It must not read as a second generic plus button.

It should visually suggest:
- scene marker
- manuscript segment insertion
- scene-map logic

Recommended form:
- marker-like button with plus
- underlying rail cue lighter than the plus itself

### Scene creation rule
Creating a new scene:
- creates a new scene in the current manuscript flow
- attaches it according to insertion context
- moves focus into that new scene
- clears the right-side context gutter until scene-local context exists

This means both creation controls ultimately create a new writable scene context.

Difference:
- chapter add = chapter + first scene
- scene add = scene only

---

## 4.13 Bottom quick-action tray
Compact, icon-first, manuscript-relevant actions.

Possible actions:
- Scenes
- Structure
- Context
- Notes
- Focus

This tray should remain subordinate to the manuscript.

---

## 5. Creation behavior

## 5.1 New Chapter
Creating a new chapter must do all of the following:

1. create chapter object
2. create first scene attached to that chapter
3. insert that chapter into chapter order
4. insert the scene into manuscript order
5. move cursor/focus into new scene body
6. clear right-side context gutter for the new empty scene
7. visually confirm insertion through:
   - active chapter tab selection
   - active scene mark selection
   - optional brief focus highlight

## 5.2 New Scene
Creating a new scene must do all of the following:

1. create scene object
2. insert it before or after current scene according to creation context
3. attach it to current chapter or appropriate structural container
4. move cursor/focus into new scene body
5. clear right-side context gutter for the new empty scene
6. visually confirm insertion through:
   - active scene map selection
   - active scene separator location
   - optional brief focus highlight

---

## 6. Dynamic behaviors

## 6.1 Scroll behavior
As the writer scrolls:
- current chapter tab updates automatically
- scene map active mark updates automatically
- active-scene chip updates automatically
- right context gutter updates to the active scene

## 6.2 Scene transition behavior
As the writer crosses a scene boundary:
- subtle scene background zone updates
- active separator emphasis updates
- active scene chip updates
- right context gutter updates
- manuscript margin anchors remain tied to local text positions

## 6.3 Fresh-scene transition behavior
After creating a chapter or scene:
- cursor enters new scene text body
- previous context gutter contents are cleared
- scene map selects the new scene
- chapter tab may update if new chapter was created
- optional ephemeral highlight confirms insertion

---

## 7. Pseudocode data model

## 7.1 Writing surface root model

```text
type WritingSurfaceModel:
    project_id
    manuscript: ManuscriptModel
    chapter_tabs: ChapterTabStripModel
    scene_map: SceneMapModel
    active_scene_chip: ActiveSceneChipModel
    context_gutter: ContextGutterModel
    margin_anchors: list<MarginAnchor>
    quick_actions: list<ActionModel>
```

## 7.2 Manuscript model

```text
type ManuscriptModel:
    ordered_chapters: list<ManuscriptChapter>
    ordered_scenes: list<ManuscriptScene>
    active_chapter_id
    active_scene_id
    cursor_position
```

```text
type ManuscriptChapter:
    chapter_id
    display_title
    start_offset
    end_offset
```

```text
type ManuscriptScene:
    scene_id
    chapter_id
    display_title
    manuscript_start_offset
    manuscript_end_offset
    tone_zone
    local_context_ids: list<object_id>
```

## 7.3 Chapter tabs

```text
type ChapterTabStripModel:
    tabs: list<ChapterTab>
    active_chapter_id
    add_chapter_action
```

```text
type ChapterTab:
    chapter_id
    display_title
    visual_width
    is_active
```

## 7.4 Scene map

```text
type SceneMapModel:
    scene_marks: list<SceneMapMark>
    active_scene_id
    add_scene_action
```

```text
type SceneMapMark:
    scene_id
    normalized_position
    visual_height
    is_active
```

## 7.5 Scene chip

```text
type ActiveSceneChipModel:
    scene_id
    display_title
```

## 7.6 Context gutter

```text
type ContextGutterModel:
    items: list<ContextGutterItem>
    is_empty
```

```text
type ContextGutterItem:
    object_id
    object_type
    is_active
    display_mode
```

## 7.7 Margin anchors

```text
type MarginAnchor:
    anchor_id
    linked_object_id
    linked_object_type
    manuscript_offset
```

---

## 8. Pseudocode interaction rules

## 8.1 Resolve active chapter from manuscript scroll

```text
function resolve_active_chapter(manuscript_offset, ordered_chapters):
    for chapter in ordered_chapters:
        if manuscript_offset >= chapter.start_offset and manuscript_offset < chapter.end_offset:
            return chapter.chapter_id

    return ordered_chapters.last.chapter_id
```

## 8.2 Resolve active scene from manuscript scroll

```text
function resolve_active_scene(manuscript_offset, ordered_scenes):
    for scene in ordered_scenes:
        if manuscript_offset >= scene.manuscript_start_offset and manuscript_offset < scene.manuscript_end_offset:
            return scene.scene_id

    return ordered_scenes.last.scene_id
```

## 8.3 Update surface state during scroll

```text
function on_manuscript_scroll(manuscript_offset):
    active_chapter_id = resolve_active_chapter(manuscript_offset, manuscript.ordered_chapters)
    active_scene_id = resolve_active_scene(manuscript_offset, manuscript.ordered_scenes)

    chapter_tabs.active_chapter_id = active_chapter_id
    scene_map.active_scene_id = active_scene_id
    active_scene_chip.scene_id = active_scene_id
    context_gutter.items = load_scene_context(active_scene_id)
```

## 8.4 Add chapter

```text
function create_new_chapter(after_chapter_id):
    new_chapter = create_chapter()
    insert_chapter_after(new_chapter, after_chapter_id)

    new_scene = create_scene()
    attach_scene_to_chapter(new_scene, new_chapter.id)
    insert_scene_into_manuscript(new_scene, after_chapter_id)

    move_cursor_to_scene_start(new_scene.id)
    context_gutter.items = []
    set_active_chapter(new_chapter.id)
    set_active_scene(new_scene.id)

    flash_insertion_feedback(new_chapter.id, new_scene.id)
```

## 8.5 Add scene

```text
function create_new_scene(relative_to_scene_id, placement_mode):
    new_scene = create_scene()

    if placement_mode == before:
        insert_scene_before(new_scene, relative_to_scene_id)
    else:
        insert_scene_after(new_scene, relative_to_scene_id)

    attach_scene_to_current_chapter_if_needed(new_scene)

    move_cursor_to_scene_start(new_scene.id)
    context_gutter.items = []
    set_active_scene(new_scene.id)

    flash_insertion_feedback(current_chapter_id(), new_scene.id)
```

## 8.6 Empty gutter state

```text
function load_scene_context(scene_id):
    items = query_scene_context_items(scene_id)

    if items is empty:
        return []

    return items
```

```text
function render_context_gutter(items):
    if items is empty:
        render_empty_gutter()
    else:
        render_context_items(items)
```

## 8.7 Margin anchor reveal

```text
function on_margin_anchor_selected(anchor_id):
    anchor = load_margin_anchor(anchor_id)
    reveal_linked_object(anchor.linked_object_id)
```

---

## 9. Visual semantics

## 9.1 Scene-awareness cues
Allowed cues:
- background tone changes
- separator rules
- small active notch
- chip
- map selection

These cues must remain subordinate to the manuscript text.

## 9.2 Context gutter semantics
The right gutter should be understood as:
- active scene-local objects/cards
- not dashboard-level summary
- not manuscript-local anchors
- not a fully descriptive inspector

## 9.3 Add controls semantics
Add Chapter:
- structural container creation
- represented by tab-like add glyph

Add Scene:
- manuscript segment creation
- represented by scene-marker-like add glyph

These should not collapse into two identical plus signs.

---

## 10. Accessibility and usability notes

- add controls must expose accessible labels:
  - Add Chapter
  - Add Scene
- compressed right gutter must remain keyboard reachable
- circle-only context must provide readable names through hover/focus/assistive access
- chapter tabs must remain selectable despite overlap
- current chapter and current scene should always be determinable through non-color cues as well

---

## 11. Explicit design rules to carry forward

1. Writing mode is continuous manuscript first.
2. Scene awareness exists underneath, not above.
3. Sidebar does not host scene map.
4. Right context gutter is compressed and primarily object/circle-based.
5. Margin anchors are local manuscript-linked indicators, not scene inventory.
6. Chapter creation automatically creates first scene.
7. Both chapter creation and scene creation clear the right context gutter for the new empty scene.
8. Chapter tabs should use decimal or authored names.
9. The active chapter tab should be automatically selected during scroll.
10. Scene map should remain above the bottom tray and host scene insertion.

---

## 12. Relationship to dashboard mode

Dashboard mode:
- project-scale cognition
- structural state
- issue and thread awareness
- resumption planning

Writing mode:
- manuscript immersion
- local scene context
- immediate writing continuation
- low-friction scene/chapter creation

These two surfaces are complementary, not redundant.

End of locked writing-surface specification.
