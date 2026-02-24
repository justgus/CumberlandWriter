//
//  ThemeManager.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  ObservableObject manager that tracks the active theme and persists the
//  user's choice via UserDefaults. Views read the current theme from the
//  environment; the manager handles theme switching and registry.
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
    private let themes: [String: any Theme]

    /// Ordered list of available themes for display in the picker.
    let availableThemes: [any Theme]

    // MARK: - Persisted Preference

    /// The identifier of the active theme, persisted across launches.
    /// `@Published` ensures SwiftUI re-renders all views that read
    /// from this manager when the theme changes.
    @Published var themeIdentifier: String

    private static let storageKey = "AppSettings.themeIdentifier"

    // MARK: - Computed

    /// The currently active theme. Falls back to `DefaultTheme` if the
    /// stored identifier doesn't match any registered theme.
    var currentTheme: any Theme {
        themes[themeIdentifier] ?? DefaultTheme()
    }

    // MARK: - Initialization

    init() {
        let defaultTheme = DefaultTheme()
        let whimsicalTheme = WhimsicalTheme()

        let allThemes: [any Theme] = [defaultTheme, whimsicalTheme]
        self.themes = Dictionary(uniqueKeysWithValues: allThemes.map { ($0.id, $0) })
        self.availableThemes = allThemes

        // Restore persisted theme choice (or default)
        self.themeIdentifier = UserDefaults.standard.string(forKey: Self.storageKey) ?? "default"
    }

    // MARK: - Actions

    /// Switch to the theme with the given identifier.
    /// - Parameter id: The `Theme.id` to activate.
    func setTheme(_ id: String) {
        guard themes[id] != nil else { return }
        themeIdentifier = id
        UserDefaults.standard.set(id, forKey: Self.storageKey)
    }
}
