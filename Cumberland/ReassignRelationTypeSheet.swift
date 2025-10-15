import SwiftUI
import SwiftData

struct ReassignRelationTypeSheet: View {
    let source: RelationType
    var onDone: (Bool) -> Void // Bool: did reassign

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var candidates: [RelationType] = []
    @State private var selectedCode: String? = nil
    @State private var edgeCount: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reassign Relation Type")
                .font(.title3.bold())

            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(source.code).font(.caption.monospaced()).foregroundStyle(.secondary)
                        Text(source.forwardLabel)
                        Text("↔︎").foregroundStyle(.secondary)
                        Text(source.inverseLabel)
                        Spacer()
                        Text("\(edgeCount) edge(s)")
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.14), in: Capsule())
                    }
                }
            }

            GroupBox("Reassign To") {
                if candidates.isEmpty {
                    Text("No compatible relation types found.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                } else {
                    Picker("Type", selection: $selectedCode) {
                        ForEach(candidates, id: \.code) { t in
                            HStack(spacing: 8) {
                                Text(t.code).font(.caption.monospaced()).foregroundStyle(.secondary)
                                Text(t.forwardLabel)
                                Text("↔︎").foregroundStyle(.secondary)
                                Text(t.inverseLabel)
                            }
                            .tag(Optional(t.code))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    onDone(false)
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    reassign()
                } label: {
                    Label("Reassign and Delete", systemImage: "arrow.triangle.2.circlepath")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedCode == nil || candidates.isEmpty)
            }
        }
        .padding()
        .task {
            await loadUsage()
            await loadCandidates()
        }
    }

    @MainActor
    private func loadUsage() async {
        let codeOpt: String? = source.code
        let fetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == codeOpt })
        let edges = (try? modelContext.fetch(fetch)) ?? []
        edgeCount = edges.count
    }

    @MainActor
    private func loadCandidates() async {
        let all = (try? modelContext.fetch(FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)]))) ?? []
        candidates = all.filter { $0.code != source.code }
        selectedCode = candidates.first?.code
    }

    @MainActor
    private func reassign() {
        guard let code = selectedCode, let target = candidates.first(where: { $0.code == code }) else {
            onDone(false); dismiss(); return
        }
        // Update all edges referencing source.type to target
        let srcCode: String? = source.code
        let fetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.type?.code == srcCode })
        let edges = (try? modelContext.fetch(fetch)) ?? []
        for e in edges {
            e.type = target
        }
        try? modelContext.save()

        // Delete the source type
        modelContext.delete(source)
        try? modelContext.save()

        onDone(true)
        dismiss()
    }
}

#Preview {
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let ctx = container.mainContext

    let t1 = RelationType(code: "appears-in/is-appeared-by", forwardLabel: "appears in", inverseLabel: "is appeared by")
    let t2 = RelationType(code: "references/referenced-by", forwardLabel: "references", inverseLabel: "referenced by")
    ctx.insert(t1); ctx.insert(t2)

    let a = Card(kind: .characters, name: "Mira", subtitle: "", detailedText: "")
    let b = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
    ctx.insert(a); ctx.insert(b)
    ctx.insert(CardEdge(from: a, to: b, type: t1))

    try? ctx.save()

    return ReassignRelationTypeSheet(source: t1) { _ in }.modelContainer(container)
}
