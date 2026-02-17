//
//  MurderBoardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/19/25.
//  Migrated to BoardEngine as part of ER-0026.
//
//  Root view of the visual relationship mapping canvas (Murderboard).
//  Uses BoardEngine's BoardCanvasView, BoardGestureIntegration, BoardZoomStrip,
//  and BoardBorderOverlay for the canvas infrastructure.
//  Cumberland-specific logic: card rendering, sidebar backlog, edge creation
//  RelationType sheet, board loading, and thumbnail prefetching.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CloudKit
import BoardEngine

struct MurderBoardView: View {
    let primary: Card

    @Environment(\.modelContext) var modelContext
    @Environment(\.services) var services
    @Environment(\.colorScheme) var scheme

    // Query for all cards (used by backlog)
    @Query(sort: \Card.name) var allCards: [Card]

    // Data source bridging Cumberland -> BoardEngine
    @State private var dataSource: CumberlandBoardDataSource?

    // Live transform state (mirrors dataSource; persisted on changes)
    @State var zoomScale: Double = 1.0
    @State var panX: Double = 0.0
    @State var panY: Double = 0.0

    // Selection (single)
    @State var selectedCardID: UUID? = nil

    // One-time initial recenter
    @State var didInitialRecenter: Bool = false

    // Staging flag to avoid heavy simultaneous image uploads during first render
    @State var isContentReady: Bool = false
    @State var prefetchProgress: (done: Int, total: Int) = (0, 0)

    // Live unscaled sizes measured for each CardView
    @State var nodeSizes: [UUID: CGSize] = [:]
    @State var nodeVisualSizes: [UUID: CGSize] = [:]

    // Named coordinate space for consistent math
    let canvasCoordSpace = "MurderBoardCanvasSpace"
    let configuration = BoardConfiguration.cumberland

    // Drag & Drop state
    @State private var isDropTargetActive: Bool = false

    // MARK: - Sidebar Backlog state

    @State var isSidebarVisible: Bool = true
    @State var selectedKindFilter: Kinds? = nil
    @State var selectedBacklogCards: Set<UUID> = []

    // MARK: - MultiGesture Handler Integration (from BoardEngine)

    @State var gestureHandler: MultiGestureHandler? = nil
    @State var canvasGestureTarget: BoardEngine.CanvasGestureTarget? = nil
    @State var nodeGestureTargets: [UUID: BoardEngine.NodeGestureTarget] = [:]

    // MARK: - Edge Creation (DR-0076)

    @Query(sort: \RelationType.code) private var allRelationTypes: [RelationType]

    @State var edgeCreationState = BoardEdgeCreationState()

    // Sheet presentation for RelationType selection
    @State var pendingEdgeCreation: PendingEdgeCreation? = nil

    init(primary: Card) {
        self.primary = primary
    }

    // MARK: - Backlog Cards Query

