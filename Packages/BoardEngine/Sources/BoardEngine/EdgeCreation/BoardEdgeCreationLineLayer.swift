//
//  BoardEdgeCreationLineLayer.swift
//  BoardEngine
//
//  Renders the temporary line from the source node handle to the
//  current cursor position during an edge creation drag.
//

import SwiftUI

// MARK: - Board Edge Creation Line Layer

/// Draws a dashed line from the edge handle of the source node to the
/// current drag position during edge creation.
public struct BoardEdgeCreationLineLayer: View {
    let edgeCreationState: BoardEdgeCreationState
    let scheme: ColorScheme
    let worldToView: (CGPoint) -> CGPoint
    let getSourceCenter: (UUID) -> CGPoint?

    public init(
        edgeCreationState: BoardEdgeCreationState,
        scheme: ColorScheme,
        worldToView: @escaping (CGPoint) -> CGPoint,
        getSourceCenter: @escaping (UUID) -> CGPoint?
    ) {
        self.edgeCreationState = edgeCreationState
        self.scheme = scheme
        self.worldToView = worldToView
        self.getSourceCenter = getSourceCenter
    }

    public var body: some View {
        if let sourceID = edgeCreationState.sourceCardID,
           let dragPos = edgeCreationState.currentDragPosition,
           let sourceCenter = getSourceCenter(sourceID) {
            Canvas { context, size in
                var path = Path()
                path.move(to: sourceCenter)
                path.addLine(to: dragPos)

                let lineColor = scheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7)
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [6, 4])
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
