// KindsEnumTests.swift
// CumberlandTests

import Testing
import SwiftUI
@testable import Cumberland

@Suite("Kinds Enum Tests")
struct KindsEnumTests {

    @Test("all 16 kinds have non-empty title")
    func allKindsHaveTitle() {
        for kind in Kinds.allCases {
            #expect(!kind.title.isEmpty, "Kind \(kind.rawValue) has empty title")
        }
    }

    @Test("all 16 kinds have non-empty singularTitle")
    func allKindsHaveSingularTitle() {
        for kind in Kinds.allCases {
            #expect(!kind.singularTitle.isEmpty, "Kind \(kind.rawValue) has empty singularTitle")
        }
    }

    @Test("all 16 kinds have non-empty systemImage")
    func allKindsHaveSystemImage() {
        for kind in Kinds.allCases {
            #expect(!kind.systemImage.isEmpty, "Kind \(kind.rawValue) has empty systemImage")
        }
    }

    @Test("orderedCases contains all cases exactly once")
    func orderedCasesComplete() {
        let ordered = Set(Kinds.orderedCases)
        let all = Set(Kinds.allCases)
        #expect(ordered == all)
        #expect(Kinds.orderedCases.count == Kinds.allCases.count)
    }

    @Test("backgroundColor returns values for both color schemes")
    func backgroundColorBothSchemes() {
        // Spot check a few kinds - verify light and dark produce different colors
        for kind in [Kinds.characters, Kinds.maps, Kinds.scenes] {
            let light = kind.backgroundColor(for: .light)
            let dark = kind.backgroundColor(for: .dark)
            // Light and dark should be different colors
            #expect(light != dark, "Kind \(kind.rawValue) has same color for light and dark")
        }
    }

    @Test("rawValue round-trips through Kinds init")
    func rawValueRoundTrip() {
        for kind in Kinds.allCases {
            let decoded = Kinds(rawValue: kind.rawValue)
            #expect(decoded == kind, "Kind \(kind.rawValue) failed round-trip")
        }
    }
}
