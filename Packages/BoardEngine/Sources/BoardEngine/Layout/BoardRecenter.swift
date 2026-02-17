//
//  BoardRecenter.swift
//  BoardEngine
//
//  Utility functions for recentering the canvas on a specific node
//  and for computing zoom-keeping-center transforms.
//

import SwiftUI

// MARK: - Board Recenter

/// Utility for recentering and zooming the board canvas.
public struct BoardRecenter {

    /// Recenter the canvas on the primary node (or first node if no primary).
    @MainActor
    public static func recenterOnPrimary<DS: BoardDataSource>(
        dataSource: DS,
        windowSize: CGSize
    ) {
        let nodes = dataSource.nodes
        guard !nodes.isEmpty else { return }

        let primaryID = dataSource.primaryNodeID
        let targetNode = nodes.first(where: { $0.nodeID == primaryID }) ?? nodes.first!
        let world = CGPoint(x: targetNode.posX, y: targetNode.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        dataSource.panX = (cView.x.dg - world.x * dataSource.zoomScale)
        dataSource.panY = (cView.y.dg - world.y * dataSource.zoomScale)
        dataSource.persistTransform()
    }

    /// Step zoom by a delta, keeping the view center fixed.
    @MainActor
    public static func stepZoom<DS: BoardDataSource>(
        dataSource: DS,
        delta: Double,
        windowSize: CGSize,
        configuration: BoardConfiguration
    ) {
        let proposed = (dataSource.zoomScale + delta).clamped(to: configuration.minZoom...configuration.maxZoom)
        setZoomKeepingCenter(dataSource: dataSource, newScale: proposed, windowSize: windowSize, configuration: configuration)
    }

    /// Set zoom to a specific scale, keeping the view center fixed.
    @MainActor
    public static func setZoomKeepingCenter<DS: BoardDataSource>(
        dataSource: DS,
        newScale: Double,
        windowSize: CGSize,
        configuration: BoardConfiguration
    ) {
        let sNew = newScale.clamped(to: configuration.minZoom...configuration.maxZoom)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        let cWorld = BoardCanvasTransform.viewToWorld(cView, scale: dataSource.zoomScale, panX: dataSource.panX, panY: dataSource.panY)
        dataSource.panX = (cView.x.dg - cWorld.x * sNew)
        dataSource.panY = (cView.y.dg - cWorld.y * sNew)
        dataSource.zoomScale = sNew
        dataSource.persistTransform()
    }
}
