# ER-0026: Extract Murderboard to Standalone Target - Build Plan

**Status:** 🔵 Proposed
**Component:** Murderboard, Relationship Visualization, Workspace Target
**Priority:** Medium
**Date Requested:** 2026-02-03
**Dependencies:** ER-0022 (Code refactoring must be complete first)

---

## Overview

Extract the Murderboard relationship visualization system into a standalone application target within the Cumberland workspace. Murderboard is currently tightly coupled to Cumberland's Card and CardEdge models, but has potential as a general-purpose visual investigation and relationship mapping tool useful beyond worldbuilding.

**Market Potential:** Law enforcement, journalism, research, investigation, project management, genealogy, network analysis

**Key Challenge:** Murderboard is heavily dependent on Cumberland's data model. This extraction requires significant abstraction work.

---

## Current State Analysis

### Existing Murderboard System

Location: `Cumberland/Murderboard/` folder

**Files (6 files, ~2,000 lines):**
- `MurderBoardView.swift` (1,386 lines) - Main view with canvas, gestures, rendering
- `MurderBoardNodeView.swift` - Node UI representation
- `EdgesLayer.swift` - Edge rendering layer
- `MurderBoardNodesLayer.swift` - Node rendering layer
- `BacklogSidebarPanel.swift` - Sidebar for unplaced cards
- `RelatedEdgesList.swift` - Edge list display

**Current Dependencies:**
- **Card model:** Nodes represent Card entities
- **CardEdge model:** Edges represent CardEdge relationships
- **RelationType model:** Edge types based on RelationType
- **SwiftData:** Persistent storage
- **AppModel:** Global app state
- **@Query:** Direct queries for cards and edges

**Current Features:**
- Pan and zoom canvas
- Drag nodes to position
- Create edges by dragging between nodes
- Select nodes and edges
- Backlog of unplaced nodes
- Edge type selection
- Node images from cards

---

## Abstraction Strategy

### Challenge: Decouple from Cumberland Models

The core challenge is that Murderboard directly uses:
```swift
// Current (Cumberland-specific):
@Query private var allCards: [Card]
var selectedCard: Card?
var edge: CardEdge

func addNode(card: Card) { ... }
func createEdge(from: Card, to: Card, type: RelationType) { ... }
```

### Solution: Protocol-Based Abstraction

Define protocols that describe what Murderboard needs, without requiring specific models:

```swift
// Generic protocols that both Cumberland and standalone Murderboard can implement

public protocol BoardNode: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var subtitle: String? { get }
    var imageData: Data? { get }
    var boardPosition: CGPoint? { get set }
    var isOnBoard: Bool { get }
}

public protocol BoardEdge: Identifiable, Codable {
    var id: UUID { get }
    var sourceNodeID: UUID { get }
    var targetNodeID: UUID { get }
    var edgeTypeName: String { get }
    var edgeTypeForward: String { get }  // "owns"
    var edgeTypeInverse: String { get }  // "owned-by"
}

public protocol BoardEdgeType: Identifiable, Codable {
    var id: UUID { get }
    var forwardVerb: String { get }  // "owns"
    var inverseVerb: String { get }  // "owned-by"
    var displayName: String { get }  // "owns/owned-by"
}

public protocol BoardDataSource {
    associatedtype Node: BoardNode
    associatedtype Edge: BoardEdge
    associatedtype EdgeType: BoardEdgeType

    func getAllNodes() -> [Node]
    func getNodesOnBoard() -> [Node]
    func getNodesNotOnBoard() -> [Node]
    func getEdges(for node: Node) -> [Edge]
    func getAllEdgeTypes() -> [EdgeType]

    func updateNodePosition(node: Node, position: CGPoint)
    func createEdge(from: Node, to: Node, edgeType: EdgeType) throws
    func deleteEdge(_ edge: Edge) throws
}
```

Then Cumberland's Card/CardEdge can conform:
```swift
extension Card: BoardNode {
    var boardPosition: CGPoint? {
        get { /* from Card.boardX/boardY */ }
        set { /* update Card.boardX/boardY */ }
    }
    // ... other conformance
}

extension CardEdge: BoardEdge {
    var sourceNodeID: UUID { source.id }
    var targetNodeID: UUID { target.id }
    // ... other conformance
}
```

