//
//  RelatedEdgesList.swift
//  Cumberland
//
//  Compact list of all CardEdge relationships (incoming and outgoing) for a
//  given card. Used in the MurderBoard's node detail popover to show the full
//  relationship context without opening the full CardRelationshipView.
//

import SwiftUI
import SwiftData

struct RelatedEdgesList: View {
    let card: Card
    var title: String = "Relationships"

    @Environment(\.modelContext) private var modelContext
    @State private var edges: [CardEdge] = []
    @State private var edgeRepository: EdgeRepository?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if edges.isEmpty {
                Text("No relationships yet.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(Array(edges.enumerated()), id: \.offset) { _, edge in
                        HStack(spacing: 6) {
                            let label = edge.type?.forwardLabel ?? "—"
                            let name = edge.to?.name ?? "Unknown"
                            Text(label)
                                .font(.body)
                            Text("–")
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.body)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                .frame(minHeight: 120)
            }
        }
        .task(id: card.id) {
            // Initialize repository if needed
            if edgeRepository == nil {
                edgeRepository = EdgeRepository(modelContext: modelContext)
            }
            reload()
        }
        .onAppear {
            // Initialize repository if needed
            if edgeRepository == nil {
                edgeRepository = EdgeRepository(modelContext: modelContext)
            }
            reload()
        }
        .accessibilityElement(children: .contain)
    }

    @MainActor
    private func reload() {
        guard let repo = edgeRepository else { return }
        // Use EdgeRepository to fetch outgoing edges
        edges = repo.fetchOutgoing(from: card)
        // Note: EdgeRepository doesn't have sorted fetch, so we sort in-memory
        edges.sort { lhs, rhs in
            let lhsCode = lhs.type?.code ?? ""
            let rhsCode = rhs.type?.code ?? ""
            if lhsCode != rhsCode {
                return lhsCode < rhsCode
            }
            return (lhs.to?.name ?? "") < (rhs.to?.name ?? "")
        }
    }
}
