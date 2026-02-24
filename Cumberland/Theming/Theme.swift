//
//  Theme.swift
//  Cumberland
//
//  ER-0037: Theming System — Whimsical Skin
//
//  Protocol defining the contract for a Cumberland theme. Each theme
//  provides a complete set of semantic design tokens. Views read tokens
//  from the environment rather than hardcoding visual values.
//

import SwiftUI

/// A complete visual theme for the Cumberland app.
///
/// Conforming types provide semantic design tokens that views consume
/// via `@Environment(\.theme)`. The `DefaultTheme` matches the current
/// app appearance exactly (zero regression). Additional themes (e.g.,
/// `WhimsicalTheme`) override tokens to change the visual presentation.
protocol Theme: Sendable {
    /// Unique identifier used for persistence (`@AppStorage`).
    var id: String { get }

    /// Human-readable name shown in the theme picker.
    var displayName: String { get }

    /// Semantic color tokens.
    var colors: ThemeColors { get }

    /// Semantic font tokens.
    var fonts: ThemeFonts { get }

    /// Semantic shape tokens.
    var shapes: ThemeShapes { get }

    /// Semantic shadow tokens.
    var shadows: ThemeShadows { get }

    /// Semantic spacing tokens.
    var spacing: ThemeSpacing { get }
}
