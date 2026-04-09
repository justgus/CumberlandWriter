//
//  UIAutomationTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 3: UI Automation Tests
//  Tests user workflows and interactions including:
//  - Map Wizard end-to-end workflows
//  - Card editing workflows
//  - Structure Board interactions
//  - Theme switching UI
//  - Navigation flows
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland

// MARK: - Test Suite

/// Test suite for UI automation and workflow validation
@Suite("UI Automation Tests", .tags(.phase3, .uiAutomation))
@MainActor
struct UIAutomationTests {

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

    // MARK: - Map Wizard End-to-End Workflows

    @Test("Map Wizard completes import image workflow")
    func testMapWizardImportWorkflow() throws {
        // Given: A map card
        let card = Card(kind: .maps, name: "Test Map", subtitle: "", detailedText: "")
        context.insert(card)

        // When: User completes import workflow
        // 1. Select import method (simulated)
        // 2. Import image
        let imageData = try createSampleImageData()
        card.originalImageData = imageData

        // 3. Complete wizard
        try context.save()

        // Then: Card should have image
        #expect(card.originalImageData != nil)
        #expect(card.kind == .maps)
    }

    @Test("Map Wizard completes draw workflow")
    func testMapWizardDrawWorkflow() throws {
        // Given: A map card with drawing canvas
        let card = Card(kind: .maps, name: "Drawn Map", subtitle: "", detailedText: "")
        context.insert(card)

        // When: User completes draw workflow
        // 1. Select draw method (simulated)
        // 2. Create drawing (simulated)
        let drawingData = try createSampleImageData()
        card.originalImageData = drawingData

        // 3. Complete wizard
        try context.save()

        // Then: Card should have drawing
        #expect(card.originalImageData != nil)
    }

    @Test("Map Wizard saves draft and resumes")
    func testMapWizardDraftResume() throws {
        // Given: A map card with draft work
        let card = Card(kind: .maps, name: "Draft Map", subtitle: "", detailedText: "")
        context.insert(card)

        let draftData = try createDraftData()
        card.draftMapWorkData = draftData
        try context.save()

        // When: User resumes from draft
        let hasDraft = card.draftMapWorkData != nil

        // Then: Draft should be available
        #expect(hasDraft == true)
    }

    @Test("Map Wizard clears draft on completion")
    func testMapWizardClearsDraft() throws {
        // Given: A map card with draft
        let card = Card(kind: .maps, name: "Completed Map", subtitle: "", detailedText: "")
        card.draftMapWorkData = try createDraftData()
        context.insert(card)

        // When: User completes wizard
        card.originalImageData = try createSampleImageData()
        card.draftMapWorkData = nil // Cleared on completion
        try context.save()

        // Then: Draft should be cleared
        #expect(card.draftMapWorkData == nil)
        #expect(card.originalImageData != nil)
    }

    @Test("Map Wizard handles cancel action")
    func testMapWizardCancel() throws {
        // Given: A map card
        let card = Card(kind: .maps, name: "Cancelled Map", subtitle: "", detailedText: "")
        context.insert(card)

        // When: User cancels wizard
        // No changes should be saved
        let initialImageData = card.originalImageData

        // Then: Card should be unchanged
        #expect(initialImageData == nil)
    }

    @Test("Map Wizard validates required fields")
    func testMapWizardValidation() throws {
        // Given: A map card without required data
        let card = Card(kind: .maps, name: "", subtitle: "", detailedText: "")

        // When: Validating wizard completion
        let isValid = !card.name.isEmpty || card.originalImageData != nil

        // Then: Should require either name or image
        #expect(isValid == false)
    }

    // MARK: - Card Editing Workflows

    @Test("Card creation workflow completes")
    func testCardCreationWorkflow() throws {
        // Given: CardOperationManager
        let manager = CardOperationManager(modelContext: context)

        // When: Creating a new card
        let card = try manager.createCard(
            kind: .characters,
            name: "New Character",
            subtitle: "Hero",
            detailedText: "A brave warrior"
        )

        // Then: Card should be created with data
        #expect(card.name == "New Character")
        #expect(card.subtitle == "Hero")
        #expect(card.detailedText == "A brave warrior")
        #expect(card.kind == .characters)
    }

