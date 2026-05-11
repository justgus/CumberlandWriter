//
//  RelationTypesDiagnosticsView.swift
//  Cumberland
//
//  Developer diagnostic view listing all RelationType records with their
//  codes, forward/inverse labels, and edge counts. Provides a "Clean
//  Duplicates" action that merges duplicate types and reassigns orphaned
//  edges. Accessed from DeveloperToolsView.
//

import SwiftUI
import SwiftData

struct RelationTypesDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services

    @State private var types: [RelationType] = []
    @State private var isCleaning: Bool = false
    @State private var showConfirm: Bool = false
    @State private var lastReport: String = ""
    @State private var removedTypeCount: Int = 0
    @State private var reassignedEdgeCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            controls

            if !lastReport.isEmpty {
                GroupBox("Cleanup Report") {
                    ScrollView {
                        Text(lastReport)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                    }
                    .frame(minHeight: 140)
                }
            }

            listSection

            Spacer(minLength: 0)
        }
        .padding()
        .frame(minWidth: 560, minHeight: 460, alignment: .topLeading)
        .confirmationDialog(
            "Remove Duplicate Relation Types?",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Duplicates", role: .destructive) {
                Task { await removeDuplicateRelationTypes() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will merge duplicate RelationType rows that share the same code. All CardEdges referencing duplicates will be repointed to the canonical type, and the duplicates will be deleted. This cannot be undone.")
        }
        .task {
            await reloadData()
        }
    }

    @MainActor
    private func reloadData() async {
        guard let services = services else { return }
        types = services.queryService.getAllRelationTypes()
        // Sort by code
        types.sort { $0.code < $1.code }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Relation Types")
                .font(.title3).bold()
            if removedTypeCount > 0 || reassignedEdgeCount > 0 {
                HStack(spacing: 16) {
                    statView(title: "Types Removed", value: removedTypeCount, color: .red)
                    statView(title: "Edges Reassigned", value: reassignedEdgeCount, color: .blue)
                    Spacer()
                }
            }
        }
    }

    private func statView(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(value)").font(.headline).foregroundStyle(color)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button {
                showConfirm = true
            } label: {
                Label("Remove Duplicate Relation Types…", systemImage: "trash.slash")
            }
            .disabled(isCleaning)
            .help("Merge duplicate RelationTypes that share the same code. Reassigns edges to the canonical type, deletes duplicates, and saves.")

            if isCleaning {
                ProgressView().controlSize(.small)
            }

            Spacer()
        }
    }

    private var listSection: some View {
        Group {
            if types.isEmpty {
                Text("No relation types.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(types, id: \.code) { t in
                        HStack(spacing: 8) {
                            Text(t.code).font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 200, alignment: .leading)
                            Text(t.forwardLabel)
                            Text("↔︎")
                                .foregroundStyle(.secondary)
                            Text(t.inverseLabel)
                            Spacer()
                            let src = t.sourceKind?.title ?? "Any"
                            let dst = t.targetKind?.title ?? "Any"
                            Text("\(src) → \(dst)")
                                .foregroundStyle(.secondary)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteType(t)
                            } label: {
                                Label("Delete Relation Type", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { idx in
                        let toDelete = idx.compactMap { types.indices.contains($0) ? types[$0] : nil }
                        for t in toDelete { deleteType(t) }
                    }
                }
            }
        }
    }

    private func deleteType(_ t: RelationType) {
        guard let _ = services else { return }
        if let um = modelContext.undoManager {
            um.beginUndoGrouping()
            um.setActionName("Delete Relation Type")
        }
        let relTypeManager = RelationTypeManager(modelContext: modelContext)
        try? relTypeManager.deleteRelationType(t)
        modelContext.undoManager?.endUndoGrouping()
    }

    // MARK: - Duplicate removal

    @MainActor
    private func removeDuplicateRelationTypes() async {
        guard !isCleaning else { return }
        isCleaning = true
        defer { isCleaning = false }

        var lines: [String] = []
        lines.append("=== Remove Duplicate Relation Types ===")
        lines.append("Date: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")

        // Fetch all types fresh for a stable snapshot
        guard let services = services else { return }
        let allTypes = services.queryService.getAllRelationTypes()

        // Group by code
        let grouped = Dictionary(grouping: allTypes, by: { $0.code })
        var removed = 0
        var reassigned = 0

        func specificity(_ t: RelationType) -> Int {
            (t.sourceKindRaw == nil ? 0 : 1) + (t.targetKindRaw == nil ? 0 : 1)
        }

        func edgeCount(_ t: RelationType) -> Int {
            (t.edges?.count) ?? 0
        }

        // Stable tie-breaker
        func tieBreaker(_ t: RelationType) -> Int {
            ObjectIdentifier(t).hashValue
        }

        // Make the dedupe pass undoable as one action
        if let um = modelContext.undoManager {
            um.beginUndoGrouping()
            um.setActionName("Clean Duplicate Relation Types")
        }

        for (code, group) in grouped.sorted(by: { $0.key < $1.key }) {
            guard group.count > 1 else { continue }

            // Canonical: prefer more specific (non-nil kinds), then more edges, then stable
            let canonical = group.max { a, b in
                let sa = specificity(a), sb = specificity(b)
                if sa != sb { return sa < sb }
                let ea = edgeCount(a), eb = edgeCount(b)
                if ea != eb { return ea < eb }
                return tieBreaker(a) < tieBreaker(b)
            }!

            lines.append("Code: \(code) — \(group.count) duplicates found. Keeping canonical: \(canonicalDescription(canonical))")

            for dup in group {
                if dup === canonical { continue }

                let dupEdges = dup.edges ?? []
                if !dupEdges.isEmpty {
                    for e in dupEdges {
                        e.type = canonical
                        reassigned += 1
                    }
                }

                let relTypeManager = RelationTypeManager(modelContext: modelContext)
                try? relTypeManager.deleteRelationType(dup)
                removed += 1
                lines.append("  - Removed duplicate: \(canonicalDescription(dup)) (reassigned \(dupEdges.count) edge(s))")
            }
        }

        do {
            try modelContext.save()
        } catch {
            lines.append("")
            lines.append("ERROR: Failed to save after cleanup: \(String(describing: error))")
        }

        modelContext.undoManager?.endUndoGrouping()

        await reloadData()

        removedTypeCount = removed
        reassignedEdgeCount = reassigned

        lines.append("")
        lines.append("--- Summary ---")
        lines.append("Types removed: \(removed)")
        lines.append("Edges reassigned: \(reassigned)")
        lastReport = lines.joined(separator: "\n")
    }

    private func canonicalDescription(_ t: RelationType) -> String {
        let src = t.sourceKind?.title ?? "Any"
        let dst = t.targetKind?.title ?? "Any"
        return "\(t.code) [\(src) → \(dst)] “\(t.forwardLabel)”/“\(t.inverseLabel)”"
    }
}

