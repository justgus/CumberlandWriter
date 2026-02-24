# visionOS Spatial Workspace — Implementation Plan

**Covers:** ER-0042 through ER-0051 (10 ERs)
**Date:** 2026-02-23

---

## Overview

This plan covers the complete visionOS spatial experience for Cumberland: the workspace redesign (Card Matrix, Filter Cube, Detail Panel, multi-window architecture) and the spatial Murderboard rendering modes (Obsession Wall, Bulletin Board, Spatial Cloud, orchestration). The workspace redesign (ER-0046–0051) should be implemented first, as the spatial Murderboard modes (ER-0042–0045) build on the multi-window and drag-and-drop infrastructure.

---

## Dependency Graph

```
ER-0046 (Multi-Window Architecture)
  ├── ER-0047 (Card Matrix)
  │     ├── ER-0048 (Filter Cube)
  │     ├── ER-0049 (Detail Panel)
  │     └── ER-0050 (Drag-and-Drop)  ← also depends on ER-0046
  │           └── ER-0051 (Workspace Integration)  ← depends on 0046-0050
  │
  └── ER-0042 (Spatial Foundation + Obsession Wall)  ← also needs ER-0046 windows
        ├── ER-0043 (Bulletin Board)
        ├── ER-0044 (Spatial Cloud)
        └── ER-0045 (Multi-Mode Orchestration)  ← depends on 0042-0044
```

---

## Implementation Order

### Track A: Workspace Redesign (ER-0046 → 0047 → 0048/0049 → 0050 → 0051)

#### Step 1: ER-0046 — Multi-Window Architecture

**Objective:** Satellite window infrastructure, session restoration, focus tracking.

1. **Window registration** — Add `WindowGroup` declarations in `CumberlandApp.swift` for each satellite type (Murderboard, Timeline, Map, Card Detail), guarded by `#if os(visionOS)`
   - Each `WindowGroup(id:for:)` takes a `UUID` value identifying the content
   - Register `openWindow` environment action for launching satellites

2. **Session restoration** — Add `.userActivity()` modifiers to each satellite view
   - Activity type: `"com.cumberland.satellite.murderboard"`, `.timeline"`, etc.
   - `userInfo` encodes the content UUID
   - Add `.onContinueUserActivity()` handler to restore content on relaunch
   - Test: force-quit and relaunch verifies all windows restore

3. **WindowFocusManager** — Create `visionOS/WindowFocusManager.swift`
   - `@Observable` class with `activeWindowType: SatelliteType?` and `activeContentID: UUID?`
   - Each satellite view writes to the manager via `.onAppear` / scene phase changes
   - Inject into Environment at app level

4. **Satellite view shells** — Create minimal satellite views that display the correct content for a given UUID
   - `SatelliteMurderboardView.swift`, `SatelliteTimelineView.swift`, `SatelliteMapView.swift`, `SatelliteCardDetailView.swift`
   - Initially these wrap the existing views with a SwiftData query for the given ID
   - Verify windows open, display content, restore on relaunch

**Verification:** Build and run on visionOS simulator. Open 3 satellite windows. Force-quit. Relaunch. All 3 windows reappear with correct content.

---

#### Step 2: ER-0047 — Card Matrix

**Objective:** Replace visionOS sidebar with 2D card grid.

1. **CardMatrixView** — Create `visionOS/CardMatrixView.swift`
   - `@Query` to fetch all cards, group by `kind`
   - `ScrollView([.horizontal, .vertical])` containing `LazyHStack` of columns
   - Each column: `LazyVStack(pinnedViews: .sectionHeaders)` with Kind header + compact `CardView`s
   - Cards sorted alphabetically within each column

2. **Column headers** — Kind icon + title, pinned during vertical scroll
   - "+" button in each header to create a card of that Kind
   - Empty Kinds hidden (columns only appear for Kinds with cards)

3. **Empty state** — `CardMatrixEmptyState.swift`
   - Kind picker + "Create Card" button
   - Transitions to matrix once any card exists

4. **Card selection** — `@State private var selectedCard: Card?`
   - Tap/pinch on CardView sets selection
   - Highlight ring on selected card
   - Tap elsewhere to deselect

5. **Integrate into app** — In `CumberlandApp.swift`, use `CardMatrixView` as primary content on visionOS instead of `NavigationSplitView`
   - Guard with `#if os(visionOS)` — macOS/iOS unchanged

6. **Navigation** — Verify pinch+drag scrolling, gaze-at-edge scrolling, and trackpad scroll all work

**Verification:** Build on visionOS. See card matrix. Create a card via "+". Select a card. Scroll in both axes. Verify macOS build is unaffected.

---

#### Step 3a: ER-0048 — Filter Cube (can parallel with 3b)

**Objective:** 3D rotatable filter control.

1. **MatrixFilterState** — Create `visionOS/MatrixFilterState.swift`
   - `@Observable` class with properties: `searchText`, `visibleKinds: Set<Kinds>`, `groupingAxis`, `sortOrder`, `displayOptions`, `savedPresets`
   - Inject into Environment alongside the matrix