    var backlogCards: [Card] {
        guard let ds = dataSource, let board = ds.board else { return allCards }
        let cardsOnBoard = Set((board.nodes ?? []).compactMap { $0.card?.id })
        var filtered = allCards.filter { !cardsOnBoard.contains($0.id) }

        if let kindFilter = selectedKindFilter {
            filtered = filtered.filter { $0.kind == kindFilter }
        }

        return filtered.sorted { (a: Card, b: Card) in
            a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let outerSize = proxy.size
            let border = configuration.windowBorderWidth
            let contentSize = CGSize(width: max(0, outerSize.width - 2 * border),
                                     height: max(0, outerSize.height - 2 * border))

            ZStack {
                if let ds = dataSource {
                    // Canvas host inside the border
                    ZStack {
                        BoardCanvasView(
                            dataSource: ds,
                            configuration: configuration,
                            selectedNodeID: selectedCardID,
                            scheme: scheme,
                            isContentReady: isContentReady,
                            isDropTargetActive: $isDropTargetActive,
                            zoomScale: $zoomScale,
                            panX: $panX,
                            panY: $panY,
                            nodeSizes: $nodeSizes,
                            nodeVisualSizes: $nodeVisualSizes,
                            edgeCreationState: edgeCreationState,
                            onDropNodeIDs: { nodeIDs, location in
                                handleCardDropByIDs(cardIDs: nodeIDs, at: location)
                            },
                            onRemoveNode: { cardID in
                                removeCardFromBoard(cardID: cardID)
                            },
                            onSelectNode: { cardID in
                                selectedCardID = cardID
                            },
                            onEdgeCreated: { sourceID, targetID in
                                handleEdgeCreationRequest(sourceCardID: sourceID, targetCardID: targetID)
                            }
                        ) { node, isSelected, isPrimary in
                            // Cumberland-specific: render each node as a CardView
                            cardNodeView(for: node, isSelected: isSelected, isPrimary: isPrimary)
                        }
                        // Drop destination for cards from backlog
                        .dropDestination(for: CardTransferData.self) { items, location in
                            handleCardDrop(cards: items, at: location)
                        } isTargeted: { isTargeted in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDropTargetActive = isTargeted
                            }
                        }
                        // Capture CardView preference keys (Cumberland-specific size reporting)
                        .onPreferenceChange(CardViewActualSizeKey.self) { newSizes in
                            if !newSizes.isEmpty {
                                nodeSizes.merge(newSizes, uniquingKeysWith: { _, new in new })
                            }
                        }
                        .onPreferenceChange(CardViewVisualSizeKey.self) { newVisualSizes in
                            if !newVisualSizes.isEmpty {
                                nodeVisualSizes.merge(newVisualSizes, uniquingKeysWith: { _, new in new })
                            }
                        }
                    }
                    .padding(border)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: max(0, configuration.windowCornerRadius - configuration.windowBorderWidth),
                            style: .continuous
                        )
                    )
                    .modifier(BoardGestureIntegration(
                        dataSource: ds,
                        configuration: configuration,
                        canvasCoordSpace: canvasCoordSpace,
                        gestureHandler: $gestureHandler,
                        canvasGestureTarget: $canvasGestureTarget,
                        nodeGestureTargets: $nodeGestureTargets,
                        zoomScale: $zoomScale,
                        panX: $panX,
                        panY: $panY,
                        selectedNodeID: $selectedCardID,
                        nodeSizes: $nodeSizes,
                        nodeVisualSizes: $nodeVisualSizes,
                        windowSize: contentSize,
                        viewCanvasRect: {
                            BoardCanvasTransform.viewCanvasRect(
                                worldForWindowSize: contentSize,
                                scale: zoomScale,
                                panX: panX,
                                panY: panY
                            )
                        },
                        edgeCreationState: edgeCreationState,
                        onEdgeCreated: { sourceID, targetID in
                            handleEdgeCreationRequest(sourceCardID: sourceID, targetCardID: targetID)
                        },
                        onRightClickNode: { cardID, location, handler, coordinateInfo in
                            handleNodeRightClick(cardID: cardID, location: location, handler: handler, coordinateInfo: coordinateInfo)
                        },
                        isSidebarVisible: isSidebarVisible
                    ))

                    if isContentReady == false {
                        progressOverlay(contentSize: contentSize)
                    }

                    // Sidebar Backlog
                    SidebarPanel(
                        contentSize: contentSize,
                        scheme: scheme,
                        isSidebarVisible: $isSidebarVisible,
                        selectedKindFilter: $selectedKindFilter,
                        selectedBacklogCards: $selectedBacklogCards,
                        backlogCards: backlogCards,
                        onAddSelectedCards: { addSelectedCardsToBoard() }
                    )

                    #if os(macOS) || os(iOS)
                    BoardZoomStrip(
                        configuration: configuration,
                        zoomScale: $zoomScale,
                        windowSize: contentSize,
                        onStepZoom: { delta, ws in
                            guard let ds = dataSource else { return }
                            BoardRecenter.stepZoom(dataSource: ds, delta: delta, windowSize: ws, configuration: configuration)
                            zoomScale = ds.zoomScale
                            panX = ds.panX
                            panY = ds.panY
                        },
                        onSetZoom: { newScale, ws in
                            guard let ds = dataSource else { return }
                            BoardRecenter.setZoomKeepingCenter(dataSource: ds, newScale: newScale, windowSize: ws, configuration: configuration)
                            zoomScale = ds.zoomScale
                            panX = ds.panX
                            panY = ds.panY
                        },
                        onRecenter: { ws in
                            guard let ds = dataSource else { return }
                            BoardRecenter.recenterOnPrimary(dataSource: ds, windowSize: ws)
                            panX = ds.panX
                            panY = ds.panY
                        },
                        onShuffle: {
                            guard let ds = dataSource else { return }
                            BoardShuffleLayout.shuffleAroundPrimary(
                                dataSource: ds,
                                nodeSizeProvider: { nodeID in
                                    nodeVisualSizes[nodeID] ?? CGSize(width: 240, height: 160)
                                },
                                zoomScale: zoomScale,
                                configuration: configuration
                            )
                        }
                    )
                    .allowsHitTesting(true)
                    #endif
                } else {
                    ProgressView("Loading board...")
                }
            }
            .overlay(
                BoardBorderOverlay(configuration: configuration, scheme: scheme)
            )
            .clipShape(RoundedRectangle(cornerRadius: configuration.windowCornerRadius, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            #if os(visionOS)
            .toolbar { visionOSToolbarContent(windowSize: contentSize) }
            #endif
            .onChange(of: dataSource?.board?.id) {
                if let ds = dataSource, let board = ds.board,
                   didInitialRecenter == false,
                   contentSize.width > 0, contentSize.height > 0 {
                    initialRecenterIfNeeded(on: board, windowSize: contentSize)
                }
            }
            .onChange(of: contentSize) { _, newSize in
                if let ds = dataSource, let board = ds.board,
                   didInitialRecenter == false,
                   newSize.width > 0, newSize.height > 0 {
                    initialRecenterIfNeeded(on: board, windowSize: newSize)
                }
            }
        }
        .task {
            await loadBoardIfNeeded()
        }
        .onChange(of: dataSource?.board?.id) {
            applyBoardTransform()
            Task { await stageThumbnailsIfNeeded() }
        }
        .onChange(of: zoomScale) { _, newValue in
            let clamped = newValue.clamped(to: configuration.minZoom...configuration.maxZoom)
            if clamped != zoomScale { zoomScale = clamped; return }
            dataSource?.persistTransform()
        }
        .onChange(of: panX) { _, newValue in
            let clamped = newValue.clamped(to: configuration.minPan...configuration.maxPan)
            if clamped != panX { panX = clamped; return }
            dataSource?.persistTransform()
        }
        .onChange(of: panY) { _, newValue in
            let clamped = newValue.clamped(to: configuration.minPan...configuration.maxPan)
            if clamped != panY { panY = clamped; return }
            dataSource?.persistTransform()
        }
        #if DEBUG
        .onChange(of: selectedCardID) { old, new in
            let o = old?.uuidString ?? "nil"
            let n = new?.uuidString ?? "nil"
            print("[MB] Selection changed: \(o) -> \(n)")
        }
        #endif
        // Edge creation RelationType selection sheet (DR-0076)
        .sheet(item: $pendingEdgeCreation) { pending in
            EdgeCreationRelationTypeSheet(
                sourceCardID: pending.sourceCardID,
                targetCardID: pending.targetCardID,
                allRelationTypes: allRelationTypes,
                allCards: allCards,
                onSelect: { relationType in
                    createEdge(from: pending.sourceCardID, to: pending.targetCardID, type: relationType)
                },
                onCancel: { }
            )
            .frame(minWidth: 420, minHeight: 340)
        }
    }

    // MARK: - Card Node View (Cumberland-specific rendering)

    @ViewBuilder
    private func cardNodeView(for node: CumberlandNode, isSelected: Bool, isPrimary: Bool) -> some View {
        if let card = allCards.first(where: { $0.id == node.nodeID }) {
            CardView(card: card, showAIBadge: false)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: isSelected ? 4 : 0)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.12), value: isSelected)
                )
        } else {
            // Fallback for nodes without a visible card
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 80)
                .overlay(
                    Text(node.displayName)
                        .font(.headline)
                )
        }
    }

    // MARK: - Progress Overlay

    @ViewBuilder
    private func progressOverlay(contentSize: CGSize) -> some View {
        VStack(spacing: 8) {
            let total = prefetchProgress.total
            let done = prefetchProgress.done
            if total > 0 {
                let fraction = min(max(Double(done) / Double(total), 0.0), 1.0)
                ProgressView(value: fraction)
                    .progressViewStyle(.linear)
                    .frame(width: min(280, contentSize.width * 0.6))
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(width: min(280, contentSize.width * 0.6))
            }
            Text("Preparing board...")
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
        )
    }

    // MARK: - Right-Click Menu (Cumberland-specific)

    private func handleNodeRightClick(cardID: UUID, location: CGPoint, handler: MultiGestureHandler?, coordinateInfo: CoordinateSpaceInfo) {
        guard let ds = dataSource,
              let board = ds.board,
              let targetNode = (board.nodes ?? []).first(where: { $0.card?.id == cardID }),
              let card = targetNode.card else { return }

        let isPrimaryCard = (card.id == board.primaryCard?.id)

        let menuItems = [
            PopupMenuItem(
                title: "Remove \(card.name) from Board",
                systemImage: "minus.circle",
                isDestructive: false,
                isDisabled: isPrimaryCard,
                action: {
                    removeCardFromBoard(cardID: cardID)
                }
            )
        ]

        if let handler = handler {
            let popup = PopupMenu(
                items: menuItems,
                position: location,
                coordinateSpace: coordinateInfo
            )
            handler.showPopup(popup)
        }
    }

    // MARK: - visionOS Toolbar

    #if os(visionOS)
    @ToolbarContentBuilder
    func visionOSToolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                guard let ds = dataSource else { return }
                BoardRecenter.stepZoom(dataSource: ds, delta: -0.05, windowSize: windowSize, configuration: configuration)
                zoomScale = ds.zoomScale
                panX = ds.panX
                panY = ds.panY
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")

            Button {
                guard let ds = dataSource else { return }
                BoardRecenter.stepZoom(dataSource: ds, delta: 0.05, windowSize: windowSize, configuration: configuration)
                zoomScale = ds.zoomScale
                panX = ds.panX
                panY = ds.panY
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")

            Divider()

            Button {
                guard let ds = dataSource else { return }
                BoardRecenter.recenterOnPrimary(dataSource: ds, windowSize: windowSize)
                panX = ds.panX
                panY = ds.panY
            } label: {
                Label("Recenter", systemImage: "dot.scope")
            }
            .help("Recenter on primary node")

            Button {
                guard let ds = dataSource else { return }
                BoardShuffleLayout.shuffleAroundPrimary(
                    dataSource: ds,
                    nodeSizeProvider: { nodeID in
                        nodeVisualSizes[nodeID] ?? CGSize(width: 240, height: 160)
                    },
                    zoomScale: zoomScale,
                    configuration: configuration
                )
            } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .help("Arrange nodes around the primary in a ring")
        }
    }
    #endif
}

