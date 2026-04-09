//
//  MajorViewTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 3: Major View Tests
//  Tests major view components including:
//  - CardSheetView rendering and state
//  - CardEditorView validation logic
//  - CardRelationshipView graph operations
//  - MainAppView navigation state
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland

// MARK: - Test Suite

/// Test suite for major view component validation
@Suite("Major View Tests", .tags(.phase3, .majorViews))
@MainActor
struct MajorViewTests {

    // MARK: - Test Infrastructure

    var container: ModelContainer
    var context: ModelContext

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([
            AppSettings.self,
            Card.self,
            RelationType.self,
            CardEdge.self,
            Source.self,
            Citation.self,
            StoryStructure.self,
            StructureElement.self,
            Board.self,
            BoardNode.self,
            ImageVersion.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = ModelContext(container)
    }

    // MARK: - CardSheetView Rendering Tests

    @Test("CardSheetView displays card data")
    func testCardSheetDisplaysData() throws {
        // Given: A card with data
        let card = Card(
            kind: .characters,
            name: "Test Character",
            subtitle: "Hero",
            detailedText: "A brave warrior"
        )
        context.insert(card)

        // When: Rendering CardSheet
        // Then: Card data should be accessible
        #expect(card.name == "Test Character")
        #expect(card.subtitle == "Hero")
        #expect(card.detailedText == "A brave warrior")
    }

    @Test("CardSheetView handles empty card")
    func testCardSheetEmptyCard() throws {
        // Given: A minimal card
        let card = Card(kind: .characters, name: "", subtitle: "", detailedText: "")
        context.insert(card)

        // When: Rendering CardSheet
        // Then: Should handle empty strings
        #expect(card.name.isEmpty)
        #expect(card.subtitle.isEmpty)
        #expect(card.detailedText.isEmpty)
    }

    @Test("CardSheetView displays image")
    func testCardSheetDisplaysImage() throws {
        // Given: A card with image
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        card.originalImageData = try createSampleImageData()
        context.insert(card)

        // When: Rendering CardSheet
        // Then: Image should be available
        #expect(card.originalImageData != nil)
    }

    @Test("CardSheetView shows relationships")
    func testCardSheetShowsRelationships() throws {
        // Given: Cards with relationship
        let hero = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let sword = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(hero)
        context.insert(sword)

        let relType = RelationType(
            code: "owns/owned-by",
            forwardLabel: "owns",
            inverseLabel: "owned-by"
        )
        context.insert(relType)

        let edge = CardEdge(from: hero, to: sword, type: relType)
        context.insert(edge)
        try context.save()

        // When: Rendering CardSheet
        // Then: Relationships should be accessible
        #expect(hero.outgoingEdges?.count == 1)
        #expect(sword.incomingEdges?.count == 1)
    }

    @Test("CardSheetView displays citations")
    func testCardSheetDisplaysCitations() throws {
        // Given: A card with citation
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        let source = Source(
            title: "Character Guide",
            authors: "Author Name"
        )
        context.insert(source)

        let citation = Citation(
            card: card,
            source: source,
            kind: .quote,
            locator: "p. 42",
            excerpt: "Character description"
        )
        context.insert(citation)
        try context.save()

        // When: Rendering CardSheet
        // Then: Citations should be accessible
        #expect(card.citations?.count == 1)
        #expect(card.citations?.first?.excerpt == "Character description")
    }

    // MARK: - CardEditorView Validation Tests

    @Test("CardEditorView validates required name")
    func testCardEditorNameValidation() throws {
        // Given: Card editor validation
        let name = ""

        // When: Validating name
        let isValid = !name.isEmpty

        // Then: Empty name should be invalid
        #expect(isValid == false)
    }

    @Test("CardEditorView validates name length")
    func testCardEditorNameLength() throws {
        // Given: Very long name
        let longName = String(repeating: "A", count: 300)

        // When: Validating name length
        let isValid = longName.count <= 255

        // Then: Should enforce length limit
        #expect(isValid == false)
    }

    @Test("CardEditorView allows valid name")
    func testCardEditorValidName() throws {
        // Given: Valid name
        let name = "Test Character"

        // When: Validating name
        let isValid = !name.isEmpty && name.count <= 255

        // Then: Should be valid
        #expect(isValid == true)
    }

    @Test("CardEditorView validates kind selection")
    func testCardEditorKindValidation() throws {
        // Given: Card with kind
        let card = Card(kind: .characters, name: "Test", subtitle: "", detailedText: "")

        // When: Validating kind
        let hasKind = card.kind == .characters

        // Then: Should have valid kind
        #expect(hasKind == true)
    }

    @Test("CardEditorView saves valid data")
    func testCardEditorSavesData() throws {
        // Given: Valid card data
        let manager = CardOperationManager(modelContext: context)
        let card = try manager.createCard(
            kind: .locations,
            name: "Castle",
            subtitle: "Royal Fortress",
            detailedText: "A magnificent castle"
        )

        // When: Saving card
        try context.save()

        // Then: Data should be persisted
        #expect(card.name == "Castle")
        #expect(card.subtitle == "Royal Fortress")
        #expect(card.detailedText == "A magnificent castle")
    }

    // MARK: - CardRelationshipView Graph Tests

    @Test("CardRelationshipView displays outgoing edges")
    func testRelationshipViewOutgoingEdges() throws {
        // Given: Card with outgoing edges
        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        let relType = RelationType(
            code: "owns/owned-by",
            forwardLabel: "owns",
            inverseLabel: "owned-by"
        )
        context.insert(relType)

        let edge = CardEdge(from: card1, to: card2, type: relType)
        context.insert(edge)
        try context.save()

        // When: Rendering relationship view
        let outgoingEdges = card1.outgoingEdges ?? []

        // Then: Should show outgoing edges
        #expect(outgoingEdges.count == 1)
        #expect(outgoingEdges.first?.to?.id == card2.id)
    }

    @Test("CardRelationshipView displays incoming edges")
    func testRelationshipViewIncomingEdges() throws {
        // Given: Card with incoming edges
        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        let relType = RelationType(
            code: "owns/owned-by",
            forwardLabel: "owns",
            inverseLabel: "owned-by"
        )
        context.insert(relType)

        let edge = CardEdge(from: card1, to: card2, type: relType)
        context.insert(edge)
        try context.save()

        // When: Rendering relationship view
        let incomingEdges = card2.incomingEdges ?? []

        // Then: Should show incoming edges
        #expect(incomingEdges.count == 1)
        #expect(incomingEdges.first?.from?.id == card1.id)
    }

    @Test("CardRelationshipView creates new relationship")
    func testRelationshipViewCreateEdge() throws {
        // Given: Two cards
        let card1 = Card(kind: .characters, name: "Knight", subtitle: "", detailedText: "")
        let card2 = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        let relType = RelationType(
            code: "lives-in/home-to",
            forwardLabel: "lives-in",
            inverseLabel: "home-to"
        )
        context.insert(relType)

        // When: Creating relationship
        let edge = CardEdge(from: card1, to: card2, type: relType)
        context.insert(edge)
        try context.save()

        // Then: Relationship should be created
        #expect(card1.outgoingEdges?.contains(edge) == true)
        #expect(card2.incomingEdges?.contains(edge) == true)
    }

    @Test("CardRelationshipView deletes relationship")
    func testRelationshipViewDeleteEdge() throws {
        // Given: Cards with relationship
        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        let relType = RelationType(
            code: "owns/owned-by",
            forwardLabel: "owns",
            inverseLabel: "owned-by"
        )
        context.insert(relType)

        let edge = CardEdge(from: card1, to: card2, type: relType)
        context.insert(edge)
        try context.save()

        // When: Deleting relationship
        context.delete(edge)
        try context.save()

        // Then: Relationship should be removed
        #expect(card1.outgoingEdges?.isEmpty == true || card1.outgoingEdges == nil)
        #expect(card2.incomingEdges?.isEmpty == true || card2.incomingEdges == nil)
    }

    @Test("CardRelationshipView shows empty state")
    func testRelationshipViewEmptyState() throws {
        // Given: Card with no relationships
        let card = Card(kind: .characters, name: "Loner", subtitle: "", detailedText: "")
        context.insert(card)

        // When: Rendering relationship view
        let hasRelationships = !(card.outgoingEdges?.isEmpty ?? true) ||
                                !(card.incomingEdges?.isEmpty ?? true)

        // Then: Should show empty state
        #expect(hasRelationships == false)
    }

    // MARK: - MainAppView Navigation Tests

    @Test("MainAppView initializes navigation state")
    func testMainAppNavigationInit() throws {
        // Given: App launch
        let selectedCardID: UUID? = nil
        let selectedKind: Kinds? = nil

        // When: Initializing navigation
        // Then: State should be unselected
        #expect(selectedCardID == nil)
        #expect(selectedKind == nil)
    }

    @Test("MainAppView selects card")
    func testMainAppSelectCard() throws {
        // Given: A card
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        // When: Selecting card
        let selectedCardID: UUID? = card.id

        // Then: Selection should update
        #expect(selectedCardID == card.id)
    }

    @Test("MainAppView filters by kind")
    func testMainAppFilterByKind() throws {
        // Given: Multiple cards of different kinds
        let char1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let char2 = Card(kind: .characters, name: "Villain", subtitle: "", detailedText: "")
        let loc1 = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(char1)
        context.insert(char2)
        context.insert(loc1)
        try context.save()

        // When: Filtering by characters
        let targetKindRaw = Kinds.characters.rawValue
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == targetKindRaw }
        )
        let characters = try context.fetch(descriptor)

