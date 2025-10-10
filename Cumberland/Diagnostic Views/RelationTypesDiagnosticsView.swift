// RelationTypesDiagnosticsView.swift
import SwiftUI
import SwiftData

struct RelationTypesDiagnosticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RelationType.code, order: .forward) private var types: [RelationType]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relation Types")
                .font(.title3).bold()

            if types.isEmpty {
                Text("No relation types.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(types, id: \.code) { t in
                        HStack(spacing: 8) {
                            Text(t.code).font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 180, alignment: .leading)
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

            Spacer(minLength: 0)
        }
        .padding()
        .frame(minWidth: 560, minHeight: 420, alignment: .topLeading)
    }

    private func deleteType(_ t: RelationType) {
        modelContext.delete(t)
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, RelationType.self, CardEdge.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.autosaveEnabled = false

    let anyAny = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    let cites = RelationType(code: "cites", forwardLabel: "cites", inverseLabel: "cited by", sourceKind: .sources, targetKind: nil)
    let chToSc = RelationType(code: "appears-in/is-appeared-by", forwardLabel: "appears in", inverseLabel: "is appeared by", sourceKind: .characters, targetKind: .scenes)
    ctx.insert(anyAny)
    ctx.insert(cites)
    ctx.insert(chToSc)
    try? ctx.save()

    return RelationTypesDiagnosticsView()
        .modelContainer(container)
}
