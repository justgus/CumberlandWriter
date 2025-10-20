//
//  MurderBoardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/19/25.
//

/*
Requirements: MurderBoardView
Spec Version: 1.3
Last Updated: 2025-10-20

Authoritative Specification (verbatim - this is the source of truth for all implementation details)

Definitions and Invariants (non-numbered, normative where referenced)
- Coordinate spaces:
  - View space: origin at the View Window’s top-left; +x to the right; +y downward.
  - World space: an independent, conceptually unbounded Cartesian plane measured in points; +x to the right; +y downward.
- Transform:
  - World→View mapping is v = w*S + T, where S is the scalar zoom factor and T = (Tx, Ty) is the view-space translation (pan).
  - The View Canvas Rectangle is the exact inverse image of the View Window’s bounds under the current transform (see 0080, 0110).
- Z-ordering (0232):
  1) Grid background (bottommost), 2) Edges, 3) CardViews (nodes), 4) selection/interaction overlays (topmost).
- Reset operation:
  - A reset is an explicit action that removes all nodes from the board. During and immediately after reset, primary presence enforcement is suspended (0286).
- Primary enforcement:
  - When enforcement is active and a Primary is set, the Primary must be present as a node; the system may auto-create a BoardNode if missing.

The Murderboard View
 0010 - The View shall be a Window to a View Canvas
 0020 - The View Window shall have a rounded rectangular border around it at least 10 points thick that separates its contents from the enclosing application.
 0030 - The View Window Border shall have a visible inner drop shadow. so that it appears above the view it is showing and the View Canvas appears inside the border.
 0040 - The View Window and its border shall fill the contents of its parent view
 0050 - The View Window shall provide a view of its content called the View Canvas.
 
 View Canvas
 0060 - There shall be view inside the View Window called the View Canvas.
 0061 - The View Canvas shall appear infinite in size.  That is, at no time will the border of the View Canvas be visible in the View Window.
 0065 - The View Canvas shall define an independent, unbounded world coordinate system.
 0066 - The pan translation T may be clamped to an implementation-defined range large enough to cover the Nodes Extents (0150) plus the margin defined in 0405 under all expected pans/zooms.
 0070 - The View Window shall present a rectangular viewport into this world. The visible region of the world is called the View Canvas Rectangle.
 0080 - The View Canvas Rectangle shall be defined as the exact inverse image of the View Window’s bounds under the current pan and zoom transform; i.e., after applying the world-to-view transform, the View Canvas Rectangle maps exactly to the View Window’s bounds, so it always fills the View Window regardless of pan or zoom. The inverse mapping shall be computed analytically from the current transform.
 0090 - As the zoom factor decreases (zooming out), the View Canvas Rectangle shall increase in size while keeping its center locked to the View Window's center (see 0330).
 0100 - The zoom factor expansion shall not move or resize the View Window in its parent; only the mapping changes.
 0110 - The View Canvas shall continuously recompute the View Canvas Rectangle whenever the View Window size, pan, or zoom changes. The recomputed rectangle shall be consistent with the current transform and shall remain the unique world-space rectangle that maps exactly to the View Window’s bounds.
 0120 - The View Canvas shall display nodes and edges.
 0130 - The View Canvas nodes shall be Cards that are displayed using a CardView.
 0140 - The View Canvas shall maintain a point in world coordinates representing the center of the View Window’s position.
 0150 - Node, their positions in the View Canvas, and their size, will be used to calculate a Nodes Extents rectangle that encompasses all Nodes currently in the View Canvas
 0160 - The Nodes Extents rectangle shall take into consideration the size of the CardView when calculating the area to enclose, using each CardView’s world-space bounding box, including any necessary padding for shadows and selection borders.
 0170 - When new nodes are added to the view, nodes are moved to new positions, or removed from the view, the Nodes Extents Rectangle shall be recalculated.
 0180 - There shall be an optional “primary” node that will be a Card selected from a list in the Main App’s Content List.
 0190 - Edges in the View Canvas shall be line segments representing a CardEdge source to target relationship between two Cards that have been added to the view.
 0200 - Even if the Cards have more than one relationship between them, only one line segment shall represent the relationship between the two Cards in the View Canvas.
 0202 - If multiple relationships exist between the same two Cards, the single displayed edge shall be chosen deterministically (e.g., by a RelationType priority list; if tied, by earliest creation date; if unavailable, by a stable UUID order). Unless otherwise specified, the edge is visually undirected and carries no label.
 0210 - Edges shall be straight line segments that span from the center of the source CardView to the center of the target CardView.
 0220 - Edges shall be at least three points thick and shall remain clearly visible against the View Canvas background in both light and dark appearances.
 0225 - Edges and selection borders shall maintain sufficient contrast in both light and dark appearances; colors shall adapt to system appearance.
 0230 - Edges on the murder board shall be displayed just behind the CardViews.
 0232 - Z-order shall be: (1) the Grid background (bottommost), (2) Edges, (3) CardViews (nodes), and (4) selection/interaction overlays (topmost).
 
 Behavior
 0240 - On first display of the MurderBoardView, if a target node exists (the Primary if present, otherwise the first node), the View Canvas shall automatically pan so that the target node’s world position is projected to the geometric center of the View Window.
 0241 - On first display, apply 0405 so the View Canvas Grid is sized such that its edges are not visible in the View Window.
 0250 - The initial recentering shall occur once per initial display and shall not change the zoom level.
 0260 - If the Primary or first node’s stored world position is uninitialized (e.g., nullable coordinates or an explicit “uninitialized” flag), its position shall first be set to the center of the current View Canvas Rectangle.
 0270 - Once the uninitialized position is reset, the View Window shall be panned so that this position is centered in the View Window.
 0280 - Except during a reset operation (0284), the Primary, if present, shall not be removed from the View Canvas. If not present, then all nodes may be removed from the board.
 0282 - If the Primary is changed, the View Canvas shall update the display.
 0284 - If the view is reset (i.e., all nodes removed), then the Primary may be removed and the Board’s primaryCard may be cleared.
 0286 - During and immediately after a reset operation, automatic primary presence enforcement shall be suspended until a new Primary is explicitly assigned. If the Primary card is deleted from the database, the board’s primaryCard shall be cleared and enforcement suspended until a new Primary is assigned.
 0300 - Zoom shall not change node world positions; only the mapping between world and view coordinates changes.
 0310 - When the parent view’s size changes, the View Window shall resize to fill its parent (0040), recompute the View Canvas Rectangle (0110), and preserve the current zoom/pan mapping semantics.
 0330 - When Zooming, the View Canvas's center point will remain fixed to the View Window's Center point; pan shall be adjusted analytically to maintain this invariant.
 0340 - Nodes in the View Canvas shall be selectable.
 0350 - When selected, the Card’s CardView shall display a border over it in the accent color of the Cumberland App.
 0360 - Nodes shall be able to be dragged via a standard click drag gesture on the Node
 0370 - When a node in the View Canvas is dragged, its position shall be updated based on the pointer's location over the View Canvas Rectangle, taking zoom and pan into account, and preserving the initial grab offset so the node follows the pointer smoothly.
 0380 - The View Canvas shall be able to be panned via a standard click drag operation on the View Canvas surface
 0390 - When the background area of the View Canvas is dragged it shall allow the whole view to be panned
 0400 - Per 0040, the View Canvas shall always resize itself to fill the View Window regardless of the pan or zoom factor.
 0402 - The View Canvas shall have a background surface called the View Canvas Grid, consisting of a low-contrast grid (bottommost) and the Edges (above the grid, but below the nodes).
 0405 - The View Canvas Grid shall be sized in world space to fully cover the union of (a) the current View Canvas Rectangle (0080) and (b) the Nodes Extents Rectangle (0150), inflated on all sides by a zoom-aware margin M sufficient to prevent drawing-surface edges from becoming visible during pan or zoom. M shall be at least one View Window diagonal expressed in world units (windowDiagonal / S), or 2×tileSize, whichever is larger.
 
 Controls
 0410 - The View Window shall have a toolbar.
 0420 - The View Window toolbar shall include a zoom control.
 0430 - The zoom control shall allow the specification of zoom percentages from 1% to 200% with 100% being the default.
 0435 - The zoom factor S shall be clamped to the inclusive range [0.01, 2.0]. Text entry shall clamp to [1, 200]% and round to the nearest integer percent; non-numeric input is ignored.
 0440 - The toolbar shall have a “recenter” button.
 0450 - the recenter button shall pan the View Canvas so that the first node, or the primary node if one is present, is in the center of the View Window.
 0452 - If the target node’s position is uninitialized, it shall be initialized per 0260 prior to recentering. Recenter shall not change the zoom level (0250).
 0460 - The toolbar shall have a “shuffle” button.
 0470 - the shuffle button shall gather all the nodes around the first node, or the primary node if one is present in a random arrangement.
 0475 - Shuffle shall preserve the Primary’s position (if present) and reposition all other nodes in world coordinates. New positions shall be persisted; edges shall update automatically from node centers.
 0480 - repeated clicks of the shuffle button will change the position of all the nodes in the arrangement.
 
Persistence
 0490 - The Murderboards shall persist in the database using the Board model object
 0500 - There shall be a helper object, called a BoardNode
 0510 - The BoardNode shall bridge the relationship between Cards and Boards
 0520 - The relationship between Cards and Boards shall be a many-to-many relationship
 0530 - Cards shall be able to have no Boards that they appear in.
 0540 - Boards shall be able to be displayed with no Cards as nodes unless a Primary is set; during a reset operation, the Primary may be removed and/or cleared.
 0550 - Nodes in the View Canvas shall be persisted in the database using a fully inverted relationship between Card and Board.
 0560 - Selection of a Card in the View Canvas shall persist until the operator clicks on another Card, at which point selection shall switch to the card clicked.
 0570 - Selection of a Card in the View Canvas shall persist until the operator clicks in the Canvas area of the View Canvas, at which point the selection shall be dropped and no Card is selected.
 0572 - Node centers shall be stored in the backing model in world coordinates. Edge endpoints shall be derived at render-time from the current node centers; explicit endpoint persistence is not required.
 0574 - Absolute or zoom-derived node sizes shall not be stored in the backing model; an optional categorical size override (e.g., compact/standard/large) may be persisted per node.
 0575 - If the selected node is removed from the board or becomes non-visible, the selection shall be cleared.
 
The Sidebar
 0580 - The View shall have a floating Sidebar list, called the Backlog
 0590 - The Backlog Sidebar panel shall be semi translucent, so that content behind it can still be made out.
 0600 - The Backlog shall potentially consist of every Card in the Database
 0610 - The Backlog shall not include any Cards that are currently included in the Murderboard View Canvas backing store.
 0620 - The Backlog shall include a drop down picker allowing the list to be filtered by Kind.
 0630 - The drop down picker in the Backlog shall consist of items in the Kind enum and equate to Card.kind
 0640 - Selecting an item in the Backlog’s Drop Down Picker shall cause the Backlog to be filtered by the selected Card.kind
 0650 - The Backlog rows shall display Card names, the Kind icon, and, if available, small image thumbnails.
 0660 - There shall be a button next to the floating Sidebar panel
 0670 - The floating Sidebar Panel Button shall be visible even if the Sidebar is hidden
 0680 - Clicking or tapping the Sidebar Panel Button shall toggle the visibility of the Backlog
 0690 - Cards shown in the Backlog shall be able to be dragged onto the Murderboard View Canvas.
 0700 - When a Card is dragged from the Backlog into the Murderboard View Canvas, a new node shall be added to the Murderboard View Canvas
 0710 - During the drag operation from the Backlog to the View Canvas, when the cursor is hovering over the View Canvas, a blue Drop Target indicator shall appear indicating to the operator that the Canvas is a valid Drop Target for the Selected Backlog Card.

 Requriements Proposed Changes (keep this section)
 - Incorporated changes into the Authoritative Specification above (Spec Version 1.3). Summary:
   - Added Definitions and Invariants for coordinate spaces, transform, Z-order, reset, and primary enforcement.
   - Clarified grid “infinite” behavior and sizing (0241 references 0405; 0405 adds quantified margin M).
   - Clarified pan policy with implementation-defined clamping tied to Nodes Extents + margin (0066).
   - Made center-locked zoom canonical (0330) and referenced by 0090; added zoom factor clamping and input rules (0435).
   - Clarified “reshape” semantics on parent size change (0310); made 0400 reference 0040.
   - Clarified uninitialized node position (0260) without relying on a specific (0,0) sentinel; recenter button handles it (0452).
   - Clarified Primary presence vs reset exceptions and DB deletion handling (0280, 0286).
   - Added accessibility/contrast requirement (0225).
   - Clarified nodes extents to include padding for shadows/borders (0160).
   - Clarified edge determinism (0202) and removed need to persist edge endpoints (0572).
   - Added selection clearing on removal/non-visibility (0575).
   - Specified shuffle semantics, persistence, and primary preservation (0475).
   - Sidebar clarifications retained; DnD indicator behavior unchanged.

 Acceptance Criteria

 
 Implementation Plan
 
 */

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CloudKit

