//
//  ReassignRelationTypeSheet.swift
//  Cumberland
//
//  Sheet that lets the user reassign all CardEdges belonging to a source
//  RelationType to a different type before deleting it. Lists candidate
//  types, shows edge count, and performs bulk reassignment in the model
//  context when confirmed.
//

import SwiftUI
import SwiftData
import Combine

struct ReassignRelationTypeSheet: View {
    let source: RelationType
    var onDone: (Bool) -> Void // Bool: did reassign

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services

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
        guard let services = services else { return }
        let edges = services.edgeRepository.fetch(ofType: source)
        edgeCount = edges.count
    }

    @MainActor
    private func loadCandidates() async {
        guard let services = services else { return }
        let all = services.queryService.getAllRelationTypes()
        candidates = all.filter { $0.code != source.code }
        selectedCode = candidates.first?.code
    }

    @MainActor
    private func reassign() {
        guard let services = services else {
            onDone(false); dismiss(); return
        }
        guard let code = selectedCode, let target = candidates.first(where: { $0.code == code }) else {
            onDone(false); dismiss(); return
        }

        // Update all edges referencing source.type to target
        let edges = services.edgeRepository.fetch(ofType: source)
        for e in edges {
            e.type = target
        }
        try? modelContext.save()

        // Delete the source type using RelationTypeManager
        let relTypeManager = RelationTypeManager(modelContext: modelContext)
        try? relTypeManager.deleteRelationType(source)

        onDone(true)
        dismiss()
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
        inverseLabel: "is appeared by"
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

    return ReassignRelationTypeSheet(source: t1) { _ in }
        .modelContainer(container)
        .serviceContainer(services)
}
