//
//  CitationViewer.swift
//  Cumberland
//
//  List view for all Citations attached to a card. Groups citations by kind,
//  displays source title and excerpt, and provides add/edit/delete actions.
//  Uses CitationEditor sheet for create/edit flows.
//

import SwiftUI
import SwiftData

struct CitationViewer: View {
    let card: Card

    @Environment(\.modelContext) private var modelContext

    @State private var citations: [Citation] = []
    @State private var isShowingAddCitation: Bool = false
    @State private var editingCitation: Citation?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Citations")
                    .font(.headline)
                Spacer()
                Button {
                    isShowingAddCitation = true
                } label: {
                    Label("Add Citation", systemImage: "plus")
                }
            }

            if citations.isEmpty {
                Text("No citations yet for this card.")
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(citations, id: \.id) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.source?.title ?? "Untitled Source")
                                    .font(.subheadline).bold()
                                Spacer()
                                Text(c.kind.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !c.locator.isEmpty {
                                Text("Locator: \(c.locator)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !c.excerpt.isEmpty {
                                Text("“\(c.excerpt)”")
                                    .font(.footnote)
                            }
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                editingCitation = c
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deleteCitation(c)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture(count: 2) {
                            editingCitation = c
                        }
                    }
                    .onDelete { idx in
                        let toDelete = idx.compactMap { citations.indices.contains($0) ? citations[$0] : nil }
                        for c in toDelete { deleteCitation(c) }
                    }
                }
                .frame(minHeight: 140)
            }
        }
        .padding(.vertical, 8)
        .onAppear { reloadCitations() }
        .onChange(of: editingCitation) { _, _ in reloadCitations() }
        .sheet(isPresented: $isShowingAddCitation) {
            CitationEditor(card: card, citation: nil) { _ in
                reloadCitations()
            }
            .frame(minWidth: 420, minHeight: 360)
        }
        .sheet(
            isPresented: Binding(
                get: { editingCitation != nil },
                set: { if !$0 { editingCitation = nil } }
            )
        ) {
            if let c = editingCitation {
                CitationEditor(card: card, citation: c) { _ in
                    reloadCitations()
                }
                .frame(minWidth: 420, minHeight: 360)
            } else {
                EmptyView()
                    .frame(minWidth: 420, minHeight: 360)
            }
        }
    }

    private func reloadCitations() {
        let cardID = card.id
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == cardID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        citations = (try? modelContext.fetch(fetch)) ?? []
    }

    private func deleteCitation(_ c: Citation) {
        modelContext.delete(c)
        try? modelContext.save()
        reloadCitations()
    }
}

#Preview("CitationViewer – Light") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, Source.self, Citation.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.autosaveEnabled = false

    // Seed sample data
    let card = Card(
        kind: .projects,
        name: "Sample Card",
        subtitle: "Subtitle",
        detailedText: "Details",
        author: "Author",
        sizeCategory: .standard
    )
    let s1 = Source(title: "The Book", authors: "J. Doe")
    let s2 = Source(title: "The Article", authors: "A. Author")
    let t0 = Date()
    let c1 = Citation(card: card, source: s1, kind: .quote,      locator: "p. 10", excerpt: "Quoted text", contextNote: "Intro", createdAt: t0.addingTimeInterval(0.1))
    let c2 = Citation(card: card, source: s2, kind: .paraphrase, locator: "§3.2",  excerpt: "Paraphrased idea", contextNote: nil, createdAt: t0.addingTimeInterval(0.2))
    ctx.insert(card); ctx.insert(s1); ctx.insert(s2); ctx.insert(c1); ctx.insert(c2)
    try? ctx.save()

    return CitationViewer(card: card)
        .padding()
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("CitationViewer – Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, Source.self, Citation.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.autosaveEnabled = false

    // Seed sample data
    let card = Card(
        kind: .characters,
        name: "Ada",
        subtitle: "The Analyst",
        detailedText: "Curious and meticulous.",
        author: "M. S.",
        sizeCategory: .standard
    )
    let s1 = Source(title: "Source Alpha", authors: "A. A.")
    let s2 = Source(title: "Source Beta", authors: "B. B.")
    let t0 = Date()
    let c1 = Citation(card: card, source: s1, kind: .data,       locator: "tbl. 2", excerpt: "",              contextNote: nil, createdAt: t0.addingTimeInterval(0.1))
    let c2 = Citation(card: card, source: s2, kind: .quote,      locator: "",       excerpt: "Insightful bit", contextNote: nil, createdAt: t0.addingTimeInterval(0.2))
    ctx.insert(card); ctx.insert(s1); ctx.insert(s2); ctx.insert(c1); ctx.insert(c2)
    try? ctx.save()

    return CitationViewer(card: card)
        .padding()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