struct MurderBoardView: View {
    let primary: Card

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Persisted board for this primary
    @State private var board: Board?

    // Live transform state (mirrors board.zoomScale/panX/panY; persisted on changes)
    @State private var zoomScale: Double = 1.0   // S
    @State private var panX: Double = 0.0        // T.x (view points)
    @State private var panY: Double = 0.0        // T.y (view points)

    // Selection (single)
    @State private var selectedCardID: UUID? = nil

    // One-time initial recenter
    @State private var didInitialRecenter: Bool = false

    // Node drag state: preserve grab offset in world coordinates
    @State private var draggingNodeID: UUID? = nil
    @State private var dragGrabOffsetWorld: CGPoint = .zero

    // Canvas pan gesture transient
    @State private var panGestureStart: CGPoint?

    // Node-drag gesture recognition flag (preempts background pan reliably)
    @GestureState private var nodeDragActive: Bool = false

    // Named coordinate space for consistent gesture math (canvas/view space)
    private let canvasCoordSpace = "MurderBoardCanvasSpace"

    init (primary: Card) {
        self.primary = primary
    }

    var body: some View {

    }
}

// MARK: - Constants

private let windowCornerRadius: CGFloat = 18
private let windowBorderWidth: CGFloat = 12

private var windowBorderColor: Color { .secondary.opacity(0.55) }
private var windowInnerShadowColor: Color { .white.opacity(0.18) }

