//
//  ThemeEnvironment.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  Injects the ThemeManager into the SwiftUI view hierarchy using both:
//
//  1. `.environmentObject()` — for Views that use `@EnvironmentObject`.
//     This is the primary mechanism: when `@Published` properties change,
//     SwiftUI automatically re-renders subscribing views.
//
//  2. `.environment(\.themeManager)` — for ViewModifiers and ButtonStyles
//     that cannot use `@EnvironmentObject`. These read the same instance
//     and are re-evaluated because their parent Views re-render.
//

import SwiftUI

// MARK: - EnvironmentKey (for ViewModifiers / ButtonStyles)

private struct ThemeManagerKey: EnvironmentKey {
    @MainActor
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    /// Access the ThemeManager in ViewModifiers and ButtonStyles.
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject the ThemeManager into the view hierarchy.
    ///
    /// Call this once at the app level (on the root `ContentView`).
    /// Sets both `.environmentObject` (for Views) and
    /// `.environment(\.themeManager)` (for ViewModifiers/ButtonStyles).
    func themeEnvironment(_ themeManager: ThemeManager) -> some View {
        self
            .environmentObject(themeManager)
            .environment(\.themeManager, themeManager)
    }
}
