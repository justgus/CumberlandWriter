//
//  CitationEditor.swift
//  Cumberland
//
//  Form for creating or editing a Citation linked to a card and a Source.
//  Collects citation kind (quote, paraphrase, image, data), page/location,
//  excerpt, and notes, then inserts or updates the Citation in the SwiftData
//  context on save.
//

import SwiftUI
import SwiftData

struct CitationEditor: View {
    let card: Card
    let citation: Citation?
    var onSave: (Citation) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Source.title, order: .forward) private var sources: [Source]

    @State private var selectedSource: Source?
    @State private var kind: CitationKind = .quote
    @State private var locator: String = ""
    @State private var excerpt: String = ""
    @State private var contextNote: String = ""

    @State private var isCreatingSource: Bool = false
    @State private var newSourceTitle: String = ""
    @State private var newSourceAuthors: String = ""

    // Note: initializer remains internal because it references internal model types.
    init(card: Card, citation: Citation?, onSave: @escaping (Citation) -> Void) {
        self.card = card
        self.citation = citation
        self.onSave = onSave
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(citation == nil ? "Add Citation" : "Edit Citation")
                .font(.title3).bold()

            GroupBox("Source") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Choose Source", selection: Binding(get: {
                        selectedSource?.id
                    }, set: { newID in
                        selectedSource = sources.first(where: { $0.id == newID })
                    })) {
                        Text("— Select —").tag(UUID?.none)
                        ForEach(sources, id: \.id) { s in
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

            GroupBox("Details") {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Kind", selection: $kind) {
                        ForEach(CitationKind.allCases, id: \.self) { k in
                            Text(k.displayName).tag(k)
                        }
                    }
                    TextField("Locator (e.g., p. 42, §3.2, 00:12:15)", text: $locator)
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
                kind = c.kind
                locator = c.locator
                excerpt = c.excerpt
                contextNote = c.contextNote ?? ""
            }
        }
    }

    private func createSource() {
        let title = newSourceTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let manager = CitationManager(modelContext: modelContext)
        selectedSource = manager.createSource(title: title, authors: newSourceAuthors)

        newSourceTitle = ""
        newSourceAuthors = ""
        isCreatingSource = false
    }

    private func saveCitation() {
        guard let src = selectedSource else { return }
        let manager = CitationManager(modelContext: modelContext)
        let noteValue = contextNote.isEmpty ? nil : contextNote
        if let c = citation {
            manager.updateCitation(c, source: src, kind: kind, locator: locator, excerpt: excerpt, contextNote: noteValue)
            onSave(c)
        } else {
            let c = manager.createCitation(card: card, source: src, kind: kind, locator: locator, excerpt: excerpt, contextNote: noteValue)
            onSave(c)
        }
        dismiss()
    }
}
