//
//  ThemeManager.swift
//  Cumberland
//
//  ER-0037: Theming System
//
//  ObservableObject manager that tracks the active theme and persists the
//  user's choice via UserDefaults. Views read the current theme from the
//  environment; the manager handles theme switching, registry, and
//  user-defined theme management.
//

import SwiftUI
import Combine

/// Manages the active theme and available theme registry.
///
/// Injected into the SwiftUI environment at the app level via
/// `.environmentObject(themeManager)`. Views access the manager via
/// `@EnvironmentObject var themeManager: ThemeManager`.
///
/// ```swift
/// struct MyView: View {
///     @EnvironmentObject private var themeManager: ThemeManager
///
///     var body: some View {
///         let theme = themeManager.currentTheme
///         Text("Hello")
///             .foregroundStyle(theme.colors.textPrimary)
///     }
/// }
/// ```
@MainActor
final class ThemeManager: ObservableObject {

    // MARK: - Theme Registry

    /// All available themes, keyed by their `id`.
    private var themes: [String: any Theme]

    /// Ordered list of available themes for display in the picker.
    /// Built-in themes first, then user themes sorted by display name.
    @Published private(set) var availableThemes: [any Theme]

    /// IDs of built-in themes (cannot be deleted).
    private let builtInIDs: Set<String>

    // MARK: - Persisted Preference

    /// The identifier of the active theme, persisted across launches.
    @Published var themeIdentifier: String

    private static let storageKey = "AppSettings.themeIdentifier"

    // MARK: - Computed

    /// The currently active theme. Falls back to `DefaultTheme` if the
    /// stored identifier doesn't match any registered theme.
    var currentTheme: any Theme {
        themes[themeIdentifier] ?? DefaultTheme()
    }

    /// Whether the given theme ID is a user-defined (deletable) theme.
    func isUserTheme(_ id: String) -> Bool {
        !builtInIDs.contains(id)
    }

    // MARK: - Initialization

    init() {
        let builtIn: [any Theme] = [
            DefaultTheme(),
            WhimsicalTheme(),
            PurpleTheme(),
            HalloweenTheme()
        ]
        let builtInIDs = Set(builtIn.map(\.id))
        self.builtInIDs = builtInIDs

        // Load user themes from disk
        let userThemes = ThemeFileManager.shared.loadUserThemes()

        let allThemes: [any Theme] = builtIn + userThemes
        self.themes = Dictionary(uniqueKeysWithValues: allThemes.map { ($0.id, $0) })
        self.availableThemes = allThemes

        // Restore persisted theme choice (or default)
        self.themeIdentifier = UserDefaults.standard.string(forKey: Self.storageKey) ?? "default"
    }

    // MARK: - Actions

    /// Switch to the theme with the given identifier.
    func setTheme(_ id: String) {
        guard themes[id] != nil else { return }
        themeIdentifier = id
        UserDefaults.standard.set(id, forKey: Self.storageKey)
    }

    /// Add an imported user theme to the registry.
    func addUserTheme(_ theme: UserTheme) {
        themes[theme.id] = theme
        rebuildAvailableThemes()
    }

    /// Remove a user theme by ID. Falls back to Default if the deleted
    /// theme was active.
    func removeUserTheme(id: String) {
        guard isUserTheme(id) else { return }
        themes.removeValue(forKey: id)
        try? ThemeFileManager.shared.deleteTheme(id: id)
        ThemeFileManager.shared.removeCachedImages(forThemeID: id)
        if themeIdentifier == id {
            setTheme("default")
        }
        rebuildAvailableThemes()
    }

    /// Duplicate the current theme as a new user theme with a unique ID.
    func duplicateCurrentTheme() throws {
        let source = currentTheme
        let newID = "\(source.id)-copy-\(Int(Date().timeIntervalSince1970))"
        let newName = "\(source.displayName) (Copy)"
        let duplicate = try ThemeFileManager.shared.duplicateTheme(source, newID: newID, newDisplayName: newName)
        addUserTheme(duplicate)
        setTheme(duplicate.id)
    }

    // MARK: - Private

    private func rebuildAvailableThemes() {
        let builtIn = availableThemes.filter { builtInIDs.contains($0.id) }
        let user = themes.values
            .filter { !builtInIDs.contains($0.id) }
            .sorted { $0.displayName < $1.displayName }
        availableThemes = builtIn + user
    }
}
