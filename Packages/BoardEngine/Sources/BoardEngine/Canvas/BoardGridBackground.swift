//
//  BoardGridBackground.swift
//  BoardEngine
//
//  Dot-grid / line-grid background for the board canvas. Renders primary
//  and secondary grid lines at configurable intervals and opacities.
//

import SwiftUI

// MARK: - Grid Background

/// A tiled grid background for the board canvas.
public struct BoardGridBackground: View {
    public let tileSize: CGFloat
    public let lineWidth: CGFloat
    public let primaryOpacity: Double
    public let secondaryEvery: Int
    public let secondaryOpacity: Double

    public init(
        tileSize: CGFloat = 40,
        lineWidth: CGFloat = 0.5,
        primaryOpacity: Double = 0.10,
        secondaryEvery: Int = 5,
        secondaryOpacity: Double = 0.14
    ) {
        self.tileSize = tileSize
        self.lineWidth = lineWidth
        self.primaryOpacity = primaryOpacity
        self.secondaryEvery = secondaryEvery
        self.secondaryOpacity = secondaryOpacity
    }

    public var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let primaryColor = Color.primary.opacity(primaryOpacity)
            let secondaryColor = Color.primary.opacity(secondaryOpacity)

            let paths = makeGridPaths(size: size,
                                      tile: tileSize,
                                      secondaryEvery: max(1, secondaryEvery))

            ZStack {
                paths.primary
                    .stroke(primaryColor, lineWidth: lineWidth)
                paths.secondary
                    .stroke(secondaryColor, lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func makeGridPaths(size: CGSize, tile: CGFloat, secondaryEvery: Int) -> (primary: Path, secondary: Path) {
        var primary = Path()
        var secondary = Path()

        var x: CGFloat = 0
        var column = 0
        while x <= size.width + 0.5 {
            if (column % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: x, y: 0))
                secondary.addLine(to: CGPoint(x: x, y: size.height))
            } else {
                primary.move(to: CGPoint(x: x, y: 0))
                primary.addLine(to: CGPoint(x: x, y: size.height))
            }
            x += tile
            column += 1
        }

        var y: CGFloat = 0
        var row = 0
        while y <= size.height + 0.5 {
            if (row % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: 0, y: y))
                secondary.addLine(to: CGPoint(x: size.width, y: y))
            } else {
                primary.move(to: CGPoint(x: 0, y: y))
                primary.addLine(to: CGPoint(x: size.width, y: y))
            }
            y += tile
            row += 1
        }

        return (primary, secondary)
    }
}
