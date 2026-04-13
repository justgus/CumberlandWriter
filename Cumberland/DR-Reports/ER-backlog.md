# Enhancement Requests (ER) — Backlog

- Guidelines: [Cumberland/DR-Reports/ER-Guidelines.md]

**Purpose:** This file contains lower-priority enhancement requests that are documented for future consideration but not currently scheduled for active development. Think of this as the Agile product backlog—features we want to build someday, but not right now.

**Status:** Currently **10 backlog ERs**

---

## ER-0042: visionOS Spatial Murderboard — Foundation & Obsession Wall

**Status:** 🔵 Backlog
**Component:** visionOS / BoardEngine / RealityKit
**Priority:** Medium
**Date Requested:** 2026-02-22

**Rationale:**
Cumberland already runs on visionOS with multi-window support, but doesn't leverage spatial computing's unique capabilities. The Murderboard — a visual relationship graph of nodes and edges — is the most natural candidate for a 3D spatial experience. This ER establishes the shared spatial rendering infrastructure and delivers the first rendering mode: the Obsession Wall. Two additional rendering modes (Bulletin Board, Spatial Cloud) follow in ER-0043 and ER-0044. An orchestration layer allowing all modes to run simultaneously is specified in ER-0045.

**Current Behavior:**
The Murderboard is a 2D canvas (`BoardEngine`) with draggable nodes and connecting edges, rendered identically on visionOS as on macOS/iOS (flat window). visionOS features used: multi-window, ornament-based controls. No Volumes, Immersive Spaces, or RealityKit integration for the board.

**Desired Behavior:**
On visionOS, the Murderboard can be rendered as an "Obsession Wall" — cards and edges pinned to a large virtual wall surface anchored in the user's space.

- Card nodes and edges are rendered on a virtual wall anchored in the user's space
- The backlog is positioned on a dedicated section of the wall (e.g., a side panel or lower region)
- Multiple walls or wall sections can host multiple Murderboards simultaneously
- Nodes can be dragged to different positions on the wall surface (constrained to 2D wall plane)
- The wall can be repositioned and scaled in the room

**Requirements:**

1. **Shared Spatial Infrastructure** — Foundation for all spatial rendering modes (ER-0042, ER-0043, ER-0044):
   - `SpatialBoardRenderer` — bridge layer translating `BoardEngine` data (nodes, edges) to RealityKit `Entity` hierarchies
   - Card entity rendering: `ModelEntity` with card thumbnail + name as textured front face, kind badge color visible
   - Edge entity rendering: line/tube geometry connecting node positions, color matched to RelationType
   - Selection state: glow/outline highlight on selected node entity
   - Gesture handling: tap to select, double-tap to open card detail in a separate window
   - Smooth animations for node movement and selection
   - `RealityView` hosting infrastructure for 3D content

2. **Data Model Extensions** — Schema additions for spatial layout persistence:
   - Add optional `spatialX`, `spatialY`, `spatialZ` to `BoardNode` (or a separate `SpatialLayout` model)
   - Add optional `wallID` property for wall assignment tracking
   - Add optional `boardSide` (front/back) property for bulletin board side assignment (used by ER-0043)
   - 2D-to-wall position mapping: changes on the wall reflect in the flat 2D view and vice versa
   - Schema migration in `Migrations.swift`

3. **Mode Selector UI** — Ornament or toolbar control (visionOS only) offering rendering mode options:
   - "Flat" (default 2D window — existing behavior)
   - "Obsession Wall" (this ER)
   - "Bulletin Board" (ER-0043 — disabled until implemented)
   - "Spatial Cloud" (ER-0044 — disabled until implemented)
   - The selector is extensible so ER-0043/ER-0044 enable their options without modifying the selector itself

4. **Obsession Wall Rendering:**
   - Virtual wall entity rendered as a large flat surface (RealityKit plane or thin box)
   - Wall surface material: subtle texture (concrete, plaster, or cork) for visual grounding
   - Card nodes rendered as flat panel entities "pinned" to the wall surface via the shared card entity renderer
   - Edges rendered as drawn lines/connections on the wall plane
   - Backlog section: a visually distinct region of the wall (different tint or separated panel)
   - Multi-wall: ability to open additional wall sections for additional boards
   - Nodes constrained to wall plane (x, y movement only; no z-depth)
   - Wall can be grabbed and repositioned in the room
   - Wall can be scaled (pinch to resize)

5. **Graceful Fallback** — The 2D Murderboard remains the default; wall mode is an explicit opt-in via the mode selector. Non-visionOS platforms only see the flat 2D mode.