// MARK: - Board Load, Prefetch, and Transform

extension MurderBoardView {
    @MainActor
    func loadBoardIfNeeded() async {
        if dataSource == nil {
            let ds = CumberlandBoardDataSource(modelContext: modelContext)
            ds.allCards = allCards
            ds.loadBoard(for: primary)
            dataSource = ds
            zoomScale = ds.zoomScale
            panX = ds.panX
            panY = ds.panY
            await stageThumbnailsIfNeeded()
        }
    }

    func applyBoardTransform() {
        guard let ds = dataSource else { return }
        zoomScale = ds.zoomScale
        panX = ds.panX
        panY = ds.panY
    }

    @MainActor
    func stageThumbnailsIfNeeded() async {
        guard isContentReady == false else { return }
        guard let ds = dataSource, let board = ds.board else {
            isContentReady = true
            return
        }
        let cards = (board.nodes ?? []).compactMap { $0.card }
        guard !cards.isEmpty else {
            isContentReady = true
            return
        }

        prefetchProgress = (0, cards.count)

        let maxConcurrent = 2
        let launchStagger: UInt64 = 15_000_000

        await withTaskGroup(of: Void.self) { group in
            var active = 0
            var index = 0

            func addTask(for card: Card) {
                group.addTask {
                    _ = await card.makeThumbnailImage()
                    await MainActor.run {
                        self.prefetchProgress.done += 1
                    }
                }
                active += 1
            }

            while index < cards.count {
                while active < maxConcurrent && index < cards.count {
                    addTask(for: cards[index])
                    index += 1
                    try? await Task.sleep(nanoseconds: launchStagger)
                }
                await group.next()
                active = max(0, active - 1)
            }
            while await group.next() != nil { }
        }

        try? await Task.sleep(nanoseconds: 80_000_000)
        withAnimation(.easeInOut(duration: 0.15)) {
            isContentReady = true
        }
    }