And standalone Murderboard can have its own models:
```swift
// Standalone Murderboard app
struct InvestigationNode: BoardNode {
    var id: UUID
    var name: String
    var subtitle: String?
    var imageData: Data?
    var boardPosition: CGPoint?
    var isOnBoard: Bool
    // No Card-specific fields
}

struct InvestigationEdge: BoardEdge {
    var id: UUID
    var sourceNodeID: UUID
    var targetNodeID: UUID
    var edgeTypeName: String
    var edgeTypeForward: String
    var edgeTypeInverse: String
    // No CardEdge-specific fields
}
```

---

## Package Architecture

### BoardEngine Package

Create a new shared package: `BoardEngine`

```
BoardEngine/
├── Package.swift
├── Sources/
│   └── BoardEngine/
│       ├── Protocols/
│       │   ├── BoardNode.swift
│       │   ├── BoardEdge.swift
│       │   ├── BoardEdgeType.swift
│       │   └── BoardDataSource.swift
│       ├── Canvas/
│       │   ├── BoardCanvasState.swift          # Canvas transform state
│       │   ├── BoardCanvasGestures.swift       # Pan, zoom, drag gestures
│       │   └── BoardRenderer.swift             # Rendering logic
│       ├── Layout/
│       │   ├── BoardLayoutEngine.swift         # Auto-layout algorithms
│       │   ├── ForceDirectedLayout.swift       # Force-directed graph layout
│       │   └── HierarchicalLayout.swift        # Tree layout
│       └── Utilities/
│           ├── GeometryExtensions.swift
│           └── ColorExtensions.swift
└── Tests/
    └── BoardEngineTests/
```

### Standalone Murderboard App Structure

```
Murderboard/
├── Murderboard.xcodeproj
├── Models/
│   ├── InvestigationProject.swift      # Main project model (@Model)
│   ├── InvestigationNode.swift         # Node model (conforms to BoardNode)
│   ├── InvestigationEdge.swift         # Edge model (conforms to BoardEdge)
│   └── EdgeType.swift                  # Edge type model (conforms to BoardEdgeType)
├── Data/
│   └── MurderboardDataSource.swift     # Implements BoardDataSource
├── Views/
│   ├── BoardCanvasView.swift           # Main board view (uses BoardEngine)
│   ├── NodeView.swift                  # Node visual
│   ├── EdgeView.swift                  # Edge visual
│   ├── NodeLibraryView.swift           # Sidebar with all nodes
│   └── ProjectListView.swift           # List of investigation projects
└── MurderboardApp.swift                # App entry point
```

---

## Implementation Plan

### Phase 1: Create BoardEngine Package (Week 1-2)

**Step 1.1: Define Core Protocols**

```swift
// BoardEngine/Sources/BoardEngine/Protocols/BoardNode.swift
import Foundation

/// Protocol representing a node on the board
public protocol BoardNode: Identifiable, Sendable {
    var id: UUID { get }
    var name: String { get }
    var subtitle: String? { get }
    var imageData: Data? { get }
    var boardPosition: CGPoint? { get set }
    var isOnBoard: Bool { get }
}

// BoardEngine/Sources/BoardEngine/Protocols/BoardEdge.swift
public protocol BoardEdge: Identifiable, Sendable {
    var id: UUID { get }
    var sourceNodeID: UUID { get }
    var targetNodeID: UUID { get }
    var edgeTypeName: String { get }
    var edgeTypeForward: String { get }
    var edgeTypeInverse: String { get }
}

// BoardEngine/Sources/BoardEngine/Protocols/BoardEdgeType.swift
public protocol BoardEdgeType: Identifiable, Sendable {
    var id: UUID { get }
    var forwardVerb: String { get }
    var inverseVerb: String { get }
    var displayName: String { get }
}

// BoardEngine/Sources/BoardEngine/Protocols/BoardDataSource.swift
@MainActor
public protocol BoardDataSource: AnyObject {
    associatedtype Node: BoardNode
    associatedtype Edge: BoardEdge
    associatedtype EdgeType: BoardEdgeType

    func getAllNodes() -> [Node]
    func getNodesOnBoard() -> [Node]
    func getNodesNotOnBoard() -> [Node]
    func getEdges(for node: Node) -> [Edge]
    func getAllEdges() -> [Edge]
    func getAllEdgeTypes() -> [EdgeType]

    func updateNodePosition(nodeID: UUID, position: CGPoint) throws
    func addNodeToBoard(nodeID: UUID) throws
    func removeNodeFromBoard(nodeID: UUID) throws
    func createEdge(fromID: UUID, toID: UUID, edgeTypeID: UUID) throws
    func deleteEdge(edgeID: UUID) throws
}
```

