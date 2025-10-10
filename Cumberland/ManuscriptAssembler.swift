// ManuscriptAssembler.swift
import Foundation
import SwiftData

struct ManuscriptAssembler {
    // Build footnotes and bibliography (Chicago-like) for a project
    static func assemble(for project: Card, in context: ModelContext) -> (footnotes: [String], bibliography: [String]) {
        // Gather content cards that refer to the project
        let projectID = project.id
        let edgeFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to.id == projectID })
        let edges = (try? context.fetch(edgeFetch)) ?? []
        let contentCards = Dictionary(grouping: edges.map { $0.from }, by: { $0.id }).compactMap { $0.value.first }

        // Collect citations in first-occurrence order
        var footnotes: [String] = []
        var sourceIndex: [UUID: Int] = [:] // first occurrence index for source id
        var bibliographySet: Set<UUID> = []
        var bibliography: [String] = []

        for card in contentCards {
            let cardID = card.id
            let citeFetch = FetchDescriptor<Citation>(
                predicate: #Predicate { $0.card.id == cardID },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let cites = (try? context.fetch(citeFetch)) ?? []
            for cite in cites {
                // Assign a footnote number by first occurrence of the source
                if sourceIndex[cite.source.id] == nil {
                    sourceIndex[cite.source.id] = footnotes.count + 1
                }
                let note = chicagoFootnote(for: cite)
                footnotes.append(note)

                if !bibliographySet.contains(cite.source.id) {
                    bibliographySet.insert(cite.source.id)
                    bibliography.append(cite.source.chicagoBibliography)
                }
            }
        }

        return (footnotes, bibliography)
    }

    private static func chicagoFootnote(for c: Citation) -> String {
        // Simple Chicago-like footnote
        var parts: [String] = []
        parts.append(c.source.chicagoShort)
        if !c.locator.isEmpty { parts.append(c.locator) }
        if !c.excerpt.isEmpty { parts.append("“\(c.excerpt)”") }
        if let note = c.contextNote, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }
}

