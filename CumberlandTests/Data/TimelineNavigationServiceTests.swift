//
//  TimelineNavigationServiceTests.swift
//  CumberlandTests
//
//  Part of Phase 6: Timeline Integration
//  Tests for TimelineNavigationService - timeline-manuscript navigation and out-of-order detection
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Timeline Navigation Service", .serialized)
struct TimelineNavigationServiceTests {

    // MARK: - Test Helpers

    @MainActor
    func makeInMemoryContext() throws -> ModelContext {
        return try TestFixtures.makeIsolatedContext()
    }

    /// Create a project card
    @MainActor
    private func createProject(name: String, context: ModelContext) -> Card {
        let project = Card(kind: .projects, name: name, subtitle: "", detailedText: "")
        context.insert(project)
        return project
    }

    /// Create a timeline card
    @MainActor
    private func createTimeline(name: String, calendarSystem: CalendarSystem? = nil, context: ModelContext) -> Card {
        let timeline = Card(kind: .timelines, name: name, subtitle: "", detailedText: "")
        timeline.calendarSystem = calendarSystem
        context.insert(timeline)
        return timeline
    }

    /// Create Scene → Project edge ("belongs-to/contains-scene")
    @MainActor
    private func linkSceneToProject(scene: Card, project: Card, sortIndex: Double, context: ModelContext) -> CardEdge {
        let relType = TestFixtures.createRelationType(
            code: "belongs-to/contains-scene",
            forward: "belongs to",
            inverse: "contains scene",
            context: context
        )
        let edge = TestFixtures.createEdge(from: scene, to: project, type: relType, context: context)
        edge.sortIndex = sortIndex
        return edge
    }

    /// Create Scene → Timeline edge ("describes/described-by")
    @MainActor
    private func linkSceneToTimeline(scene: Card, timeline: Card, sortIndex: Double? = nil, temporalPosition: Date? = nil, context: ModelContext) -> CardEdge {
        let relType = TestFixtures.createRelationType(
            code: "describes/described-by",
            forward: "describes",
            inverse: "described by",
            context: context
        )
        let edge = TestFixtures.createEdge(from: scene, to: timeline, type: relType, context: context)
        if let sortIndex = sortIndex {
            edge.sortIndex = sortIndex
        }
        if let temporalPosition = temporalPosition {
            edge.temporalPosition = temporalPosition
        }
        return edge
    }

    /// Create Timeline → Project edge ("part-of/has-timeline")
    @MainActor
    private func linkTimelineToProject(timeline: Card, project: Card, context: ModelContext) -> CardEdge {
        let relType = TestFixtures.createRelationType(
            code: "part-of/has-timeline",
            forward: "part of",
            inverse: "has timeline",
            context: context
        )
        return TestFixtures.createEdge(from: timeline, to: project, type: relType, context: context)
    }

    // MARK: - Timeline Discovery Tests

    @Test("Find primary timeline for scene in project")
    @MainActor
    func findPrimaryTimelineForScene() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project = createProject(name: "Test Project", context: context)
        let timeline1 = createTimeline(name: "Timeline A", context: context)
        let timeline2 = createTimeline(name: "Timeline B", context: context)
        let scene = TestFixtures.createSampleScene(name: "Scene 1", context: context)

        let _ = linkTimelineToProject(timeline: timeline1, project: project, context: context)
        let _ = linkTimelineToProject(timeline: timeline2, project: project, context: context)
        let _ = linkSceneToTimeline(scene: scene, timeline: timeline1, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene, timeline: timeline2, sortIndex: 0, context: context)

        try context.save()

        let primaryTimeline = service.findPrimaryTimelineForScene(sceneID: scene.id, projectID: project.id)