**Step 1.2: Implement Canvas State Management**

```swift
// BoardEngine/Sources/BoardEngine/Canvas/BoardCanvasState.swift
import SwiftUI
import Observation

@Observable
@MainActor
public class BoardCanvasState {
    // Canvas transform
    public var scale: CGFloat = 1.0
    public var offset: CGSize = .zero

    // Selection state
    public var selectedNodeIDs: Set<UUID> = []
    public var selectedEdgeIDs: Set<UUID> = []

    // Interaction state
    public var isDraggingNode: Bool = false
    public var draggedNodeID: UUID?
    public var dragOffset: CGSize = .zero

    // Edge creation
    public var isCreatingEdge: Bool = false
    public var edgeStartNodeID: UUID?
    public var edgePreviewEndPoint: CGPoint?

    public init() {}

    // MARK: - Transform Methods

    public func zoomIn() {
        scale = min(scale * 1.2, 5.0)
    }

    public func zoomOut() {
        scale = max(scale / 1.2, 0.2)
    }

    public func resetZoom() {
        scale = 1.0
    }

    public func panBy(delta: CGSize) {
        offset = CGSize(
            width: offset.width + delta.width,
            height: offset.height + delta.height
        )
    }

    // MARK: - Selection Methods

    public func selectNode(_ nodeID: UUID, additive: Bool = false) {
        if additive {
            selectedNodeIDs.insert(nodeID)
        } else {
            selectedNodeIDs = [nodeID]
            selectedEdgeIDs = []
        }
    }

    public func deselectAll() {
        selectedNodeIDs = []
        selectedEdgeIDs = []
    }

    // MARK: - Drag Methods

    public func beginDrag(nodeID: UUID) {
        isDraggingNode = true
        draggedNodeID = nodeID
        dragOffset = .zero
    }

    public func updateDrag(delta: CGSize) {
        guard isDraggingNode else { return }
        dragOffset = CGSize(
            width: dragOffset.width + delta.width / scale,
            height: dragOffset.height + delta.height / scale
        )
    }

    public func endDrag() {
        isDraggingNode = false
        draggedNodeID = nil
        dragOffset = .zero
    }

    // MARK: - Edge Creation Methods

    public func beginEdgeCreation(from nodeID: UUID) {
        isCreatingEdge = true
        edgeStartNodeID = nodeID
        edgePreviewEndPoint = nil
    }

    public func updateEdgePreview(endPoint: CGPoint) {
        edgePreviewEndPoint = endPoint
    }

    public func endEdgeCreation() {
        isCreatingEdge = false
        edgeStartNodeID = nil
        edgePreviewEndPoint = nil
    }
}
```

**Step 1.3: Implement Gesture Handling**

```swift
// BoardEngine/Sources/BoardEngine/Canvas/BoardCanvasGestures.swift
import SwiftUI

public struct BoardCanvasGestures {
    let canvasState: BoardCanvasState

    public init(canvasState: BoardCanvasState) {
        self.canvasState = canvasState
    }

    // MARK: - Pan Gesture

    public func panGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                canvasState.panBy(delta: value.translation)
            }
    }

    // MARK: - Zoom Gesture

    public func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                canvasState.scale *= value
                canvasState.scale = min(max(canvasState.scale, 0.2), 5.0)
            }
    }

    // MARK: - Node Drag Gesture

    public func nodeDragGesture<Node: BoardNode>(
        node: Node,
        dataSource: any BoardDataSource<Node, _, _>
    ) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !canvasState.isDraggingNode {
                    canvasState.beginDrag(nodeID: node.id)
                }
                canvasState.updateDrag(delta: value.translation)
            }
            .onEnded { _ in
                if let draggedID = canvasState.draggedNodeID,
                   let currentNode = dataSource.getAllNodes().first(where: { $0.id == draggedID }) {
                    let newPosition = CGPoint(
                        x: (currentNode.boardPosition?.x ?? 0) + canvasState.dragOffset.width,
                        y: (currentNode.boardPosition?.y ?? 0) + canvasState.dragOffset.height
                    )
                    try? dataSource.updateNodePosition(nodeID: draggedID, position: newPosition)
                }
                canvasState.endDrag()
            }
    }
}
```

**Step 1.4: Implement Auto-Layout (Optional but valuable)**

