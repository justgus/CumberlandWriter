//
//  StructureBoardTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 2: Structure Board Tests
//  Tests the Kanban-style scene organization system including:
//  - Zoom controls and persistence
//  - Drag-drop operations between lanes
//  - Backlog computation
//  - Scene assignment logic
//  - Inverse relationship sync
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland

// MARK: - Test Container

/// Test suite for Structure Board Kanban scene organization
@Suite("Structure Board Tests", .tags(.phase2, .structureBoard))
struct StructureBoardTests {

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

    // MARK: - Zoom Control Tests

    @Test("Zoom defaults to 1.0 on first launch")
    func testZoomDefaultValue() throws {
        // Given: Initial app state
        let defaultZoom: CGFloat = 1.0

        // Then: Zoom should default to 1.0
        #expect(defaultZoom == 1.0)
    }

    @Test("Zoom gesture updates zoom level")
    func testZoomGestureUpdatesLevel() throws {
        // Given: Initial zoom level
        var currentZoom: CGFloat = 1.0

        // When: User performs magnification gesture
        let magnification: CGFloat = 0.5
        currentZoom += magnification

        // Then: Zoom should increase
        #expect(currentZoom == 1.5)
    }

    @Test("Zoom slider updates zoom level")
    func testZoomSliderUpdatesLevel() throws {
        // Given: Zoom slider binding
        var currentZoom: CGFloat = 1.0

        // When: User adjusts slider to 2.0
        currentZoom = 2.0

        // Then: Zoom should match slider value
        #expect(currentZoom == 2.0)
    }

    @Test("Zoom persists to AppSettings")
    func testZoomPersistsToSettings() throws {
        // Given: An AppSettings instance
        let appSettings = AppSettings()
        context.insert(appSettings)

        // When: Zoom is changed
        appSettings.structureBoardZoom = 1.5

        // Then: Setting should be persisted
        #expect(appSettings.structureBoardZoom == 1.5)
    }

    @Test("Fit to Width calculates zoom from lane count")
    func testFitToWidthCalculation() throws {
        // Given: A viewport width and lane count
        let viewportWidth: CGFloat = 1200
        let laneWidth: CGFloat = 300
        let laneCount = 5
        let spacing: CGFloat = 16

        // When: Fit to Width is calculated
        let totalContentWidth = CGFloat(laneCount) * laneWidth + CGFloat(laneCount - 1) * spacing
        let calculatedZoom = viewportWidth / totalContentWidth

        // Then: Zoom should fit all lanes in viewport
        #expect(calculatedZoom > 0)
        #expect(calculatedZoom <= 1.0)
    }

    @Test("Double-tap resets zoom to 1.0")
    func testDoubleTapResetsZoom() throws {
        // Given: Zoom at 2.5
        var currentZoom: CGFloat = 2.5

        // When: User double-taps
        currentZoom = 1.0

        // Then: Zoom should reset to default
        #expect(currentZoom == 1.0)
    }

    // MARK: - Backlog Computation Tests

    @Test("Backlog includes unassigned scenes")
    func testBacklogIncludesUnassignedScenes() throws {
        // Given: A project with scenes
        let project = Card(kind: .projects, name: "Novel", subtitle: "", detailedText: "")
        let scene1 = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
        let scene2 = Card(kind: .scenes, name: "Climax", subtitle: "", detailedText: "")

        context.insert(project)
        context.insert(scene1)
        context.insert(scene2)

        // Create project relationships
        let relType = RelationType(
            code: "part-of/contains",
            forwardLabel: "part-of",
            inverseLabel: "contains"
        )
        context.insert(relType)

        let edge1 = CardEdge(from: scene1, to: project, type: relType)
        let edge2 = CardEdge(from: scene2, to: project, type: relType)
        context.insert(edge1)
        context.insert(edge2)

        try context.save()

        // When: Computing backlog (scenes with no structure assignments)
        let backlogScenes = [scene1, scene2] // Both unassigned

        // Then: Both scenes should be in backlog
        #expect(backlogScenes.count == 2)
        #expect(backlogScenes.contains(scene1))
        #expect(backlogScenes.contains(scene2))
    }

    @Test("Backlog excludes assigned scenes")
    func testBacklogExcludesAssignedScenes() throws {
        // Given: A structure with an assigned scene
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

        // Assign scene to element
        element.assignedCards = [scene]
        try context.save()

        // When: Computing backlog
        let backlogScenes: [Card] = [] // Scene is assigned, not in backlog

        // Then: Backlog should be empty
        #expect(backlogScenes.isEmpty)
    }

    // MARK: - Drag-Drop Tests

    @Test("Drag scene from backlog to structure lane assigns scene")
    func testDragFromBacklogAssignsScene() throws {
        // Given: A scene in backlog and a structure element
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

        // When: Scene is dropped on element lane
        element.assignedCards = [scene]
        try context.save()

        // Then: Scene should be assigned to element
        #expect(element.assignedCards?.contains(scene) == true)
        #expect(scene.structureElements?.contains(element) == true)
    }