    func initialRecenterIfNeeded(on board: Board, windowSize: CGSize) {
        guard didInitialRecenter == false else { return }

        board.ensurePrimaryPresence(in: modelContext)

        let pairs = (board.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !pairs.isEmpty else {
            didInitialRecenter = true
            return
        }
        let primaryID = board.primaryCard?.id
        let target = pairs.first(where: { $0.1.id == primaryID })?.0 ?? pairs.first!.0

        if abs(target.posX) < 0.0001 && abs(target.posY) < 0.0001 {
            let rect = BoardCanvasTransform.viewCanvasRect(
                worldForWindowSize: windowSize,
                scale: zoomScale,
                panX: panX,
                panY: panY
            )
            let center = CGPoint(x: rect.midX, y: rect.midY)
            target.posX = center.x.dg
            target.posY = center.y.dg
            try? modelContext.save()
        }

        let world = CGPoint(x: target.posX, y: target.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        dataSource?.persistTransform()

        didInitialRecenter = true
    }
}

// MARK: - Board Management

extension MurderBoardView {
    func handleCardDrop(cards: [CardTransferData], at location: CGPoint) -> Bool {
        guard let ds = dataSource, let board = ds.board else { return false }

        let worldLocation = BoardCanvasTransform.viewToWorld(
            location, scale: zoomScale, panX: panX, panY: panY
        )

        var addedAny = false

        for cardData in cards {
            let request = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardData.id }
            )

            guard let card = try? modelContext.fetch(request).first else { continue }

            let existingNode = (board.nodes ?? []).first { $0.card?.id == card.id }
            if existingNode != nil { continue }

            let node = board.node(
                for: card,
                in: modelContext,
                createIfMissing: true,
                defaultPosition: (worldLocation.x, worldLocation.y)
            )

            if cards.count > 1 {
                let offset = Double(cards.firstIndex(where: { $0.id == card.id }) ?? 0) * 50.0
                node?.posX += offset
                node?.posY += offset * 0.3
            }

            addedAny = true
        }

        if addedAny {
            try? modelContext.save()
            for cardData in cards {
                selectedBacklogCards.remove(cardData.id)
            }
        }

        return addedAny
    }

