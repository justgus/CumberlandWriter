//
//  CalendarSystemMigrationHelper.swift
//  Cumberland
//
//  Created by Claude Code on 1/27/26.
//  Phase 7.5: Calendar Cards Architecture
//
//  One-time data-migration helper that converts standalone CalendarSystem
//  objects (created before Phase 7.5) into Calendar cards with proper
//  CalendarSystem relationship links. Run once from DeveloperToolsView;
//  safe to call on already-migrated data.
//

import Foundation
import SwiftData

/// One-time migration helper for converting standalone CalendarSystem objects to Calendar cards
/// CloudKit Note: No schema migration needed - CloudKit handles new optional properties automatically
struct CalendarSystemMigrationHelper {

    /// Migrate orphaned CalendarSystem objects to Calendar cards
    /// - Parameter context: ModelContext to perform migration
    /// - Returns: Number of calendars migrated
    @discardableResult
    static func migrateOrphanCalendarSystems(context: ModelContext) -> Int {
        #if DEBUG
        print("📅 [Migration] Starting CalendarSystem → Calendar Card migration")
        #endif

        // Fetch all CalendarSystem objects
        let descriptor = FetchDescriptor<CalendarSystem>()
        guard let allCalendars = try? context.fetch(descriptor) else {
            #if DEBUG
            print("⚠️ [Migration] Failed to fetch CalendarSystem objects")
            #endif
            return 0
        }

        #if DEBUG
        print("   Found \(allCalendars.count) total CalendarSystem objects")
        #endif

        // Filter to orphaned calendars (no calendarCard relationship)
        let orphanedCalendars = allCalendars.filter { $0.calendarCard == nil }

        #if DEBUG
        print("   Found \(orphanedCalendars.count) orphaned calendars to migrate")
        #endif

        var migratedCount = 0

        // Fetch existing calendar cards to avoid duplicates
        let existingCardsFetch = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { $0.kindRaw == "Calendars" }
        )
        let existingCards = (try? context.fetch(existingCardsFetch)) ?? []
        let existingNames = Set(existingCards.map { $0.name })

        for calendar in orphanedCalendars {
            // Skip if a calendar card with this name already exists
            if existingNames.contains(calendar.name) {
                #if DEBUG
                print("   ⏭️  Skipped: \(calendar.name) (card already exists)")
                #endif
                continue
            }

            // Create Calendar card
            let calendarCard = Card(
                kind: .calendars,
                name: calendar.name,
                subtitle: "\(calendar.divisions.count) divisions",
                detailedText: generateCalendarDescription(calendar)
            )

            // Link card to calendar system
            calendarCard.calendarSystemRef = calendar

            // Insert into context
            context.insert(calendarCard)
            migratedCount += 1

            #if DEBUG
            print("   ✅ Migrated: \(calendar.name)")
            #endif
        }

        // Save context
        do {
            try context.save()
            #if DEBUG
            print("✅ [Migration] Successfully migrated \(migratedCount) calendars")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [Migration] Failed to save context: \(error)")
            #endif
        }

        return migratedCount
    }

    /// Generate detailed description for calendar card
    private static func generateCalendarDescription(_ calendar: CalendarSystem) -> String {
        var description = "Calendar system with \(calendar.divisions.count) time divisions:\n\n"

        for (index, division) in calendar.divisions.enumerated() {
            let indent = String(repeating: "  ", count: index)
            description += "\(indent)• \(division.pluralName.capitalized)"
            if index > 0 {
                description += " (\(division.length) \(calendar.divisions[index - 1].pluralName))"
            }
            description += "\n"
        }

        if let calendarDescription = calendar.calendarDescription {
            description += "\n\(calendarDescription)"
        }

        return description
    }
}
