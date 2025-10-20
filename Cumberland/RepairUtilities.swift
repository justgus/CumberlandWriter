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
}