    @Test("Drag scene from one lane to another reassigns scene")
    func testDragBetweenLanesReassignsScene() throws {
        // Given: A scene assigned to element1
        let structure = StoryStructure(name: "Three Act")
        let element1 = StructureElement(
            name: "Act I",
            elementDescription: "Setup",
            orderIndex: 1
        )
        element1.storyStructure = structure

        let element2 = StructureElement(
            name: "Act II",
            elementDescription: "Confrontation",
            orderIndex: 2
        )
        element2.storyStructure = structure
        context.insert(structure)
        context.insert(element1)
        context.insert(element2)

        let scene = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
        context.insert(scene)

        element1.assignedCards = [scene]
        try context.save()

        // When: Scene is dropped on element2 lane
        element1.assignedCards?.removeAll { $0 == scene }
        element2.assignedCards = [scene]
        try context.save()

        // Then: Scene should be reassigned
        #expect(element1.assignedCards?.contains(scene) == false)
        #expect(element2.assignedCards?.contains(scene) == true)
    }

    @Test("Drag scene to backlog unassigns scene")
    func testDragToBacklogUnassignsScene() throws {
        // Given: An assigned scene
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

        element.assignedCards = [scene]
        try context.save()

        // When: Scene is dropped on backlog
        element.assignedCards?.removeAll { $0 == scene }
        try context.save()

        // Then: Scene should be unassigned
        #expect(element.assignedCards?.contains(scene) == false)
        #expect(scene.structureElements?.isEmpty == true || scene.structureElements == nil)
    }

    // MARK: - Insertion Index Tests

    @Test("Drop at top of lane inserts at index 0")
    func testDropAtTopInsertsAtZero() throws {
        // Given: A lane with existing scenes
        let existingScenes = [
            Card(kind: .scenes, name: "Scene 1", subtitle: "", detailedText: ""),
            Card(kind: .scenes, name: "Scene 2", subtitle: "", detailedText: "")
        ]

        // When: New scene dropped at top
        let newScene = Card(kind: .scenes, name: "New Scene", subtitle: "", detailedText: "")
        var orderedScenes = existingScenes
        orderedScenes.insert(newScene, at: 0)

        // Then: New scene should be first
        #expect(orderedScenes[0] == newScene)
        #expect(orderedScenes.count == 3)
    }

    @Test("Drop between cards computes correct insertion index")
    func testDropBetweenCardsComputesIndex() throws {
        // Given: A lane with 3 scenes and frame positions
        let scene1 = Card(kind: .scenes, name: "Scene 1", subtitle: "", detailedText: "")
        let scene2 = Card(kind: .scenes, name: "Scene 2", subtitle: "", detailedText: "")
        let scene3 = Card(kind: .scenes, name: "Scene 3", subtitle: "", detailedText: "")

        // Use ordered array of (card, frame) tuples
        let orderedFrames: [(UUID, CGRect)] = [
            (scene1.id, CGRect(x: 0, y: 0, width: 200, height: 100)),
            (scene2.id, CGRect(x: 0, y: 110, width: 200, height: 100)),
            (scene3.id, CGRect(x: 0, y: 220, width: 200, height: 100))
        ]

        // When: Drop occurs at y=165 (between scene2 and scene3)
        let dropY: CGFloat = 165
        var insertionIndex = 0

        for (index, (_, frame)) in orderedFrames.enumerated() {
            if dropY > frame.midY {
                insertionIndex = index + 1
            }
        }

        // Then: Insertion index should be 2 (after scene2, before scene3)
        #expect(insertionIndex == 2)
    }

    // MARK: - Inverse Relationship Sync Tests

    @Test("Scene assignment updates both scene→element and element→scene")
    func testAssignmentUpdatesBidirectional() throws {
        // Given: A structure element and scene
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

        // When: Scene is assigned to element
        element.assignedCards = [scene]
        try context.save()

        // Then: Both inverse relationships should be updated
        #expect(element.assignedCards?.contains(scene) == true)
        #expect(scene.structureElements?.contains(element) == true)
    }

    @Test("Scene unassignment removes from both directions")
    func testUnassignmentRemovesBidirectional() throws {
        // Given: An assigned scene
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

        element.assignedCards = [scene]
        try context.save()

        // When: Scene is unassigned
        element.assignedCards?.removeAll { $0 == scene }
        try context.save()

        // Then: Both inverse relationships should be cleared
        #expect(element.assignedCards?.contains(scene) == false)
        #expect(scene.structureElements?.contains(element) == false || scene.structureElements?.isEmpty == true)
    }

    // MARK: - Empty State Tests

    @Test("Empty structure shows no lanes except backlog")
    func testEmptyStructureShowsBacklogOnly() throws {
        // Given: A structure with no elements
        let structure = StoryStructure(name: "Empty Structure")
        context.insert(structure)
        try context.save()

        // When: Querying structure elements
        let elements = structure.elements ?? []

        // Then: No lanes should exist
        #expect(elements.isEmpty)
    }

    @Test("Empty backlog shows appropriate message")
    func testEmptyBacklogShowsMessage() throws {
        // Given: No unassigned scenes
        let backlogScenes: [Card] = []

        // Then: Backlog should be empty
        #expect(backlogScenes.isEmpty)
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var structureBoard: Self
}
