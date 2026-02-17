//
//  BoardEdgesLayer.swift
//  BoardEngine
//
//  Generic canvas layer that draws relationship arrows between nodes.
//  Groups edges by undirected pair and deterministically selects one
//  edge per pair to display, avoiding duplicate rendering of
//  bidirectional relationships.
//

import SwiftUI

// MARK: - Board Edges Layer

/// Renders edges between nodes on the board canvas using a SwiftUI Canvas.
public struct BoardEdgesLayer<DS: BoardDataSource>: View {
    let dataSource: DS
    let scheme: ColorScheme
    let worldToView: (CGPoint) -> CGPoint
    let selectedEdgeSourceTarget: (UUID, UUID)?

    public init(
        dataSource: DS,
        scheme: ColorScheme,
        worldToView: @escaping (CGPoint) -> CGPoint,
        selectedEdgeSourceTarget: (UUID, UUID)? = nil
    ) {
        self.dataSource = dataSource
        self.scheme = scheme
        self.worldToView = worldToView
        self.selectedEdgeSourceTarget = selectedEdgeSourceTarget
    }

    public var body: some View {
        let edges = displayedEdges()
        Canvas { context, size in
            for e in edges {
                let p0 = worldToView(e.start)
                let p1 = worldToView(e.end)

                var path = Path()
                path.move(to: p0)
                path.addLine(to: p1)

                let isSelected = isEdgeSelected(e)

                let sourceColor = e.sourceAccent
                let targetColor = e.targetAccent
                let midColor = gridContrastColor

                let gradient = Gradient(colors: [
                    targetColor,
                    midColor,
                    sourceColor
                ])

                // Draw glow behind selected edge
                if isSelected {
                    context.stroke(
                        path,
                        with: .color(.accentColor.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round)
                    )
                }

                context.stroke(
                    path,
                    with: .linearGradient(gradient, startPoint: p0, endPoint: p1),
                    style: StrokeStyle(lineWidth: isSelected ? 5.0 : 3.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func isEdgeSelected(_ edge: DisplayedEdge) -> Bool {
        guard let (selA, selB) = selectedEdgeSourceTarget else { return false }
        let pairMatches = (edge.fromID == selA && edge.toID == selB)
            || (edge.fromID == selB && edge.toID == selA)
        return pairMatches
    }
}

// MARK: - Implementation

extension BoardEdgesLayer {
    private struct UndirectedPair: Hashable {
        let a: UUID
        let b: UUID
        init(_ i1: UUID, _ i2: UUID) {
            if i1.uuidString < i2.uuidString {
                a = i1; b = i2
            } else {
                a = i2; b = i1
            }
        }
    }

    /// A single edge resolved for display (after deduplication).
    public struct DisplayedEdge {
        public let fromID: UUID
        public let toID: UUID
        public let typeCode: String
        public let start: CGPoint
        public let end: CGPoint
        public let sourceAccent: Color
        public let targetAccent: Color
    }

    /// Returns the deduplicated set of edges to display on the canvas.
    public func displayedEdges() -> [DisplayedEdge] {
        let nodes = dataSource.nodes
        var centers: [UUID: CGPoint] = [:]
        var accentColors: [UUID: Color] = [:]
        for n in nodes {
            centers[n.nodeID] = CGPoint(x: n.posX, y: n.posY)
            accentColors[n.nodeID] = n.accentColor(for: scheme)
        }
        let memberIDs = Set(centers.keys)
        guard !memberIDs.isEmpty else { return [] }

        let allEdges = dataSource.edges(for: memberIDs)

        var grouped: [UndirectedPair: [DS.Edge]] = [:]
        for e in allEdges {
            let fID = e.sourceNodeID
            let tID = e.targetNodeID
            guard fID != tID, memberIDs.contains(fID), memberIDs.contains(tID) else { continue }
            let key = UndirectedPair(fID, tID)
            grouped[key, default: []].append(e)
        }

        func chooseEdge(_ list: [DS.Edge]) -> DS.Edge? {
            return list.min(by: { lhs, rhs in
                let lc = lhs.typeCode
                let rc = rhs.typeCode
                if lc != rc { return lc < rc }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                let lKey = [lhs.sourceNodeID.uuidString, lhs.targetNodeID.uuidString, lc].joined(separator: "-")
                let rKey = [rhs.sourceNodeID.uuidString, rhs.targetNodeID.uuidString, rc].joined(separator: "-")
                return lKey < rKey
            })
        }

        var result: [DisplayedEdge] = []
        for (_, list) in grouped {
            guard let chosen = chooseEdge(list),
                  let p0 = centers[chosen.sourceNodeID],
                  let p1 = centers[chosen.targetNodeID] else { continue }
            result.append(DisplayedEdge(
                fromID: chosen.sourceNodeID,
                toID: chosen.targetNodeID,
                typeCode: chosen.typeCode,
                start: p0,
                end: p1,
                sourceAccent: accentColors[chosen.sourceNodeID] ?? .accentColor,
                targetAccent: accentColors[chosen.targetNodeID] ?? .accentColor
            ))
        }
        return result
    }

    private var gridContrastColor: Color {
        scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9)
    }
}
