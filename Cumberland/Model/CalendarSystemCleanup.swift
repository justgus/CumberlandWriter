import Foundation
import SwiftData

/// Cleanup utility for fixing CalendarSystem relationships created before DR-0065 fix
/// This addresses calendars created when the relationship was improperly configured
class CalendarSystemCleanup {

    /// Fix all existing CalendarSystem objects by recreating them with proper relationship structure
    /// Call this once after updating to DR-0065 fix
    /// - Parameter context: SwiftData model context
    /// - Returns: Number of calendars fixed
    @MainActor
    static func fixExistingCalendarRelationships(context: ModelContext) throws -> Int {
        #if DEBUG
        print("🔧 [CalendarSystemCleanup] Starting cleanup of existing calendar relationships...")
        #endif

        // Fetch all CalendarSystem objects
        let descriptor = FetchDescriptor<CalendarSystem>()
        let calendars = try context.fetch(descriptor)

        #if DEBUG
        print("   Found \(calendars.count) calendar system(s)")
        #endif

        guard !calendars.isEmpty else {
            return 0
        }

        // Store calendar data before deletion
        struct CalendarData {
            let id: UUID
            let name: String
            let description: String?
            let divisions: [TimeDivision]
            let createdAt: Date
            let modifiedAt: Date
            let owningCardID: UUID?
            let timelineIDs: [UUID]
        }

        var calendarDataList: [CalendarData] = []

        // STEP 1: Collect all data and break relationships
        for oldCalendar in calendars {
            #if DEBUG
            print("   Collecting data from: \(oldCalendar.name)")
            #endif

            let data = CalendarData(
                id: oldCalendar.id,
                name: oldCalendar.name,
                description: oldCalendar.calendarDescription,
                divisions: oldCalendar.divisions,
                createdAt: oldCalendar.createdAt,
                modifiedAt: oldCalendar.modifiedAt,
                owningCardID: oldCalendar.calendarCard?.id,
                timelineIDs: (oldCalendar.timelines ?? []).map { $0.id }
            )
            calendarDataList.append(data)

            // Break relationships to allow safe deletion
            if let card = oldCalendar.calendarCard {
                card.calendarSystemRef = nil
            }
            for timeline in (oldCalendar.timelines ?? []) {
                timeline.calendarSystem = nil
            }
        }

        // Save to commit relationship breaks
        try context.save()

        #if DEBUG
        print("   Broke all relationships, now deleting old calendars...")
        #endif

        // STEP 2: Delete all old calendars
        for oldCalendar in calendars {
            context.delete(oldCalendar)
        }

        // Save deletions
        try context.save()

        #if DEBUG
        print("   Deleted old calendars, now recreating with proper structure...")
        #endif

        // STEP 3: Recreate calendars with proper structure
        for data in calendarDataList {
            let newCalendar = CalendarSystem(
                id: data.id,
                name: data.name,
                divisions: data.divisions,
                createdAt: data.createdAt,
                modifiedAt: data.modifiedAt
            )
            newCalendar.calendarDescription = data.description

            context.insert(newCalendar)

            // Restore owning card relationship
            if let cardID = data.owningCardID {
                let cardFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
                if let card = try? context.fetch(cardFetch).first {
                    card.calendarSystemRef = newCalendar
                }
            }

            // Restore timeline relationships
            for timelineID in data.timelineIDs {
                let timelineFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == timelineID })
                if let timeline = try? context.fetch(timelineFetch).first {
                    timeline.calendarSystem = newCalendar
                }
            }

            #if DEBUG
            print("   Recreated: \(data.name)")
            #endif
        }

        // Final save
        try context.save()

        #if DEBUG
        print("✅ [CalendarSystemCleanup] Successfully recreated \(calendarDataList.count) calendar system(s)")
        #endif

        return calendarDataList.count
    }

    /// Remove all orphaned CalendarSystem objects (calendars with no owning card)
    /// Use with caution - this permanently deletes data
    /// - Parameter context: SwiftData model context
    /// - Returns: Number of orphaned calendars deleted
    @MainActor
    static func removeOrphanedCalendars(context: ModelContext) throws -> Int {
        #if DEBUG
        print("🗑️ [CalendarSystemCleanup] Removing orphaned calendar systems...")
        #endif

        let descriptor = FetchDescriptor<CalendarSystem>()
        let calendars = try context.fetch(descriptor)

        var deletedCount = 0

        for calendar in calendars {
            // If no calendar card owns this system, it's orphaned
            if calendar.calendarCard == nil {
                #if DEBUG
                print("   Deleting orphaned calendar: \(calendar.name)")
                #endif
                context.delete(calendar)
                deletedCount += 1
            }
        }

        try context.save()

        #if DEBUG
        print("✅ [CalendarSystemCleanup] Removed \(deletedCount) orphaned calendar(s)")
        #endif

        return deletedCount
    }

    /// Diagnostic: Print all calendar systems and their relationships
    /// - Parameter context: SwiftData model context
    @MainActor
    static func diagnoseCalendarRelationships(context: ModelContext) throws {
        print("🔍 [CalendarSystemCleanup] Diagnosing calendar relationships...")

        let descriptor = FetchDescriptor<CalendarSystem>()
        let calendars = try context.fetch(descriptor)

        print("   Total calendars: \(calendars.count)")
        print("")

        for calendar in calendars {
            print("   📅 Calendar: \(calendar.name)")
            print("      ID: \(calendar.id)")
            print("      Divisions: \(calendar.divisions.count)")
            print("      Owning card: \(calendar.calendarCard?.name ?? "NONE - ORPHANED!")")
            print("      Used by timelines: \(calendar.timelines?.count ?? 0)")
            if let timelines = calendar.timelines, !timelines.isEmpty {
                for timeline in timelines {
                    print("         - \(timeline.name)")
                }
            }
            print("")
        }
    }
}
