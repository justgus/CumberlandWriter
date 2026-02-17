//
//  BoardConfiguration.swift
//  BoardEngine
//
//  Configurable constants for the board canvas: zoom limits, pan limits,
//  visual appearance (border, corner radius, grid), and shuffle geometry.
//

import SwiftUI

// MARK: - Board Configuration

/// Configuration for a board canvas instance. Provides zoom/pan limits,
/// visual constants, and layout parameters.
public struct BoardConfiguration: Sendable {
    // MARK: - Zoom & Pan Limits

    public var minZoom: Double = 0.01
    public var maxZoom: Double = 2.0
    public var minPan: Double = -1_000_000
    public var maxPan: Double = 1_000_000

    // MARK: - Visual Constants

    public var windowCornerRadius: CGFloat = 18
    public var windowBorderWidth: CGFloat = 12
    public var gridTileSize: CGFloat = 40
    public var gridLineWidth: CGFloat = 0.5

    // MARK: - Shuffle Geometry Constants

    public var shuffleInitialAnchorFactor: CGFloat = 0.35
    public var shuffleInitialNodeSpanFactor: CGFloat = 0.45
    public var shuffleBaseMarginWorldFactor: CGFloat = 0.10
    public var shuffleBaseMarginViewPadding: CGFloat = 8.0
    public var shuffleSpacingMultiplier: CGFloat = 1.15
    public var shuffleRingSeparationMultiplier: CGFloat = 0.75
    public var shuffleRadialJitterWorld: ClosedRange<Double> = -0.06...0.06
    public var shuffleAngularJitter: ClosedRange<Double> = -0.12...0.12

    public init() {}

    /// Default configuration matching Cumberland's Board constants.
    public static let cumberland: BoardConfiguration = {
        var config = BoardConfiguration()
        config.minZoom = 0.01
        config.maxZoom = 2.0
        config.minPan = -1_000_000
        config.maxPan = 1_000_000
        return config
    }()
}

// MARK: - Border Color Helpers

extension BoardConfiguration {
    /// Border color for the canvas window frame.
    public func windowBorderColor(for scheme: ColorScheme) -> Color {
        .secondary.opacity(0.55)
    }

    /// Inner shadow color for the canvas window frame.
    public func windowInnerShadowColor(for scheme: ColorScheme) -> Color {
        .white.opacity(0.18)
    }
}
