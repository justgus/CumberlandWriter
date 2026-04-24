//
//  NarrativeArcVisualization.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-21.
//  Part of Phase 2: Story Structure Integration - Arc Visualization
//
//  Tufte-style narrative arc visualization for Project Dashboard structure band.
//  Line thickness encodes scene density (data-ink ratio principle).
//

import SwiftUI

/// Segment of the narrative arc with scene density information
struct ArcSegment: Identifiable {
    let id = UUID()
    let startPosition: Double // 0.0 to 1.0
    let endPosition: Double // 0.0 to 1.0
    let startTension: Double // 0.0 to 1.0
    let endTension: Double // 0.0 to 1.0
    let sceneCount: Int
    let beatLabel: String?
    let beatID: UUID?
}

/// Tufte-style narrative arc renderer
///
/// Renders a variable-width sparkline where:
/// - Y position encodes narrative tension/complexity
/// - Line thickness encodes scene density (Tufte's data-ink ratio)
/// - Beat markers overlay at key structural points
///
/// Line width mapping:
/// - 0 scenes: 1pt (ghosted gray)
/// - 1 scene: 2pt
/// - 2-3 scenes: 3pt
/// - 4-6 scenes: 4-5pt
/// - 7+ scenes: 6pt+
struct NarrativeArcVisualization: View {
    let arc: NarrativeArc
    let segments: [ArcSegment]
    let activePositionFraction: Double?
    let height: CGFloat
    let highlightedSegmentIndex: Int?
    let onSegmentTap: ((Int) -> Void)?

    @EnvironmentObject private var themeManager: ThemeManager

    private let minLineWidth: CGFloat = 1.0
    private let maxLineWidth: CGFloat = 8.0

