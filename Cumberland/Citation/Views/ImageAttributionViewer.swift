//
//  ImageAttributionViewer.swift
//  Cumberland
//
//  List view for image attribution (CitationKind.image) records attached to
//  a card. Shows artist, license, and source URL; provides add/edit/delete
//  actions via ImageAttributionEditor sheet.
//

import SwiftUI
import SwiftData

struct ImageAttributionViewer: View {
    let card: Card

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var imageCitations: [Citation] = []
    @State private var isShowingAddAttribution: Bool = false
    @State private var editingAttribution: Citation?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Image attribution")
                    .font(.footnote).bold()
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isShowingAddAttribution = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .help("Add image attribution")
            }

            if imageCitations.isEmpty {
                Button {
                    isShowingAddAttribution = true
                } label: {
                    Text("Add attribution…")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(imageCitations) { c in
                        ImageAttributionRow(
                            citation: c,
                            summary: attributionSummary(for: c),
                            onEdit: { editingAttribution = $0 },
                            onDelete: { deleteAttribution($0) }
                        )
                        Divider().opacity(0.2)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
        .onAppear {
            reloadImageCitations()
        }
        .onChange(of: isShowingAddAttribution) { _, presented in
            if !presented { reloadImageCitations() }
        }
        .onChange(of: editingAttribution) { _, newVal in
            if newVal == nil { reloadImageCitations() }
        }
        .sheet(isPresented: $isShowingAddAttribution) {
            ImageAttributionEditor(card: card, citation: nil) { _ in
                reloadImageCitations()
            }
            .frame(minWidth: 420, minHeight: 360)
            .environmentObject(themeManager)
        }
        .sheet(item: $editingAttribution) { c in
            ImageAttributionEditor(card: card, citation: c) { _ in
                reloadImageCitations()
            }
            .frame(minWidth: 420, minHeight: 360)
            .environmentObject(themeManager)
        }
    }
    
    // MARK: - Data Management
    private func reloadImageCitations() {
        let manager = CitationManager(modelContext: modelContext)
        imageCitations = manager.fetchImageCitations(for: card)
    }

    @MainActor
    private func deleteAttribution(_ c: Citation) {
        let manager = CitationManager(modelContext: modelContext)
        manager.deleteCitation(c)
        reloadImageCitations()
    }

    private func attributionSummary(for c: Citation) -> String? {
        var details: [String] = []
        if !c.locator.isEmpty { details.append(c.locator) }
        if !c.excerpt.isEmpty { details.append("“\(c.excerpt)”") }
        if let note = c.contextNote, !note.isEmpty { details.append(note) }
        return details.isEmpty ? nil : details.joined(separator: " — ")
    }
}

private struct ImageAttributionRow: View {
    let citation: Citation
    let summary: String?
    let onEdit: (Citation) -> Void
    let onDelete: (Citation) -> Void

    // Prefer chicagoShort if available, then title, else a placeholder.
    private var sourceDisplayTitle: String {
        let short = citation.source?.chicagoShort ?? ""
        if !short.isEmpty { return short }
        let title = citation.source?.title ?? ""
        return title.isEmpty ? "Untitled Source" : title
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sourceDisplayTitle)
                    .font(.caption)
                    .lineLimit(2)
                if let summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 4)
            Menu {
                Button {
                    onEdit(citation)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    onDelete(citation)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .controlSize(.mini)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit(citation)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete(citation)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview("ImageAttributionViewer – Light") {
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
    let s1 = Source(title: "Photo Archive", authors: "Archivist")
    let s2 = Source(title: "Stock Photo", authors: "Photog Inc.")
    let t0 = Date()
    let c1 = Citation(card: card, source: s1, kind: .image, locator: "fig. 2", excerpt: "Portrait", contextNote: "Cover image", createdAt: t0.addingTimeInterval(0.1))
    let c2 = Citation(card: card, source: s2, kind: .image, locator: "ID 12345", excerpt: "Landscape", contextNote: nil, createdAt: t0.addingTimeInterval(0.2))
    ctx.insert(card); ctx.insert(s1); ctx.insert(s2); ctx.insert(c1); ctx.insert(c2)
    try? ctx.save()

    return ImageAttributionViewer(card: card)
        .padding()
        .modelContainer(container)
        .preferredColorScheme(.light)
}

#Preview("ImageAttributionViewer – Dark") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, Source.self, Citation.self, configurations: config)
    let ctx = ModelContext(container)
    ctx.autosaveEnabled = false

    // Seed sample data
    let card = Card(
        kind: .projects,
        name: "Exploration Project",
        subtitle: "Initial Planning",
        detailedText: "Details…",
        author: nil,
        sizeCategory: .standard
    )
    let s1 = Source(title: "Museum Collection", authors: "Curator")
    let c1 = Citation(card: card, source: s1, kind: .image, locator: "cat. 77", excerpt: "", contextNote: "Banner image", createdAt: Date())
    ctx.insert(card); ctx.insert(s1); ctx.insert(c1)
    try? ctx.save()

    return ImageAttributionViewer(card: card)
        .padding()
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