// MARK: - Canvas

private extension MurderBoardView {
    // World→View transform: v = w*S + T
    func worldToView(_ world: CGPoint) -> CGPoint {
        let s = zoomScale
        return CGPoint(x: world.x.dg * s + panX, y: world.y.dg * s + panY)
    }

    // View→World inverse: w = (v − T)/S
    func viewToWorld(_ view: CGPoint) -> CGPoint {
        let s = max(zoomScale, 0.000001)
        return CGPoint(x: (view.x.dg - panX) / s, y: (view.y.dg - panY) / s)
    }

    // View Canvas Rectangle in world coordinates (0080)
    func viewCanvasRect(worldForWindowSize size: CGSize) -> CGRect {
        let originWorld = viewToWorld(.zero)
        let s = max(zoomScale, 0.000001)
        let wWorld = size.width.dg / s
        let hWorld = size.height.dg / s
        return CGRect(x: originWorld.x, y: originWorld.y, width: wWorld, height: hWorld)
    }

    // World center corresponding to the View Window’s geometric center (0140)
    func worldCenter(forWindowSize size: CGSize) -> CGPoint {
        let cView = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        return viewToWorld(cView)
    }

    @ViewBuilder
    func canvasLayer(windowSize: CGSize, windowCenter: CGPoint) -> some View {
        ZStack {
            // Background: keep “infinite” appearance by not drawing finite edges (0061, 0241)
            Rectangle()
                .fill(scheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.04))
                .contentShape(Rectangle()) // ensure hit-testing across the full rect
                .gesture(canvasPanGesture()) // attach pan directly to the background
                .ignoresSafeArea()

            // Nodes layer (0120, 0130, 0340–0390)
            nodesLayer(windowSize: windowSize)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Nodes

    @ViewBuilder
    func nodesLayer(windowSize: CGSize) -> some View {
        let nodes = (board?.nodes ?? []).compactMap { node -> (BoardNode, Card)? in
            guard let c = node.card else { return nil }
            return (node, c)
        }

        // Apply the world→view transform to the entire nodes layer so positions and sizes scale together.
        ZStack {
            ForEach(nodes, id: \.0.id) { pair in
                let node = pair.0
                let card = pair.1
                let nodeCenterWorld = CGPoint(x: node.posX, y: node.posY)

                CardView(card: card)
                    .overlay(
                        // Selection border (0350) in app AccentColor
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: selectedCardID == card.id ? 4 : 0)
                            .animation(.easeInOut(duration: 0.12), value: selectedCardID)
                    )
                    // Position the CardView by its world-space center; the layer transform maps to view.
                    .position(nodeCenterWorld)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCardID = card.id
                    }
                    // Make node drag win over background pan and internal controls.
                    .highPriorityGesture(nodeDragGesture(node: node, card: card))
                    .zIndex(
                        (draggingNodeID == card.id ? 2 : 0) +
                        (selectedCardID == card.id ? 1 : 0)
                    )
            }
        }
        .scaleEffect(zoomScale)
        .offset(x: panX.cg, y: panY.cg)
        // Hit testing remains in view space; gestures convert using viewToWorld as needed.
    }
}