    init(
        arc: NarrativeArc,
        segments: [ArcSegment],
        activePositionFraction: Double? = nil,
        height: CGFloat,
        highlightedSegmentIndex: Int? = nil,
        onSegmentTap: ((Int) -> Void)? = nil
    ) {
        self.arc = arc
        self.segments = segments
        self.activePositionFraction = activePositionFraction
        self.height = height
        self.highlightedSegmentIndex = highlightedSegmentIndex
        self.onSegmentTap = onSegmentTap
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas for arc drawing
                Canvas { context, size in
                    // Draw arc segments with variable width
                    for segment in segments {
                        drawArcSegment(
                            segment: segment,
                            in: context,
                            size: size
                        )
                    }

                    // Draw active position marker
                    if let activePosition = activePositionFraction {
                        drawActivePositionMarker(
                            at: activePosition,
                            in: context,
                            size: size
                        )
                    }
                }

                // Interactive beat markers as overlays
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    if segment.beatLabel != nil {
                        beatMarkerButton(
                            at: segment.startPosition,
                            tension: segment.startTension,
                            index: index,
                            size: geometry.size
                        )
                    }
                }
            }
            .frame(height: height)
        }
    }

    private func drawArcSegment(
        segment: ArcSegment,
        in context: GraphicsContext,
        size: CGSize
    ) {
        let resolution = 20 // Points per segment for smooth curves

        // Sample positions along segment
        let positions = (0...resolution).map { i in
            let t = Double(i) / Double(resolution)
            return segment.startPosition + (segment.endPosition - segment.startPosition) * t
        }

        // Create path
        var path = Path()
        var isFirstPoint = true

        for position in positions {
            let tension = arc.tension(at: position)
            let point = arcPoint(position: position, tension: tension, in: size)

            if isFirstPoint {
                path.move(to: point)
                isFirstPoint = false
            } else {
                path.addLine(to: point)
            }
        }

        // Calculate line width based on scene count
        let lineWidth = lineWidthForSceneCount(segment.sceneCount)

        // Determine color based on scene count
        let color = colorForSceneCount(segment.sceneCount)

        // Draw the path
        context.stroke(
            path,
            with: .color(color),
            lineWidth: lineWidth
        )
    }

    private func drawBeatMarker(
        at position: Double,
        tension: Double,
        in context: GraphicsContext,
        size: CGSize
    ) {
        let point = arcPoint(position: position, tension: tension, in: size)
        let markerSize: CGFloat = 8

        let markerRect = CGRect(
            x: point.x - markerSize / 2,
            y: point.y - markerSize / 2,
            width: markerSize,
            height: markerSize
        )

        let markerPath = Path(ellipseIn: markerRect)

        // Fill with white/clear background
        context.fill(
            markerPath,
            with: .color(.white)
        )

        // Stroke
        context.stroke(
            markerPath,
            with: .color(themeManager.currentTheme.colors.accentPrimary),
            lineWidth: 2
        )
    }

    private func drawActivePositionMarker(
        at position: Double,
        in context: GraphicsContext,
        size: CGSize
    ) {
        let tension = arc.tension(at: position)
        let point = arcPoint(position: position, tension: tension, in: size)

        // Vertical line from arc to bottom
        var path = Path()
        path.move(to: point)
        path.addLine(to: CGPoint(x: point.x, y: size.height))

        context.stroke(
            path,
            with: .color(themeManager.currentTheme.colors.accentPrimary),
            style: StrokeStyle(lineWidth: 2, dash: [4, 4])
        )

        // Marker circle at arc position
        let markerSize: CGFloat = 10
        let markerRect = CGRect(
            x: point.x - markerSize / 2,
            y: point.y - markerSize / 2,
            width: markerSize,
            height: markerSize
        )

        let markerPath = Path(ellipseIn: markerRect)

        context.fill(
            markerPath,
            with: .color(themeManager.currentTheme.colors.accentPrimary)
        )
    }

    private func beatMarkerButton(
        at position: Double,
        tension: Double,
        index: Int,
        size: CGSize
    ) -> some View {
        let point = arcPoint(position: position, tension: tension, in: size)
        let markerSize: CGFloat = highlightedSegmentIndex == index ? 16 : 12
        let isHighlighted = highlightedSegmentIndex == index

        return Button {
            onSegmentTap?(index)
        } label: {
            Circle()
                .fill(
                    isHighlighted
                        ? themeManager.currentTheme.colors.accentPrimary
                        : Color.white
                )
                .frame(width: markerSize, height: markerSize)
                .overlay(
                    Circle()
                        .strokeBorder(
                            themeManager.currentTheme.colors.accentPrimary,
                            lineWidth: isHighlighted ? 3 : 2
                        )
                )
                .shadow(
                    color: isHighlighted
                        ? themeManager.currentTheme.colors.accentPrimary.opacity(0.4)
                        : Color.clear,
                    radius: 6
                )
        }
        .buttonStyle(.plain)
        .position(x: point.x, y: point.y)
    }

    private func arcPoint(position: Double, tension: Double, in size: CGSize) -> CGPoint {
        let x = position * size.width

        // Invert Y (higher tension = higher on screen)
        // Use middle 80% of height for arc
        let verticalPadding = size.height * 0.1
        let availableHeight = size.height - (2 * verticalPadding)
        let y = size.height - verticalPadding - (tension * availableHeight)

        return CGPoint(x: x, y: y)
    }

    private func lineWidthForSceneCount(_ sceneCount: Int) -> CGFloat {
        switch sceneCount {
        case 0:
            return 1.0 // Ghosted
        case 1:
            return 2.0
        case 2...3:
            return 3.0
        case 4...6:
            return 4.5
        default: // 7+
            return 6.0
        }
    }

    private func colorForSceneCount(_ sceneCount: Int) -> Color {
        if sceneCount == 0 {
            // Ghosted gray for empty beats
            return themeManager.currentTheme.colors.textTertiary.opacity(0.3)
        } else {
            // Full color for populated beats
            return themeManager.currentTheme.colors.accentPrimary
        }
    }
}

// MARK: - Preview

#Preview("Narrative Arc Visualization") {
    let arc = ThreeActArc()

    let segments = [
        ArcSegment(
            startPosition: 0.0,
            endPosition: 0.33,
            startTension: arc.tension(at: 0.0),
            endTension: arc.tension(at: 0.33),
            sceneCount: 0,
            beatLabel: "Act 1",
            beatID: UUID()
        ),
        ArcSegment(
            startPosition: 0.33,
            endPosition: 0.67,
            startTension: arc.tension(at: 0.33),
            endTension: arc.tension(at: 0.67),
            sceneCount: 3,
            beatLabel: "Act 2",
            beatID: UUID()
        ),
        ArcSegment(
            startPosition: 0.67,
            endPosition: 1.0,
            startTension: arc.tension(at: 0.67),
            endTension: arc.tension(at: 1.0),
            sceneCount: 7,
            beatLabel: "Act 3",
            beatID: UUID()
        )
    ]

    VStack(spacing: 20) {
        Text("Three-Act Structure")
            .font(.headline)

        NarrativeArcVisualization(
            arc: arc,
            segments: segments,
            activePositionFraction: 0.5,
            height: 80
        )
        .environmentObject(ThemeManager())
        .padding()
        .background(Color.white)
    }
    .padding()
}
