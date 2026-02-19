//
//  InvestigationEdge.swift
//  MurderboardApp
//
//  SwiftData model for a connection (edge) between two investigation nodes.
//

import Foundation
import SwiftData

@Model
final class InvestigationEdge {
    var id: UUID = UUID()

    /// Source node ID.
    var sourceNodeID: UUID = UUID()

    /// Target node ID.
    var targetNodeID: UUID = UUID()

    /// Label describing the relationship (e.g. "knows", "witnessed", "owns").
    var label: String = ""

    /// When this edge was created.
    var createdAt: Date = Date()

    /// The board this edge belongs to.
    var board: InvestigationBoard?

    init(sourceNodeID: UUID, targetNodeID: UUID, label: String = "", board: InvestigationBoard? = nil) {
        self.id = UUID()
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
        self.label = label
        self.createdAt = Date()
        self.board = board
    }
}