// MARK: - Gestures

private extension MurderBoardView {
    func canvasPanGesture() -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named(canvasCoordSpace))
            .onChanged { value in
                // If a node is currently being dragged, ignore background panning.
                guard draggingNodeID == nil, nodeDragActive == false else { return }
                if panGestureStart == nil {
                    panGestureStart = CGPoint(x: panX.cg, y: panY.cg)
                }
                if let start = panGestureStart {
                    panX = (start.x + value.translation.width).dg
                    panY = (start.y + value.translation.height).dg
                }
            }
            .onEnded { _ in
                panGestureStart = nil
                persistTransformNow()
            }
    }

    func nodeDragGesture(node: BoardNode, card: Card) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .named(canvasCoordSpace))
            .updating($nodeDragActive) { _, state, _ in
                // Mark node drag as active as soon as the gesture updates begin
                state = true
            }
            .onChanged { value in
                // Initialize grab offset on the first change of this drag (translation == .zero)
                if value.translation == .zero {
                    draggingNodeID = card.id
                    let startPointerWorld = viewToWorld(value.startLocation)
                    let nodeCenterWorld = CGPoint(x: node.posX, y: node.posY)
                    dragGrabOffsetWorld = CGPoint(
                        x: nodeCenterWorld.x - startPointerWorld.x,
                        y: nodeCenterWorld.y - startPointerWorld.y
                    )
                }
                // Update node position: pointerWorld + grabOffset
                let pointerWorld = viewToWorld(value.location)
                let newCenter = CGPoint(
                    x: pointerWorld.x + dragGrabOffsetWorld.x,
                    y: pointerWorld.y + dragGrabOffsetWorld.y
                )
                node.posX = newCenter.x.dg
                node.posY = newCenter.y.dg
                try? modelContext.save()
            }
            .onEnded { _ in
                draggingNodeID = nil
                dragGrabOffsetWorld = .zero
            }
    }
}

