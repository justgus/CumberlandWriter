//
//  CumberlandBoardAdapter.swift
//  Cumberland
//
//  Bridges Cumberland's SwiftData models to BoardEngine's generic protocols.
//  CumberlandNode wraps BoardNode to conform to BoardNodeRepresentable.
//  CumberlandEdge wraps CardEdge to conform to BoardEdgeRepresentable.
//

import SwiftUI
import SwiftData
import BoardEngine

// MARK: - CumberlandNode (BoardNodeRepresentable wrapper)

/// Lightweight wrapper around BoardNode + Card for BoardEngine protocol conformance.
/// BoardNode is a SwiftData @Model whose identity is PersistentIdentifier,
/// so we wrap it to satisfy `Identifiable where ID == UUID`.
struct CumberlandNode: BoardNodeRepresentable {
    let nodeID: UUID
    var posX: Double
    var posY: Double
    var zIndex: Double
    let isPinned: Bool
    let displayName: String
    let subtitle: String
    let categorySystemImage: String
    let isPrimary: Bool

    /// The Card's kind, used for accent color lookup.
    let cardKind: Kinds

    var id: UUID { nodeID }

    func accentColor(for scheme: ColorScheme) -> Color {
        cardKind.accentColor(for: scheme)
    }

    init(from boardNode: BoardNode, primaryCardID: UUID?) {
        let card = boardNode.card
        self.nodeID = card?.id ?? UUID()
        self.posX = boardNode.posX
        self.posY = boardNode.posY
        self.zIndex = boardNode.zIndex
        self.isPinned = boardNode.pinned
        self.displayName = card?.name ?? "Unknown"
        self.subtitle = card?.subtitle ?? ""
        self.categorySystemImage = card?.kind.systemImage ?? "questionmark"
        self.isPrimary = (card?.id == primaryCardID)
        self.cardKind = card?.kind ?? .projects
    }
}

// MARK: - CumberlandEdge (BoardEdgeRepresentable wrapper)

/// Lightweight wrapper around CardEdge for BoardEngine protocol conformance.
struct CumberlandEdge: BoardEdgeRepresentable, Identifiable {
    let edgeID: UUID
    let sourceNodeID: UUID
    let targetNodeID: UUID
    let typeCode: String
    let createdAt: Date

    var id: UUID { edgeID }

    init(from cardEdge: CardEdge) {
        // Use a deterministic UUID from the CardEdge's persistent model ID
        self.edgeID = UUID()
        self.sourceNodeID = cardEdge.from?.id ?? UUID()
        self.targetNodeID = cardEdge.to?.id ?? UUID()
        self.typeCode = cardEdge.type?.code ?? "unknown"
        self.createdAt = cardEdge.createdAt
    }

    init(edgeID: UUID = UUID(), sourceNodeID: UUID, targetNodeID: UUID, typeCode: String, createdAt: Date = Date()) {
        self.edgeID = edgeID
        self.sourceNodeID = sourceNodeID
        self.targetNodeID = targetNodeID
        self.typeCode = typeCode
        self.createdAt = createdAt
    }
}
