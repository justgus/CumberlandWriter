//
//  BoardBorderOverlay.swift
//  BoardEngine
//
//  Decorative border overlay for the board canvas window frame.
//  Renders a rounded rectangle border with inner shadow.
//

import SwiftUI

// MARK: - Board Border Overlay

/// Decorative border overlay rendered on top of the canvas.
public struct BoardBorderOverlay: View {
    let configuration: BoardConfiguration
    let scheme: ColorScheme

    public init(configuration: BoardConfiguration, scheme: ColorScheme) {
        self.configuration = configuration
        self.scheme = scheme
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: configuration.windowCornerRadius, style: .continuous)
            .stroke(configuration.windowBorderColor(for: scheme), lineWidth: configuration.windowBorderWidth)
            .allowsHitTesting(false)
            .overlay(
                RoundedRectangle(cornerRadius: configuration.windowCornerRadius - 1, style: .continuous)
                    .stroke(configuration.windowInnerShadowColor(for: scheme), lineWidth: 1)
                    .padding(configuration.windowBorderWidth / 2)
                    .allowsHitTesting(false)
            )
    }
}
