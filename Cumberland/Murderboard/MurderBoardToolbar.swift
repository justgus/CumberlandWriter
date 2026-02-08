// MurderBoardToolbar.swift
// Extracted from MurderBoardView.swift as part of ER-0022 Phase 3.3
// Contains toolbar and zoom controls

import SwiftUI
import SwiftData

// MARK: - Toolbar Extension

extension MurderBoardView {
    @ToolbarContentBuilder
    func toolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button { stepZoom(-0.05, windowSize: windowSize) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")
            .keyboardShortcut("-", modifiers: [.command])

            Slider(value: Binding(
                get: { zoomScale },
                set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
            ), in: Board.minZoom...Board.maxZoom)
            .frame(width: 160)
            .help("Zoom")

            Button { stepZoom(+0.05, windowSize: windowSize) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
            .keyboardShortcut("=", modifiers: [.command])

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
                Text("%").foregroundStyle(.secondary)
            }
            .help("Enter zoom percentage (1–200)")

            Divider()

            Button { recenterOnPrimaryOrFirst(windowSize: windowSize) } label: {
                Label("Recenter", systemImage: "dot.scope")
            }
            .help("Recenter on primary (or first) node")

            Button { shuffleAroundPrimary() } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .help("Arrange nodes around the primary in a ring; repeat to reshuffle")

            Divider()

            #if DEBUG
            // Debug controls can go here
            #endif
        }
    }

    func stepZoom(_ delta: Double, windowSize: CGSize) {
        let proposed = (zoomScale + delta).clamped(to: Board.minZoom...Board.maxZoom)
        setZoomKeepingCenter(proposed, windowSize: windowSize)
    }

    func setZoomKeepingCenter(_ newScale: Double, windowSize: CGSize) {
        let sNew = newScale.clamped(to: Board.minZoom...Board.maxZoom)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        let cWorld = viewToWorld(cView)
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
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()
    }
}

// MARK: - Shuffle Geometry Constants

let shuffleInitialAnchorFactor: CGFloat = 0.35
let shuffleInitialNodeSpanFactor: CGFloat = 0.45
let shuffleBaseMarginWorldFactor: CGFloat = 0.10
let shuffleBaseMarginViewPadding: CGFloat = 8.0
let shuffleSpacingMultiplier: CGFloat = 1.15
let shuffleRingSeparationMultiplier: CGFloat = 0.75
let shuffleRadialJitterWorld: ClosedRange<Double> = -0.06...0.06
let shuffleAngularJitter: ClosedRange<Double> = -0.12...0.12

// MARK: - Shuffle Implementation

extension MurderBoardView {
    func shuffleAroundPrimary() {
        guard let b = board else { return }
        guard var nodes = b.nodes, !nodes.isEmpty else { return }

        // Identify anchor (primary or first)
        let primaryID = b.primaryCard?.id
        let anchorNode = nodes.first(where: { $0.card?.id == primaryID }) ?? nodes.first!
        let anchor = CGPoint(x: anchorNode.posX, y: anchorNode.posY)

        // Remove anchor from placement list
        nodes.removeAll(where: { $0.id == anchorNode.id })

        // Early exit if nothing to place
        let count = max(0, nodes.count)
        guard count > 0 else { return }

        // CA-15: Adaptive ring geometry in WORLD space (zoom-independent)
        // Measure world-space sizes
        func worldSize(for node: BoardNode) -> CGSize {
            guard let id = node.card?.id else { return CGSize(width: 240, height: 160) }
            return nodeSizeInWorldPoints(for: id)
        }
        let anchorSize = worldSize(for: anchorNode)
        let nodeWorldSizes: [CGSize] = nodes.map(worldSize(for:))

        let maxNodeSpan = nodeWorldSizes.map { max($0.width, $0.height) }.max() ?? max(anchorSize.width, anchorSize.height)
        let avgNodeWidth = nodeWorldSizes.map { $0.width }.reduce(0, +) / CGFloat(nodeWorldSizes.count)

        // Base margins (WORLD units)
        let baseMargin: CGFloat = (maxNodeSpan * shuffleBaseMarginWorldFactor)
            + (shuffleBaseMarginViewPadding / max(CGFloat(zoomScale), 0.000001)) // include a small view->world normalized margin
        let spacingMultiplier: CGFloat = shuffleSpacingMultiplier // arc-length spacing factor vs avg width
        let ringSeparationMultiplier: CGFloat = shuffleRingSeparationMultiplier // radial separation vs max node span

        // Start radius: clear the anchor's size plus margin (tighter factors)
        var radius: CGFloat = (max(anchorSize.width, anchorSize.height) * shuffleInitialAnchorFactor)
            + (maxNodeSpan * shuffleInitialNodeSpanFactor)
            + baseMargin

        // Mutable pool
        var pool: [BoardNode] = nodes
        var remaining = pool.count
        var ringIndex = 0

        // Random seed angles per ring
        while remaining > 0 {
            // Desired arc spacing along circumference to avoid overlap
            let desiredArcSpacing = max(avgNodeWidth, 1.0) * spacingMultiplier

            // Ensure capacity for this ring; grow radius until capacity >= 1
            func capacity(at r: CGFloat) -> Int {
                let circ = 2.0 * .pi * r
                return max(1, Int(floor(circ / desiredArcSpacing)))
            }
            var cap = capacity(at: radius)

            // If we still have many nodes, make sure this ring can hold a reasonable share;
            // grow radius until we can place at least 1 and up to remaining
            while cap == 0 {
                radius += max(6.0, maxNodeSpan * 0.20) // smaller growth step
                cap = capacity(at: radius)
            }

            let take = min(remaining, cap)
            let angleStep = (2.0 * .pi) / CGFloat(take)
            let startAngle = Double.random(in: 0..<(2.0 * Double.pi))

            for i in 0..<take {
                if let node = pool.popLast() {
                    // Even placement with small jitter (reduced)
                    let theta = startAngle + Double(i) * Double(angleStep)
                    let jitterR = Double.random(in: shuffleRadialJitterWorld) * Double(maxNodeSpan)
                    let jitterT = Double.random(in: shuffleAngularJitter)
                    let r = Double(radius) + jitterR
                    let x = anchor.x + (r * cos(theta + jitterT))
                    let y = anchor.y + (r * sin(theta + jitterT))
                    node.posX = x
                    node.posY = y
                }
            }

            remaining = pool.count
            ringIndex += 1
            // Increase radius for next ring with separation based on node spans in WORLD units (tighter)
            let ringSeparationWorld = max(maxNodeSpan * ringSeparationMultiplier + baseMargin, maxNodeSpan * 0.7)
            radius += ringSeparationWorld
        }

        try? modelContext.save()
    }
}