**Design Approach:**
- `SpatialBoardRenderer` as the bridge: takes `Board` + `[BoardNode]` + `[CardEdge]` and produces a RealityKit `Entity` subtree. Mode-specific renderers (wall, board, cloud) call into the shared renderer for card/edge entity creation and add their own placement logic.
- **Wall mode:** `ModelEntity` with `MeshResource.generatePlane()` for wall surface; card entities anchored as children of the wall entity; positions constrained to wall local x/y
- Card face textures: render SwiftUI card content to `UIImage`, apply as `SimpleMaterial` texture on plane entities (workaround for RealityKit's limited text rendering)
- `RealityView` hosts all 3D content; `DragGesture` on card entities for repositioning within wall plane
- Volume scene registered in `CumberlandApp.swift` (visionOS only)
- `BoardEngine` data model feeds node/edge data

**Components Affected:**
- New: `visionOS/SpatialBoardRenderer.swift` — translates BoardEngine data to RealityKit entities (shared across all future modes)
- New: `visionOS/ObsessionWallView.swift` — Wall mode RealityView + gesture handling
- New: `visionOS/SpatialModeSelector.swift` — Mode picker ornament/toolbar (extensible for ER-0043/ER-0044)
- Modified: `CumberlandApp.swift` — register Volume scene (visionOS)
- Modified: `MurderBoardView.swift` — integrate mode selector (visionOS only)
- Modified: `BoardNode` model — optional `spatialX`, `spatialY`, `spatialZ`, `wallID`, `boardSide` properties
- Modified: `visionOS/OrnamentViews.swift` — spatial mode controls
- Modified: `Migrations.swift` — schema migration for new BoardNode spatial properties

**Test Steps:**
1. Open Murderboard on visionOS — default 2D flat mode active
2. Mode selector visible in ornament/toolbar; "Obsession Wall" enabled, "Bulletin Board" and "Spatial Cloud" disabled/greyed
3. Select "Obsession Wall" — virtual wall appears in space with cards pinned to it
4. Card thumbnails, names, and kind badge colors visible on wall entities
5. Drag a card node — constrained to wall surface, edges follow
6. Backlog section visible and functional on the wall
7. Tap node to select (glow highlight); double-tap opens card detail in a separate window
8. Edge colors match RelationType
9. Wall can be repositioned and scaled in the room
10. Open a second wall section with a different Murderboard
11. Switch back to "Flat" mode — node positions updated from wall arrangement
12. Move nodes in flat 2D, switch to "Obsession Wall" — positions reflected on wall
13. Close and reopen — wall layout preserved

**Notes:**
- This ER establishes the shared infrastructure that ER-0043 (Bulletin Board) and ER-0044 (Spatial Cloud) build on
- The multi-mode simultaneous orchestration and board placement exclusivity constraint is specified in ER-0045
- Performance: large boards (50+ nodes) may need LOD — distant/off-screen nodes show only colored dots
- RealityKit text rendering is limited — card labels rendered as textures from SwiftUI snapshots
- Hand tracking precision affects grab gesture reliability — consider generous hit targets
- Future extensions: 3D timeline (walk through chronology), 3D map terrain (RealityKit terrain from drawn maps)
- Related: ER-0033 (gesture callbacks in MurderBoard app), ER-0043, ER-0044, ER-0045

---

## ER-0043: visionOS Spatial Murderboard — Bulletin Board

**Status:** 🔵 Backlog
**Component:** visionOS / BoardEngine / RealityKit
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0042 (shared spatial infrastructure)

**Rationale:**
The Bulletin Board rendering mode gives the Murderboard a tactile, physical-object metaphor — a free-standing cork board with pinned cards and string edges. Its unique flip mechanic lets a single board entity host two Murderboards (front and back), making efficient use of the spatial environment.

**Current Behavior:**
After ER-0042, the Murderboard can render on an Obsession Wall or in the default 2D flat view. No free-standing board object or flip mechanic exists.

**Desired Behavior:**
On visionOS, the Murderboard can be rendered as a free-standing physical bulletin board:

- A 3D bulletin board object appears in the user's space (cork board, whiteboard, etc.)
- Card nodes are "pinned" to the surface of the board with visible pin/tack decorations
- Relationship edges render as physical strings/yarn/thread between the pinned cards
- Users can grab, move, and rearrange nodes to different positions on the board surface
- **Flippable**: The board has a front and back side, each hosting a different Murderboard
  - User taps a flip button or uses a "pinch and pull" gesture to rotate the board 180 degrees along its horizontal axis
  - Smooth flip animation reveals the second board on the reverse side
  - The backside renders correctly as a mirrored surface (appears upside-down if the user walks around to view it from behind, just like a real physical board)
- The board can be repositioned and scaled in the room

**Requirements:**

1. **Board Entity:**
   - Free-standing 3D board entity: `MeshResource.generateBox()` with cork/whiteboard material
   - Board frame visible (wood trim, metal edges, or similar decorative border)
   - Board sized for comfortable interaction (~1.5m wide, ~1m tall at default scale)
   - Board can be grabbed and repositioned in the room
   - Pinch gesture to scale the board

2. **Card Rendering:**
   - Card nodes rendered as pinned items on the board surface using shared `SpatialBoardRenderer` card entities (ER-0042)
   - Pin/tack visual decoration at the top of each card entity
   - Nodes constrained to the board plane (2D surface movement only)
   - Drag gesture to reposition cards on the board surface

3. **Edge Rendering:**
   - Relationship edges rendered as physical strings/yarn between pin positions
   - Thin cylinder geometry or spline curves with slight droop (catenary) for realism
   - Edge color matches RelationType

4. **Flip Mechanic:**
   - Front and back sides each host a separate Murderboard (two different `Board` instances)
   - Flip trigger: button in ornament AND pinch-and-pull gesture on the board edge
   - Animated 180-degree rotation along the board's horizontal axis
   - Backside content is spatially correct — if the user walks around to view the back, content appears upside-down (physically accurate, not auto-corrected)
   - Board assignment: each side tracks which `Board` is displayed via `boardSide` property on `BoardNode`

5. **Mode Selector Integration:**
   - Enables the "Bulletin Board" option in the mode selector created by ER-0042
   - No modification to the selector UI itself — just registers as an available mode

**Design Approach:**
- `BulletinBoardView` hosts a `RealityView` with the board entity
- Board entity: root `Entity` with a `ModelEntity` child for the board body, two child `Entity` groups for front-side and back-side content
- Card/edge entities created by the shared `SpatialBoardRenderer` (ER-0042), parented under the appropriate side group
- Flip: animated `Transform` rotation on the board root entity (180 degrees around local X axis)
- Pin decoration: small `ModelEntity` sphere/cylinder at the top of each card entity
- String edges: thin cylinder geometry between pin positions, with slight sag via midpoint offset
- Backside mirroring: the back-side `Entity` group has a 180-degree Y rotation so content faces outward from the back but appears inverted when viewed from the front side

**Components Affected:**
- New: `visionOS/BulletinBoardView.swift` — Board mode RealityView + flip mechanic + gesture handling
- Modified: `visionOS/SpatialBoardRenderer.swift` — add pin decoration option, string edge geometry option
- Modified: `visionOS/SpatialModeSelector.swift` — enable "Bulletin Board" option

**Test Steps:**
1. Select "Bulletin Board" from mode selector — 3D board appears with frame and surface material
2. Cards pinned to board with visible pin/tack decoration
3. Edges rendered as strings between cards with slight droop
4. Edge colors match RelationType
5. Drag a card node — constrained to board surface, string edges follow
6. Tap node to select (glow); double-tap opens card detail window
7. Tap flip button — board rotates 180 degrees with smooth animation
8. Back side shows a different Murderboard
9. Walk behind the board — content appears upside-down (physically correct)
10. Flip back — front Murderboard restored
11. Reposition the board in the room — grab and move
12. Pinch to scale the board — cards and edges scale proportionally
13. Switch to "Flat" mode — positions from board reflected in 2D
14. Close and reopen — board layout and side assignments preserved

**Notes:**
- The catenary (droop) on string edges is a visual nicety; straight lines are an acceptable first pass
- Pin decoration should be subtle — functional, not cartoonish (unless Whimsical theme from ER-0037 is active)
- The flip mechanic is the most technically interesting part — get the rotation + backside mirroring right before polishing visuals
- Board side assignment uses the `boardSide` property added to `BoardNode` in ER-0042's schema migration
- Related: ER-0042 (foundation), ER-0044 (Spatial Cloud), ER-0045 (orchestration)

---

## ER-0044: visionOS Spatial Murderboard — Spatial Cloud

**Status:** 🔵 Backlog
**Component:** visionOS / BoardEngine / RealityKit
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0042 (shared spatial infrastructure)

**Rationale:**
The Spatial Cloud is the most immersive rendering mode — cards float freely in 3D space around the user with no surface constraint. This mode fully exploits visionOS spatial computing, letting writers physically walk among their characters, locations, and story elements, experiencing their world's relationships from within.

**Current Behavior:**
After ER-0042, the Murderboard can render on an Obsession Wall or in the default 2D flat view. Cards are always constrained to a 2D surface. No free-floating 3D arrangement exists.

**Desired Behavior:**
On visionOS, users can open the Murderboard as a 3D spatial experience where:

- Card nodes float as panels in 3D space around the user at comfortable interaction distances
- Relationship edges render as visible connections (lines, threads, or glowing arcs) between nodes
- Users can grab, move, and arrange nodes with hand gestures in full 3D (not constrained to any surface)
- Spatial clustering emerges naturally (group characters by faction, locations by region, etc.)
- Distance-based detail: pulling a node closer reveals more detail (full card with thumbnail, name, kind badge); pushing it away reduces to title and colored dot only

**Requirements:**

1. **Immersive Space Integration:**
   - Opens in a Shared Space (real environment visible) or Full Immersive Space (user preference)
   - `ImmersiveSpace` scene registered in `CumberlandApp.swift`
   - Cards positioned at comfortable interaction distances (1-3 meters from user initially)
   - Mixed Reality: real environment visible behind floating cards (Shared Space default)

2. **3D Node Rendering:**
   - Nodes are flat card panel entities floating in space using shared `SpatialBoardRenderer` card entities (ER-0042)
   - No surface constraint — full x, y, z positioning
   - Hand gesture: grab and drag to reposition nodes in 3D
   - Pinch gesture to scale individual nodes
   - Cards face the user (billboard orientation) unless manually rotated

3. **3D Edge Rendering:**
   - Edges rendered as 3D line/tube/arc entities connecting node positions
   - Edge geometry updates dynamically as nodes move
   - Edge color matches RelationType
   - Optional glow/luminance on edges for visibility in mixed reality

4. **Distance-Based LOD (Level of Detail):**
   - Nodes beyond ~2m: show only card title + kind-colored dot
   - Nodes at 1-2m: show thumbnail + name + kind badge
   - Nodes closer than ~1m: show full card detail (thumbnail, name, subtitle, kind badge)
   - LOD transitions are smooth (crossfade or scale)

5. **Mode Selector Integration:**
   - Enables the "Spatial Cloud" option in the mode selector created by ER-0042
   - Opening Spatial Cloud triggers the `ImmersiveSpace` opening flow

**Design Approach:**
- `SpatialCloudView` hosts a `RealityView` within an `ImmersiveSpace` scene
- Card entities as free-floating children of a root anchor entity
- `DragGesture` on entities for 3D repositioning (translate in all three axes)
- LOD system: attach multiple representation entities to each node; show/hide based on distance from `CameraComponent` position (computed per frame or on timer)
- Billboard orientation: use `BillboardComponent` or manual `look(at:)` to keep cards facing the user
- Edge entities: regenerated or updated when node positions change (use thin cylinders oriented between endpoints)
- `BoardEngine` data maps to 3D positions via the shared `SpatialBoardRenderer`

**Components Affected:**
- New: `visionOS/SpatialCloudView.swift` — Cloud mode RealityView + 3D gestures + LOD
- Modified: `CumberlandApp.swift` — register `ImmersiveSpace` scene (visionOS)
- Modified: `visionOS/SpatialBoardRenderer.swift` — add billboard orientation option, LOD entity management
- Modified: `visionOS/SpatialModeSelector.swift` — enable "Spatial Cloud" option, trigger ImmersiveSpace

**Test Steps:**
1. Select "Spatial Cloud" from mode selector — ImmersiveSpace opens, cards float in 3D around user
2. Real environment visible behind cards (Mixed Reality)
3. Cards face the user (billboard orientation)
4. Grab and drag a node — repositions in full 3D, edges follow
5. Pinch to scale a node — node resizes
6. Move a node farther away (~2m+) — detail reduces to title + colored dot
7. Pull a node closer (~1m) — full card detail visible
8. LOD transitions are smooth (no pop-in)
9. Edge colors match RelationType
10. Edges update in real-time as nodes move
11. Tap node to select; double-tap opens card detail in a window
12. Close ImmersiveSpace — return to flat mode, 3D positions mapped back to 2D
13. Close and reopen — spatial positions preserved

**Notes:**
- Spatial Cloud is the highest-complexity mode; ship it after Wall and Board are stable
- Comfort zone: initial node placement should avoid nodes too close (<0.5m) or too far (>4m) from the user
- Performance: large boards (50+ nodes) in 3D are expensive — aggressive LOD and possibly off-screen culling needed
- Billboard orientation can be disorienting if many cards overlap from the user's viewpoint — consider gentle spread/repulsion algorithm
- `ImmersiveSpace` has platform restrictions: only one can be open at a time in visionOS
- Related: ER-0042 (foundation), ER-0043 (Bulletin Board), ER-0045 (orchestration)

---

## ER-0045: visionOS Spatial Murderboard — Multi-Mode Orchestration

**Status:** 🔵 Backlog
**Component:** visionOS / BoardEngine / State Management
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0042, ER-0043, ER-0044

**Rationale:**
With three spatial rendering modes available (Obsession Wall, Bulletin Board, Spatial Cloud), users should be able to run all three simultaneously — multiple boards on walls, two on a bulletin board, and one in the spatial cloud — creating a rich, multi-surface workspace. However, a given Murderboard should only exist in one place at a time to avoid conflicting edits and confusing state. This ER adds the orchestration layer that manages concurrent rendering modes and enforces board placement exclusivity.

**Current Behavior:**
After ER-0042/ER-0043/ER-0044, each rendering mode works independently. The mode selector switches between modes for a single board. No mechanism exists to run multiple modes concurrently or to prevent the same board from appearing in two places.

**Desired Behavior:**
All three spatial rendering modes can be active simultaneously:

- Multiple Murderboards displayed on Obsession Walls (one or more walls, each hosting one or more boards)
- Two Murderboards displayed on a Bulletin Board (one per side, front and back)
- One Murderboard displayed in the Spatial Cloud
- **Exclusivity constraint:** A given Murderboard can only appear in one rendering location at a time. If Board "A" is on a wall, it cannot also be on the bulletin board or in the cloud. The user must explicitly move or close it from its current location before placing it elsewhere.

**Requirements:**

1. **Board Placement Registry:**
   - A `SpatialPlacementManager` (@Observable) tracks where each `Board` is currently rendered
   - Each placement is a value type: `SpatialPlacement` with cases:
     - `.flat` (2D window)
     - `.wall(wallID: UUID, position: CGPoint)` — which wall, where on the wall
     - `.bulletinBoard(boardEntityID: UUID, side: .front | .back)` — which board entity, which side
     - `.spatialCloud` — in the immersive space
   - The registry is the single source of truth for "where is this board?"

2. **Exclusivity Enforcement:**
   - When the user attempts to place a board in a new location, the system checks the registry
   - If the board is already placed elsewhere, present a confirmation: "This board is currently on [Wall 1 / Bulletin Board front / Spatial Cloud]. Move it here?"
   - On confirmation: remove from old location, place in new location
   - On cancel: no change
   - A board can only appear in **one** spatial location (or the flat 2D window) at a time

3. **Concurrent Mode Rendering:**
   - Multiple `ObsessionWallView` instances can coexist (multiple walls in the room)
   - One `BulletinBoardView` instance with front/back boards
   - One `SpatialCloudView` instance (one Immersive Space — visionOS limitation)
   - All render simultaneously without interference
   - Changes to a board in any location are reflected in real-time (SwiftData observation)

4. **Board Picker:**
   - When the user opens a new wall section, bulletin board side, or the spatial cloud, they pick which board to display from a list of available boards
   - Boards already placed elsewhere are shown with their current location and a "Move here" option
   - Unplaced boards are shown as directly available

5. **Lifecycle Management:**
   - Closing a wall removes its boards from the registry (boards become unplaced)
   - Flipping the bulletin board does not unplace — both sides remain active
   - Closing the Immersive Space (Spatial Cloud) unplaces that board
   - App termination persists placement state for session restore

6. **Data Synchronization:**
   - Node edits (position, selection) in any rendering location write through to `BoardNode` model
   - All active renderings of other boards continue to reflect SwiftData changes
   - No conflict: since a board can only be in one place, no two renderers edit the same board simultaneously

**Design Approach:**
- `SpatialPlacementManager` as an `@Observable` singleton, injected via SwiftUI Environment
- Placement state persisted to `@AppStorage` (serialized dictionary of `Board.id → SpatialPlacement`)
- Each spatial view (Wall, Board, Cloud) queries the placement manager on launch to determine which boards to display
- Placement change flow: user action → check registry → confirm if needed → update registry → old renderer releases board → new renderer acquires board
- Board picker: SwiftUI sheet/popover listing all project boards with placement status indicators

**Components Affected:**
- New: `visionOS/SpatialPlacementManager.swift` — placement registry + exclusivity logic
- New: `visionOS/BoardPickerView.swift` — board selection UI with placement status
- Modified: `visionOS/ObsessionWallView.swift` — query placement manager, support multi-instance
- Modified: `visionOS/BulletinBoardView.swift` — query placement manager for front/back assignment
- Modified: `visionOS/SpatialCloudView.swift` — query placement manager
- Modified: `visionOS/SpatialModeSelector.swift` — becomes "Add Rendering Surface" rather than mode switch (since multiple modes coexist)
- Modified: `CumberlandApp.swift` — inject `SpatialPlacementManager` into Environment

**Test Steps:**

*Concurrent Modes:*
1. Open an Obsession Wall with Board "A" pinned to it
2. Open a Bulletin Board with Board "B" on the front and Board "C" on the back
3. Open Spatial Cloud with Board "D" floating in space
4. All four boards visible and interactive simultaneously
5. Edit a node in Board "A" on the wall — changes persisted

*Exclusivity:*
6. Attempt to place Board "A" (currently on the wall) onto the bulletin board front
7. Confirmation prompt: "Board A is currently on Obsession Wall. Move it here?"
8. Confirm — Board "A" removed from wall, appears on bulletin board front
9. Wall section now shows empty/available slot
10. Attempt to place Board "B" into the Spatial Cloud while it's on the bulletin board
11. Confirm move — Board "B" removed from bulletin board, appears in cloud
12. Bulletin board front now shows empty/available slot

*Board Picker:*
13. Open a new wall section — board picker appears
14. Placed boards shown with location indicator (e.g., "Board C — Bulletin Board back")
15. Unplaced boards shown as directly available
16. Select an unplaced board — appears on the new wall section
17. Select a placed board — confirmation to move

*Lifecycle:*
18. Close a wall section — boards on it become unplaced
19. Close Immersive Space — cloud board becomes unplaced
20. Quit and relaunch on visionOS — placement state restored

**Notes:**
- The exclusivity constraint prevents confusing state where two renderers could write conflicting positions to the same `BoardNode`
- The mode selector evolves from "switch mode" (ER-0042) to "add rendering surface" — the user can have multiple surfaces active
- visionOS limits Immersive Spaces to one at a time, so only one Spatial Cloud can exist — this is a platform constraint, not an app limitation
- Consider a "spatial overview" ornament that shows a minimap of all active rendering surfaces and which boards they host
- Performance: rendering 3+ boards across multiple surfaces simultaneously may require aggressive LOD and lazy entity creation
- Related: ER-0042 (foundation + wall), ER-0043 (bulletin board), ER-0044 (spatial cloud)

---

## ER-0046: visionOS Multi-Window Architecture

**Status:** 🔵 Backlog
**Component:** visionOS / Window Management / State Restoration
**Priority:** Medium
**Date Requested:** 2026-02-23

**Rationale:**
Cumberland on visionOS currently launches with a single window and does not restore window state across sessions. The Vision Pro can display multiple windows simultaneously, and writers working in spatial computing expect their workspace arrangement to persist — just as a physical desk stays arranged between sessions. This ER establishes the multi-window infrastructure that all visionOS workspace features depend on.

**Current Behavior:**
Cumberland opens a single window on visionOS. Additional windows can be opened via the system, but closing and relaunching the app restores only one default window. No mechanism tracks which content was displayed in which window, where windows were positioned, or which satellite views were open.

**Desired Behavior:**
Cumberland on visionOS supports multiple named window types (satellite windows) for different content views. On relaunch, the app restores all previously open windows with their content and the system restores their spatial positions.

**Requirements:**

1. **Window Type Registration:**
   - `WindowGroup` registrations in `CumberlandApp.swift` for each satellite content type:
     - Murderboard viewer (displays a specific Board)
     - Timeline viewer (displays a specific Card's timeline)
     - Multi-Timeline viewer (comparative timeline view)
     - Map viewer (displays a specific map Card)
     - Card detail viewer (standalone card detail for pinned reference)
   - Each `WindowGroup` has a unique scene identifier
   - Windows opened via `openWindow(id:value:)` with the content ID (Board ID, Card ID, etc.)

2. **Session Restoration via `NSUserActivity`:**
   - Each satellite window advertises an `NSUserActivity` via the `.userActivity()` modifier
   - Activity `userInfo` encodes the content identifier (e.g., `["boardID": UUID string]`)
   - On relaunch, visionOS restores scenes from saved activities
   - Cumberland rehydrates each window's content from the activity's `userInfo`
   - The workspace window (Card Matrix) restores its scroll position, selected card, and filter state

3. **Cross-Window Focus Tracking:**
   - A shared `@Observable` `WindowFocusManager` tracks which satellite window currently has focus
   - Each satellite window writes its identity to the manager when it gains focus (via `.onAppear` / `FocusedValue`)
   - The workspace matrix reads the focus manager to determine which cards to disable (ER-0050)
   - Focus state is transient — not persisted across sessions

4. **Window Lifecycle:**
   - Opening a satellite window: triggered from the workspace matrix or from within another view ("Open in new window")
   - Closing a satellite window: standard visionOS close gesture; window's content is removed from focus tracking
   - visionOS manages window positions automatically — Cumberland does not need to store spatial coordinates

5. **Graceful Degradation:**
   - macOS and iOS continue using their existing navigation paradigms (sidebar + tabs)
   - All `WindowGroup` registrations and satellite window code are `#if os(visionOS)` guarded
   - No changes to macOS/iOS behavior

**Design Approach:**
- Register `WindowGroup` instances in `CumberlandApp.swift` within `#if os(visionOS)` blocks
- Use `openWindow(id:value:)` where `value` conforms to `Codable` and `Hashable` (typically a UUID)
- Each satellite view uses `.userActivity(activityType)` to advertise its state for restoration
- `WindowFocusManager` is an `@Observable` class injected via `.environment()` at the app level
- `FocusedValue` / `.focusedValue()` propagates the active window's content type and ID
- Test restoration by force-quitting and relaunching on visionOS

**Components Affected:**
- Modified: `CumberlandApp.swift` — `WindowGroup` registrations, `WindowFocusManager` injection (visionOS)
- New: `visionOS/WindowFocusManager.swift` — cross-window focus tracking
- New: `visionOS/SatelliteMurderboardView.swift` — standalone Murderboard window
- New: `visionOS/SatelliteTimelineView.swift` — standalone Timeline window
- New: `visionOS/SatelliteMapView.swift` — standalone Map window
- New: `visionOS/SatelliteCardDetailView.swift` — standalone Card detail window
- Modified: `visionOS/OrnamentViews.swift` — "Open in new window" controls

**Test Steps:**
1. Launch Cumberland on visionOS — workspace window appears
2. Open a Murderboard in a satellite window — new window appears
3. Open a Timeline in another satellite window — second satellite appears
4. Open a card detail in a third satellite window — third satellite appears
5. Position all windows in space
6. Force-quit Cumberland
7. Relaunch — all satellite windows restored with correct content
8. Satellite window positions restored by visionOS
9. Workspace matrix scroll position and selected card restored
10. Close a satellite window — focus manager no longer reports it
11. Verify macOS/iOS builds are unaffected (no satellite windows, existing navigation intact)

**Notes:**
- visionOS handles window position persistence automatically — we only need to persist *content identity*
- `NSUserActivity` is the standard restoration mechanism; `SceneStorage` is an alternative for simpler state
- The number of simultaneous satellite windows should have a sensible soft limit (e.g., 8-10) to avoid performance issues
- Window titles should reflect content: "Murderboard — Character Relationships", "Timeline — Chapter 3", etc.
- Related: ER-0047 (Card Matrix), ER-0049 (Detail Panel), ER-0050 (Drag-and-Drop), ER-0051 (Workspace Integration)

---

## ER-0047: visionOS Card Matrix

**Status:** 🔵 Backlog
**Component:** visionOS / Navigation / UI
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0046 (multi-window architecture)

**Rationale:**
The current visionOS sidebar is identical to the macOS sidebar — a narrow vertical list that feels cramped on a spatial display capable of filling the user's field of view. The Card Matrix replaces this with a 2D scrollable grid that leverages the Vision Pro's expansive canvas, showing full compact CardViews organized in columns by Kind, alphabetically sorted within each column.

**Current Behavior:**
Cumberland on visionOS uses the same sidebar navigation as macOS — a narrow `NavigationSplitView` with a list of cards filtered by Kind tabs. The sidebar occupies a small fraction of the available display area.

**Desired Behavior:**
On visionOS, the primary workspace window displays a Card Matrix — a wide, 2D-scrollable grid of compact CardViews organized in columns by card Kind. The matrix is the first thing the user sees on launch and serves as the universal card source for all spatial views.

**Requirements:**

1. **Matrix Layout:**
   - Columns: one per card Kind that has at least one card (empty Kinds hidden)
   - Column headers: Kind icon + title, pinned at top during vertical scroll
   - Rows: compact CardViews sorted alphabetically by name within each column
   - Full compact `CardView` rendered for each card (thumbnail, name, kind badge, border, size category)
   - `LazyHStack` of `LazyVStack`s for efficient rendering — only visible cards are instantiated

2. **Navigation:**
   - Pinch+drag gesture to pan the matrix in any direction
   - Gaze-at-edge scrolling (visionOS built-in API) for hands-free navigation
   - Trackpad scroll gestures for desk-bound usage
   - Smooth momentum scrolling in both axes

3. **Empty State:**
   - When no cards exist, display a welcoming empty state with instructions
   - Kind picker (dropdown or segmented control) to choose what kind of card to create
   - "Create Card" button that opens the CardEditorView for the selected Kind
   - Once any card exists, the matrix appears

4. **Card Creation in Matrix:**
   - "+" button in each column header to create a new card of that Kind directly
   - Opens CardEditorView for the new card

5. **Card Selection:**
   - Quick pinch (tap) on a card to select it
   - Selected card shows a highlight ring/glow in the matrix
   - Selection triggers the detail panel pop-out (ER-0049)
   - Only one card selected at a time
   - Tap elsewhere or dismiss gesture to deselect

6. **Matrix as Universal Source:**
   - The matrix serves as the backlog/source for all spatial views (Murderboard, Timeline, Map)
   - When a satellite window has focus, cards already placed in that view are visually disabled (dimmed) in the matrix
   - Disabled cards show a subtle indicator of where they're placed (e.g., small icon overlay)
   - This behavior depends on ER-0046's `WindowFocusManager` and ER-0050's drag-and-drop

**Design Approach:**
- New `visionOS/CardMatrixView.swift` as the primary workspace content on visionOS
- Replace `NavigationSplitView` sidebar with the matrix on visionOS (macOS/iOS unchanged)
- Use SwiftData `@Query` to fetch all cards, grouped by `kind`, sorted by `name`
- `LazyHStack(spacing:)` → `LazyVStack(spacing:, pinnedViews: .sectionHeaders)` per column
- Wrap in `ScrollView([.horizontal, .vertical])` for 2D scrolling
- Column visibility managed by the filter system (ER-0048)
- Card selection state stored in a `@State` property on the workspace view
- The matrix passes the focused satellite window's content to determine which cards to disable

**Components Affected:**
- New: `visionOS/CardMatrixView.swift` — 2D scrollable card grid
- New: `visionOS/CardMatrixColumnView.swift` — single column rendering
- New: `visionOS/CardMatrixEmptyState.swift` — empty state with card creation controls
- Modified: `CumberlandApp.swift` — use `CardMatrixView` as primary visionOS content (conditionally)
- Modified: `CardView.swift` — add disabled/dimmed state for placed-card indication

**Test Steps:**
1. Launch Cumberland on visionOS with existing cards — matrix appears with columns by Kind
2. Column headers show Kind icon + title, pinned during vertical scroll
3. Cards display as full compact CardViews with thumbnail, name, kind badge, border
4. Pinch+drag to scroll horizontally and vertically — smooth momentum
5. Gaze at left/right edge — matrix scrolls horizontally
6. Trackpad scroll works in both axes
7. Tap a card — highlight ring appears, detail panel pops out (ER-0049)
8. Tap elsewhere — card deselects, detail panel collapses
9. Tap "+" on Characters column header — CardEditorView opens for new Character
10. Create the card — it appears in the correct column, alphabetically positioned
11. Delete all cards — empty state appears with creation controls
12. Create a card from empty state — matrix appears with the new card
13. Verify macOS/iOS sidebar navigation is unchanged

**Notes:**
- Compact CardView is the right density — standard/large would make the matrix unwieldy
- Column count indicator ("Showing 4 of 16 kinds") helpful for orientation when many kinds exist
- Consider a minimap/overview strip at the bottom showing all columns as colored bars for quick navigation
- The matrix replaces the per-view backlog (Murderboard backlog, etc.) — this is a significant UX simplification
- Performance: with 500+ cards, lazy rendering is critical; test with large datasets
- Related: ER-0048 (Filter Cube), ER-0049 (Detail Panel), ER-0050 (Drag-and-Drop), ER-0051 (Integration)

---

## ER-0048: visionOS Filter Cube

**Status:** 🔵 Backlog
**Component:** visionOS / Navigation / UI
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0047 (Card Matrix)

_(See ER-proposed.md for full details - this is a complex feature with 6 interactive faces controlling search, kind filtering, grouping, sorting, display options, and saved filter presets)_

---

## ER-0049: visionOS Expanded Detail Panel

**Status:** 🔵 Backlog
**Component:** visionOS / Card Editing / UI
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0047 (Card Matrix)

_(See ER-proposed.md for full details - slides out from Card Matrix on selection, showing all card info simultaneously in stacked layout)_

---

## ER-0050: visionOS Cross-Window Drag-and-Drop

**Status:** 🔵 Backlog
**Component:** visionOS / Interaction / Data Transfer
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0046 (multi-window), ER-0047 (Card Matrix)

_(See ER-proposed.md for full details - drag cards from matrix to satellite windows using Transferable protocol)_

---

## ER-0051: visionOS Workspace Integration

**Status:** 🔵 Backlog
**Component:** visionOS / UX / Architecture
**Priority:** Medium
**Date Requested:** 2026-02-23
**Depends On:** ER-0046, ER-0047, ER-0048, ER-0049, ER-0050

_(See ER-backlog.md for full details - integrates all workspace components into cohesive experience with backlog removal and cross-window coordination)_

---

*Last Updated: 2026-04-13*
