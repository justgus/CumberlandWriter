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
    ///   - relationType
    /// - Returns: Array of edges between these two cards filtered by the given RelationType.  If RelationType is passed as nil, then the function returns all edges between the two cards.
    func fetchEdges(between cardA: Card, and cardB: Card, ofType relationType: RelationType? = nil) -> [CardEdge] {
        let aID: UUID? = cardA.id
        let bID: UUID? = cardB.id
        let relationTypeCode: String? = relationType?.code

        if let typeCode = relationTypeCode {
            let abFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID && $0.type?.code == typeCode }
            )
            let baFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID && $0.type?.code == typeCode }
            )

            let ab = (try? modelContext.fetch(abFetch)) ?? []
            let ba = (try? modelContext.fetch(baFetch)) ?? []

            return ab + ba
        }
        else { //Get all edges between the two cards
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
    } //end func fetchEdges

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

    /// Fetch incoming edges to a card of a specific type
    /// - Parameters:
    ///   - card: The target card
    ///   - relationType: The relationship type
    /// - Returns: Array of matching edges
    func fetchIncoming(to card: Card, ofType relationType: RelationType) -> [CardEdge] {
        let cardID: UUID? = card.id
        let typeCode: String? = relationType.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.to?.id == cardID && $0.type?.code == typeCode }
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    func fetchReverseRelationship(for edge: CardEdge) throws -> CardEdge? {
        let sourceID: String? = edge.from?.id.uuidString
        let targetID: String? = edge.to?.id.uuidString
        let relationTypeName: String? = edge.type?.forwardLabel
        guard let to = edge.to else {
            throw EdgeRepositoryError.malformedEdge(source: sourceID ?? "nil", target: targetID ?? "nil", relationType: relationTypeName ?? "nil")
        }
        guard let from = edge.from else {
            throw EdgeRepositoryError.malformedEdge(source: sourceID ?? "nil", target: targetID ?? "nil", relationType: relationTypeName ?? "nil")
        }
        guard let relationType = edge.type else {
            throw EdgeRepositoryError.malformedEdge(source: sourceID ?? "nil", target: targetID ?? "nil", relationType: relationTypeName ?? "nil")
        }
        
        // Parse the bidirectional code to get the reverse relationship type
        // e.g., "part-of/has-scene" → reverse is "has-scene/part-of"
        let reverseCode = reverseRelationCode(relationType.code)

        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == reverseCode }
        )
        guard let reverseRelationType = try modelContext.fetch(typeFetch).first else {
            throw EdgeRepositoryError.relationTypeNotFound(reverseCode)
        }
        
        let between = fetchEdges(between: to , and: from, ofType: reverseRelationType)
        
        if between.count > 0 {
            return between.first
        } else {
            return nil
        }
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
    // MARK: - Insert Operations

    /// **CENTRALIZED EDGE CREATION** - Creates a bidirectional relationship between two cards
    /// This is the ONLY method that should be used to create edges. It automatically creates
    /// both the forward edge (from → to) and the reverse edge (to → from) based on the
    /// RelationType's bidirectional code.
    ///
    /// - Parameters:
    ///   - source: The source card
    ///   - target: The target card
    ///   - relationType: The relationship type (e.g., "part-of/has-scene")
    ///   - sortIndex: Optional sort index for the forward edge
    /// - Throws: SwiftData errors or EdgeRepositoryError if reverse RelationType not found or if relationship already exists
    func createRelationship(
        from source: Card,
        to target: Card,
        relationType: RelationType,
        sortIndex: Double? = nil
    ) throws {
        // Detect if this edge already exists between these two Cards
        
        if !exists(from: source, to: target, ofType: relationType) {
            // Create forward edge
            let forwardEdge = CardEdge(from: source, to: target, type: relationType)
            if let sortIndex = sortIndex {
                forwardEdge.sortIndex = sortIndex
            }

            modelContext.insert(forwardEdge)
            EdgeIntegrityMonitor.incrementCounts(source: source, target: target)

            #if DEBUG
            print("[EdgeAudit] createRelationship: Created forward edge '\(source.name)' → '\(target.name)' type=\(relationType.code)")
            #endif
        }
        else {
            #if DEBUG
            print("[EdgeAudit] createRelationship: Relationship already exists '\(source.name)' → '\(target.name)' type=\(relationType.code) - skipping creation")
            #endif
            //Fail quietly
        }

        // Create reverse edge
        // Parse the bidirectional code to get the reverse relationship type
        // e.g., "part-of/has-scene" → reverse is "has-scene/part-of"
        let reverseCode = reverseRelationCode(relationType.code)

        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == reverseCode }
        )
        guard let reverseRelationType = try modelContext.fetch(typeFetch).first else {
            throw EdgeRepositoryError.relationTypeNotFound(reverseCode)
        }

        //There is no guarantee that the reverse Edge is not already created, so we must
        //check for this as well.
        if !exists(from: target, to: source, ofType: reverseRelationType) {
            let reverseEdge = CardEdge(from: target, to: source, type: reverseRelationType)
            // Note: reverse edge doesn't get sortIndex - only forward edge has ordering

            modelContext.insert(reverseEdge)
            EdgeIntegrityMonitor.incrementCounts(source: target, target: source)

            #if DEBUG
            print("[EdgeAudit] createRelationship: Created reverse edge '\(target.name)' → '\(source.name)' type=\(reverseRelationType.code)")
            #endif

        }
        else {
            #if DEBUG
            print("[EdgeAudit] createRelationship: Relationship already exists '\(target.name)' → '\(source.name)' type=\(reverseRelationType.code) - skipping creation")
            #endif
            //Fail quietly
        }
        
        try modelContext.save()
    }

    /// **SINGLE EDGE CREATION** - Creates a single edge without automatically creating the reverse
    /// WARNING: This should only be used in special cases (e.g., legacy data repair tools).
    /// For normal operation, use createRelationship() which creates bidirectional edges.
    ///
    /// - Parameters:
    ///   - source: The source card
    ///   - target: The target card
    ///   - relationType: The relationship type
    ///   - note: Optional note for the edge
    ///   - createdAt: Optional creation timestamp (defaults to now)
    ///   - sortIndex: Optional sort index
    /// - Throws: SwiftData errors
    /// - Returns: The created CardEdge
    @discardableResult
    func insertSingleEdge(
        from source: Card,
        to target: Card,
        type relationType: RelationType,
        note: String? = nil,
        createdAt: Date = Date(),
        sortIndex: Double? = nil
    ) throws -> CardEdge {
        // Check if edge already exists
        if exists(from: source, to: target, ofType: relationType) {
            #if DEBUG
            print("[EdgeAudit] insertSingleEdge: Edge already exists '\(source.name)' → '\(target.name)' type=\(relationType.code) - skipping")
            #endif
            // Fetch and return the existing edge
            return fetchOutgoing(from: source, ofType: relationType).first(where: { $0.to?.id == target.id })!
        }

        let edge = CardEdge(from: source, to: target, type: relationType, note: note, createdAt: createdAt, sortIndex: sortIndex)
        modelContext.insert(edge)
        EdgeIntegrityMonitor.incrementCounts(source: source, target: target)

        #if DEBUG
        print("[EdgeAudit] insertSingleEdge: Created edge '\(source.name)' → '\(target.name)' type=\(relationType.code)")
        #endif

        try modelContext.save()
        return edge
    }

    // MARK: - Delete Operations

    /// **CENTRALIZED EDGE DELETION** - Deletes a bidirectional relationship
    /// Automatically finds and deletes both the forward and reverse edges
    ///
    /// - Parameters:
    ///   - source: The source card
    ///   - target: The target card
    ///   - relationType: The relationship type
    /// - Throws: SwiftData errors
    func deleteRelationship(
        from source: Card,
        to target: Card,
        relationType: RelationType
    ) throws {
        // Find and delete forward edge
        let forwardEdges = fetchOutgoing(from: source, ofType: relationType)
            .filter { $0.to?.id == target.id }

        for edge in forwardEdges {
            #if DEBUG
            print("[EdgeAudit] deleteRelationship: Deleting forward edge '\(source.name)' → '\(target.name)' type=\(relationType.code)")
            #endif
            EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
            modelContext.delete(edge)
        }

        // Find and delete reverse edge
        let reverseCode = reverseRelationCode(relationType.code)
        let typeFetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == reverseCode }
        )
        if let reverseRelationType = try modelContext.fetch(typeFetch).first {
            let reverseEdges = fetchOutgoing(from: target, ofType: reverseRelationType)
                .filter { $0.to?.id == source.id }

            for edge in reverseEdges {
                #if DEBUG
                print("[EdgeAudit] deleteRelationship: Deleting reverse edge '\(target.name)' → '\(source.name)' type=\(reverseCode)")
                #endif
                EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
                modelContext.delete(edge)
            }
        }

        try modelContext.save()
    }
    
    /// Delete an edge from the context
    /// - Parameter edge: The edge to delete
    /// - Throws: SwiftData errors
    func deleteEdge(_ edge: CardEdge) throws {
        #if DEBUG
        print("[EdgeAudit] EdgeRepository.delete: Deleting edge '\(edge.from?.name ?? "nil")' → '\(edge.to?.name ?? "nil")' type=\(edge.type?.code ?? "nil")")
        #endif
        EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
        modelContext.delete(edge)
        if let reverseEdge = try fetchReverseRelationship(for: edge) {
            EdgeIntegrityMonitor.decrementCounts(source: reverseEdge.from, target: reverseEdge.to)
            modelContext.delete(reverseEdge)
        }
    }



    // MARK: - Update Operations
    
    /// Update the RelationType of an existing relationship (changes both forward and reverse edges)
    /// - Parameters:
    ///   - source: The source card
    ///   - target: The target card
    ///   - oldRelationType: The current relationship type
    ///   - newRelationType: The new relationship type
    /// - Throws: SwiftData errors
    func updateRelationType(
        from source: Card,
        to target: Card,
        from oldRelationType: RelationType,
        to newRelationType: RelationType
    ) throws {
        // Delete old relationship
        try deleteRelationship(from: source, to: target, relationType: oldRelationType)
        // Create new relationship
        try createRelationship(from: source, to: target, relationType: newRelationType)
    }

    /// Helper to reverse a bidirectional relation code
    /// e.g., "part-of/has-scene" → "has-scene/part-of"
    private func reverseRelationCode(_ code: String) -> String {
        let parts = code.split(separator: "/").map(String.init)
        guard parts.count == 2 else {
            // Symmetric relationship (e.g., "related-to/related-to")
            return code
        }
        return "\(parts[1])/\(parts[0])"
    }

    /// Move a relationship from one target to another (e.g., moving scene from Chapter 1 to Chapter 2)
    /// - Parameters:
    ///   - source: The source card (stays the same)
    ///   - oldTarget: The current target card
    ///   - newTarget: The new target card
    ///   - relationType: The relationship type
    /// - Throws: SwiftData errors
    func moveRelationship(
        from source: Card,
        oldTarget: Card,
        newTarget: Card,
        relationType: RelationType
    ) throws {
        // Delete old relationship
        try deleteRelationship(from: source, to: oldTarget, relationType: relationType)
        // Create new relationship
        try createRelationship(from: source, to: newTarget, relationType: relationType)
    }

    /// Reorder an edge by updating its sortIndex and adjusting all other edges in the same list
    /// This method finds all edges from the same source card with the same relationship type,
    /// then reorders them to maintain a consistent sortIndex sequence when one edge moves position.
    ///
    /// - Parameters:
    ///   - edge: The edge to reorder
    ///   - newSortIndex: The new sort index (target position)
    /// - Throws: SwiftData errors
    func updateSortIndex(_ edge: CardEdge, to newSortIndex: Double) throws {
        guard let source = edge.from,
              let relationType = edge.type else {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: Edge has nil source or type, skipping reorder")
            #endif
            return
        }

        // Get all edges from the same source with the same relationship type (the "list")
        let allEdges = fetchOutgoing(from: source, ofType: relationType)
            .sorted { $0.sortIndex < $1.sortIndex }

        guard let currentIndex = allEdges.firstIndex(where: { $0 === edge }) else {
            // This is a data integrity error - the edge should be in the list we just fetched
            let edgeDescription = "\(edge.from?.name ?? "nil") → \(edge.to?.name ?? "nil")"
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: CRITICAL - Edge '\(edgeDescription)' not found in list of \(allEdges.count) edges from '\(source.name)' with type '\(relationType.code)'")
            #endif
            throw EdgeRepositoryError.edgeNotFoundInList(
                edge: edgeDescription,
                source: source.name,
                relationType: relationType.code
            )
        }

        let oldSortIndex = edge.sortIndex
        var targetIndex = Int(newSortIndex)

        // If no change, skip
        if currentIndex == targetIndex {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: No position change, skipping reorder")
            #endif
            return
        }

        #if DEBUG
        print("[EdgeAudit] updateSortIndex: Reordering edge from index \(currentIndex) (sortIndex: \(oldSortIndex)) to index \(targetIndex)")
        #endif

        // Validate target index is within bounds
        if targetIndex < 0 || targetIndex >= allEdges.count {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: Target index \(targetIndex) out of bounds [0..\(allEdges.count-1)], skipping reorder")
            #endif
            
            //Don't return.  Just push the relation onto the end of the list
            targetIndex = allEdges.count
        }

        // Moving up in the list (to a lower index)
        if targetIndex < currentIndex {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: Moving UP - shifting edges between \(targetIndex) and \(currentIndex-1) down by 1")
            #endif
            // Shift edges between target and current position down by 1
            for i in targetIndex..<currentIndex {
                allEdges[i].sortIndex += 1.0
            }
            edge.sortIndex = Double(targetIndex)
        }
        else if targetIndex == allEdges.count {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: Moving DOWN - shifting edges between \(currentIndex+1) and \(targetIndex) up by 1")
            #endif
            // Shift edges between current and target position up by 1
            for i in (currentIndex+1)...targetIndex-1 {
                allEdges[i].sortIndex -= 1.0
            }
            edge.sortIndex = Double(targetIndex)
        }
        // Moving down in the list (to a higher index)
        else {
            #if DEBUG
            print("[EdgeAudit] updateSortIndex: Moving DOWN - shifting edges between \(currentIndex+1) and \(targetIndex) up by 1")
            #endif
            // Shift edges between current and target position up by 1
            for i in (currentIndex+1)...targetIndex {
                allEdges[i].sortIndex -= 1.0
            }
            edge.sortIndex = Double(targetIndex)
        }

        #if DEBUG
        print("[EdgeAudit] updateSortIndex: Reorder complete, saving context")
        #endif

        try modelContext.save()
    }

    /// Reorder multiple edges (bulk update sortIndex values)
    /// Each edge will be reordered individually, adjusting surrounding edges as needed.
    /// Note: For best results when reordering multiple edges in the same list, consider
    /// doing them in order from the edges moving the furthest to those moving the least.
    ///
    /// - Parameter edgesWithIndices: Dictionary mapping edges to their new sort indices
    /// - Throws: SwiftData errors
    func updateSortIndices(_ edgesWithIndices: [CardEdge: Double]) throws {
        for (edge, newIndex) in edgesWithIndices {
            try updateSortIndex(edge, to: newIndex)
        }
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
    func deleteAllRelationships(for card: Card) throws {
        let edges = fetchAll(for: card)
        for edge in edges {
              guard let from = edge.from,
                    let to = edge.to,
                    let type = edge.type else {
                  #if DEBUG
                  print("[EdgeAudit] deleteAllRelationships: Skipping edge with nil properties")
                  #endif
                  continue
              }
              try deleteRelationship(from: from, to: to, relationType: type)
          }
    }
    

    /// Delete all edges between two cards
    /// - Parameters:
    ///   - cardA: First card
    ///   - cardB: Second card
    /// - Throws: SwiftData errors
    func deleteAllRelationships(between cardA: Card, and cardB: Card) throws {
        let edges = fetchEdges(between: cardA, and: cardB)
        for edge in edges {
            guard let from = edge.from,
                  let to = edge.to,
                  let type = edge.type else {
                continue
            }
            try deleteRelationship(from: from, to: to, relationType: type)
        }

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

        // Use centralized createRelationship to ensure bidirectional edge
        try createRelationship(from: scene, to: project, relationType: relationType, sortIndex: finalSortIndex)
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

        // Use centralized createRelationship to ensure bidirectional edge
        try createRelationship(from: chapter, to: project, relationType: relationType, sortIndex: finalSortIndex)
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

        // Use centralized createRelationship to ensure bidirectional edge
        try createRelationship(from: scene, to: chapter, relationType: relationType)
    }
}

/// Errors that can occur in EdgeRepository operations
enum EdgeRepositoryError: Error {
    case relationTypeNotFound(String)
    case relationshipAlreadyExists(source: String, target: String, type: String)
    case edgeNotFoundInList(edge: String, source: String, relationType: String)
    case malformedEdge(source: String, target: String, relationType: String)

    var localizedDescription: String {
        switch self {
        case .relationTypeNotFound(let code):
            return "Relationship type '\(code)' not found. Make sure it's seeded in CumberlandApp."
        case .relationshipAlreadyExists(let source, let target, let type):
            return "Relationship already exists: '\(source)' → '\(target)' (type: \(type))"
        case .edgeNotFoundInList(let edge, let source, let relationType):
            return "Data integrity error: Edge '\(edge)' not found in list of edges from source '\(source)' with type '\(relationType)'. This indicates database corruption."
        case .malformedEdge(let source, let target, let relationType):
            return "Malformed Edge: Edge either has no source, target, or relationType. Source: '\(source)', Target: '\(target)', relationType: '\(relationType)'"
        }
    }
}
