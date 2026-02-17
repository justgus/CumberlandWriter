# ER-0026: Extract Murderboard to Standalone Target

**Status:** Verified
**Component:** Murderboard, Relationship Visualization, Workspace Target
**Priority:** Low
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-17
**Date Verified:** 2026-02-17
**Dependencies:** ER-0022 (Code refactoring must be complete first)

**Summary:**

Extract the Murderboard relationship visualization system into a reusable `BoardEngine` Swift Package. Create adapter types for Cumberland integration, migrate Cumberland's MurderBoardView to use BoardEngine components, delete redundant files, and create a standalone investigation board app with seed data.

**What Was Implemented:**

### BoardEngine Package (`Packages/BoardEngine/`)

Created a fully self-contained Swift Package (swift-tools-version:6.2) with 22 source files:

**Protocols:**
- `BoardNodeRepresentable` - Generic node protocol with UUID identity, position, display properties
- `BoardEdgeRepresentable` - Generic edge protocol with source/target/type
- `BoardDataSource` - Data access abstraction (nodes, edges, transforms, CRUD operations)

**Canvas System:**
- `BoardCanvasTransform` - World-to-view/view-to-world coordinate transforms (`v = w*S + T`)
- `BoardCanvasView` - Composite canvas stacking grid, edges, nodes (generic over DataSource + @ViewBuilder)
- `BoardNodesLayer` - Generic node rendering with preference key size collection
- `BoardEdgesLayer` - Relationship edge rendering with gradient strokes
- `BoardGridBackground` - Tile-based grid overlay
- `BoardNodeSizeKeys` - PreferenceKeys for node size measurement
- `BoardBorderOverlay` - Decorative window frame border

**Gesture System:**
- `MultiGestureHandler` - Cross-platform gesture system (1,559 lines, macOS/iOS/visionOS)
- `CanvasGestureTarget` - Pan/pinch/background tap with configurable zoom/pan limits
- `NodeGestureTarget` - Node drag/selection/right-click with offset tracking
- `EdgeHandleGestureTarget` - Edge creation drag with hit-testing
- `BoardGestureIntegration` - ViewModifier wiring all targets to a DataSource

**Edge Creation:**
- `BoardEdgeCreationState` - Observable state machine for drag-to-create edges
- `BoardEdgeHandle` - Visual handle circle on node trailing edge
- `BoardEdgeHandlesLayer` - Layer rendering handles on all nodes
- `BoardEdgeCreationLineLayer` - Dashed preview line during edge drag
- `BoardEdgeDropTargetHighlight` - Highlight modifier for hovered targets

**Toolbar & Layout:**
- `BoardZoomStrip` - Platform-specific floating zoom controls (macOS editable field, iOS read-only)
- `BoardRecenter` - Recenter on primary node + zoom-keeping-center utilities
- `BoardShuffleLayout` - Ring-based shuffle algorithm arranging nodes concentrically
- `BoardSidebarPanel` - Generic sidebar with @ViewBuilder rows, multi-selection, keyboard shortcuts

**Configuration:**
- `BoardConfiguration` - All constants (zoom/pan limits, visual appearance, shuffle geometry)
- `GeometryExtensions` - `.dg`, `.cg`, `.clamped()`, `.scaled()` utilities

**Tests:** 17 passing tests covering transforms, edge creation state, geometry extensions, configuration.

### Cumberland Migration

**MurderBoardView** was rewritten to use BoardEngine components:
- Uses `BoardCanvasView` (replaces CanvasLayer)
- Uses `BoardGestureIntegration` (replaces GestureHandlerIntegration)
- Uses `BoardZoomStrip` (replaces MurderBoardToolbar zoom controls)
- Uses `BoardBorderOverlay` (replaces inline border overlay)
- Uses `BoardEdgeCreationState` (replaces EdgeCreationState)
- Uses `BoardCanvasTransform` for coordinate math (replaces CanvasLayerTransform)
- Uses `BoardRecenter` and `BoardShuffleLayout` for toolbar actions
- Cumberland-specific parts retained: CardView rendering via @ViewBuilder, SidebarPanel backlog, EdgeCreationRelationTypeSheet, thumbnail prefetching, board loading

