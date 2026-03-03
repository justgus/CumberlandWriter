//
//  ThemeBackgroundView.swift
//  Cumberland
//
//  ER-0037 Phase 2: Background Image Support
//
//  A view modifier that overlays an optional themed background image
//  behind content. The image is tiled at low opacity for a subtle
//  texture effect. On visionOS, background images are suppressed
//  entirely — materials take precedence for spatial depth perception.
//

import SwiftUI

// MARK: - ThemeBackgroundModifier

/// Applies a themed background image overlay to a view.
///
/// Usage:
/// ```swift
/// myView.themeBackground(\.sidebarBackground)
/// ```
///
/// The modifier reads the current theme's `backgroundImages` to find
/// the asset name for the requested surface. If `nil`, no overlay is added.
/// On visionOS, the overlay is always suppressed.
struct ThemeBackgroundModifier: ViewModifier {
    let imageName: String?

    /// Rendering mode: `.tile` for repeating textures, `.stretch` for
    /// hero/watermark images that scale to fill.
    let mode: ThemeBackgroundMode

    /// Opacity of the background image overlay.
    let opacity: Double

    func body(content: Content) -> some View {
        content.background { backgroundImage }
    }

    @ViewBuilder
    private var backgroundImage: some View {
        #if os(visionOS)
        // visionOS: suppress background images — materials required for spatial depth
        EmptyView()
        #else
        if let imageName {
            switch mode {
            case .tile:
                Image(imageName)
                    .resizable(resizingMode: .tile)
                    .opacity(opacity)
                    .ignoresSafeArea()
            case .stretch:
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .opacity(opacity)
                    .ignoresSafeArea()
            }
        }
        #endif
    }
}

// MARK: - ThemeBackgroundMode

enum ThemeBackgroundMode {
    /// Repeating tiled texture (sidebar, content area, canvas backgrounds).
    case tile
    /// Stretched/scaled image (hero images, watermarks, decorative art).
    case stretch
}

// MARK: - View Extension

extension View {
    /// Applies a themed background image overlay using a keypath into
    /// `ThemeBackgroundImages`.
    ///
    /// - Parameters:
    ///   - keyPath: KeyPath into `ThemeBackgroundImages` selecting the
    ///     asset name for this surface (e.g., `\.sidebarBackground`).
    ///   - mode: `.tile` for repeating textures (default), `.stretch` for
    ///     hero/watermark images.
    ///   - opacity: Opacity of the image overlay. Default `0.15` for subtle texture.
    ///   - theme: The current theme to read background images from.
    func themeBackground(
        _ keyPath: KeyPath<ThemeBackgroundImages, String?>,
        mode: ThemeBackgroundMode = .tile,
        opacity: Double = 0.15,
        theme: any Theme
    ) -> some View {
        modifier(ThemeBackgroundModifier(
            imageName: theme.backgroundImages[keyPath: keyPath],
            mode: mode,
            opacity: opacity
        ))
    }
}
