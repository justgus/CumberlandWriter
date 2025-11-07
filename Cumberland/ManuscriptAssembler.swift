// ManuscriptAssembler.swift
import Foundation
import SwiftData
import Combine

struct ManuscriptAssembler {
    // Build footnotes and bibliography (Chicago-like) for a project
    static func assemble(for project: Card, in context: ModelContext) -> (footnotes: [String], bibliography: [String]) {
        // Use inverse relationship instead of a fetch predicate
        let edges: [CardEdge] = project.incomingEdges ?? []

        // Collect non-nil "from" cards and deduplicate by their stable UUID
        let fromCards: [Card] = edges.compactMap { $0.from }
        var seenCardIDs = Set<UUID>()
        let contentCards: [Card] = fromCards.filter { seenCardIDs.insert($0.id).inserted }

        // Collect citations in first-occurrence order
        var footnotes: [String] = []
        var sourceIndex: [UUID: Int] = [:] // first occurrence index for source id
        var bibliographySet: Set<UUID> = []
        var bibliography: [String] = []

        for card in contentCards {
            // Use inverse relationship instead of a fetch predicate; sort in-memory
            let cites: [Citation] = (card.citations ?? []).sorted { $0.createdAt < $1.createdAt }

            for cite in cites {
                // Ensure we have a source
                guard let source = cite.source else { continue }

                // Assign a footnote number by first occurrence of the source
                if sourceIndex[source.id] == nil {
                    sourceIndex[source.id] = footnotes.count + 1
                }
                let note = chicagoFootnote(for: cite, source: source)
                footnotes.append(note)

                if !bibliographySet.contains(source.id) {
                    bibliographySet.insert(source.id)
                    bibliography.append(source.chicagoBibliography)
                }
            }
        }

        return (footnotes, bibliography)
    }

    private static func chicagoFootnote(for c: Citation, source: Source) -> String {
        // Simple Chicago-like footnote
        var parts: [String] = []
        parts.append(source.chicagoShort)
        if !c.locator.isEmpty { parts.append(c.locator) }
        if !c.excerpt.isEmpty { parts.append("“\(c.excerpt)”") }
        if let note = c.contextNote, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }
}
