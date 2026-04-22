//
//  ProjectDashboardService.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 4: Dashboard Integration
//
//  Service for aggregating project dashboard data from Cumberland repositories.
//  Located in Data layer for direct access to CardRepository and EdgeRepository.
//
//  Implements dashboard data model as specified in
//  cumberland_project_dashboard_design_spec.md
//

import Foundation
import SwiftData

/// Service for building Project Dashboard data models
@Observable
@MainActor
final class ProjectDashboardService {
    private let modelContext: ModelContext
    private let cardRepository: CardRepository
    private let edgeRepository: EdgeRepository

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cardRepository = CardRepository(modelContext: modelContext)
        self.edgeRepository = EdgeRepository(modelContext: modelContext)
    }

    // MARK: - Main Dashboard Builder

    /// Build complete dashboard model for a project
    func buildDashboardModel(for project: Card) -> ProjectDashboardModel {
        guard project.kind == .projects else {
            fatalError("buildDashboardModel called with non-project card")
        }

        return ProjectDashboardModel(
            project: project,
            currentContext: buildCurrentContext(for: project),
            structureBand: buildStructureBand(for: project),
            statusGlyph: buildStatusGlyph(for: project),
            returnStrip: buildReturnStrip(for: project),
            castShelf: buildCastShelf(for: project),
            issuesShelf: buildIssuesShelf(for: project),
            threadShelf: buildThreadShelf(for: project)
        )
    }

    // MARK: - Current Context

    private func buildCurrentContext(for project: Card) -> CurrentContext {
        // TODO: Implement active scene/chapter tracking
        let activeChapterID: UUID? = nil
        let activeSceneID: UUID? = nil
        let activeEventID: UUID? = nil

        // Get scene contents (placeholder for now)
        let sceneContents: [Card] = []

        // Detect orphan counts
        let orphanCounts = detectOrphanCounts(for: project)

        return CurrentContext(
            activeChapterID: activeChapterID,
            activeSceneID: activeSceneID,
            activeEventID: activeEventID,
            sceneContents: sceneContents,
            orphanCounts: orphanCounts
        )
    }

    private func detectOrphanCounts(for project: Card) -> [OrphanCount] {
        var counts: [OrphanCount] = []

        // Orphaned scenes
        let orphanedScenes = cardRepository.fetchOrphanedScenesInProject(project)
        if !orphanedScenes.isEmpty {
            counts.append(OrphanCount(issueType: "Orphan scenes", count: orphanedScenes.count))
        }

        // Orphaned chapters (chapters not linked to project)
        let allChapters = cardRepository.fetch(byKind: .chapters)
        let projectChapters = cardRepository.fetchChaptersInProject(project)
        let orphanedChapters = allChapters.filter { chapter in
            !projectChapters.contains(where: { $0.id == chapter.id })
        }
        if !orphanedChapters.isEmpty {
            counts.append(OrphanCount(issueType: "Orphan chapters", count: orphanedChapters.count))
        }

        return counts
    }

    // MARK: - Structure Band

    private func buildStructureBand(for project: Card) -> StructureBandModel {
        // Fetch the story structure for this project
        let projectUUID = project.id
        let descriptor = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { structure in
                structure.projectID == projectUUID
            }
        )

        guard let structure = try? modelContext.fetch(descriptor).first,
              let elements = structure.elements,
              !elements.isEmpty else {
            // No structure defined - return empty model
            return StructureBandModel(
                beats: [],
                contourSegments: [],
                activePositionFraction: 0.0,
                continuityBreaks: [],
                narrativeArc: nil,
                arcSegments: nil
            )
        }

        // Build beats array
        let sortedElements = elements.sorted { $0.orderIndex < $1.orderIndex }
        let beats = sortedElements.enumerated().map { index, element in
            let assignedScenes = element.assignedCards?.filter { $0.kind == .scenes } ?? []
            let normalizedPosition = Double(index) / Double(max(1, sortedElements.count - 1))

            return StructureBeat(
                beatID: element.id,
                label: element.name,
                normalizedPosition: normalizedPosition,
                isDefined: true,
                isMaterialized: !assignedScenes.isEmpty,
                attachedSceneCount: assignedScenes.count
            )
        }

        // Get narrative arc
        let arc = structure.narrativeArc

        // Build contour segments (legacy format for existing visualization)
        let contourSegments = buildContourSegments(
            arc: arc,
            beats: beats,
            elements: sortedElements
        )

        // Build arc segment data for new Tufte-style visualization
        let arcSegmentData = buildArcSegmentData(
            beats: beats,
            elements: sortedElements
        )

        // Calculate active position (placeholder - based on most recent scene)
        let activePositionFraction = calculateActivePosition(
            in: sortedElements
        )

        // Detect continuity breaks (placeholder)
        let continuityBreaks: [ClosedRange<Double>] = []

        return StructureBandModel(
            beats: beats,
            contourSegments: contourSegments,
            activePositionFraction: activePositionFraction,
            continuityBreaks: continuityBreaks,
            narrativeArc: arc,
            arcSegments: arcSegmentData
        )
    }

    /// Build arc segment data for Tufte-style visualization
    private func buildArcSegmentData(
        beats: [StructureBeat],
        elements: [StructureElement]
    ) -> [ArcSegmentData] {
        guard !beats.isEmpty else { return [] }

        var segments: [ArcSegmentData] = []

        for i in 0..<beats.count {
            let startPosition = beats[i].normalizedPosition
            let endPosition: Double

            if i < beats.count - 1 {
                endPosition = beats[i + 1].normalizedPosition
            } else {
                endPosition = 1.0
            }

            segments.append(ArcSegmentData(
                startPosition: startPosition,
                endPosition: endPosition,
                sceneCount: beats[i].attachedSceneCount,
                beatLabel: beats[i].label,
                beatID: beats[i].beatID
            ))
        }

        return segments
    }

    /// Build contour segments from narrative arc and structure elements
    private func buildContourSegments(
        arc: NarrativeArc,
        beats: [StructureBeat],
        elements: [StructureElement]
    ) -> [ContourSegment] {
        guard !beats.isEmpty else { return [] }

        var segments: [ContourSegment] = []

        for i in 0..<beats.count {
            let startPosition = beats[i].normalizedPosition
            let endPosition: Double

            if i < beats.count - 1 {
                endPosition = beats[i + 1].normalizedPosition
            } else {
                endPosition = 1.0
            }

            // Get scene count for this beat
            let sceneCount = beats[i].attachedSceneCount

            // Calculate visual weight based on scene count (Tufte principle)
            let visualWeight = visualWeightForSceneCount(sceneCount)

            // Determine contour state
            let state: ContourState = {
                if sceneCount == 0 {
                    return .thin // No scenes = ghosted line
                } else if sceneCount >= 3 {
                    return .formed // Well-populated beat
                } else {
                    return .thin // Some scenes but still thin
                }
            }()

            segments.append(ContourSegment(
                startFraction: startPosition,
                endFraction: endPosition,
                visualWeight: visualWeight,
                state: state
            ))
        }

        return segments
    }

    /// Calculate visual weight for scene count (maps to line thickness)
    private func visualWeightForSceneCount(_ sceneCount: Int) -> Double {
        switch sceneCount {
        case 0:
            return 0.5 // Ghosted
        case 1:
            return 1.0
        case 2...3:
            return 1.5
        case 4...6:
            return 2.25
        default: // 7+
            return 3.0
        }
    }

    /// Calculate active position in structure (placeholder implementation)
    private func calculateActivePosition(in elements: [StructureElement]) -> Double {
        // TODO: Track actual active scene/chapter
        // For now, find the last element with assigned scenes
        for (index, element) in elements.enumerated().reversed() {
            if let scenes = element.assignedCards?.filter({ $0.kind == .scenes }),
               !scenes.isEmpty {
                return Double(index) / Double(max(1, elements.count - 1))
            }
        }

        return 0.0 // Default to beginning
    }

    // MARK: - Status Glyph

    private func buildStatusGlyph(for project: Card) -> StatusGlyphModel {
        return StatusGlyphModel(
            timelineRing: buildTimelineRing(for: project),
            chapterRing: buildChapterRing(for: project),
            sceneRing: buildSceneRing(for: project),
            activeLocus: buildActiveLocus(for: project)
        )
    }

    private func buildTimelineRing(for project: Card) -> TimelineRing {
        // Placeholder: no timeline events yet
        return TimelineRing(
            beginMarkerAngle: 0.0,
            endMarkerAngle: Double.pi * 2.0,
            direction: .counterclockwise,
            events: []
        )
    }

    private func buildChapterRing(for project: Card) -> ChapterRing {
        let chapters = cardRepository.fetchChaptersInProject(project)

        guard !chapters.isEmpty else {
            return ChapterRing(spans: [])
        }

        // Calculate chapter spans
        let totalExtent = Double(chapters.count) // Simple: equal weight for now
        let sweepAngle = Double.pi * 2.0 * 0.9 // 90% of circle (leave gap at top)
        let startAngle = Double.pi * 0.55 // Start at ~100° (leaving top gap)

        var currentAngle = startAngle
        var spans: [ChapterSpan] = []

        for chapter in chapters {
            let chapterExtent = 1.0 // Equal weight
            let spanSize = (chapterExtent / totalExtent) * sweepAngle
            let endAngle = currentAngle + spanSize

            // Determine state based on scene count
            let sceneCount = cardRepository.fetchScenesInChapter(
                chapterID: chapter.id,
                projectID: project.id
            ).count

            let state: GlyphSpanState
            if sceneCount == 0 {
                state = .thinDefined
            } else if sceneCount < 2 {
                state = .thinDefined
            } else {
                state = .formed
            }

            spans.append(ChapterSpan(
                chapterID: chapter.id,
                startAngle: currentAngle,
                endAngle: endAngle,
                state: state
            ))

            currentAngle = endAngle
        }

        return ChapterRing(spans: spans)
    }

    private func buildSceneRing(for project: Card) -> SceneRing {
        let scenes = cardRepository.fetchScenesInProject(project)

        guard !scenes.isEmpty else {
            return SceneRing(spans: [])
        }

        // Calculate scene spans
        let totalExtent = Double(scenes.count) // Simple: equal weight for now
        let sweepAngle = Double.pi * 2.0 * 0.9 // 90% of circle
        let startAngle = Double.pi * 0.55

        var currentAngle = startAngle
        var spans: [SceneSpan] = []

        for scene in scenes {
            let sceneExtent = 1.0 // Equal weight
            let spanSize = (sceneExtent / totalExtent) * sweepAngle
            let endAngle = currentAngle + spanSize

            // Determine state based on content
            let wordCount = scene.detailedText.split(separator: " ").count
            let state: GlyphSpanState
            if wordCount == 0 {
                state = .thinDefined
            } else if wordCount < 100 {
                state = .thinDefined
            } else {
                state = .formed
            }

            spans.append(SceneSpan(
                sceneID: scene.id,
                startAngle: currentAngle,
                endAngle: endAngle,
                state: state,
                isOrphanSpill: false // TODO: Check if scene has valid chapter parent
            ))

            currentAngle = endAngle
        }

        return SceneRing(spans: spans)
    }

    private func buildActiveLocus(for project: Card) -> ActiveLocus {
        // Placeholder: no active locus yet
        return ActiveLocus(
            eventID: nil,
            chapterID: nil,
            sceneID: nil,
            eventAngle: nil,
            chapterSpan: nil,
            sceneSpan: nil
        )
    }

    // MARK: - Return Strip

    private func buildReturnStrip(for project: Card) -> ReturnStripModel {
        // Find resume target (most recent scene or first scene)
        let scenes = cardRepository.fetchScenesInProject(project)

        guard let resumeScene = scenes.first else {
            // No scenes - create placeholder
            return ReturnStripModel(
                lastNode: nil,
                resumeNode: ReturnNode(
                    targetID: project.id,
                    targetType: .scene,
                    title: "No scenes yet",
                    subtitle: "Create your first scene to begin",
                    excerpt: "",
                    contextTokens: []
                ),
                nextNode: nil
            )
        }

        let resumeNode = ReturnNode(
            targetID: resumeScene.id,
            targetType: .scene,
            title: resumeScene.name.isEmpty ? "Untitled Scene" : resumeScene.name,
            subtitle: resumeScene.subtitle,
            excerpt: String(resumeScene.detailedText.suffix(50)),
            contextTokens: []
        )

        return ReturnStripModel(
            lastNode: nil, // TODO: Track last edited scene
            resumeNode: resumeNode,
            nextNode: nil // TODO: Find next structural opening
        )
    }

    // MARK: - Cast Shelf

    private func buildCastShelf(for project: Card) -> CastShelfModel {
        // Get all characters linked to project scenes
        let scenes = cardRepository.fetchScenesInProject(project)
        var characterIDs = Set<UUID>()

        for scene in scenes {
            // Get characters linked to this scene
            let sceneEdges = edgeRepository.fetchOutgoing(from: scene)
            for edge in sceneEdges {
                if let toCard = edge.to, toCard.kind == .characters {
                    characterIDs.insert(toCard.id)
                }
            }
        }

        // Fetch character cards
        let characters = characterIDs.compactMap { id in
            cardRepository.fetch(byUUID: id)
        }.map { character in
            CastCharacter(
                characterID: character.id,
                displayLabel: character.name,
                thumbnailData: character.thumbnailData
            )
        }

        return CastShelfModel(
            characters: characters,
            summaryText: characters.isEmpty ? "No characters" : "\(characters.count) character\(characters.count == 1 ? "" : "s")"
        )
    }

    // MARK: - Issues Shelf

    private func buildIssuesShelf(for project: Card) -> IssuesShelfModel {
        var issues: [ProjectIssue] = []

        // Detect orphaned scenes
        let orphanedScenes = cardRepository.fetchOrphanedScenesInProject(project)
        if !orphanedScenes.isEmpty {
            issues.append(ProjectIssue(
                id: UUID(),
                issueType: .orphanedScenes,
                displayText: "Orphan scene ×\(orphanedScenes.count)",
                severity: .warning,
                linkedTargets: orphanedScenes.map { $0.id },
                resolutionActions: ["Assign to chapter", "View scenes"]
            ))
        }

        // Detect orphaned chapters
        let allChapters = cardRepository.fetch(byKind: .chapters)
        let projectChapters = cardRepository.fetchChaptersInProject(project)
        let orphanedChapters = allChapters.filter { chapter in
            !projectChapters.contains(where: { $0.id == chapter.id })
        }
        if !orphanedChapters.isEmpty {
            issues.append(ProjectIssue(
                id: UUID(),
                issueType: .orphanedChapters,
                displayText: "Orphan chapter ×\(orphanedChapters.count)",
                severity: .warning,
                linkedTargets: orphanedChapters.map { $0.id },
                resolutionActions: ["Assign to project", "View chapters"]
            ))
        }

        // TODO: Detect continuity gaps
        // TODO: Detect unresolved citations

        return IssuesShelfModel(issues: issues)
    }

    // MARK: - Thread Shelf

    private func buildThreadShelf(for project: Card) -> ThreadShelfModel {
        // Placeholder: threads not yet implemented
        return ThreadShelfModel(threads: [])
    }
}
