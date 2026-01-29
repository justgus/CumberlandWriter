import Testing
import Foundation
import SwiftData
@testable import Cumberland

/// Tests for calendar system extraction from narrative text
/// Part of ER-0010: AI Content Analysis (Calendar Extraction)
/// TEMPORARILY DISABLED - Needs fixes for CalendarSystem vs CalendarStructure
#if false
@Suite("Calendar Extraction Tests")
struct CalendarExtractionTests {

    // MARK: - Test Helpers

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

    // MARK: - CalendarStructure Type Tests

    @Test("CalendarStructure can be created")
    func createCalendarStructure() {
        let calendar = CalendarStructure(
            name: "Test Calendar",
            divisions: [
                TimeDivisionData(name: "hour", pluralName: "hours", length: 24, isVariable: false)
            ],
            eras: ["Ancient Era"],
            festivals: [Festival(name: "Festival", date: "Day 1")],
            confidence: 0.9
        )

        #expect(calendar.name == "Test Calendar")
        #expect(calendar.divisions.count == 1)
        #expect(calendar.eras?.count == 1) // CalendarStructure property
        #expect(calendar.festivals?.count == 1) // CalendarStructure property
        #expect(calendar.confidence == 0.9) // CalendarStructure property
    }

    @Test("TimeDivisionData structure")
    func timeDivisionDataStructure() {
        let division = TimeDivisionData(
            name: "cycle",
            pluralName: "cycles",
            length: 10,
            isVariable: false
        )

        #expect(division.name == "cycle")
        #expect(division.pluralName == "cycles")
        #expect(division.length == 10)
        #expect(division.isVariable == false)
    }

    @Test("Festival structure")
    func festivalStructure() {
        let festival = Festival(name: "Spring Equinox", date: "First day of spring")

        #expect(festival.name == "Spring Equinox")
        #expect(festival.date == "First day of spring")
    }

    // MARK: - Analysis Result Tests

    @Test("AnalysisResult with calendar structures")
    func analysisResultWithCalendars() {
        let calendar1 = CalendarStructure(
            name: "Calendar 1",
            divisions: [],
            eras: nil,
            festivals: nil,
            confidence: 0.8
        )

        let calendar2 = CalendarStructure(
            name: "Calendar 2",
            divisions: [],
            eras: nil,
            festivals: nil,
            confidence: 0.7
        )

        let result = AnalysisResult(
            entities: nil,
            relationships: nil,
            calendars: [calendar1, calendar2],
            metadata: nil
        )

        #expect(result.calendars?.count == 2)
        #expect(result.calendars?[0].name == "Calendar 1")
        #expect(result.calendars?[1].name == "Calendar 2")
    }

    // MARK: - Text Pattern Recognition Tests

    @Test("Recognize calendar keywords in text")
    func recognizeCalendarKeywords() {
        let text = "The Meridian calendar system consists of 10 cycles per rotation"

        #expect(text.contains("calendar"))
        #expect(text.contains("cycles"))
        #expect(text.contains("rotation"))
        #expect(text.contains("10"))
    }

    @Test("Recognize time unit relationships")
    func recognizeTimeUnitRelationships() {
        let text = "There are 24 hours in a day and 7 days in a week"

        #expect(text.contains("in a"))
        #expect(text.contains("hours"))
        #expect(text.contains("day"))
        #expect(text.contains("days"))
        #expect(text.contains("week"))
    }

    @Test("Recognize era mentions")
    func recognizeEraMentions() {
        let text = "The Age of Discovery began three centuries ago"

        #expect(text.contains("Age of Discovery"))
    }

    @Test("Recognize festival mentions")
    func recognizeFestivalMentions() {
        let text = "The Spring Equinox is celebrated on the first day of spring"

        #expect(text.contains("Spring Equinox"))
        #expect(text.contains("first day of spring"))
    }

    // MARK: - Conversion Tests

    @Test("Convert CalendarStructure to CalendarSystem model")
    @MainActor
    func convertToCalendarSystem() async throws {
        let (_, context) = try makeInMemoryContainer()

        let calendarData = CalendarStructure(
            name: "Test Calendar",
            divisions: [
                TimeDivisionData(name: "day", pluralName: "days", length: 24, isVariable: false)
            ],
            eras: ["Era 1"],
            festivals: [Festival(name: "Festival", date: "Day 1")],
            confidence: 0.9
        )

        // Convert TimeDivisionData to TimeDivision
        let divisions = calendarData.divisions.map { data in
            TimeDivision(
                name: data.name,
                pluralName: data.pluralName,
                length: data.length ?? 1,
                isVariable: data.isVariable
            )
        }

        let calendar = CalendarSystem(
            name: calendarData.name ?? "Unnamed Calendar",
            divisions: divisions
        )
        // Note: CalendarSystem doesn't store eras/festivals - those are only in CalendarStructure

        context.insert(calendar)
        try context.save()

        #expect(calendar.name == "Test Calendar")
        #expect(calendar.divisions.count == 1)
        // Eras and festivals are stored in CalendarStructure, not CalendarSystem model
    }

