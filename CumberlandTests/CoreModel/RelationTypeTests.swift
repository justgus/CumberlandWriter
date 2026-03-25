// RelationTypeTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("RelationType Tests", .serialized)
struct RelationTypeTests {

    @Test("matches returns true when no kind constraints")
    func matchesWithNoConstraints() {
        let rt = RelationType(code: "knows/known-by", forwardLabel: "knows", inverseLabel: "known-by")
        #expect(rt.matches(from: .characters, to: .locations))
        #expect(rt.matches(from: .artifacts, to: .scenes))
    }

    @Test("matches returns true when kinds match constraints")
    func matchesWithMatchingConstraints() {
        let rt = RelationType(
            code: "owns/owned-by", forwardLabel: "owns", inverseLabel: "owned-by",
            sourceKind: .characters, targetKind: .artifacts
        )
        #expect(rt.matches(from: .characters, to: .artifacts))
    }

    @Test("matches returns false when source kind mismatches")
    func matchesFailsOnSourceMismatch() {
        let rt = RelationType(
            code: "owns/owned-by", forwardLabel: "owns", inverseLabel: "owned-by",
            sourceKind: .characters, targetKind: .artifacts
        )
        #expect(!rt.matches(from: .locations, to: .artifacts))
    }

    @Test("matches returns false when target kind mismatches")
    func matchesFailsOnTargetMismatch() {
        let rt = RelationType(
            code: "owns/owned-by", forwardLabel: "owns", inverseLabel: "owned-by",
            sourceKind: .characters, targetKind: .artifacts
        )
        #expect(!rt.matches(from: .characters, to: .locations))
    }

    @Test("sourceKind and targetKind computed properties decode and encode")
    func kindAccessorsRoundTrip() {
        let rt = RelationType(code: "test/test", forwardLabel: "f", inverseLabel: "i",
                              sourceKind: .characters, targetKind: .locations)

        #expect(rt.sourceKind == .characters)
        #expect(rt.targetKind == .locations)
        #expect(rt.sourceKindRaw == Kinds.characters.rawValue)
        #expect(rt.targetKindRaw == Kinds.locations.rawValue)

        // Nil case
        let rtNil = RelationType(code: "any/any", forwardLabel: "f", inverseLabel: "i")
        #expect(rtNil.sourceKind == nil)
        #expect(rtNil.targetKind == nil)
        #expect(rtNil.sourceKindRaw == nil)
    }
}
