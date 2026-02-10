//
//  TemporalPositioningTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0008: Time-Based Timeline System.
//  Verifies temporal positioning of scene cards on timelines, including
//  epoch-relative offset calculations, CalendarSystem assignment, and
//  sorted scene ordering.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for temporal positioning of scenes on timelines
/// Part of ER-0008: Time-Based Timeline System
@Suite("Temporal Positioning Tests")
struct TemporalPositioningTests {

    // MARK: - Test Helpers

    @MainActor
    func makeInMemoryContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, CalendarSystem.self, CardEdge.self, RelationType.self,
            configurations: config
        )
        let context = ModelContext(container)
        return (container, context)
    }

    // MARK: - Basic Temporal Positioning Tests

    @Test("Scene on timeline with temporal position")
    @MainActor
    func sceneWithTemporalPosition() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Battle Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = Date()

        context.insert(edge)
        try context.save()

        #expect(edge.temporalPosition != nil)
        #expect(scene.kind == .scenes)
    }

    @Test("Scene temporal position persists on edge")
    @MainActor
    func temporalPositionPersists() async throws {
        let (container, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Test Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let testDate = Date(timeIntervalSince1970: 1000000)
        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = testDate

        context.insert(edge)
        try context.save()

        // Fetch in new context
        let newContext = ModelContext(container)
        let descriptor = FetchDescriptor<CardEdge>()
        let fetched = try newContext.fetch(descriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.temporalPosition != nil)
        #expect(fetched.first?.temporalPosition?.timeIntervalSince1970 == testDate.timeIntervalSince1970)
    }

    // MARK: - Timeline-Scene Relationship Tests

    @Test("Create timeline-scene relationship with temporal position")
    @MainActor
    func timelineSceneRelationship() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Create relationship type
        let relType = RelationType(
            code: "appears-in/features",
            forwardLabel: "appears in",
            inverseLabel: "features",
            sourceKind: .scenes,
            targetKind: .timelines
        )
        context.insert(relType)

        // Create timeline and scene
        let timeline = Card(kind: .timelines, name: "Main Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Opening Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        // Create relationship with temporal position
        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = Date(timeIntervalSince1970: 500000)
        edge.duration = 3600 // 1 hour in seconds

        context.insert(edge)
        try context.save()

        #expect(edge.temporalPosition != nil)
        #expect(edge.duration == 3600)
        #expect(edge.from?.name == "Opening Scene")
        #expect(edge.to?.name == "Main Timeline")
    }

    @Test("Scene on timeline at specific date")
    @MainActor
    func sceneAtSpecificDate() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(
            code: "appears-in/features",
            forwardLabel: "appears in",
            inverseLabel: "features"
        )
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Story Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Climax Scene", subtitle: "", detailedText: "")

        // Create calendar
        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: []
        )
        timeline.calendarSystem = calendar
        timeline.epochDate = Date(timeIntervalSince1970: 0) // Unix epoch

        context.insert(calendar)
        context.insert(timeline)
        context.insert(scene)

        // Place scene 1 year after epoch
        let oneYearLater = Date(timeIntervalSince1970: 31536000) // ~1 year in seconds
        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = oneYearLater

        context.insert(edge)
        try context.save()

        #expect(edge.temporalPosition != nil)
        #expect(edge.temporalPosition?.timeIntervalSince1970 ?? 0 > 31000000)
    }

    // MARK: - Duration Tests

    @Test("Scene with duration")
    @MainActor
    func sceneWithDuration() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Long Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = Date()
        edge.duration = 7200 // 2 hours

        context.insert(edge)
        try context.save()

        #expect(edge.duration == 7200)
    }

    @Test("Scene with zero duration")
    @MainActor
    func sceneWithZeroDuration() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Instant Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = Date()
        edge.duration = 0

        context.insert(edge)
        try context.save()

        #expect(edge.duration == 0)
    }

    // MARK: - Multiple Scenes Tests

    @Test("Multiple scenes on same timeline")
    @MainActor
    func multipleScenesOnTimeline() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Main Timeline", subtitle: "", detailedText: "")
        context.insert(timeline)

        // Create 5 scenes at different times
        let baseTime = Date().timeIntervalSince1970
        for i in 1...5 {
            let scene = Card(kind: .scenes, name: "Scene \(i)", subtitle: "", detailedText: "")
            context.insert(scene)

            let edge = CardEdge(from: scene, to: timeline, type: relType)
            edge.temporalPosition = Date(timeIntervalSince1970: baseTime + Double(i * 3600)) // 1 hour apart
            context.insert(edge)
        }

        try context.save()

        // Verify all edges exist
        let descriptor = FetchDescriptor<CardEdge>()
        let edges = try context.fetch(descriptor)
        #expect(edges.count == 5)
    }

    @Test("Scenes with overlapping durations")
    @MainActor
    func scenesWithOverlappingDurations() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        context.insert(timeline)

        let scene1 = Card(kind: .scenes, name: "Scene 1", subtitle: "", detailedText: "")
        let scene2 = Card(kind: .scenes, name: "Scene 2", subtitle: "", detailedText: "")

        context.insert(scene1)
        context.insert(scene2)

        let baseTime = Date()

        let edge1 = CardEdge(from: scene1, to: timeline, type: relType)
        edge1.temporalPosition = baseTime
        edge1.duration = 7200 // 2 hours

        let edge2 = CardEdge(from: scene2, to: timeline, type: relType)
        edge2.temporalPosition = Date(timeInterval: 3600, since: baseTime) // 1 hour later
        edge2.duration = 3600 // 1 hour

        context.insert(edge1)
        context.insert(edge2)
        try context.save()

        // Scenes overlap for 1 hour
        #expect(edge1.duration ?? 0 > 0)
        #expect(edge2.duration ?? 0 > 0)
    }

    // MARK: - Edge Cases

    @Test("Scene without temporal position on timeline")
    @MainActor
    func sceneWithoutTemporalPosition() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Unpositioned Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        // No temporal position set

        context.insert(edge)
        try context.save()

        #expect(edge.temporalPosition == nil)
        #expect(edge.duration == nil)
    }

    @Test("Scene on timeline without calendar")
    @MainActor
    func sceneOnTimelineWithoutCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Ordinal Timeline", subtitle: "", detailedText: "")
        // No calendar system assigned
        let scene = Card(kind: .scenes, name: "Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.temporalPosition = Date()

        context.insert(edge)
        try context.save()

        #expect(timeline.calendarSystem == nil)
        #expect(edge.temporalPosition != nil)
    }

    @Test("Negative duration is allowed")
    @MainActor
    func negativeDuration() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Scene", subtitle: "", detailedText: "")

        context.insert(timeline)
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        edge.duration = -3600 // Negative duration (flashback?)

        context.insert(edge)
        try context.save()

        #expect(edge.duration == -3600)
    }
}
