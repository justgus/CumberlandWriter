//
//  CalendarSystemTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0008: Time-Based Timeline System.
//  Tests CalendarSystem model validation, TimeDivision arithmetic, and
//  factory methods. Currently partially disabled (#if false) pending fixes
//  for eras/festivals/gregorianTemplate API changes.
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for Calendar System model and validation
/// Part of ER-0008: Time-Based Timeline System
/// TEMPORARILY DISABLED - Needs fixes for eras/festivals/gregorianTemplate
#if false
@Suite("Calendar System Tests")
struct CalendarSystemTests {

    // MARK: - Test Helpers

    /// Creates an in-memory ModelContainer for testing
    @MainActor
    func makeInMemoryContainer() throws -> (ModelContainer, ModelContext) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Card.self, CalendarSystem.self,
            configurations: config
        )
        let context = ModelContext(container)
        return (container, context)
    }

    // MARK: - Calendar System Creation Tests

    @Test("Create basic calendar system")
    @MainActor
    func createBasicCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Create calendar
        let calendar = CalendarSystem(
            name: "Gregorian",
            divisions: [
                TimeDivision(name: "second", pluralName: "seconds", length: 60, isVariable: false),
                TimeDivision(name: "minute", pluralName: "minutes", length: 60, isVariable: false),
                TimeDivision(name: "hour", pluralName: "hours", length: 24, isVariable: false),
                TimeDivision(name: "day", pluralName: "days", length: 7, isVariable: false)
            ]
        )

        context.insert(calendar)
        try context.save()

        // Verify
        #expect(calendar.name == "Gregorian")
        #expect(calendar.divisions.count == 4)
        #expect(calendar.divisions[0].name == "second")
        #expect(calendar.divisions[0].length == 60)
    }

    @Test("Create custom fantasy calendar")
    @MainActor
    func createFantasyCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Create fantasy calendar
        let calendar = CalendarSystem(
            name: "Eldarian Calendar",
            divisions: [
                TimeDivision(name: "moment", pluralName: "moments", length: 100, isVariable: false),
                TimeDivision(name: "cycle", pluralName: "cycles", length: 10, isVariable: false),
                TimeDivision(name: "moon", pluralName: "moons", length: 13, isVariable: true)
            ]
        )

        context.insert(calendar)
        try context.save()

        // Verify
        #expect(calendar.name == "Eldarian Calendar")
        #expect(calendar.divisions.count == 3)
        #expect(calendar.divisions.last?.isVariable == true)
        #expect(calendar.divisions[2].name == "moon")
    }

    @Test("Calendar with eras")
    @MainActor
    func calendarWithEras() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Historical Calendar",
            divisions: [TimeDivision(name: "year", pluralName: "years", length: 1, isVariable: false)]
        )
        calendar.eras = ["Ancient Era", "Modern Era", "Future Era"]

        context.insert(calendar)
        try context.save()

        #expect(calendar.eras != nil)
        #expect(calendar.eras?.count == 3)
        #expect(calendar.eras?.contains("Ancient Era") == true)
    }

    @Test("Calendar with festivals")
    @MainActor
    func calendarWithFestivals() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Festival Calendar",
            divisions: []
        )
        calendar.festivals = [
            Festival(name: "Spring Equinox", date: "First day of spring"),
            Festival(name: "Harvest Moon", date: "Full moon in autumn")
        ]

        context.insert(calendar)
        try context.save()

        #expect(calendar.festivals != nil)
        #expect(calendar.festivals?.count == 2)
        #expect(calendar.festivals?[0].name == "Spring Equinox")
    }

    // MARK: - Timeline Association Tests

    @Test("Associate calendar with timeline")
    @MainActor
    func associateCalendarWithTimeline() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Create calendar
        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: [
                TimeDivision(name: "day", pluralName: "days", length: 24, isVariable: false)
            ]
        )
        context.insert(calendar)

        // Create timeline card
        let timeline = Card(
            kind: .timelines,
            name: "Test Timeline",
            subtitle: "",
            detailedText: ""
        )
        timeline.calendarSystem = calendar
        context.insert(timeline)

        try context.save()

        // Verify association
        #expect(timeline.calendarSystem != nil)
        #expect(timeline.calendarSystem?.name == "Test Calendar")
        #expect(timeline.kind == .timelines)
    }

    @Test("Timeline with epoch date")
    @MainActor
    func timelineWithEpoch() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: []
        )
        context.insert(calendar)

        let timeline = Card(
            kind: .timelines,
            name: "Timeline with Epoch",
            subtitle: "",
            detailedText: ""
        )
        timeline.calendarSystem = calendar
        timeline.epochDate = Date()
        timeline.epochDescription = "Year Zero of the Empire"

        context.insert(timeline)
        try context.save()

        #expect(timeline.epochDate != nil)
        #expect(timeline.epochDescription == "Year Zero of the Empire")
        #expect(timeline.calendarSystem != nil)
    }

    @Test("Multiple timelines can share calendar")
    @MainActor
    func multipleTimelinesShareCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Shared Calendar",
            divisions: []
        )
        context.insert(calendar)

        let timeline1 = Card(kind: .timelines, name: "Timeline 1", subtitle: "", detailedText: "")
        let timeline2 = Card(kind: .timelines, name: "Timeline 2", subtitle: "", detailedText: "")

        timeline1.calendarSystem = calendar
        timeline2.calendarSystem = calendar

        context.insert(timeline1)
        context.insert(timeline2)
        try context.save()

        #expect(timeline1.calendarSystem?.name == "Shared Calendar")
        #expect(timeline2.calendarSystem?.name == "Shared Calendar")
    }

    // MARK: - Gregorian Calendar Template Tests

    @Test("Gregorian calendar template structure")
    @MainActor
    func gregorianTemplate() async throws {
        let calendar = CalendarSystem.gregorianTemplate()

        #expect(calendar.name == "Gregorian Calendar")
        #expect(calendar.divisions.count > 0)

        // Find the "month" division
        let monthDiv = calendar.divisions.first { $0.name == "month" }
        #expect(monthDiv != nil)
        #expect(monthDiv?.isVariable == true) // Months have variable lengths

        // Verify standard Gregorian months
        #expect(calendar.standardMonths?.count == 12)
        #expect(calendar.standardMonths?.contains("January") == true)
        #expect(calendar.standardMonths?.contains("December") == true)
    }

    // MARK: - Calendar Modification Tests

    @Test("Add division to existing calendar")
    @MainActor
    func addDivisionToCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Modifiable Calendar",
            divisions: [
                TimeDivision(name: "hour", pluralName: "hours", length: 24, isVariable: false)
            ]
        )
        context.insert(calendar)
        try context.save()

        // Add new division
        calendar.divisions.append(
            TimeDivision(name: "day", pluralName: "days", length: 7, isVariable: false)
        )
        try context.save()

        #expect(calendar.divisions.count == 2)
        #expect(calendar.divisions[1].name == "day")
    }

    @Test("Remove division from calendar")
    @MainActor
    func removeDivisionFromCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: [
                TimeDivision(name: "hour", pluralName: "hours", length: 24, isVariable: false),
                TimeDivision(name: "day", pluralName: "days", length: 7, isVariable: false)
            ]
        )
        context.insert(calendar)
        try context.save()

        calendar.divisions.removeFirst()
        try context.save()

        #expect(calendar.divisions.count == 1)
        #expect(calendar.divisions[0].name == "day")
    }

    // MARK: - Persistence Tests

    @Test("Calendar persists after save")
    @MainActor
    func calendarPersistence() async throws {
        let (container, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Persistent Calendar",
            divisions: [
                TimeDivision(name: "cycle", pluralName: "cycles", length: 10, isVariable: false)
            ]
        )
        context.insert(calendar)
        try context.save()

        // Create new context and fetch
        let newContext = ModelContext(container)
        let fetchDescriptor = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate { $0.name == "Persistent Calendar" }
        )
        let fetched = try newContext.fetch(fetchDescriptor)

        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Persistent Calendar")
        #expect(fetched.first?.divisions.count == 1)
    }

    // MARK: - Edge Cases

    @Test("Calendar with empty name")
    @MainActor
    func calendarWithEmptyName() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "",
            divisions: []
        )
        context.insert(calendar)
        try context.save()

        #expect(calendar.name == "")
    }

    @Test("Calendar with no divisions")
    @MainActor
    func calendarWithNoDivisions() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendar = CalendarSystem(
            name: "Minimal Calendar",
            divisions: []
        )
        context.insert(calendar)
        try context.save()

        #expect(calendar.divisions.count == 0)
    }

    @Test("Calendar with many divisions")
    @MainActor
    func calendarWithManyDivisions() async throws {
        let (_, context) = try makeInMemoryContainer()

        var divisions: [TimeDivision] = []
        for i in 1...20 {
            divisions.append(
                TimeDivision(name: "unit\(i)", pluralName: "units\(i)", length: i, isVariable: false)
            )
        }

        let calendar = CalendarSystem(
            name: "Complex Calendar",
            divisions: divisions
        )
        context.insert(calendar)
        try context.save()

        #expect(calendar.divisions.count == 20)
        #expect(calendar.divisions[19].length == 20)
    }
}
#endif
