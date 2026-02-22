//
//  RelationshipAuditView.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-21.
//  Part of ER-0035: Relationship Diagnostic Tools and Safety Guards
//
//  Comprehensive diagnostic view for auditing CardEdge integrity.
//  Uses FetchDescriptor-based queries (not relationship arrays) to detect
//  discrepancies, orphan edges, and potential data loss.
//

import SwiftUI
import SwiftData

/// Diagnostic view for deep edge inspection and relationship integrity auditing.
/// Accessible from DeveloperToolsView under "Data Integrity".
struct RelationshipAuditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.services) private var services
    @Query(sort: \Card.name) private var allCards: [Card]

    @State private var auditResults: [CardAuditResult] = []
    @State private var orphanEdges: [CardEdge] = []
    @State private var duplicateGroups: [DuplicateGroup] = []
    @State private var isRunning = false
    @State private var hasRun = false
    @State private var sortOrder: SortOrder = .name
    @State private var filterMode: FilterMode = .all
    @State private var actionResult: String = ""

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case totalEdges = "Edge Count"
        case kind = "Kind"
        case discrepancy = "Discrepancies"
    }

    enum FilterMode: String, CaseIterable {
        case all = "All Cards"
        case zeroEdges = "Zero Edges"
        case discrepancies = "Discrepancies"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                if hasRun {
                    summarySection
                    duplicateSection
                    orphanSection
                    cardEdgeTable
                }
            }
            .padding()
        }
        .navigationTitle("Relationship Audit")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relationship Audit")
                .font(.title2.bold())

            Text("Fetches all CardEdges via FetchDescriptor and compares with relationship arrays to detect integrity issues.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    runAudit()
                } label: {
                    Label(hasRun ? "Re-run Audit" : "Run Audit", systemImage: "play.fill")
                }
                .disabled(isRunning)

                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if !actionResult.isEmpty {
                Text(actionResult)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        GroupBox("Summary") {
            VStack(alignment: .leading, spacing: 8) {
                statRow("Total cards audited", value: "\(auditResults.count)")
                statRow("Cards with 0 edges", value: "\(auditResults.filter { $0.fetchOutgoing + $0.fetchIncoming == 0 }.count)")
                statRow("Cards with discrepancies", value: "\(auditResults.filter { $0.hasDiscrepancy }.count)")
                statRow("Cards with cached count mismatch", value: "\(auditResults.filter { $0.cachedOutDiscrepancy || $0.cachedInDiscrepancy }.count)")
                statRow("Orphan edges (nil from/to)", value: "\(orphanEdges.count)")

                let totalFetchEdges = auditResults.reduce(0) { $0 + $1.fetchOutgoing + $1.fetchIncoming }
                statRow("Total edges (fetch-based)", value: "\(totalFetchEdges)")
                let totalCachedEdges = auditResults.reduce(0) { $0 + $1.cachedOutgoing + $1.cachedIncoming }
                statRow("Total edges (cached)", value: "\(totalCachedEdges)")
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Duplicate Cards

    @ViewBuilder
    private var duplicateSection: some View {
        if !duplicateGroups.isEmpty {
            GroupBox("Duplicate Cards (\(duplicateGroups.count) groups)") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cards with the same name and kind. The card with the most edges is listed first (recommended to keep).")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(duplicateGroups, id: \.name) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(group.name) (\(group.kind)) — \(group.cards.count) copies")
                                .font(.caption.bold())

                            ForEach(Array(group.cards.enumerated()), id: \.element.card.id) { index, info in
                                HStack(spacing: 8) {
                                    if index == 0 {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.caption2)
                                    } else {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundStyle(.secondary)
                                            .font(.caption2)
                                    }
                                    Text("\(info.fetchEdgeCount) edges")
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(width: 70, alignment: .leading)
                                    if info.hasDetailedText {
                                        Text("has text")
                                            .font(.caption2)
                                            .foregroundStyle(.blue)
                                    }
                                    if info.hasImage {
                                        Text("has image")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    }
                                    Text(info.card.id.uuidString.prefix(8))
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if index > 0 {
                                        Button(role: .destructive) {
                                            deleteDuplicateCard(info.card, keepingPrimary: group.cards[0].card)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                                .font(.caption2)
                                        }
                                    } else {
                                        Text("keep")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                        Divider()
                    }

                    Button(role: .destructive) {
                        deleteAllDuplicates()
                    } label: {
                        Label("Delete All Duplicates (keep highest-edge card in each group)", systemImage: "trash")
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Orphan Edges

    @ViewBuilder
    private var orphanSection: some View {
        if !orphanEdges.isEmpty {
            GroupBox("Orphan Edges (\(orphanEdges.count))") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edges where `from` or `to` is nil — the referenced card was deleted without proper cleanup.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(orphanEdges.prefix(20), id: \.self) { edge in
                        HStack {
                            Text("'\(edge.from?.name ?? "nil")' → '\(edge.to?.name ?? "nil")'")
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Text(edge.type?.code ?? "no type")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if orphanEdges.count > 20 {
                        Text("... and \(orphanEdges.count - 20) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button(role: .destructive) {
                            repairOrphanEdges()
                        } label: {
                            Label("Delete Orphan Edges", systemImage: "trash")
                        }

                        Button {
                            exportSnapshot()
                        } label: {
                            Label("Export Snapshot", systemImage: "doc.on.clipboard")
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Card Edge Table

    private var cardEdgeTable: some View {
        GroupBox("Per-Card Edge Audit") {
            VStack(alignment: .leading, spacing: 8) {
                // Controls
                HStack {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)

                    Spacer()

                    Picker("Filter", selection: $filterMode) {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .frame(maxWidth: 200)
                }

                // Header row
                HStack {
                    Text("Card Name")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Kind")
                        .frame(width: 80)
                    Text("Out(F)")
                        .frame(width: 50)
                    Text("In(F)")
                        .frame(width: 50)
                    Text("Out(A)")
                        .frame(width: 50)
                    Text("In(A)")
                        .frame(width: 50)
                    Text("Out(C)")
                        .frame(width: 50)
                    Text("In(C)")
                        .frame(width: 50)
                    Text("Status")
                        .frame(width: 60)
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)

                Divider()

                // Rows
                let filtered = filteredAndSorted
                if filtered.isEmpty {
                    Text("No cards match the current filter.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(filtered, id: \.cardID) { result in
                        cardRow(result)
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button {
                        exportSnapshot()
                    } label: {
                        Label("Export Edge Snapshot", systemImage: "doc.on.clipboard")
                    }

                    Button {
                        recalculateAllCachedCounts()
                    } label: {
                        Label("Recalculate Cached Counts", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 4)
        }
    }

    private func cardRow(_ result: CardAuditResult) -> some View {
        HStack {
            Text(result.cardName)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(result.cardKind)
                .font(.caption)
                .frame(width: 80)
            Text("\(result.fetchOutgoing)")
                .frame(width: 55)
                .foregroundStyle(result.outgoingDiscrepancy ? .red : .primary)
            Text("\(result.fetchIncoming)")
                .frame(width: 55)
                .foregroundStyle(result.incomingDiscrepancy ? .red : .primary)
            Text("\(result.arrayOutgoing)")
                .frame(width: 55)
                .foregroundStyle(result.outgoingDiscrepancy ? .orange : .secondary)
            Text("\(result.arrayIncoming)")
                .frame(width: 55)
                .foregroundStyle(result.incomingDiscrepancy ? .orange : .secondary)
            Text("\(result.cachedOutgoing)")
                .frame(width: 55)
                .foregroundStyle(result.cachedOutDiscrepancy ? .purple : .secondary)
            Text("\(result.cachedIncoming)")
                .frame(width: 55)
                .foregroundStyle(result.cachedInDiscrepancy ? .purple : .secondary)
            Group {
                if result.fetchOutgoing + result.fetchIncoming == 0 {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                } else if result.hasDiscrepancy {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .frame(width: 60)
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.vertical, 2)
    }

    // MARK: - Filtering & Sorting

    private var filteredAndSorted: [CardAuditResult] {
        var results = auditResults

        switch filterMode {
        case .all:
            break
        case .zeroEdges:
            results = results.filter { $0.fetchOutgoing + $0.fetchIncoming == 0 }
        case .discrepancies:
            results = results.filter { $0.hasDiscrepancy }
        }

        switch sortOrder {
        case .name:
            results.sort { $0.cardName.localizedCaseInsensitiveCompare($1.cardName) == .orderedAscending }
        case .totalEdges:
            results.sort { ($0.fetchOutgoing + $0.fetchIncoming) > ($1.fetchOutgoing + $1.fetchIncoming) }
        case .kind:
            results.sort { $0.cardKind < $1.cardKind }
        case .discrepancy:
            results.sort { $0.hasDiscrepancy && !$1.hasDiscrepancy }
        }

        return results
    }

    // MARK: - Audit Logic

    private func runAudit() {
        isRunning = true
        actionResult = ""

        var results: [CardAuditResult] = []

        for card in allCards {
            let cardID: UUID? = card.id

            // Fetch-based counts
            let fetchFromDesc = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
            let fetchToDesc = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })
            let fetchOut = (try? modelContext.fetch(fetchFromDesc))?.count ?? 0
            let fetchIn = (try? modelContext.fetch(fetchToDesc))?.count ?? 0

            // Relationship array counts
            let arrayOut = card.outgoingEdges?.count ?? 0
            let arrayIn = card.incomingEdges?.count ?? 0

            results.append(CardAuditResult(
                cardID: card.id,
                cardName: card.name,
                cardKind: card.kind.rawValue,
                fetchOutgoing: fetchOut,
                fetchIncoming: fetchIn,
                arrayOutgoing: arrayOut,
                arrayIncoming: arrayIn,
                cachedOutgoing: card.cachedOutgoingEdgeCount,
                cachedIncoming: card.cachedIncomingEdgeCount
            ))
        }

        // Orphan edge detection: edges where from or to is nil
        let allEdgeFetch = FetchDescriptor<CardEdge>()
        let allEdges = (try? modelContext.fetch(allEdgeFetch)) ?? []
        let orphans = allEdges.filter { $0.from == nil || $0.to == nil }

        // Duplicate card detection: same name + same kind
        var kindNameGroups: [String: [Card]] = [:]
        for card in allCards {
            let key = "\(card.kind.rawValue)|\(card.name.trimmingCharacters(in: .whitespaces).lowercased())"
            kindNameGroups[key, default: []].append(card)
        }
        var dupes: [DuplicateGroup] = []
        for (_, cards) in kindNameGroups {
            guard cards.count > 1 else { continue }
            let sorted = cards.sorted { edgeTotal($0) > edgeTotal($1) }
            var infos: [DuplicateCardInfo] = []
            for card in sorted {
                let cardID: UUID? = card.id
                let fetchOut = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
                let fetchIn = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })
                let outCount = (try? modelContext.fetch(fetchOut))?.count ?? 0
                let inCount = (try? modelContext.fetch(fetchIn))?.count ?? 0
                let hasText = !card.detailedText.isEmpty
                let hasImg = card.originalImageData != nil
                infos.append(DuplicateCardInfo(card: card, fetchEdgeCount: outCount + inCount, hasDetailedText: hasText, hasImage: hasImg))
            }
            dupes.append(DuplicateGroup(name: sorted[0].name, kind: sorted[0].kind.rawValue, cards: infos))
        }
        dupes.sort { $0.name < $1.name }

        auditResults = results
        orphanEdges = orphans
        duplicateGroups = dupes
        hasRun = true
        isRunning = false
    }

    // MARK: - Actions

    private func recalculateAllCachedCounts() {
        var fixed = 0
        for card in allCards {
            let before = (card.cachedOutgoingEdgeCount, card.cachedIncomingEdgeCount)
            EdgeIntegrityMonitor.recalculateCounts(for: card, modelContext: modelContext)
            let after = (card.cachedOutgoingEdgeCount, card.cachedIncomingEdgeCount)
            if before != after { fixed += 1 }
        }
        try? modelContext.save()
        actionResult = "Recalculated cached counts for \(allCards.count) cards (\(fixed) corrected)"
        // Re-run audit to show updated values
        runAudit()
    }

    private func deleteDuplicateCard(_ card: Card, keepingPrimary primary: Card) {
        // Move any edges from the duplicate to the primary if they don't already exist
        let dupeID: UUID? = card.id
        let outFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == dupeID })
        let inFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == dupeID })
        let outEdges = (try? modelContext.fetch(outFetch)) ?? []
        let inEdges = (try? modelContext.fetch(inFetch)) ?? []

        var migrated = 0
        let primaryID: UUID? = primary.id

        // Migrate outgoing edges: duplicate→target becomes primary→target (if not already there)
        for edge in outEdges {
            guard let target = edge.to, let edgeType = edge.type else { continue }
            let targetID: UUID? = target.id
            let typeCode: String? = edgeType.code
            let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
                $0.from?.id == primaryID && $0.to?.id == targetID && $0.type?.code == typeCode
            })
            let alreadyExists = ((try? modelContext.fetch(existsFetch))?.isEmpty == false)
            if !alreadyExists {
                let newEdge = CardEdge(from: primary, to: target, type: edgeType, note: edge.note, createdAt: edge.createdAt)
                modelContext.insert(newEdge)
                EdgeIntegrityMonitor.incrementCounts(source: primary, target: target)
                migrated += 1
            }
        }

        // Migrate incoming edges: source→duplicate becomes source→primary (if not already there)
        for edge in inEdges {
            guard let source = edge.from, let edgeType = edge.type else { continue }
            let sourceID: UUID? = source.id
            let typeCode: String? = edgeType.code
            let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
                $0.from?.id == sourceID && $0.to?.id == primaryID && $0.type?.code == typeCode
            })
            let alreadyExists = ((try? modelContext.fetch(existsFetch))?.isEmpty == false)
            if !alreadyExists {
                let newEdge = CardEdge(from: source, to: primary, type: edgeType, note: edge.note, createdAt: edge.createdAt)
                modelContext.insert(newEdge)
                EdgeIntegrityMonitor.incrementCounts(source: source, target: primary)
                migrated += 1
            }
        }

        // Merge content: copy detailedText and image if primary lacks them
        if primary.detailedText.isEmpty && !card.detailedText.isEmpty {
            primary.detailedText = card.detailedText
        }
        if primary.originalImageData == nil, let dupeImage = card.originalImageData {
            try? primary.setOriginalImageData(dupeImage)
        }

        // Save migrated edges before deleting the duplicate
        try? modelContext.save()

        // Delete the duplicate via CardOperationManager
        let cardName = card.name
        do {
            try services?.cardOperations.deleteCard(card)
        } catch {
            actionResult = "Failed to delete '\(cardName)': \(error.localizedDescription)"
            return
        }

        actionResult = "Deleted duplicate '\(cardName)', migrated \(migrated) edge(s) to primary"
        runAudit()
    }

    private func deleteAllDuplicates() {
        var totalDeleted = 0
        var totalMigrated = 0

        for group in duplicateGroups {
            let primary = group.cards[0].card
            for info in group.cards.dropFirst() {
                let dupeID: UUID? = info.card.id
                let outFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == dupeID })
                let inFetch = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == dupeID })
                let outEdges = (try? modelContext.fetch(outFetch)) ?? []
                let inEdges = (try? modelContext.fetch(inFetch)) ?? []
                let primaryID: UUID? = primary.id

                for edge in outEdges {
                    guard let target = edge.to, let edgeType = edge.type else { continue }
                    let targetID: UUID? = target.id
                    let typeCode: String? = edgeType.code
                    let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
                        $0.from?.id == primaryID && $0.to?.id == targetID && $0.type?.code == typeCode
                    })
                    if (try? modelContext.fetch(existsFetch))?.isEmpty ?? true {
                        let newEdge = CardEdge(from: primary, to: target, type: edgeType, note: edge.note, createdAt: edge.createdAt)
                        modelContext.insert(newEdge)
                        EdgeIntegrityMonitor.incrementCounts(source: primary, target: target)
                        totalMigrated += 1
                    }
                }

                for edge in inEdges {
                    guard let source = edge.from, let edgeType = edge.type else { continue }
                    let sourceID: UUID? = source.id
                    let typeCode: String? = edgeType.code
                    let existsFetch = FetchDescriptor<CardEdge>(predicate: #Predicate {
                        $0.from?.id == sourceID && $0.to?.id == primaryID && $0.type?.code == typeCode
                    })
                    if (try? modelContext.fetch(existsFetch))?.isEmpty ?? true {
                        let newEdge = CardEdge(from: source, to: primary, type: edgeType, note: edge.note, createdAt: edge.createdAt)
                        modelContext.insert(newEdge)
                        EdgeIntegrityMonitor.incrementCounts(source: source, target: primary)
                        totalMigrated += 1
                    }
                }

                if primary.detailedText.isEmpty && !info.card.detailedText.isEmpty {
                    primary.detailedText = info.card.detailedText
                }
                if primary.originalImageData == nil, let dupeImage = info.card.originalImageData {
                    try? primary.setOriginalImageData(dupeImage)
                }

                // Save migrated edges before deleting
                try? modelContext.save()

                // Delete via CardOperationManager
                do {
                    try services?.cardOperations.deleteCard(info.card)
                    totalDeleted += 1
                } catch {
                    #if DEBUG
                    print("[EdgeAudit] Failed to delete duplicate '\(info.card.name)': \(error)")
                    #endif
                }
            }
        }

        actionResult = "Deleted \(totalDeleted) duplicate(s), migrated \(totalMigrated) edge(s)"
        runAudit()
    }

    private func repairOrphanEdges() {
        let count = orphanEdges.count
        for edge in orphanEdges {
            modelContext.delete(edge)
        }
        try? modelContext.save()
        orphanEdges = []
        actionResult = "Deleted \(count) orphan edge(s)"

        #if DEBUG
        print("[EdgeAudit] repairOrphanEdges: Deleted \(count) orphan edge(s)")
        #endif
    }

    private func exportSnapshot() {
        var snapshot: [[String: Any]] = []

        let allEdgeFetch = FetchDescriptor<CardEdge>()
        let allEdges = (try? modelContext.fetch(allEdgeFetch)) ?? []

        for edge in allEdges {
            var entry: [String: Any] = [:]
            entry["from_name"] = edge.from?.name ?? "nil"
            entry["from_id"] = edge.from?.id.uuidString ?? "nil"
            entry["to_name"] = edge.to?.name ?? "nil"
            entry["to_id"] = edge.to?.id.uuidString ?? "nil"
            entry["type_code"] = edge.type?.code ?? "nil"
            entry["created_at"] = edge.createdAt.ISO8601Format()
            snapshot.append(entry)
        }

        // Convert to JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(jsonString, forType: .string)
            #elseif os(iOS) || os(visionOS)
            UIPasteboard.general.string = jsonString
            #endif
            actionResult = "Exported \(allEdges.count) edge(s) to clipboard as JSON"
        } else {
            actionResult = "Failed to serialize edge snapshot"
        }
    }

    // MARK: - Helper Views

    private func edgeTotal(_ card: Card) -> Int {
        (card.outgoingEdges?.count ?? 0) + (card.incomingEdges?.count ?? 0)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Audit Result Model

struct CardAuditResult {
    let cardID: UUID
    let cardName: String
    let cardKind: String
    let fetchOutgoing: Int
    let fetchIncoming: Int
    let arrayOutgoing: Int
    let arrayIncoming: Int
    let cachedOutgoing: Int
    let cachedIncoming: Int

    var outgoingDiscrepancy: Bool { fetchOutgoing != arrayOutgoing }
    var incomingDiscrepancy: Bool { fetchIncoming != arrayIncoming }
    var cachedOutDiscrepancy: Bool { fetchOutgoing != cachedOutgoing }
    var cachedInDiscrepancy: Bool { fetchIncoming != cachedIncoming }
    var hasDiscrepancy: Bool { outgoingDiscrepancy || incomingDiscrepancy || cachedOutDiscrepancy || cachedInDiscrepancy }
}

// MARK: - Duplicate Detection Models

struct DuplicateGroup {
    let name: String
    let kind: String
    let cards: [DuplicateCardInfo]
}

struct DuplicateCardInfo {
    let card: Card
    let fetchEdgeCount: Int
    let hasDetailedText: Bool
    let hasImage: Bool
}
