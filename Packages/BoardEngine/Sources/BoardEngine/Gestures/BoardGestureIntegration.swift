//
//  BoardGestureIntegration.swift
//  BoardEngine
//
//  ViewModifier that wires MultiGestureHandler to a BoardDataSource,
//  creating and configuring canvas, node, and edge handle gesture targets.
//  Generic over BoardDataSource — consumers provide callbacks for
//  domain-specific actions (popup menus, save, etc.).
//

import SwiftUI

// MARK: - Board Gesture Integration

/// ViewModifier that integrates MultiGestureHandler with a BoardDataSource.
public struct BoardGestureIntegration<DS: BoardDataSource>: ViewModifier {
    let dataSource: DS
    let configuration: BoardConfiguration

    let canvasCoordSpace: String
    @Binding var gestureHandler: MultiGestureHandler?
    @Binding var canvasGestureTarget: CanvasGestureTarget?
    @Binding var nodeGestureTargets: [UUID: NodeGestureTarget]

    @Binding var zoomScale: Double
    @Binding var panX: Double
    @Binding var panY: Double
    @Binding var selectedNodeID: UUID?

    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]
    let windowSize: CGSize
    let viewCanvasRect: () -> CGRect

    // Edge creation
    var edgeCreationState: BoardEdgeCreationState?
    var onEdgeCreated: ((UUID, UUID) -> Void)?

    // Consumer-provided callbacks for domain-specific actions
    var onRightClickNode: ((UUID, CGPoint, MultiGestureHandler?, CoordinateSpaceInfo) -> Void)?

    // Sidebar visibility for scroll exclusion zone
    let isSidebarVisible: Bool

    // Internal storage for edge handle targets
    @State private var edgeHandleGestureTargets: [UUID: EdgeHandleGestureTarget] = [:]

    public init(
        dataSource: DS,
        configuration: BoardConfiguration = .cumberland,
        canvasCoordSpace: String,
        gestureHandler: Binding<MultiGestureHandler?>,
        canvasGestureTarget: Binding<CanvasGestureTarget?>,
        nodeGestureTargets: Binding<[UUID: NodeGestureTarget]>,
        zoomScale: Binding<Double>,
        panX: Binding<Double>,
        panY: Binding<Double>,
        selectedNodeID: Binding<UUID?>,
        nodeSizes: Binding<[UUID: CGSize]>,
        nodeVisualSizes: Binding<[UUID: CGSize]>,
        windowSize: CGSize,
        viewCanvasRect: @escaping () -> CGRect,
        edgeCreationState: BoardEdgeCreationState? = nil,
        onEdgeCreated: ((UUID, UUID) -> Void)? = nil,
        onRightClickNode: ((UUID, CGPoint, MultiGestureHandler?, CoordinateSpaceInfo) -> Void)? = nil,
        isSidebarVisible: Bool = false
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.canvasCoordSpace = canvasCoordSpace
        self._gestureHandler = gestureHandler
        self._canvasGestureTarget = canvasGestureTarget
        self._nodeGestureTargets = nodeGestureTargets
        self._zoomScale = zoomScale
        self._panX = panX
        self._panY = panY
        self._selectedNodeID = selectedNodeID
        self._nodeSizes = nodeSizes
        self._nodeVisualSizes = nodeVisualSizes
        self.windowSize = windowSize
        self.viewCanvasRect = viewCanvasRect
        self.edgeCreationState = edgeCreationState
        self.onEdgeCreated = onEdgeCreated
        self.onRightClickNode = onRightClickNode
        self.isSidebarVisible = isSidebarVisible
    }

    // Check if we have visual sizes for all nodes on the board
    private var hasAllVisualSizes: Bool {
        let nodeIDs = Set(dataSource.nodes.map { $0.nodeID })
        let measuredIDs = Set(nodeVisualSizes.keys)
        return nodeIDs.isSubset(of: measuredIDs)
    }

    private var nodesKey: [UUID] {
        dataSource.nodes.map { $0.nodeID }
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                setupGestureHandler()
            }
            .onChange(of: dataSource.boardID) { _, _ in
                setupGestureHandler()
            }
            .onChange(of: nodesKey) { _, _ in
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                    if hasAllVisualSizes {
                        setupGestureHandler()
                    }
                }
            }
            .onChange(of: nodeVisualSizes) { _, _ in
                if !nodesKey.isEmpty && hasAllVisualSizes {
                    setupGestureHandler()
                }
            }
            .onChange(of: isSidebarVisible) { _, _ in
                updateScrollExclusionZone()
            }
            .onChange(of: windowSize) { _, _ in
                updateScrollExclusionZone()
            }
            .onAppear {
                updateScrollExclusionZone()
            }
            .multiGestureHandler(
                gestureHandler ?? setupAndReturnGestureHandler(),
                coordinateInfo: CoordinateSpaceInfo(
                    spaceName: canvasCoordSpace,
                    transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                        .translatedBy(x: panX, y: panY),
                    zoomScale: zoomScale,
                    panOffset: CGPoint(x: panX, y: panY)
                )
            )
    }

    private func setupAndReturnGestureHandler() -> MultiGestureHandler {
        let handler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        gestureHandler = handler
        setupGestureHandler()
        return handler
    }

    // MARK: - Scroll Exclusion Zone

    private func updateScrollExclusionZone() {
        guard let handler = gestureHandler else { return }
        if isSidebarVisible {
            let sidebarWidth = min(320, windowSize.width * 0.35)
            let rect = CGRect(x: 0, y: 0, width: sidebarWidth, height: windowSize.height)
            handler.setScrollExclusionRects([rect])
        } else {
            handler.setScrollExclusionRects([])
        }
        #if os(macOS)
        handler.setMouseExclusionRects([])
        #endif
    }

    // MARK: - Setup

    private func setupGestureHandler() {
        guard hasAllVisualSizes else { return }

        if gestureHandler == nil {
            gestureHandler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        }

        guard let handler = gestureHandler else { return }

        nodeGestureTargets.removeAll()

        // Setup canvas target
        if canvasGestureTarget == nil {
            canvasGestureTarget = CanvasGestureTarget(configuration: configuration)
        }
        guard let canvasTarget = canvasGestureTarget else { return }
        canvasTarget.configuration = configuration

        canvasTarget.onTransformChanged = { scale, newPanX, newPanY in
            zoomScale = scale
            panX = newPanX
            panY = newPanY
        }

        canvasTarget.onTransformCommit = {
            dataSource.persistTransform()
        }

        canvasTarget.onSelectionChanged = { nodeID in
            selectedNodeID = nodeID
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

        handler.registerTarget(canvasTarget)

        // Setup node targets sorted by zIndex (topmost registers last = highest priority)
        let sortedNodes = dataSource.nodes.sorted { $0.zIndex < $1.zIndex }

        for node in sortedNodes {
            let nodeTarget = NodeGestureTarget(nodeID: node.nodeID, isPrimary: node.isPrimary)

            nodeTarget.onSelectionChanged = { nID in
                selectedNodeID = nID
            }

            nodeTarget.onNodeMoved = { nID, worldPos in
                dataSource.moveNode(nID, to: worldPos)
            }

            nodeTarget.onNodeMoveCommit = { nID in
                dataSource.commitNodeMove(nID)
            }

            nodeTarget.onRightClick = { nID, location in
                let coordinateInfo = CoordinateSpaceInfo(
                    spaceName: canvasCoordSpace,
                    transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale)
                        .translatedBy(x: panX, y: panY),
                    zoomScale: zoomScale,
                    panOffset: CGPoint(x: panX, y: panY)
                )
                onRightClickNode?(nID, location, gestureHandler, coordinateInfo)
            }

            nodeTarget.getNodeWorldBounds = { nID in
                guard let targetNode = dataSource.nodes.first(where: { $0.nodeID == nID }) else {
                    return CGRect.zero
                }

                let nodeCenter = CGPoint(x: targetNode.posX, y: targetNode.posY)

                let sizePoints: CGSize
                if let visualSize = nodeVisualSizes[nID] {
                    sizePoints = visualSize
                } else if let layoutSize = nodeSizes[nID] {
                    sizePoints = layoutSize
                } else {
                    sizePoints = CGSize(width: 50, height: 50)
                }

                return CGRect(
                    x: nodeCenter.x - sizePoints.width / 2,
                    y: nodeCenter.y - sizePoints.height / 2,
                    width: sizePoints.width,
                    height: sizePoints.height
                )
            }

            handler.registerTarget(nodeTarget)
            nodeGestureTargets[node.nodeID] = nodeTarget
        }

        // Setup edge handle gesture targets
        if let edgeState = edgeCreationState {
            edgeHandleGestureTargets.removeAll()

            for node in dataSource.nodes {
                let edgeHandleTarget = EdgeHandleGestureTarget(nodeID: node.nodeID)
                edgeHandleTarget.edgeCreationState = edgeState
                edgeHandleTarget.onEdgeCreated = onEdgeCreated

                edgeHandleTarget.getHandleWorldBounds = { nID in
                    guard let targetNode = dataSource.nodes.first(where: { $0.nodeID == nID }) else {
                        return CGRect.zero
                    }

                    let worldCenter = CGPoint(x: targetNode.posX, y: targetNode.posY)
                    let nodeSize = nodeVisualSizes[nID] ?? CGSize(width: 240, height: 160)
                    let handleSize: CGFloat = 80

                    let handleCenterX = worldCenter.x + nodeSize.width / 2
                    let handleCenterY = worldCenter.y

                    return CGRect(
                        x: handleCenterX - handleSize / 2,
                        y: handleCenterY - handleSize / 2,
                        width: handleSize,
                        height: handleSize
                    )
                }

                edgeHandleTarget.hitTestNodes = { viewLocation in
                    for testNode in dataSource.nodes {
                        let worldCenter = CGPoint(x: testNode.posX, y: testNode.posY)
                        let viewCenter = CGPoint(
                            x: worldCenter.x * zoomScale + panX,
                            y: worldCenter.y * zoomScale + panY
                        )

                        let nodeSize = nodeVisualSizes[testNode.nodeID] ?? CGSize(width: 240, height: 160)
                        let scaledWidth = nodeSize.width * zoomScale
                        let scaledHeight = nodeSize.height * zoomScale

                        let nodeRect = CGRect(
                            x: viewCenter.x - scaledWidth / 2,
                            y: viewCenter.y - scaledHeight / 2,
                            width: scaledWidth,
                            height: scaledHeight
                        )

                        if nodeRect.contains(viewLocation) {
                            return testNode.nodeID
                        }
                    }
                    return nil
                }

                handler.registerTarget(edgeHandleTarget)
                edgeHandleGestureTargets[node.nodeID] = edgeHandleTarget
            }
        }

        updateScrollExclusionZone()
    }
}
