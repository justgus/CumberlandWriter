//
//  CalendarSystemExtractor.swift
//  Cumberland
//
//  Phase 7: ER-0010 + ER-0008 Integration - Calendar Extraction
//  Extracts calendar systems from scene/timeline descriptions using AI
//

import Foundation

/// Extracts calendar system definitions from natural language text
/// Phase 7 (ER-0010 + ER-0008)
class CalendarSystemExtractor {

    // MARK: - Data Structures

    /// A detected calendar system
    struct DetectedCalendar: Identifiable, Codable {
        let id = UUID()
        let name: String
        let monthNames: [String]
        let daysPerMonth: Int?  // nil if variable/not specified
        let dayNames: [String]?
        let daysPerWeek: Int?
        let monthsPerYear: Int
        let eraName: String?
        let festivals: [Festival]?
        let confidence: Double
        let context: String  // The text where this calendar was described

        struct Festival: Codable {
            let name: String
            let description: String?
            let timing: String  // e.g., "last day of Dark-Moon"
        }

        enum CodingKeys: String, CodingKey {
            case name, monthNames, daysPerMonth, dayNames, daysPerWeek
            case monthsPerYear, eraName, festivals, confidence, context
        }
    }

    // MARK: - Properties

    private let provider: AIProviderProtocol

    // MARK: - Initialization

    init(provider: AIProviderProtocol) {
        self.provider = provider
    }

    // MARK: - Public API

    /// Extract calendar systems from text
    /// - Parameters:
    ///   - text: The text to analyze
    /// - Returns: Array of detected calendars with confidence scores
    func extractCalendars(from text: String) async throws -> [DetectedCalendar] {
        #if DEBUG
        print("📅 [CalendarSystemExtractor] Extracting calendars from text...")
        print("   Text length: \(text.count) characters")
        #endif

        // Call AI provider for calendar extraction
        let result = try await provider.analyzeText(text, for: .calendarExtraction)

        #if DEBUG
        print("   Received response from AI provider")
        #endif

        // Convert CalendarStructure(s) to DetectedCalendar format
        var calendars: [DetectedCalendar] = []

        if let calendarStructures = result.calendars {
            for calendarStructure in calendarStructures {
                let detected = convertToDetectedCalendar(calendarStructure, context: text)
                calendars.append(detected)
            }
        }

        #if DEBUG
        print("✅ [CalendarSystemExtractor] Extracted \(calendars.count) calendar systems")
        for calendar in calendars {
            print("   - \(calendar.name): \(calendar.monthsPerYear) months, confidence: \(Int(calendar.confidence * 100))%")
        }
        #endif

        return calendars
    }

    // MARK: - Private Helpers

    /// Convert CalendarStructure to DetectedCalendar format
    private func convertToDetectedCalendar(_ structure: CalendarStructure, context: String) -> DetectedCalendar {
        // Extract information from time divisions
        // TimeDivisionData describes categories (e.g., "month", "day"), not individual members
        var daysPerMonth: Int? = nil
        var daysPerWeek: Int? = nil
        var monthsPerYear: Int = 12  // Default

        for division in structure.divisions {
            let divisionName = division.name.lowercased()

            // Extract days per month
            if divisionName.contains("month") {
                if let length = division.length {
                    daysPerMonth = length
                }
            }
            // Extract days per week
            else if divisionName.contains("week") || divisionName.contains("day") {
                if let length = division.length {
                    if divisionName.contains("week") {
                        daysPerWeek = length
                    }
                }
            }
            // Try to determine number of months per year
            else if divisionName.contains("year") {
                if let length = division.length {
                    monthsPerYear = length
                }
            }
        }

        // Convert festivals from AIProviderProtocol.Festival to DetectedCalendar.Festival
        var detectedFestivals: [DetectedCalendar.Festival]? = nil
        if let structureFestivals = structure.festivals, !structureFestivals.isEmpty {
            detectedFestivals = structureFestivals.map { f in
                DetectedCalendar.Festival(
                    name: f.name,
                    description: nil,  // AIProviderProtocol.Festival doesn't have description
                    timing: f.date ?? "Not specified"  // Use 'date' field as timing
                )
            }
        }

        // Use first era name if available
        let eraName = structure.eras?.first

        // Note: Month names and day names are not extracted from TimeDivisionData
        // These would need to come from the original text analysis or be added manually
        return DetectedCalendar(
            name: structure.name ?? "Untitled Calendar",
            monthNames: [],  // Not available from TimeDivisionData structure
            daysPerMonth: daysPerMonth,
            dayNames: nil,   // Not available from TimeDivisionData structure
            daysPerWeek: daysPerWeek,
            monthsPerYear: monthsPerYear,
            eraName: eraName,
            festivals: detectedFestivals,
            confidence: structure.confidence,
            context: String(context.prefix(200))
        )
    }
}
