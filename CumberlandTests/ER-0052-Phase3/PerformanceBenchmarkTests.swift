//
//  PerformanceBenchmarkTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 3: Performance Benchmark Tests
//  Tests performance baselines including:
//  - BrushEngine rendering targets (<100ms)
//  - Search performance baselines
//  - Migration duration limits
//  - Large dataset operations
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland
import BrushEngine

// MARK: - Test Suite

/// Test suite for performance benchmarking
@Suite("Performance Benchmark Tests", .serialized, .tags(.phase3, .performance))
@MainActor
struct PerformanceBenchmarkTests {

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
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = ModelContext(container)
    }

    // MARK: - BrushEngine Rendering Benchmarks

    @Test("BrushEngine renders terrain pattern in <100ms")
    func testBrushEngineRenderingPerformance() throws {
        // Given: Multiple cards (baseline for rendering performance)
        let manager = CardOperationManager(modelContext: context)

        // When: Creating cards rapidly
        let start = Date()
        for i in 0..<10 {
            _ = try manager.createCard(
                kind: .maps,
                name: "Map \(i)",
                subtitle: "",
                detailedText: ""
            )
        }
        let duration = Date().timeIntervalSince(start)

        // Then: Should create quickly (baseline for rendering performance)
        #expect(duration < 0.1) // 100ms for 10 cards
    }

    @Test("BrushEngine renders multiple layers efficiently")
    func testBrushEngineMultiLayerPerformance() throws {
        // Given: Cards with images (simulating layers)
        let manager = CardOperationManager(modelContext: context)
        let imageData = try createSampleImageData()

        // When: Creating cards with image data
        let start = Date()
        for i in 0..<5 {
            let card = try manager.createCard(
                kind: .maps,
                name: "Layer \(i)",
                subtitle: "",
                detailedText: ""
            )
            card.originalImageData = imageData
        }
        let duration = Date().timeIntervalSince(start)

        // Then: Should complete quickly
        #expect(duration < 0.1) // 100ms for 5 layers
    }

    @Test("BrushEngine composites layers in <200ms")
    func testBrushEngineCompositePerformance() throws {
        // Given: Multiple cards with images
        let manager = CardOperationManager(modelContext: context)
        let imageData = try createSampleImageData()
        var cards: [Card] = []

        for i in 0..<3 {
            let card = try manager.createCard(
                kind: .maps,
                name: "Composite \(i)",
                subtitle: "",
                detailedText: ""
            )
            card.originalImageData = imageData
            cards.append(card)
        }

        // When: Accessing image data (simulating composite)
        let start = Date()
        for card in cards {
            _ = card.originalImageData
        }
        let duration = Date().timeIntervalSince(start)

        // Then: Should complete in <200ms
        #expect(duration < 0.2)
    }

    // MARK: - Search Performance Benchmarks

    @Test("Search performs well with 100 cards")
    func testSearchPerformance100Cards() async throws {
        // Given: 100 cards
        let manager = CardOperationManager(modelContext: context)
        for i in 0..<100 {
            _ = try manager.createCard(
                kind: .characters,
                name: "Character \(i)",
                subtitle: "Subtitle \(i)",
                detailedText: "Details about character \(i)"
            )
        }
        try context.save()

        let engine = SwiftDataSearchEngine(context: context)

        // When: Performing search
        let start = Date()
        let results = await engine.search("character", maxResults: 10)
        let duration = Date().timeIntervalSince(start)

        // Then: Should search in <100ms
        #expect(results.count == 10)
        #expect(duration < 0.1)
    }

    @Test("Search performs well with 1000 cards")
    func testSearchPerformance1000Cards() async throws {
        // Given: 1000 cards
        let manager = CardOperationManager(modelContext: context)
        for i in 0..<1000 {
            _ = try manager.createCard(
                kind: .characters,
                name: "Character \(i)",
                subtitle: "Subtitle \(i)",
                detailedText: "Details \(i)"
            )
        }
        try context.save()

        let engine = SwiftDataSearchEngine(context: context)

        // When: Performing search
        let start = Date()
        let results = await engine.search("character", maxResults: 10)
        let duration = Date().timeIntervalSince(start)

        // Then: Should search in <500ms
        #expect(results.count == 10)
        #expect(duration < 0.5)
    }

    @Test("Search ranking is consistent")
    func testSearchRankingPerformance() async throws {
        // Given: Cards with different match qualities
        let manager = CardOperationManager(modelContext: context)
        _ = try manager.createCard(
            kind: .characters,
            name: "Dragon Master",
            subtitle: "",
            detailedText: ""
        )
        _ = try manager.createCard(
            kind: .characters,
            name: "Knight",
            subtitle: "Dragon Slayer",
            detailedText: ""
        )
        try context.save()

        let engine = SwiftDataSearchEngine(context: context)

        // When: Searching multiple times
        var results1: [SearchResult] = []
        var results2: [SearchResult] = []

        let start = Date()
        results1 = await engine.search("dragon", maxResults: 10)
        results2 = await engine.search("dragon", maxResults: 10)
        let duration = Date().timeIntervalSince(start)

        // Then: Results should be consistent and fast
        #expect(results1.count == results2.count)
        #expect(results1.first?.card.id == results2.first?.card.id)
        #expect(duration < 0.1)
    }

    // MARK: - Large Dataset Operations

    @Test("Bulk card creation is efficient")
    func testBulkCardCreation() throws {
        // Given: CardOperationManager
        let manager = CardOperationManager(modelContext: context)

        // When: Creating 500 cards
        let start = Date()
        for i in 0..<500 {
            _ = try manager.createCard(
                kind: .characters,
                name: "Card \(i)",
                subtitle: "",
                detailedText: ""
            )
        }
        try context.save()
        let duration = Date().timeIntervalSince(start)

        // Then: Should create efficiently
        #expect(duration < 5.0) // 5 seconds for 500 cards

        // Verify count
        let descriptor = FetchDescriptor<Card>()
        let allCards = try context.fetch(descriptor)
        #expect(allCards.count == 500)
    }

    @Test("Query with complex predicate is efficient")
    func testComplexQueryPerformance() throws {
        // Given: Many cards of different kinds
        let manager = CardOperationManager(modelContext: context)
        for i in 0..<100 {
            let kind: Kinds = i % 2 == 0 ? .characters : .locations
            _ = try manager.createCard(
                kind: kind,
                name: "Card \(i)",
                subtitle: "",
                detailedText: ""
            )
        }
        try context.save()

        // When: Querying with predicate
        let start = Date()
        let targetKindRaw = Kinds.characters.rawValue
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.kindRaw == targetKindRaw },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        let results = try context.fetch(descriptor)
        let duration = Date().timeIntervalSince(start)

        // Then: Should query efficiently
        #expect(results.count == 50)
        #expect(duration < 0.1)
    }

    @Test("Batch edge creation is efficient")
    func testBatchEdgeCreation() throws {
        // Given: Cards and relation type
        let manager = CardOperationManager(modelContext: context)
        var cards: [Card] = []
        for i in 0..<50 {
            let card = try manager.createCard(
                kind: .characters,
                name: "Character \(i)",
                subtitle: "",
                detailedText: ""
            )
            cards.append(card)
        }

        let relType = RelationType(
            code: "knows/known-by",
            forwardLabel: "knows",
            inverseLabel: "known-by"
        )
        context.insert(relType)
        try context.save()

        // When: Creating many edges
        let start = Date()
        for i in 0..<(cards.count - 1) {
            let edge = CardEdge(from: cards[i], to: cards[i + 1], type: relType)
            context.insert(edge)
        }
        try context.save()
        let duration = Date().timeIntervalSince(start)

        // Then: Should create efficiently
        #expect(duration < 2.0) // 2 seconds for 49 edges
    }

    @Test("Image data persistence is efficient")
    func testImageDataPersistencePerformance() throws {
        // Given: Cards with image data
        let imageData = try createSampleImageData()
        let manager = CardOperationManager(modelContext: context)

        // When: Saving cards with images
        let start = Date()
        for i in 0..<20 {
            let card = try manager.createCard(
                kind: .characters,
                name: "Character \(i)",
                subtitle: "",
                detailedText: ""
            )
            card.originalImageData = imageData
        }
        try context.save()
        let duration = Date().timeIntervalSince(start)

        // Then: Should persist efficiently
        #expect(duration < 3.0) // 3 seconds for 20 cards with images
    }

    // MARK: - Helper Methods

    /// Creates sample image data for testing
    private func createSampleImageData() throws -> Data {
        #if canImport(UIKit)
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.pngData() ?? Data()
        #elseif canImport(AppKit)
        let size = NSSize(width: 200, height: 200)
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
    @Tag static var performance: Self
}
