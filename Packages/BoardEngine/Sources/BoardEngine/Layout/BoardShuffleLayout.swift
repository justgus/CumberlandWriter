//
//  BoardShuffleLayout.swift
//  BoardEngine
//
//  Ring-based shuffle layout algorithm that arranges nodes in concentric
//  rings around the primary/anchor node with adaptive spacing.
//

import SwiftUI

// MARK: - Board Shuffle Layout

/// Arranges nodes in concentric rings around a primary/anchor node.
public struct BoardShuffleLayout {

    /// Shuffle all nodes in the data source around the primary node.
    /// - Parameters:
    ///   - dataSource: The board data source to mutate.
    ///   - nodeSizeProvider: Returns the world-space size for a given node ID.
    ///   - zoomScale: Current zoom scale (used for margin calculation).
    ///   - configuration: Board configuration with shuffle constants.
    @MainActor
    public static func shuffleAroundPrimary<DS: BoardDataSource>(
        dataSource: DS,
        nodeSizeProvider: (UUID) -> CGSize,
        zoomScale: Double,
        configuration: BoardConfiguration
    ) {
        var nodes = dataSource.nodes
        guard !nodes.isEmpty else { return }

        // Identify anchor (primary or first)
        let primaryID = dataSource.primaryNodeID
        let anchorNode = nodes.first(where: { $0.nodeID == primaryID }) ?? nodes.first!
        let anchor = CGPoint(x: anchorNode.posX, y: anchorNode.posY)

        // Remove anchor from placement list
        nodes.removeAll(where: { $0.nodeID == anchorNode.nodeID })

        let count = nodes.count
        guard count > 0 else { return }

        // Measure world-space sizes
        let anchorSize = nodeSizeProvider(anchorNode.nodeID)
        let nodeWorldSizes: [CGSize] = nodes.map { nodeSizeProvider($0.nodeID) }

        let maxNodeSpan = nodeWorldSizes.map { max($0.width, $0.height) }.max() ?? max(anchorSize.width, anchorSize.height)
        let avgNodeWidth = nodeWorldSizes.map { $0.width }.reduce(0, +) / CGFloat(nodeWorldSizes.count)

        // Base margins (WORLD units)
        let baseMargin: CGFloat = (maxNodeSpan * configuration.shuffleBaseMarginWorldFactor)
            + (configuration.shuffleBaseMarginViewPadding / max(CGFloat(zoomScale), 0.000001))
        let spacingMultiplier = configuration.shuffleSpacingMultiplier
        let ringSeparationMultiplier = configuration.shuffleRingSeparationMultiplier

        // Start radius
        var radius: CGFloat = (max(anchorSize.width, anchorSize.height) * configuration.shuffleInitialAnchorFactor)
            + (maxNodeSpan * configuration.shuffleInitialNodeSpanFactor)
            + baseMargin

        var pool = nodes
        var remaining = pool.count

        while remaining > 0 {
            let desiredArcSpacing = max(avgNodeWidth, 1.0) * spacingMultiplier

            func capacity(at r: CGFloat) -> Int {
                let circ = 2.0 * .pi * r
                return max(1, Int(floor(circ / desiredArcSpacing)))
            }
            var cap = capacity(at: radius)

            while cap == 0 {
                radius += max(6.0, maxNodeSpan * 0.20)
                cap = capacity(at: radius)
            }

            let take = min(remaining, cap)
            let angleStep = (2.0 * .pi) / CGFloat(take)
            let startAngle = Double.random(in: 0..<(2.0 * Double.pi))

            for i in 0..<take {
                if let node = pool.popLast() {
                    let theta = startAngle + Double(i) * Double(angleStep)
                    let jitterR = Double.random(in: configuration.shuffleRadialJitterWorld) * Double(maxNodeSpan)
                    let jitterT = Double.random(in: configuration.shuffleAngularJitter)
                    let r = Double(radius) + jitterR
                    let x = anchor.x + (r * cos(theta + jitterT))
                    let y = anchor.y + (r * sin(theta + jitterT))
                    dataSource.moveNode(node.nodeID, to: CGPoint(x: x, y: y))
                }
            }

            remaining = pool.count
            let ringSeparationWorld = max(maxNodeSpan * ringSeparationMultiplier + baseMargin, maxNodeSpan * 0.7)
            radius += ringSeparationWorld
        }

        // Commit all moves
        for node in nodes {
            dataSource.commitNodeMove(node.nodeID)
        }
    }
}