    func handleCardDropByIDs(cardIDs: [UUID], at location: CGPoint) -> Bool {
        guard let ds = dataSource else { return false }
        ds.addNodes(cardIDs, at: location)
        return true
    }

    func removeCardFromBoard(cardID: UUID) {
        guard let ds = dataSource else { return }
        ds.removeNode(cardID)
        if selectedCardID == cardID {
            selectedCardID = nil
        }
    }

    func addSelectedCardsToBoard() {
        guard !selectedBacklogCards.isEmpty else { return }
        guard let ds = dataSource else { return }

        let worldCenter = BoardCanvasTransform.worldCenter(
            forWindowSize: CGSize(width: 400, height: 300),
            scale: zoomScale,
            panX: panX,
            panY: panY
        )

        ds.addNodes(Array(selectedBacklogCards), at: worldCenter)
        selectedBacklogCards.removeAll()
    }
}

// MARK: - Edge Creation (DR-0076)

extension MurderBoardView {
    func handleEdgeCreationRequest(sourceCardID: UUID, targetCardID: UUID) {
        #if DEBUG
        print("[MB] Edge creation requested: \(sourceCardID) -> \(targetCardID)")
        #endif

        pendingEdgeCreation = PendingEdgeCreation(
            sourceCardID: sourceCardID,
            targetCardID: targetCardID
        )
    }

