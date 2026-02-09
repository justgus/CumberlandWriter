// MurderBoardGestureTargets.swift
// Extracted from MurderBoardView.swift as part of ER-0022 Phase 3.3
// Contains gesture target implementations for canvas and node gestures

import SwiftUI
import SwiftData

// MARK: - Canvas Gesture Target

/// Canvas-level gesture target for pan, pinch, and background tap
@MainActor
final class CanvasGestureTarget: GestureTarget {
    let gestureID = UUID()

    // Callbacks to the view
    var onTransformChanged: ((Double, Double, Double) -> Void)?
    var onTransformCommit: (() -> Void)?
    var onSelectionChanged: ((UUID?) -> Void)?

    // Transform state access
    var getCurrentTransform: (() -> (scale: Double, panX: Double, panY: Double))?
    var getWindowSize: (() -> CGSize)?
    var getCanvasRect: (() -> CGRect)?

    var worldBounds: CGRect {
        // Canvas target covers the entire canvas area
        getCanvasRect?() ?? CGRect(x: -10000, y: -10000, width: 20000, height: 20000)
    }

    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .pinch, .twoFingerPan:
            return true
        case .drag, .doubleTap, .rightClick:
            return false // Let node targets handle these first
        }
    }

    func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            // Background tap - clear selection
            onSelectionChanged?(nil)

        case .pinchBegan(_, _, _, _):
            // Start pinch - no immediate action needed
            break

        case .pinchChanged(let scale, _, let center, let coordinateInfo):
            // Update zoom keeping center point fixed
            if let transform = getCurrentTransform?() {

                let centerWorld = coordinateInfo.toWorldSpace(center)
                let newScale = (transform.scale * scale).clamped(to: Board.minZoom...Board.maxZoom)

                // Adjust pan to keep world point under center fixed
                let newPanX = center.x - centerWorld.x * newScale
                let newPanY = center.y - centerWorld.y * newScale

                onTransformChanged?(newScale, newPanX, newPanY)
            }

        case .pinchEnded(_, _, _, _):
            // Commit transform changes
            onTransformCommit?()

        case .twoFingerPanBegan(_, _):
            // Start two-finger pan - no immediate action needed
            break

        case .twoFingerPanChanged(let translation, _, _):
            // Update pan translation
            if let transform = getCurrentTransform?() {
                let newPanX = (transform.panX + translation.width).clamped(to: Board.minPan...Board.maxPan)
                let newPanY = (transform.panY + translation.height).clamped(to: Board.minPan...Board.maxPan)
                onTransformChanged?(transform.scale, newPanX, newPanY)
            }

        case .twoFingerPanEnded(_, _, _, _):
            // Commit transform changes
            onTransformCommit?()

        default:
            break
        }
    }
}

// MARK: - Node Gesture Target

/// Node-level gesture target for drag and selection
@MainActor
final class NodeGestureTarget: GestureTarget {
    let gestureID = UUID()
    let cardID: UUID
    let isPrimary: Bool
    private var dragStartWorldPosition: CGPoint = .zero
    private var dragGrabOffset: CGPoint = .zero

    // Callbacks to the view
    var onSelectionChanged: ((UUID?) -> Void)?
    var onNodeMoved: ((UUID, CGPoint) -> Void)?
    var onNodeMoveCommit: ((UUID) -> Void)?
    var onRightClick: ((UUID, CGPoint) -> Void)?

    // Position and size access
    var getNodeWorldBounds: ((UUID) -> CGRect)?

    init(cardID: UUID, isPrimary: Bool = false) {
        self.cardID = cardID
        self.isPrimary = isPrimary
    }

    var worldBounds: CGRect {
        getNodeWorldBounds?(cardID) ?? CGRect.zero
    }

    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .drag, .rightClick, .doubleTap:
            return true
        case .pinch, .twoFingerPan:
            return false // Let canvas handle these
        }
    }

    func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            // Node tap - select this node
            onSelectionChanged?(cardID)

        case .dragBegan(let startLocation, let coordinateInfo):
            // Ensure this node becomes selected when dragging starts
            onSelectionChanged?(cardID)
            // Start dragging this node
            let worldStart = coordinateInfo.toWorldSpace(startLocation)
            let nodeCenter = CGPoint(x: worldBounds.midX, y: worldBounds.midY)
            dragStartWorldPosition = nodeCenter
            dragGrabOffset = CGPoint(x: worldStart.x - nodeCenter.x, y: worldStart.y - nodeCenter.y)

        case .dragChanged(let location, _, let coordinateInfo):
            // Update node position preserving grab offset
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(cardID, newNodeCenter)

        case .dragEnded(let location, _, _, let coordinateInfo):
            // Commit node position
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(cardID, newNodeCenter)
            onNodeMoveCommit?(cardID)

        case .rightClick(let location, _):
            #if DEBUG
            print("NodeGestureTarget: rightClick gestureID= \(gestureID), cardID= \(cardID).  isPrimary=\( isPrimary ? "true" : "false" )")
            #endif
            // Node right-click - ensure selection happens first SYNCHRONOUSLY
            onSelectionChanged?(cardID)
            // Process right-click immediately after selection (no async Task needed)
            onRightClick?(cardID, location)

        default:
            break
        }
    }
}

