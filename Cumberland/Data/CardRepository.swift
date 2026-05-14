//
//  CardRepository.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 2
//
//  Repository encapsulating SwiftData fetch operations for the Card model.
//  Provides methods to fetch all cards, cards by kind, cards by ID, and
//  filtered/sorted card lists. Used by services and views that need
//  non-@Query imperative fetching.
//

import Foundation
import SwiftData
import RealityKit

/// Repository for Card data access operations.
/// Encapsulates all SwiftData queries and operations for the Card model.
///
/// **ER-0022 Phase 2**: Abstracts SwiftData access to enable testability and dependency injection
@Observable
@MainActor
final class CardRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Insert/Update/Delete Operations
    // MARK: - Insert Operations

    /// Create a new card and insert it into the context
    /// - Parameters:
    ///   - kind: The card kind
    ///   - name: The card name
    ///   - subtitle: The card subtitle
    ///   - detailedText: The detailed text
    /// - Returns: The newly created card
    /// - Throws: SwiftData errors
    @discardableResult
    func createCard(
        kind: Kinds,
        name: String,
        subtitle: String = "",
        detailedText: String = ""
    ) throws -> Card {
        let card = Card(kind: kind, name: name, subtitle: subtitle, detailedText: detailedText)
        modelContext.insert(card)
        try modelContext.save()
        return card
    }
    
    @discardableResult
    func insertCard(_ card: Card) throws -> Card {
        insert(card)
        try modelContext.save()
        return card
    }

    /// INSERT a card INTO the context without saving
    /// Use this when you need to set additional properties before saving
    /// - Parameter card: The card to insert
    /// - Note: Caller is responsible for calling save() when ready
    func insertWithoutSaving(_ card: Card) {
        insert(card)
    }

    /// INSERT a card INTO the context.  Note this function is Private.  it is used internally only
    /// - Parameter card: The card to delete
    private func insert(_ card: Card) {
        modelContext.insert(card)
    }

    // MARK: - Update Operations


    /// Update a card's basic properties
    /// - Parameters:
    ///   - card: The card to update
    ///   - name: New name (nil = no change)
    ///   - subtitle: New subtitle (nil = no change)
    ///   - detailedText: New detailed text (nil = no change)
    /// - Throws: SwiftData errors
    func updateCard(
        _ card: Card,
        name: String? = nil,
        subtitle: String? = nil,
        detailedText: String? = nil
    ) throws {
        if let name = name {
            card.name = name
        }
        if let subtitle = subtitle {
            card.subtitle = subtitle
        }
        if let detailedText = detailedText {
            card.detailedText = detailedText
        }
        try modelContext.save()
    }

    /// Update a card's kind.  Note changing a card's Kind will remove all previous relationships to other objects.  
    /// - Parameters:
    ///   - card: The card to update
    ///   - kind: New kind
    /// - Throws: SwiftData errors
    func updateCardKind(_ card: Card, to kind: Kinds) throws {
        // Store old kind for logging
        let _ = card.kind

        let edgeRepository = EdgeRepository.init(modelContext: modelContext)
        try edgeRepository.deleteAllRelationships(for: card)
        
        // Update the kind
        card.kindRaw = kind.rawValue

        try modelContext.save()
    }

    /// Update a card's image
    /// - Parameters:
    ///   - card: The card to update
    ///   - imageData: New image data (nil to remove image)
    /// - Throws: SwiftData errors
    func updateCardImage(_ card: Card, imageData: Data?) throws {
        if let imageData = imageData {
            try card.setOriginalImageData(imageData)
        } else {
            // Remove image
            card.originalImageData = nil
            card.thumbnailData = nil
            if let url = card.imageFileURL {
                try? ImageStore.shared.deleteOriginalImage(at: url)
                card.imageFileURL = nil
            }
        }
        try modelContext.save()
    }
    
    // MARK: - Delete Operations
    ///Public Delete Card function.  Note delete has been made private as it should not be used externally.
    /// - Parameter card: The card to delete
    /// - Throws SwiftDataErrors
    func deleteCard(_ card: Card) throws {
        try delete(card)
        try modelContext.save()
    }

    /// Delete multiple cards
    /// - Parameter cards: Array of cards to delete
    /// - Throws: SwiftData errors
    func deleteCards(_ cards: [Card]) throws {
        for card in cards {
            try delete(card)
        }
        try modelContext.save()
    }

    /// Delete a card from the context.  Note this function is Private.  it is used internally only
    /// - Parameter card: The card to delete
    /// - Throws: SwiftData errors
    private func delete(_ card: Card) throws {
        card.cleanupBeforeDeletion(in: modelContext)
        modelContext.delete(card)
    }
    
    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - Batch Operations

    /// Fetch count of cards by kind
    /// - Parameter kind: The card kind
    /// - Returns: Count of cards of this kind
    func count(ofKind kind: Kinds) -> Int {
        return fetch(byKind: kind).count
    }

    /// Fetch total count of all cards
    /// - Returns: Total count
    func countAll() -> Int {
        return fetchAll().count
    }

    // MARK: - Fetch Operations

    /// Fetch all cards, sorted by name
    /// - Returns: Array of all cards
    func fetchAll() -> [Card] {
        let fetch = FetchDescriptor<Card>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards filtered by kind
    /// - Parameter kind: The card kind to filter by
    /// - Returns: Array of cards matching the kind
    func fetch(byKind kind: Kinds) -> [Card] {
        let kindRaw = kind.rawValue
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == kindRaw },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch a single card by its persistent identifier
    /// - Parameter id: The persistent identifier
    /// - Returns: The card, or nil if not found
    func fetch(byID id: PersistentIdentifier) -> Card? {
        return modelContext.model(for: id) as? Card
    }

    /// Fetch a card by UUID
    /// - Parameter uuid: The card's UUID
    /// - Returns: The card, or nil if not found
    func fetch(byUUID uuid: UUID) -> Card? {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Search cards by text query (searches name, subtitle, and detailed text)
    /// - Parameter query: The search query
    /// - Returns: Array of matching cards
    func search(query: String) -> [Card] {
        guard !query.isEmpty else { return fetchAll() }

        let lowercaseQuery = query.lowercased()

        // Use normalized search text for efficient searching
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.normalizedSearchText.contains(lowercaseQuery)
            },
            sortBy: [SortDescriptor(\.name)]
        )

        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards with images (originalImageData is not nil)
    /// - Returns: Array of cards with images
    func fetchCardsWithImages() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.originalImageData != nil },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards by multiple kinds
    /// - Parameter kinds: Array of kinds to filter by
    /// - Returns: Array of cards matching any of the kinds
    func fetch(byKinds kinds: [Kinds]) -> [Card] {
        let kindRawValues = kinds.map { $0.rawValue }
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                kindRawValues.contains(card.kindRaw)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch cards assigned to a specific structure element
    /// - Parameter element: The structure element
    /// - Returns: Array of cards assigned to this element
    func fetch(assignedTo element: StructureElement) -> [Card] {
        // Return cards from the element's relationship directly
        return element.assignedCards ?? []
    }

    /// Fetch cards not assigned to any structure (backlog cards)
    /// - Returns: Array of unassigned cards
    func fetchUnassignedCards() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.structureElements?.isEmpty ?? true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    // MARK: - Specialized Queries

    /// Fetch timeline cards (kind = .timelines)
    /// - Returns: Array of timeline cards
    func fetchTimelineCards() -> [Card] {
        return fetch(byKind: .timelines)
    }

    /// Fetch calendar cards (kind = .calendars)
    /// - Returns: Array of calendar cards
    func fetchCalendarCards() -> [Card] {
        return fetch(byKind: .calendars)
    }

    /// Fetch chronicle cards (kind = .chronicles)
    /// - Returns: Array of chronicle cards
    func fetchChronicleCards() -> [Card] {
        return fetch(byKind: .chronicles)
    }

    /// Fetch scene cards (kind = .scenes)
    /// - Returns: Array of scene cards
    func fetchSceneCards() -> [Card] {
        return fetch(byKind: .scenes)
    }

    /// Fetch character cards (kind = .characters)
    /// - Returns: Array of character cards
    func fetchCharacterCards() -> [Card] {
        return fetch(byKind: .characters)
    }

    /// Fetch location cards (kind = .locations)
    /// - Returns: Array of location cards
    func fetchLocationCards() -> [Card] {
        return fetch(byKind: .locations)
    }

    /// Fetch cards with AI-generated images
    /// - Returns: Array of cards with AI-generated images
    func fetchCardsWithAIImages() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { $0.imageGeneratedByAI == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch recently modified cards
    /// - Parameter limit: Maximum number of cards to return
    /// - Returns: Array of recently modified cards
    func fetchRecentlyModified(limit: Int = 10) -> [Card] {
        // Note: Card model doesn't have a modifiedDate property
        // This would need to be added to the model first
        // For now, return all cards sorted by name
        return Array(fetchAll().prefix(limit))
    }

    // MARK: - Project Writer Queries

    /// Fetch scenes associated with a project via "belongs-to/contains-scene" edges,
    /// ordered by sortIndex (manuscript order).
    ///
    /// - Parameter project: The project card
    /// - Returns: Array of scene cards in manuscript order
    func fetchScenesInProject(_ project: Card) -> [Card] {
        guard project.kind == .projects else { return [] }

        let projectID: UUID? = project.id
        let sceneKind: String = Kinds.scenes.rawValue
        let relationCode: String? = "belongs-to/contains-scene"

        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.to?.id == projectID &&
                edge.from?.kindRaw == sceneKind &&
                edge.type?.code == relationCode
            },
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )

        let edges = (try? modelContext.fetch(fetch)) ?? []
        return edges.compactMap { $0.from }
    }

    /// Fetch chapters associated with a project via "part-of/has-chapter" edges,
    /// ordered by sortIndex (chapter order).
    ///
    /// - Parameter project: The project card
    /// - Returns: Array of chapter cards in order
    func fetchChaptersInProject(_ project: Card) -> [Card] {
        guard project.kind == .projects else { return [] }

        let projectID: UUID? = project.id
        let chapterKind: String = Kinds.chapters.rawValue
        let relationCode: String? = "part-of/has-chapter"

        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.to?.id == projectID &&
                edge.from?.kindRaw == chapterKind &&
                edge.type?.code == relationCode
            },
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )

        let edges = (try? modelContext.fetch(fetch)) ?? []
        return edges.compactMap { $0.from }
    }

    /// Fetch scenes in a specific chapter within a project context.
    /// Uses the existing "part-of/has-scene" edges to determine chapter membership.
    ///
    /// - Parameters:
    ///   - chapterID: The UUID of the chapter to filter by
    ///   - projectID: The UUID of the project context
    /// - Returns: Array of scene cards in manuscript order within the chapter
    func fetchScenesInChapter(chapterID: UUID, projectID: UUID) -> [Card] {
        // Get scenes that belong to this project
        let projectIDOpt: UUID? = projectID
        let sceneKind: String = Kinds.scenes.rawValue
        let relationCode: String? = "belongs-to/contains-scene"

        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.to?.id == projectIDOpt &&
                edge.from?.kindRaw == sceneKind &&
                edge.type?.code == relationCode
            },
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )

        let projectSceneEdges = (try? modelContext.fetch(fetch)) ?? []

        // Get scenes that belong to this chapter
        let chapterIDOpt: UUID? = chapterID
        let chapterSceneFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.to?.id == chapterIDOpt &&
                edge.type?.code == "part-of/has-scene"
            }
        )
        let chapterSceneEdges = (try? modelContext.fetch(chapterSceneFetch)) ?? []
        let sceneIDsInChapter = Set(chapterSceneEdges.compactMap { $0.from?.id })

        // Return scenes that are both in the project and in the chapter
        return projectSceneEdges.compactMap { $0.from }.filter { sceneIDsInChapter.contains($0.id) }
    }

    /// Fetch scenes in a project that are not assigned to any chapter (orphaned scenes).
    ///
    /// - Parameter project: The project card
    /// - Returns: Array of orphaned scene cards in manuscript order
    func fetchOrphanedScenesInProject(_ project: Card) -> [Card] {
        guard project.kind == .projects else { return [] }

        let allScenes = fetchScenesInProject(project)

        // Get all scenes that belong to any chapter via "part-of/has-scene"
        let chapterSceneFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.type?.code == "part-of/has-scene"
            }
        )
        let chapterSceneEdges = (try? modelContext.fetch(chapterSceneFetch)) ?? []
        let sceneIDsInChapters = Set(chapterSceneEdges.compactMap { $0.from?.id })

        return allScenes.filter { !sceneIDsInChapters.contains($0.id) }
    }

    /// Find the project that owns a scene
    ///
    /// - Parameter scene: The scene card
    /// - Returns: The project card that owns this scene, or nil if not found
    func fetchProjectForScene(_ scene: Card) -> Card? {
        guard scene.kind == .scenes else { return nil }

        let sceneIDOpt: UUID? = scene.id
        let descriptor = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.from?.id == sceneIDOpt &&
                edge.type?.code == "belongs-to/contains-scene"
            }
        )

        guard let edge = try? modelContext.fetch(descriptor).first else {
            return nil
        }

        return edge.to
    }
}
