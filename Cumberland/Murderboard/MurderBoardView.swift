//
//  MurderBoardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/19/25.
//  Refactored as part of ER-0022 Phase 3.3
//  Extracted components:
//  - MurderBoardGestureTargets.swift (gesture targets and handler integration)
//  - MurderBoardToolbar.swift (toolbar and zoom controls)
//  - MurderBoardOperations.swift (board operations, persistence, transforms)

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CloudKit

#if canImport(Testing)
import Testing
#endif

struct MurderBoardView: View {
    let primary: Card

    @Environment(\.modelContext) var modelContext
    @Environment(\.colorScheme) var scheme

    // Query for all cards (used by backlog)
    @Query(sort: \Card.name) private var allCards: [Card]

    // Persisted board for this primary
    @State var board: Board?

    // Live transform state (mirrors board.zoomScale/panX/panY; persisted on changes)
    @State var zoomScale: Double = 1.0   // S
    @State var panX: Double = 0.0        // T.x (view points)
    @State var panY: Double = 0.0        // T.y (view points)

    // Selection (single)
    @State var selectedCardID: UUID? = nil

    // One-time initial recenter
    @State var didInitialRecenter: Bool = false

    // Staging flag to avoid heavy simultaneous image uploads during first render
    @State var isContentReady: Bool = false
    @State var prefetchProgress: (done: Int, total: Int) = (0, 0)

    // Live unscaled sizes measured for each CardView (pre-transform, full layout size)
    @State var nodeSizes: [UUID: CGSize] = [:]
    // Visual card-shape sizes reported by CardView (excludes outer padding for tabs)
    @State var nodeVisualSizes: [UUID: CGSize] = [:]
    // Track whether we have all visual sizes needed for gesture setup
    @State private var visualSizesReady: Bool = false

    // Named coordinate space for consistent math (canvas/view space)
    let canvasCoordSpace = "MurderBoardCanvasSpace"

    // Drag & Drop state
    @State private var isDropTargetActive: Bool = false

    // MARK: - Sidebar Backlog state

    @State var isSidebarVisible: Bool = true
    @State var selectedKindFilter: Kinds? = nil
    @State var selectedBacklogCards: Set<UUID> = []
    @State private var draggedCard: Card? = nil

    // MARK: - MultiGesture Handler Integration

    // Feature flag to control gesture handling system
    @State private var useNewGestureHandler: Bool = true

    // MultiGestureHandler instance and targets
    @State var gestureHandler: MultiGestureHandler? = nil
    @State var canvasGestureTarget: CanvasGestureTarget? = nil
    @State var nodeGestureTargets: [UUID: NodeGestureTarget] = [:]

    init(primary: Card) {
        self.primary = primary
    }

    // MARK: - Backlog Cards Query

