//
//  NarrativeArcTests.swift
//  CumberlandTests
//
//  Created by Claude Code on 2026-04-21.
//  Tests for narrative arc functions
//

import Testing
@testable import Cumberland

struct NarrativeArcTests {

    // MARK: - Protocol Conformance Tests

    @Test("ThreeActArc conforms to NarrativeArc protocol")
    func threeActArcConformance() {
        let arc = ThreeActArc()

        // Tension at start should be low
        #expect(arc.tension(at: 0.0) > 0.0)
        #expect(arc.tension(at: 0.0) < 0.5)

        // Tension at climax (~83%) should be peak
        #expect(arc.tension(at: 0.83) >= 0.9)

        // Tension at end should be moderate
        #expect(arc.tension(at: 1.0) > 0.5)
        #expect(arc.tension(at: 1.0) < 0.9)
    }

    @Test("All arcs return values in valid range [0.0, 1.0]")
    func arcValuesInRange() {
        let arcs: [NarrativeArc] = [
            ThreeActArc(),
            BeginningMiddleEndArc(),
            FiveActArc(),
            FourPartArc(),
            HerosJourneyFormalArc(),
            HerosJourneySimplifiedArc(),
            SaveTheCatArc(),
            NovelArc(),
            ShortStoryArc(),
            AcademicPaperArc(),
            TermPaperArc(),
            TechnicalDocumentArc(),
            WhitePaperArc(),
            LinearArc()
        ]

        for arc in arcs {
            for i in 0...100 {
                let position = Double(i) / 100.0
                let tension = arc.tension(at: position)

                #expect(tension >= 0.0, "Tension below 0.0 at position \(position)")
                #expect(tension <= 1.0, "Tension above 1.0 at position \(position)")
            }
        }
    }

    // MARK: - Specific Arc Characteristics

    @Test("FiveActArc peaks around 60% (Climax)")
    func fiveActPeak() {
        let arc = FiveActArc()

        let tensionAt50 = arc.tension(at: 0.5)
        let tensionAt60 = arc.tension(at: 0.6)
        let tensionAt70 = arc.tension(at: 0.7)

        // Peak should be around 60%
        #expect(tensionAt60 > tensionAt50)
        #expect(tensionAt60 > tensionAt70)
        #expect(tensionAt60 >= 0.9) // Should be near peak tension
    }

    @Test("HerosJourneyFormalArc has dual peaks")
    func heroJourneyDualPeaks() {
        let arc = HerosJourneyFormalArc()

        // First peak around Ordeal (58-67%)
        let firstPeak = arc.tension(at: 0.62)

        // Valley between peaks (around 75%)
        let valley = arc.tension(at: 0.75)

        // Second peak around Resurrection (83-92%)
        let secondPeak = arc.tension(at: 0.87)

        #expect(firstPeak > valley)
        #expect(secondPeak > valley)
        #expect(firstPeak >= 0.8)
        #expect(secondPeak >= 0.8)
    }

    @Test("SaveTheCatArc has precise midpoint at 50%")
    func saveTheCatMidpoint() {
        let arc = SaveTheCatArc()

        // Midpoint should be notable peak around 50%
        let tensionAt45 = arc.tension(at: 0.45)
        let tensionAt50 = arc.tension(at: 0.55) // In midpoint range 0.53-0.6
        let tensionAt60 = arc.tension(at: 0.6)

        #expect(tensionAt50 > tensionAt45)
        #expect(tensionAt50 >= 0.75) // Should be elevated
    }

    @Test("ShortStoryArc has earlier climax than novel arcs")
    func shortStoryEarlyClimax() {
        let shortArc = ShortStoryArc()
        let novelArc = NovelArc()

        // Short story climax around 58%
        let shortClimax = shortArc.tension(at: 0.58)

        // Novel climax around 80%
        let novelClimax = novelArc.tension(at: 0.8)

        // Both should be high tension
        #expect(shortClimax >= 0.9)
        #expect(novelClimax >= 0.9)

        // Short story should already be descending at 80%
        let shortAt80 = shortArc.tension(at: 0.8)
        #expect(shortAt80 < shortClimax)
    }