```swift
// BoardEngine/Sources/BoardEngine/Layout/ForceDirectedLayout.swift
import Foundation

/// Force-directed graph layout algorithm (Fruchterman-Reingold)
public class ForceDirectedLayout {
    public struct LayoutNode {
        var id: UUID
        var position: CGPoint
        var velocity: CGPoint = .zero
    }

    public struct LayoutEdge {
        var sourceID: UUID
        var targetID: UUID
    }

    private let iterations: Int
    private let optimalDistance: CGFloat
    private let repulsionStrength: CGFloat
    private let attractionStrength: CGFloat

    public init(
        iterations: Int = 50,
        optimalDistance: CGFloat = 100,
        repulsionStrength: CGFloat = 5000,
        attractionStrength: CGFloat = 0.1
    ) {
        self.iterations = iterations
        self.optimalDistance = optimalDistance
        self.repulsionStrength = repulsionStrength
        self.attractionStrength = attractionStrength
    }

    public func layout(
        nodes: inout [LayoutNode],
        edges: [LayoutEdge],
        canvasSize: CGSize
    ) {
        for _ in 0..<iterations {
            // Reset forces
            var forces = [UUID: CGPoint]()
            for node in nodes {
                forces[node.id] = .zero
            }

            // Repulsion between all nodes
            for i in 0..<nodes.count {
                for j in (i+1)..<nodes.count {
                    let delta = CGPoint(
                        x: nodes[i].position.x - nodes[j].position.x,
                        y: nodes[i].position.y - nodes[j].position.y
                    )
                    let distance = max(sqrt(delta.x * delta.x + delta.y * delta.y), 1.0)
                    let repulsion = repulsionStrength / (distance * distance)

                    let forceX = (delta.x / distance) * repulsion
                    let forceY = (delta.y / distance) * repulsion

                    forces[nodes[i].id]!.x += forceX
                    forces[nodes[i].id]!.y += forceY
                    forces[nodes[j].id]!.x -= forceX
                    forces[nodes[j].id]!.y -= forceY
                }
            }

            // Attraction along edges
            for edge in edges {
                guard let sourceNode = nodes.first(where: { $0.id == edge.sourceID }),
                      let targetNode = nodes.first(where: { $0.id == edge.targetID }) else {
                    continue
                }

                let delta = CGPoint(
                    x: targetNode.position.x - sourceNode.position.x,
                    y: targetNode.position.y - sourceNode.position.y
                )
                let distance = sqrt(delta.x * delta.x + delta.y * delta.y)
                let attraction = attractionStrength * (distance - optimalDistance)

                let forceX = (delta.x / distance) * attraction
                let forceY = (delta.y / distance) * attraction

                forces[sourceNode.id]!.x += forceX
                forces[sourceNode.id]!.y += forceY
                forces[targetNode.id]!.x -= forceX
                forces[targetNode.id]!.y -= forceY
            }

            // Apply forces
            for i in 0..<nodes.count {
                nodes[i].position.x += forces[nodes[i].id]!.x
                nodes[i].position.y += forces[nodes[i].id]!.y

                // Keep within canvas bounds
                nodes[i].position.x = max(50, min(nodes[i].position.x, canvasSize.width - 50))
                nodes[i].position.y = max(50, min(nodes[i].position.y, canvasSize.height - 50))
            }
        }
    }
}
```

### Phase 2: Adapt Cumberland to Use BoardEngine (Week 3)

**Step 2.1: Make Card/CardEdge Conform to Protocols**

```swift
// Cumberland/Model/Card+BoardNode.swift
import BoardEngine

extension Card: BoardNode {
    public var boardPosition: CGPoint? {
        get {
            guard let x = boardX, let y = boardY else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            if let position = newValue {
                boardX = position.x
                boardY = position.y
            } else {
                boardX = nil
                boardY = nil
            }
        }
    }

    public var isOnBoard: Bool {
        boardX != nil && boardY != nil
    }

    public var subtitle: String? {
        self.subtitleText
    }

    public var imageData: Data? {
        self.thumbnailData
    }
}

// Cumberland/Model/CardEdge+BoardEdge.swift
extension CardEdge: BoardEdge {
    public var sourceNodeID: UUID {
        source.id
    }

    public var targetNodeID: UUID {
        target.id
    }

    public var edgeTypeName: String {
        relationType?.displayName ?? "related-to"
    }

    public var edgeTypeForward: String {
        relationType?.forwardVerb ?? "relates-to"
    }

    public var edgeTypeInverse: String {
        relationType?.inverseVerb ?? "related-to"
    }
}

// Cumberland/Model/RelationType+BoardEdgeType.swift
extension RelationType: BoardEdgeType {
    public var forwardVerb: String {
        // Parse from displayName "owns/owned-by" → "owns"
        displayName.split(separator: "/").first.map(String.init) ?? displayName
    }

    public var inverseVerb: String {
        // Parse from displayName "owns/owned-by" → "owned-by"
        let parts = displayName.split(separator: "/")
        return parts.count > 1 ? String(parts[1]) : displayName
    }
}
```

