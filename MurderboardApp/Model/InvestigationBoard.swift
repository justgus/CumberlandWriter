//
//  InvestigationBoard.swift
//  MurderboardApp
//
//  SwiftData model for a standalone investigation board.
//

import Foundation
import SwiftData

@Model
final class InvestigationBoard {
    var id: UUID = UUID()
    var name: String = ""
    var zoomScale: Double = 1.0
    var panX: Double = 0.0
    var panY: Double = 0.0

    @Relationship(deleteRule: .cascade, inverse: \InvestigationNode.board)
    var nodes: [InvestigationNode]? = []

    @Relationship(deleteRule: .cascade, inverse: \InvestigationEdge.board)
    var edges: [InvestigationEdge]? = []

    /// The primary node ID (the central investigation subject).
    var primaryNodeID: UUID?

    init(name: String, primaryNodeID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.primaryNodeID = primaryNodeID
    }
}