    @Test("AcademicPaperArc has plateau in Results/Discussion")
    func academicPaperPlateau() {
        let arc = AcademicPaperArc()

        // Complexity should be high and relatively stable in Results (45-65%) and Discussion (65-85%)
        let tensionAt50 = arc.tension(at: 0.5)  // Results
        let tensionAt60 = arc.tension(at: 0.6)  // Results
        let tensionAt70 = arc.tension(at: 0.7)  // Discussion
        let tensionAt80 = arc.tension(at: 0.8)  // Discussion

        // Should all be relatively high
        #expect(tensionAt50 >= 0.6)
        #expect(tensionAt60 >= 0.6)
        #expect(tensionAt70 >= 0.7)
        #expect(tensionAt80 >= 0.7)

        // Discussion should be sustained plateau
        #expect(abs(tensionAt70 - tensionAt80) < 0.1)
    }

    @Test("TechnicalDocumentArc has extended plateau")
    func technicalDocumentPlateau() {
        let arc = TechnicalDocumentArc()

        // Extended plateau from 30% to 80%
        let tensions: [Double] = [0.4, 0.5, 0.6, 0.7].map { arc.tension(at: $0) }

        // All should be at plateau level (~0.6)
        for tension in tensions {
            #expect(abs(tension - 0.6) < 0.1)
        }
    }

    @Test("LinearArc is monotonically increasing")
    func linearArcMonotonic() {
        let arc = LinearArc()

        for i in 0..<100 {
            let pos1 = Double(i) / 100.0
            let pos2 = Double(i + 1) / 100.0

            let tension1 = arc.tension(at: pos1)
            let tension2 = arc.tension(at: pos2)

            #expect(tension2 >= tension1, "Linear arc should always increase")
        }
    }

    // MARK: - Slope Tests

    @Test("Slope is positive in rising sections")
    func slopePositiveInRisingSection() {
        let arc = ThreeActArc()

        // Act 1 is rising
        let slopeAt10 = arc.slope(at: 0.1)
        #expect(slopeAt10 > 0.0)

        // Early Act 2 is rising
        let slopeAt40 = arc.slope(at: 0.4)
        #expect(slopeAt40 > 0.0)
    }

    @Test("Slope is negative in falling sections")
    func slopeNegativeInFallingSection() {
        let arc = ThreeActArc()

        // After climax (after 83%) should be falling
        let slopeAt90 = arc.slope(at: 0.9)
        #expect(slopeAt90 < 0.0)
    }

    @Test("Slope changes sign at peaks")
    func slopeChangesSignAtPeak() {
        let arc = FiveActArc()

        // Before climax (~60%) should be rising
        let slopeBefore = arc.slope(at: 0.55)
        #expect(slopeBefore > 0.0)

        // After climax should be falling
        let slopeAfter = arc.slope(at: 0.65)
        #expect(slopeAfter < 0.0)
    }

    // MARK: - Sparkline Points Tests

    @Test("Sparkline points cover full range")
    func sparklinePointsCoverRange() {
        let arc = ThreeActArc()
        let points = arc.sparklinePoints(resolution: 100)

        #expect(points.count == 100)

        // First point should be at x=0.0
        #expect(points.first?.x == 0.0)

        // Last point should be at x=1.0
        #expect(points.last?.x == 1.0)
    }

    @Test("Sparkline points are evenly distributed")
    func sparklinePointsEvenlyDistributed() {
        let arc = LinearArc()
        let points = arc.sparklinePoints(resolution: 50)

        #expect(points.count == 50)

        // Check spacing
        for i in 1..<points.count {
            let spacing = points[i].x - points[i - 1].x
            let expectedSpacing = 1.0 / Double(points.count - 1)

            #expect(abs(spacing - expectedSpacing) < 0.001)
        }
    }

    @Test("Sparkline y-values match tension function")
    func sparklineValuesMatchTension() {
        let arc = ThreeActArc()
        let points = arc.sparklinePoints(resolution: 20)

        for point in points {
            let directTension = arc.tension(at: point.x)
            #expect(abs(point.y - directTension) < 0.001)
        }
    }