**Step 2.2: Create Cumberland BoardDataSource**

```swift
// Cumberland/Murderboard/CumberlandBoardDataSource.swift
import SwiftData
import BoardEngine

@MainActor
class CumberlandBoardDataSource: BoardDataSource {
    typealias Node = Card
    typealias Edge = CardEdge
    typealias EdgeType = RelationType

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func getAllNodes() -> [Card] {
        let descriptor = FetchDescriptor<Card>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getNodesOnBoard() -> [Card] {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.boardX != nil && $0.boardY != nil }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getNodesNotOnBoard() -> [Card] {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.boardX == nil || $0.boardY == nil }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getEdges(for node: Card) -> [CardEdge] {
        return node.allEdges
    }

    func getAllEdges() -> [CardEdge] {
        let descriptor = FetchDescriptor<CardEdge>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getAllEdgeTypes() -> [RelationType] {
        let descriptor = FetchDescriptor<RelationType>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func updateNodePosition(nodeID: UUID, position: CGPoint) throws {
        guard let card = try modelContext.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == nodeID })
        ).first else {
            throw BoardDataSourceError.nodeNotFound
        }

        card.boardX = position.x
        card.boardY = position.y
        try modelContext.save()
    }

    func addNodeToBoard(nodeID: UUID) throws {
        guard let card = try modelContext.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == nodeID })
        ).first else {
            throw BoardDataSourceError.nodeNotFound
        }

        // Set initial position (center or smart placement)
        card.boardX = 400
        card.boardY = 300
        try modelContext.save()
    }

    func removeNodeFromBoard(nodeID: UUID) throws {
        guard let card = try modelContext.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == nodeID })
        ).first else {
            throw BoardDataSourceError.nodeNotFound
        }

        card.boardX = nil
        card.boardY = nil
        try modelContext.save()
    }

    func createEdge(fromID: UUID, toID: UUID, edgeTypeID: UUID) throws {
        // Use existing RelationshipManager from ER-0022
        // Or implement directly here
        guard let source = try modelContext.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == fromID })
        ).first,
              let target = try modelContext.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == toID })
        ).first,
              let edgeType = try modelContext.fetch(
            FetchDescriptor<RelationType>(predicate: #Predicate { $0.id == edgeTypeID })
        ).first else {
            throw BoardDataSourceError.invalidParameters
        }

        let edge = CardEdge(source: source, target: target, relationType: edgeType)
        modelContext.insert(edge)
        try modelContext.save()
    }

    func deleteEdge(edgeID: UUID) throws {
        guard let edge = try modelContext.fetch(
            FetchDescriptor<CardEdge>(predicate: #Predicate { $0.id == edgeID })
        ).first else {
            throw BoardDataSourceError.edgeNotFound
        }

        modelContext.delete(edge)
        try modelContext.save()
    }
}

enum BoardDataSourceError: Error {
    case nodeNotFound
    case edgeNotFound
    case invalidParameters
}
```

**Step 2.3: Refactor MurderBoardView to Use BoardEngine**

```swift
// Cumberland/Murderboard/MurderBoardView.swift (refactored)
import SwiftUI
import BoardEngine

struct MurderBoardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var canvasState = BoardCanvasState()
    @State private var dataSource: CumberlandBoardDataSource?

    var body: some View {
        ZStack {
            // Canvas
            if let dataSource = dataSource {
                BoardCanvasView(
                    canvasState: canvasState,
                    dataSource: dataSource
                )
            }

            // Sidebar
            BacklogSidebarPanel(
                canvasState: canvasState,
                dataSource: dataSource
            )
        }
        .onAppear {
            if dataSource == nil {
                dataSource = CumberlandBoardDataSource(modelContext: modelContext)
            }
        }
    }
}

// Use generic BoardCanvasView from BoardEngine package
```

**Code Reduction in Cumberland:** MurderBoardView: 1,386 → ~300 lines (moved to BoardEngine package)

### Phase 3: Create Standalone Murderboard App (Week 4-5)

**Step 3.1: Create Murderboard Target in Workspace**

