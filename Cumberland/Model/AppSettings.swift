//
//  AppSettings.swift
//  Cumberland
//
//  SwiftData model for persisted app-wide user preferences (singleton record).
//  Stores color scheme preference, default card size, show-AI-badge toggle,
//  and other display settings. Accessed via a unique singletonKey predicate.
//

import Foundation
import SwiftData
import SwiftUI

enum ColorSchemePreference: String, Codable, CaseIterable, Hashable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .light:  return String(localized: "Light")
        case .dark:   return String(localized: "Dark")
        }
    }

    var resolvedColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@Model
final class AppSettings {
    // Remove unique constraint for CloudKit compatibility
    var singletonKey: String = "AppSettingsSingleton"

    // Add default values at declaration for CloudKit compatibility
    var linesCompact: Int = 1
    var linesStandard: Int = 5
    var linesLarge: Int = 20

    // Provide a default raw value at declaration
    var colorSchemePreferenceRaw: String = ColorSchemePreference.system.rawValue

    // Persist the last selected settings section (stringly-typed to avoid cross-file enum coupling)
    // Defaults to "Display" to match SettingsSection.display.rawValue.
    var lastSelectedSettingsSectionRaw: String = "Display"

    // Default author for auto-fill in CardEditorView (empty means none)
    var defaultAuthor: String = ""

    // Views: Structure Board zoom (persisted)
    // Clamp in UI to a reasonable range; 1.0 = Actual Size
    var structureBoardZoom: Double = 1.0

    var colorSchemePreference: ColorSchemePreference {
        get { ColorSchemePreference(rawValue: colorSchemePreferenceRaw) ?? .system }
        set { colorSchemePreferenceRaw = newValue.rawValue }
    }

    init(
        linesCompact: Int = 1,
        linesStandard: Int = 5,
        linesLarge: Int = 20,
        colorSchemePreference: ColorSchemePreference = .system,
        lastSelectedSettingsSectionRaw: String = "Display",
        defaultAuthor: String = "",
        structureBoardZoom: Double = 1.0
    ) {
        self.linesCompact = linesCompact
        self.linesStandard = linesStandard
        self.linesLarge = linesLarge
        self.colorSchemePreferenceRaw = colorSchemePreference.rawValue
        self.lastSelectedSettingsSectionRaw = lastSelectedSettingsSectionRaw
        self.defaultAuthor = defaultAuthor
        self.structureBoardZoom = structureBoardZoom
    }

    // Convenience: map a SizeCategory to the current configured line limit
    func lineLimit(for sizeCategory: SizeCategory) -> Int {
        switch sizeCategory {
        case .compact:  return linesCompact
        case .standard: return linesStandard
        case .large:    return linesLarge
        }
    }
}

extension AppSettings {
    // Helper to fetch or create the singleton row
    @MainActor
    static func fetchOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
        if let settings = (try? context.fetch(descriptor))?.first {
            return settings
        }
        let created = AppSettings()
        context.insert(created)
        try? context.save()
        return created
    }
}
