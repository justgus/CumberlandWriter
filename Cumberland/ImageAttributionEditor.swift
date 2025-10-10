// ImageAttributionEditor.swift
import SwiftUI
import SwiftData

struct ImageAttributionEditor: View {
    let card: Card
    let citation: Citation?
    var onSave: (Citation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Source.title, order: .forward) private var sources: [Source]

    @State private var selectedSource: Source?
    @State private var locator: String = ""
    @State private var excerpt: String = ""
    @State private var contextNote: String = ""

    @State private var isCreatingSource: Bool = false
    @State private var newSourceTitle: String = ""
    @State private var newSourceAuthors: String = ""

    init(card: Card, citation: Citation?, onSave: @escaping (Citation) -> Void) {
        self.card = card
        self.citation = citation
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(citation == nil ? "Add Image Attribution" : "Edit Image Attribution")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Choose Source", selection: Binding(get: {
                        selectedSource?.id
                    }, set: { newID in
                        selectedSource = sources.first(where: { $0.id == newID })
                    })) {
                        Text("— Select —").tag(UUID?.none)
                        ForEach(sources) { s in
                            Text(s.title).tag(Optional(s.id))
                        }
                    }
                    .labelsHidden()

                    Divider().opacity(0.3)

                    DisclosureGroup(isExpanded: $isCreatingSource) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Title", text: $newSourceTitle)
                            TextField("Authors", text: $newSourceAuthors)
                            Button {
                                createSource()
                            } label: {
                                Label("Create Source", systemImage: "plus")
                            }
                            .disabled(newSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.top, 6)
                    } label: {
                        Label("Create New Source", systemImage: "plus.circle")
                    }
                }
            }

            GroupBox("Attribution Details") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo")
                        Text("Kind: Image")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    TextField("Locator (e.g., p. 42, fig. 2, 00:12:15)", text: $locator)
                    TextField("Excerpt (optional)", text: $excerpt)
                    TextField("Note (optional)", text: $contextNote)
                }
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    saveCitation()
                }
                .disabled(selectedSource == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .onAppear {
            if let c = citation {
                selectedSource = c.source
                locator = c.locator
                excerpt = c.excerpt
                contextNote = c.contextNote ?? ""
            }
        }
    }

    private func createSource() {
        let title = newSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let s = Source(title: title, authors: newSourceAuthors)
        modelContext.insert(s)
        try? modelContext.save()
        selectedSource = s
        newSourceTitle = ""
        newSourceAuthors = ""
        isCreatingSource = false
    }

    private func saveCitation() {
        guard let src = selectedSource else { return }
        if let c = citation {
            c.source = src
            c.kind = .image
            c.locator = locator
            c.excerpt = excerpt
            c.contextNote = contextNote.isEmpty ? nil : contextNote
            try? modelContext.save()
            onSave(c)
        } else {
            let c = Citation(card: card, source: src, kind: .image, locator: locator, excerpt: excerpt, contextNote: contextNote.isEmpty ? nil : contextNote, createdAt: Date())
            modelContext.insert(c)
            try? modelContext.save()
            onSave(c)
        }
        dismiss()
    }
}
