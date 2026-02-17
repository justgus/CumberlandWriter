//
//  BoardEdgeSelectionLayer.swift
//  BoardEngine
//
//  ER-0030: Invisible hit-test overlay for edge selection on the board canvas.
//  Renders transparent thick paths over each displayed edge so tap gestures
//  can select edges. Also shows the relationship type label on the selected edge.
//

import SwiftUI

// MARK: - Board Edge Selection Layer

/// Transparent overlay that enables tap-to-select on edges rendered by `BoardEdgesLayer`.
/// Uses the same deduplication logic to ensure visual/interaction parity.
public struct BoardEdgeSelectionLayer<DS: BoardDataSource>: View {
    let dataSource: DS
    let scheme: ColorScheme
    let zoomScale: Double
    let worldToView: (CGPoint) -> CGPoint
    let selectedEdgeSourceTarget: (UUID, UUID)?
    let onSelectEdge: (_ sourceNodeID: UUID, _ targetNodeID: UUID, _ typeCode: String) -> Void

    /// Hit-test tolerance in view-space points (half-width of the invisible stroke)
    private let hitTestWidth: CGFloat = 24

    public init(
        dataSource: DS,
        scheme: ColorScheme,
        zoomScale: Double,
        worldToView: @escaping (CGPoint) -> CGPoint,
        selectedEdgeSourceTarget: (UUID, UUID)? = nil,
        onSelectEdge: @escaping (_ sourceNodeID: UUID, _ targetNodeID: UUID, _ typeCode: String) -> Void
    ) {
        self.dataSource = dataSource
        self.scheme = scheme
        self.zoomScale = zoomScale
        self.worldToView = worldToView
        self.selectedEdgeSourceTarget = selectedEdgeSourceTarget
        self.onSelectEdge = onSelectEdge
    }

    public var body: some View {
        let edgesLayer = BoardEdgesLayer(
            dataSource: dataSource,
            scheme: scheme,
            worldToView: worldToView
        )
        let edges = edgesLayer.displayedEdges()

        ZStack {
            // Invisible hit-test paths for each edge
            ForEach(edges, id: \.fromID) { edge in
                edgeHitPath(for: edge)
            }

            // Label overlay for selected edge
            if let sel = selectedEdgeSourceTarget,
               let selected = edges.first(where: { isMatch($0, sel) }) {
                edgeLabel(for: selected)
            }
        }
    }

    // MARK: - Hit-Test Path

    @ViewBuilder
    private func edgeHitPath(for edge: BoardEdgesLayer<DS>.DisplayedEdge) -> some View {
        let p0 = worldToView(edge.start)
        let p1 = worldToView(edge.end)

        let hitShape = Path { path in
            path.move(to: p0)
            path.addLine(to: p1)
        }.strokedPath(StrokeStyle(lineWidth: hitTestWidth, lineCap: .round))

        Path { path in
            path.move(to: p0)
            path.addLine(to: p1)
        }
        .stroke(Color.clear, style: StrokeStyle(lineWidth: hitTestWidth, lineCap: .round))
        .contentShape(hitShape)
        .onTapGesture {
            onSelectEdge(edge.fromID, edge.toID, edge.typeCode)
        }
    }

    // MARK: - Edge Label

    @ViewBuilder
    private func edgeLabel(for edge: BoardEdgesLayer<DS>.DisplayedEdge) -> some View {
        let p0 = worldToView(edge.start)
        let p1 = worldToView(edge.end)
        let mid = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)

        // Format the type code for display (e.g., "owns/owned-by" → "owns / owned-by")
        let label = edge.typeCode.replacingOccurrences(of: "/", with: " / ")

        Text(label)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .foregroundStyle(.primary)
            .position(x: mid.x, y: mid.y - 14)
            .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func isMatch(_ edge: BoardEdgesLayer<DS>.DisplayedEdge, _ pair: (UUID, UUID)?) -> Bool {
        guard let (a, b) = pair else { return false }
        return (edge.fromID == a && edge.toID == b) || (edge.fromID == b && edge.toID == a)
    }
}