    func createEdge(from sourceID: UUID, to targetID: UUID, type: RelationType) {
        guard let sourceCard = allCards.first(where: { $0.id == sourceID }),
              let targetCard = allCards.first(where: { $0.id == targetID }) else {
            #if DEBUG
            print("[MB] Edge creation failed: could not find cards")
            #endif
            pendingEdgeCreation = nil
            return
        }

        if let mgr = services?.relationshipManager {
            do {
                try mgr.createRelationship(from: sourceCard, to: targetCard, type: type, createReverse: true)
            } catch RelationshipError.alreadyExists {
                #if DEBUG
                print("[MB] Both edges already exist, skipping creation")
                #endif
            } catch {
                #if DEBUG
                print("[MB] Edge creation via RelationshipManager failed: \(error)")
                #endif
            }
            pendingEdgeCreation = nil
            return
        }

        // Fallback: direct modelContext operations
        let forwardExists = sourceCard.outgoingEdges?.contains { edge in
            edge.to?.id == targetID && edge.type?.code == type.code
        } ?? false

        let reverseExists = targetCard.outgoingEdges?.contains { edge in
            edge.to?.id == sourceID && edge.type?.code == type.code
        } ?? false

        if forwardExists && reverseExists {
            pendingEdgeCreation = nil
            return
        }

        if !forwardExists {
            let forwardEdge = CardEdge(from: sourceCard, to: targetCard, type: type)
            modelContext.insert(forwardEdge)
        }

        if !reverseExists {
            let reverseEdge = CardEdge(from: targetCard, to: sourceCard, type: type)
            modelContext.insert(reverseEdge)
        }

        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("[MB] Edge creation save failed: \(error)")
            #endif
        }

        pendingEdgeCreation = nil
    }
}

// MARK: - Preview

#Preview("Murder Board (seeded)") {
    let schema = Schema([Card.self, Board.self, BoardNode.self, CardEdge.self, RelationType.self])
    let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [cfg])
    let ctx = container.mainContext
    ctx.autosaveEnabled = false

    let mira = Card(kind: .characters, name: "Mira", subtitle: "Explorer", detailedText: "")
    let jonas = Card(kind: .characters, name: "Historian", subtitle: "Historian", detailedText: "")
    let aster = Card(kind: .characters, name: "Mechanic", subtitle: "Mechanic", detailedText: "")
    let eden = Card(kind: .worlds, name: "Eden-3", subtitle: "Frontier World", detailedText: "")
    let opening = Card(kind: .scenes, name: "Opening Scene", subtitle: "Crash Site", detailedText: "")
    let artifact = Card(kind: .artifacts, name: "Ancient Artifact", subtitle: "Unknown origin", detailedText: "")

    ctx.insert(mira)
    ctx.insert(jonas)
    ctx.insert(aster)
    ctx.insert(eden)
    ctx.insert(opening)
    ctx.insert(artifact)

    let appearsIn = RelationType(code: "appears-in/is-appeared-by",
                                 forwardLabel: "appears in",
                                 inverseLabel: "is appeared by",
                                 sourceKind: .characters,
                                 targetKind: .scenes)
    let references = RelationType(code: "references/referenced-by",
                                  forwardLabel: "references",
                                  inverseLabel: "referenced by")
    ctx.insert(appearsIn)
    ctx.insert(references)

    ctx.insert(CardEdge(from: mira, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: jonas, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: aster, to: opening, type: appearsIn))
    ctx.insert(CardEdge(from: mira, to: artifact, type: references))
    ctx.insert(CardEdge(from: jonas, to: eden, type: references))

    let board = Board.fetchOrCreatePrimaryBoard(for: mira, in: ctx)
    board.zoomScale = 1.0
    board.panX = 0
    board.panY = 0
    board.clampState()

    _ = board.node(for: mira, in: ctx, createIfMissing: true, defaultPosition: (0, 0))
    _ = board.node(for: jonas, in: ctx, createIfMissing: true, defaultPosition: (280, -40))
    _ = board.node(for: aster, in: ctx, createIfMissing: true, defaultPosition: (-260, 60))
    _ = board.node(for: eden, in: ctx, createIfMissing: true, defaultPosition: (0, -260))
    _ = board.node(for: opening, in: ctx, createIfMissing: true, defaultPosition: (0, 260))
    _ = board.node(for: artifact, in: ctx, createIfMissing: true, defaultPosition: (-120, -240))

    try? ctx.save()

    return NavigationStack {
        MurderBoardView(primary: mira)
    }
    .modelContainer(container)
    .frame(minWidth: 820, minHeight: 560)
}
