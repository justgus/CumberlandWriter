//
//  EdgeRepository.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 2
//
//  Repository encapsulating SwiftData fetch and mutation operations for
//  CardEdge records. Provides methods to fetch edges by card, create edges,
//  delete edges, and bulk-reassign relation types during RelationType deletion.
//

import Foundation
import SwiftData

/// Repository for CardEdge data access operations.
/// Encapsulates all SwiftData queries and operations for the CardEdge model (relationships).
///
/// **ER-0022 Phase 2**: Abstracts SwiftData access for relationship data
@Observable
@MainActor
final class EdgeRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Fetch Operations

    /// Fetch all edges
    /// - Returns: Array of all edges
    func fetchAll() -> [CardEdge] {
        let fetch = FetchDescriptor<CardEdge>()
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch outgoing edges from a card (where card is the source)
    /// - Parameter card: The source card
    /// - Returns: Array of outgoing edges
    func fetchOutgoing(from card: Card) -> [CardEdge] {
        let cardID: UUID? = card.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == cardID }
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch incoming edges to a card (where card is the target)
    /// - Parameter card: The target card
    /// - Returns: Array of incoming edges
    func fetchIncoming(to card: Card) -> [CardEdge] {
        let cardID: UUID? = card.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.to?.id == cardID }
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch all edges (both incoming and outgoing) for a card
    /// - Parameter card: The card
    /// - Returns: Array of all edges connected to this card
    func fetchAll(for card: Card) -> [CardEdge] {
        return fetchOutgoing(from: card) + fetchIncoming(to: card)
    }

    /// Fetch edges between two specific cards (in both directions)
    /// - Parameters:
    ///   - cardA: First card
    ///   - cardB: Second card
    /// - Returns: Array of edges between these two cards
    func fetchEdges(between cardA: Card, and cardB: Card) -> [CardEdge] {
        let aID: UUID? = cardA.id
        let bID: UUID? = cardB.id

        let abFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID }
        )
        let baFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID }
        )

        let ab = (try? modelContext.fetch(abFetch)) ?? []
        let ba = (try? modelContext.fetch(baFetch)) ?? []

        return ab + ba
    }

    /// Fetch edges of a specific relationship type
    /// - Parameter relationType: The relationship type
    /// - Returns: Array of edges with this type
    func fetch(ofType relationType: RelationType) -> [CardEdge] {
        let typeCode: String? = relationType.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.type?.code == typeCode }
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch edges from a card of a specific type
    /// - Parameters:
    ///   - card: The source card
    ///   - relationType: The relationship type
    /// - Returns: Array of matching edges
    func fetchOutgoing(from card: Card, ofType relationType: RelationType) -> [CardEdge] {
        let cardID: UUID? = card.id
        let typeCode: String? = relationType.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == cardID && $0.type?.code == typeCode }
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Check if an edge exists between two cards with a specific type
    /// - Parameters:
    ///   - source: The source card
    ///   - target: The target card
    ///   - relationType: The relationship type
    /// - Returns: True if the edge exists
    func exists(from source: Card, to target: Card, ofType relationType: RelationType) -> Bool {
        let srcID: UUID? = source.id
        let dstID: UUID? = target.id
        let typeCode: String? = relationType.code

        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == srcID && $0.to?.id == dstID && $0.type?.code == typeCode }
        )

        let edges = (try? modelContext.fetch(fetch)) ?? []
        return !edges.isEmpty
    }

    // MARK: - Insert/Update/Delete Operations

    /// Insert a new edge into the context
    /// - Parameter edge: The edge to insert
    /// - Throws: SwiftData errors
    func insert(_ edge: CardEdge) throws {
        modelContext.insert(edge)
        EdgeIntegrityMonitor.incrementCounts(source: edge.from, target: edge.to)
        try modelContext.save()
    }

    /// Delete an edge from the context
    /// - Parameter edge: The edge to delete
    /// - Throws: SwiftData errors
    func delete(_ edge: CardEdge) throws {
        #if DEBUG
        print("[EdgeAudit] EdgeRepository.delete: Deleting edge '\(edge.from?.name ?? "nil")' → '\(edge.to?.name ?? "nil")' type=\(edge.type?.code ?? "nil")")
        #endif
        EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
        modelContext.delete(edge)
        try modelContext.save()
    }

    /// Delete multiple edges
    /// - Parameter edges: Array of edges to delete
    /// - Throws: SwiftData errors
    func delete(_ edges: [CardEdge]) throws {
        #if DEBUG
        print("[EdgeAudit] EdgeRepository.delete(batch): Deleting \(edges.count) edge(s)")
        for edge in edges {
            print("[EdgeAudit]   '\(edge.from?.name ?? "nil")' → '\(edge.to?.name ?? "nil")' type=\(edge.type?.code ?? "nil")")
        }
        #endif
        for edge in edges {
            EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
            modelContext.delete(edge)
        }
        try modelContext.save()
    }

    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - Batch Operations

    /// Delete all edges for a card (both incoming and outgoing)
    /// - Parameter card: The card
    /// - Throws: SwiftData errors
    func deleteAll(for card: Card) throws {
        let edges = fetchAll(for: card)
        try delete(edges)
    }

    /// Delete all edges between two cards
    /// - Parameters:
    ///   - cardA: First card
    ///   - cardB: Second card
    /// - Throws: SwiftData errors
    func deleteAllEdges(between cardA: Card, and cardB: Card) throws {
        let edges = fetchEdges(between: cardA, and: cardB)
        try delete(edges)
    }

    // MARK: - Statistics

    /// Count total edges
    /// - Returns: Total count of edges
    func countAll() -> Int {
        return fetchAll().count
    }

    /// Count outgoing edges from a card
    /// - Parameter card: The source card
    /// - Returns: Count of outgoing edges
    func countOutgoing(from card: Card) -> Int {
        return fetchOutgoing(from: card).count
    }

    /// Count incoming edges to a card
    /// - Parameter card: The target card
    /// - Returns: Count of incoming edges
    func countIncoming(to card: Card) -> Int {
        return fetchIncoming(to: card).count
    }

    /// Count edges of a specific type
    /// - Parameter relationType: The relationship type
    /// - Returns: Count of edges with this type
    func count(ofType relationType: RelationType) -> Int {
        return fetch(ofType: relationType).count
    }

    // MARK: - Recent Edges

    /// Fetch recently created edges
    /// - Parameter limit: Maximum number of edges to return
    /// - Returns: Array of recently created edges
    func fetchRecentlyCreated(limit: Int = 20) -> [CardEdge] {
        let fetch = FetchDescriptor<CardEdge>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allEdges = (try? modelContext.fetch(fetch)) ?? []
        return Array(allEdges.prefix(limit))
    }

    // MARK: - Project Writer Helpers

    /// Create an edge linking a scene to a project with manuscript order
    /// - Parameters:
    ///   - scene: The scene card
    ///   - project: The project card
    ///   - sortIndex: The manuscript order position (optional, defaults to end)
    ///   - chapterID: Optional chapter UUID this scene belongs to in this project (currently unused - for future implementation)
    /// - Throws: SwiftData errors
    func linkSceneToProject(
        scene: Card,
        project: Card,
        sortIndex: Double? = nil,
        chapterID: UUID? = nil
    ) throws {
        // Get the "belongs-to/contains-scene" relationship type
        let typeCode = "belongs-to/contains-scene"
        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == typeCode }
        )
        guard let relationType = try modelContext.fetch(typeFetch).first else {
            throw EdgeRepositoryError.relationTypeNotFound(typeCode)
        }

        // Calculate sortIndex if not provided
        let finalSortIndex: Double
        if let providedIndex = sortIndex {
            finalSortIndex = providedIndex
        } else {
            // Get max sortIndex for scenes in this project
            let projectID: UUID? = project.id
            let sceneKind: String = Kinds.scenes.rawValue
            let relationCode: String? = typeCode

            let existingFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { edge in
                    edge.to?.id == projectID &&
                    edge.from?.kindRaw == sceneKind &&
                    edge.type?.code == relationCode
                },
                sortBy: [SortDescriptor(\.sortIndex, order: .reverse)]
            )

            let existing = (try? modelContext.fetch(existingFetch)) ?? []
            let maxIndex = existing.first?.sortIndex ?? 0.0
            finalSortIndex = maxIndex + 1.0
        }

        // Create the edge
        let edge = CardEdge(from: scene, to: project, type: relationType)
        edge.sortIndex = finalSortIndex
        // Note: chapterID field doesn't exist on CardEdge yet - scene-to-chapter
        // association is tracked via separate "part-of/has-scene" edges

        try insert(edge)
    }

    /// Create an edge linking a chapter to a project with order
    /// - Parameters:
    ///   - chapter: The chapter card
    ///   - project: The project card
    ///   - sortIndex: The chapter order position (optional, defaults to end)
    /// - Throws: SwiftData errors
    func linkChapterToProject(
        chapter: Card,
        project: Card,
        sortIndex: Double? = nil
    ) throws {
        // Get the "part-of/has-chapter" relationship type
        let typeCode = "part-of/has-chapter"
        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == typeCode }
        )
        guard let relationType = try modelContext.fetch(typeFetch).first else {
            throw EdgeRepositoryError.relationTypeNotFound(typeCode)
        }

        // Calculate sortIndex if not provided
        let finalSortIndex: Double
        if let providedIndex = sortIndex {
            finalSortIndex = providedIndex
        } else {
            // Get max sortIndex for chapters in this project
            let projectID: UUID? = project.id
            let chapterKind: String = Kinds.chapters.rawValue
            let relationCode: String? = typeCode

            let existingFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { edge in
                    edge.to?.id == projectID &&
                    edge.from?.kindRaw == chapterKind &&
                    edge.type?.code == relationCode
                },
                sortBy: [SortDescriptor(\.sortIndex, order: .reverse)]
            )

            let existing = (try? modelContext.fetch(existingFetch)) ?? []
            let maxIndex = existing.first?.sortIndex ?? 0.0
            finalSortIndex = maxIndex + 1.0
        }

        // Create the edge
        let edge = CardEdge(from: chapter, to: project, type: relationType)
        edge.sortIndex = finalSortIndex

        try insert(edge)
    }

    /// Create an edge linking a scene to a chapter
    /// - Parameters:
    ///   - scene: The scene card
    ///   - chapter: The chapter card
    /// - Throws: SwiftData errors
    func linkSceneToChapter(scene: Card, chapter: Card) throws {
        // Get the "part-of/has-scene" relationship type
        let typeCode = "part-of/has-scene"
        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == typeCode }
        )
        guard let relationType = try modelContext.fetch(typeFetch).first else {
            throw EdgeRepositoryError.relationTypeNotFound(typeCode)
        }

        // Create the edge
        let edge = CardEdge(from: scene, to: chapter, type: relationType)
        try insert(edge)
    }
}

/// Errors that can occur in EdgeRepository operations
enum EdgeRepositoryError: Error {
    case relationTypeNotFound(String)

    var localizedDescription: String {
        switch self {
        case .relationTypeNotFound(let code):
            return "Relationship type '\(code)' not found. Make sure it's seeded in CumberlandApp."
        }
    }
}
