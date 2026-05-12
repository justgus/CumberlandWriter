//
//  RelationTypeManager.swift
//  Cumberland
//
//  Created as part of DR-0103: Service Layer Completion.
//  Centralises RelationType CRUD, mirror-type management, and the shared
//  sanitize / makeCode utilities that were previously duplicated across
//  CardRelationshipOperations, CardRelationshipSheets, RelationTypeFormView,
//  SuggestionEngine, and SceneProjectRelationDiagnosticsView.
//

import Foundation
import SwiftData

/// Centralized manager for RelationType persistence operations.
///
/// **DR-0103**: Consolidates RelationType creation, mirror management,
/// and code-generation utilities into a single service.
@Observable
@MainActor
final class RelationTypeManager {

    private let modelContext: ModelContext
    private let edgeRepository: EdgeRepository

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.edgeRepository = EdgeRepository(modelContext: modelContext)
    }

    // MARK: - Core CRUD

    /// Create a new RelationType and persist it.
    /// - Throws: If a type with the same code already exists or save fails.
    @discardableResult
    func createRelationType(
        code: String,
        forwardLabel: String,
        inverseLabel: String,
        sourceKind: Kinds? = nil,
        targetKind: Kinds? = nil
    ) throws -> RelationType {
        if fetchRelationType(code: code) != nil {
            throw RelationTypeError.duplicateCode
        }
        let rt = RelationType(
            code: code,
            forwardLabel: forwardLabel,
            inverseLabel: inverseLabel,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
        modelContext.insert(rt)
        try modelContext.save()
        return rt
    }

    /// Fetch an existing type or create one. Idempotent — safe to call repeatedly.
    /// Also ensures the mirror type exists.
    @discardableResult
    func ensureRelationType(
        code: String,
        forwardLabel: String,
        inverseLabel: String,
        sourceKind: Kinds? = nil,
        targetKind: Kinds? = nil
    ) -> RelationType {
        if let existing = fetchRelationType(code: code) {
            // Still ensure mirror exists
            ensureMirror(
                forwardLabel: forwardLabel,
                inverseLabel: inverseLabel,
                sourceKind: sourceKind,
                targetKind: targetKind
            )
            return existing
        }
        let rt = RelationType(
            code: code,
            forwardLabel: forwardLabel,
            inverseLabel: inverseLabel,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
        modelContext.insert(rt)
        ensureMirror(
            forwardLabel: forwardLabel,
            inverseLabel: inverseLabel,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
        try? modelContext.save()
        return rt
    }

    /// Delete a RelationType.
    /// DR-0202: Properly cleanup edges using this type before deletion
    /// - Parameter type: The RelationType to delete
    /// - Throws: SwiftData errors
    func deleteRelationType(_ type: RelationType) throws {
        #if DEBUG
        print("[RelationTypeManager] Deleting RelationType '\(type.code)' and cleaning up associated edges")
        #endif

        // DR-0202: Clean up all edges using this type before deleting
        let edgesWithType = edgeRepository.fetch(ofType: type)

        #if DEBUG
        print("[RelationTypeManager] Found \(edgesWithType.count) edges using type '\(type.code)'")
        #endif

        // Delete all edges using this type
        for edge in edgesWithType {
            guard let from = edge.from,
                  let to = edge.to else {
                #if DEBUG
                print("[RelationTypeManager] Skipping edge with nil source or target")
                #endif
                continue
            }

            // Use EdgeRepository to properly delete the edge (handles reverse edges and counts)
            try edgeRepository.deleteRelationship(from: from, to: to, relationType: type)
        }

        // Now safe to delete the RelationType
        modelContext.delete(type)
        try modelContext.save()

        #if DEBUG
        print("[RelationTypeManager] Successfully deleted RelationType '\(type.code)' and \(edgesWithType.count) associated edges")
        #endif
    }

    // MARK: - Mirror Management

    /// Ensure a mirror (inverse) RelationType exists. Creates one if missing.
    /// Uses collision-safe code generation with suffix numbering.
    @discardableResult
    func ensureMirror(
        forwardLabel: String,
        inverseLabel: String,
        sourceKind: Kinds? = nil,
        targetKind: Kinds? = nil
    ) -> RelationType {
        let mirrorForward = inverseLabel
        let mirrorInverse = forwardLabel
        let mirrorSource = targetKind
        let mirrorTarget = sourceKind

        let desiredCode = Self.makeCode(forward: mirrorForward, inverse: mirrorInverse)

        // Check if mirror already exists with correct code
        if let existing = fetchRelationType(code: desiredCode) {
            return existing
        }

        // Handle code collisions with suffix numbering
        var codeToUse = desiredCode
        var suffix = 1
        while fetchRelationType(code: codeToUse) != nil {
            suffix += 1
            codeToUse = Self.makeCode(forward: mirrorForward, inverse: mirrorInverse, suffix: suffix)
        }

        let mirror = RelationType(
            code: codeToUse,
            forwardLabel: mirrorForward,
            inverseLabel: mirrorInverse,
            sourceKind: mirrorSource,
            targetKind: mirrorTarget
        )
        modelContext.insert(mirror)
        // Caller is responsible for save (or ensureRelationType saves)
        return mirror
    }

    /// Get or create the mirror type for a given RelationType.
    /// Tries multiple strategies: exact code match, label+kind semantic match, then creation.
    func mirrorType(
        for type: RelationType,
        sourceKind: Kinds,
        targetKind: Kinds
    ) -> RelationType {
        let mirrorForward = type.inverseLabel
        let mirrorInverse = type.forwardLabel

        // Strategy 1: Exact code match
        let desiredCode = Self.makeCode(forward: mirrorForward, inverse: mirrorInverse)
        if let existing = fetchRelationType(code: desiredCode) {
            return existing
        }

        // Strategy 2: Semantic match by labels
        let all = fetchAll()
        if let match = all.first(where: {
            ($0.sourceKindRaw == targetKind.rawValue || $0.sourceKindRaw == nil) &&
            ($0.targetKindRaw == sourceKind.rawValue || $0.targetKindRaw == nil) &&
            $0.forwardLabel == mirrorForward &&
            $0.inverseLabel == mirrorInverse
        }) {
            return match
        }

        // Strategy 3: Create new mirror with collision-safe code
        let mirror = ensureMirror(
            forwardLabel: type.forwardLabel,
            inverseLabel: type.inverseLabel,
            sourceKind: sourceKind,
            targetKind: targetKind
        )
        try? modelContext.save()
        return mirror
    }

    // MARK: - Queries

    /// Fetch a RelationType by its code.
    func fetchRelationType(code: String) -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == code })
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch all RelationTypes sorted by code.
    func fetchAll() -> [RelationType] {
        let fetch = FetchDescriptor<RelationType>(sortBy: [SortDescriptor(\.code, order: .forward)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch RelationTypes applicable to a given source/target kind pair.
    func fetchApplicable(from sourceKind: Kinds, to targetKind: Kinds) -> [RelationType] {
        fetchAll().filter { $0.matches(from: sourceKind, to: targetKind) }
    }

    // MARK: - Shared Utilities

    /// Sanitize a string for use in a RelationType code.
    /// Lowercases, replaces spaces with hyphens, strips invalid characters, collapses double-hyphens.
    static func sanitize(_ s: String) -> String {
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

    /// Generate a RelationType code from forward and inverse labels.
    /// Format: `"forward/inverse"` or `"forward/inverse-N"` when a suffix is provided.
    static func makeCode(forward: String, inverse: String, suffix: Int? = nil) -> String {
        let base = "\(sanitize(forward))/\(sanitize(inverse))"
        if let suffix {
            return "\(base)-\(suffix)"
        }
        return base
    }
}

// MARK: - Errors

enum RelationTypeError: Error, LocalizedError {
    case duplicateCode

    var errorDescription: String? {
        switch self {
        case .duplicateCode:
            return "A RelationType with this code already exists."
        }
    }
}
