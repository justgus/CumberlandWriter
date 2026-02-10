//
//  StructureRepository.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 2
//
//  Repository for StoryStructure and StructureElement SwiftData operations.
//  Provides fetch-by-project, fetch all structures, element CRUD, and
//  card-to-element assignment helpers. Centralises structure query logic
//  used by StructureBoardView and StructureAssignmentManager.
//

import Foundation
import SwiftData

/// Repository for StoryStructure and StructureElement data access operations.
/// Encapsulates all SwiftData queries and operations for story structure models.
///
/// **ER-0022 Phase 2**: Abstracts SwiftData access for story structure data
@Observable
@MainActor
final class StructureRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - StoryStructure Operations

    /// Fetch all story structures
    /// - Returns: Array of all story structures
    func fetchAllStructures() -> [StoryStructure] {
        let fetch = FetchDescriptor<StoryStructure>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch a structure by ID
    /// - Parameter id: The persistent identifier
    /// - Returns: The structure, or nil if not found
    func fetchStructure(byID id: PersistentIdentifier) -> StoryStructure? {
        return modelContext.model(for: id) as? StoryStructure
    }

    /// Fetch a structure by UUID
    /// - Parameter uuid: The structure's UUID
    /// - Returns: The structure, or nil if not found
    func fetchStructure(byUUID uuid: UUID) -> StoryStructure? {
        let fetch = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch a structure by name
    /// - Parameter name: The structure name
    /// - Returns: The structure, or nil if not found
    func fetchStructure(byName name: String) -> StoryStructure? {
        let fetch = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { $0.name == name }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Insert a new structure
    /// - Parameter structure: The structure to insert
    /// - Throws: SwiftData errors
    func insertStructure(_ structure: StoryStructure) throws {
        modelContext.insert(structure)
        try modelContext.save()
    }

    /// Delete a structure
    /// - Parameter structure: The structure to delete
    /// - Throws: SwiftData errors
    func deleteStructure(_ structure: StoryStructure) throws {
        modelContext.delete(structure)
        try modelContext.save()
    }

    /// Count total structures
    /// - Returns: Total count
    func countStructures() -> Int {
        return fetchAllStructures().count
    }

    // MARK: - StructureElement Operations

    /// Fetch all elements from a structure
    /// - Parameter structure: The parent structure
    /// - Returns: Array of elements in this structure
    func fetchElements(from structure: StoryStructure) -> [StructureElement] {
        return structure.elements ?? []
    }

    /// Fetch an element by ID
    /// - Parameter id: The persistent identifier
    /// - Returns: The element, or nil if not found
    func fetchElement(byID id: PersistentIdentifier) -> StructureElement? {
        return modelContext.model(for: id) as? StructureElement
    }

    /// Fetch an element by UUID
    /// - Parameter uuid: The element's UUID
    /// - Returns: The element, or nil if not found
    func fetchElement(byUUID uuid: UUID) -> StructureElement? {
        let fetch = FetchDescriptor<StructureElement>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch all cards assigned to a specific element
    /// - Parameter element: The structure element
    /// - Returns: Array of cards assigned to this element
    func fetchCards(assignedTo element: StructureElement) -> [Card] {
        return element.assignedCards ?? []
    }

    /// Insert a new element
    /// - Parameter element: The element to insert
    /// - Throws: SwiftData errors
    func insertElement(_ element: StructureElement) throws {
        modelContext.insert(element)
        try modelContext.save()
    }

    /// Delete an element
    /// - Parameter element: The element to delete
    /// - Throws: SwiftData errors
    func deleteElement(_ element: StructureElement) throws {
        modelContext.delete(element)
        try modelContext.save()
    }

    // MARK: - Card-Element Assignment Operations

    /// Assign a card to a structure element
    /// - Parameters:
    ///   - card: The card to assign
    ///   - element: The structure element
    /// - Throws: SwiftData errors
    func assignCard(_ card: Card, to element: StructureElement) throws {
        // Ensure arrays are initialized
        if card.structureElements == nil {
            card.structureElements = []
        }
        if element.assignedCards == nil {
            element.assignedCards = []
        }

        // Add to both sides of the many-to-many relationship
        if !(card.structureElements?.contains(where: { $0.id == element.id }) ?? false) {
            card.structureElements?.append(element)
        }
        if !(element.assignedCards?.contains(where: { $0.id == card.id }) ?? false) {
            element.assignedCards?.append(card)
        }

        try modelContext.save()
    }

    /// Unassign a card from a structure element
    /// - Parameters:
    ///   - card: The card to unassign
    ///   - element: The structure element
    /// - Throws: SwiftData errors
    func unassignCard(_ card: Card, from element: StructureElement) throws {
        // Remove from both sides of the many-to-many relationship
        card.structureElements?.removeAll(where: { $0.id == element.id })
        element.assignedCards?.removeAll(where: { $0.id == card.id })

        try modelContext.save()
    }

    /// Unassign a card from all structure elements
    /// - Parameter card: The card to unassign
    /// - Throws: SwiftData errors
    func unassignCardFromAll(_ card: Card) throws {
        let elements = card.structureElements ?? []

        for element in elements {
            element.assignedCards?.removeAll(where: { $0.id == card.id })
        }

        card.structureElements = []

        try modelContext.save()
    }

    /// Check if a card is assigned to a specific element
    /// - Parameters:
    ///   - card: The card
    ///   - element: The structure element
    /// - Returns: True if the card is assigned to this element
    func isAssigned(_ card: Card, to element: StructureElement) -> Bool {
        return card.structureElements?.contains(where: { $0.id == element.id }) ?? false
    }

    // MARK: - Save Operations

    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - Statistics

    /// Count cards assigned to an element
    /// - Parameter element: The structure element
    /// - Returns: Count of assigned cards
    func countCards(in element: StructureElement) -> Int {
        return element.assignedCards?.count ?? 0
    }

    /// Count elements in a structure
    /// - Parameter structure: The story structure
    /// - Returns: Count of elements
    func countElements(in structure: StoryStructure) -> Int {
        return structure.elements?.count ?? 0
    }

    /// Fetch unassigned cards (cards not in any structure element)
    /// - Returns: Array of cards not assigned to any element
    func fetchUnassignedCards() -> [Card] {
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate { card in
                card.structureElements?.isEmpty ?? true
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }
}