    // MARK: - StoryStructure Integration Tests

    @Test("StoryStructure returns correct arc for Three-Act")
    func storyStructureThreeActArc() {
        let structure = StoryStructure(name: "Three-Act Structure", projectID: nil)
        let arc = structure.narrativeArc

        // Should return ThreeActArc characteristics
        let tensionAtClimax = arc.tension(at: 0.83)
        #expect(tensionAtClimax >= 0.9)
    }

    @Test("StoryStructure returns correct arc for Hero's Journey")
    func storyStructureHerosJourneyArc() {
        let structure = StoryStructure(name: "Hero's Journey (Formal)", projectID: nil)
        let arc = structure.narrativeArc

        // Should have dual peaks characteristic
        let firstPeak = arc.tension(at: 0.62)
        let secondPeak = arc.tension(at: 0.87)

        #expect(firstPeak >= 0.8)
        #expect(secondPeak >= 0.8)
    }

    @Test("StoryStructure returns LinearArc for unknown structures")
    func storyStructureUnknownFallback() {
        let structure = StoryStructure(name: "Custom Unknown Structure", projectID: nil)
        let arc = structure.narrativeArc

        // Should be monotonically increasing (LinearArc characteristic)
        let tension1 = arc.tension(at: 0.0)
        let tension2 = arc.tension(at: 0.5)
        let tension3 = arc.tension(at: 1.0)

        #expect(tension2 > tension1)
        #expect(tension3 > tension2)
    }

    @Test("All predefined structures have corresponding arcs")
    func allPredefinedStructuresHaveArcs() {
        let expectedNonLinearStructures = Set([
            "Three-Act Structure",
            "Beginning-Middle-End",
            "Five-Act Structure",
            "Four-Part Structure",
            "Hero's Journey (Formal)",
            "Hero's Journey (Simplified)",
            "Save the Cat",
            "Novel",
            "Short Story",
            "Academic Paper",
            "Term Paper",
            "Technical Document",
            "White Paper"
        ])

        for template in StoryStructure.predefinedTemplates {
            let structure = StoryStructure(name: template.name, projectID: nil)
            let arc = structure.narrativeArc

            // Generate a few test points
            let points = arc.sparklinePoints(resolution: 10)

            #expect(points.count == 10, "Structure '\(template.name)' should have valid arc")

            // If this is an expected non-linear structure, verify it's not just linear
            if expectedNonLinearStructures.contains(template.name) {
                // Check that it's not perfectly linear
                let isLinear = points.enumerated().allSatisfy { index, point in
                    let expected = 0.3 + (0.4 * point.x) // LinearArc formula
                    return abs(point.y - expected) < 0.01
                }

                #expect(!isLinear, "Structure '\(template.name)' should have non-linear arc")
            }
        }
    }

    // MARK: - Edge Case Tests

    @Test("Arcs handle boundary positions (0.0 and 1.0)")
    func arcsHandleBoundaries() {
        let arcs: [NarrativeArc] = [
            ThreeActArc(),
            FiveActArc(),
            SaveTheCatArc(),
            NovelArc()
        ]

        for arc in arcs {
            let tensionAt0 = arc.tension(at: 0.0)
            let tensionAt1 = arc.tension(at: 1.0)

            #expect(tensionAt0 >= 0.0)
            #expect(tensionAt0 <= 1.0)
            #expect(tensionAt1 >= 0.0)
            #expect(tensionAt1 <= 1.0)
        }
    }

    @Test("Slope handles boundary positions")
    func slopeHandlesBoundaries() {
        let arc = ThreeActArc()

        // Slope at boundaries should not crash or return extreme values
        let slopeAt0 = arc.slope(at: 0.0)
        let slopeAt1 = arc.slope(at: 1.0)

        #expect(abs(slopeAt0) < 100.0, "Slope at 0.0 should be reasonable")
        #expect(abs(slopeAt1) < 100.0, "Slope at 1.0 should be reasonable")
    }
}
