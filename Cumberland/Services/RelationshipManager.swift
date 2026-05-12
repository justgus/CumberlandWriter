//
//  RelationshipManager.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 1
//
//  Centralised service for CardEdge relationship CRUD. Consolidates edge
//  creation (with duplicate-check), edge deletion, bulk type reassignment,
//  and relationship query helpers extracted from CardRelationshipView,
//  SuggestionEngine, and MurderBoardView.
//

import Foundation
import SwiftData

/// Centralized manager for CardEdge relationship operations in Cumberland.
/// Consolidates relationship CRUD logic from CardRelationshipView, SuggestionEngine, and MurderBoardView.
///
/// **ER-0022 Phase 1**: Provides common relationship operations to reduce code duplication
@Observable
@MainActor
final class RelationshipManager {

    private let modelContext: ModelContext
    private let edgeRepository: EdgeRepository

    /// RelationTypeManager reference for centralized mirror-type operations (DR-0103).
    /// Set after ServiceContainer initialization to avoid circular dependency.
    var relationTypeManager: RelationTypeManager?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.edgeRepository = EdgeRepository(modelContext: modelContext)
    }

    // MARK: - Relationship Creation

    /// Create a bidirectional relationship between two cards
    /// - Parameters:
    ///   - sourceCard: The source card (from)
    ///   - targetCard: The target card (to)
    ///   - type: The relationship type
    ///   - note: Optional note for the relationship
    ///   - createReverse: Whether to automatically create the reverse edge (default: true)
    /// - Throws: SwiftData errors
    /// - Returns: The created forward edge
    @discardableResult
    func createRelationship(
        from sourceCard: Card,
        to targetCard: Card,
        type: RelationType,
        note: String? = nil,
        createReverse: Bool = true
    ) throws -> CardEdge {
        // Check if forward relationship already exists
        if relationshipExists(from: sourceCard, to: targetCard, type: type) {
            throw RelationshipError.alreadyExists
        }

        // DR-0140: Use EdgeRepository for edge creation instead of direct instantiation
        if createReverse {
            // Use EdgeRepository.createRelationship() for bidirectional edges
            try edgeRepository.createRelationship(from: sourceCard, to: targetCard, relationType: type)
        } else {
            // Use EdgeRepository.insertSingleEdge() for single edge without reverse
            try edgeRepository.insertSingleEdge(from: sourceCard, to: targetCard, type: type, note: note)
        }

        // Fetch and return the created forward edge
        let edges = edgeRepository.fetchOutgoing(from: sourceCard, ofType: type)
        guard let forwardEdge = edges.first(where: { $0.to?.id == targetCard.id }) else {
            throw RelationshipError.invalidEdge
        }

        return forwardEdge
    }


    // MARK: - Relationship Deletion

    /// Remove all relationships between two cards
    /// - Parameters:
    ///   - cardA: First card
    ///   - cardB: Second card
    ///   - typeFilter: Optional type filter (only remove relationships of this type)
    /// - Throws: SwiftData errors
    func removeRelationship(
        between cardA: Card,
        and cardB: Card,
        typeFilter: RelationType? = nil
    ) throws {
        // DR-0205: Use EdgeRepository for deletion instead of direct modelContext.delete()
        if let type = typeFilter {
            // Remove only specific type - EdgeRepository handles both forward and reverse
            #if DEBUG
            print("[EdgeAudit] removeRelationship(typed): Deleting relationship between '\(cardA.name)' and '\(cardB.name)' type=\(type.code)")
            #endif

            try edgeRepository.deleteRelationship(from: cardA, to: cardB, relationType: type)
        } else {
            // Remove all relationships between the two cards
            #if DEBUG
            print("[EdgeAudit] removeRelationship(all): Deleting all relationships between '\(cardA.name)' and '\(cardB.name)'")
            #endif

            try edgeRepository.deleteAllRelationships(between: cardA, and: cardB)
        }
    }

    /// Remove a single edge
    /// - Parameter edge: The edge to remove
    /// - Throws: SwiftData errors
    func removeEdge(_ edge: CardEdge) throws {
        #if DEBUG
        print("[EdgeAudit] removeEdge: Deleting edge '\(edge.from?.name ?? "nil")' → '\(edge.to?.name ?? "nil")' type=\(edge.type?.code ?? "nil")")
        #endif
        // DR-0205: Use EdgeRepository for deletion instead of direct modelContext.delete()
        try edgeRepository.deleteEdge(edge)
    }

    // MARK: - Bulk Deletion

    /// Remove ALL edges for a card (used by changeCardType).
    /// Fetches via FetchDescriptor (not arrays), decrements counterpart counts,
    /// zeros the card's own counts, and deletes all edges.
    /// - Parameter card: The card whose edges should be removed
    /// - Returns: The number of edges deleted
    @discardableResult
    func removeAllEdges(for card: Card) throws -> Int {
        #if DEBUG
        print("[EdgeAudit] removeAllEdges: Removing all edges for '\(card.name)'")
        #endif

        // DR-0205: Use EdgeRepository for deletion instead of direct modelContext.delete()
        let edges = edgeRepository.fetchAll(for: card)
        let totalDeleted = edges.count

        try edgeRepository.deleteAllRelationships(for: card)

        // Zero the card's own counts (EdgeRepository handles counterpart counts)
        card.cachedOutgoingEdgeCount = 0
        card.cachedIncomingEdgeCount = 0

        return totalDeleted
    }

    // MARK: - Relationship Queries

    /// Get all edges where the given card is the source
    /// - Parameter card: The source card
    /// - Returns: Array of outgoing edges
    func getOutgoingEdges(for card: Card) -> [CardEdge] {
        return edgeRepository.fetchOutgoing(from: card)
    }

    /// Get all edges where the given card is the target
    /// - Parameter card: The target card
    /// - Returns: Array of incoming edges
    func getIncomingEdges(for card: Card) -> [CardEdge] {
        return edgeRepository.fetchIncoming(to: card)
    }

    /// Get all edges (both incoming and outgoing) for a card
    /// - Parameter card: The card
    /// - Returns: Array of all edges
    func getAllEdges(for card: Card) -> [CardEdge] {
        return edgeRepository.fetchAll(for: card)
    }

    /// Check if a relationship exists between two cards
    /// - Parameters:
    ///   - sourceCard: The source card
    ///   - targetCard: The target card
    ///   - type: The relationship type
    /// - Returns: True if the relationship exists
    func relationshipExists(from sourceCard: Card, to targetCard: Card, type: RelationType) -> Bool {
        return edgeRepository.exists(from: sourceCard, to: targetCard, ofType: type)
    }

    // MARK: - Mirror Type Handling

    /// Get or create the mirror relationship type
    /// DR-0103: Delegates to RelationTypeManager when available
    /// - Parameters:
    ///   - originalType: The original relationship type
    ///   - sourceKind: The source card kind
    ///   - targetKind: The target card kind
    /// - Returns: The mirror type
    private func getMirrorType(for originalType: RelationType, sourceKind: Kinds, targetKind: Kinds) -> RelationType {
        // DR-0103: Delegate to RelationTypeManager when available
        if let mgr = relationTypeManager {
            return mgr.mirrorType(for: originalType, sourceKind: sourceKind, targetKind: targetKind)
        }

        // Fallback: direct modelContext operations
        let mirrorForward = originalType.inverseLabel
        let mirrorInverse = originalType.forwardLabel

        let fetchDesc = FetchDescriptor<RelationType>(
            predicate: #Predicate { rt in
                rt.forwardLabel == mirrorForward &&
                rt.inverseLabel == mirrorInverse
            }
        )

        if let existing = try? modelContext.fetch(fetchDesc).first {
            return existing
        }

        let code = RelationTypeManager.makeCode(forward: mirrorForward, inverse: mirrorInverse)
        let mirrorType = RelationType(
            code: code,
            forwardLabel: mirrorForward,
            inverseLabel: mirrorInverse,
            sourceKind: targetKind,
            targetKind: sourceKind
        )
        modelContext.insert(mirrorType)

        return mirrorType
    }

    // MARK: - Validation

    /// Validate if a relationship can be created
    /// - Parameters:
    ///   - sourceCard: The source card
    ///   - targetCard: The target card
    ///   - type: The relationship type
    /// - Returns: True if the relationship is valid
    func validateRelationship(from sourceCard: Card, to targetCard: Card, type: RelationType) -> Bool {
        // Can't create relationship to self
        if sourceCard.id == targetCard.id {
            return false
        }

        // Check if relationship already exists
        if relationshipExists(from: sourceCard, to: targetCard, type: type) {
            return false
        }

        return true
    }
}

// MARK: - Errors

enum RelationshipError: Error, LocalizedError {
    case alreadyExists
    case invalidEdge
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .alreadyExists:
            return "A relationship already exists between these cards."
        case .invalidEdge:
            return "The edge is missing required data (source, target, or type)."
        case .validationFailed:
            return "The relationship failed validation."
        }
    }
}
