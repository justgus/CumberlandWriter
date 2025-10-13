// SceneProjectRelationDiagnosticsView.swift
import SwiftUI
import SwiftData
import OSLog

struct SceneProjectRelationDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var nonCanonicalEdges: [EdgeInfo] = []
    @State private var isLoading: Bool = false
    @State private var fixInProgress: Bool = false
    @State private var statusMessage: String?

    private let canonicalCode = "stories/is-storied-by"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Cumberland", category: "Diagnostics.SceneProject")

    struct EdgeInfo: Identifiable, Hashable {
        let id = UUID()
        let edgeID: UUID
        let sceneID: UUID
        let projectID: UUID
        let sceneName: String
        let projectName: String
        let currentTypeCode: String?
        let createdAt: Date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            GroupBox {
                if isLoading {
                    ProgressView("Scanning…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if nonCanonicalEdges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No non-canonical Scene → Project relationships found.", systemImage: "checkmark.seal")
                            .foregroundStyle(.green)
                        Text("All Scene → Project edges use the canonical type “\(canonicalCode)”.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                } else {
                    list
                }
            }

            footer
        }
        .padding()
        .task {
            await refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: Kinds.scenes.systemImage)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        Kinds.scenes.accentColor(for: scheme).opacity(0.95),
                        .white.opacity(scheme == .dark ? 0.7 : 0.9)
                    )
                    .font(.caption2)
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Image(systemName: Kinds.projects.systemImage)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        Kinds.projects.accentColor(for: scheme).opacity(0.95),
                        .white.opacity(scheme == .dark ? 0.7 : 0.9)
                    )
                    .font(.caption2)
            }
            Text("Scene → Project Relationship Diagnostics")
                .font(.title3).bold()
            Text("Find and fix Scene → Project relationships that don’t use the canonical type “\(canonicalCode)”.")
                .foregroundStyle(.secondary)
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(nonCanonicalEdges.count) issue(s) found")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await fixAll() }
                } label: {
                    Label("Fix All", systemImage: "wrench.and.screwdriver.fill")
                }
                .disabled(fixInProgress || nonCanonicalEdges.isEmpty)
            }
            .padding(.bottom, 4)

            List {
                ForEach(nonCanonicalEdges) { info in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: Kinds.scenes.systemImage)
                                    .foregroundStyle(.secondary)
                                Text(info.sceneName)
                                    .font(.body)
                                    .lineLimit(1)
                                Text("→")
                                    .foregroundStyle(.secondary)
                                Image(systemName: Kinds.projects.systemImage)
                                    .foregroundStyle(.secondary)
                                Text(info.projectName)
                                    .font(.body)
                                    .lineLimit(1)
                            }
                            HStack(spacing: 8) {
                                Text("Current type:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(info.currentTypeCode ?? "nil")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.orange)
                                Text("Created:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(info.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            Task { await fixOne(info) }
                        } label: {
                            Label("Fix", systemImage: "wrench.adjustable.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(fixInProgress)
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(minHeight: 240)
        }
    }

    private var footer: some View {
        HStack {
            Button {
                Task { await refresh() }
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(isLoading || fixInProgress)

            if let statusMessage, !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    @MainActor
    private func refresh() async {
        isLoading = true
        statusMessage = nil
        defer { isLoading = false }

        let edges = await loadNonCanonicalEdges()
        withAnimation {
            self.nonCanonicalEdges = edges
        }
    }

    @MainActor
    private func fixAll() async {
        guard !nonCanonicalEdges.isEmpty else { return }
        fixInProgress = true
        statusMessage = nil
        defer { fixInProgress = false }

        let count = await normalizeAll()
        await refresh()
        statusMessage = "Fixed \(count) edge(s)."
    }

    @MainActor
    private func fixOne(_ info: EdgeInfo) async {
        fixInProgress = true
        statusMessage = nil
        defer { fixInProgress = false }

        let count = await normalize(edgeID: info.edgeID)
        await refresh()
        statusMessage = count == 1 ? "Fixed 1 edge." : "No change."
    }

    // MARK: - Data layer

    private func canonicalType() -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == canonicalCode })
        return try? modelContext.fetch(fetch).first
    }

    private func ensureCanonicalType() -> RelationType {
        if let t = canonicalType() { return t }
        let t = RelationType(code: canonicalCode, forwardLabel: "stories", inverseLabel: "is storied by", sourceKind: .scenes, targetKind: .projects)
        modelContext.insert(t)
        try? modelContext.save()
        return t
    }

    @MainActor
    private func loadNonCanonicalEdges() async -> [EdgeInfo] {
        // Fetch all edges, filter in-memory by kinds and non-canonical type
        let fetch = FetchDescriptor<CardEdge>(
            sortBy: [
                SortDescriptor(\.createdAt, order: .reverse)
            ]
        )
        let edges = (try? modelContext.fetch(fetch)) ?? []
        let result: [EdgeInfo] = edges.compactMap { e in
            guard let from = e.from, let to = e.to else { return nil }
            guard from.kind == .scenes, to.kind == .projects else { return nil }
            if e.type?.code == canonicalCode {
                return nil
            }
            return EdgeInfo(
                edgeID: e.persistentModelID.hashValue.uuid,
                sceneID: from.id,
                projectID: to.id,
                sceneName: from.name.isEmpty ? "Untitled Scene" : from.name,
                projectName: to.name.isEmpty ? "Untitled Project" : to.name,
                currentTypeCode: e.type?.code,
                createdAt: e.createdAt
            )
        }
        return result
    }

    @MainActor
    private func normalizeAll() async -> Int {
        let canonical = ensureCanonicalType()
        // Fetch all edges, mutate those that need it
        let fetch = FetchDescriptor<CardEdge>()
        let edges = (try? modelContext.fetch(fetch)) ?? []
        var changed = 0
        for e in edges {
            guard let from = e.from, let to = e.to else { continue }
            guard from.kind == .scenes, to.kind == .projects else { continue }
            if e.type?.code != canonical.code {
                e.type = canonical
                changed += 1
            }
        }
        if changed > 0 {
            do { try modelContext.save() } catch {
                logger.error("NormalizeAll save failed: \(String(describing: error))")
            }
        }
        return changed
    }

    @MainActor
    private func normalize(edgeID: UUID) async -> Int {
        let canonical = ensureCanonicalType()
        // There’s no public ID on CardEdge; re-find by from/to/type from our snapshot.
        // Safer approach: refetch all and change the first that matches scene+project and non-canonical type.
        let fetch = FetchDescriptor<CardEdge>()
        let edges = (try? modelContext.fetch(fetch)) ?? []
        guard let e = edges.first(where: { edge in
            guard let from = edge.from, let to = edge.to else { return false }
            return from.kind == .scenes && to.kind == .projects && edge.type?.code != canonical.code
        }) else {
            return 0
        }
        e.type = canonical
        do { try modelContext.save() } catch {
            logger.error("Normalize save failed: \(String(describing: error))")
        }
        return 1
    }
}

// Small helper to derive a UUID from a hash if we don’t have an exposed ID on CardEdge.
// This is only used for Identifiable in the diagnostics list and is not persisted.
private extension Int {
    var uuid: UUID {
        var hash = self
        var bytes = [UInt8](repeating: 0, count: 16)
        withUnsafeBytes(of: &hash) { raw in
            for i in 0..<Swift.min(16, raw.count) {
                bytes[i] = raw[i]
            }
        }
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                           bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

#Preview {
    // In-memory container preview
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])

    // Seed canonical type
    let ctx = container.mainContext
    let canonical = RelationType(code: "stories/is-storied-by", forwardLabel: "stories", inverseLabel: "is storied by", sourceKind: .scenes, targetKind: .projects)
    ctx.insert(canonical)

    // Sample cards
    let proj = Card(kind: .projects, name: "Project Alpha", subtitle: "", detailedText: "")
    let scene1 = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
    let scene2 = Card(kind: .scenes, name: "Climax", subtitle: "", detailedText: "")
    ctx.insert(proj); ctx.insert(scene1); ctx.insert(scene2)

    // Wrong type
    let wrongType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    ctx.insert(wrongType)
    ctx.insert(CardEdge(from: scene1, to: proj, type: wrongType))
    // Correct type
    ctx.insert(CardEdge(from: scene2, to: proj, type: canonical))

    return SceneProjectRelationDiagnosticsView()
        .modelContainer(container)
        .frame(minWidth: 700, minHeight: 420)
}
