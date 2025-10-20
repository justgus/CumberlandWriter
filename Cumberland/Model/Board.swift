import Foundation
import SwiftData

@Model
final class Board {
    // Identity
    var id: UUID = UUID()
    var name: String = ""

    // Optional primary card — if set, it should always be present on this board.
    // CloudKit: declare inverse so sync can model it correctly.
    @Relationship(deleteRule: .nullify, inverse: \Card.primaryBoards)
    var primaryCard: Card?

    // Optional backlog filter by kind (raw string to keep schema simple)
    var backlogKindRaw: String?

    // Panning and zoom
    var zoomScale: Double = 1.0
    var panX: Double = 0.0
    var panY: Double = 0.0
//
    // Membership and placement via nodes
    @Relationship(deleteRule: .cascade, inverse: \BoardNode.board)
    var nodes: [BoardNode]? = []

    init(id: UUID = UUID(),
         name: String,
         primaryCard: Card? = nil,
         backlogKindRaw: String? = nil,
         zoomScale: Double = 1.0,
         panX: Double = 0.0,
         panY: Double = 0.0)
    {
        self.id = id
        self.name = name
        self.primaryCard = primaryCard
        self.backlogKindRaw = backlogKindRaw
        self.zoomScale = zoomScale
        self.panX = panX
        self.panY = panY
    }
}

@Model
final class BoardNode {
    // Relationships
    // Inverse of Board.nodes is declared on Board.
    var board: Board?
    // Inverse of Card.boardNodes is declared on Card.
    var card: Card?

    // Placement/state
    var posX: Double = 0.0
    var posY: Double = 0.0
    var zIndex: Double = 0.0
    var pinned: Bool = false
    // Optional per-node size override (falls back to card.sizeCategory)
    var sizeOverrideRaw: Int?

    init(board: Board,
         card: Card,
         posX: Double = 0.0,
         posY: Double = 0.0,
         zIndex: Double = 0.0,
         pinned: Bool = false,
         sizeOverrideRaw: Int? = nil)
    {
        self.board = board
        self.card = card
        self.posX = posX
        self.posY = posY
        self.zIndex = zIndex
        self.pinned = pinned
        self.sizeOverrideRaw = sizeOverrideRaw
    }

    var effectiveSizeCategory: SizeCategory {
        if let raw = sizeOverrideRaw, let cat = SizeCategory(rawValue: raw) { return cat }
        return card?.sizeCategory ?? .standard
    }
}

// MARK: - Board helpers

extension Board {
    // Clamp ranges for stability — aligned to spec (1%…200%)
    static let minZoom: Double = 0.01
    static let maxZoom: Double = 2.0
    static let minPan: Double = -1_000_000
    static let maxPan: Double = +1_000_000

    func clampState() {
        zoomScale = zoomScale.rangeClamped(to: Self.minZoom...Self.maxZoom)
        panX = panX.rangeClamped(to: Self.minPan...Self.maxPan)
        panY = panY.rangeClamped(to: Self.minPan...Self.maxPan)
    }

    // Ensure a node exists for a given card; find via context fetch to avoid cross-context traversal,
    // then create if missing.
    @MainActor
    func node(for card: Card, in ctx: ModelContext, createIfMissing: Bool = true, defaultPosition: (x: Double, y: Double) = (0, 0)) -> BoardNode? {
        let bID: UUID? = self.id
        let cID: UUID? = card.id

        // Prefer a context-local fetch keyed by IDs (avoids relying on relationship arrays that may be stale/foreign)
        let fetch = FetchDescriptor<BoardNode>(
            predicate: #Predicate { $0.board?.id == bID && $0.card?.id == cID },
            sortBy: [SortDescriptor(\.zIndex, order: .forward)]
        )
        if let existing = try? ctx.fetch(fetch), let node = existing.first {
            return node
        }

        guard createIfMissing else { return nil }

        let node = BoardNode(
            board: self,
            card: card,
            posX: defaultPosition.x,
            posY: defaultPosition.y,
            zIndex: ((nodes?.map { $0.zIndex }.max() ?? 0) + 1)
        )
        if nodes == nil { nodes = [] }
        nodes?.append(node)
        ctx.insert(node)
        return node
    }

    // Ensure primary card is present on the board (create node if needed).
    @MainActor
    func ensurePrimaryPresence(in ctx: ModelContext) {
        guard let primary = primaryCard else { return }
        _ = node(for: primary, in: ctx, createIfMissing: true, defaultPosition: (0, 0))
    }

    // Fetch or create a board whose primaryCard == given card.
    @MainActor
    static func fetchOrCreatePrimaryBoard(for primary: Card, in ctx: ModelContext) -> Board {
        let primaryID: UUID? = primary.id
        let fetch = FetchDescriptor<Board>(predicate: #Predicate { $0.primaryCard?.id == primaryID },
                                           sortBy: [SortDescriptor(\.name, order: .forward)])
        if let existing = try? ctx.fetch(fetch), let board = existing.first {
            board.ensurePrimaryPresence(in: ctx)
            board.clampState()
            try? ctx.save()
            return board
        }
        // Create a new board
        let board = Board(name: "\(primary.name.isEmpty ? primary.kind.singularTitle : primary.name) Board", primaryCard: primary, zoomScale: 1.0, panX: 0, panY: 0)
        ctx.insert(board)
        board.ensurePrimaryPresence(in: ctx)
        try? ctx.save()
        return board
    }

    var backlogKind: Kinds? {
        get { backlogKindRaw.flatMap { Kinds(rawValue: $0) } }
        set { backlogKindRaw = newValue?.rawValue }
    }

    // All cards currently on this board (via nodes)
    var memberCards: [Card] {
        (nodes ?? []).compactMap { $0.card }
    }
}

extension Comparable {
    func rangeClamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
