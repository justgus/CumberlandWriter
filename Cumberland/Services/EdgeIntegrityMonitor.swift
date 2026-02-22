//
//  EdgeIntegrityMonitor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-21.
//  Part of ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery
//
//  Detects SwiftData relationship array desynchronization at runtime by
//  comparing cached edge counts (maintained by RelationshipManager) against
//  in-memory relationship array counts. When a mismatch is found, recovers
//  authoritative edges via FetchDescriptor and corrects cached counts.
//
//  Uses OSLog for production-visible logging of desync events.
//

import Foundation
import SwiftData
import os

// MARK: - Edge Integrity Status

enum EdgeIntegrityStatus {
    case ok
    case desyncDetected(outgoingExpected: Int, outgoingActual: Int, incomingExpected: Int, incomingActual: Int)
    case countStale(outgoingCached: Int, outgoingFetched: Int, incomingCached: Int, incomingFetched: Int)
}

// MARK: - EdgeIntegrityMonitor

@Observable
@MainActor
final class EdgeIntegrityMonitor {

    private static let logger = Logger(subsystem: "com.cumberland.app", category: "EdgeIntegrity")

    // MARK: - Integrity Check

    /// Compare cached counts on a Card against its relationship array counts.
    /// Returns `.ok` if they match, `.desyncDetected` if arrays are stale.
    func checkIntegrity(card: Card) -> EdgeIntegrityStatus {
        let cachedOut = card.cachedOutgoingEdgeCount
        let cachedIn = card.cachedIncomingEdgeCount
        let arrayOut = card.outgoingEdges?.count ?? 0
        let arrayIn = card.incomingEdges?.count ?? 0

        // If cached counts are both 0, we may not have backfilled yet — skip check
        if cachedOut == 0 && cachedIn == 0 {
            return .ok
        }

        if cachedOut != arrayOut || cachedIn != arrayIn {
            Self.logger.warning(
                "[ER-0036] Desync detected for '\(card.name)' (id: \(card.id)): cached=\(cachedOut)out/\(cachedIn)in, array=\(arrayOut)out/\(arrayIn)in"
            )
            return .desyncDetected(
                outgoingExpected: cachedOut,
                outgoingActual: arrayOut,
                incomingExpected: cachedIn,
                incomingActual: arrayIn
            )
        }

        return .ok
    }

    // MARK: - Recovery

    /// Recover authoritative edges for a card via FetchDescriptor, correct cached counts.
    /// Returns the fetched outgoing and incoming edges.
    func recover(card: Card, modelContext: ModelContext) -> (outgoing: [CardEdge], incoming: [CardEdge]) {
        let cardID: UUID? = card.id
        let outFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        let inFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

        let outgoing = (try? modelContext.fetch(outFetch)) ?? []
        let incoming = (try? modelContext.fetch(inFetch)) ?? []

        let oldOut = card.cachedOutgoingEdgeCount
        let oldIn = card.cachedIncomingEdgeCount

        card.cachedOutgoingEdgeCount = outgoing.count
        card.cachedIncomingEdgeCount = incoming.count

        Self.logger.info(
            "[ER-0036] Recovered edges for '\(card.name)': \(outgoing.count)out/\(incoming.count)in (was cached \(oldOut)out/\(oldIn)in)"
        )

        return (outgoing, incoming)
    }

    // MARK: - Full Recount

    /// Recalculate cached counts for a single card from FetchDescriptor.
    static func recalculateCounts(for card: Card, modelContext: ModelContext) {
        let cardID: UUID? = card.id
        let outFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
        let inFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

        let outCount = (try? modelContext.fetchCount(outFetch)) ?? 0
        let inCount = (try? modelContext.fetchCount(inFetch)) ?? 0

        card.cachedOutgoingEdgeCount = outCount
        card.cachedIncomingEdgeCount = inCount
    }

    // MARK: - Count Maintenance (called by RelationshipManager)

    /// Increment cached counts after edge creation.
    /// source.cachedOutgoingEdgeCount += 1, target.cachedIncomingEdgeCount += 1
    static func incrementCounts(source: Card?, target: Card?) {
        if let source = source {
            source.cachedOutgoingEdgeCount += 1
        }
        if let target = target {
            target.cachedIncomingEdgeCount += 1
        }
    }

    /// Decrement cached counts before edge deletion.
    /// source.cachedOutgoingEdgeCount -= 1, target.cachedIncomingEdgeCount -= 1
    static func decrementCounts(source: Card?, target: Card?) {
        if let source = source {
            source.cachedOutgoingEdgeCount = max(0, source.cachedOutgoingEdgeCount - 1)
        }
        if let target = target {
            target.cachedIncomingEdgeCount = max(0, target.cachedIncomingEdgeCount - 1)
        }
    }
}