    var backlogCards: [Card] {
        guard let b = board else { return allCards }
        let cardsOnBoard = Set((b.nodes ?? []).compactMap { $0.card?.id })
        var filtered = allCards.filter { !cardsOnBoard.contains($0.id) }

        // Apply kind filter if selected
        if let kindFilter = selectedKindFilter {
            filtered = filtered.filter { $0.kind == kindFilter }
        }

        // Sort by name for consistent ordering
        return filtered.sorted { (a: Card, b: Card) in
            a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    // Check if we have visual sizes for all nodes on the board
    private var hasAllVisualSizes: Bool {
        guard let b = board else { return true }
        let nodeCardIDs = Set((b.nodes ?? []).compactMap { $0.card?.id })
        let measuredCardIDs = Set(nodeVisualSizes.keys)
        return nodeCardIDs.isSubset(of: measuredCardIDs)
    }

    var body: some View {
        GeometryReader { proxy in
            let outerSize = proxy.size
            let border = windowBorderWidth
            let contentSize = CGSize(width: max(0, outerSize.width - 2 * border),
                                     height: max(0, outerSize.height - 2 * border))
            let contentCenter = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)

            // A key that changes when the set of nodes (by card ID) changes
            let nodesKey: [UUID] = {
                guard let nodes = board?.nodes else { return [] }
                return nodes.compactMap { $0.card?.id }.sorted { $0.uuidString < $1.uuidString }
            }()

            ZStack {
                // Canvas host inside the border
                ZStack {
                    CanvasLayer(
                        board: board,
                        windowSize: contentSize,
                        windowCenter: contentCenter,
                        selectedCardID: selectedCardID,
                        primaryCardID: primary.id,
                        scheme: scheme,
                        isContentReady: isContentReady,
                        canvasCoordSpace: canvasCoordSpace,
                        isDropTargetActive: $isDropTargetActive,
                        zoomScale: $zoomScale,
                        panX: $panX,
                        panY: $panY,
                        nodeSizes: $nodeSizes,
                        nodeVisualSizes: $nodeVisualSizes,
                        selectedKindFilter: selectedKindFilter,
                        selectedBacklogCards: $selectedBacklogCards,
                        isSidebarVisible: isSidebarVisible,
                        backlogCards: backlogCards,
                        worldToView: worldToView,
                        viewToWorld: viewToWorld,
                        onCardDrop: { items, location in
                            handleCardDrop(cards: items, at: location)
                        },
                        onRemoveCard: { id in
                            removeCardFromBoard(cardID: id)
                        },
                        onSelectCard: { id in
                            $selectedCardID.wrappedValue = id
                        }
                    )
                }
                .padding(border)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: max(0, windowCornerRadius - windowBorderWidth),
                        style: .continuous
                    )
                )
                .modifier(GestureHandlerIntegration(
                    useNewGestureHandler: useNewGestureHandler,
                    gestureHandler: $gestureHandler,
                    canvasGestureTarget: $canvasGestureTarget,
                    nodeGestureTargets: $nodeGestureTargets,
                    canvasCoordSpace: canvasCoordSpace,
                    zoomScale: $zoomScale,
                    panX: $panX,
                    panY: $panY,
                    selectedCardID: $selectedCardID,
                    board: board,
                    modelContext: modelContext,
                    nodeSizes: $nodeSizes,
                    nodeVisualSizes: $nodeVisualSizes,
                    windowSize: contentSize,
                    viewCanvasRect: { viewCanvasRect(worldForWindowSize: contentSize) },
                    persistTransform: persistTransformNow,
                    removeCardFromBoard: removeCardFromBoard,
                    nodesKey: nodesKey
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
            }
            .overlay(borderCanvasOverlay())
            .clipShape(RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .toolbar { toolbarContent(windowSize: contentSize) }
            .onChange(of: board?.id) {
                if let b = board, didInitialRecenter == false, contentSize.width > 0, contentSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: contentSize)
                }
            }
            .onChange(of: contentSize) { _, newSize in
                if let b = board, didInitialRecenter == false, newSize.width > 0, newSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: newSize)
                }
            }
        }
        .task {
            await loadBoardIfNeeded()
        }
        .onChange(of: board?.id) {
            applyBoardTransform()
            Task { await stageThumbnailsIfNeeded() }
        }
        .onChange(of: zoomScale) { _, newValue in
            let clamped = newValue.clamped(to: Board.minZoom...Board.maxZoom)
            if clamped != zoomScale { zoomScale = clamped; return }
            persistTransformDebounced()
        }
        .onChange(of: panX) { _, newValue in
            let clamped = newValue.clamped(to: Board.minPan...Board.maxPan)
            if clamped != panX { panX = clamped; return }
            persistTransformDebounced()
        }
        .onChange(of: panY) { _, newValue in
            let clamped = newValue.clamped(to: Board.minPan...Board.maxPan)
            if clamped != panY { panY = clamped; return }
            persistTransformDebounced()
        }
        #if DEBUG
        .onChange(of: selectedCardID) { old, new in
            let o = old?.uuidString ?? "nil"
            let n = new?.uuidString ?? "nil"
            print("[MB] Selection changed: \(o) → \(n)")
        }
        #endif
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
            Text("Preparing board…")
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

#if canImport(Testing)
// MARK: - MurderBoard Verification Suite (Phases 0–14)

@Suite("MurderBoardView Verification (Phases 0–14)")
struct MurderBoardVerification {
    // [tests unchanged]
}
#endif