// MARK: - Edge Handle Gesture Target (DR-0076)

/// Gesture target for edge creation handles
@MainActor
final class EdgeHandleGestureTarget: GestureTarget {
    let gestureID = UUID()
    let cardID: UUID

    // Edge creation state reference
    var edgeCreationState: EdgeCreationState?

    // Callbacks
    var onEdgeCreated: ((UUID, UUID) -> Void)?

    // Position and size access - returns bounds in WORLD coordinates
    var getHandleWorldBounds: ((UUID) -> CGRect)?

    // Hit test all nodes to find which one we're hovering over (takes VIEW coordinates)
    var hitTestNodes: ((CGPoint) -> UUID?)?

    init(cardID: UUID) {
        self.cardID = cardID
    }

    var worldBounds: CGRect {
        // Get handle bounds directly in WORLD coordinates
        getHandleWorldBounds?(cardID) ?? CGRect.zero
    }

    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .drag:
            return true
        case .tap, .doubleTap, .rightClick, .pinch, .twoFingerPan:
            return false
        }
    }

    func handleGesture(_ gesture: GestureEvent) {
        guard let state = edgeCreationState else { return }

        switch gesture {
        case .dragBegan(let startLocation, _):
            // Start edge creation drag
            state.startDrag(from: cardID, at: startLocation)
            #if DEBUG
            print("[EdgeHandle] Drag began from card \(cardID) at \(startLocation)")
            #endif

        case .dragChanged(let location, _, _):
            // Update drag position and check for hover target
            state.updateDrag(to: location)

            // Hit test to find what node we're over
            if let targetID = hitTestNodes?(location), targetID != cardID {
                state.setHoveredTarget(targetID)
            } else {
                state.setHoveredTarget(nil)
            }

        case .dragEnded(let location, _, _, _):
            // Check for valid target and trigger edge creation
            if let targetID = hitTestNodes?(location), targetID != cardID {
                state.setHoveredTarget(targetID)
            }

            if let targetID = state.endDrag() {
                #if DEBUG
                print("[EdgeHandle] Drag ended on target \(targetID)")
                #endif
                onEdgeCreated?(cardID, targetID)
            } else {
                #if DEBUG
                print("[EdgeHandle] Drag ended with no valid target")
                #endif
            }

        default:
            break
        }
    }
}

// MARK: - Gesture Handler Integration ViewModifier

struct GestureHandlerIntegration: ViewModifier {
    let useNewGestureHandler: Bool
    @Binding var gestureHandler: MultiGestureHandler?
    @Binding var canvasGestureTarget: CanvasGestureTarget?
    @Binding var nodeGestureTargets: [UUID: NodeGestureTarget]

    let canvasCoordSpace: String
    @Binding var zoomScale: Double
    @Binding var panX: Double
    @Binding var panY: Double
    @Binding var selectedCardID: UUID?

