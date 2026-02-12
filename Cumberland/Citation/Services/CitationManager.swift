//
//  CitationManager.swift
//  Cumberland
//
//  Centralized service for Citation and Source CRUD operations.
//  Extracts duplicated business logic from CitationEditor,
//  CitationViewer, ImageAttributionEditor, ImageAttributionViewer,
//  and QuickAttributionSheetEditor into a single service layer.
//
//  Part of ER-0029: Consolidate Citation System with Service Layer
//

import Foundation
import SwiftData

@MainActor
final class CitationManager {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Citation CRUD

    /// Create a new citation linking a card to a source.
    @discardableResult
    func createCitation(
        card: Card,
        source: Source,
        kind: CitationKind,
        locator: String = "",
        excerpt: String = "",
        contextNote: String? = nil
    ) -> Citation {
        let citation = Citation(
            card: card,
            source: source,
            kind: kind,
            locator: locator,
            excerpt: excerpt,
            contextNote: contextNote,
            createdAt: Date()
        )
        modelContext.insert(citation)
        try? modelContext.save()
        return citation
    }

    /// Update an existing citation's fields.
    func updateCitation(
        _ citation: Citation,
        source: Source,
        kind: CitationKind,
        locator: String,
        excerpt: String,
        contextNote: String?
    ) {
        citation.source = source
        citation.kind = kind
        citation.locator = locator
        citation.excerpt = excerpt
        citation.contextNote = contextNote
        try? modelContext.save()
    }

    /// Delete a citation from the context.
    func deleteCitation(_ citation: Citation) {
        modelContext.delete(citation)
        try? modelContext.save()
    }

    // MARK: - Citation Queries

    /// Fetch all citations for a card, sorted by creation date.
    func fetchCitations(for card: Card) -> [Citation] {
        let cardID = card.id
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate { $0.card?.id == cardID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch only image-kind citations for a card, sorted by creation date.
    func fetchImageCitations(for card: Card) -> [Citation] {
        let cardIDOpt: UUID? = card.id
        let imageKindRaw = CitationKind.image.rawValue
        let fetch = FetchDescriptor<Citation>(
            predicate: #Predicate {
                $0.card?.id == cardIDOpt && $0.kindRaw == imageKindRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Source CRUD

    /// Create a new source, checking for duplicates by title first.
    /// If a source with the same title already exists, returns it instead.
    @discardableResult
    func createSource(title: String, authors: String) -> Source {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            // Fallback: create with empty title (shouldn't happen in practice)
            let s = Source(title: "", authors: authors)
            modelContext.insert(s)
            try? modelContext.save()
            return s
        }

        // Check for existing source with same title
        if let existing = findSource(byTitle: trimmedTitle) {
            return existing
        }

        let s = Source(title: trimmedTitle, authors: authors)
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    /// Fetch an existing source by title, or create a new one.
    /// If an existing source is found, updates empty fields with provided values.
    @discardableResult
    func fetchOrCreateSource(
        title: String,
        authors: String = "",
        urlString: String = ""
    ) -> Source {
        let titleToMatch = title
        if let existing = findSource(byTitle: titleToMatch) {
            // Update empty fields with new values
            if existing.authors.isEmpty && !authors.isEmpty {
                existing.authors = authors
            }
            if existing.url == nil && !urlString.isEmpty {
                existing.url = urlString
                existing.accessedDate = Date()
            }
            return existing
        }

        let newSource = Source(
            title: title,
            authors: authors,
            url: urlString.isEmpty ? nil : urlString,
            accessedDate: urlString.isEmpty ? nil : Date()
        )
        modelContext.insert(newSource)
        return newSource
    }

    // MARK: - Source Queries

    /// Find a source by exact title match.
    func findSource(byTitle title: String) -> Source? {
        let titleToMatch = title
        var fetchDescriptor = FetchDescriptor<Source>(
            predicate: #Predicate { $0.title == titleToMatch }
        )
        fetchDescriptor.fetchLimit = 1
        return try? modelContext.fetch(fetchDescriptor).first
    }
}
