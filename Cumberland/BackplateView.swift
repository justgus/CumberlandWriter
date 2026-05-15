//
//  BackplateView.swift
//  Cumberland
//
//  Created by Claude on 4/23/26.
//
//  Reusable SwiftUI view component for displaying themed backplate images.
//  Automatically responds to theme changes and light/dark mode.
//

import SwiftUI

/// Displays a decorative backplate image with theme awareness and opacity control
struct BackplateView: View {
    let subject: SubjectType
    let opacity: Double
    var alignment: Alignment = .center
    var heightScale: CGFloat = 0.8 // Default to 80% of parent height
    var widthScale: CGFloat = 1.0 // Default to 100% of parent width (for fill mode)
    var contentMode: ContentMode = .fit // Default to aspect fit

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private let backplateEnum = BackplateEnum()

    var body: some View {
        GeometryReader { geometry in
            if let backplate = loadBackplate() {
                if contentMode == .fill {
                    // Aspect fill: fill configured width percentage
                    let targetWidth = geometry.size.width * widthScale
                    let targetHeight = geometry.size.height

                    backplate
                        .resizable()
                        .aspectRatio(4.0, contentMode: .fill)
                        .opacity(opacity)
                        .frame(width: targetWidth, height: targetHeight, alignment: alignment)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
                        .clipped()
                } else {
                    // Aspect fit: use configured height percentage
                    let imageHeight = geometry.size.height * heightScale
                    let imageWidth = imageHeight * 4.0

                    backplate
                        .resizable()
                        .aspectRatio(4.0, contentMode: .fit)
                        .frame(width: imageWidth, height: imageHeight)
                        .opacity(opacity)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .trailing)
                        .clipped()
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadBackplate() -> Image? {
        // Get current theme type from ThemeManager
        let themeType = backplateEnum.themeTypeFromThemeManager(
            themeManager.currentTheme.id
        )

        // Load backplate for current theme and color scheme
        #if DEBUG
        let img = backplateEnum.getImage(theme: themeType, colorScheme: colorScheme, subject: subject)
        print("themeType: \(themeType), colorScheme: \(colorScheme), subject: \(subject), img: \(String(describing: img))")
        return img
        #else
        return backplateEnum.getImage(
            theme: themeType,
            colorScheme: colorScheme,
            subject: subject
        )
        #endif
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Adds a backplate behind this view with specified subject and opacity
    /// - Parameters:
    ///   - subject: The backplate subject/item to display
    ///   - opacity: Opacity level (0.0 - 1.0)
    ///   - alignment: How to align the backplate (default: .center)
    ///   - heightScale: Height as percentage of parent (default: 0.8 = 80%), only used with .fit mode
    ///   - widthScale: Width as percentage of parent (default: 1.0 = 100%), only used with .fill mode
    ///   - contentMode: How to size the backplate (.fit or .fill, default: .fit)
    /// - Returns: View with backplate in background
    func backplate(_ subject: SubjectType, opacity: Double = 0.15, alignment: Alignment = .center, heightScale: CGFloat = 0.8, widthScale: CGFloat = 1.0, contentMode: ContentMode = .fit) -> some View {
        background {
            BackplateView(subject: subject, opacity: opacity, alignment: alignment, heightScale: heightScale, widthScale: widthScale, contentMode: contentMode)
        }
    }

    /// Adds a kind-appropriate backplate for empty states
    /// - Parameters:
    ///   - kind: The Card kind to display backplate for
    ///   - opacity: Opacity level (0.0 - 1.0), defaults to 0.20 for empty states
    ///   - alignment: How to align the backplate (default: .center)
    /// - Returns: View with kind-appropriate backplate in background
    func emptyStateBackplate(for kind: Kinds, opacity: Double = 0.20, alignment: Alignment = .center) -> some View {
        let subject = BackplateEnum().subjectForKind(kind)
        return background {
            BackplateView(subject: subject, opacity: opacity, alignment: alignment)
        }
    }
}

// MARK: - Preview

#Preview("Backplate Items") {
    VStack(spacing: 20) {
        ForEach(SubjectType.allCases, id: \.self) { subject in
            BackplateView(subject: subject, opacity: 0.25)
                .frame(height: 100)
                .overlay(alignment: .bottomTrailing) {
                    Text(subject.displayName)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(8)
                }
        }
    }
    .padding()
}

#Preview("With Content") {
    ZStack {
        BackplateView(subject: .pen, opacity: 0.15)

        VStack(spacing: 20) {
            Text("Sample Content")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The backplate appears behind this content at low opacity, providing thematic visual interest without interfering with readability.")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
