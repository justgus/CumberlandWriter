//
//  MultiTimelineTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0008: Time-Based Timeline System.
//  Tests multi-timeline functionality including shared CalendarSystem
//  references across multiple timeline cards and scene ordering within
//  each timeline.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for multi-timeline functionality and shared calendars
/// Part of ER-0008: Time-Based Timeline System
@Suite("Multi-Timeline Tests")
struct MultiTimelineTests {

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

    // MARK: - Shared Calendar Tests

    @Test("Two timelines share calendar")
    @MainActor
    func twoTimelinesShareCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Shared Calendar",
            divisions: [
                TimeDivision(name: "day", pluralName: "days", length: 24, isVariable: false)
            ]
        )
        context.insert(calendar)

        let timeline1 = Card(kind: .timelines, name: "Timeline A", subtitle: "", detailedText: "")
        let timeline2 = Card(kind: .timelines, name: "Timeline B", subtitle: "", detailedText: "")

        timeline1.calendarSystem = calendar
        timeline2.calendarSystem = calendar

        context.insert(timeline1)
        context.insert(timeline2)
        try context.save()

        #expect(timeline1.calendarSystem?.name == "Shared Calendar")
        #expect(timeline2.calendarSystem?.name == "Shared Calendar")
    }

    @Test("Multiple timelines with different epochs on same calendar")
    @MainActor
    func differentEpochsSameCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Common Calendar",
            divisions: []
        )
        context.insert(calendar)

        let epoch1 = Date(timeIntervalSince1970: 0)
        let epoch2 = Date(timeIntervalSince1970: 1000000000)

        let timeline1 = Card(kind: .timelines, name: "Ancient Timeline", subtitle: "", detailedText: "")
        timeline1.calendarSystem = calendar
        timeline1.epochDate = epoch1
        timeline1.epochDescription = "The Beginning"

        let timeline2 = Card(kind: .timelines, name: "Modern Timeline", subtitle: "", detailedText: "")
        timeline2.calendarSystem = calendar
        timeline2.epochDate = epoch2
        timeline2.epochDescription = "The Awakening"

        context.insert(timeline1)
        context.insert(timeline2)
        try context.save()

        #expect(timeline1.epochDate?.timeIntervalSince1970 == 0)
        #expect(timeline2.epochDate?.timeIntervalSince1970 == 1000000000)
        #expect(timeline1.calendarSystem === timeline2.calendarSystem)
    }

    // MARK: - Parallel Events Tests

    @Test("Scenes on different timelines at same time")
    @MainActor
    func parallelScenes() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let calendar = CalendarSystem(name: "Shared Calendar", divisions: [])
        context.insert(calendar)

        let epoch = Date(timeIntervalSince1970: 0)

        let timeline1 = Card(kind: .timelines, name: "Timeline 1", subtitle: "", detailedText: "")
        timeline1.calendarSystem = calendar
        timeline1.epochDate = epoch

        let timeline2 = Card(kind: .timelines, name: "Timeline 2", subtitle: "", detailedText: "")
        timeline2.calendarSystem = calendar
        timeline2.epochDate = epoch

        context.insert(timeline1)
        context.insert(timeline2)

        let scene1 = Card(kind: .scenes, name: "Scene A", subtitle: "", detailedText: "")
        let scene2 = Card(kind: .scenes, name: "Scene B", subtitle: "", detailedText: "")

        context.insert(scene1)
        context.insert(scene2)

        // Same temporal position on different timelines
        let sameTime = Date(timeIntervalSince1970: 1000)

        let edge1 = CardEdge(from: scene1, to: timeline1, type: relType)
        edge1.temporalPosition = sameTime

        let edge2 = CardEdge(from: scene2, to: timeline2, type: relType)
        edge2.temporalPosition = sameTime

        context.insert(edge1)
        context.insert(edge2)
        try context.save()

        #expect(edge1.temporalPosition?.timeIntervalSince1970 == edge2.temporalPosition?.timeIntervalSince1970)
    }

    // MARK: - Timeline Querying Tests

    @Test("Fetch all timelines with same calendar")
    @MainActor
    func fetchTimelinesWithSameCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(name: "Query Calendar", divisions: [])
        context.insert(calendar)

        let timeline1 = Card(kind: .timelines, name: "TL1", subtitle: "", detailedText: "")
        let timeline2 = Card(kind: .timelines, name: "TL2", subtitle: "", detailedText: "")
        let timeline3 = Card(kind: .timelines, name: "TL3", subtitle: "", detailedText: "")

        timeline1.calendarSystem = calendar
        timeline2.calendarSystem = calendar
        // timeline3 has no calendar

        context.insert(timeline1)
        context.insert(timeline2)
        context.insert(timeline3)
        try context.save()

        // Query timelines with this calendar
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.kindRaw == "Timelines" && card.calendarSystem != nil
            }
        )
        let results = try context.fetch(descriptor)

        #expect(results.count >= 2) // At least timeline1 and timeline2
    }

    @Test("Query scenes across multiple timelines")
    @MainActor
    func queryScenesAcrossTimelines() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline1 = Card(kind: .timelines, name: "TL1", subtitle: "", detailedText: "")
        let timeline2 = Card(kind: .timelines, name: "TL2", subtitle: "", detailedText: "")

        context.insert(timeline1)
        context.insert(timeline2)

        let scene1 = Card(kind: .scenes, name: "Scene 1", subtitle: "", detailedText: "")
        let scene2 = Card(kind: .scenes, name: "Scene 2", subtitle: "", detailedText: "")
        let scene3 = Card(kind: .scenes, name: "Scene 3", subtitle: "", detailedText: "")

        context.insert(scene1)
        context.insert(scene2)
        context.insert(scene3)

        // Distribute scenes across timelines
        let edge1 = CardEdge(from: scene1, to: timeline1, type: relType)
        let edge2 = CardEdge(from: scene2, to: timeline1, type: relType)
        let edge3 = CardEdge(from: scene3, to: timeline2, type: relType)

        context.insert(edge1)
        context.insert(edge2)
        context.insert(edge3)
        try context.save()

        // Query all edges
        let descriptor = FetchDescriptor<CardEdge>()
        let edges = try context.fetch(descriptor)

        #expect(edges.count == 3)
    }

    // MARK: - Edge Cases

    @Test("Timeline without calendar can still have scenes")
    @MainActor
    func timelineWithoutCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline = Card(kind: .timelines, name: "Ordinal Timeline", subtitle: "", detailedText: "")
        // No calendar assigned
        context.insert(timeline)

        let scene = Card(kind: .scenes, name: "Scene", subtitle: "", detailedText: "")
        context.insert(scene)

        let edge = CardEdge(from: scene, to: timeline, type: relType)
        context.insert(edge)
        try context.save()

        #expect(timeline.calendarSystem == nil)
        #expect(edge.from?.name == "Scene")
        #expect(edge.to?.name == "Ordinal Timeline")
    }

    @Test("Many timelines sharing single calendar")
    @MainActor
    func manyTimelinesOneCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(name: "Universal Calendar", divisions: [])
        context.insert(calendar)

        // Create 10 timelines
        for i in 1...10 {
            let timeline = Card(kind: .timelines, name: "Timeline \(i)", subtitle: "", detailedText: "")
            timeline.calendarSystem = calendar
            context.insert(timeline)
        }

        try context.save()

        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { $0.kindRaw == "Timelines" }
        )
        let timelines = try context.fetch(descriptor)

        #expect(timelines.count >= 10)
        // All should share the same calendar
        for timeline in timelines where timeline.calendarSystem != nil {
            #expect(timeline.calendarSystem?.name == "Universal Calendar")
        }
    }

    @Test("Timeline with calendar then calendar deleted")
    @MainActor
    func timelineAfterCalendarDeletion() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(name: "Temporary Calendar", divisions: [])
        context.insert(calendar)

        let timeline = Card(kind: .timelines, name: "Timeline", subtitle: "", detailedText: "")
        timeline.calendarSystem = calendar
        context.insert(timeline)
        try context.save()

        #expect(timeline.calendarSystem != nil)

        // Delete calendar
        context.delete(calendar)
        try context.save()

        #expect(timeline.calendarSystem == nil)
    }

    @Test("Same scene appears on multiple timelines")
    @MainActor
    func sceneOnMultipleTimelines() async throws {
        let (_, context) = try makeInMemoryContainer()

        let relType = RelationType(code: "appears-in/features", forwardLabel: "appears in", inverseLabel: "features")
        context.insert(relType)

        let timeline1 = Card(kind: .timelines, name: "Timeline 1", subtitle: "", detailedText: "")
        let timeline2 = Card(kind: .timelines, name: "Timeline 2", subtitle: "", detailedText: "")
        let scene = Card(kind: .scenes, name: "Shared Scene", subtitle: "", detailedText: "")

        context.insert(timeline1)
        context.insert(timeline2)
        context.insert(scene)

        // Same scene on both timelines
        let edge1 = CardEdge(from: scene, to: timeline1, type: relType)
        let edge2 = CardEdge(from: scene, to: timeline2, type: relType)

        context.insert(edge1)
        context.insert(edge2)
        try context.save()

        // Query edges for this scene
        let descriptor = FetchDescriptor<CardEdge>(
            predicate: #Predicate<CardEdge> { edge in
                edge.from?.name == "Shared Scene"
            }
        )
        let edges = try context.fetch(descriptor)

        #expect(edges.count == 2)
    }
}
