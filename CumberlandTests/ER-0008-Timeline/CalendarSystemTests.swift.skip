import Testing
import SwiftData
@testable import Cumberland

/// Tests for Calendar System model and validation
/// Part of ER-0008: Time-Based Timeline System
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
    }

    // MARK: - Calendar Validation Tests

    @Test("Validate calendar hierarchy")
    @MainActor
    func validateCalendarHierarchy() async throws {
        // TODO: Implement hierarchy validation logic
        // Should detect circular dependencies
        // Should validate logical ordering
    }

    // MARK: - Gregorian Calendar Template Tests

    @Test("Gregorian calendar template structure")
    @MainActor
    func gregorianTemplate() async throws {
        // TODO: Test pre-populated Gregorian calendar
        // Verify 12 months, correct day counts, etc.
    }

    // MARK: - Timeline Association Tests

    @Test("Associate calendar with timeline")
    @MainActor
    func associateCalendarWithTimeline() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Create calendar
        let calendar = CalendarSystem(
            name: "Test Calendar",
            divisions: []
        )
        context.insert(calendar)

        // Create timeline card
        let timeline = Card(
            kind: .timelines,
            name: "Test Timeline",
            createdAt: Date()
        )
        timeline.calendarSystem = calendar
        context.insert(timeline)

        try context.save()

        // Verify association
        #expect(timeline.calendarSystem != nil)
        #expect(timeline.calendarSystem?.name == "Test Calendar")
    }
}
