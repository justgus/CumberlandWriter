//
//  RelationTypesManagerView.swift
//  Cumberland
//
//  Full CRUD manager for RelationType records. Displays a searchable list of
//  all relation types with forward/inverse labels, and provides add, edit,
//  and delete (with reassignment flow) actions. Accessible from Settings and
//  the relationship editor toolbar.
//

import SwiftUI
import SwiftData

struct RelationTypesManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @Environment(\.services) private var services
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var types: [RelationType] = []
    @State private var searchText: String = ""
    @State private var isPresentingNew: Bool = false
    @State private var editing: RelationType? = nil

    @State private var toDelete: RelationType? = nil
    @State private var showDeleteAlert: Bool = false
    @State private var reassignSource: RelationType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            GroupBox {
                if filtered.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("No relation types found")
                            .font(.headline)
                        Text("Create a new type to get started.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    list
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .frame(minWidth: 680, minHeight: 420)
        .task {
            await reloadData()
        }
        .sheet(isPresented: $isPresentingNew) {
            RelationTypeFormView(
                mode: .create,
                initialSourceKind: nil,
                initialTargetKind: nil
            ) { _ in
                isPresentingNew = false
            }
            .frame(minWidth: 480, minHeight: 420)
            .environmentObject(themeManager)
        }
        .sheet(item: $editing) { type in
            RelationTypeFormView(mode: .edit(type)) { _ in
                editing = nil
            }
            .frame(minWidth: 480, minHeight: 420)
            .environmentObject(themeManager)
        }
        .sheet(item: $reassignSource) { src in
            ReassignRelationTypeSheet(source: src) { didReassign in
                if didReassign {
                    // If reassigned, the source type has already been deleted by the sheet.
                }
            }
            .frame(minWidth: 520, minHeight: 380)
            .environmentObject(themeManager)
        }
        .alert("Delete Relation Type?", isPresented: $showDeleteAlert, presenting: toDelete) { type in
            Button("Cancel", role: .cancel) { toDelete = nil }

            if usageCount(for: type) == 0 {
                Button("Delete", role: .destructive) { delete(type) }
            } else {
                Button("Reassign…") {
                    reassignSource = type
                    toDelete = nil
                }
                Button("Force Delete", role: .destructive) {
                    nullifyEdges(of: type)
                    delete(type)
                }
            }
        } message: { type in
            let count = usageCount(for: type)
            if count == 0 {
                Text("This type is not used by any relationships. It’s safe to delete.")
            } else {
                Text("This type is used by \(count) relationship(s). Reassign those edges to another type, or force delete to clear their type reference.")
            }
        }
    }

    @MainActor
    private func reloadData() async {
        guard let services = services else { return }
        types = services.queryService.getAllRelationTypes()
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Relation Types", systemImage: "link")
                .font(.title3.bold())

            Spacer()

            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)

            Button {
                isPresentingNew = true
            } label: {
                Label("New Type", systemImage: "plus")
            }
            .keyboardShortcut("N", modifiers: [.command])

            Button {
                deleteAllUnused()
            } label: {
                Label("Delete Unused", systemImage: "trash")
            }
            .help("Remove all relation types that are not referenced by any edges")
            .disabled(unusedTypes().isEmpty)
        }
    }

    private var list: some View {
        List {
            ForEach(filtered, id: \.code) { t in
                HStack(spacing: 8) {
                    Text(t.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .frame(width: 220, alignment: .leading)

                    Text(t.forwardLabel)
                        .lineLimit(1)
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                    Text(t.inverseLabel)
                        .lineLimit(1)

                    Spacer()

                    kindBadge("From", kindRaw: t.sourceKindRaw)
                    Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                    kindBadge("To", kindRaw: t.targetKindRaw)

                    let count = usageCount(for: t)
                    Text("\(count)")
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background((count == 0 ? Color.green.opacity(0.18) : Color.secondary.opacity(0.14)), in: Capsule())
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { editing = t }
                .contextMenu {
                    Button { editing = t } label: { Label("Edit", systemImage: "pencil") }
                    if usageCount(for: t) == 0 {
                        Button(role: .destructive) { delete(t) } label: { Label("Delete", systemImage: "trash") }
                    } else {
                        Button { reassignSource = t } label: { Label("Reassign…", systemImage: "arrow.triangle.2.circlepath") }
                        Button(role: .destructive) {
                            toDelete = t
                            showDeleteAlert = true
                        } label: { Label("Force Delete…", systemImage: "trash.slash") }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button { editing = t } label: { Label("Edit", systemImage: "pencil") }.tint(.accentColor)
                    if usageCount(for: t) == 0 {
                        Button(role: .destructive) { delete(t) } label: { Label("Delete", systemImage: "trash") }
                    } else {
                        Button { reassignSource = t } label: { Label("Reassign…", systemImage: "arrow.triangle.2.circlepath") }.tint(.orange)
                    }
                }
            }
        }
    }

    private var filtered: [RelationType] {
        let s = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !s.isEmpty else { return types }
        return types.filter { t in
            t.code.lowercased().contains(s) ||
            t.forwardLabel.lowercased().contains(s) ||
            t.inverseLabel.lowercased().contains(s) ||
            (t.sourceKindRaw?.lowercased().contains(s) ?? false) ||
            (t.targetKindRaw?.lowercased().contains(s) ?? false)
        }
    }

    private func kindBadge(_ title: String, kindRaw: String?) -> some View {
        HStack(spacing: 4) {
            if let raw = kindRaw, let k = Kinds(rawValue: raw) {
                Image(systemName: k.systemImage).font(.caption2)
                Text(k.singularTitle).font(.caption2)
            } else {
                Image(systemName: "circle.dotted").font(.caption2)
                Text("Any").font(.caption2)
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(.quinary, in: Capsule())
        .foregroundStyle(.secondary)
    }

    // MARK: - Usage / deletion helpers

    private func usageCount(for type: RelationType) -> Int {
        guard let services = services else { return 0 }
        let edges = services.edgeRepository.fetch(ofType: type)
        return edges.count
    }

    private func nullifyEdges(of type: RelationType) {
        guard let services = services else { return }
        try? services.edgeRepository.nullifyAllEdges(ofType: type)
    }

    private func delete(_ type: RelationType) {
        let relTypeManager = RelationTypeManager(modelContext: modelContext)
        try? relTypeManager.deleteRelationType(type)
        Task { await reloadData() }
    }

    private func unusedTypes() -> [RelationType] {
        types.filter { usageCount(for: $0) == 0 }
    }

    private func deleteAllUnused() {
        let unused = unusedTypes()
        guard !unused.isEmpty else { return }
        let relTypeManager = RelationTypeManager(modelContext: modelContext)
        for t in unused {
            try? relTypeManager.deleteRelationType(t)
        }
        Task { await reloadData() }
    }
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

    // Create relation types using RelationTypeManager
    let relTypeManager = RelationTypeManager(modelContext: ctx)
    let t1 = relTypeManager.ensureRelationType(
        code: "appears-in/is-appeared-by",
        forwardLabel: "appears in",
        inverseLabel: "is appeared by",
        sourceKind: .characters,
        targetKind: .scenes
    )
    let _ = relTypeManager.ensureRelationType(
        code: "references/referenced-by",
        forwardLabel: "references",
        inverseLabel: "referenced by"
    )

    // Create cards using CardRepository
    let cardRepo = CardRepository(modelContext: ctx)
    let a = try! cardRepo.createCard(kind: .characters, name: "Mira")
    let b = try! cardRepo.createCard(kind: .scenes, name: "Opening")

    // Create edge using EdgeRepository
    let edgeRepo = EdgeRepository(modelContext: ctx)
    try! edgeRepo.createRelationship(from: a, to: b, relationType: t1)

    try? ctx.save()

    return RelationTypesManagerView()
        .modelContainer(container)
        .serviceContainer(services)
}
