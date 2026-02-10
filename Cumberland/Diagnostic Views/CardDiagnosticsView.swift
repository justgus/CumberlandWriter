//
//  CardDiagnosticsView.swift
//  Cumberland
//
//  Developer diagnostic view showing detailed SwiftData state for a single
//  card: forward and incoming edges with source/target IDs, relation-type
//  codes, and temporal position data. Used from DeveloperToolsView when
//  investigating relationship data integrity issues.
//

import SwiftUI
import SwiftData

struct CardDiagnosticsView: View {
    let card: Card
    @Environment(\.modelContext) private var modelContext

    @State private var forwardEdges: [CardEdge] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 6) {
                    Image(systemName: card.kind.systemImage)
                        .foregroundStyle(.secondary)
                    Text(card.kind.title)
                        .font(.title3).bold()
                }
                Text(card.name)
                    .font(.title2)
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .foregroundStyle(.secondary)
                }

                // Relationships (labeled, with empty state)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationships")
                        .font(.headline)

                    if forwardEdges.isEmpty {
                        Text("No relationships yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        List {
                            ForEach(forwardEdges, id: \.createdAt) { edge in
                                HStack {
                                    Text(edge.type?.forwardLabel ?? "—")
                                    Text("–")
                                        .foregroundStyle(.secondary)
                                    Text(edge.to?.name ?? "Untitled")
                                }
                            }
                        }
                        .frame(minHeight: 120)
                    }
                }
                .padding(.top, 4)

                // Details
                if !card.detailedText.isEmpty {
                    Divider()
                    Text(card.detailedText)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .task(id: card.id) {
            reloadForwardEdges()
        }
        .onAppear {
            reloadForwardEdges()
        }
        .navigationTitle("\(card.kind.title): \(card.name)")
    }

    @MainActor
    private func reloadForwardEdges() {
        // Match optional relationship key path with an optional RHS value in the predicate.
        let fromIDOpt: UUID? = card.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == fromIDOpt },
            // Avoid sorting across optional relationships in the fetch; sort in-memory below.
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let fetched = (try? modelContext.fetch(fetch)) ?? []

        // In-memory sort: by type code, then by 'to' name, then by createdAt for stability.
        forwardEdges = fetched.sorted { a, b in
            let aType = a.type?.code ?? ""
            let bType = b.type?.code ?? ""
            if aType != bType { return aType < bType }

            let aName = a.to?.name ?? ""
            let bName = b.to?.name ?? ""
            if aName != bName { return aName < bName }

            return a.createdAt < b.createdAt
        }
    }
}

#Preview {
    let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    let a = Card(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: "Windy highlands.", sizeCategory: .standard)
    let p = Card(kind: .projects, name: "Project X", subtitle: "", detailedText: "", sizeCategory: .standard)
    let c = Card(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: "", sizeCategory: .compact)
    let _ = CardEdge(from: a, to: p, type: relType)
    let _ = CardEdge(from: a, to: c, type: relType)

    return NavigationStack {
        CardDiagnosticsView(card: a)
    }
    .modelContainer(for: [Card.self, RelationType.self, CardEdge.self], inMemory: true)
}