1. In `CumberlandWorkspace.xcworkspace`
2. File > New > Target
3. Choose "App" template
4. Name: "Murderboard"
5. Add BoardEngine package dependency

**Step 3.2: Create Murderboard Data Models**

```swift
// Murderboard/Models/InvestigationProject.swift
import SwiftData
import Foundation

@Model
class InvestigationProject {
    var id: UUID
    var name: String
    var description: String?
    var createdDate: Date
    var modifiedDate: Date

    @Relationship(deleteRule: .cascade)
    var nodes: [InvestigationNode]?

    @Relationship(deleteRule: .cascade)
    var edges: [InvestigationEdge]?

    @Relationship(deleteRule: .cascade)
    var edgeTypes: [EdgeType]?

    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.createdDate = Date()
        self.modifiedDate = Date()
    }
}

// Murderboard/Models/InvestigationNode.swift
import SwiftData
import BoardEngine

@Model
class InvestigationNode {
    var id: UUID
    var name: String
    var subtitle: String?
    var notes: String?

    @Attribute(.externalStorage)
    var imageData: Data?

    var boardX: Double?
    var boardY: Double?

    @Relationship(inverse: \InvestigationProject.nodes)
    var project: InvestigationProject?

    init(name: String, subtitle: String? = nil) {
        self.id = UUID()
        self.name = name
        self.subtitle = subtitle
    }
}

extension InvestigationNode: BoardNode {
    var boardPosition: CGPoint? {
        get {
            guard let x = boardX, let y = boardY else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            if let position = newValue {
                boardX = position.x
                boardY = position.y
            } else {
                boardX = nil
                boardY = nil
            }
        }
    }

    var isOnBoard: Bool {
        boardX != nil && boardY != nil
    }
}

// Similar for InvestigationEdge and EdgeType...
```

**Step 3.3: Implement Murderboard BoardDataSource**

(Similar to Cumberland's but using InvestigationNode/Edge instead of Card/CardEdge)

**Step 3.4: Create Murderboard UI**

Main views:
- `ProjectListView` - List of investigation projects
- `BoardView` - Main board canvas (uses BoardEngine)
- `NodeLibraryView` - Sidebar with all nodes
- `NodeDetailView` - Edit node details

**Total New Code for Standalone Murderboard:** ~2,000 lines

---

## Success Criteria

- [ ] BoardEngine package created and tested
- [ ] Cumberland adapted to use BoardEngine
- [ ] Cumberland Murderboard still works (no regressions)
- [ ] Standalone Murderboard app created
- [ ] Murderboard app has independent data model
- [ ] Both apps can use same BoardEngine package
- [ ] Auto-layout feature works
- [ ] Documentation complete

---

## Risks and Mitigations

### Risk 1: Very High Complexity

**Risk:** This is the most complex extraction of all ERs

**Mitigation:**
- ER-0022 MUST be complete first (data layer abstraction)
- Extensive testing at each phase
- Consider this lower priority (do after other ERs)

### Risk 2: Limited Market for Standalone Murderboard

**Risk:** May not justify the effort if market is small

**Mitigation:**
- Research market demand first
- Consider as "nice to have" rather than priority
- Could be beneficial for law enforcement/journalism

### Risk 3: Protocol Abstraction May Limit Features

**Risk:** Generic protocols may not support all Cumberland features

**Mitigation:**
- Start with MVP feature set
- Add protocol extensions as needed
- Cumberland can still use Card-specific features directly

---

## Timeline Estimate

**Total Duration:** 5 weeks (most complex ER)

- **Week 1-2:** Create BoardEngine package
- **Week 3:** Adapt Cumberland to use BoardEngine
- **Week 4-5:** Create standalone Murderboard app

---

## Dependencies

**Required:**
- ER-0022 (Code refactoring) **MUST be complete first**

**Recommended:**
- ER-0023 (ImageProcessing package) - useful for node images

---

## Future Enhancements

1. **Advanced Layouts:** Hierarchical, circular, timeline-based
2. **Collaboration:** Multi-user boards
3. **Export:** PDF, image, data export
4. **Import:** CSV, JSON data import
5. **Templates:** Pre-built board templates for common use cases
6. **Mobile Apps:** iOS/iPadOS versions

---

**Priority Recommendation:** **LOW** - Do this after ER-0022, 0023, 0024, 0025

**Rationale:** While interesting, this is the most complex extraction and has uncertain market value. Focus on higher-ROI extractions first (Map Generation → Storyscapes has clear market value).

---

*Last Updated: 2026-02-03*
