//
//  RelatedEdgesList.swift
//  Cumberland
//
//  Compact list of all CardEdge relationships (incoming and outgoing) for a
//  given card. Used in the Murderboard's node detail popover to show the full
//  relationship context without opening the full CardRelationshipView.
//

import SwiftUI
import SwiftData

struct RelatedEdgesList: View {
    let card: Card
    var title: String = "Relationships"

    @Environment(\.modelContext) private var modelContext
    @State private var edges: [CardEdge] = []

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
            reload()
        }
        .onAppear { reload() }
        .accessibilityElement(children: .contain)
    }

    @MainActor
    private func reload() {
        let fromID = card.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == fromID },
            sortBy: [
                SortDescriptor(\.type?.code, order: .forward),
                SortDescriptor(\.to?.name, order: .forward)
            ]
        )
        edges = (try? modelContext.fetch(fetch)) ?? []
    }
}
