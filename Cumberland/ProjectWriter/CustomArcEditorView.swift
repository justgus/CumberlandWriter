//
//  CustomArcEditorView.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 5/7: Custom Story Structure Arcs
//
//  Interactive visual editor for creating and modifying custom narrative arcs.
//

import SwiftUI

struct CustomArcEditorView: View {
    @Binding var customArc: CustomArc
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedPointIndex: Int?
    @State private var isDragging = false
    @State private var editingLabel: Int?

    private let gridLines = 5
    private let editorHeight: CGFloat = 300
    private let handleRadius: CGFloat = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            header

            // Arc canvas
            arcCanvas

            // Control points list
            controlPointsList

            // Instructions
            instructions
        }
        .padding(20)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Arc Editor")
                    .font(.headline)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                if let description = customArc.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }
            }

            Spacer()

            Button {
                addControlPoint()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Point")
                }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Arc Canvas

    private var arcCanvas: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background
                themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)

                // Grid lines
                gridLinesView(size: geometry.size)

                // Arc curve
                arcCurveView(size: geometry.size)

                // Control point handles
                ForEach(Array(customArc.controlPoints.enumerated()), id: \.offset) { index, point in
                    controlPointHandle(
                        for: point,
                        at: index,
                        in: geometry.size
                    )
                }

                // Axis labels
                axisLabels(size: geometry.size)
            }
        }
        .frame(height: editorHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.currentTheme.colors.textTertiary.opacity(0.3), lineWidth: 1)
        )
    }

    private func gridLinesView(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let gridColor = themeManager.currentTheme.colors.textTertiary.opacity(0.2)

            // Horizontal grid lines (tension levels)
            for i in 0...gridLines {
                let y = canvasSize.height * (1.0 - Double(i) / Double(gridLines))
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))

                context.stroke(
                    path,
                    with: .color(gridColor),
                    lineWidth: i == 0 || i == gridLines ? 1 : 0.5
                )
            }

            // Vertical grid lines (story position)
            for i in 0...gridLines {
                let x = canvasSize.width * Double(i) / Double(gridLines)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))

                context.stroke(
                    path,
                    with: .color(gridColor),
                    lineWidth: i == 0 || i == gridLines ? 1 : 0.5
                )
            }
        }
    }

    private func arcCurveView(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Generate sparkline points
            let points = customArc.sparklinePoints(resolution: 200)

            guard !points.isEmpty else { return }

            // Convert to canvas coordinates
            var path = Path()
            let firstPoint = points[0]
            path.move(to: CGPoint(
                x: firstPoint.x * canvasSize.width,
                y: (1.0 - firstPoint.y) * canvasSize.height
            ))

            for point in points.dropFirst() {
                path.addLine(to: CGPoint(
                    x: point.x * canvasSize.width,
                    y: (1.0 - point.y) * canvasSize.height
                ))
            }

            // Draw the arc line
            context.stroke(
                path,
                with: .color(themeManager.currentTheme.colors.accentPrimary),
                lineWidth: 3
            )
        }
    }

    private func controlPointHandle(for point: ArcControlPoint, at index: Int, in size: CGSize) -> some View {
        let position = CGPoint(
            x: point.position * size.width,
            y: (1.0 - point.tension) * size.height
        )

        let isSelected = selectedPointIndex == index
        let isBoundary = index == 0 || index == customArc.controlPoints.count - 1

        return ZStack {
            // Handle circle
            Circle()
                .fill(isSelected
                    ? themeManager.currentTheme.colors.accentPrimary
                    : Color.white
                )
                .frame(width: handleRadius * 2, height: handleRadius * 2)
                .overlay(
                    Circle()
                        .stroke(
                            themeManager.currentTheme.colors.accentPrimary,
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .shadow(radius: isSelected ? 4 : 2)

            // Label above handle
            if let label = point.label, !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(themeManager.currentTheme.colors.textTertiary.opacity(0.3), lineWidth: 1)
                    )
                    .offset(y: -20)
            }
        }
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(at: index, value: value, canvasSize: size, isBoundary: isBoundary)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .onTapGesture {
            selectedPointIndex = index
        }
    }

    private func axisLabels(size: CGSize) -> some View {
        ZStack {
            // Y-axis label (Tension)
            Text("Tension")
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                .rotationEffect(.degrees(-90))
                .offset(x: -size.width / 2 + 30, y: size.height / 2)

            // X-axis label (Story Position)
            Text("Story Position")
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                .offset(x: size.width / 2, y: size.height - 10)
        }
    }

    // MARK: - Control Points List

    private var controlPointsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Control Points")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(customArc.controlPoints.enumerated()), id: \.offset) { index, point in
                        controlPointCard(for: point, at: index)
                    }
                }
            }
        }
    }

    private func controlPointCard(for point: ArcControlPoint, at index: Int) -> some View {
        let isSelected = selectedPointIndex == index
        let isBoundary = index == 0 || index == customArc.controlPoints.count - 1

        return VStack(alignment: .leading, spacing: 6) {
            // Label
            if editingLabel == index {
                TextField("Label", text: Binding(
                    get: { point.label ?? "" },
                    set: { newLabel in
                        customArc.updateControlPoint(at: index, label: newLabel.isEmpty ? nil : newLabel)
                    }
                ))
                .font(.caption.weight(.semibold))
                .textFieldStyle(.plain)
                .onSubmit {
                    editingLabel = nil
                }
            } else {
                HStack(spacing: 4) {
                    Text(point.label ?? "Point \(index + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                    Button {
                        editingLabel = index
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Stats
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Position:")
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    Text(String(format: "%.2f", point.position))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                }

                HStack(spacing: 4) {
                    Text("Tension:")
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    Text(String(format: "%.2f", point.tension))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                }
            }

            // Delete button (if not boundary)
            if !isBoundary {
                Button(role: .destructive) {
                    customArc.removeControlPoint(at: index)
                    if selectedPointIndex == index {
                        selectedPointIndex = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(10)
        .frame(width: 140)
        .background(
            Group {
                if isSelected {
                    themeManager.currentTheme.colors.accentPrimary.opacity(0.1)
                } else {
                    themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isSelected
                        ? themeManager.currentTheme.colors.accentPrimary
                        : themeManager.currentTheme.colors.textTertiary.opacity(0.3),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .onTapGesture {
            selectedPointIndex = index
        }
    }

    // MARK: - Instructions

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Instructions:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            Text("• Drag control points to reshape the arc")
            Text("• Click \"Add Point\" to add new control points")
            Text("• Click the pencil icon to rename points")
            Text("• First and last points are locked to start/end positions")

            Text("Tension represents dramatic intensity (0.0 = calm, 1.0 = maximum tension)")
                .italic()
        }
        .font(.caption)
        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
    }

    // MARK: - Interaction Handlers

    private func handleDrag(at index: Int, value: DragGesture.Value, canvasSize: CGSize, isBoundary: Bool) {
        isDragging = true
        selectedPointIndex = index

        // Convert drag location to normalized coordinates
        let normalizedX = (value.location.x / canvasSize.width).clamped(to: 0.0...1.0)
        let normalizedY = 1.0 - (value.location.y / canvasSize.height).clamped(to: 0.0...1.0)

        // Update control point
        if isBoundary {
            // Boundary points can only move vertically (tension)
            customArc.updateControlPoint(at: index, tension: normalizedY)
        } else {
            // Interior points can move both directions
            customArc.updateControlPoint(at: index, position: normalizedX, tension: normalizedY)
        }
    }

    private func addControlPoint() {
        // Add point at middle of arc
        let position = 0.5
        let tension = customArc.tension(at: position)

        let newPoint = ArcControlPoint(
            position: position,
            tension: tension,
            label: "New Point"
        )

        customArc.addControlPoint(newPoint)
        selectedPointIndex = customArc.controlPoints.firstIndex(where: { $0.position == position })
    }
}

// MARK: - Double Extension

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

#Preview("Custom Arc Editor") {
    @Previewable @State var customArc = CustomArc.defaultArc(name: "My Custom Arc")

    return CustomArcEditorView(customArc: $customArc)
        .environmentObject(ThemeManager())
        .frame(width: 700, height: 700)
}