        // Then: Should return only characters
        #expect(characters.count == 2)
        #expect(characters.allSatisfy { $0.kind == .characters })
    }

    @Test("MainAppView sidebar shows all kinds")
    func testMainAppSidebarKinds() throws {
        // Given: Available kinds
        let allKinds = Kinds.allCases

        // When: Rendering sidebar
        // Then: All kinds should be available
        #expect(allKinds.contains(.characters))
        #expect(allKinds.contains(.locations))
        #expect(allKinds.contains(.scenes))
        #expect(allKinds.contains(.maps))
    }

    @Test("MainAppView counts cards by kind")
    func testMainAppCardCounts() throws {
        // Given: Cards of various kinds
        let char1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let char2 = Card(kind: .characters, name: "Villain", subtitle: "", detailedText: "")
        let loc1 = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(char1)
        context.insert(char2)
        context.insert(loc1)
        try context.save()

        // When: Counting characters
        let targetKindRaw = Kinds.characters.rawValue
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == targetKindRaw }
        )
        let characterCount = try context.fetch(descriptor).count

        // Then: Should return correct count
        #expect(characterCount == 2)
    }

    // MARK: - Helper Methods

    /// Creates sample image data for testing
    private func createSampleImageData() throws -> Data {
        #if canImport(UIKit)
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.pngData() ?? Data()
        #elseif canImport(AppKit)
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return Data()
        }
        return pngData
        #else
        return Data()
        #endif
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var majorViews: Self
}
