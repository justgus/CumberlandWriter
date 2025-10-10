import Foundation
import SwiftData
import SwiftUI

enum ColorSchemePreference: String, Codable, CaseIterable, Hashable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
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
    // Keep a unique row (singleton) so we always edit the same settings
    @Attribute(.unique)
    var singletonKey: String = "AppSettingsSingleton"

    // User-tunable line limits per size category
    var linesCompact: Int
    var linesStandard: Int
    var linesLarge: Int

    // Color scheme preference
    var colorSchemePreferenceRaw: String

    // Persist the last selected settings section (stringly-typed to avoid cross-file enum coupling)
    // Defaults to "Display" to match SettingsSection.display.rawValue.
    var lastSelectedSettingsSectionRaw: String = "Display"

    // Default author for auto-fill in CardEditorView (empty means none)
    var defaultAuthor: String = ""

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
        defaultAuthor: String = ""
    ) {
        self.linesCompact = linesCompact
        self.linesStandard = linesStandard
        self.linesLarge = linesLarge
        self.colorSchemePreferenceRaw = colorSchemePreference.rawValue
        self.lastSelectedSettingsSectionRaw = lastSelectedSettingsSectionRaw
        self.defaultAuthor = defaultAuthor
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
