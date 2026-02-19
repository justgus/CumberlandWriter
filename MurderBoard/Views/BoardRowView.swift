//
//  BoardRowView.swift
//  MurderboardApp
//
//  Row view for a single InvestigationBoard in the boards list.
//  Displays board name, node count, and primary node name.
//

import SwiftUI

struct BoardRowView: View {
    let board: InvestigationBoard

    private var nodeCount: Int {
        board.nodes?.count ?? 0
    }

    private var primaryNodeName: String? {
        guard let primaryID = board.primaryNodeID else { return nil }
        return (board.nodes ?? []).first(where: { $0.id == primaryID })?.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(board.name.isEmpty ? "Untitled Board" : board.name)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Label("^[\(nodeCount) node](inflect: true)", systemImage: "circle.grid.3x3")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let primaryName = primaryNodeName {
                    Text(primaryName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
