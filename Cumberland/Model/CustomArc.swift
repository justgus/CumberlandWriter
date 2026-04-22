//
//  CustomArc.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 5/7: Custom Story Structure Arcs
//
//  User-defined narrative arcs with Catmull-Rom spline interpolation.
//

import Foundation
import SwiftData

/// A control point defining a position on the narrative arc
nonisolated struct ArcControlPoint: Codable, Hashable, Sendable {
    /// Normalized position along the story (0.0 = start, 1.0 = end)
    var position: Double

    /// Dramatic tension at this point (0.0 = low, 1.0 = high)
    var tension: Double

    /// Optional label for this control point (e.g., "Inciting Incident")
    var label: String?

    init(position: Double, tension: Double, label: String? = nil) {
        self.position = position.clamped(to: 0.0...1.0)
        self.tension = tension.clamped(to: 0.0...1.0)
        self.label = label
    }
}

/// Custom narrative arc defined by user-created control points
nonisolated struct CustomArc: NarrativeArc, Codable, Hashable, Sendable {
    /// Name of this custom arc
    var name: String

    /// Control points defining the arc shape
    var controlPoints: [ArcControlPoint]

    /// Description of this arc's purpose
    var description: String?

    init(name: String, controlPoints: [ArcControlPoint], description: String? = nil) {
        self.name = name
        self.controlPoints = controlPoints.sorted { $0.position < $1.position }
        self.description = description

        // Ensure first and last points are at 0.0 and 1.0
        ensureBoundaryPoints()
    }

    /// Creates a default custom arc with standard three-act shape
    static func defaultArc(name: String = "Custom Arc") -> CustomArc {
        return CustomArc(
            name: name,
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3, label: "Opening"),
                ArcControlPoint(position: 0.25, tension: 0.5, label: "Inciting Incident"),
                ArcControlPoint(position: 0.5, tension: 0.7, label: "Midpoint"),
                ArcControlPoint(position: 0.75, tension: 0.9, label: "Crisis"),
                ArcControlPoint(position: 1.0, tension: 0.6, label: "Resolution")
            ],
            description: "A standard three-act structure"
        )
    }

    // MARK: - NarrativeArc Protocol

    func tension(at position: Double) -> Double {
        let x = position.clamped(to: 0.0...1.0)

        guard controlPoints.count >= 2 else {
            return 0.5 // Fallback if no points
        }

        // If we're exactly at a control point, return its tension
        if let exactPoint = controlPoints.first(where: { abs($0.position - x) < 0.0001 }) {
            return exactPoint.tension
        }

        // Find the segment containing this position
        guard let segmentIndex = findSegmentIndex(for: x) else {
            // Outside all segments - use endpoint
            return x < 0.5 ? controlPoints.first!.tension : controlPoints.last!.tension
        }

        // Get the four control points for Catmull-Rom interpolation
        let p0 = getControlPoint(at: segmentIndex - 1)
        let p1 = getControlPoint(at: segmentIndex)
        let p2 = getControlPoint(at: segmentIndex + 1)
        let p3 = getControlPoint(at: segmentIndex + 2)

        // Calculate local t within this segment
        let localT = (x - p1.position) / (p2.position - p1.position)

        // Catmull-Rom interpolation
        return catmullRomInterpolate(
            y0: p0.tension,
            y1: p1.tension,
            y2: p2.tension,
            y3: p3.tension,
            t: localT
        )
    }

    func slope(at position: Double) -> Double {
        let epsilon = 0.001
        let x = position.clamped(to: 0.0...1.0)

        // Numerical derivative using central difference
        let tensionBefore = tension(at: Swift.max(0.0, x - epsilon))
        let tensionAfter = tension(at: Swift.min(1.0, x + epsilon))

        return (tensionAfter - tensionBefore) / (2.0 * epsilon)
    }

    func sparklinePoints(resolution: Int = 100) -> [(x: Double, y: Double)] {
        return (0..<resolution).map { i in
            let x = Double(i) / Double(max(1, resolution - 1))
            return (x: x, y: tension(at: x))
        }
    }

    // MARK: - Catmull-Rom Spline Mathematics

    /// Catmull-Rom spline interpolation between four control points
    /// - Parameters:
    ///   - y0: Tension at point before segment start
    ///   - y1: Tension at segment start
    ///   - y2: Tension at segment end
    ///   - y3: Tension at point after segment end
    ///   - t: Normalized position within segment (0.0 to 1.0)
    /// - Returns: Interpolated tension value
    private func catmullRomInterpolate(y0: Double, y1: Double, y2: Double, y3: Double, t: Double) -> Double {
        let t2 = t * t
        let t3 = t2 * t

        // Catmull-Rom basis matrix coefficients
        let c0 = -0.5 * y0 + 1.5 * y1 - 1.5 * y2 + 0.5 * y3
        let c1 = y0 - 2.5 * y1 + 2.0 * y2 - 0.5 * y3
        let c2 = -0.5 * y0 + 0.5 * y2
        let c3 = y1

        return c0 * t3 + c1 * t2 + c2 * t + c3
    }

    /// Find the segment index containing the given position
    private func findSegmentIndex(for position: Double) -> Int? {
        for i in 0..<(controlPoints.count - 1) {
            if position >= controlPoints[i].position && position <= controlPoints[i + 1].position {
                return i
            }
        }
        return nil
    }

    /// Get control point at index with boundary handling
    /// Extends beyond array bounds by repeating first/last point
    private func getControlPoint(at index: Int) -> ArcControlPoint {
        if index < 0 {
            return controlPoints.first!
        } else if index >= controlPoints.count {
            return controlPoints.last!
        } else {
            return controlPoints[index]
        }
    }

    /// Ensure the arc has boundary points at 0.0 and 1.0
    private mutating func ensureBoundaryPoints() {
        // Check if we have a point at 0.0
        if controlPoints.first?.position != 0.0 {
            let firstTension = controlPoints.first?.tension ?? 0.3
            controlPoints.insert(
                ArcControlPoint(position: 0.0, tension: firstTension, label: "Start"),
                at: 0
            )
        }

        // Check if we have a point at 1.0
        if controlPoints.last?.position != 1.0 {
            let lastTension = controlPoints.last?.tension ?? 0.6
            controlPoints.append(
                ArcControlPoint(position: 1.0, tension: lastTension, label: "End")
            )
        }
    }

    // MARK: - Control Point Manipulation

    /// Add a new control point (automatically sorts)
    mutating func addControlPoint(_ point: ArcControlPoint) {
        controlPoints.append(point)
        controlPoints.sort { $0.position < $1.position }
    }

    /// Remove control point at index (protects boundary points)
    mutating func removeControlPoint(at index: Int) {
        guard index > 0 && index < controlPoints.count - 1 else {
            return // Can't remove first or last point
        }
        controlPoints.remove(at: index)
    }

    /// Update control point at index
    mutating func updateControlPoint(at index: Int, position: Double? = nil, tension: Double? = nil, label: String? = nil) {
        guard index >= 0 && index < controlPoints.count else { return }

        var point = controlPoints[index]

        // Update position (but protect boundaries)
        if let newPosition = position {
            if index == 0 {
                point.position = 0.0
            } else if index == controlPoints.count - 1 {
                point.position = 1.0
            } else {
                point.position = newPosition.clamped(to: 0.0...1.0)
            }
        }

        // Update tension
        if let newTension = tension {
            point.tension = newTension.clamped(to: 0.0...1.0)
        }

        // Update label
        if let newLabel = label {
            point.label = newLabel
        }

        controlPoints[index] = point

        // Re-sort if position changed
        if position != nil {
            controlPoints.sort { $0.position < $1.position }
        }
    }

    /// Find the closest control point to a given position
    func closestControlPoint(to position: Double, within threshold: Double = 0.05) -> Int? {
        var closestIndex: Int?
        var closestDistance = threshold

        for (index, point) in controlPoints.enumerated() {
            let distance = abs(point.position - position)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        return closestIndex
    }
}

// MARK: - Double Extension

private extension Double {
    nonisolated func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