// MARK: - Toolbar

private extension MurderBoardView {
    @ToolbarContentBuilder
    func toolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            // Zoom Out
            Button {
                stepZoom(-0.05, windowSize: windowSize)
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")
            .keyboardShortcut("-", modifiers: [.command])

            // Slider (1%–200%)
            Slider(value: Binding(
                get: { zoomScale },
                set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
            ), in: Board.minZoom...Board.maxZoom)
            .frame(width: 160)
            .help("Zoom")

            // Zoom In
            Button {
                stepZoom(+0.05, windowSize: windowSize)
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
            .keyboardShortcut("=", modifiers: [.command])

            // Percent field
            HStack(spacing: 6) {
                TextField(
                    "Zoom %",
                    text: Binding(
                        get: { "\(Int(round(zoomScale * 100)))" },
                        set: { raw in
                            if let v = Double(raw) {
                                let s = (v / 100.0).clamped(to: Board.minZoom...Board.maxZoom)
                                setZoomKeepingCenter(s, windowSize: windowSize)
                            }
                        }
                    )
                )
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                Text("%")
                    .foregroundStyle(.secondary)
            }
            .help("Enter zoom percentage (1–200)")

            Divider()

            // Recenter on primary/first node
            Button {
                recenterOnPrimaryOrFirst(windowSize: windowSize)
            } label: {
                Label("Recenter", systemImage: "dot.scope")
            }
            .help("Recenter on primary (or first) node")

            // Shuffle arrangement around primary
            Button {
                shuffleAroundPrimary()
            } label: {
                Label("Shuffle", systemImage: "arrow.triangle.2.circlepath")
            }
            .help("Arrange nodes around the primary in a ring; repeat to reshuffle")
        }
    }

