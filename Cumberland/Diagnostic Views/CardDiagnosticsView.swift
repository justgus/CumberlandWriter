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
    @Environment(\.services) private var services

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
                Text(verbatim: card.name)
                    .font(.title2)
                if !card.subtitle.isEmpty {
                    Text(verbatim: card.subtitle)
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
                    Text(verbatim: card.detailedText)
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
        guard let services = services else { return }

        // Use EdgeRepository to fetch edges from this card
        let fetched = services.edgeRepository.fetchOutgoing(from: card)

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
    // Create in-memory container for preview
    let container = ModelContainerFactory.makeInMemoryContainer([
        Card.self, RelationType.self, CardEdge.self,
        StoryStructure.self, StructureElement.self,
        Board.self, BoardNode.self,
        Citation.self, Source.self,
        CalendarSystem.self, AppSettings.self, SuggestionFeedback.self
    ])
    let context = container.mainContext
    let services = ServiceContainer(modelContext: context)

    // Create sample data using repositories
    let relTypeManager = RelationTypeManager(modelContext: context)
    let relType = relTypeManager.ensureRelationType(
        code: "references",
        forwardLabel: "references",
        inverseLabel: "referenced by"
    )

    let cardRepo = CardRepository(modelContext: context)
    let a = try! cardRepo.createCard(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: "Windy highlands.")
    let p = try! cardRepo.createCard(kind: .projects, name: "Project X")
    let c = try! cardRepo.createCard(kind: .characters, name: "Mira", subtitle: "Scout")

    let edgeRepo = EdgeRepository(modelContext: context)
    try! edgeRepo.createRelationship(from: a, to: p, relationType: relType)
    try! edgeRepo.createRelationship(from: a, to: c, relationType: relType)

    return NavigationStack {
        CardDiagnosticsView(card: a)
    }
    .modelContainer(container)
    .serviceContainer(services)
}