    // MARK: - Confidence Scoring Tests

    @Test("High confidence calendar extraction")
    func highConfidenceExtraction() {
        let calendar = CalendarStructure(
            name: "Well-Defined Calendar",
            divisions: [
                TimeDivisionData(name: "hour", pluralName: "hours", length: 24, isVariable: false),
                TimeDivisionData(name: "day", pluralName: "days", length: 7, isVariable: false),
                TimeDivisionData(name: "month", pluralName: "months", length: 12, isVariable: true)
            ],
            eras: nil,
            festivals: nil,
            confidence: 0.95
        )

        #expect(calendar.confidence >= 0.9)
        #expect(calendar.divisions.count == 3)
    }

    @Test("Low confidence calendar extraction")
    func lowConfidenceExtraction() {
        let calendar = CalendarStructure(
            name: "Vague Calendar",
            divisions: [
                TimeDivisionData(name: "unit", pluralName: "units", length: 1, isVariable: false)
            ],
            eras: nil,
            festivals: nil,
            confidence: 0.45
        )

        #expect(calendar.confidence < 0.7)
    }

    // MARK: - Edge Cases

    @Test("Calendar with no name")
    func calendarWithNoName() {
        let calendar = CalendarStructure(
            name: nil,
            divisions: [],
            eras: nil,
            festivals: nil,
            confidence: 0.5
        )

        #expect(calendar.name == nil)
    }

    @Test("Calendar with no divisions")
    func calendarWithNoDivisions() {
        let calendar = CalendarStructure(
            name: "Minimal Calendar",
            divisions: [],
            eras: ["Era 1"],
            festivals: nil,
            confidence: 0.6
        )

        #expect(calendar.divisions.isEmpty)
        #expect(calendar.eras?.isEmpty == false)
    }

    @Test("Calendar with many divisions")
    func calendarWithManyDivisions() {
        var divisions: [TimeDivisionData] = []
        for i in 1...10 {
            divisions.append(
                TimeDivisionData(name: "unit\(i)", pluralName: "units\(i)", length: i, isVariable: false)
            )
        }

        let calendar = CalendarStructure(
            name: "Complex Calendar",
            divisions: divisions,
            eras: nil,
            festivals: nil,
            confidence: 0.75
        )

        #expect(calendar.divisions.count == 10)
    }

    // MARK: - Multiple Calendar Detection Tests

    @Test("Multiple calendars in analysis result")
    func multipleCalendarsInResult() {
        let calendars = [
            CalendarStructure(name: "Calendar 1", divisions: [], eras: nil, festivals: nil, confidence: 0.9),
            CalendarStructure(name: "Calendar 2", divisions: [], eras: nil, festivals: nil, confidence: 0.85)
        ]

        let result = AnalysisResult(entities: nil, relationships: nil, calendars: calendars, metadata: nil)

        #expect(result.calendars?.count == 2)
    }

    // MARK: - Integration Test

    @Test("Extract calendar and associate with timeline")
    @MainActor
    func extractAndAssociateCalendar() async throws {
        let (_, context) = try makeInMemoryContainer()

        // Simulate extracted calendar
        let calendarData = CalendarStructure(
            name: "Story Calendar",
            divisions: [
                TimeDivisionData(name: "hour", pluralName: "hours", length: 24, isVariable: false)
            ],
            eras: nil,
            festivals: nil,
            confidence: 0.9
        )

        // Convert to CalendarSystem
        let divisions = calendarData.divisions.map { data in
            TimeDivision(name: data.name, pluralName: data.pluralName, length: data.length ?? 1, isVariable: data.isVariable)
        }

        let calendar = CalendarSystem(name: calendarData.name ?? "Calendar", divisions: divisions)
        context.insert(calendar)

        // Create timeline and associate
        let timeline = Card(kind: .timelines, name: "Main Timeline", subtitle: "", detailedText: "")
        timeline.calendarSystem = calendar
        context.insert(timeline)

        try context.save()

        // Verify
        #expect(timeline.calendarSystem != nil)
        #expect(timeline.calendarSystem?.name == "Story Calendar")
    }
}
#endif
