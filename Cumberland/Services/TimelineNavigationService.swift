//
//  TimelineNavigationService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 6: Timeline Integration
//
//  Centralized service for timeline-manuscript navigation and out-of-order detection.
//
//  **Architecture**: Business logic layer - delegates data access to TimelineQueryService

import Foundation
import SwiftData

@MainActor
final class TimelineNavigationService {
    private let queryService: TimelineQueryService
    private let cardRepository: CardRepository

    init(modelContext: ModelContext) {
        self.queryService = TimelineQueryService(modelContext: modelContext)
        self.cardRepository = CardRepository(modelContext: modelContext)
    }

    // MARK: - Timeline Discovery

    /// Find the primary (first) timeline containing a scene for a project
    func findPrimaryTimelineForScene(sceneID: UUID, projectID: UUID) -> Card? {
        let timelines = queryService.findTimelinesForSceneID(sceneID, projectID: projectID)
        return timelines.first
    }

    /// Find all timelines that contain a given scene
    func findTimelinesForScene(_ scene: Card) -> [Card] {
        return queryService.findTimelinesForSceneID(scene.id, projectID: nil)
    }

    // MARK: - Scene Positioning

    /// Get scene's position on timeline (returns index and temporal data)
    func getSceneTimelinePosition(scene: Card, timeline: Card) -> SceneTimelinePosition? {
        return queryService.getSceneTimelinePosition(scene: scene, timeline: timeline)
    }

    // MARK: - Out-of-Order Detection

    /// Detect out-of-order scenes between manuscript and timeline
    func detectOutOfOrderScenes(project: Card, timeline: Card) -> [OutOfOrderScene] {
        // Get scenes in manuscript order
        let manuscriptScenes = cardRepository.fetchScenesInProject(project)

        // Get scenes in timeline order
        let timelineScenes = queryService.fetchScenesOnTimeline(timeline)

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
}

// MARK: - Supporting Types

/// Represents a scene that appears in different positions in manuscript vs timeline
struct OutOfOrderScene: Identifiable, Hashable {
    let sceneID: UUID
    let sceneName: String
    let manuscriptIndex: Int
    let timelineIndex: Int
    let isEarlierInManuscript: Bool  // true = manuscript position < timeline position

    var id: UUID { sceneID }
}
