//
//  QueryService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 2
//

import Foundation
import SwiftData

/// Service providing common @Query patterns as reusable methods.
/// Consolidates frequently-used queries to reduce duplication across views.
///
/// **ER-0022 Phase 2**: Provides common query patterns for views
@Observable
@MainActor
final class QueryService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Cards

    /// Get all cards (replaces @Query private var cards: [Card])
    /// - Returns: Array of all cards
    func getAllCards() -> [Card] {
        let fetch = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get cards filtered by kind
    /// - Parameter kind: The card kind
    /// - Returns: Array of cards of this kind
    func getCards(ofKind kind: Kinds) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == kindRaw },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Story Structures

    /// Get all story structures (replaces @Query private var structures: [StoryStructure])
    /// - Returns: Array of all structures
    func getAllStructures() -> [StoryStructure] {
        let fetch = FetchDescriptor<StoryStructure>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Settings

    /// Get app settings (replaces @Query private var allSettings: [AppSettings])
    /// - Returns: The app settings instance, or creates a new one if none exists
    func getSettings() -> AppSettings {
        let fetch = FetchDescriptor<AppSettings>()
        if let existing = try? modelContext.fetch(fetch).first {
            return existing
        }

        // Create new settings if none exist
        let settings = AppSettings()
        modelContext.insert(settings)
        try? modelContext.save()
        return settings
    }

    // MARK: - Sources

    /// Get all sources (replaces @Query private var sources: [Source])
    /// - Returns: Array of all sources
    func getAllSources() -> [Source] {
        let fetch = FetchDescriptor<Source>(
            sortBy: [SortDescriptor(\.title)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Relation Types

    /// Get all relation types (replaces @Query private var allRelationTypes: [RelationType])
    /// - Returns: Array of all relation types
    func getAllRelationTypes() -> [RelationType] {
        let fetch = FetchDescriptor<RelationType>(
            sortBy: [SortDescriptor(\.forwardLabel)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get relation types applicable to a source and target kind
    /// - Parameters:
    ///   - sourceKind: The source card kind
    ///   - targetKind: The target card kind
    /// - Returns: Array of applicable relation types
    func getRelationTypes(from sourceKind: Kinds, to targetKind: Kinds) -> [RelationType] {
        // Fetch all and filter in Swift (predicate too complex for compiler)
        let allTypes = getAllRelationTypes()
        return allTypes.filter { rt in
            let sourceOK = (rt.sourceKindRaw == nil) || (rt.sourceKindRaw == sourceKind.rawValue)
            let targetOK = (rt.targetKindRaw == nil) || (rt.targetKindRaw == targetKind.rawValue)
            return sourceOK && targetOK
        }
    }

    // MARK: - Boards

    /// Get all boards (replaces @Query private var allBoards: [Board])
    /// - Returns: Array of all boards
    func getAllBoards() -> [Board] {
        let fetch = FetchDescriptor<Board>()
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get the primary board for a card
    /// - Parameter card: The card
    /// - Returns: The primary board, or nil if none exists
    func getPrimaryBoard(for card: Card) -> Board? {
        let cardID: UUID? = card.id
        let fetch = FetchDescriptor<Board>(
            predicate: #Predicate { $0.primaryCard?.id == cardID }
        )
        return try? modelContext.fetch(fetch).first
    }

    // MARK: - Calendar Systems

    /// Get all calendar systems (replaces @Query private var calendars: [CalendarSystem])
    /// - Returns: Array of all calendar systems
    func getAllCalendarSystems() -> [CalendarSystem] {
        let fetch = FetchDescriptor<CalendarSystem>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Edges

    /// Get all edges (replaces @Query private var allEdges: [CardEdge])
    /// - Returns: Array of all edges
    func getAllEdges() -> [CardEdge] {
        let fetch = FetchDescriptor<CardEdge>()
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Get recent edges (for diagnostics)
    /// - Parameter limit: Maximum number of edges to return
    /// - Returns: Array of recently created edges
    func getRecentEdges(limit: Int = 20) -> [CardEdge] {
        let fetch = FetchDescriptor<CardEdge>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allEdges = (try? modelContext.fetch(fetch)) ?? []
        return Array(allEdges.prefix(limit))
    }

    // MARK: - Convenience Methods

    /// Refresh queries (useful after batch operations)
    func refresh() {
        // SwiftData automatically refreshes, but this method provides
        // a consistent API for views that need to explicitly refresh
        try? modelContext.save()
    }

    /// Check if any cards exist
    /// - Returns: True if at least one card exists
    func hasAnyCards() -> Bool {
        return !getAllCards().isEmpty
    }

    /// Check if any structures exist
    /// - Returns: True if at least one structure exists
    func hasAnyStructures() -> Bool {
        return !getAllStructures().isEmpty
    }

    /// Get card count
    /// - Returns: Total number of cards
    func getCardCount() -> Int {
        return getAllCards().count
    }

    /// Get card count by kind
    /// - Parameter kind: The card kind
    /// - Returns: Number of cards of this kind
    func getCardCount(ofKind kind: Kinds) -> Int {
        return getCards(ofKind: kind).count
    }
}
