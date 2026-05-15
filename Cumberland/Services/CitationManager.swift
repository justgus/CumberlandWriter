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
    /// DR-0196: Citations are simple link objects with no complex cleanup needed.
    /// SwiftData cascade rules handle the relationship cleanup automatically.
    /// A full CitationRepository could be added in the future if more complex
    /// citation lifecycle management is needed.
    func deleteCitation(_ citation: Citation) {
        #if DEBUG
        let cardName = citation.card?.name ?? "nil"
        let sourceName = citation.source?.title ?? "nil"
        print("[CitationManager] Deleting citation linking '\(cardName)' to source '\(sourceName)'")
        #endif

        // DR-0196: Direct deletion is safe here as Citation has no complex cleanup requirements
        // The citation relationships to Card and Source are automatically handled by SwiftData
        modelContext.delete(citation)
        try? modelContext.save()

        #if DEBUG
        print("[CitationManager] Citation deleted successfully")
        #endif
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

    // MARK: - Source Maintenance

    /// Result of a source consolidation operation
    struct ConsolidationResult {
        let mergedCount: Int
        let deletedCount: Int

        var message: String {
            if deletedCount == 0 {
                return "✓ No duplicate sources found"
            } else {
                return "✓ Consolidated \(deletedCount) duplicate source(s), moved \(mergedCount) citation(s)"
            }
        }
    }

    /// Consolidate duplicate sources by title
    ///
    /// Finds sources with matching titles (case-insensitive, trimmed) and consolidates them by:
    /// 1. Selecting the "best" source (has sourceCard, most citations, most metadata)
    /// 2. Moving all citations from duplicates to the primary source
    /// 3. Merging metadata from duplicates into primary if missing
    /// 4. Deleting the duplicate sources
    ///
    /// - Returns: Result containing counts of merged citations and deleted sources
    func consolidateDuplicateSources() async throws -> ConsolidationResult {
        // Fetch all sources
        let descriptor = FetchDescriptor<Source>()
        let sources = try modelContext.fetch(descriptor)

        // Group sources by normalized title (case-insensitive, trimmed)
        var titleGroups: [String: [Source]] = [:]
        for source in sources {
            let normalizedTitle = source.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            titleGroups[normalizedTitle, default: []].append(source)
        }

        var mergedCount = 0
        var deletedCount = 0

        for (_, group) in titleGroups where group.count > 1 {
            // Sort by: has sourceCard first, then by citation count (descending), then by metadata completeness
            let sorted = group.sorted { a, b in
                // Prefer one with a sourceCard link
                if (a.sourceCard != nil) != (b.sourceCard != nil) {
                    return a.sourceCard != nil
                }
                // Then prefer one with more citations
                let aCount = a.citations?.count ?? 0
                let bCount = b.citations?.count ?? 0
                if aCount != bCount {
                    return aCount > bCount
                }
                // Then prefer one with more metadata
                let aMetadata = [a.authors, a.publisher ?? "", a.doi ?? "", a.url ?? ""].filter { !$0.isEmpty }.count
                let bMetadata = [b.authors, b.publisher ?? "", b.doi ?? "", b.url ?? ""].filter { !$0.isEmpty }.count
                if aMetadata != bMetadata {
                    return aMetadata > bMetadata
                }
                return a.id.uuidString < b.id.uuidString
            }

            let primary = sorted[0]
            let duplicates = Array(sorted.dropFirst())

            for duplicate in duplicates {
                // Move all citations from duplicate to primary
                if let citations = duplicate.citations {
                    for citation in citations {
                        citation.source = primary
                        mergedCount += 1
                    }
                }

                // Merge metadata from duplicate to primary if primary is missing it
                mergeMetadata(from: duplicate, into: primary)

                // Delete the duplicate source
                modelContext.delete(duplicate)
                deletedCount += 1
            }
        }

        try modelContext.save()

        return ConsolidationResult(mergedCount: mergedCount, deletedCount: deletedCount)
    }

    /// Merge metadata from one source into another (only fills missing fields)
    private func mergeMetadata(from source: Source, into target: Source) {
        if target.authors.isEmpty && !source.authors.isEmpty {
            target.authors = source.authors
        }
        if target.publisher == nil && source.publisher != nil {
            target.publisher = source.publisher
        }
        if target.year == nil && source.year != nil {
            target.year = source.year
        }
        if target.doi == nil && source.doi != nil {
            target.doi = source.doi
        }
        if target.url == nil && source.url != nil {
            target.url = source.url
        }
        if target.containerTitle == nil && source.containerTitle != nil {
            target.containerTitle = source.containerTitle
        }
        if target.volume == nil && source.volume != nil {
            target.volume = source.volume
        }
        if target.issue == nil && source.issue != nil {
            target.issue = source.issue
        }
        if target.pages == nil && source.pages != nil {
            target.pages = source.pages
        }
        if target.license == nil && source.license != nil {
            target.license = source.license
        }
        if target.accessedDate == nil && source.accessedDate != nil {
            target.accessedDate = source.accessedDate
        }
        if target.notes == nil && source.notes != nil {
            target.notes = source.notes
        } else if let targetNotes = target.notes, let sourceNotes = source.notes, !sourceNotes.isEmpty {
            // Append notes if both have them
            target.notes = targetNotes + "\n\n[Merged from duplicate]: " + sourceNotes
        }
    }
}
