//
//  CardRelationshipOperations.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5
//  Contains all business logic operations for managing card relationships.
//

import Foundation
import SwiftData

/// Extension containing all relationship operations for CardRelationshipView.
/// Separated from the view layer to improve testability and maintainability.
extension CardRelationshipView {

    // MARK: - Constants

    static let citesCode: String = "cites"
    static let defaultNonSourceCode: String = "references"
    static let canonicalSceneProjectCode: String = "stories/is-storied-by"

    // MARK: - Master Card Queries

    /// Fetch all cards that have a relationship pointing to the primary card for a given kind.
    /// Uses EdgeRepository for centralized edge queries.
    func masterCards(for kind: Kinds, modelContext: ModelContext) -> [Card] {
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Fetch all incoming edges to the primary card
        let allEdges = edgeRepo.fetchIncoming(to: primary)

        // Filter by relationship type if specified
        let filteredEdges: [CardEdge]
        if let t = relationTypeFilter {
            filteredEdges = allEdges.filter { $0.type?.code == t.code }
        } else {
            filteredEdges = allEdges
        }

        // Extract source cards and filter by kind
        let cards = filteredEdges.compactMap { $0.from }.filter { $0.kind == kind }

        // Remove duplicates while preserving order
        var seen: Set<UUID> = []
        var ordered: [Card] = []
        for c in cards {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                ordered.append(c)
            }
        }
        return ordered
    }

    /// Find the first kind that has related cards.
    func firstAvailableKind(modelContext: ModelContext) -> Kinds? {
        for kind in Kinds.orderedCases {
            if !masterCards(for: kind, modelContext: modelContext).isEmpty {
                return kind
            }
        }
        return nil
    }

    // MARK: - Relationship Type Helpers (Delegate to RelationTypeManager)

    /// Fetch a RelationType by its code.
    /// MUST delegate to RelationTypeManager - no direct database access allowed.
    func fetchRelationType(code: String, modelContext: ModelContext, services: ServiceContainer? = nil) -> RelationType? {
        // Use RelationTypeManager - create one if not in services
        if let mgr = services?.relationTypeManager {
            return mgr.fetchRelationType(code: code)
        }

        // Create temporary manager if services not available
        let mgr = RelationTypeManager(modelContext: modelContext)
        return mgr.fetchRelationType(code: code)
    }

    /// Ensure a RelationType exists, creating it if necessary.
    /// MUST use RelationTypeManager - no direct database access allowed.
    /// RelationTypeManager.ensureRelationType() automatically creates mirror types.
    @discardableResult
    func ensureRelationType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil, modelContext: ModelContext, services: ServiceContainer? = nil) -> RelationType {
        // Use RelationTypeManager - create one if not in services
        let mgr = services?.relationTypeManager ?? RelationTypeManager(modelContext: modelContext)
        return mgr.ensureRelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
    }

    /// Ensure the mirror (inverse) RelationType exists.
    /// MUST use RelationTypeManager - no direct database access allowed.
    /// Note: RelationTypeManager.ensureRelationType() already handles mirror creation automatically.
    func ensureMirror(forwardLabel: String, inverseLabel: String, sourceKind: Kinds?, targetKind: Kinds?, modelContext: ModelContext, services: ServiceContainer? = nil) {
        // Use RelationTypeManager - create one if not in services
        let mgr = services?.relationTypeManager ?? RelationTypeManager(modelContext: modelContext)
        mgr.ensureMirror(forwardLabel: forwardLabel, inverseLabel: inverseLabel, sourceKind: sourceKind, targetKind: targetKind)
    }

    /// Get the mirror type for a given RelationType.
    /// MUST use RelationTypeManager - no direct database access allowed.
    /// Note: For simple reverse code calculation, use EdgeRepository's reverseRelationCode() instead.
    func mirrorType(for type: RelationType, sourceKind: Kinds, targetKind: Kinds, modelContext: ModelContext, services: ServiceContainer? = nil) -> RelationType {
        // Use RelationTypeManager - create one if not in services
        let mgr = services?.relationTypeManager ?? RelationTypeManager(modelContext: modelContext)
        return mgr.mirrorType(for: type, sourceKind: sourceKind, targetKind: targetKind)
    }

    /// Check if a RelationType applies to given source and target kinds.
    func relationTypeApplies(_ t: RelationType, from source: Kinds, to target: Kinds) -> Bool {
        let sourceOK = (t.sourceKindRaw == nil) || (t.sourceKindRaw == source.rawValue)
        let targetOK = (t.targetKindRaw == nil) || (t.targetKindRaw == target.rawValue)
        return sourceOK && targetOK
    }

    /// Get non-cites relation types applicable to source and target kinds.
    /// MUST use RelationTypeManager - no direct database access allowed.
    func nonCitesRelationTypes(applicableFrom source: Kinds, to target: Kinds, modelContext: ModelContext, services: ServiceContainer? = nil) -> [RelationType] {
        // Use RelationTypeManager - create one if not in services
        let mgr = services?.relationTypeManager ?? RelationTypeManager(modelContext: modelContext)
        let all = mgr.fetchApplicable(from: source, to: target)

        if source == .scenes && target == .projects {
            return all.filter { $0.code == Self.canonicalSceneProjectCode }
        }

        return all.filter { $0.code != Self.citesCode }
    }

    /// Get applicable retype choices for changing relationship type.
    /// MUST use RelationTypeManager - no direct database access allowed.
    func applicableRetypeChoices(fromKind: Kinds, toKind: Kinds, modelContext: ModelContext, services: ServiceContainer? = nil) -> [RelationType] {
        // Use RelationTypeManager - create one if not in services
        let mgr = services?.relationTypeManager ?? RelationTypeManager(modelContext: modelContext)

        if fromKind == .scenes && toKind == .projects {
            let t = mgr.ensureRelationType(
                code: Self.canonicalSceneProjectCode,
                forwardLabel: "stories",
                inverseLabel: "is storied by",
                sourceKind: .scenes,
                targetKind: .projects
            )
            return [t]
        }

        // Ensure default reference type exists
        _ = mgr.ensureRelationType(
            code: Self.defaultNonSourceCode,
            forwardLabel: "references",
            inverseLabel: "referenced by",
            sourceKind: nil,
            targetKind: nil
        )

        let all = mgr.fetchApplicable(from: fromKind, to: toKind)
        return all.filter { $0.code != Self.citesCode || fromKind == .sources }
    }

    // MARK: - Edge Operations

    /// Create a CardEdge if it doesn't already exist.
    /// Delegates to EdgeRepository for centralized bidirectional edge creation.
    @MainActor
    func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType, appendToEnd: Bool, modelContext: ModelContext, services: ServiceContainer? = nil) {
        guard let enforcedType = canonicalizedTypeFor(source: source, target: target, proposed: type, modelContext: modelContext, services: services) else {
            return
        }

        // Use EdgeRepository for centralized bidirectional edge creation
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Check if edge already exists
        if edgeRepo.exists(from: source, to: target, ofType: enforcedType) {
            return
        }

        // Calculate sortIndex if appendToEnd is true
        // Use EdgeRepository to fetch existing edges instead of direct query
        let sortIndex: Double?
        if appendToEnd {
            let existing = edgeRepo.fetchOutgoing(from: source, ofType: enforcedType)
            let sorted = existing.sorted { $0.sortIndex < $1.sortIndex }
            let maxSort = sorted.last?.sortIndex ?? 0.0
            sortIndex = maxSort + 1.0
        } else {
            sortIndex = nil
        }

        // Use EdgeRepository to create bidirectional relationship
        // EdgeRepository handles save() internally
        try? edgeRepo.createRelationship(
            from: source,
            to: target,
            relationType: enforcedType,
            sortIndex: sortIndex
        )
    }

    /// Ensure the reverse edge exists for a forward edge.
    /// Note: This function is now redundant since EdgeRepository.createRelationship() handles
    /// bidirectional edge creation automatically. Kept for backwards compatibility but delegates
    /// to EdgeRepository for proper implementation.
    @MainActor
    func ensureReverseEdge(forwardEdge: CardEdge, appendToEnd: Bool, modelContext: ModelContext, services: ServiceContainer? = nil) {
        guard let src = forwardEdge.from, let dst = forwardEdge.to, let t = forwardEdge.type else { return }

        // Use EdgeRepository to ensure reverse edge exists
        let edgeRepo = EdgeRepository(modelContext: modelContext)

        // Get the mirror type for the reverse relationship
        let mirror = mirrorType(for: t, sourceKind: src.kind, targetKind: dst.kind, modelContext: modelContext)

        // Check if reverse edge already exists
        if edgeRepo.exists(from: dst, to: src, ofType: mirror) {
            return
        }

        // EdgeRepository.createRelationship() will create both forward and reverse edges,
        // but since the forward edge already exists, we just need to create the reverse edge.
        // EdgeRepository doesn't have a method to create only a reverse edge (by design),
        // so this is the one acceptable exception for direct edge creation.
        // TODO: Consider adding EdgeRepository.createSingleEdge() to eliminate this exception.
        let reverseEdge = CardEdge(from: dst, to: src, type: mirror, note: forwardEdge.note)
        modelContext.insert(reverseEdge)  // Exception: EdgeRepository has no single-edge creation API
        EdgeIntegrityMonitor.incrementCounts(source: dst, target: src)

        #if DEBUG
        print("[EdgeAudit] ensureReverseEdge: Created reverse edge '\(dst.name)' → '\(src.name)' type=\(mirror.code)")
        #endif
        // Note: Caller is responsible for save() if needed
    }

    // MARK: - Canonicalization

    /// Get the canonical type for a source/target pair, handling special cases.
    /// Uses RelationTypeManager for centralized RelationType management.
    func canonicalizedTypeFor(source: Card, target: Card, proposed: RelationType?, modelContext: ModelContext, services: ServiceContainer? = nil) -> RelationType? {
        if source.kind == .scenes && target.kind == .projects {
            let sceneProjectCode = Self.canonicalSceneProjectCode

            // Use RelationTypeManager if available, otherwise use ensureRelationType()
            if let mgr = services?.relationTypeManager {
                return mgr.ensureRelationType(
                    code: sceneProjectCode,
                    forwardLabel: "stories",
                    inverseLabel: "is storied by",
                    sourceKind: .scenes,
                    targetKind: .projects
                )
            } else {
                // Fallback to local ensureRelationType method
                return ensureRelationType(
                    code: sceneProjectCode,
                    forward: "stories",
                    inverse: "is storied by",
                    sourceKind: .scenes,
                    targetKind: .projects,
                    modelContext: modelContext,
                    services: services
                )
            }
        }

        if let proposed, proposed.matches(from: source.kind, to: target.kind) {
            return proposed
        }
        return nil
    }

    // MARK: - Existing Card Candidates

    /// Get cards of a given kind that can be linked to the primary card.
    /// Uses CardRepository for centralized card queries.
    func availableExistingCandidates(for kind: Kinds, primary: Card, modelContext: ModelContext) -> [Card] {
        let cardRepo = CardRepository(modelContext: modelContext)

        // Fetch all cards of the specified kind using CardRepository
        let allOfKind = cardRepo.fetch(byKind: kind)

        // Filter out the primary card and ensure uniqueness
        let filtered = allOfKind.filter { $0.id != primary.id }
        var seen: Set<UUID> = []
        var unique: [Card] = []
        for c in filtered {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                unique.append(c)
            }
        }

        return unique.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Get the relationship decoration label for a card.
    /// Uses EdgeRepository for centralized edge queries.
    func relationDecoration(for card: Card, primary: Card, modelContext: ModelContext) -> String? {
        if let t = relationTypeFilter {
            return t.forwardLabel
        }

        // Use EdgeRepository to fetch outgoing edges from card
        let edgeRepo = EdgeRepository(modelContext: modelContext)
        let outgoing = edgeRepo.fetchOutgoing(from: card)

        // Find the edge pointing to the primary card
        if let edge = outgoing.first(where: { $0.to?.id == primary.id }) {
            return edge.type?.forwardLabel
        }

        return nil
    }

    // MARK: - Code Generation (DR-0103: delegate to RelationTypeManager)

    /// Sanitize a string for use in a code.
    func sanitize(_ s: String) -> String {
        RelationTypeManager.sanitize(s)
    }

    /// Generate a code from forward and inverse labels.
    func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        RelationTypeManager.makeCode(forward: forward, inverse: inverse, suffix: suffix)
    }
}