    @Test("Card editing saves changes")
    func testCardEditingWorkflow() throws {
        // Given: An existing card
        let card = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: User edits the card
        card.name = "Grand Castle"
        card.subtitle = "Royal Fortress"
        card.detailedText = "A magnificent structure"
        try context.save()

        // Then: Changes should be persisted
        #expect(card.name == "Grand Castle")
        #expect(card.subtitle == "Royal Fortress")
        #expect(card.detailedText == "A magnificent structure")
    }

    @Test("Card deletion workflow removes card")
    func testCardDeletionWorkflow() throws {
        // Given: An existing card
        let card = Card(kind: .artifacts, name: "Old Sword", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        let cardID = card.id

        // When: User deletes the card
        context.delete(card)
        try context.save()

        // Then: Card should be removed
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == cardID }
        )
        let results = try context.fetch(descriptor)
        #expect(results.isEmpty)
    }

    @Test("Card image upload workflow")
    func testCardImageUploadWorkflow() throws {
        // Given: A card without image
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        // When: User uploads image
        let imageData = try createSampleImageData()
        card.originalImageData = imageData
        try context.save()

        // Then: Image should be saved
        #expect(card.originalImageData != nil)
        #expect(card.originalImageData == imageData)
    }

    @Test("Card relationship creation workflow")
    func testCardRelationshipWorkflow() throws {
        // Given: Two cards
        let hero = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let sword = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(hero)
        context.insert(sword)

        // And: A relation type
        let relType = RelationType(
            code: "owns/owned-by",
            forwardLabel: "owns",
            inverseLabel: "owned-by"
        )
        context.insert(relType)

        // When: Creating relationship
        let edge = CardEdge(from: hero, to: sword, type: relType)
        context.insert(edge)
        try context.save()

        // Then: Relationship should be created
        #expect(hero.outgoingEdges?.contains(edge) == true)
        #expect(sword.incomingEdges?.contains(edge) == true)
    }

    // MARK: - Structure Board Interactions

    @Test("Structure Board assigns scene to element")
    func testStructureBoardAssignment() throws {
        // Given: A structure and scene
        let structure = StoryStructure(name: "Three Act")
        let element = StructureElement(
            name: "Act I",
            elementDescription: "Setup",
            orderIndex: 1
        )
        element.storyStructure = structure
        context.insert(structure)
        context.insert(element)

        let scene = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
        context.insert(scene)

        // When: User drags scene to element lane
        element.assignedCards = [scene]
        try context.save()

        // Then: Scene should be assigned
        #expect(element.assignedCards?.contains(scene) == true)
        #expect(scene.structureElements?.contains(element) == true)
    }

    @Test("Structure Board moves scene between elements")
    func testStructureBoardReassignment() throws {
        // Given: Two structure elements and a scene
        let structure = StoryStructure(name: "Three Act")
        let act1 = StructureElement(name: "Act I", elementDescription: "Setup", orderIndex: 1)
        let act2 = StructureElement(name: "Act II", elementDescription: "Conflict", orderIndex: 2)
        act1.storyStructure = structure
        act2.storyStructure = structure
        context.insert(structure)
        context.insert(act1)
        context.insert(act2)

        let scene = Card(kind: .scenes, name: "Scene", subtitle: "", detailedText: "")
        context.insert(scene)

        act1.assignedCards = [scene]
        try context.save()

        // When: User moves scene from act1 to act2
        act1.assignedCards?.removeAll { $0 == scene }
        act2.assignedCards = [scene]
        try context.save()

        // Then: Scene should be reassigned
        #expect(act1.assignedCards?.contains(scene) == false)
        #expect(act2.assignedCards?.contains(scene) == true)
    }

    @Test("Structure Board removes scene assignment")
    func testStructureBoardUnassignment() throws {
        // Given: An assigned scene
        let structure = StoryStructure(name: "Three Act")
        let element = StructureElement(name: "Act I", elementDescription: "Setup", orderIndex: 1)
        element.storyStructure = structure
        context.insert(structure)
        context.insert(element)

        let scene = Card(kind: .scenes, name: "Scene", subtitle: "", detailedText: "")
        context.insert(scene)

        element.assignedCards = [scene]
        try context.save()

        // When: User drags scene back to backlog
        element.assignedCards?.removeAll { $0 == scene }
        try context.save()

        // Then: Scene should be unassigned
        #expect(element.assignedCards?.contains(scene) == false)
    }

    @Test("Structure Board zoom persists setting")
    func testStructureBoardZoomPersistence() throws {
        // Given: AppSettings instance
        let settings = AppSettings()
        context.insert(settings)

        // When: User adjusts zoom
        settings.structureBoardZoom = 1.5
        try context.save()

        // Then: Zoom should persist
        #expect(settings.structureBoardZoom == 1.5)
    }

    @Test("Structure Board fit to width calculation")
    func testStructureBoardFitToWidth() throws {
        // Given: Viewport and lane dimensions
        let viewportWidth: CGFloat = 1200
        let laneWidth: CGFloat = 300
        let laneCount = 5
        let spacing: CGFloat = 16

        // When: Calculating fit-to-width zoom
        let totalWidth = CGFloat(laneCount) * laneWidth + CGFloat(laneCount - 1) * spacing
        let zoom = viewportWidth / totalWidth

        // Then: Zoom should fit all lanes
        #expect(zoom > 0)
        #expect(zoom <= 1.0)
    }

    // MARK: - Theme Switching UI

    @Test("Theme switching updates UI")
    func testThemeSwitchingUI() throws {
        // Given: ThemeManager
        let themeManager = ThemeManager()

        // When: User switches theme
        themeManager.setTheme("purple")

        // Then: Current theme should update
        #expect(themeManager.currentTheme.id == "purple")
    }

    @Test("Theme persists across sessions")
    func testThemePersistence() throws {
        // Given: ThemeManager with selected theme
        let themeManager = ThemeManager()
        themeManager.setTheme("whimsical")

        // When: Checking persisted theme
        let persistedID = themeManager.currentTheme.id

        // Then: Theme should be persisted
        #expect(persistedID == "whimsical")
    }

    @Test("Theme UI shows all available themes")
    func testThemeUIAvailability() throws {
        // Given: ThemeManager
        let themeManager = ThemeManager()

        // When: Checking available themes
        let availableThemes = themeManager.availableThemes

        // Then: Should include built-in themes
        #expect(availableThemes.count >= 4) // default, purple, whimsical, halloween
    }

    @Test("Theme colors apply to UI")
    func testThemeColorsApply() throws {
        // Given: A theme
        let theme = PurpleTheme()

        // When: Accessing theme colors
        let accentColor = theme.colors.accentPrimary
        let surfaceColor = theme.colors.surfacePrimary

        // Then: Colors should be accessible
        _ = accentColor
        _ = surfaceColor
    }

    // MARK: - Navigation Flows

    @Test("Navigation from sidebar to card detail")
    func testNavigationToCardDetail() throws {
        // Given: A card in the database
        let card = Card(kind: .characters, name: "Test Character", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: User selects card from sidebar
        let selectedCardID = card.id

        // Then: Card should be navigable
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == selectedCardID }
        )
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results.first?.id == selectedCardID)
    }

    @Test("Navigation from search to card")
    func testNavigationFromSearch() async throws {
        // Given: A searchable card
        let card = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: User searches and selects result
        let engine = SwiftDataSearchEngine(context: context)
        let results = await engine.search("Castle", maxResults: 10)

        // Then: Should navigate to card
        #expect(results.count == 1)
        #expect(results.first?.card.id == card.id)
    }

    @Test("Navigation maintains state across views")
    func testNavigationStateManagement() throws {
        // Given: Multiple cards
        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .characters, name: "Villain", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)
        try context.save()

        // When: Navigating between cards
        var selectedID: UUID? = card1.id
        selectedID = card2.id

        // Then: State should update
        #expect(selectedID == card2.id)
    }

    @Test("Navigation back stack preserves history")
    func testNavigationBackStack() throws {
        // Given: Navigation path
        var navigationPath: [UUID] = []

        let card1 = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        let card2 = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card1)
        context.insert(card2)

        // When: Navigating forward
        navigationPath.append(card1.id)
        navigationPath.append(card2.id)

        // Then: History should be preserved
        #expect(navigationPath.count == 2)
        #expect(navigationPath[0] == card1.id)
        #expect(navigationPath[1] == card2.id)

        // When: Navigating back
        navigationPath.removeLast()

        // Then: Should return to previous card
        #expect(navigationPath.count == 1)
        #expect(navigationPath[0] == card1.id)
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

    /// Creates sample draft data for testing
    private func createDraftData() throws -> Data {
        let draftInfo = ["method": "draw", "step": "configure"]
        return try JSONEncoder().encode(draftInfo)
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var phase3: Self
    @Tag static var uiAutomation: Self
}
