import Foundation
import SwiftData

/// Calendar System model for custom time measurement
/// Part of ER-0008: Time-Based Timeline System with Custom Calendars
///
/// Represents a complete time system with hierarchical divisions
/// (e.g., moments → cycles → days → months → years → eras)
@Model
final class CalendarSystem {

    // MARK: - Identity

    /// Unique identifier
    var id: UUID

    /// Calendar name (e.g., "Gregorian", "Eldarian Calendar")
    var name: String

    /// Optional description of the calendar system
    var calendarDescription: String?

    // MARK: - Time Structure

    /// Hierarchical time divisions (ordered from smallest to largest)
    /// Examples: [second, minute, hour, day, week, month, year]
    /// or [moment, cycle, day, moon, year, age]
    var divisions: [TimeDivision]

    // MARK: - Metadata

    /// When this calendar was created
    var createdAt: Date

    /// Last modification date
    var modifiedAt: Date

    // MARK: - Relationships

    /// Timelines using this calendar system
    @Relationship(inverse: \Card.calendarSystem)
    var timelines: [Card]?

    // MARK: - Initialization

    init(id: UUID = UUID(), name: String, divisions: [TimeDivision]) {
        self.id = id
        self.name = name
        self.divisions = divisions
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // MARK: - Validation

    /// Validate calendar structure
    /// Returns nil if valid, error message if invalid
    func validate() -> String? {
        // Check for at least one division
        guard !divisions.isEmpty else {
            return "Calendar must have at least one time division"
        }

        // Check for duplicate division names
        let names = divisions.map { $0.name }
        let uniqueNames = Set(names)
        if names.count != uniqueNames.count {
            return "Calendar has duplicate division names"
        }

        // Check for reasonable division lengths
        for division in divisions {
            if division.length < 1 {
                return "Division '\(division.name)' has invalid length: \(division.length)"
            }
            if division.length > 10000 {
                return "Division '\(division.name)' length is unreasonably large: \(division.length)"
            }
        }

        return nil // Valid
    }

    /// Check if this calendar is valid
    var isValid: Bool {
        validate() == nil
    }

    // MARK: - Calendar Calculations

    /// Calculate total smallest units in one largest unit
    /// Example: For Gregorian, seconds in a year
    func smallestUnitsInLargestUnit() -> Int? {
        guard divisions.count >= 2 else {
            return nil
        }

        var total = 1
        for division in divisions.dropFirst() {
            total *= division.length
        }

        return total
    }

    /// Get a division by name
    func division(named name: String) -> TimeDivision? {
        divisions.first { $0.name == name || $0.pluralName == name }
    }

    /// Get the smallest division (e.g., "second" or "moment")
    var smallestDivision: TimeDivision? {
        divisions.first
    }

    /// Get the largest division (e.g., "year" or "age")
    var largestDivision: TimeDivision? {
        divisions.last
    }
}

// MARK: - Time Division

/// A single division in a calendar system
/// Example: "day" with 24 hours, "month" with 28-31 days
struct TimeDivision: Codable, Hashable, Identifiable {

    /// Unique identifier
    var id: UUID = UUID()

    /// Singular name (e.g., "day", "moon", "cycle")
    var name: String

    /// Plural name (e.g., "days", "moons", "cycles")
    var pluralName: String

    /// Number of subdivisions in this division
    /// Example: day has 24 hours, hour has 60 minutes
    var length: Int

    /// Whether length is variable (e.g., months have 28-31 days)
    var isVariable: Bool

    // MARK: - Display

    /// Get appropriate name based on count
    func displayName(count: Int) -> String {
        count == 1 ? name : pluralName
    }
}

// MARK: - Extensions

extension CalendarSystem {
    /// Create a standard Gregorian calendar
    static func gregorian() -> CalendarSystem {
        CalendarSystem(
            name: "Gregorian",
            divisions: [
                TimeDivision(name: "second", pluralName: "seconds", length: 60, isVariable: false),
                TimeDivision(name: "minute", pluralName: "minutes", length: 60, isVariable: false),
                TimeDivision(name: "hour", pluralName: "hours", length: 24, isVariable: false),
                TimeDivision(name: "day", pluralName: "days", length: 7, isVariable: false),
                TimeDivision(name: "week", pluralName: "weeks", length: 4, isVariable: true),
                TimeDivision(name: "month", pluralName: "months", length: 12, isVariable: true),
                TimeDivision(name: "year", pluralName: "years", length: 10, isVariable: false),
                TimeDivision(name: "decade", pluralName: "decades", length: 10, isVariable: false),
                TimeDivision(name: "century", pluralName: "centuries", length: 10, isVariable: false),
                TimeDivision(name: "millennium", pluralName: "millennia", length: 1, isVariable: false)
            ]
        )
    }
}

// MARK: - Comparable Conformance

extension CalendarSystem: Comparable {
    static func < (lhs: CalendarSystem, rhs: CalendarSystem) -> Bool {
        lhs.name < rhs.name
    }
}
