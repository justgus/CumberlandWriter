//
//  CardEdge.swift
//  Cumberland
//
//  SwiftData model representing a directed relationship between two cards.
//  Stores optional from/to Card references and a RelationType. Temporal
//  positioning properties (temporalStart, temporalEnd, temporalDuration,
//  temporalUnit) support timeline placement for scene cards on a Timeline.
//

import Foundation
import SwiftData

@Model
final class CardEdge {
    // Inverses are declared on Card (outgoingEdges/incomingEdges) and RelationType (edges).
    // CloudKit: relationships must be optional.
    var from: Card?
    var to: Card?
    var type: RelationType?

    var note: String?

    // CloudKit: provide defaults at declaration
    var createdAt: Date = Date()
    // Persistent ordering within a swimlane (Double allows easy mid-insertion)
    var sortIndex: Double = 0

    // MARK: - Temporal Positioning (ER-0008)
    // Optional properties - CloudKit auto-migrates without explicit schema migration

    /// Temporal position of a scene on a timeline
    /// Used when timeline has a calendar system (temporal mode)
    /// If nil, fallback to sortIndex for ordinal positioning
    var temporalPosition: Date? = nil

    /// Duration of the scene (in seconds)
    /// Used for visualizing scene length on timeline
    var duration: TimeInterval? = nil

    init(from: Card, to: Card, type: RelationType, note: String? = nil, createdAt: Date = Date(), sortIndex: Double? = nil) {
        self.from = from
        self.to = to
        self.type = type
        self.note = note
        self.createdAt = createdAt
        // Default new edges to an index derived from createdAt; existing rows will need migration/backfill.
        self.sortIndex = sortIndex ?? createdAt.timeIntervalSinceReferenceDate
    }
}