#Preview {
    let container = ModelContainerFactory.makeInMemoryContainer([
        Card.self, RelationType.self, CardEdge.self,
        StoryStructure.self, StructureElement.self,
        Board.self, BoardNode.self,
        Citation.self, Source.self,
        CalendarSystem.self, AppSettings.self, SuggestionFeedback.self
    ])
    let ctx = container.mainContext
    let services = ServiceContainer(modelContext: ctx)

    // Seed: canonical + duplicates by code (directly insert for testing duplicates)
    let anyAny1 = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    let anyAny2 = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    let anyAny3 = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by", sourceKind: .projects, targetKind: .projects)

    let cites1 = RelationType(code: "cites", forwardLabel: "cites", inverseLabel: "cited by", sourceKind: .sources, targetKind: nil)
    let cites2 = RelationType(code: "cites", forwardLabel: "cites", inverseLabel: "cited by", sourceKind: .sources, targetKind: nil)

    ctx.insert(anyAny1); ctx.insert(anyAny2); ctx.insert(anyAny3)
    ctx.insert(cites1);  ctx.insert(cites2)

    // Create cards using repositories
    let cardRepo = CardRepository(modelContext: ctx)
    let a = try! cardRepo.createCard(kind: .projects, name: "Project A")
    let b = try! cardRepo.createCard(kind: .characters, name: "Mira")
    let c = try! cardRepo.createCard(kind: .sources, name: "Paper")

    // Create edges using EdgeRepository
    let edgeRepo = EdgeRepository(modelContext: ctx)
    try! edgeRepo.createRelationship(from: b, to: a, relationType: anyAny2)
    try! edgeRepo.createRelationship(from: c, to: a, relationType: cites2)

    return RelationTypesDiagnosticsView()
        .modelContainer(container)
        .serviceContainer(services)
}