    func stepZoom(_ delta: Double, windowSize: CGSize) {
        let proposed = (zoomScale + delta).clamped(to: Board.minZoom...Board.maxZoom)
        setZoomKeepingCenter(proposed, windowSize: windowSize)
    }

    // Center-stable zoom (0330)
    func setZoomKeepingCenter(_ newScale: Double, windowSize: CGSize) {
        let sNew = newScale.rangeClamped(to: Board.minZoom...Board.maxZoom)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        let cWorld = viewToWorld(cView)
        // T' = C_v − (C_w * S')
        panX = (cView.x.dg - cWorld.x * sNew)
        panY = (cView.y.dg - cWorld.y * sNew)
        zoomScale = sNew
        persistTransformDebounced()
    }

    func recenterOnPrimaryOrFirst(windowSize: CGSize) {
        guard let b = board else { return }
        let nodePairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !nodePairs.isEmpty else { return }
        let primaryID = b.primaryCard?.id
        let targetNode: BoardNode = nodePairs.first(where: { $0.1.id == primaryID })?.0 ?? nodePairs.first!.0
        let world = CGPoint(x: targetNode.posX, y: targetNode.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        // Solve for pan so world maps to center at current zoom
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()
    }

    func shuffleAroundPrimary() {
        guard let b = board else { return }
        guard var nodes = b.nodes, !nodes.isEmpty else { return }

        // Choose anchor: primary or the first node
        let primaryID = b.primaryCard?.id
        let anchorNode = nodes.first(where: { $0.card?.id == primaryID }) ?? nodes.first!
        let anchor = CGPoint(x: anchorNode.posX, y: anchorNode.posY)

        // Exclude anchor from shuffling
        nodes.removeAll(where: { $0.id == anchorNode.id })

        // Basic ring layout with jitter; ring count grows with node count.
        let count = max(1, nodes.count)
        let ringCapacity = 12
        var remaining = count
        var radius: Double = 220
        var ringIndex = 0

        while remaining > 0 {
            let take = min(remaining, ringCapacity + ringIndex * 6) // slightly larger outer rings
            let angleStep = (2.0 * Double.pi) / Double(take)
            let startAngle = Double.random(in: 0..<(2.0 * Double.pi))
            for i in 0..<take {
                if let node = nodes.popLast() {
                    let theta = startAngle + Double(i) * angleStep
                    let jitterR = Double.random(in: -12...12)
                    let jitterT = Double.random(in: -0.20...0.20)
                    let r = radius + jitterR
                    let x = anchor.x + (r * cos(theta + jitterT))
                    let y = anchor.y + (r * sin(theta + jitterT))
                    node.posX = x
                    node.posY = y
                }
            }
            remaining = nodes.count
            ringIndex += 1
            radius += 180 // increase spacing for next ring
        }
        try? modelContext.save()
    }
}

// MARK: - Board load and transform persistence

private extension MurderBoardView {
    @MainActor
    func loadBoardIfNeeded() async {
        if board == nil {
            let b = Board.fetchOrCreatePrimaryBoard(for: primary, in: modelContext)
            b.clampState()
            board = b
            zoomScale = b.zoomScale
            panX = b.panX
            panY = b.panY
        }
    }

    func applyBoardTransform() {
        guard let b = board else { return }
        zoomScale = b.zoomScale
        panX = b.panX
        panY = b.panY
    }

    // Debounced persistence to reduce write churn during gestures
    func persistTransformDebounced() {
        // For simplicity here, persist immediately but clamped. Replace with debounce if needed.
        persistTransformNow()
    }

    func persistTransformNow() {
        guard let b = board else { return }
        b.zoomScale = zoomScale.rangeClamped(to: Board.minZoom...Board.maxZoom)
        b.panX = panX.rangeClamped(to: Board.minPan...Board.maxPan)
        b.panY = panY.rangeClamped(to: Board.minPan...Board.maxPan)
        b.clampState()
        try? modelContext.save()
    }

