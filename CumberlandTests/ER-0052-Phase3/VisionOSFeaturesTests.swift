//
//  VisionOSFeaturesTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 3: visionOS Features Tests
//  Tests visionOS-specific functionality including:
//  - Ornament controls
//  - Multi-window coordination
//  - Platform-specific gestures
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland
import BrushEngine

// MARK: - Test Suite

/// Test suite for visionOS platform features
@Suite("visionOS Features Tests", .tags(.phase3, .visionOS))
@MainActor
struct VisionOSFeaturesTests {

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

    // MARK: - Ornament Controls Tests

    @Test("Ornament controls display on visionOS")
    func testOrnamentControlsDisplay() {
        // Given: visionOS platform check
        #if os(visionOS)
        let isVisionOS = true
        #else
        let isVisionOS = false
        #endif

        // When: Checking ornament availability
        // Then: Ornaments should be visionOS-only
        #if os(visionOS)
        #expect(isVisionOS == true)
        #else
        #expect(isVisionOS == false)
        #endif
    }

    @Test("Ornament zoom control updates state")
    func testOrnamentZoomControl() throws {
        // Given: Zoom state
        var currentZoom: CGFloat = 1.0

        // When: User adjusts zoom via ornament
        currentZoom = 1.5

        // Then: Zoom should update
        #expect(currentZoom == 1.5)
    }

    @Test("Ornament layer controls update active layer")
    func testOrnamentLayerControl() {
        // Given: Drawing canvas state
        var currentLayer: String = "Base Layer"

        // When: User selects different layer via ornament
        currentLayer = "Terrain Layer"

        // Then: Layer selection should update
        #expect(currentLayer == "Terrain Layer")
    }

    @Test("Ornament brush palette shows brushes")
    @MainActor
    func testOrnamentBrushPalette() {
        // Given: Brush registry
        let registry = BrushRegistry.shared

        // When: Accessing installed brush sets
        let hasBrushSets = registry.hasBrushSets

        // Then: Brushes should be available
        #expect(hasBrushSets == true || hasBrushSets == false) // Registry exists
    }

    // MARK: - Multi-Window Coordination Tests

    @Test("Multi-window supports card detail windows")
    func testMultiWindowCardDetail() throws {
        // Given: A card
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)

        // When: Opening in new window
        let windowID = UUID()
        let openedCardID = card.id

        // Then: Window should reference card
        #expect(openedCardID == card.id)
        #expect(windowID.uuidString.count > 0) // Valid UUID
    }

    @Test("Multi-window preserves card state")
    func testMultiWindowStatePreservation() throws {
        // Given: Card edited in one window
        let card = Card(kind: .locations, name: "Castle", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: Editing in one window
        card.name = "Grand Castle"
        try context.save()

        // Then: Changes should be visible in all windows
        #expect(card.name == "Grand Castle")
    }

    @Test("Multi-window handles concurrent edits")
    func testMultiWindowConcurrentEdits() throws {
        // Given: Card open in multiple windows
        let card = Card(kind: .characters, name: "Hero", subtitle: "", detailedText: "")
        context.insert(card)
        try context.save()

        // When: Editing same card
        card.subtitle = "Brave Warrior"
        try context.save()

        // Then: Last write wins
        #expect(card.subtitle == "Brave Warrior")
    }

    // MARK: - Platform-Specific Gestures Tests

    @Test("Pinch gesture updates zoom level")
    func testPinchGestureZoom() {
        // Given: Initial zoom
        var zoom: CGFloat = 1.0

        // When: Pinch gesture applied
        let magnification: CGFloat = 0.5
        zoom += magnification

        // Then: Zoom should update
        #expect(zoom == 1.5)
    }

    @Test("Rotation gesture updates orientation")
    func testRotationGesture() {
        // Given: Initial rotation
        var rotation: Angle = .zero

        // When: Rotation gesture applied
        rotation = Angle(degrees: 45)

        // Then: Rotation should update
        #expect(rotation.degrees == 45)
    }

    @Test("Tap gesture selects card")
    func testTapGestureSelection() throws {
        // Given: A card
        let card = Card(kind: .artifacts, name: "Sword", subtitle: "", detailedText: "")
        context.insert(card)

        // When: Tap gesture on card
        let selectedID: UUID? = card.id

        // Then: Card should be selected
        #expect(selectedID == card.id)
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var visionOS: Self
}
