//
//  StructureMappingService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 3: Story Structure Integration - Arc-Based Scene Mapping
//
//  Intelligent scene mapping algorithm that uses narrative arc functions
//  to preserve dramatic position when switching between story structures.
//
//  Instead of simple proportional mapping (50% → 50%), this algorithm:
//  1. Calculates the tension value and slope at the scene's current position
//  2. Finds the best matching position in the new structure's arc
//  3. Assigns the scene to the nearest beat at that position
//

import Foundation
import SwiftData

/// Service for mapping scenes between story structures using narrative arcs
@MainActor
final class StructureMappingService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Structure Switching

    /// Switch a project's story structure while intelligently remapping scenes
    ///
    /// - Parameters:
    ///   - project: The project to switch structures for
    ///   - oldStructure: The current story structure
    ///   - newStructure: The new story structure to apply
    ///   - mappingStrategy: Strategy to use for mapping (defaults to arc-based)
    ///
    /// - Returns: Mapping result with statistics and warnings
    func switchStructure(
        for project: Card,
        from oldStructure: StoryStructure,
        to newStructure: StoryStructure,
        strategy: MappingStrategy = .arcBased
    ) -> MappingResult {
        guard project.kind == .projects else {
            fatalError("switchStructure called with non-project card")
        }

        switch strategy {
        case .arcBased:
            return switchStructureUsingArcMapping(
                from: oldStructure,
                to: newStructure
            )
        case .proportional:
            return switchStructureUsingProportionalMapping(
                from: oldStructure,
                to: newStructure
            )
        case .preserveOld:
            return preserveOldStructureWhileBuildingNew(
                old: oldStructure,
                new: newStructure
            )
        }
    }

    // MARK: - Arc-Based Mapping Algorithm

    /// Map scenes using narrative arc tension and slope matching
    private func switchStructureUsingArcMapping(
        from oldStructure: StoryStructure,
        to newStructure: StoryStructure
    ) -> MappingResult {
        guard let oldElements = oldStructure.elements?.sorted(by: { $0.orderIndex < $1.orderIndex }),
              let newElements = newStructure.elements?.sorted(by: { $0.orderIndex < $1.orderIndex }),
              !oldElements.isEmpty,
              !newElements.isEmpty else {
            return MappingResult(
                mappedSceneCount: 0,
                unmappedSceneCount: 0,
                warnings: ["Empty structure elements"],
                mappings: []
            )
        }

        let oldArc = oldStructure.narrativeArc
        let newArc = newStructure.narrativeArc

        var mappings: [SceneMapping] = []
        var totalScenesMapped = 0
        var warnings: [String] = []

        // Process each old element and its assigned scenes
        for (oldIndex, oldElement) in oldElements.enumerated() {
            guard let scenes = oldElement.assignedCards?.filter({ $0.kind == .scenes }),
                  !scenes.isEmpty else {
                continue
            }

            // Calculate old element's normalized position
            let oldPosition = Double(oldIndex) / Double(max(1, oldElements.count - 1))

            // Get tension and slope at this position in old structure
            let oldTension = oldArc.tension(at: oldPosition)
            let oldSlope = oldArc.slope(at: oldPosition)

            // Find best matching position in new structure
            let (newPosition, matchQuality) = findBestArcMatch(
                targetTension: oldTension,
                targetSlope: oldSlope,
                in: newArc,
                elementCount: newElements.count
            )

            // Find nearest element in new structure
            let newIndex = findNearestElementIndex(
                at: newPosition,
                in: newElements
            )

            let newElement = newElements[newIndex]

            // Map all scenes from old element to new element
            for scene in scenes {
                // Remove from old element
                oldElement.assignedCards?.removeAll { $0.id == scene.id }

                // Add to new element
                if newElement.assignedCards == nil {
                    newElement.assignedCards = []
                }
                newElement.assignedCards?.append(scene)

                totalScenesMapped += 1

                mappings.append(SceneMapping(
                    sceneID: scene.id,
                    sceneName: scene.name,
                    fromBeat: oldElement.name,
                    toBeat: newElement.name,
                    oldPosition: oldPosition,
                    newPosition: newPosition,
                    matchQuality: matchQuality
                ))
            }

            // Add warning if match quality is low
            if matchQuality < 0.7 && scenes.count > 0 {
                warnings.append(
                    "Low match quality (\(Int(matchQuality * 100))%) mapping '\(oldElement.name)' → '\(newElement.name)'"
                )
            }
        }

        // Update project's structure reference
        newStructure.projectID = oldStructure.projectID
        oldStructure.projectID = nil

        return MappingResult(
            mappedSceneCount: totalScenesMapped,
            unmappedSceneCount: 0,
            warnings: warnings,
            mappings: mappings
        )
    }

    /// Find the best matching position in the new arc based on tension and slope
    ///
    /// Returns: (position, matchQuality) where position is 0.0-1.0 and matchQuality is 0.0-1.0
    private func findBestArcMatch(
        targetTension: Double,
        targetSlope: Double,
        in arc: NarrativeArc,
        elementCount: Int
    ) -> (position: Double, matchQuality: Double) {
        // Sample positions across the arc
        let sampleCount = elementCount * 10 // Sample 10x element count for precision
        var bestMatch: (position: Double, score: Double) = (0.0, 0.0)

        for i in 0..<sampleCount {
            let position = Double(i) / Double(max(1, sampleCount - 1))
            let tension = arc.tension(at: position)
            let slope = arc.slope(at: position)

            // Calculate match score (weighted: 70% tension, 30% slope direction)
            let tensionDiff = abs(tension - targetTension)
            let tensionScore = 1.0 - tensionDiff // 0.0 = perfect match

            // Slope direction match (both positive, both negative, or both near-zero)
            let slopeMatch: Double = {
                let threshold = 0.1
                let oldRising = targetSlope > threshold
                let oldFalling = targetSlope < -threshold
                let newRising = slope > threshold
                let newFalling = slope < -threshold

                if (oldRising && newRising) || (oldFalling && newFalling) {
                    return 1.0 // Same direction
                } else if abs(targetSlope) < threshold && abs(slope) < threshold {
                    return 1.0 // Both flat
                } else {
                    return 0.5 // Different direction
                }
            }()

            let score = (tensionScore * 0.7) + (slopeMatch * 0.3)

            if score > bestMatch.score {
                bestMatch = (position, score)
            }
        }

        return (position: bestMatch.position, matchQuality: bestMatch.score)
    }

    /// Find the nearest element index for a given normalized position
    private func findNearestElementIndex(
        at position: Double,
        in elements: [StructureElement]
    ) -> Int {
        guard !elements.isEmpty else { return 0 }

        var nearestIndex = 0
        var smallestDiff = Double.infinity

        for (index, _) in elements.enumerated() {
            let elementPosition = Double(index) / Double(max(1, elements.count - 1))
            let diff = abs(position - elementPosition)

            if diff < smallestDiff {
                smallestDiff = diff
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    // MARK: - Alternative Mapping Strategies

    /// Simple proportional mapping (legacy approach)
    private func switchStructureUsingProportionalMapping(
        from oldStructure: StoryStructure,
        to newStructure: StoryStructure
    ) -> MappingResult {
        guard let oldElements = oldStructure.elements?.sorted(by: { $0.orderIndex < $1.orderIndex }),
              let newElements = newStructure.elements?.sorted(by: { $0.orderIndex < $1.orderIndex }),
              !oldElements.isEmpty,
              !newElements.isEmpty else {
            return MappingResult(
                mappedSceneCount: 0,
                unmappedSceneCount: 0,
                warnings: ["Empty structure elements"],
                mappings: []
            )
        }

        var mappings: [SceneMapping] = []
        var totalScenesMapped = 0

        for (oldIndex, oldElement) in oldElements.enumerated() {
            guard let scenes = oldElement.assignedCards?.filter({ $0.kind == .scenes }),
                  !scenes.isEmpty else {
                continue
            }

            // Simple proportional mapping
            let oldPosition = Double(oldIndex) / Double(max(1, oldElements.count - 1))
            let newIndex = Int(round(oldPosition * Double(newElements.count - 1)))
                .clamped(to: 0...(newElements.count - 1))

            let newElement = newElements[newIndex]

            // Move scenes
            for scene in scenes {
                oldElement.assignedCards?.removeAll { $0.id == scene.id }
                if newElement.assignedCards == nil {
                    newElement.assignedCards = []
                }
                newElement.assignedCards?.append(scene)
                totalScenesMapped += 1

                mappings.append(SceneMapping(
                    sceneID: scene.id,
                    sceneName: scene.name,
                    fromBeat: oldElement.name,
                    toBeat: newElement.name,
                    oldPosition: oldPosition,
                    newPosition: Double(newIndex) / Double(max(1, newElements.count - 1)),
                    matchQuality: 1.0
                ))
            }
        }

        // Update project's structure reference
        newStructure.projectID = oldStructure.projectID
        oldStructure.projectID = nil

        return MappingResult(
            mappedSceneCount: totalScenesMapped,
            unmappedSceneCount: 0,
            warnings: [],
            mappings: mappings
        )
    }

    /// Preserve old structure while building new (no automatic mapping)
    private func preserveOldStructureWhileBuildingNew(
        old oldStructure: StoryStructure,
        new newStructure: StoryStructure
    ) -> MappingResult {
        // Simply create the new structure without moving any scenes
        // Writer will manually assign scenes to new structure
        newStructure.projectID = oldStructure.projectID

        return MappingResult(
            mappedSceneCount: 0,
            unmappedSceneCount: 0,
            warnings: ["Manual mapping required - no scenes automatically moved"],
            mappings: []
        )
    }
}

// MARK: - Supporting Types

/// Strategy for mapping scenes between structures
enum MappingStrategy {
    case arcBased          // Use narrative arc tension and slope matching (recommended)
    case proportional      // Simple proportional position mapping
    case preserveOld       // Keep old structure, build new one manually
}

/// Result of a structure mapping operation
struct MappingResult {
    let mappedSceneCount: Int
    let unmappedSceneCount: Int
    let warnings: [String]
    let mappings: [SceneMapping]

    var success: Bool {
        unmappedSceneCount == 0 && warnings.isEmpty
    }
}

/// Individual scene mapping record
struct SceneMapping: Identifiable {
    let id = UUID()
    let sceneID: UUID
    let sceneName: String
    let fromBeat: String
    let toBeat: String
    let oldPosition: Double  // 0.0 to 1.0
    let newPosition: Double  // 0.0 to 1.0
    let matchQuality: Double // 0.0 to 1.0 (1.0 = perfect match)
}

// MARK: - Helper Extensions

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
