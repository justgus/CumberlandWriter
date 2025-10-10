// CardEdge.swift
import Foundation
import SwiftData

@Model
final class CardEdge {
    @Relationship(deleteRule: .cascade) var from: Card
    @Relationship(deleteRule: .cascade) var to: Card
    @Relationship var type: RelationType
    var note: String?
    var createdAt: Date
    // Persistent ordering within a swimlane (Double allows easy mid-insertion)
    var sortIndex: Double

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