    let board: Board?
    let modelContext: ModelContext
    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]
    let windowSize: CGSize
    let viewCanvasRect: () -> CGRect
    let persistTransform: () -> Void
    let removeCardFromBoard: (UUID) -> Void
    let nodesKey: [UUID]

    // Edge creation (DR-0076)
    var edgeCreationState: EdgeCreationState?
    var onEdgeCreated: ((UUID, UUID) -> Void)?

    // Internal storage for edge handle targets (not exposed to parent)
    @State private var edgeHandleGestureTargets: [UUID: EdgeHandleGestureTarget] = [:]

    // Check if we have visual sizes for all nodes on the board
    private var hasAllVisualSizes: Bool {
        guard let b = board else { return true }
        let nodeCardIDs = Set((b.nodes ?? []).compactMap { $0.card?.id })
        let measuredCardIDs = Set(nodeVisualSizes.keys)
        return nodeCardIDs.isSubset(of: measuredCardIDs)
    }

    func body(content: Content) -> some View {
        if useNewGestureHandler {
            content
                .onAppear {
                    setupGestureHandler()
                }
                .onChange(of: board?.id) { _, _ in
                    setupGestureHandler()
                }
                .onChange(of: nodesKey) { _, _ in
                    // Nodes membership changed (drop/add/remove) — rebuild gesture targets
                    // Defer setup slightly to allow CardViews to report their sizes
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                        if hasAllVisualSizes {
                            setupGestureHandler()
                        }
                    }
                }
                .onChange(of: nodeVisualSizes) { _, _ in
                    // Visual sizes updated - rebuild gesture targets if we have all sizes
                    if !nodesKey.isEmpty && hasAllVisualSizes {
                        setupGestureHandler()
                    }
                }
                .multiGestureHandler(
                    gestureHandler ?? setupAndReturnGestureHandler(),
                    coordinateInfo: CoordinateSpaceInfo(
                        spaceName: canvasCoordSpace,
                        transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale).translatedBy(x: panX, y: panY),
                        zoomScale: zoomScale,
                        panOffset: CGPoint(x: panX, y: panY)
                    )
                )
        } else {
            // Fallback: Use legacy gesture handling (if any)
            content
        }
    }

    private func setupAndReturnGestureHandler() -> MultiGestureHandler {
        let handler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        gestureHandler = handler
        setupGestureHandler()
        return handler
    }

    private func setupGestureHandler() {
        guard useNewGestureHandler else { return }

        // Check if we have all visual sizes before proceeding
        guard hasAllVisualSizes else {
            #if DEBUG
            print("setupGestureHandler: Waiting for visual sizes. Have \(nodeVisualSizes.count) of \(nodesKey.count) needed.")
            #endif
            return
        }

        #if DEBUG
        print("setupGestureHandler: All visual sizes ready, proceeding with setup.")
        #endif

        // Create handler if it doesn't exist, otherwise reuse existing
        if gestureHandler == nil {
            gestureHandler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        }

        guard let handler = gestureHandler else { return }

        // Clear existing targets to avoid duplicates
        nodeGestureTargets.removeAll()

        // Setup (or reuse) canvas gesture target instance
        if canvasGestureTarget == nil {
            canvasGestureTarget = CanvasGestureTarget()
        }
        guard let canvasTarget = canvasGestureTarget else { return }

        // Configure canvas target callbacks
        canvasTarget.onTransformChanged = { scale, newPanX, newPanY in
            zoomScale = scale
            panX = newPanX
            panY = newPanY
            print("Canvas transform changed to: \(scale), \(newPanX), \(newPanY)")
        }

        canvasTarget.onTransformCommit = {
            persistTransform()
        }

        canvasTarget.onSelectionChanged = { cardID in
            selectedCardID = cardID
        }

        canvasTarget.getCurrentTransform = {
            (scale: zoomScale, panX: panX, panY: panY)
        }

        canvasTarget.getWindowSize = {
            windowSize
        }

        canvasTarget.getCanvasRect = {
            viewCanvasRect()
        }

        // Register canvas target first; nodes will be registered after and thus win taps over canvas
        print("Registering canvas target")
        handler.registerTarget(canvasTarget)

        // Setup node targets for each card on the board (sort by zIndex so topmost registers last)
        if let nodeArray = board?.nodes {
            let sortedNodes = nodeArray.sorted { $0.zIndex < $1.zIndex }
            for node in sortedNodes {
                guard let card = node.card else { continue }
                let primaryCard = node.board?.primaryCard
                let isPrimary = (card.id == primaryCard?.id)

                let nodeTarget = NodeGestureTarget(cardID: card.id, isPrimary: isPrimary)

                // Configure node target callbacks
                nodeTarget.onSelectionChanged = { cardID in
                    selectedCardID = cardID
                }

                nodeTarget.onNodeMoved = { cardID, worldPos in
                    // Look up from the live board each time (avoid captured snapshots)
                    if let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }) {
                        targetNode.posX = worldPos.x
                        targetNode.posY = worldPos.y
                    }
                }

                nodeTarget.onNodeMoveCommit = { _ in
                    try? modelContext.save()
                }

                nodeTarget.onRightClick = { cardID, location in
                    #if DEBUG
                    print("[MB] Right-click on node \(cardID)")
                    #endif

                    // Create popup menu for the node
                    guard let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }),
                          let card = targetNode.card else { return }

                    // Check if this is the primary card
                    let isPrimaryCard = (card.id == board?.primaryCard?.id)

                    let menuItems = [
                        PopupMenuItem(
                            title: "Remove \(card.name) from Board",
                            systemImage: "minus.circle",
                            isDestructive: false,
                            isDisabled: isPrimaryCard,
                            action: {
                                removeCardFromBoard(cardID)
                            }
                        )
                    ]

                    // Show popup through gesture handler
                    if let handler = gestureHandler {
                        let coordinateInfo = CoordinateSpaceInfo(
                            spaceName: canvasCoordSpace,
                            transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale).translatedBy(x: panX, y: panY),
                            zoomScale: zoomScale,
                            panOffset: CGPoint(x: panX, y: panY)
                        )

                        let popup = PopupMenu(
                            items: menuItems,
                            position: location,
                            coordinateSpace: coordinateInfo
                        )

                        handler.showPopup(popup)
                    }
                }

                nodeTarget.getNodeWorldBounds = { cardID in
                    // Compute world-space bounds for the node using live board lookup
                    guard let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }) else {
                        return CGRect.zero
                    }

                    let nodeCenter = CGPoint(x: targetNode.posX, y: targetNode.posY)

                    // Use visual size if available, otherwise fall back to layout size
                    let sizePoints: CGSize
                    if let visualSize = nodeVisualSizes[cardID] {
                        sizePoints = visualSize
                    } else if let layoutSize = nodeSizes[cardID] {
                        sizePoints = layoutSize
                    } else {
                        sizePoints = CGSize(width: 50, height: 50) // Fallback
                    }

                    // Convert to world space
                    _ = max(zoomScale, 0.000001)
                    let worldSize = CGSize(
                        width: sizePoints.width,
                        height: sizePoints.height
                    )

                    let worldRect = CGRect(
                        x: nodeCenter.x - worldSize.width / 2,
                        y: nodeCenter.y - worldSize.height / 2,
                        width: worldSize.width,
                        height: worldSize.height
                    )

                    return worldRect
                }

                // Register node target
                #if DEBUG
                print("Registering node target for card \(card.name) with visual size: \(nodeVisualSizes[card.id] ?? CGSize.zero)")
                #endif
                handler.registerTarget(nodeTarget)
                nodeGestureTargets[card.id] = nodeTarget
            }
        }

        // DR-0076: Setup edge handle gesture targets
        #if DEBUG
        print("Edge creation state: \(edgeCreationState == nil ? "nil" : "present"), board nodes: \(board?.nodes?.count ?? 0)")
        #endif
        if let edgeState = edgeCreationState, let nodeArray = board?.nodes {
            edgeHandleGestureTargets.removeAll()

            for node in nodeArray {
                guard let card = node.card else { continue }

                let edgeHandleTarget = EdgeHandleGestureTarget(cardID: card.id)

                // Configure edge handle callbacks
                edgeHandleTarget.edgeCreationState = edgeState
                edgeHandleTarget.onEdgeCreated = onEdgeCreated

                // Provide hit bounds for the edge handle in WORLD coordinates
                edgeHandleTarget.getHandleWorldBounds = { [self] cardID in
                    guard let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }) else {
                        return CGRect.zero
                    }

                    // Node center in WORLD coordinates
                    let worldCenter = CGPoint(x: targetNode.posX, y: targetNode.posY)

                    // Get node size (these are in view/layout units, need to use as-is for world bounds)
                    let nodeSize = nodeVisualSizes[cardID] ?? CGSize(width: 240, height: 160)

                    // Edge handle straddles the trailing edge of the node (half on, half off)
                    // Visual handle is 20pt, but use larger hit area (80x80) for easier clicking
                    let handleSize: CGFloat = 80

                    // Handle center is at the card's trailing edge (straddling position)
                    let handleCenterX = worldCenter.x + nodeSize.width / 2
                    let handleCenterY = worldCenter.y

                    return CGRect(
                        x: handleCenterX - handleSize / 2,
                        y: handleCenterY - handleSize / 2,
                        width: handleSize,
                        height: handleSize
                    )
                }

                // Provide hit test for nodes during drag
                edgeHandleTarget.hitTestNodes = { [self] viewLocation in
                    // Check each node to see if the point is inside
                    for testNode in (board?.nodes ?? []) {
                        guard let testCard = testNode.card else { continue }

                        let worldCenter = CGPoint(x: testNode.posX, y: testNode.posY)
                        let viewCenter = CGPoint(
                            x: worldCenter.x * zoomScale + panX,
                            y: worldCenter.y * zoomScale + panY
                        )

                        let nodeSize = nodeVisualSizes[testCard.id] ?? CGSize(width: 240, height: 160)
                        let scaledWidth = nodeSize.width * zoomScale
                        let scaledHeight = nodeSize.height * zoomScale

                        let nodeRect = CGRect(
                            x: viewCenter.x - scaledWidth / 2,
                            y: viewCenter.y - scaledHeight / 2,
                            width: scaledWidth,
                            height: scaledHeight
                        )

                        if nodeRect.contains(viewLocation) {
                            return testCard.id
                        }
                    }
                    return nil
                }

                // Register edge handle target BEFORE node target so it wins hit testing
                // (Targets registered later have higher priority)
                #if DEBUG
                print("Registering edge handle target for card \(card.name)")
                #endif
                handler.registerTarget(edgeHandleTarget)
                edgeHandleGestureTargets[card.id] = edgeHandleTarget
            }
        }
    }
}
