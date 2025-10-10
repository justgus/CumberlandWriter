// RecentEdgesDiagnosticsView.swift
import SwiftUI
import SwiftData

struct RecentEdgesDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
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
                            Text(e.type.forwardLabel)
                                .font(.body)
                            Text("—")
                                .foregroundStyle(.secondary)
                            Text(e.from.name)
                                .font(.body)
                            Text("→")
                                .foregroundStyle(.secondary)
                            Text(e.to.name)
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
        var fetch = FetchDescriptor<CardEdge>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fetch.fetchLimit = 50
        edges = (try? modelContext.fetch(fetch)) ?? []
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        return f
    }()
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, RelationType.self, CardEdge.self, AppSettings.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.autosaveEnabled = false

    // Ensure AppSettings exists
    _ = AppSettings.fetchOrCreate(in: ctx)

    let rt = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    let a = Card(kind: .worlds, name: "Aether", subtitle: "", detailedText: "", sizeCategory: .standard)
    let b = Card(kind: .projects, name: "Project X", subtitle: "", detailedText: "", sizeCategory: .standard)
    ctx.insert(rt); ctx.insert(a); ctx.insert(b)
    for i in 0..<3 {
        let edge = CardEdge(from: a, to: b, type: rt, note: nil, createdAt: Date().addingTimeInterval(Double(-i * 60)))
        ctx.insert(edge)
    }
    try? ctx.save()

    return RecentEdgesDiagnosticsView()
        .modelContainer(container)
        .frame(width: 640, height: 480)
}

