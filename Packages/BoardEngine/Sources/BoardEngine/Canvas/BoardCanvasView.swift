//
//  BoardCanvasView.swift
//  BoardEngine
//
//  Composite board canvas view that stacks grid background, edges layer,
//  nodes layer, edge handles, and edge creation line in the correct Z-order.
//  Generic over a BoardDataSource and a consumer-provided node view.
//

import SwiftUI

// MARK: - Board Canvas View

/// The main composite canvas view for the board. Stacks:
/// 1. Grid background
/// 2. Edges layer (relationship arrows)
/// 3. Nodes layer (consumer-provided views, with transform applied)
/// 4. Drop target indicator
/// 5. Edge handles layer
/// 6. Edge creation line layer
public struct BoardCanvasView<DS: BoardDataSource, NodeContent: View>: View {
    let dataSource: DS
    let configuration: BoardConfiguration
    let selectedNodeID: UUID?
    let selectedEdgeSourceTarget: (UUID, UUID)?
    let scheme: ColorScheme
    let isContentReady: Bool

    @Binding var isDropTargetActive: Bool
    @Binding var zoomScale: Double
    @Binding var panX: Double
    @Binding var panY: Double
    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]

    let edgeCreationState: BoardEdgeCreationState

    // Callbacks
    let onDropNodeIDs: ([UUID], CGPoint) -> Bool
    let onRemoveNode: (UUID) -> Void
    let onSelectNode: (UUID) -> Void
    let onEdgeCreated: (UUID, UUID) -> Void
    let onSelectEdge: ((_ sourceNodeID: UUID, _ targetNodeID: UUID, _ typeCode: String) -> Void)?

    @ViewBuilder let nodeContent: (_ node: DS.Node, _ isSelected: Bool, _ isPrimary: Bool) -> NodeContent

    public init(
        dataSource: DS,
        configuration: BoardConfiguration = .cumberland,
        selectedNodeID: UUID?,
        selectedEdgeSourceTarget: (UUID, UUID)? = nil,
        scheme: ColorScheme,
        isContentReady: Bool,
        isDropTargetActive: Binding<Bool>,
        zoomScale: Binding<Double>,
        panX: Binding<Double>,
        panY: Binding<Double>,
        nodeSizes: Binding<[UUID: CGSize]>,
        nodeVisualSizes: Binding<[UUID: CGSize]>,
        edgeCreationState: BoardEdgeCreationState,
        onDropNodeIDs: @escaping ([UUID], CGPoint) -> Bool,
        onRemoveNode: @escaping (UUID) -> Void,
        onSelectNode: @escaping (UUID) -> Void,
        onEdgeCreated: @escaping (UUID, UUID) -> Void,
        onSelectEdge: ((_ sourceNodeID: UUID, _ targetNodeID: UUID, _ typeCode: String) -> Void)? = nil,
        @ViewBuilder nodeContent: @escaping (_ node: DS.Node, _ isSelected: Bool, _ isPrimary: Bool) -> NodeContent
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
        self.selectedNodeID = selectedNodeID
        self.selectedEdgeSourceTarget = selectedEdgeSourceTarget
        self.scheme = scheme
        self.isContentReady = isContentReady
        self._isDropTargetActive = isDropTargetActive
        self._zoomScale = zoomScale
        self._panX = panX
        self._panY = panY
        self._nodeSizes = nodeSizes
        self._nodeVisualSizes = nodeVisualSizes
        self.edgeCreationState = edgeCreationState
        self.onDropNodeIDs = onDropNodeIDs
        self.onRemoveNode = onRemoveNode
        self.onSelectNode = onSelectNode
        self.onEdgeCreated = onEdgeCreated
        self.onSelectEdge = onSelectEdge
        self.nodeContent = nodeContent
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background: base fill + grid overlay
                ZStack {
                    Rectangle()
                        .fill(scheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.04))

                    BoardGridBackground(
                        tileSize: configuration.gridTileSize,
                        lineWidth: configuration.gridLineWidth,
                        primaryOpacity: scheme == .dark ? 0.22 : 0.10,
                        secondaryEvery: 5,
                        secondaryOpacity: scheme == .dark ? 0.28 : 0.14
                    )
                }
                .ignoresSafeArea()

                // Edges layer (above grid, below nodes)
                BoardEdgesLayer(
                    dataSource: dataSource,
                    scheme: scheme,
                    worldToView: worldToViewFunc,
                    selectedEdgeSourceTarget: selectedEdgeSourceTarget
                )
                .allowsHitTesting(false)

                // Edge selection hit-test overlay (above edges, below nodes)
                if isContentReady {
                    BoardEdgeSelectionLayer(
                        dataSource: dataSource,
                        scheme: scheme,
                        zoomScale: zoomScale,
                        worldToView: worldToViewFunc,
                        selectedEdgeSourceTarget: selectedEdgeSourceTarget,
                        onSelectEdge: { sourceID, targetID, typeCode in
                            onSelectEdge?(sourceID, targetID, typeCode)
                        }
                    )
                }

                // Nodes layer (with transform applied)
                if isContentReady {
                    BoardNodesLayer(
                        dataSource: dataSource,
                        selectedNodeID: selectedNodeID,
                        scheme: scheme,
                        isContentReady: isContentReady,
                        nodeSizes: $nodeSizes,
                        nodeVisualSizes: $nodeVisualSizes,
                        nodeContent: nodeContent
                    )
                    .modifier(BoardTransformModifier(
                        zoomScale: zoomScale,
                        panX: panX,
                        panY: panY
                    ))
                    .transition(.opacity.combined(with: .scale))
                }

                // Drop target indicator
                if isDropTargetActive {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .allowsHitTesting(false)
                        .accessibilityLabel("Drop target for adding nodes to board")
                }

                // Edge creation layers (in view coordinates, not transformed)
                if isContentReady {
                    BoardEdgeHandlesLayer(
                        dataSource: dataSource,
                        scheme: scheme,
                        zoomScale: zoomScale,
                        edgeCreationState: edgeCreationState,
                        nodeSizes: nodeVisualSizes,
                        worldToView: worldToViewFunc
                    )

                    BoardEdgeCreationLineLayer(
                        edgeCreationState: edgeCreationState,
                        scheme: scheme,
                        worldToView: worldToViewFunc,
                        getSourceCenter: { nodeID in
                            guard let node = dataSource.nodes.first(where: { $0.nodeID == nodeID }) else {
                                return nil
                            }
                            let nodeSize = nodeVisualSizes[nodeID] ?? CGSize(width: 240, height: 160)
                            let handleWorldX = node.posX + nodeSize.width / 2
                            let handleWorldY = node.posY
                            return worldToViewFunc(CGPoint(x: handleWorldX, y: handleWorldY))
                        }
                    )
                }
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Coordinate Transforms

    private var worldToViewFunc: (CGPoint) -> CGPoint {
        { world in
            BoardCanvasTransform.worldToView(world, scale: zoomScale, panX: panX, panY: panY)
        }
    }
}