2. **FilterCubeView** — Create `visionOS/FilterCubeView.swift`
   - Six SwiftUI views arranged in 3D space using `.rotation3DEffect()` transforms
   - Gesture-driven rotation: `DragGesture` → update rotation angles → snap to nearest face on release
   - Trackpad scroll gesture mapped to rotation
   - Position in top-leading corner of matrix

3. **Face views** — Create individual face views in `visionOS/FilterCubeFaces/`:
   - `SearchFace.swift` — text field bound to `filterState.searchText`
   - `KindFilterFace.swift` — toggle grid bound to `filterState.visibleKinds`
   - `GroupingFace.swift` — picker bound to `filterState.groupingAxis`
   - `SortFace.swift` — picker bound to `filterState.sortOrder`
   - `DisplayFace.swift` — toggles bound to `filterState.displayOptions`
   - `PresetsFace.swift` — save/load UI, persisted via `@AppStorage`

4. **Matrix integration** — `CardMatrixView` reads `MatrixFilterState` to:
   - Filter cards by search text and visible Kinds
   - Group columns by the selected axis
   - Sort within columns by the selected order
   - Handle multi-column card appearance (By Project/World/Source/RelationType grouping)

5. **Active filter indicators** — Edge glow when a face has non-default state

**Verification:** Rotate cube. Search filters cards. Kind toggles hide columns. Grouping axis changes columns. Sort reorders. Saved presets persist.

---

#### Step 3b: ER-0049 — Expanded Detail Panel (can parallel with 3a)

**Objective:** Pop-out card detail panel in workspace.

1. **CardDetailPanelView** — Create `visionOS/CardDetailPanelView.swift`
   - Left stack: Card Detail section (editable fields), Compact Relationship section, Citation section
   - Right panel: Contextual view picker + contextual view (Murderboard/Timeline/Map/Structure)
   - All sections scrollable independently

2. **Extract compact sections** from existing views:
   - `CompactRelationshipSection` — from `CardRelationshipView`, remove redundant header
   - `CompactCitationSection` — from citation views, adapted for panel width
   - Reuse existing editing logic — no rewrite

3. **Pop-out animation** — In `CardMatrixView`:
   - When `selectedCard != nil`, animate workspace window width expansion
   - Use `.inspector()` modifier or manual `HStack` with animated width
   - The panel appears to slide out from the right edge

4. **Contextual view** — Mode picker at top of right panel
   - Show applicable views based on card context (e.g., only show Murderboard if card is a node)
   - If no contextual views applicable, hide right panel

5. **Keyboard integration** — Tab between fields, Escape to dismiss, Cmd+1/2/3 for contextual modes

**Verification:** Select card → panel pops out. Edit name → matrix updates. Relationships visible. Citations editable. Contextual view switches. Deselect → panel collapses.

---

#### Step 4: ER-0050 — Cross-Window Drag-and-Drop

**Objective:** Drag cards from matrix to satellite windows, focus-aware disabling.

1. **Transferable conformance** — Extend `Card` with `Transferable` in `Model/Card.swift`
   - `CodableRepresentation` using Card UUID as payload
   - Keep payload lightweight

2. **Draggable matrix cards** — Add `.draggable(card)` to `CardView` in matrix

3. **Drop targets** — Add `.dropDestination(for:)` to satellite views:
   - Murderboard: create `BoardNode` at drop position
   - Timeline: create timeline entry at drop position
   - Map: pin card at geographic coordinate

4. **Focus-aware disabling** — Extend `WindowFocusManager` with `placedCardIDs: Set<UUID>`
   - Each satellite publishes its placed card IDs when focused
   - Matrix reads `placedCardIDs`, dims matching cards, disables drag on them

5. **File drops** — Add `UTType.image` and `UTType.plainText` support to matrix drop target

**Verification:** Drag card from matrix to Murderboard → node appears. Focus Murderboard → that card dims in matrix. Drop file → card image updates.

---

#### Step 5: ER-0051 — Workspace Integration

**Objective:** Polish, remove redundant backlogs, cross-view navigation, performance.

1. **Remove per-view backlogs** on visionOS — `#if os(visionOS)` guards in MurderBoardView, Timeline, Map
2. **Cross-view navigation** — `WorkspaceNavigationManager` for "navigate to card" from any satellite
3. **Performance profiling** — 200+ cards, 3 satellites, 90fps target
4. **Accessibility audit** — VoiceOver through matrix, cube, panel, satellites
5. **End-to-end testing** — Full author workflow from launch to session restore

---

### Track B: Spatial Murderboard (ER-0042 → 0043/0044 → 0045)

Track B can begin after ER-0046 is complete (needs multi-window infrastructure). Track A and Track B can then proceed in parallel.

#### Step 6: ER-0042 — Foundation & Obsession Wall

**Objective:** Shared spatial rendering infrastructure + first spatial mode.

1. **Schema migration** — Add `spatialX`, `spatialY`, `spatialZ`, `wallID`, `boardSide` to `BoardNode`
   - Create `AppSchemaV6` and migration stage in `Migrations.swift`