        #expect(primaryTimeline != nil)
        // Should return first timeline (by database order)
    }

    @Test("Find all timelines for a scene")
    @MainActor
    func findAllTimelinesForScene() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let timeline1 = createTimeline(name: "Timeline A", context: context)
        let timeline2 = createTimeline(name: "Timeline B", context: context)
        let scene = TestFixtures.createSampleScene(name: "Scene 1", context: context)

        let _ = linkSceneToTimeline(scene: scene, timeline: timeline1, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene, timeline: timeline2, sortIndex: 0, context: context)

        try context.save()

        let timelines = service.findTimelinesForScene(scene)

        #expect(timelines.count == 2)
        let timelineIDs = Set(timelines.map { $0.id })
        #expect(timelineIDs.contains(timeline1.id))
        #expect(timelineIDs.contains(timeline2.id))
    }

    @Test("Find primary timeline filters by project")
    @MainActor
    func findPrimaryTimelineFiltersProject() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project1 = createProject(name: "Project 1", context: context)
        let project2 = createProject(name: "Project 2", context: context)
        let timeline1 = createTimeline(name: "Timeline in Project 1", context: context)
        let timeline2 = createTimeline(name: "Timeline in Project 2", context: context)
        let scene = TestFixtures.createSampleScene(name: "Scene 1", context: context)

        let _ = linkTimelineToProject(timeline: timeline1, project: project1, context: context)
        let _ = linkTimelineToProject(timeline: timeline2, project: project2, context: context)
        let _ = linkSceneToTimeline(scene: scene, timeline: timeline1, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene, timeline: timeline2, sortIndex: 0, context: context)

        try context.save()

        let timelineForProject1 = service.findPrimaryTimelineForScene(sceneID: scene.id, projectID: project1.id)
        let timelineForProject2 = service.findPrimaryTimelineForScene(sceneID: scene.id, projectID: project2.id)

        #expect(timelineForProject1?.id == timeline1.id)
        #expect(timelineForProject2?.id == timeline2.id)
    }

    // MARK: - Scene Positioning Tests

    @Test("Get scene timeline position with temporal data")
    @MainActor
    func getSceneTimelinePositionTemporal() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let timeline = createTimeline(name: "Timeline", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)
        let scene3 = TestFixtures.createSampleScene(name: "Scene 3", context: context)

        let baseTime = Date(timeIntervalSince1970: 1000000)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, temporalPosition: baseTime, context: context)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, temporalPosition: Date(timeInterval: 3600, since: baseTime), context: context)
        let _ = linkSceneToTimeline(scene: scene3, timeline: timeline, temporalPosition: Date(timeInterval: 7200, since: baseTime), context: context)

        try context.save()

        let position = service.getSceneTimelinePosition(scene: scene2, timeline: timeline)

        #expect(position != nil)
        #expect(position?.sceneID == scene2.id)
        #expect(position?.timelineIndex == 1) // Second scene in temporal order
        #expect(position?.temporalPosition != nil)
    }

    @Test("Get scene timeline position with ordinal data")
    @MainActor
    func getSceneTimelinePositionOrdinal() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let timeline = createTimeline(name: "Ordinal Timeline", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)
        let scene3 = TestFixtures.createSampleScene(name: "Scene 3", context: context)

        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, sortIndex: 1, context: context)
        let _ = linkSceneToTimeline(scene: scene3, timeline: timeline, sortIndex: 2, context: context)

        try context.save()

        let position = service.getSceneTimelinePosition(scene: scene3, timeline: timeline)

        #expect(position != nil)
        #expect(position?.sceneID == scene3.id)
        #expect(position?.timelineIndex == 2) // Third scene in ordinal order
        #expect(position?.temporalPosition == nil) // Ordinal mode has no temporal position
    }

    // MARK: - Out-of-Order Detection Tests

    @Test("Detect out-of-order scenes with ordinal timeline")
    @MainActor
    func detectOutOfOrderOrdinalTimeline() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project = createProject(name: "Test Project", context: context)
        let timeline = createTimeline(name: "Timeline", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)
        let scene3 = TestFixtures.createSampleScene(name: "Scene 3", context: context)

        // Manuscript order: Scene 1 (0), Scene 2 (1), Scene 3 (2)
        let _ = linkSceneToProject(scene: scene1, project: project, sortIndex: 0, context: context)
        let _ = linkSceneToProject(scene: scene2, project: project, sortIndex: 1, context: context)
        let _ = linkSceneToProject(scene: scene3, project: project, sortIndex: 2, context: context)

        // Timeline order: Scene 2 (0), Scene 1 (1), Scene 3 (2)
        // Out of order: Scene 1 and Scene 2 are swapped
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, sortIndex: 1, context: context)
        let _ = linkSceneToTimeline(scene: scene3, timeline: timeline, sortIndex: 2, context: context)

        try context.save()

        let discrepancies = service.detectOutOfOrderScenes(project: project, timeline: timeline)

        #expect(discrepancies.count == 2)

        // Scene 1: manuscript index 0, timeline index 1 (earlier in manuscript)
        let scene1Discrepancy = discrepancies.first { $0.sceneID == scene1.id }
        #expect(scene1Discrepancy != nil)
        #expect(scene1Discrepancy?.manuscriptIndex == 0)
        #expect(scene1Discrepancy?.timelineIndex == 1)
        #expect(scene1Discrepancy?.isEarlierInManuscript == true)

        // Scene 2: manuscript index 1, timeline index 0 (later in manuscript)
        let scene2Discrepancy = discrepancies.first { $0.sceneID == scene2.id }
        #expect(scene2Discrepancy != nil)
        #expect(scene2Discrepancy?.manuscriptIndex == 1)
        #expect(scene2Discrepancy?.timelineIndex == 0)
        #expect(scene2Discrepancy?.isEarlierInManuscript == false)
    }

    @Test("Detect out-of-order scenes with temporal timeline")
    @MainActor
    func detectOutOfOrderTemporalTimeline() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: [TimeDivision(name: "day", pluralName: "days", length: 24, isVariable: false)]
        )
        context.insert(calendar)

        let project = createProject(name: "Test Project", context: context)
        let timeline = createTimeline(name: "Timeline", calendarSystem: calendar, context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)
        let scene3 = TestFixtures.createSampleScene(name: "Scene 3", context: context)

        // Manuscript order: Scene 1, Scene 2, Scene 3
        let _ = linkSceneToProject(scene: scene1, project: project, sortIndex: 0, context: context)
        let _ = linkSceneToProject(scene: scene2, project: project, sortIndex: 1, context: context)
        let _ = linkSceneToProject(scene: scene3, project: project, sortIndex: 2, context: context)

        // Timeline order (temporal): Scene 3 (earliest), Scene 1 (middle), Scene 2 (latest)
        let baseTime = Date(timeIntervalSince1970: 1000000)
        let _ = linkSceneToTimeline(scene: scene3, timeline: timeline, temporalPosition: baseTime, context: context)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, temporalPosition: Date(timeInterval: 3600, since: baseTime), context: context)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, temporalPosition: Date(timeInterval: 7200, since: baseTime), context: context)

        try context.save()

        let discrepancies = service.detectOutOfOrderScenes(project: project, timeline: timeline)

        // All three scenes are out of order
        #expect(discrepancies.count == 3)
    }

    @Test("Detect no false positives when scenes are in order")
    @MainActor
    func detectNoFalsePositivesInOrder() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project = createProject(name: "Test Project", context: context)
        let timeline = createTimeline(name: "Timeline", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)
        let scene3 = TestFixtures.createSampleScene(name: "Scene 3", context: context)

        // Manuscript order: Scene 1 (0), Scene 2 (1), Scene 3 (2)
        let _ = linkSceneToProject(scene: scene1, project: project, sortIndex: 0, context: context)
        let _ = linkSceneToProject(scene: scene2, project: project, sortIndex: 1, context: context)
        let _ = linkSceneToProject(scene: scene3, project: project, sortIndex: 2, context: context)

        // Timeline order: Scene 1 (0), Scene 2 (1), Scene 3 (2) - SAME ORDER
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, sortIndex: 1, context: context)
        let _ = linkSceneToTimeline(scene: scene3, timeline: timeline, sortIndex: 2, context: context)

        try context.save()

        let discrepancies = service.detectOutOfOrderScenes(project: project, timeline: timeline)

        #expect(discrepancies.isEmpty)
    }

    @Test("Handle scene on timeline but not in manuscript")
    @MainActor
    func handleSceneOnTimelineNotInManuscript() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project = createProject(name: "Test Project", context: context)
        let timeline = createTimeline(name: "Timeline", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene in Manuscript", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene Only in Timeline", context: context)

        // Scene 1 in both
        let _ = linkSceneToProject(scene: scene1, project: project, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline, sortIndex: 0, context: context)

        // Scene 2 only in timeline (orphaned)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline, sortIndex: 1, context: context)

        try context.save()

        let discrepancies = service.detectOutOfOrderScenes(project: project, timeline: timeline)

        // Scene 2 should not appear in discrepancies (only compares scenes in both)
        #expect(discrepancies.count == 0)
    }

    @Test("Detect out-of-order with multiple timelines")
    @MainActor
    func detectOutOfOrderMultipleTimelines() async throws {
        let context = try makeInMemoryContext()
        let service = TimelineNavigationService(modelContext: context)

        let project = createProject(name: "Test Project", context: context)
        let timeline1 = createTimeline(name: "Timeline 1", context: context)
        let timeline2 = createTimeline(name: "Timeline 2", context: context)
        let scene1 = TestFixtures.createSampleScene(name: "Scene 1", context: context)
        let scene2 = TestFixtures.createSampleScene(name: "Scene 2", context: context)

        // Manuscript order: Scene 1, Scene 2
        let _ = linkSceneToProject(scene: scene1, project: project, sortIndex: 0, context: context)
        let _ = linkSceneToProject(scene: scene2, project: project, sortIndex: 1, context: context)

        // Timeline 1: Scene 2, Scene 1 (out of order)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline1, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline1, sortIndex: 1, context: context)

        // Timeline 2: Scene 1, Scene 2 (in order)
        let _ = linkSceneToTimeline(scene: scene1, timeline: timeline2, sortIndex: 0, context: context)
        let _ = linkSceneToTimeline(scene: scene2, timeline: timeline2, sortIndex: 1, context: context)

        try context.save()

        let discrepancies1 = service.detectOutOfOrderScenes(project: project, timeline: timeline1)
        let discrepancies2 = service.detectOutOfOrderScenes(project: project, timeline: timeline2)

        #expect(discrepancies1.count == 2) // Out of order in timeline 1
        #expect(discrepancies2.isEmpty) // In order in timeline 2
    }
}
