//
//  RelationshipManager.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 1
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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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

        // Create the forward CardEdge
        let forwardEdge = CardEdge(from: sourceCard, to: targetCard, type: type)
        if let note = note {
            forwardEdge.note = note
        }
        modelContext.insert(forwardEdge)

        // Create reverse edge if requested
        if createReverse {
            try createReverseEdge(for: forwardEdge)
        }

        try modelContext.save()
        return forwardEdge
    }

    /// Create the reverse edge for a forward relationship
    /// - Parameter forwardEdge: The forward edge to create a reverse for
    /// - Throws: SwiftData errors
    private func createReverseEdge(for forwardEdge: CardEdge) throws {
        guard let sourceCard = forwardEdge.from,
              let targetCard = forwardEdge.to,
              let forwardType = forwardEdge.type else {
            throw RelationshipError.invalidEdge
        }

        // Check if reverse already exists
        if relationshipExists(from: targetCard, to: sourceCard, type: forwardType) {
            return // Already exists, skip
        }

        // Get or create the mirror type
        let mirrorType = getMirrorType(for: forwardType, sourceKind: sourceCard.kind, targetKind: targetCard.kind)

        // Create reverse edge with slightly later timestamp for ordering
        let reverseCreatedAt = forwardEdge.createdAt.addingTimeInterval(0.001)
        let reverseEdge = CardEdge(
            from: targetCard,
            to: sourceCard,
            type: mirrorType,
            note: forwardEdge.note,
            createdAt: reverseCreatedAt
        )
        modelContext.insert(reverseEdge)
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
        let aID: UUID? = cardA.id
        let bID: UUID? = cardB.id

        if let type = typeFilter {
            // Remove only specific type
            let forwardCode: String? = type.code
            let fwdFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID && $0.type?.code == forwardCode })
            let fwd = (try? modelContext.fetch(fwdFetch)) ?? []

            let mirror = getMirrorType(for: type, sourceKind: cardA.kind, targetKind: cardB.kind)
            let mirrorCode: String? = mirror.code
            let revFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID && $0.type?.code == mirrorCode })
            let rev = (try? modelContext.fetch(revFetch)) ?? []

            for e in fwd { modelContext.delete(e) }
            for e in rev { modelContext.delete(e) }
        } else {
            // Remove all relationships between the two cards
            let abFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID })
            let baFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID })
            let ab = (try? modelContext.fetch(abFetch)) ?? []
            let ba = (try? modelContext.fetch(baFetch)) ?? []
            for e in ab { modelContext.delete(e) }
            for e in ba { modelContext.delete(e) }
        }

        try modelContext.save()
    }

    /// Remove a single edge
    /// - Parameter edge: The edge to remove
    /// - Throws: SwiftData errors
    func removeEdge(_ edge: CardEdge) throws {
        modelContext.delete(edge)
        try modelContext.save()
    }

    // MARK: - Relationship Queries

    /// Get all edges where the given card is the source
    /// - Parameter card: The source card
    /// - Returns: Array of outgoing edges
    func getOutgoingEdges(for card: Card) -> [CardEdge] {
        let cardID: UUID? = card.id
        let fetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get all edges where the given card is the target
    /// - Parameter card: The target card
    /// - Returns: Array of incoming edges
    func getIncomingEdges(for card: Card) -> [CardEdge] {
        let cardID: UUID? = card.id
        let fetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get all edges (both incoming and outgoing) for a card
    /// - Parameter card: The card
    /// - Returns: Array of all edges
    func getAllEdges(for card: Card) -> [CardEdge] {
        return getOutgoingEdges(for: card) + getIncomingEdges(for: card)
    }

    /// Check if a relationship exists between two cards
    /// - Parameters:
    ///   - sourceCard: The source card
    ///   - targetCard: The target card
    ///   - type: The relationship type
    /// - Returns: True if the relationship exists
    func relationshipExists(from sourceCard: Card, to targetCard: Card, type: RelationType) -> Bool {
        let srcID: UUID? = sourceCard.id
        let dstID: UUID? = targetCard.id
        let typeCode: String? = type.code

        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == srcID && $0.to?.id == dstID && $0.type?.code == typeCode }
        )
        let edges = (try? modelContext.fetch(fetch)) ?? []
        return !edges.isEmpty
    }

    // MARK: - Mirror Type Handling

    /// Get or create the mirror relationship type
    /// - Parameters:
    ///   - originalType: The original relationship type
    ///   - sourceKind: The source card kind
    ///   - targetKind: The target card kind
    /// - Returns: The mirror type
    private func getMirrorType(for originalType: RelationType, sourceKind: Kinds, targetKind: Kinds) -> RelationType {
        // Try to find existing mirror type
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

        // Create new mirror type
        // Generate code by combining forward and inverse labels (same as existing pattern)
        let code = "\(mirrorForward)/\(mirrorInverse)"
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
