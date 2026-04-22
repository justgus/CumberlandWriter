//
//  TimelineNavigationService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 6: Timeline Integration
//
//  Centralized service for timeline-manuscript navigation and out-of-order detection.
//

import Foundation
import SwiftData

@MainActor
final class TimelineNavigationService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Timeline Discovery

    /// Find the primary (first) timeline containing a scene for a project
    func findPrimaryTimelineForScene(sceneID: UUID, projectID: UUID) -> Card? {
        let timelines = findTimelinesForSceneID(sceneID, projectID: projectID)
        return timelines.first
    }

    /// Find all timelines that contain a given scene
    func findTimelinesForScene(_ scene: Card) -> [Card] {
        return findTimelinesForSceneID(scene.id, projectID: nil)
    }

    private func findTimelinesForSceneID(_ sceneID: UUID, projectID: UUID?) -> [Card] {
        let sceneIDOpt: UUID? = sceneID
        let timelineKind = Kinds.timelines.rawValue

        // Query Scene → Timeline edges ("describes/described-by")
        let descriptor = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.from?.id == sceneIDOpt &&
                edge.to?.kindRaw == timelineKind
            }
        )

        guard let edges = try? modelContext.fetch(descriptor) else {
            return []
        }

        var timelines = edges.compactMap { $0.to }

        // Filter by project if specified
        if let projectID = projectID {
            timelines = timelines.filter { timeline in
                guard let tlProject = fetchProjectForTimeline(timeline) else { return false }
                return tlProject.id == projectID
            }
        }

        return timelines
    }

    // MARK: - Scene Positioning

    /// Get scene's position on timeline (returns index and temporal data)
    func getSceneTimelinePosition(scene: Card, timeline: Card) -> SceneTimelinePosition? {
        let sceneIDOpt: UUID? = scene.id
        let timelineIDOpt: UUID? = timeline.id

        // Find the edge connecting this scene to this timeline
        let descriptor = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.from?.id == sceneIDOpt &&
                edge.to?.id == timelineIDOpt
            }
        )

        guard let edge = try? modelContext.fetch(descriptor).first else {
            return nil
        }

        // Get all scenes on this timeline in order
        let allScenes = fetchScenesOnTimeline(timeline)
        guard let index = allScenes.firstIndex(where: { $0.id == scene.id }) else {
            return nil
        }

        return SceneTimelinePosition(
            sceneID: scene.id,
            timelineIndex: index,
            temporalPosition: edge.temporalPosition,
            duration: edge.duration
        )
    }

    // MARK: - Out-of-Order Detection

    /// Detect out-of-order scenes between manuscript and timeline
    func detectOutOfOrderScenes(project: Card, timeline: Card) -> [OutOfOrderScene] {
        // Get scenes in manuscript order
        let repository = CardRepository(modelContext: modelContext)
        let manuscriptScenes = repository.fetchScenesInProject(project)

        // Get scenes in timeline order
        let timelineScenes = fetchScenesOnTimeline(timeline)

        // Compare orderings
        var discrepancies: [OutOfOrderScene] = []

        for (manuscriptIndex, manuscriptScene) in manuscriptScenes.enumerated() {
            if let timelineIndex = timelineScenes.firstIndex(where: { $0.id == manuscriptScene.id }) {
                // Scene exists in both orderings - check if positions match
                if manuscriptIndex != timelineIndex {
                    discrepancies.append(OutOfOrderScene(
                        sceneID: manuscriptScene.id,
                        sceneName: manuscriptScene.name,
                        manuscriptIndex: manuscriptIndex,
                        timelineIndex: timelineIndex,
                        isEarlierInManuscript: manuscriptIndex < timelineIndex
                    ))
                }
            }
        }

        return discrepancies
    }

    // MARK: - Helper Methods

    private func fetchScenesOnTimeline(_ timeline: Card) -> [Card] {
        let timelineIDOpt: UUID? = timeline.id
        let sceneKind = Kinds.scenes.rawValue

        // Determine timeline mode
        let isTemporalMode = timeline.calendarSystem != nil

        // Fetch Scene → Timeline edges
        let descriptor: FetchDescriptor<CardEdge>

        if isTemporalMode {
            // Sort by temporal position
            descriptor = FetchDescriptor<CardEdge>(
                predicate: #Predicate { edge in
                    edge.to?.id == timelineIDOpt &&
                    edge.from?.kindRaw == sceneKind
                },
                sortBy: [
                    SortDescriptor(\.temporalPosition, order: .forward),
                    SortDescriptor(\.sortIndex, order: .forward)
                ]
            )
        } else {
            // Sort by sortIndex (ordinal mode)
            descriptor = FetchDescriptor<CardEdge>(
                predicate: #Predicate { edge in
                    edge.to?.id == timelineIDOpt &&
                    edge.from?.kindRaw == sceneKind
                },
                sortBy: [
                    SortDescriptor(\.sortIndex, order: .forward),
                    SortDescriptor(\.createdAt, order: .forward)
                ]
            )
        }

        guard let edges = try? modelContext.fetch(descriptor) else {
            return []
        }

        return edges.compactMap { $0.from }
    }

    private func fetchProjectForTimeline(_ timeline: Card) -> Card? {
        let timelineIDOpt: UUID? = timeline.id

        // Timelines belong to projects via "part-of/has-timeline" edges
        let descriptor = FetchDescriptor<CardEdge>(
            predicate: #Predicate { edge in
                edge.from?.id == timelineIDOpt &&
                edge.type?.code == "part-of/has-timeline"
            }
        )

        guard let edge = try? modelContext.fetch(descriptor).first else {
            return nil
        }

        return edge.to
    }
}

// MARK: - Supporting Types

struct OutOfOrderScene: Identifiable, Hashable {
    let sceneID: UUID
    let sceneName: String
    let manuscriptIndex: Int
    let timelineIndex: Int
    let isEarlierInManuscript: Bool  // true = manuscript position < timeline position

    var id: UUID { sceneID }
}

struct SceneTimelinePosition: Hashable {
    let sceneID: UUID
    let timelineIndex: Int
    let temporalPosition: Date?
    let duration: TimeInterval?
}