    // Initial recenter logic (0240–0280, 0250)
    func initialRecenterIfNeeded(on b: Board, windowSize: CGSize) {
        // Ensure node exists
        b.ensurePrimaryPresence(in: modelContext)

        // Find primary node or first node
        let pairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !pairs.isEmpty else {
            didInitialRecenter = true
            return
        }
        let primaryID = b.primaryCard?.id
        let target = pairs.first(where: { $0.1.id == primaryID })?.0 ?? pairs.first!.0

        // If uninitialized (0260), set it to center of current View Canvas Rectangle
        if abs(target.posX) < 0.0001 && abs(target.posY) < 0.0001 {
            let rect = viewCanvasRect(worldForWindowSize: windowSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            target.posX = center.x.dg
            target.posY = center.y.dg
            try? modelContext.save()
        }

        // Pan so that target maps to window center (no zoom change) (0240, 0250, 0270)
        let world = CGPoint(x: target.posX, y: target.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()

        didInitialRecenter = true
    }
}

// MARK: - Small helpers

private extension CGFloat {
    var dg: Double { Double(self) }
}

private extension Double {
    var cg: CGFloat { CGFloat(self) }
}

private extension CGSize {
    func dxClamped(min: Double, max: Double) -> Double {
        Double(width).rangeClamped(to: min...max)
    }
    func dyClamped(min: Double, max: Double) -> Double {
        Double(height).rangeClamped(to: min...max)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview("Murder Board (seeded)") {
    let schema = Schema([Card.self, Board.self, BoardNode.self, CardEdge.self, RelationType.self])
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [cfg])
    let ctx = container.mainContext
    ctx.autosaveEnabled = false

    let mira = Card(kind: .characters, name: "Mira", subtitle: "Explorer", detailedText: "")
    let jonas = Card(kind: .characters, name: "Jonas", subtitle: "Historian", detailedText: "")
    let aster = Card(kind: .characters, name: "Aster", subtitle: "Mechanic", detailedText: "")
    let eden = Card(kind: .worlds, name: "Eden-3", subtitle: "Frontier World", detailedText: "")
    let opening = Card(kind: .scenes, name: "Opening Scene", subtitle: "Crash Site", detailedText: "")
    let artifact = Card(kind: .artifacts, name: "Ancient Artifact", subtitle: "Unknown origin", detailedText: "")

    ctx.insert(mira)
    ctx.insert(jonas)
    ctx.insert(aster)
    ctx.insert(eden)
    ctx.insert(opening)
    ctx.insert(artifact)

    let appearsIn = RelationType(code: "appears-in/is-appeared-by",
                                 forwardLabel: "appears in",
                                 inverseLabel: "is appeared by",
                                 sourceKind: .characters,
                                 targetKind: .scenes)
    let references = RelationType(code: "references/referenced-by",
                                  forwardLabel: "references",
                                  inverseLabel: "referenced by")
    ctx.insert(appearsIn)
    ctx.insert(references)

    ctx.insert(CardEdge(from: mira, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: jonas, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: aster, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: mira, to: artifact, type: references))
    ctx.insert(CardEdge(from: jonas, to: eden, type: references))

    let board = Board.fetchOrCreatePrimaryBoard(for: mira, in: ctx)
    board.zoomScale = 1.0
    board.panX = 0
    board.panY = 0
    board.clampState()

    _ = board.node(for: mira, in: ctx, createIfMissing: true, defaultPosition: (0, 0))
    _ = board.node(for: jonas, in: ctx, createIfMissing: true, defaultPosition: (280, -40))
    _ = board.node(for: aster, in: ctx, createIfMissing: true, defaultPosition: (-260, 60))
    _ = board.node(for: eden, in: ctx, createIfMissing: true, defaultPosition: (0, -260))
    _ = board.node(for: opening, in: ctx, createIfMissing: true, defaultPosition: (0, 260))
    _ = board.node(for: artifact, in: ctx, createIfMissing: true, defaultPosition: (-120, -240))

    try? ctx.save()

    return NavigationStack {
        MurderBoardView(primary: mira)
    }
    .modelContainer(container)
    .frame(minWidth: 820, minHeight: 560)
}

