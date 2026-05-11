//
//  RecentEdgesDiagnosticsView.swift
//  Cumberland
//
//  Developer diagnostic view listing the most recently created CardEdge
//  records with their from/to card names, relation-type code, and creation
//  timestamps. Useful for verifying that relationship operations produce
//  the expected edges. Accessed from DeveloperToolsView.
//

import SwiftUI
import SwiftData

struct RecentEdgesDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    @State private var edges: [CardEdge] = []

    // Follow app appearance setting
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]

    private var appSettings: AppSettings? { settingsResults.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 50 Edges")
                .font(.title3).bold()

            if edges.isEmpty {
                Text("No edges found.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(edges, id: \.createdAt) { e in
                        HStack(spacing: 8) {
                            Text(Self.formatter.string(from: e.createdAt))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 160, alignment: .leading)
                            Text(e.type?.forwardLabel ?? "—")
                                .font(.body)
                            Text("—")
                                .foregroundStyle(.secondary)
                            Text(e.from?.name ?? "—")
                                .font(.body)
                            Text("→")
                                .foregroundStyle(.secondary)
                            Text(e.to?.name ?? "—")
                                .font(.body)
                        }
                        .lineLimit(1)
                        .truncationMode(.middle)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
        .task { await reload() }
        .preferredColorScheme(appSettings?.colorSchemePreference.resolvedColorScheme)
    }

    @MainActor
    private func reload() async {
        guard let services = services else { return }
        edges = services.edgeRepository.fetchRecentlyCreated(limit: 50)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
}

#Preview { @MainActor in
    let container = ModelContainerFactory.makeInMemoryContainer([
        Card.self, RelationType.self, CardEdge.self,
        StoryStructure.self, StructureElement.self,
        Board.self, BoardNode.self,
        Citation.self, Source.self,
        CalendarSystem.self, AppSettings.self, SuggestionFeedback.self
    ])
    let ctx = container.mainContext
    let services = ServiceContainer(modelContext: ctx)

    // Ensure AppSettings exists
    _ = AppSettings.fetchOrCreate(in: ctx)

    // Create sample data using repositories
    let relTypeManager = RelationTypeManager(modelContext: ctx)
    let rt = relTypeManager.ensureRelationType(
        code: "references",
        forwardLabel: "references",
        inverseLabel: "referenced by"
    )

    let cardRepo = CardRepository(modelContext: ctx)
    let a = try! cardRepo.createCard(kind: .worlds, name: "Aether")
    let b = try! cardRepo.createCard(kind: .projects, name: "Project X")

    let edgeRepo = EdgeRepository(modelContext: ctx)
    for _ in 0..<3 {
        try! edgeRepo.createRelationship(from: a, to: b, relationType: rt)
    }

    return RecentEdgesDiagnosticsView()
        .modelContainer(container)
        .serviceContainer(services)
        .frame(width: 640, height: 480)
}
