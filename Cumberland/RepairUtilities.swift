// RepairUtilities.swift
import SwiftUI
import SwiftData

enum DataRepair {
    static func repairForeignBoardNodes(in ctx: ModelContext) {
        var fetch = FetchDescriptor<BoardNode>()
        fetch.fetchLimit = 0
        let nodes: [BoardNode] = (try? ctx.fetch(fetch)) ?? []
        guard !nodes.isEmpty else { return }
        var toDelete: [BoardNode] = []
        for n in nodes {
            guard let bID = n.board?.id, let cID = n.card?.id else {
                toDelete.append(n)
                continue
            }
            let bFetch = FetchDescriptor<Board>(predicate: #Predicate { $0.id == bID })
            let cFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cID })
            let bOK = ((try? ctx.fetch(bFetch)) ?? []).first != nil
            let cOK = ((try? ctx.fetch(cFetch)) ?? []).first != nil
            if !bOK || !cOK { toDelete.append(n) }
        }
        guard !toDelete.isEmpty else { return }
        for n in toDelete { ctx.delete(n) }
        try? ctx.save()
    }

    // Delete all Boards that have zero nodes.
    static func purgeEmptyBoards(in ctx: ModelContext) {
        var fetch = FetchDescriptor<Board>()
        fetch.fetchLimit = 0
        let boards = (try? ctx.fetch(fetch)) ?? []
        var deleted = 0
        for b in boards {
            if (b.nodes?.isEmpty ?? true) {
                ctx.delete(b)
                deleted += 1
            }
        }
        if deleted > 0 {
            try? ctx.save()
        }
    }

    // Remove BoardNodes whose board or card is missing.
    static func removeOrphanBoardNodes(in ctx: ModelContext) {
        var fetch = FetchDescriptor<BoardNode>()
        fetch.fetchLimit = 0
        let nodes = (try? ctx.fetch(fetch)) ?? []
        var deleted = 0
        for n in nodes {
            guard let bID = n.board?.id, let cID = n.card?.id else {
                ctx.delete(n); deleted += 1; continue
            }
            let bFetch = FetchDescriptor<Board>(predicate: #Predicate { $0.id == bID })
            let cFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cID })
            let bOK = ((try? ctx.fetch(bFetch)) ?? []).first != nil
            let cOK = ((try? ctx.fetch(cFetch)) ?? []).first != nil
            if !bOK || !cOK {
                ctx.delete(n); deleted += 1
            }
        }
        if deleted > 0 {
            try? ctx.save()
        }
    }

    // Clear primaryCard on Boards when the referenced card no longer exists.
    static func clearInvalidBoardPrimaries(in ctx: ModelContext) {
        var fetch = FetchDescriptor<Board>()
        fetch.fetchLimit = 0
        let boards = (try? ctx.fetch(fetch)) ?? []
        var changed = 0
        for b in boards {
            if let p = b.primaryCard {
                // Card.id is non-optional (UUID), so use a non-optional UUID in the predicate.
                let pID: UUID = p.id
                let pf = FetchDescriptor<Card>(predicate: #Predicate { $0.id == pID })
                let exists = (((try? ctx.fetch(pf)) ?? []).first != nil)
                if !exists {
                    b.primaryCard = nil
                    changed += 1
                }
            }
        }
        if changed > 0 {
            try? ctx.save()
        }
    }

    // Remove duplicate BoardNodes for the same (Board, Card) pair, keeping one.
    static func fixDuplicateBoardNodes(in ctx: ModelContext) {
        var fetch = FetchDescriptor<BoardNode>()
        fetch.fetchLimit = 0
        let nodes = (try? ctx.fetch(fetch)) ?? []

        // Group by (boardID, cardID)
        var groups: [String: [BoardNode]] = [:]
        for n in nodes {
            guard let bID = n.board?.id, let cID = n.card?.id else { continue }
            groups["\(bID.uuidString)|\(cID.uuidString)", default: []].append(n)
        }

        var deleted = 0
        for (_, arr) in groups {
            guard arr.count > 1 else { continue }
            // Keep a single node deterministically: choose the one with the lowest zIndex
            let keep = arr.min(by: { (a: BoardNode, b: BoardNode) -> Bool in
                if a.zIndex != b.zIndex { return a.zIndex < b.zIndex }
                // Secondary tie-breakers for stability
                if a.posY != b.posY { return a.posY < b.posY }
                if a.posX != b.posX { return a.posX < b.posX }
                // Prefer unpinned over pinned to maintain flexibility
                if a.pinned != b.pinned { return a.pinned == false }
                // Final fallback: keep the first as-is
                return true
            }) ?? arr[0]

            for n in arr where n !== keep {
                ctx.delete(n)
                deleted += 1
            }
        }
        if deleted > 0 {
            try? ctx.save()
        }
    }
}
