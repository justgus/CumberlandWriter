//
//  EdgesLayer.swift  (formerly MBEdgesLayer.swift)
//  Cumberland
//
//  Created by Assistant on 11/1/25.
//
//  SwiftUI canvas layer that draws CardEdge relationship lines between
//  BoardNode positions on the Murderboard. Renders Bezier curve arrows
//  with relation-type labels, highlights selected edges, and draws the
//  in-progress edge during interactive edge creation.
//

import SwiftUI
import SwiftData

// MARK: - Edges Layer

struct EdgesLayer: View {
    let board: Board?
    let scheme: ColorScheme
    let worldToView: (CGPoint) -> CGPoint
    
    var body: some View {
        let edges = displayedEdges()
        Canvas { context, size in
            for e in edges {
                let p0 = worldToView(e.start)
                let p1 = worldToView(e.end)

                // Build a simple 2-point path
                var path = Path()
                path.move(to: p0)
                path.addLine(to: p1)

                // Resolve stops per 0224: along source→target, stops are [target border, grid contrast, source border]
                let sourceColor = nodeBorderColor(for: e.fromID)
                let targetColor = nodeBorderColor(for: e.toID)
                let midColor = gridContrastColor

                let gradient = Gradient(colors: [
                    targetColor,    // at source end (startPoint) per spec
                    midColor,       // middle
                    sourceColor     // at target end (endPoint) per spec
                ])

                context.stroke(
                    path,
                    with: .linearGradient(gradient, startPoint: p0, endPoint: p1),
                    style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

// MARK: - Edges Layer Implementation

extension EdgesLayer {
    // An undirected pair key for grouping edges between two cards
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
    
    // Compute the single displayed segment per card pair, deterministically (E1).
    // Returns card IDs and world-space endpoints for drawing.
    private func displayedEdges() -> [(fromID: UUID, toID: UUID, start: CGPoint, end: CGPoint)] {
        guard let b = board else { return [] }
        let nodes = (b.nodes ?? [])
        // Map cardID -> node center (world)
        var centers: [UUID: CGPoint] = [:]
        for n in nodes {
            if let id = n.card?.id {
                centers[id] = CGPoint(x: n.posX, y: n.posY)
            }
        }
        let memberIDs = Set(centers.keys)
        guard !memberIDs.isEmpty else { return [] }

        // Group candidate CardEdges by undirected pair
        var grouped: [UndirectedPair: [CardEdge]] = [:]

        for n in nodes {
            guard let card = n.card else { continue }
            let outs = card.outgoingEdges ?? []
            let ins = card.incomingEdges ?? []
            for e in outs + ins {
                guard let fromID = e.from?.id, let toID = e.to?.id else { continue }
                guard fromID != toID, memberIDs.contains(fromID), memberIDs.contains(toID) else { continue }
                let key = UndirectedPair(fromID, toID)
                grouped[key, default: []].append(e)
            }
        }

        func chooseEdge(_ list: [CardEdge]) -> CardEdge? {
            return list.min(by: { lhs, rhs in
                let lc = lhs.type?.code ?? ""
                let rc = rhs.type?.code ?? ""
                if lc != rc { return lc < rc }
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
                let lKey = [(lhs.from?.id.uuidString ?? ""), (lhs.to?.id.uuidString ?? ""), lc].joined(separator: "-")
                let rKey = [(rhs.from?.id.uuidString ?? ""), (rhs.to?.id.uuidString ?? ""), rc].joined(separator: "-")
                return lKey < rKey
            })
        }

        var result: [(UUID, UUID, CGPoint, CGPoint)] = []
        for (_, list) in grouped {
            guard let chosen = chooseEdge(list),
                  let fID = chosen.from?.id,
                  let tID = chosen.to?.id,
                  let p0 = centers[fID],
                  let p1 = centers[tID] else { continue }
            result.append((fID, tID, p0, p1))
        }
        return result
    }
    
    // Resolve the node border color used by CardView for a given card ID.
    // Default fallback is AccentColor if the card or kind is unavailable.
    private func nodeBorderColor(for cardID: UUID) -> Color {
        guard let b = board,
              let node = (b.nodes ?? []).first(where: { $0.card?.id == cardID }),
              let card = node.card
        else {
            return .accentColor
        }
        return card.kind.accentColor(for: scheme)
    }
    
    // Grid contrast color (light/dark aware) used as the middle stop of the edge gradient.
    private var gridContrastColor: Color {
        scheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9)
    }
}
