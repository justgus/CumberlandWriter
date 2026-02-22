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
    func masterCards(for kind: Kinds, modelContext: ModelContext) -> [Card] {
        let predicate: Predicate<CardEdge>
        let primaryIDOpt: UUID? = primary.id
        if let t = relationTypeFilter {
            let typeCodeOpt: String? = t.code
            predicate = #Predicate {
                $0.to?.id == primaryIDOpt && $0.type?.code == typeCodeOpt
            }
        } else {
            predicate = #Predicate {
                $0.to?.id == primaryIDOpt
            }
        }
        let fetch = FetchDescriptor<CardEdge>(predicate: predicate, sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        let edges = (try? modelContext.fetch(fetch)) ?? []
        let cards = edges.compactMap { $0.from }.filter { $0.kind == kind }
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

    // MARK: - Relationship Type Helpers

    /// Fetch a RelationType by its code.
    func fetchRelationType(code: String, modelContext: ModelContext) -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
        return try? modelContext.fetch(fetch).first
    }

    /// Ensure a RelationType exists, creating it if necessary.
    @discardableResult
    func ensureRelationType(code: String, forward: String, inverse: String, sourceKind: Kinds? = nil, targetKind: Kinds? = nil, modelContext: ModelContext) -> RelationType {
        if let existing = fetchRelationType(code: code, modelContext: modelContext) {
            ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind, modelContext: modelContext)
            return existing
        }
        let type = RelationType(code: code, forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind)
        modelContext.insert(type)
        ensureMirror(forwardLabel: forward, inverseLabel: inverse, sourceKind: sourceKind, targetKind: targetKind, modelContext: modelContext)
        try? modelContext.save()
        return type
    }

    /// Ensure the mirror (inverse) RelationType exists.
    func ensureMirror(forwardLabel: String, inverseLabel: String, sourceKind: Kinds?, targetKind: Kinds?, modelContext: ModelContext) {
        let mirrorForward = inverseLabel
        let mirrorInverse = forwardLabel
        let mirrorSource = targetKind
        let mirrorTarget = sourceKind

        let desiredCode = makeCode(forward: mirrorForward, inverse: mirrorInverse)
        if fetchRelationType(code: desiredCode, modelContext: modelContext) != nil {
            return
        }

        var codeToUse = desiredCode
        var suffix = 1
        while fetchRelationType(code: codeToUse, modelContext: modelContext) != nil {
            suffix += 1
            codeToUse = makeCode(forward: mirrorForward, inverse: mirrorInverse, suffix: suffix)
        }

        let mirror = RelationType(code: codeToUse, forwardLabel: mirrorForward, inverseLabel: mirrorInverse, sourceKind: mirrorSource, targetKind: mirrorTarget)
        modelContext.insert(mirror)
    }

    /// Get the mirror type for a given RelationType.
    func mirrorType(for type: RelationType, sourceKind: Kinds, targetKind: Kinds, modelContext: ModelContext) -> RelationType {
        let desiredCode = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel)
        if let existing = fetchRelationType(code: desiredCode, modelContext: modelContext) {
            return existing
        }

        ensureMirror(forwardLabel: type.forwardLabel, inverseLabel: type.inverseLabel, sourceKind: sourceKind, targetKind: targetKind, modelContext: modelContext)
        if let exact = fetchRelationType(code: desiredCode, modelContext: modelContext) {
            return exact
        }
        let all = (try? modelContext.fetch(FetchDescriptor<RelationType>())) ?? []
        if let match = all.first(where: {
            ($0.sourceKindRaw == targetKind.rawValue || $0.sourceKindRaw == nil) &&
            ($0.targetKindRaw == sourceKind.rawValue || $0.targetKindRaw == nil) &&
            $0.forwardLabel == type.inverseLabel &&
            $0.inverseLabel == type.forwardLabel
        }) {
            return match
        }
        var codeToUse = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel)
        var suffix = 1
        while fetchRelationType(code: codeToUse, modelContext: modelContext) != nil {
            suffix += 1
            codeToUse = makeCode(forward: type.inverseLabel, inverse: type.forwardLabel, suffix: suffix)
        }
        let mirror = RelationType(code: codeToUse, forwardLabel: type.inverseLabel, inverseLabel: type.forwardLabel, sourceKind: targetKind, targetKind: sourceKind)
        modelContext.insert(mirror)
        try? modelContext.save()
        return mirror
    }

    /// Check if a RelationType applies to given source and target kinds.
    func relationTypeApplies(_ t: RelationType, from source: Kinds, to target: Kinds) -> Bool {
        let sourceOK = (t.sourceKindRaw == nil) || (t.sourceKindRaw == source.rawValue)
        let targetOK = (t.targetKindRaw == nil) || (t.targetKindRaw == target.rawValue)
        return sourceOK && targetOK
    }

    /// Get non-cites relation types applicable to source and target kinds.
    func nonCitesRelationTypes(applicableFrom source: Kinds, to target: Kinds, modelContext: ModelContext) -> [RelationType] {
        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let fetched = (try? modelContext.fetch(fetch)) ?? []

        if source == .scenes && target == .projects {
            return fetched.filter { $0.code == Self.canonicalSceneProjectCode }
        }

        return fetched.filter { $0.code != Self.citesCode && relationTypeApplies($0, from: source, to: target) }
    }

    /// Get applicable retype choices for changing relationship type.
    func applicableRetypeChoices(fromKind: Kinds, toKind: Kinds, modelContext: ModelContext) -> [RelationType] {
        if fromKind == .scenes && toKind == .projects {
            let t = fetchRelationType(code: Self.canonicalSceneProjectCode, modelContext: modelContext)
                ?? ensureRelationType(code: Self.canonicalSceneProjectCode, forward: "stories", inverse: "is storied by", sourceKind: .scenes, targetKind: .projects, modelContext: modelContext)
            return [t]
        }

        _ = fetchRelationType(code: Self.defaultNonSourceCode, modelContext: modelContext)
            ?? ensureRelationType(code: Self.defaultNonSourceCode, forward: "references", inverse: "referenced by", sourceKind: nil, targetKind: nil, modelContext: modelContext)

        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        let all = (try? modelContext.fetch(fetch)) ?? []
        return all.filter { relationTypeApplies($0, from: fromKind, to: toKind) && ($0.code != Self.citesCode || fromKind == .sources) }
    }

    // MARK: - Edge Operations

    /// Create a CardEdge if it doesn't already exist.
    /// Delegates to RelationshipManager when available via services.
    @MainActor
    func createEdgeIfNeeded(from source: Card, to target: Card, type: RelationType, appendToEnd: Bool, modelContext: ModelContext, services: ServiceContainer? = nil) {
        guard let enforcedType = canonicalizedTypeFor(source: source, target: target, proposed: type, modelContext: modelContext) else {
            return
        }

        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        let typeCodeOpt: String? = enforcedType.code
        let existsFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt && $0.type?.code == typeCodeOpt
            }
        )
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            if let existingEdge = found.first {
                ensureReverseEdge(forwardEdge: existingEdge, appendToEnd: appendToEnd, modelContext: modelContext, services: services)
            }
            return
        }

        let createdAt: Date
        if appendToEnd {
            let fetchForMax = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.to?.id == targetIDOpt && $0.type?.code == typeCodeOpt
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let existing = (try? modelContext.fetch(fetchForMax)) ?? []
            let last = existing.last?.createdAt ?? Date()
            createdAt = last.addingTimeInterval(0.001)
        } else {
            createdAt = Date()
        }

        let edge = CardEdge(from: source, to: target, type: enforcedType, note: nil, createdAt: createdAt)
        modelContext.insert(edge)
        EdgeIntegrityMonitor.incrementCounts(source: source, target: target)
        try? modelContext.save()

        ensureReverseEdge(forwardEdge: edge, appendToEnd: appendToEnd, modelContext: modelContext, services: services)
    }

    /// Ensure the reverse edge exists for a forward edge.
    /// Delegates to RelationshipManager when available via services.
    @MainActor
    func ensureReverseEdge(forwardEdge: CardEdge, appendToEnd: Bool, modelContext: ModelContext, services: ServiceContainer? = nil) {
        guard let src = forwardEdge.from, let dst = forwardEdge.to, let t = forwardEdge.type else { return }
        let srcID: UUID? = src.id
        let dstID: UUID? = dst.id

        let mirror = mirrorType(for: t, sourceKind: src.kind, targetKind: dst.kind, modelContext: modelContext)
        let mirrorCodeForCheck: String? = mirror.code
        let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
            $0.from?.id == dstID && $0.to?.id == srcID && $0.type?.code == mirrorCodeForCheck
        })
        if let found = try? modelContext.fetch(existsFetch), found.isEmpty == false {
            return
        }

        let createdAt: Date
        if appendToEnd {
            let mirrorCode: String? = mirror.code
            let fetchForMax = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.to?.id == srcID && $0.type?.code == mirrorCode
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            let existing = (try? modelContext.fetch(fetchForMax)) ?? []
            let last = existing.last?.createdAt ?? (forwardEdge.createdAt)
            createdAt = last.addingTimeInterval(0.001)
        } else {
            createdAt = forwardEdge.createdAt
        }

        let reverse = CardEdge(from: dst, to: src, type: mirror, note: forwardEdge.note, createdAt: createdAt)
        modelContext.insert(reverse)
        EdgeIntegrityMonitor.incrementCounts(source: dst, target: src)
        try? modelContext.save()
    }

    /// Retype an existing edge to a new RelationType.
    @MainActor
    func retypeEdge(from source: Card, to target: Card, newType: RelationType, modelContext: ModelContext) {
        guard let enforced = canonicalizedTypeFor(source: source, target: target, proposed: newType, modelContext: modelContext) else { return }

        let sourceIDOpt: UUID? = source.id
        let targetIDOpt: UUID? = target.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == sourceIDOpt && $0.to?.id == targetIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        guard let edge = try? modelContext.fetch(fetch).first else { return }

        if edge.type?.code == enforced.code { return }

        edge.type = enforced
        try? modelContext.save()

        let reverseFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == targetIDOpt && $0.to?.id == sourceIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        if let reverseEdge = try? modelContext.fetch(reverseFetch).first {
            let mirror = mirrorType(for: enforced, sourceKind: source.kind, targetKind: target.kind, modelContext: modelContext)
            reverseEdge.type = mirror
            try? modelContext.save()
        } else {
            ensureReverseEdge(forwardEdge: edge, appendToEnd: true, modelContext: modelContext)
        }
    }

    /// Remove all relationships between two cards.
    /// Delegates to RelationshipManager when available via services.
    @MainActor
    func removeRelationship(between a: Card, and b: Card, modelContext: ModelContext, services: ServiceContainer? = nil) {
        if let mgr = services?.relationshipManager {
            try? mgr.removeRelationship(between: a, and: b, typeFilter: relationTypeFilter)
            return
        }
        // Fallback: direct modelContext operations
        let aID: UUID? = a.id
        let bID: UUID? = b.id

        if let t = relationTypeFilter {
            let forwardCode: String? = t.code
            let fwdFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID && $0.type?.code == forwardCode })
            let fwd = (try? modelContext.fetch(fwdFetch)) ?? []

            let mirror = mirrorType(for: t, sourceKind: a.kind, targetKind: b.kind, modelContext: modelContext)
            let mirrorCode: String? = mirror.code
            let revFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID && $0.type?.code == mirrorCode })
            let rev = (try? modelContext.fetch(revFetch)) ?? []

            #if DEBUG
            print("[EdgeAudit] CardRelationshipOperations.removeRelationship(fallback, typed): Deleting \(fwd.count) fwd + \(rev.count) rev edge(s) between '\(a.name)' and '\(b.name)' type=\(t.code)")
            #endif

            for e in fwd {
                EdgeIntegrityMonitor.decrementCounts(source: e.from, target: e.to)
                modelContext.delete(e)
            }
            for e in rev {
                EdgeIntegrityMonitor.decrementCounts(source: e.from, target: e.to)
                modelContext.delete(e)
            }
        } else {
            let abFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == aID && $0.to?.id == bID })
            let baFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == bID && $0.to?.id == aID })
            let ab = (try? modelContext.fetch(abFetch)) ?? []
            let ba = (try? modelContext.fetch(baFetch)) ?? []

            #if DEBUG
            print("[EdgeAudit] CardRelationshipOperations.removeRelationship(fallback, all): Deleting \(ab.count) fwd + \(ba.count) rev edge(s) between '\(a.name)' and '\(b.name)'")
            #endif

            for e in ab {
                EdgeIntegrityMonitor.decrementCounts(source: e.from, target: e.to)
                modelContext.delete(e)
            }
            for e in ba {
                EdgeIntegrityMonitor.decrementCounts(source: e.from, target: e.to)
                modelContext.delete(e)
            }
        }

        try? modelContext.save()
    }

    // MARK: - Card Operations

    /// Cleanup and delete a card.
    /// Delegates to CardOperationManager when available via services.
    @MainActor
    func cleanupAndDelete(_ card: Card, modelContext: ModelContext, services: ServiceContainer? = nil) {
        if let mgr = services?.cardOperations {
            try? mgr.deleteCard(card)
            return
        }
        // Fallback: direct modelContext operations
        card.cleanupBeforeDeletion(in: modelContext)
        modelContext.delete(card)
        try? modelContext.save()
    }

    /// Change a card's type and remove all its relationships.
    /// Delegates to CardOperationManager when available via services.
    @MainActor
    func changeCardType(card: Card, to newKind: Kinds, modelContext: ModelContext, services: ServiceContainer? = nil) {
        guard newKind != card.kind else { return }

        if let mgr = services?.cardOperations {
            do { try mgr.changeCardType(card, to: newKind) } catch {}
            return
        }

        // Fallback: direct modelContext operations
        let cardID: UUID? = card.id
        let fetchFrom = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        let fetchTo = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

        let edgesFrom = (try? modelContext.fetch(fetchFrom)) ?? []
        let edgesTo = (try? modelContext.fetch(fetchTo)) ?? []

        #if DEBUG
        let totalEdges = edgesFrom.count + edgesTo.count
        print("[EdgeAudit] CardRelationshipOperations.changeCardType(fallback): Card '\(card.name)' (\(card.id)) changing from \(card.kind.rawValue) to \(newKind.rawValue) — deleting \(edgesFrom.count) outgoing + \(edgesTo.count) incoming = \(totalEdges) edge(s)")
        #endif

        for edge in edgesFrom + edgesTo {
            EdgeIntegrityMonitor.decrementCounts(source: edge.from, target: edge.to)
            modelContext.delete(edge)
        }

        card.kindRaw = newKind.rawValue
        try? modelContext.save()
    }

    // MARK: - Canonicalization

    /// Get the canonical type for a source/target pair, handling special cases.
    func canonicalizedTypeFor(source: Card, target: Card, proposed: RelationType?, modelContext: ModelContext) -> RelationType? {
        if source.kind == .scenes && target.kind == .projects {
            let sceneProjectCode = Self.canonicalSceneProjectCode
            let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == sceneProjectCode })
            if let canonical = try? modelContext.fetch(fetch).first {
                return canonical
            } else {
                let t = RelationType(code: sceneProjectCode, forwardLabel: "stories", inverseLabel: "is storied by", sourceKind: .scenes, targetKind: .projects)
                modelContext.insert(t)

                let mirrorCode = "is-storied-by/stories"
                let existsMirror = (try? modelContext.fetch(FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == mirrorCode })))?.first
                if existsMirror == nil {
                    let mirror = RelationType(code: mirrorCode, forwardLabel: "is storied by", inverseLabel: "stories", sourceKind: .projects, targetKind: .scenes)
                    modelContext.insert(mirror)
                }

                try? modelContext.save()
                return t
            }
        }

        if let proposed, proposed.matches(from: source.kind, to: target.kind) {
            return proposed
        }
        return nil
    }

    // MARK: - Existing Card Candidates

    /// Get cards of a given kind that can be linked to the primary card.
    func availableExistingCandidates(for kind: Kinds, primary: Card, modelContext: ModelContext) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(predicate: #Predicate {
            $0.kindRaw == kindRaw
        })
        let allOfKind = (try? modelContext.fetch(fetch)) ?? []

        let filtered = allOfKind.filter { $0.id != primary.id }
        var seen: Set<UUID> = []
        var unique: [Card] = []
        for c in filtered {
            if !seen.contains(c.id) {
                seen.insert(c.id)
                unique.append(c)
            }
        }

        return unique.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Get the relationship decoration label for a card.
    func relationDecoration(for card: Card, primary: Card, modelContext: ModelContext) -> String? {
        if let t = relationTypeFilter {
            return t.forwardLabel
        }
        let cardIDOpt: UUID? = card.id
        let primaryIDOpt: UUID? = primary.id
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.from?.id == cardIDOpt && $0.to?.id == primaryIDOpt
            }
        )
        if let edge = try? modelContext.fetch(fetch).first {
            return edge.type?.forwardLabel
        }
        return nil
    }

    // MARK: - Code Generation

    /// Sanitize a string for use in a code.
    func sanitize(_ s: String) -> String {
        let lowered = s.lowercased()
        let replaced = lowered.replacingOccurrences(of: " ", with: "-")
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
        let filtered = String(replaced.unicodeScalars.filter { allowed.contains($0) })
        var result = filtered
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        return result
    }

    /// Generate a code from forward and inverse labels.
    func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        } else {
            return "\(base)"
        }
    }
}
