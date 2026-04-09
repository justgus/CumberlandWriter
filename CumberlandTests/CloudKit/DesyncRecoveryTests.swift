//
//  DesyncRecoveryTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 1.3: Tests for EdgeIntegrityMonitor desync detection and recovery
//  Tests ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery
//

import Testing
import Foundation
import SwiftData
@testable import Cumberland

@Suite("Desync Detection and Recovery", .serialized)
struct DesyncRecoveryTests {

    // MARK: - Desync Detection Tests

    @Test("Detects desync when cached counts don't match array counts")
    @MainActor
    func detectDesync() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        // Manually create desync by modifying cached count without updating array
        source.cachedOutgoingEdgeCount = 5 // Should be 1
        target.cachedIncomingEdgeCount = 3 // Should be 1

        let status = monitor.checkIntegrity(card: source)

        // Should detect the desync
        switch status {
        case .desyncDetected(let outExpected, let outActual, _, _):
            #expect(outExpected == 5)
            #expect(outActual == 1)
        default:
            #expect(Bool(false), "Expected desync detection")
        }
    }

    @Test("Returns ok status when counts match")
    @MainActor
    func noDesyncDetected() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        // Ensure counts are correct
        source.cachedOutgoingEdgeCount = 1
        target.cachedIncomingEdgeCount = 1

        let status = monitor.checkIntegrity(card: source)

        // Should return ok
        switch status {
        case .ok:
            #expect(true)
        default:
            #expect(Bool(false), "Expected ok status")
        }
    }

    @Test("Skips check when cached counts are zero")
    @MainActor
    func skipsCheckForUninitialized() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let card = TestFixtures.createSampleCharacter(name: "Test", context: context)
        try context.save()

        // New card with no edges should have cached counts of 0
        card.cachedOutgoingEdgeCount = 0
        card.cachedIncomingEdgeCount = 0

        let status = monitor.checkIntegrity(card: card)

        // Should return ok (skips check for uninitialized)
        switch status {
        case .ok:
            #expect(true)
        default:
            #expect(Bool(false), "Expected ok status")
        }
    }

    // MARK: - Recovery Tests

    @Test("Recover fetches authoritative edges and corrects counts")
    @MainActor
    func recoverEdges() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target1 = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let target2 = TestFixtures.createSampleCharacter(name: "Charlie", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target1, type: relationType, context: context)
        let _ = TestFixtures.createEdge(from: source, to: target2, type: relationType, context: context)
        try context.save()

        // Create desync
        source.cachedOutgoingEdgeCount = 10 // Actually has 2

        // Recover
        let (outgoing, incoming) = monitor.recover(card: source, modelContext: context)

        // Should fetch 2 outgoing edges
        #expect(outgoing.count == 2)
        #expect(incoming.count == 0)

        // Should correct the cached count
        #expect(source.cachedOutgoingEdgeCount == 2)
    }

    @Test("Recover handles cards with no edges")
    @MainActor
    func recoverNoEdges() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let card = TestFixtures.createSampleCharacter(name: "Isolated", context: context)
        try context.save()

        // Create fake desync
        card.cachedOutgoingEdgeCount = 5
        card.cachedIncomingEdgeCount = 3

        // Recover
        let (outgoing, incoming) = monitor.recover(card: card, modelContext: context)

        // Should fetch no edges
        #expect(outgoing.isEmpty)
        #expect(incoming.isEmpty)

        // Should correct counts to 0
        #expect(card.cachedOutgoingEdgeCount == 0)
        #expect(card.cachedIncomingEdgeCount == 0)
    }

    // MARK: - Count Recalculation Tests

    @Test("Recalculate counts uses FetchDescriptor")
    @MainActor
    func recalculateCounts() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        // Corrupt the counts
        source.cachedOutgoingEdgeCount = 999
        target.cachedIncomingEdgeCount = 888

        // Recalculate
        EdgeIntegrityMonitor.recalculateCounts(for: source, modelContext: context)
        EdgeIntegrityMonitor.recalculateCounts(for: target, modelContext: context)

        // Counts should be corrected
        #expect(source.cachedOutgoingEdgeCount == 1)
        #expect(target.cachedIncomingEdgeCount == 1)
    }

    // MARK: - Count Maintenance Tests

    @Test("Increment counts increases cached values")
    @MainActor
    func incrementCounts() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        try context.save()

        source.cachedOutgoingEdgeCount = 5
        target.cachedIncomingEdgeCount = 3

        EdgeIntegrityMonitor.incrementCounts(source: source, target: target)

        #expect(source.cachedOutgoingEdgeCount == 6)
        #expect(target.cachedIncomingEdgeCount == 4)
    }

    @Test("Decrement counts decreases cached values")
    @MainActor
    func decrementCounts() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        try context.save()

        source.cachedOutgoingEdgeCount = 5
        target.cachedIncomingEdgeCount = 3

        EdgeIntegrityMonitor.decrementCounts(source: source, target: target)

        #expect(source.cachedOutgoingEdgeCount == 4)
        #expect(target.cachedIncomingEdgeCount == 2)
    }

    @Test("Decrement counts never goes below zero")
    @MainActor
    func decrementCountsFloor() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        try context.save()

        source.cachedOutgoingEdgeCount = 0
        target.cachedIncomingEdgeCount = 0

        EdgeIntegrityMonitor.decrementCounts(source: source, target: target)

        // Should not go negative
        #expect(source.cachedOutgoingEdgeCount == 0)
        #expect(target.cachedIncomingEdgeCount == 0)
    }

    // MARK: - Integration Tests

    @Test("Full workflow: detect, recover, verify")
    @MainActor
    func fullWorkflow() async throws {
        let (_, context) = try TestFixtures.makeFullSchemaContainer()
        let monitor = EdgeIntegrityMonitor()

        let source = TestFixtures.createSampleCharacter(name: "Alice", context: context)
        let target = TestFixtures.createSampleCharacter(name: "Bob", context: context)
        let relationType = TestFixtures.createRelationType(code: "knows", context: context)

        let _ = TestFixtures.createEdge(from: source, to: target, type: relationType, context: context)
        try context.save()

        // 1. Corrupt the count (simulate desync)
        source.cachedOutgoingEdgeCount = 100

        // 2. Detect the desync
        let status1 = monitor.checkIntegrity(card: source)
        switch status1 {
        case .desyncDetected:
            #expect(true) // Expected
        default:
            #expect(Bool(false), "Should detect desync")
        }

        // 3. Recover
        let _ = monitor.recover(card: source, modelContext: context)

        // 4. Verify recovery
        let status2 = monitor.checkIntegrity(card: source)
        switch status2 {
        case .ok:
            #expect(true) // Expected
        default:
            #expect(Bool(false), "Should be ok after recovery")
        }
    }
}
