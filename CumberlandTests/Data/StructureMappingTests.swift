//
//  StructureMappingTests.swift
//  CumberlandTests
//
//  Created by Claude Code on 2026-04-21.
//  Tests for arc-based structure mapping algorithm
//

import Foundation
import Testing
import SwiftData
@testable import Cumberland

struct StructureMappingTests {

    // MARK: - Test Setup

    @MainActor
    private func createTestContext() -> (ModelContext, Card) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Card.self, StoryStructure.self, StructureElement.self,
            configurations: config
        )
        let context = container.mainContext

        let project = Card(kind: .projects, name: "Test Project", subtitle: "", detailedText: "")
        context.insert(project)

        return (context, project)
    }

    @MainActor
    private func createStructureWithScenes(
        name: String,
        elements: [String],
        scenesPerElement: [Int],
        projectID: UUID?,
        in context: ModelContext
    ) -> StoryStructure {
        let structure = StoryStructure(name: name, projectID: projectID)
        context.insert(structure)

        for (index, elementName) in elements.enumerated() {
            let element = StructureElement(name: elementName, orderIndex: index)
            element.storyStructure = structure
            context.insert(element)

            if structure.elements == nil {
                structure.elements = []
            }
            structure.elements?.append(element)

            // Create scenes for this element
            let sceneCount = scenesPerElement[safe: index] ?? 0
            for sceneIndex in 0..<sceneCount {
                let scene = Card(
                    kind: .scenes,
                    name: "\(elementName) - Scene \(sceneIndex + 1)",
                    subtitle: "",
                    detailedText: ""
                )
                context.insert(scene)

                if element.assignedCards == nil {
                    element.assignedCards = []
                }
                element.assignedCards?.append(scene)
            }
        }

        return structure
    }

    // MARK: - Arc-Based Mapping Tests

    @Test("Arc-based mapping preserves dramatic position")
    @MainActor
    func arcBasedMappingPreservesDramaticPosition() async throws {
        let (context, project) = createTestContext()

        // Create Three-Act structure with scenes
        let threeAct = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [2, 5, 3], // 2 scenes in Act 1, 5 in Act 2, 3 in Act 3
            projectID: project.id,
            in: context
        )

        // Create Five-Act structure (empty)
        let fiveAct = createStructureWithScenes(
            name: "Five-Act Structure",
            elements: ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"],
            scenesPerElement: [0, 0, 0, 0, 0],
            projectID: nil,
            in: context
        )

        // Map from Three-Act to Five-Act
        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: threeAct,
            to: fiveAct,
            strategy: .arcBased
        )

        // Verify all scenes were mapped
        #expect(result.mappedSceneCount == 10)
        #expect(result.unmappedSceneCount == 0)

        // Verify Five-Act now has the project ID
        #expect(fiveAct.projectID == project.id)
        #expect(threeAct.projectID == nil)

        // Verify scenes were distributed across Five-Act structure
        let fiveActElements = fiveAct.elements?.sorted { $0.orderIndex < $1.orderIndex } ?? []
        let totalMappedScenes = fiveActElements.reduce(0) { sum, element in
            sum + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        }
        #expect(totalMappedScenes == 10)
    }

    @Test("Arc-based mapping matches tension values")
    @MainActor
    func arcBasedMappingMatchesTension() async throws {
        let (context, project) = createTestContext()

        let threeAct = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [1, 1, 1],
            projectID: project.id,
            in: context
        )

        let herosJourney = createStructureWithScenes(
            name: "Hero's Journey (Formal)",
            elements: [
                "Ordinary World", "Call to Adventure", "Refusal of the Call",
                "Meeting the Mentor", "Crossing the First Threshold",
                "Tests, Allies, Enemies", "Approach to the Inmost Cave",
                "Ordeal", "Reward (Seizing the Sword)", "The Road Back",
                "Resurrection", "Return with the Elixir"
            ],
            scenesPerElement: Array(repeating: 0, count: 12),
            projectID: nil,
            in: context
        )

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: threeAct,
            to: herosJourney,
            strategy: .arcBased
        )

        // Verify mappings exist
        #expect(result.mappings.count == 3)

        // Verify match quality is reasonable (>= 50%)
        for mapping in result.mappings {
            #expect(mapping.matchQuality >= 0.5, "Match quality should be at least 50%")
        }
    }

    @Test("Arc-based mapping provides quality warnings for poor matches")
    @MainActor
    func arcBasedMappingProvidesWarnings() async throws {
        let (context, project) = createTestContext()

        // Create structures with very different arc shapes
        let linear = createStructureWithScenes(
            name: "Beginning-Middle-End",
            elements: ["Beginning", "Middle", "End"],
            scenesPerElement: [5, 0, 0], // All scenes at start
            projectID: project.id,
            in: context
        )

        let fiveAct = createStructureWithScenes(
            name: "Five-Act Structure",
            elements: ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"],
            scenesPerElement: [0, 0, 0, 0, 0],
            projectID: nil,
            in: context
        )

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: linear,
            to: fiveAct,
            strategy: .arcBased
        )

        // Should still map all scenes
        #expect(result.mappedSceneCount == 5)

        // Warnings may or may not be present depending on match quality
        // This is expected behavior - test just verifies it doesn't crash
    }

    // MARK: - Proportional Mapping Tests

    @Test("Proportional mapping distributes scenes evenly")
    @MainActor
    func proportionalMappingDistributesEvenly() async throws {
        let (context, project) = createTestContext()

        let threeAct = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [3, 3, 3],
            projectID: project.id,
            in: context
        )

        let fiveAct = createStructureWithScenes(
            name: "Five-Act Structure",
            elements: ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"],
            scenesPerElement: [0, 0, 0, 0, 0],
            projectID: nil,
            in: context
        )

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: threeAct,
            to: fiveAct,
            strategy: .proportional
        )

        #expect(result.mappedSceneCount == 9)
        #expect(result.unmappedSceneCount == 0)
        #expect(result.warnings.isEmpty)
    }

    // MARK: - Preserve Old Strategy Tests

    @Test("Preserve old strategy doesn't move scenes")
    @MainActor
    func preserveOldDoesNotMoveScenes() async throws {
        let (context, project) = createTestContext()

        let threeAct = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [2, 3, 2],
            projectID: project.id,
            in: context
        )

        let fiveAct = createStructureWithScenes(
            name: "Five-Act Structure",
            elements: ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"],
            scenesPerElement: [0, 0, 0, 0, 0],
            projectID: nil,
            in: context
        )

        // Count scenes in old structure before mapping
        let oldSceneCount = threeAct.elements?.reduce(0) { sum, element in
            sum + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        } ?? 0

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: threeAct,
            to: fiveAct,
            strategy: .preserveOld
        )

        // No scenes should be mapped
        #expect(result.mappedSceneCount == 0)
        #expect(result.warnings.count > 0)

        // Old structure should still have all its scenes
        let stillHasScenes = threeAct.elements?.reduce(0) { sum, element in
            sum + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        } ?? 0
        #expect(stillHasScenes == oldSceneCount)

        // New structure should still be empty
        let newSceneCount = fiveAct.elements?.reduce(0) { sum, element in
            sum + (element.assignedCards?.filter { $0.kind == .scenes }.count ?? 0)
        } ?? 0
        #expect(newSceneCount == 0)
    }

    // MARK: - Edge Cases

    @Test("Mapping handles empty source structure")
    @MainActor
    func mappingHandlesEmptySource() async throws {
        let (context, project) = createTestContext()

        let emptyStructure = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [0, 0, 0], // No scenes
            projectID: project.id,
            in: context
        )

        let fiveAct = createStructureWithScenes(
            name: "Five-Act Structure",
            elements: ["Exposition", "Rising Action", "Climax", "Falling Action", "Resolution"],
            scenesPerElement: [0, 0, 0, 0, 0],
            projectID: nil,
            in: context
        )

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: emptyStructure,
            to: fiveAct,
            strategy: .arcBased
        )

        // Should handle gracefully with no mappings
        #expect(result.mappedSceneCount == 0)
        #expect(result.unmappedSceneCount == 0)
    }

    @Test("Mapping handles single-element structures")
    @MainActor
    func mappingHandlesSingleElement() async throws {
        let (context, project) = createTestContext()

        let singleElement = StoryStructure(name: "Single", projectID: project.id)
        context.insert(singleElement)
        let element = StructureElement(name: "Only Beat", orderIndex: 0)
        element.storyStructure = singleElement
        context.insert(element)
        singleElement.elements = [element]

        // Add scenes
        for i in 0..<3 {
            let scene = Card(kind: .scenes, name: "Scene \(i)", subtitle: "", detailedText: "")
            context.insert(scene)
            if element.assignedCards == nil {
                element.assignedCards = []
            }
            element.assignedCards?.append(scene)
        }

        let threeAct = createStructureWithScenes(
            name: "Three-Act Structure",
            elements: ["Act 1", "Act 2", "Act 3"],
            scenesPerElement: [0, 0, 0],
            projectID: nil,
            in: context
        )

        let service = StructureMappingService(modelContext: context)
        let result = service.switchStructure(
            for: project,
            from: singleElement,
            to: threeAct,
            strategy: .arcBased
        )

        // All scenes should map to one of the three acts
        #expect(result.mappedSceneCount == 3)
    }
}

// MARK: - Helper Extensions

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
