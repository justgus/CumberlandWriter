//
//  CustomArcTests.swift
//  CumberlandTests
//
//  Created by Claude Code on 2026-04-22.
//  Part of Phase 5/7: Custom Arc System Tests
//
//  Comprehensive tests for CustomArc and Catmull-Rom spline interpolation.
//

import Testing
import Foundation
@testable import Cumberland

@Suite("CustomArc Tests")
struct CustomArcTests {

    // MARK: - Control Point Tests

    @Test("CustomArc initializes with sorted control points")
    func controlPointsSortedOnInit() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.5, tension: 0.7),
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 1.0, tension: 0.6),
                ArcControlPoint(position: 0.25, tension: 0.5)
            ]
        )

        // Verify sorted order
        for i in 0..<(arc.controlPoints.count - 1) {
            #expect(arc.controlPoints[i].position <= arc.controlPoints[i + 1].position)
        }
    }

    @Test("CustomArc ensures boundary points at 0.0 and 1.0")
    func ensuresBoundaryPoints() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.5, tension: 0.7)
            ]
        )

        #expect(arc.controlPoints.first?.position == 0.0)
        #expect(arc.controlPoints.last?.position == 1.0)
    }

    @Test("ArcControlPoint clamps position to valid range")
    func controlPointClampsPosition() {
        let point1 = ArcControlPoint(position: -0.5, tension: 0.5)
        #expect(point1.position == 0.0)

        let point2 = ArcControlPoint(position: 1.5, tension: 0.5)
        #expect(point2.position == 1.0)

        let point3 = ArcControlPoint(position: 0.5, tension: 0.5)
        #expect(point3.position == 0.5)
    }

    @Test("ArcControlPoint clamps tension to valid range")
    func controlPointClampsTension() {
        let point1 = ArcControlPoint(position: 0.5, tension: -0.5)
        #expect(point1.tension == 0.0)

        let point2 = ArcControlPoint(position: 0.5, tension: 1.5)
        #expect(point2.tension == 1.0)

        let point3 = ArcControlPoint(position: 0.5, tension: 0.7)
        #expect(point3.tension == 0.7)
    }

    // MARK: - Default Arc Tests

    @Test("Default arc has 5 control points")
    func defaultArcHasFivePoints() {
        let arc = CustomArc.defaultArc()
        #expect(arc.controlPoints.count == 5)
    }

    @Test("Default arc covers full position range")
    func defaultArcCoversFullRange() {
        let arc = CustomArc.defaultArc()
        #expect(arc.controlPoints.first?.position == 0.0)
        #expect(arc.controlPoints.last?.position == 1.0)
    }

    @Test("Default arc has reasonable tension values")
    func defaultArcHasReasonableTension() {
        let arc = CustomArc.defaultArc()

        for point in arc.controlPoints {
            #expect(point.tension >= 0.0)
            #expect(point.tension <= 1.0)
        }
    }

    // MARK: - NarrativeArc Protocol Tests

    @Test("tension(at:) returns exact value at control point")
    func tensionAtControlPoint() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 0.5, tension: 0.8),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        let midTension = arc.tension(at: 0.5)
        #expect(abs(midTension - 0.8) < 0.01) // Close to exact value
    }

    @Test("tension(at:) interpolates between control points")
    func tensionInterpolatesBetweenPoints() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.0),
                ArcControlPoint(position: 1.0, tension: 1.0)
            ]
        )

        let midTension = arc.tension(at: 0.5)
        #expect(midTension > 0.0)
        #expect(midTension < 1.0)
    }

    @Test("tension(at:) returns valid values across full range")
    func tensionValidAcrossRange() {
        let arc = CustomArc.defaultArc()

        for i in 0...100 {
            let position = Double(i) / 100.0
            let tension = arc.tension(at: position)

            #expect(tension >= 0.0)
            #expect(tension <= 1.0)
        }
    }

    @Test("tension(at:) produces smooth curve")
    func tensionProducesSmoothCurve() {
        let arc = CustomArc.defaultArc()

        var previousTension = arc.tension(at: 0.0)

        // Check for no sudden jumps (discontinuities)
        for i in 1...100 {
            let position = Double(i) / 100.0
            let tension = arc.tension(at: position)

            let change = abs(tension - previousTension)
            #expect(change < 0.2) // No jump larger than 0.2 per 1% position

            previousTension = tension
        }
    }

    @Test("slope(at:) returns positive value in rising sections")
    func slopePositiveInRisingSections() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.2),
                ArcControlPoint(position: 0.5, tension: 0.5),
                ArcControlPoint(position: 1.0, tension: 0.8)
            ]
        )

        let slopeAtStart = arc.slope(at: 0.1)
        let slopeAtMid = arc.slope(at: 0.5)

        #expect(slopeAtStart > -0.1) // Approximately positive or flat
        #expect(slopeAtMid > -0.1)
    }

    @Test("slope(at:) returns negative value in falling sections")
    func slopeNegativeInFallingSections() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.8),
                ArcControlPoint(position: 0.5, tension: 0.5),
                ArcControlPoint(position: 1.0, tension: 0.2)
            ]
        )

        let slopeAtStart = arc.slope(at: 0.1)
        let slopeAtEnd = arc.slope(at: 0.9)

        #expect(slopeAtStart < 0.1) // Approximately negative or flat
        #expect(slopeAtEnd < 0.1)
    }

    @Test("sparklinePoints returns correct number of points")
    func sparklinePointsCorrectCount() {
        let arc = CustomArc.defaultArc()

        let points100 = arc.sparklinePoints(resolution: 100)
        #expect(points100.count == 100)

        let points50 = arc.sparklinePoints(resolution: 50)
        #expect(points50.count == 50)
    }

    @Test("sparklinePoints covers full range")
    func sparklinePointsCoversFullRange() {
        let arc = CustomArc.defaultArc()
        let points = arc.sparklinePoints(resolution: 100)

        #expect(points.first?.x == 0.0)
        #expect(points.last?.x == 1.0)
    }

    @Test("sparklinePoints has valid y values")
    func sparklinePointsValidYValues() {
        let arc = CustomArc.defaultArc()
        let points = arc.sparklinePoints(resolution: 100)

        for point in points {
            #expect(point.y >= 0.0)
            #expect(point.y <= 1.0)
        }
    }

    // MARK: - Catmull-Rom Interpolation Tests

    @Test("Catmull-Rom interpolation passes through control points")
    func catmullRomPassesThroughControlPoints() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.2),
                ArcControlPoint(position: 0.33, tension: 0.5),
                ArcControlPoint(position: 0.67, tension: 0.8),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        // Check that we're close to control point values
        #expect(abs(arc.tension(at: 0.0) - 0.2) < 0.05)
        #expect(abs(arc.tension(at: 0.33) - 0.5) < 0.05)
        #expect(abs(arc.tension(at: 0.67) - 0.8) < 0.05)
        #expect(abs(arc.tension(at: 1.0) - 0.6) < 0.05)
    }

    @Test("Catmull-Rom produces smooth transitions")
    func catmullRomSmoothTransitions() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 0.5, tension: 0.7),
                ArcControlPoint(position: 1.0, tension: 0.4)
            ]
        )

        // Check that slope doesn't change too rapidly (C1 continuity)
        var previousSlope = arc.slope(at: 0.1)

        for i in 2...10 {
            let position = Double(i) * 0.1
            let slope = arc.slope(at: position)

            let slopeChange = abs(slope - previousSlope)
            #expect(slopeChange < 2.0) // Reasonable bound for slope change

            previousSlope = slope
        }
    }

    // MARK: - Control Point Manipulation Tests

    @Test("addControlPoint maintains sorted order")
    func addControlPointMaintainsSortedOrder() {
        var arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        arc.addControlPoint(ArcControlPoint(position: 0.5, tension: 0.8))

        // Verify sorted
        for i in 0..<(arc.controlPoints.count - 1) {
            #expect(arc.controlPoints[i].position <= arc.controlPoints[i + 1].position)
        }

        #expect(arc.controlPoints.count == 3)
    }

    @Test("removeControlPoint protects boundary points")
    func removeControlPointProtectsBoundaries() {
        var arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 0.5, tension: 0.7),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        // Try to remove first point (should be protected)
        arc.removeControlPoint(at: 0)
        #expect(arc.controlPoints.count == 3)
        #expect(arc.controlPoints.first?.position == 0.0)

        // Try to remove last point (should be protected)
        arc.removeControlPoint(at: arc.controlPoints.count - 1)
        #expect(arc.controlPoints.count == 3)
        #expect(arc.controlPoints.last?.position == 1.0)

        // Remove middle point (should succeed)
        arc.removeControlPoint(at: 1)
        #expect(arc.controlPoints.count == 2)
    }

    @Test("updateControlPoint modifies point correctly")
    func updateControlPointModifiesCorrectly() {
        var arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 0.5, tension: 0.7, label: "Midpoint"),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        // Update tension
        arc.updateControlPoint(at: 1, tension: 0.9)
        #expect(arc.controlPoints[1].tension == 0.9)

        // Update label
        arc.updateControlPoint(at: 1, label: "Climax")
        #expect(arc.controlPoints[1].label == "Climax")

        // Update position (interior point)
        arc.updateControlPoint(at: 1, position: 0.6)

        // Find the updated point (it may have moved due to re-sorting)
        let updatedPoint = arc.controlPoints.first { $0.label == "Climax" }
        #expect(updatedPoint?.position == 0.6)
    }

    @Test("updateControlPoint protects boundary positions")
    func updateControlPointProtectsBoundaryPositions() {
        var arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        // Try to move first point
        arc.updateControlPoint(at: 0, position: 0.5)
        #expect(arc.controlPoints.first?.position == 0.0)

        // Try to move last point
        arc.updateControlPoint(at: 1, position: 0.5)
        #expect(arc.controlPoints.last?.position == 1.0)
    }

    @Test("closestControlPoint finds nearest point")
    func closestControlPointFindsNearest() {
        let arc = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3),
                ArcControlPoint(position: 0.3, tension: 0.5),
                ArcControlPoint(position: 0.7, tension: 0.8),
                ArcControlPoint(position: 1.0, tension: 0.6)
            ]
        )

        // Find closest to 0.32 (should be index 1 at position 0.3)
        let closest1 = arc.closestControlPoint(to: 0.32, within: 0.1)
        #expect(closest1 == 1)

        // Find closest to 0.68 (should be index 2 at position 0.7)
        let closest2 = arc.closestControlPoint(to: 0.68, within: 0.1)
        #expect(closest2 == 2)

        // Find with position too far (should return nil)
        let closest3 = arc.closestControlPoint(to: 0.5, within: 0.05)
        #expect(closest3 == nil)
    }

    // MARK: - Codable Tests

    @Test("CustomArc encodes and decodes correctly")
    func customArcCodable() throws {
        let original = CustomArc(
            name: "Test Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.3, label: "Start"),
                ArcControlPoint(position: 0.5, tension: 0.8, label: "Climax"),
                ArcControlPoint(position: 1.0, tension: 0.5, label: "End")
            ],
            description: "A test arc"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CustomArc.self, from: data)

        #expect(decoded.name == original.name)
        #expect(decoded.description == original.description)
        #expect(decoded.controlPoints.count == original.controlPoints.count)

        for (originalPoint, decodedPoint) in zip(original.controlPoints, decoded.controlPoints) {
            #expect(abs(originalPoint.position - decodedPoint.position) < 0.001)
            #expect(abs(originalPoint.tension - decodedPoint.tension) < 0.001)
            #expect(originalPoint.label == decodedPoint.label)
        }
    }

    @Test("ArcControlPoint encodes and decodes correctly")
    func arcControlPointCodable() throws {
        let original = ArcControlPoint(position: 0.5, tension: 0.7, label: "Midpoint")

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ArcControlPoint.self, from: data)

        #expect(abs(decoded.position - original.position) < 0.001)
        #expect(abs(decoded.tension - original.tension) < 0.001)
        #expect(decoded.label == original.label)
    }

    // MARK: - Edge Case Tests

    @Test("CustomArc handles single control point")
    func handlesSingleControlPoint() {
        let arc = CustomArc(
            name: "Minimal Arc",
            controlPoints: [
                ArcControlPoint(position: 0.5, tension: 0.7)
            ]
        )

        // Should auto-add boundary points
        #expect(arc.controlPoints.count >= 2)
        #expect(arc.controlPoints.first?.position == 0.0)
        #expect(arc.controlPoints.last?.position == 1.0)

        // Should return valid tension across range
        let tension1 = arc.tension(at: 0.0)
        let tension2 = arc.tension(at: 0.5)
        let tension3 = arc.tension(at: 1.0)

        #expect(tension1 >= 0.0 && tension1 <= 1.0)
        #expect(tension2 >= 0.0 && tension2 <= 1.0)
        #expect(tension3 >= 0.0 && tension3 <= 1.0)
    }

    @Test("CustomArc handles many control points")
    func handlesManyControlPoints() {
        var points: [ArcControlPoint] = []
        for i in 0...20 {
            let position = Double(i) / 20.0
            let tension = 0.3 + (Double(i % 3) * 0.2) // Vary between 0.3, 0.5, 0.7
            points.append(ArcControlPoint(position: position, tension: tension))
        }

        let arc = CustomArc(name: "Complex Arc", controlPoints: points)

        #expect(arc.controlPoints.count == 21)

        // Verify smooth interpolation still works
        for i in 0...100 {
            let position = Double(i) / 100.0
            let tension = arc.tension(at: position)
            #expect(tension >= 0.0 && tension <= 1.0)
        }
    }

    @Test("CustomArc handles flat arc (all same tension)")
    func handlesFlatArc() {
        let arc = CustomArc(
            name: "Flat Arc",
            controlPoints: [
                ArcControlPoint(position: 0.0, tension: 0.5),
                ArcControlPoint(position: 0.5, tension: 0.5),
                ArcControlPoint(position: 1.0, tension: 0.5)
            ]
        )

        // All positions should return approximately 0.5
        for i in 0...10 {
            let position = Double(i) / 10.0
            let tension = arc.tension(at: position)
            #expect(abs(tension - 0.5) < 0.1) // Small tolerance for interpolation artifacts
        }
    }
}
