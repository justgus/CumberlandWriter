//
//  BoardEdgeHandlesLayer.swift
//  BoardEngine
//
//  Layer that renders edge creation handles on the trailing edge of
//  each node on the board canvas.
//

import SwiftUI

// MARK: - Board Edge Handles Layer

/// Renders edge handle circles at the trailing edge of each node.
public struct BoardEdgeHandlesLayer<DS: BoardDataSource>: View {
    let dataSource: DS
    let scheme: ColorScheme
    let zoomScale: Double
    let edgeCreationState: BoardEdgeCreationState
    let nodeSizes: [UUID: CGSize]
    let worldToView: (CGPoint) -> CGPoint

    public init(
        dataSource: DS,
        scheme: ColorScheme,
        zoomScale: Double,
        edgeCreationState: BoardEdgeCreationState,
        nodeSizes: [UUID: CGSize],
        worldToView: @escaping (CGPoint) -> CGPoint
    ) {
        self.dataSource = dataSource
        self.scheme = scheme
        self.zoomScale = zoomScale
        self.edgeCreationState = edgeCreationState
        self.nodeSizes = nodeSizes
        self.worldToView = worldToView
    }

    public var body: some View {
        let nodes = dataSource.nodes
        ForEach(nodes, id: \.nodeID) { node in
            let nodeSize = nodeSizes[node.nodeID] ?? CGSize(width: 240, height: 160)
            let handleWorldX = node.posX + nodeSize.width / 2
            let handleWorldY = node.posY
            let handleViewPos = worldToView(CGPoint(x: handleWorldX, y: handleWorldY))

            let isSource = edgeCreationState.sourceCardID == node.nodeID
            let isTarget = edgeCreationState.hoveredTargetID == node.nodeID

            BoardEdgeHandle(
                nodeID: node.nodeID,
                accentColor: node.accentColor(for: scheme),
                isSource: isSource,
                isTarget: isTarget
            )
            .position(handleViewPos)
        }
        .allowsHitTesting(false)
    }
}
