//
//  CalendarSystemRepository.swift
//  Cumberland
//
//  Created as part of DR-0193: Complete ER-0022 Phase 2 Migration
//  Repository for CalendarSystem CRUD operations.
//
//  Encapsulates all SwiftData operations for CalendarSystem models, providing
//  platform-independent data access for the timeline calendar feature.
//

import Foundation
import SwiftData

/// Repository for CalendarSystem data access operations.
/// Encapsulates all SwiftData queries and operations for CalendarSystem models.
///
/// **DR-0193**: Separates data access from business logic for platform independence
@Observable
@MainActor
final class CalendarSystemRepository {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// Create a new CalendarSystem and insert it into the context
    /// - Parameters:
    ///   - name: The calendar name
    ///   - divisions: Time divisions for this calendar
    ///   - description: Optional calendar description
    /// - Returns: The newly created calendar
    /// - Throws: SwiftData errors
    @discardableResult
    func createCalendar(
        name: String,
        divisions: [TimeDivision],
        description: String? = nil
    ) throws -> CalendarSystem {
        let calendar = CalendarSystem(name: name, divisions: divisions)
        calendar.calendarDescription = description
        modelContext.insert(calendar)
        try modelContext.save()
        return calendar
    }

    /// Insert an existing CalendarSystem (e.g., from a factory method like CalendarSystem.gregorian())
    /// - Parameter calendar: The calendar to insert
    /// - Returns: The inserted calendar
    /// - Throws: SwiftData errors
    @discardableResult
    func insertCalendar(_ calendar: CalendarSystem) throws -> CalendarSystem {
        modelContext.insert(calendar)
        try modelContext.save()
        return calendar
    }

    /// Delete a CalendarSystem
    /// - Parameter calendar: The calendar to delete
    /// - Throws: SwiftData errors
    func deleteCalendar(_ calendar: CalendarSystem) throws {
        modelContext.delete(calendar)
        try modelContext.save()
    }

    /// Update a calendar's properties
    /// - Parameters:
    ///   - calendar: The calendar to update
    ///   - name: New name (nil = no change)
    ///   - divisions: New divisions (nil = no change)
    ///   - description: New description (nil = no change, empty string = clear)
    /// - Throws: SwiftData errors
    func updateCalendar(
        _ calendar: CalendarSystem,
        name: String? = nil,
        divisions: [TimeDivision]? = nil,
        description: String?? = nil
    ) throws {
        if let name = name {
            calendar.name = name
        }
        if let divisions = divisions {
            calendar.divisions = divisions
        }
        if let description = description {
            calendar.calendarDescription = description
        }
        calendar.modifiedAt = Date()
        try modelContext.save()
    }

    /// Save changes to the context
    /// - Throws: SwiftData errors
    func save() throws {
        try modelContext.save()
    }

    // MARK: - Fetch Operations

    /// Fetch all calendars sorted by name
    /// - Returns: Array of all calendars
    func fetchAllCalendars() -> [CalendarSystem] {
        let fetch = FetchDescriptor<CalendarSystem>(sortBy: [SortDescriptor(\.name, order: .forward)])
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch a calendar by its UUID
    /// - Parameter uuid: The calendar's UUID
    /// - Returns: The calendar, or nil if not found
    func fetchCalendar(byUUID uuid: UUID) -> CalendarSystem? {
        let fetch = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? modelContext.fetch(fetch).first
    }

    /// Fetch calendars by name (partial match)
    /// - Parameter nameFragment: The name fragment to search for
    /// - Returns: Array of matching calendars
    func fetchCalendars(nameContaining nameFragment: String) -> [CalendarSystem] {
        let fetch = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate { calendar in
                calendar.name.localizedStandardContains(nameFragment)
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return (try? modelContext.fetch(fetch)) ?? []
    }

    /// Fetch the Gregorian calendar (if it exists)
    /// - Returns: The Gregorian calendar, or nil if not found
    func fetchGregorianCalendar() -> CalendarSystem? {
        let fetch = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate { $0.name == "Gregorian" }
        )
        return try? modelContext.fetch(fetch).first
    }

    // MARK: - Utility Operations

    /// Count total calendars
    /// - Returns: Number of calendars
    func countAll() -> Int {
        let fetch = FetchDescriptor<CalendarSystem>()
        return (try? modelContext.fetchCount(fetch)) ?? 0
    }

    /// Check if a calendar with the given name already exists
    /// - Parameter name: The calendar name to check
    /// - Returns: True if a calendar with this name exists
    func exists(name: String) -> Bool {
        let fetch = FetchDescriptor<CalendarSystem>(
            predicate: #Predicate { $0.name == name }
        )
        return ((try? modelContext.fetchCount(fetch)) ?? 0) > 0
    }
}
