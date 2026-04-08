//
//  BrushEngineCoreTests.swift
//  BrushEngineTests
//
//  ER-0052 Phase 1.1: Comprehensive tests for BrushEngine core functionality
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import BrushEngine

@Suite("Brush Engine Core")
struct BrushEngineCoreTests {

    // MARK: - Seeded Random Generator Tests

    @Test("Seeded random generator produces consistent results")
    func seededRandomConsistency() {
        var rng1 = SeededRandomGenerator(seed: 42)
        var rng2 = SeededRandomGenerator(seed: 42)

        let value1 = rng1.next()
        let value2 = rng2.next()

        #expect(value1 == value2)
    }

    @Test("Seeded random generator produces different sequences for different seeds")
    func seededRandomDifferentSeeds() {
        var rng1 = SeededRandomGenerator(seed: 111)
        var rng2 = SeededRandomGenerator(seed: 999)

        let value1 = rng1.next()
        let value2 = rng2.next()

        #expect(value1 != value2)
    }

    @Test("Seeded random generator produces deterministic sequence")
    func seededRandomDeterministic() {
        var rng1 = SeededRandomGenerator(seed: 12345)
        let first1 = rng1.next()
        let second1 = rng1.next()
        let third1 = rng1.next()

        var rng2 = SeededRandomGenerator(seed: 12345)
        let first2 = rng2.next()
        let second2 = rng2.next()
        let third2 = rng2.next()

        #expect(first1 == first2)
        #expect(second1 == second2)
        #expect(third1 == third2)
    }

    @Test("Seeded random generator nextDouble returns values in range")
    func seededRandomDoubleInRange() {
        var rng = SeededRandomGenerator(seed: 12345)

        for _ in 0..<100 {
            let value = rng.nextDouble(in: 0.0...1.0)
            #expect(value >= 0.0)
            #expect(value <= 1.0)
        }
    }

    @Test("Seeded random generator nextDouble respects custom range")
    func seededRandomDoubleCustomRange() {
        var rng = SeededRandomGenerator(seed: 54321)
        let range: ClosedRange<CGFloat> = 10.0...20.0

        for _ in 0..<100 {
            let value = rng.nextDouble(in: range)
            #expect(value >= 10.0)
            #expect(value <= 20.0)
        }
    }

    @Test("Seeded random generator handles negative seeds")
    func seededRandomNegativeSeed() {
        var rng = SeededRandomGenerator(seed: -999)

        // Should not crash with negative seed
        let value = rng.next()
        #expect(value > 0) // Generator always produces positive values
    }

    @Test("Seeded random generator handles zero seed")
    func seededRandomZeroSeed() {
        var rng = SeededRandomGenerator(seed: 0)

        // Should not crash with zero seed
        let value = rng.next()
        // Just verify it produces a value
        #expect(value >= 0)
    }

    @Test("Seeded random generator produces varied distribution")
    func seededRandomDistribution() {
        var rng = SeededRandomGenerator(seed: 777)
        var values: [CGFloat] = []

        for _ in 0..<100 {
            values.append(rng.nextDouble(in: 0.0...1.0))
        }

        // Check that we have variety (not all the same value)
        let uniqueValues = Set(values.map { Int($0 * 1000) })
        #expect(uniqueValues.count > 50) // Should have many unique values
    }

    @Test("Seeded random generator handles large range")
    func seededRandomLargeRange() {
        var rng = SeededRandomGenerator(seed: 444)
        let range: ClosedRange<CGFloat> = -1000.0...1000.0

        for _ in 0..<100 {
            let value = rng.nextDouble(in: range)
            #expect(value >= -1000.0)
            #expect(value <= 1000.0)
        }
    }

    @Test("Seeded random generator handles narrow range")
    func seededRandomNarrowRange() {
        var rng = SeededRandomGenerator(seed: 555)
        let range: ClosedRange<CGFloat> = 9.9...10.1

        for _ in 0..<100 {
            let value = rng.nextDouble(in: range)
            #expect(value >= 9.9)
            #expect(value <= 10.1)
        }
    }
}
