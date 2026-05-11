//
//  TimelineQueryService.swift
//  Cumberland
//
//  Created as part of architectural refactoring to separate data queries
//  from business logic.
//
//  This service provides pure data access for timeline-related queries.
//  Business logic should use TimelineNavigationService in the Services folder.
//

import Foundation
import SwiftData

/// Data access service for timeline-related queries
///
/// Provides low-level database queries for:
/// - Scene positioning on timelines
/// - Timeline-project relationships
/// - Scene-timeline associations
///
/// **Architecture**: Data access layer - uses FetchDescriptor directly
@MainActor
final class TimelineQueryService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Scene Positioning Queries

    /// Get scene's position on timeline (returns index and temporal data)
    /// - Parameters:
    ///   - scene: The scene card
    ///   - timeline: The timeline card
    /// - Returns: Position data or nil if scene not on timeline
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

    /// Fetch all scenes on a timeline in order
    /// - Parameter timeline: The timeline card
    /// - Returns: Array of scene cards in timeline order
    func fetchScenesOnTimeline(_ timeline: Card) -> [Card] {
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

    // MARK: - Timeline-Project Relationship Queries

    /// Fetch the project that owns a timeline
    /// - Parameter timeline: The timeline card
    /// - Returns: Project card or nil if not found
    func fetchProjectForTimeline(_ timeline: Card) -> Card? {
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

    // MARK: - Scene-Timeline Association Queries

    /// Find all timelines that contain a given scene
    /// - Parameters:
    ///   - sceneID: The scene's UUID
    ///   - projectID: Optional project UUID to filter results
    /// - Returns: Array of timeline cards
    func findTimelinesForSceneID(_ sceneID: UUID, projectID: UUID?) -> [Card] {
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
}

// MARK: - Supporting Types

/// Position information for a scene on a timeline
struct SceneTimelinePosition: Hashable {
    let sceneID: UUID
    let timelineIndex: Int
    let temporalPosition: Date?
    let duration: TimeInterval?
}
