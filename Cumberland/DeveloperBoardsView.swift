// DeveloperBoardsView.swift
// Diagnostics console for Boards and BoardNodes (live container)
// Appears under a DEBUG-only button from MainAppView.

import SwiftUI
import SwiftData

struct DeveloperBoardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText: String = ""
    @State private var selection: UUID? = nil
    @State private var confirmDestructive: ConfirmAction?
    @State private var isRunningGlobal: Bool = false
    @State private var isRunningBoardAction: Bool = false

    enum ConfirmAction: Identifiable {
        case deleteBoard(Board)
        case deleteNode(BoardNode)
        case purgeEmptyBoards
        case removeOrphanNodes
        case clearInvalidPrimaries
        case fixDuplicateNodes

        var id: String {
            switch self {
            case .deleteBoard(let b): return "deleteBoard.\(b.id)"
            case .deleteNode(let n): return "deleteNode.\(n.id)"
            case .purgeEmptyBoards: return "purgeEmptyBoards"
            case .removeOrphanNodes: return "removeOrphanNodes"
            case .clearInvalidPrimaries: return "clearInvalidPrimaries"
            case .fixDuplicateNodes: return "fixDuplicateNodes"
            }
        }

        var title: String {
            switch self {
            case .deleteBoard: return "Delete Board?"
            case .deleteNode: return "Delete Node?"
            case .purgeEmptyBoards: return "Purge Empty Boards?"
            case .removeOrphanNodes: return "Remove Orphan Nodes?"
            case .clearInvalidPrimaries: return "Clear Invalid Primaries?"
            case .fixDuplicateNodes: return "Fix Duplicate Nodes?"
            }
        }

        var message: String {
            switch self {
            case .deleteBoard:
                return "This will delete the board and all of its BoardNodes. This cannot be undone."
            case .deleteNode:
                return "This will remove the selected BoardNode from its Board."
            case .purgeEmptyBoards:
                return "This will delete all Boards with zero nodes."
            case .removeOrphanNodes:
                return "This will delete all BoardNodes whose board or card no longer exists."
            case .clearInvalidPrimaries:
                return "This will clear primaryCard on Boards that reference deleted or missing Cards."
            case .fixDuplicateNodes:
                return "This will remove duplicate BoardNodes for the same (Board, Card) pair, keeping one."
            }
        }

        var confirmLabel: String {
            switch self {
            case .deleteBoard: return "Delete Board"
            case .deleteNode: return "Delete Node"
            case .purgeEmptyBoards: return "Purge"
            case .removeOrphanNodes: return "Remove"
            case .clearInvalidPrimaries: return "Clear"
            case .fixDuplicateNodes: return "Fix"
            }
        }
    }

    // Live board list
    @Query(sort: [
        SortDescriptor(\Board.name, order: .forward)
    ]) private var boards: [Board]

    private var filteredBoards: [Board] {
        guard !searchText.isEmpty else { return boards }
        let s = searchText.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return boards.filter { b in
            if !b.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(s) { return false }
            return true
        }
    }

    // Resolve current selection to a Board instance (prefer filtered set, fall back to all)
    private var selectedBoard: Board? {
        guard let id = selection else { return nil }
        return filteredBoards.first(where: { $0.id == id }) ?? boards.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                boardList
                    .frame(minWidth: 300, idealWidth: 320, maxWidth: 360)
                Divider()
                if let b = selectedBoard ?? filteredBoards.first {
                    boardDetail(b)
                        .frame(minWidth: 520)
                } else {
                    ContentPlaceholderView(
                        title: "No Boards",
                        subtitle: "Create a board by opening a Card’s Board tab.",
                        systemImage: "rectangle.stack.badge.plus"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Developer: Boards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Button {
                            confirmDestructive = .purgeEmptyBoards
                        } label: {
                            Label("Purge Empty Boards", systemImage: "trash")
                        }

                        Button {
                            confirmDestructive = .removeOrphanNodes
                        } label: {
                            Label("Remove Orphan Nodes", systemImage: "trash.slash")
                        }

                        Button {
                            confirmDestructive = .clearInvalidPrimaries
                        } label: {
                            Label("Clear Invalid Primaries", systemImage: "xmark.seal")
                        }

                        Button {
                            confirmDestructive = .fixDuplicateNodes
                        } label: {
                            Label("Fix Duplicate Nodes", systemImage: "wrench.adjustable")
                        }
                    } label: {
                        Label("Global Cleanup", systemImage: "wand.and.stars.inverse")
                    }
                    .disabled(isRunningGlobal || isRunningBoardAction)
                }

                ToolbarItem(placement: .status) {
                    if isRunningGlobal || isRunningBoardAction {
                        ProgressView().controlSize(.small)
                    }
                }
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "Search boards")
            .confirmationDialog(
                confirmDestructive?.title ?? "",
                isPresented: Binding(
                    get: { confirmDestructive != nil },
                    set: { if !$0 { confirmDestructive = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let action = confirmDestructive {
                    Button(role: .destructive) {
                        runConfirm(action)
                    } label: {
                        Text(action.confirmLabel)
                    }
                }
                Button("Cancel", role: .cancel) { confirmDestructive = nil }
            } message: {
                Text(confirmDestructive?.message ?? "")
            }
        }
    }

    // MARK: - Left list

    private var boardList: some View {
        List(selection: $selection) {
            ForEach(filteredBoards, id: \.id) { b in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(b.name.isEmpty ? "Untitled Board" : b.name)
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            Text("Nodes: \(b.nodes?.count ?? 0)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let p = b.primaryCard {
                                Text("Primary: \(p.name.isEmpty ? p.kind.singularTitle : p.name)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No Primary")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                }
                .tag(b.id as UUID?)
                .contextMenu {
                    Button(role: .destructive) {
                        confirmDestructive = .deleteBoard(b)
                    } label: {
                        Label("Delete Board", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Right detail

    @ViewBuilder
    private func boardDetail(_ board: Board) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header(board)
            Divider()
            nodeTable(board)
            Spacer(minLength: 0)
        }
        .padding()
    }

    @ViewBuilder
    private func header(_ board: Board) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(board.name.isEmpty ? "Untitled Board" : board.name)
                    .font(.title3.bold())
                Spacer()
                Menu {
                    Button {
                        resetTransform(board)
                    } label: {
                        Label("Reset Transform (S=1, T=0)", systemImage: "arrow.uturn.backward")
                    }

                    Button {
                        ensurePrimaryPresence(board)
                    } label: {
                        Label("Ensure Primary Presence", systemImage: "star")
                    }

                    Button {
                        clearPrimary(board)
                    } label: {
                        Label("Clear Primary", systemImage: "star.slash")
                    }

                    Divider()

                    Button {
                        removeOrphanNodes(board)
                    } label: {
                        Label("Remove Orphan Nodes", systemImage: "trash.slash")
                    }

                    Button {
                        fixDuplicateNodes(board)
                    } label: {
                        Label("Fix Duplicate Nodes", systemImage: "wrench.adjustable")
                    }

                    Divider()

                    Button(role: .destructive) {
                        confirmDestructive = .deleteBoard(board)
                    } label: {
                        Label("Delete Board…", systemImage: "trash")
                    }
                } label: {
                    Label("Board Actions", systemImage: "slider.horizontal.3")
                }
                .disabled(isRunningBoardAction || isRunningGlobal)
            }

            HStack(spacing: 16) {
                stat("Zoom", value: String(format: "%.2f", board.zoomScale))
                stat("PanX", value: String(format: "%.0f", board.panX))
                stat("PanY", value: String(format: "%.0f", board.panY))
                stat("Nodes", value: "\(board.nodes?.count ?? 0)")
                if let p = board.primaryCard {
                    stat("Primary", value: (p.name.isEmpty ? p.kind.singularTitle : p.name))
                } else {
                    stat("Primary", value: "None")
                }
                Spacer()
            }
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout)
        }
    }

    @ViewBuilder
    private func nodeTable(_ board: Board) -> some View {
        GroupBox("Nodes") {
            if let nodes = board.nodes, !nodes.isEmpty {
                Table(nodes) {
                    TableColumn("Card") { node in
                        if let c = node.card {
                            Text(c.name.isEmpty ? c.kind.singularTitle : c.name)
                        } else {
                            Text("Missing Card").foregroundStyle(.secondary)
                        }
                    }.width(min: 160, ideal: 220, max: .infinity)

                    // Fixed: use closure-based initializer to handle optionals safely
                    TableColumn("Kind") { node in
                        if let kind = node.card?.kindRaw {
                            Text(kind)
                        } else {
                            Text("—").foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 80, ideal: 110, max: 140)

                    TableColumn("X") { node in
                        Text(String(format: "%.1f", node.posX))
                    }.width(min: 60, ideal: 80, max: 120)

                    TableColumn("Y") { node in
                        Text(String(format: "%.1f", node.posY))
                    }.width(min: 60, ideal: 80, max: 120)

                    TableColumn("Pinned") { node in
                        Image(systemName: node.pinned ? "pin.fill" : "pin.slash")
                            .foregroundStyle(node.pinned ? .orange : .secondary)
                    }
                    .width(min: 60, ideal: 80, max: 120)

                    TableColumn("Actions") { node in
                        HStack(spacing: 8) {
                            Button {
                                resetNodePosition(board: board, node: node)
                            } label: {
                                Label("Center", systemImage: "dot.scope")
                            }
                            .help("Reset node position to (0,0) or board’s current logical center")

                            Button(role: .destructive) {
                                confirmDestructive = .deleteNode(node)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .width(min: 160, ideal: 180, max: 220)
                }
                .frame(minHeight: 300)
            } else {
                Text("No nodes on this board.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Actions

    private func runConfirm(_ action: ConfirmAction) {
        switch action {
        case .deleteBoard(let b):
            deleteBoard(b)
        case .deleteNode(let n):
            deleteNode(n)
        case .purgeEmptyBoards:
            Task { @MainActor in
                isRunningGlobal = true
                defer { isRunningGlobal = false; confirmDestructive = nil }
                DataRepair.purgeEmptyBoards(in: modelContext)
            }
        case .removeOrphanNodes:
            Task { @MainActor in
                isRunningGlobal = true
                defer { isRunningGlobal = false; confirmDestructive = nil }
                DataRepair.removeOrphanBoardNodes(in: modelContext)
            }
        case .clearInvalidPrimaries:
            Task { @MainActor in
                isRunningGlobal = true
                defer { isRunningGlobal = false; confirmDestructive = nil }
                DataRepair.clearInvalidBoardPrimaries(in: modelContext)
            }
        case .fixDuplicateNodes:
            Task { @MainActor in
                isRunningGlobal = true
                defer { isRunningGlobal = false; confirmDestructive = nil }
                DataRepair.fixDuplicateBoardNodes(in: modelContext)
            }
        }
    }

    private func deleteBoard(_ board: Board) {
        // Clear selection if deleting the selected board
        if selection == board.id {
            selection = nil
        }
        modelContext.delete(board)
        try? modelContext.save()
        confirmDestructive = nil
    }

    private func deleteNode(_ node: BoardNode) {
        modelContext.delete(node)
        try? modelContext.save()
        confirmDestructive = nil
    }

    private func resetTransform(_ board: Board) {
        isRunningBoardAction = true
        defer { isRunningBoardAction = false }
        board.zoomScale = 1.0
        board.panX = 0
        board.panY = 0
        board.clampState()
        try? modelContext.save()
    }

    private func ensurePrimaryPresence(_ board: Board) {
        isRunningBoardAction = true
        defer { isRunningBoardAction = false }
        board.ensurePrimaryPresence(in: modelContext)
        try? modelContext.save()
    }

    private func clearPrimary(_ board: Board) {
        isRunningBoardAction = true
        defer { isRunningBoardAction = false }
        board.primaryCard = nil
        try? modelContext.save()
    }

    private func removeOrphanNodes(_ board: Board) {
        isRunningBoardAction = true
        defer { isRunningBoardAction = false }
        // Delete nodes with missing card or foreign board reference
        if let nodes = board.nodes {
            for n in nodes {
                if n.card == nil || n.board == nil {
                    modelContext.delete(n)
                }
            }
        }
        try? modelContext.save()
    }

    private func fixDuplicateNodes(_ board: Board) {
        isRunningBoardAction = true
        defer { isRunningBoardAction = false }
        // Ensure only one node per (board, card) pair
        guard let nodes = board.nodes else { return }
        var seen: Set<String> = []
        for n in nodes {
            guard let c = n.card else { continue }
            let key = "\(board.id)|\(c.id)"
            if seen.contains(key) {
                modelContext.delete(n)
            } else {
                seen.insert(key)
            }
        }
        try? modelContext.save()
    }

    private func resetNodePosition(board: Board, node: BoardNode) {
        // Reset to board’s logical origin (0,0). Developer tool keeps it simple.
        node.posX = 0
        node.posY = 0
        try? modelContext.save()
    }
}

#Preview("DeveloperBoardsView (in-memory)") {
    let schema = Schema([Card.self, Board.self, BoardNode.self])
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [cfg])
    let ctx = container.mainContext

    let p = Card(kind: .projects, name: "Project A", subtitle: "", detailedText: "")
    let c1 = Card(kind: .characters, name: "Mira", subtitle: "", detailedText: "")
    let c2 = Card(kind: .characters, name: "Jonas", subtitle: "", detailedText: "")
    ctx.insert(p); ctx.insert(c1); ctx.insert(c2)

    let b = Board(name: "Project A Board", primaryCard: p)
    ctx.insert(b)
    _ = b.node(for: c1, in: ctx, createIfMissing: true, defaultPosition: (100, 50))
    _ = b.node(for: c2, in: ctx, createIfMissing: true, defaultPosition: (-80, -40))
    try? ctx.save()

    return DeveloperBoardsView()
        .modelContainer(container)
        .frame(width: 960, height: 560)
}