2. **SpatialBoardRenderer** — Create `visionOS/SpatialBoardRenderer.swift`
   - Input: `Board` + `[BoardNode]` + `[CardEdge]`
   - Output: RealityKit `Entity` subtree
   - Card entity: `ModelEntity` with `MeshResource.generatePlane()`, textured with SwiftUI-rendered card snapshot
   - Edge entity: thin cylinder geometry between node positions, colored by RelationType
   - Selection glow: `HoverEffectComponent` or custom shader

3. **ObsessionWallView** — Create `visionOS/ObsessionWallView.swift`
   - `RealityView` with wall plane entity
   - Card entities as children of wall entity, constrained to local x/y
   - `DragGesture` on card entities for repositioning within wall plane
   - Wall surface material: textured `SimpleMaterial`

4. **Mode selector** — Create `visionOS/SpatialModeSelector.swift`
   - Ornament with mode options: Flat, Obsession Wall (enabled), Bulletin Board (disabled), Spatial Cloud (disabled)
   - Integrate into `MurderBoardView` on visionOS

5. **2D ↔ Wall position sync** — Write wall positions back to `BoardNode.spatialX/Y`; map to 2D positions when switching modes

**Verification:** Open Murderboard → select Obsession Wall → cards on wall. Drag cards. Edges follow. Switch to Flat → positions preserved.

---

#### Step 7a: ER-0043 — Bulletin Board (can parallel with 7b)

**Objective:** Free-standing 3D board with flip mechanic.

1. **Board entity** — `MeshResource.generateBox()` with cork material and wood frame
2. **Pin decoration** — Small sphere/cylinder at top of each card entity
3. **String edges** — Thin cylinder geometry with midpoint sag
4. **Flip mechanic** — Front/back `Entity` groups; animated 180-degree rotation; backside mirroring
5. **Mode selector integration** — Enable "Bulletin Board" option

---

#### Step 7b: ER-0044 — Spatial Cloud (can parallel with 7a)

**Objective:** Free-floating cards in Immersive Space.

1. **ImmersiveSpace registration** in `CumberlandApp.swift`
2. **SpatialCloudView** — `RealityView` in ImmersiveSpace; cards as free-floating entities
3. **3D drag gestures** — Full x/y/z repositioning
4. **Billboard orientation** — `BillboardComponent` or manual look-at
5. **LOD system** — Distance-based detail switching
6. **Mode selector integration** — Enable "Spatial Cloud" option, trigger ImmersiveSpace

---

#### Step 8: ER-0045 — Multi-Mode Orchestration

**Objective:** All modes simultaneously, board placement exclusivity.

1. **SpatialPlacementManager** — Board placement registry with exclusivity enforcement
2. **Board picker** — UI for assigning boards to surfaces
3. **Concurrent rendering** — Multiple walls + bulletin board + cloud simultaneously
4. **Lifecycle management** — Closing surfaces unplaces boards; persist placement state

---

## Recommended Execution Order

| Phase | ERs | Description |
|-------|-----|-------------|
| **1** | ER-0046 | Multi-window architecture (foundation for everything) |
| **2** | ER-0047 | Card Matrix (primary workspace) |
| **3** | ER-0048 + ER-0049 | Filter Cube + Detail Panel (can be parallel) |
| **4** | ER-0050 | Cross-window drag-and-drop |
| **5** | ER-0051 | Workspace integration and polish |
| **6** | ER-0042 | Spatial foundation + Obsession Wall |
| **7** | ER-0043 + ER-0044 | Bulletin Board + Spatial Cloud (can be parallel) |
| **8** | ER-0045 | Multi-mode orchestration |

Phases 3 and 7 have internal parallelism. Track B (phases 6-8) can begin as early as after Phase 1 is complete, running alongside Track A phases 2-5.

---

## Risk Areas

1. **Cross-window drag-and-drop on visionOS** — The `Transferable` + `.draggable()` + `.dropDestination()` pipeline between separate `WindowGroup` instances needs validation. If cross-window drops don't work reliably, the fallback is a context menu ("Add to Murderboard...") triggered from the matrix.

2. **Filter Cube 3D rendering** — If SwiftUI `.rotation3DEffect()` doesn't produce a convincing cube on visionOS (clipping, z-fighting), fall back to a RealityKit-rendered cube with SwiftUI textures, or simplify to a rotating panel stack.

3. **Card snapshot textures for RealityKit** — Rendering SwiftUI CardViews to `UIImage` for use as entity textures is necessary but may have performance implications for large boards. Cache aggressively and render off-main-thread.

4. **Session restoration reliability** — `NSUserActivity`-based restoration on visionOS is the standard path but has edge cases (activities expiring, system memory pressure). Test with varying numbers of windows and cold starts.

5. **Matrix performance at scale** — 500+ cards with full compact CardViews in a 2D lazy grid. SwiftUI's `LazyHStack`/`LazyVStack` should handle this, but verify with Instruments on device.

---

*Last Updated: 2026-02-23*