**Adapter Layer:**
- `CumberlandBoardAdapter.swift` - `CumberlandNode` (wraps BoardNode) and `CumberlandEdge` (wraps CardEdge) protocol conformances
- `CumberlandBoardDataSource.swift` - `@Observable` class implementing `BoardDataSource`, wrapping Board + ModelContext
- BoardEngine added as local package dependency to all 3 Cumberland targets (macOS, iOS, visionOS)

**Files Deleted (10 files, ~4,200 lines):**
- `CanvasLayer.swift` - Replaced by `BoardCanvasView`
- `MultiGestureHandler.swift` - Moved to BoardEngine
- `Murderboard/BacklogSidebarPanel.swift` - Superseded by `SidebarPanel.swift`
- `Murderboard/MurderBoardNodeView.swift` - Replaced by @ViewBuilder node content
- `Murderboard/MurderBoardNodesLayer.swift` - Replaced by `BoardNodesLayer`
- `Murderboard/EdgesLayer.swift` - Replaced by `BoardEdgesLayer`
- `Murderboard/MurderBoardGestureTargets.swift` - Replaced by BoardEngine gesture targets
- `Murderboard/MurderBoardToolbar.swift` - Replaced by `BoardZoomStrip`
- `Murderboard/MurderBoardOperations.swift` - Logic moved into MurderBoardView + CumberlandBoardDataSource
- `CardDropTargetExample.swift` - Example file referencing old gesture types

**Files Trimmed:**
- `CanvasLayerTransform.swift` - Reduced to just `Comparable.clamped(to:)` extension (used by non-Murderboard code); transform logic moved to BoardEngine
- `EdgeCreationSystem.swift` - Reduced to `PendingEdgeCreation` + `EdgeCreationRelationTypeSheet` (Cumberland-specific); state/handles/line/highlight moved to BoardEngine

### Standalone App (`MurderboardApp/`)

- `MurderboardApp.swift` - `@main` entry point with SwiftData container
- `InvestigationBoard.swift` - `@Model` board with zoom/pan/primaryNodeID, cascade relationships to nodes and edges
- `InvestigationNode.swift` - `@Model` node with name, subtitle, category (person/place/clue/event/document/weapon/vehicle/organization), color
- `InvestigationEdge.swift` - `@Model` edge with source/target/label
- `InvestigationDataSource.swift` - `BoardDataSource` conformance wrapping Investigation models, with seed data
- `InvestigationBoardView.swift` - Root view using `BoardCanvasView` + `BoardGestureIntegration` + `BoardZoomStrip` + `BoardBorderOverlay`
- `InvestigationNodeView.swift` - Custom node tile (provided via @ViewBuilder)
- `NodeEditorSheet.swift` - Create node sheet
- `EdgeLabelSheet.swift` - Edge label entry sheet

**Seed Data (auto-populated on first launch):**
A realistic investigation scenario with 12 nodes and 14 edges:
- 5 persons: Det. Sarah Chen (primary), Marcus Webb (victim), Julian Reeves (suspect), Nadia Okafor (suspect), Tommy Huang (witness)
- 2 places: Pier 7 Warehouse (crime scene), Webb & Reeves LLC (office)
- 1 weapon: 9mm Shell Casing
- 1 clue: Burner Phone
- 1 event: Insurance Policy Change
- 1 document: Financial Records
- 1 organization: Harbor Freight Co.
- 14 relationship edges connecting the investigation web

### Build Verification

- **BoardEngine** `swift build`: BUILD SUCCEEDED
- **BoardEngine** `swift test`: 17/17 tests passed
- **Cumberland macOS** `xcodebuild`: BUILD SUCCEEDED
- **Cumberland iOS** `xcodebuild`: BUILD SUCCEEDED
- **Cumberland visionOS** `xcodebuild`: BUILD SUCCEEDED
- **MurderboardApp**: Builds and runs with seed data, verified by user

**Files Created:** 28 new files (22 in BoardEngine, 2 in Cumberland adapter, 4 in standalone app)
**Files Modified:** 4 (project.pbxproj, MurderBoardView.swift, EdgeCreationSystem.swift, CanvasLayerTransform.swift)
**Files Deleted:** 10

---

*Verified: 2026-02-17*
