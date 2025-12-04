//
//  MurderBoardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/19/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CloudKit

#if canImport(Testing)
import Testing
#endif

// MARK: - Stage 1-6: Gesture Target Implementations

/// Canvas-level gesture target for pan, pinch, and background tap
@MainActor
final class CanvasGestureTarget: GestureTarget {
    let gestureID = UUID()
    
    // Callbacks to the view
    var onTransformChanged: ((Double, Double, Double) -> Void)?
    var onTransformCommit: (() -> Void)?
    var onSelectionChanged: ((UUID?) -> Void)?
    
    // Transform state access
    var getCurrentTransform: (() -> (scale: Double, panX: Double, panY: Double))?
    var getWindowSize: (() -> CGSize)?
    var getCanvasRect: (() -> CGRect)?
    
    var worldBounds: CGRect {
        // Canvas target covers the entire canvas area
        getCanvasRect?() ?? CGRect(x: -10000, y: -10000, width: 20000, height: 20000)
    }
    
    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .pinch, .twoFingerPan:
            return true
        case .drag, .doubleTap, .rightClick:
            return false // Let node targets handle these first
        }
    }
    
    func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            // Background tap - clear selection
            onSelectionChanged?(nil)
            
        case .pinchBegan(_, _, _, _):
            // Start pinch - no immediate action needed
            break
            
        case .pinchChanged(let scale, _, let center, let coordinateInfo):
            // Update zoom keeping center point fixed
            if let transform = getCurrentTransform?() {
                
                let centerWorld = coordinateInfo.toWorldSpace(center)
                let newScale = (transform.scale * scale).clamped(to: Board.minZoom...Board.maxZoom)
                
                // Adjust pan to keep world point under center fixed
                let newPanX = center.x - centerWorld.x * newScale
                let newPanY = center.y - centerWorld.y * newScale
                
                onTransformChanged?(newScale, newPanX, newPanY)
            }
            
        case .pinchEnded(_, _, _, _):
            // Commit transform changes
            onTransformCommit?()
            
        case .twoFingerPanBegan(_, _):
            // Start two-finger pan - no immediate action needed
            break
            
        case .twoFingerPanChanged(let translation, _, _):
            // Update pan translation
            if let transform = getCurrentTransform?() {
                let newPanX = (transform.panX + translation.width).clamped(to: Board.minPan...Board.maxPan)
                let newPanY = (transform.panY + translation.height).clamped(to: Board.minPan...Board.maxPan)
                onTransformChanged?(transform.scale, newPanX, newPanY)
            }
            
        case .twoFingerPanEnded(_, _, _, _):
            // Commit transform changes
            onTransformCommit?()
            
        default:
            break
        }
    }
}

/// Node-level gesture target for drag and selection
@MainActor
final class NodeGestureTarget: GestureTarget {
    let gestureID = UUID()
    let cardID: UUID
    let isPrimary: Bool
    private var dragStartWorldPosition: CGPoint = .zero
    private var dragGrabOffset: CGPoint = .zero
    
    // Callbacks to the view
    var onSelectionChanged: ((UUID?) -> Void)?
    var onNodeMoved: ((UUID, CGPoint) -> Void)?
    var onNodeMoveCommit: ((UUID) -> Void)?
    var onRightClick: ((UUID, CGPoint) -> Void)?
    
    // Position and size access
    var getNodeWorldBounds: ((UUID) -> CGRect)?
    
    init(cardID: UUID, isPrimary: Bool = false) {
        self.cardID = cardID
        self.isPrimary = isPrimary
    }
    
    var worldBounds: CGRect {
        getNodeWorldBounds?(cardID) ?? CGRect.zero
    }
    
    func canHandleGesture(_ gesture: GestureType) -> Bool {
        switch gesture {
        case .tap, .drag, .rightClick, .doubleTap:
            return true
        case .pinch, .twoFingerPan:
            return false // Let canvas handle these
        }
    }
    
    func handleGesture(_ gesture: GestureEvent) {
        switch gesture {
        case .tap(_, _):
            // Node tap - select this node
            onSelectionChanged?(cardID)
            
        case .dragBegan(let startLocation, let coordinateInfo):
            // Ensure this node becomes selected when dragging starts
            onSelectionChanged?(cardID)
            // Start dragging this node
            let worldStart = coordinateInfo.toWorldSpace(startLocation)
            let nodeCenter = CGPoint(x: worldBounds.midX, y: worldBounds.midY)
            dragStartWorldPosition = nodeCenter
            dragGrabOffset = CGPoint(x: worldStart.x - nodeCenter.x, y: worldStart.y - nodeCenter.y)
            
        case .dragChanged(let location, _, let coordinateInfo):
            // Update node position preserving grab offset
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(cardID, newNodeCenter)
            
        case .dragEnded(let location, _, _, let coordinateInfo):
            // Commit node position
            let worldPointer = coordinateInfo.toWorldSpace(location)
            let newNodeCenter = CGPoint(
                x: worldPointer.x - dragGrabOffset.x,
                y: worldPointer.y - dragGrabOffset.y
            )
            onNodeMoved?(cardID, newNodeCenter)
            onNodeMoveCommit?(cardID)
            
        case .rightClick(let location, _):
            #if DEBUG
            print("NodeGestureTarget: rightClick gestureID= \(gestureID), cardID= \(cardID).  isPrimary=\( isPrimary ? "true" : "false" )")
            #endif
            // Node right-click - ensure selection happens first SYNCHRONOUSLY
            onSelectionChanged?(cardID)
            // Process right-click immediately after selection (no async Task needed)
            onRightClick?(cardID, location)
            
        default:
            break
        }
    }
}

struct MurderBoardView: View {
    let primary: Card

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Query for all cards (used by backlog)
    @Query(sort: \Card.name) private var allCards: [Card]

    // Persisted board for this primary
    @State private var board: Board?

    // Live transform state (mirrors board.zoomScale/panX/panY; persisted on changes)
    @State private var zoomScale: Double = 1.0   // S
    @State private var panX: Double = 0.0        // T.x (view points)
    @State private var panY: Double = 0.0        // T.y (view points)

    // Selection (single)
    @State private var selectedCardID: UUID? = nil

    // One-time initial recenter
    @State private var didInitialRecenter: Bool = false

    // Staging flag to avoid heavy simultaneous image uploads during first render
    @State private var isContentReady: Bool = false
    @State private var prefetchProgress: (done: Int, total: Int) = (0, 0)

    // Live unscaled sizes measured for each CardView (pre-transform, full layout size)
    @State private var nodeSizes: [UUID: CGSize] = [:]
    // Visual card-shape sizes reported by CardView (excludes outer padding for tabs)
    @State private var nodeVisualSizes: [UUID: CGSize] = [:]
    // Track whether we have all visual sizes needed for gesture setup
    @State private var visualSizesReady: Bool = false

    // Named coordinate space for consistent math (canvas/view space)
    fileprivate let canvasCoordSpace = "MurderBoardCanvasSpace"

    // Drag & Drop state (0690-0710)
    @State private var isDropTargetActive: Bool = false

    // MARK: - Sidebar Backlog state (0580-0610)
    
    @State private var isSidebarVisible: Bool = true // 0622: Initially visible
    @State private var selectedKindFilter: Kinds? = nil
    @State private var selectedBacklogCards: Set<UUID> = []
    @State private var draggedCard: Card? = nil

    // MARK: - Debug instrumentation
    // (No context menu state needed - handled by MultiGestureHandler now)

    // MARK: - Stage 0-6: MultiGesture Handler Integration Complete
    
    // Feature flag to control gesture handling system (Stage 6: default to new system)
    @State private var useNewGestureHandler: Bool = true
    
    // MultiGestureHandler instance and targets (Stages 1-6)
    @State private var gestureHandler: MultiGestureHandler? = nil
    @State private var canvasGestureTarget: CanvasGestureTarget? = nil
    @State private var nodeGestureTargets: [UUID: NodeGestureTarget] = [:]

    init (primary: Card) {
        self.primary = primary
    }
    
    // MARK: - Backlog Cards Query (0600, 0610)
    
    // Cards available for the backlog (exclude those already on the board)
    private var backlogCards: [Card] {
        guard let b = board else { return allCards }
        let cardsOnBoard = Set((b.nodes ?? []).compactMap { $0.card?.id })
        var filtered = allCards.filter { !cardsOnBoard.contains($0.id) }
        
        // Apply kind filter if selected (0640)
        if let kindFilter = selectedKindFilter {
            filtered = filtered.filter { $0.kind == kindFilter }
        }
        
        // Sort by name for consistent ordering
        return filtered.sorted { (a: Card, b: Card) in
            a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    } //end backlogCards
    
    // Check if we have visual sizes for all nodes on the board
    private var hasAllVisualSizes: Bool {
        guard let b = board else { return true }
        let nodeCardIDs = Set((b.nodes ?? []).compactMap { $0.card?.id })
        let measuredCardIDs = Set(nodeVisualSizes.keys)
        return nodeCardIDs.isSubset(of: measuredCardIDs)
    }

    var body: some View {
        GeometryReader { proxy in
            // Phase 1: View Window shell
            let outerSize = proxy.size
            let border = windowBorderWidth
            // Content (canvas) size accounts for the border inset so the canvas is fully inside the border
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
                } //end ZStack canvasLayer
                .padding(border)
                // Clip canvas to the inner edge of the border (0054)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: max(0, windowCornerRadius - windowBorderWidth),
                        style: .continuous
                    )
                ) //end .clipShape
                // Stage 1-6: Apply MultiGestureHandler integration
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
                    // Lightweight progress overlay while thumbnails are being prefetched
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
                        } //end if titalo >0 else
                        Text("Preparing board…")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } //end VStack
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 8)
                    ) //end .background
                } //end if isContentReady == false
                
                // MARK: - Sidebar Backlog (0580-0680)
                
                SidebarPanel(
                    contentSize: contentSize,
                    scheme: scheme,
                    isSidebarVisible: $isSidebarVisible,
                    selectedKindFilter: $selectedKindFilter,
                    selectedBacklogCards: $selectedBacklogCards,
                    backlogCards: backlogCards,
                    onAddSelectedCards: { addSelectedCardsToBoard() }
                )
            } //end ZStack
            // Outer rounded border drawn on top (0052)
            .overlay(
                borderCanvasOverlay()
            ) //end .overlay
            .clipShape(RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .toolbar { toolbarContent(windowSize: contentSize) }
            .onChange(of: board?.id) {
                if let b = board, didInitialRecenter == false, contentSize.width > 0, contentSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: contentSize)
                } //end if let b = ...
            } //end .onChange((of:)
            .onChange(of: contentSize) { _, newSize in
                if let b = board, didInitialRecenter == false, newSize.width > 0, newSize.height > 0 {
                    initialRecenterIfNeeded(on: b, windowSize: newSize)
                } //end if let b = ...
            } //end .onChange(of:)
        } //end GeometryReader
        // Phase 2: Load board and wire transform state with clamping/persistence
        .task {
            await loadBoardIfNeeded()
        } //end .task
        .onChange(of: board?.id) {
            applyBoardTransform()
            Task { await stageThumbnailsIfNeeded() }
        } //end .onChange(of:)
        .onChange(of: zoomScale) { _, newValue in
            let clamped = newValue.clamped(to: Board.minZoom...Board.maxZoom)
            if clamped != zoomScale { zoomScale = clamped; return }
            persistTransformDebounced()
        } //end .onChange(of:)
        .onChange(of: panX) { _, newValue in
            let clamped = newValue.clamped(to: Board.minPan...Board.maxPan)
            if clamped != panX { panX = clamped; return }
            persistTransformDebounced()
        } //end .onChange(of:)
        .onChange(of: panY) { _, newValue in
            let clamped = newValue.clamped(to: Board.minPan...Board.maxPan)
            if clamped != panY { panY = clamped; return }
            persistTransformDebounced()
        } //end .onChange(of:)
        #if DEBUG
        .onChange(of: selectedCardID) { old, new in
            let o = old?.uuidString ?? "nil"
            let n = new?.uuidString ?? "nil"
            print("[MB] Selection changed: \(o) → \(n)")
        } //end .onChange(of:)
        #endif
    } //end var body
} //end struct MurderBoardView

extension MurderBoardView {
    func borderCanvasOverlay() -> some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                    .fill(Color.clear)

                RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                    .stroke(windowBorderColor, lineWidth: windowBorderWidth)

                RoundedRectangle(cornerRadius: max(0, windowCornerRadius - windowBorderWidth / 2), style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                windowInnerShadowColor.opacity(scheme == .dark ? 0.55 : 0.85),
                                windowInnerShadowColor.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), //end LinearGradient
                        lineWidth: 2
                    ) //end .stroke
                    .mask(
                        RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                            .stroke(lineWidth: windowBorderWidth)
                    ) //end .mask
                    .blendMode(.overlay)
                    .opacity(scheme == .dark ? 0.5 : 0.8)
            } //end ZStack
            .allowsHitTesting(false)
        } //end Geometry Reader
    } //end borderOverlay
} //end extension MurderBoardView

// MARK: - Stage 1-6: Gesture Handler Integration ViewModifier

struct GestureHandlerIntegration: ViewModifier {
    let useNewGestureHandler: Bool
    @Binding var gestureHandler: MultiGestureHandler?
    @Binding var canvasGestureTarget: CanvasGestureTarget?
    @Binding var nodeGestureTargets: [UUID: NodeGestureTarget]
    
    let canvasCoordSpace: String
    @Binding var zoomScale: Double
    @Binding var panX: Double
    @Binding var panY: Double
    @Binding var selectedCardID: UUID?
    
    let board: Board?
    let modelContext: ModelContext
    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]
    let windowSize: CGSize
    let viewCanvasRect: () -> CGRect
    let persistTransform: () -> Void
    let removeCardFromBoard: (UUID) -> Void
    let nodesKey: [UUID]
    
    // Check if we have visual sizes for all nodes on the board
    private var hasAllVisualSizes: Bool {
        guard let b = board else { return true }
        let nodeCardIDs = Set((b.nodes ?? []).compactMap { $0.card?.id })
        let measuredCardIDs = Set(nodeVisualSizes.keys)
        return nodeCardIDs.isSubset(of: measuredCardIDs)
    }
    
    func body(content: Content) -> some View {
        if useNewGestureHandler {
            content
                .onAppear {
                    setupGestureHandler()
                }
                .onChange(of: board?.id) { _, _ in
                    setupGestureHandler()
                }
                .onChange(of: nodesKey) { _, _ in
                    // Nodes membership changed (drop/add/remove) — rebuild gesture targets
                    // Defer setup slightly to allow CardViews to report their sizes
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                        if hasAllVisualSizes {
                            setupGestureHandler()
                        }
                    }
                }
                .onChange(of: nodeVisualSizes) { _, _ in
                    // Visual sizes updated - rebuild gesture targets if we have all sizes
                    if !nodesKey.isEmpty && hasAllVisualSizes {
                        setupGestureHandler()
                    }
                }
                .multiGestureHandler(
                    gestureHandler ?? setupAndReturnGestureHandler(),
                    coordinateInfo: CoordinateSpaceInfo(
                        spaceName: canvasCoordSpace,
                        transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale).translatedBy(x: panX, y: panY),
                        zoomScale: zoomScale,
                        panOffset: CGPoint(x: panX, y: panY)
                    )
                )
        } else {
            // Fallback: Use legacy gesture handling (if any)
            content
        }
    }
    
    private func setupAndReturnGestureHandler() -> MultiGestureHandler {
        let handler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        gestureHandler = handler
        setupGestureHandler()
        return handler
    }
    
    private func setupGestureHandler() {
        guard useNewGestureHandler else { return }
        
        // Check if we have all visual sizes before proceeding
        guard hasAllVisualSizes else {
            #if DEBUG
            print("setupGestureHandler: Waiting for visual sizes. Have \(nodeVisualSizes.count) of \(nodesKey.count) needed.")
            #endif
            return
        }
        
        #if DEBUG
        print("setupGestureHandler: All visual sizes ready, proceeding with setup.")
        #endif
        
        // Create handler if it doesn't exist, otherwise reuse existing
        if gestureHandler == nil {
            gestureHandler = MultiGestureHandler(coordinateSpace: canvasCoordSpace)
        }
        
        guard let handler = gestureHandler else { return }
        
        // Clear existing targets to avoid duplicates
        nodeGestureTargets.removeAll()
        
        // Setup (or reuse) canvas gesture target instance
        if canvasGestureTarget == nil {
            canvasGestureTarget = CanvasGestureTarget()
        }
        guard let canvasTarget = canvasGestureTarget else { return }
        
        // Configure canvas target callbacks
        canvasTarget.onTransformChanged = { scale, newPanX, newPanY in
            zoomScale = scale
            panX = newPanX
            panY = newPanY
            print("Canvas transform changed to: \(scale), \(newPanX), \(newPanY)")
        }
        
        canvasTarget.onTransformCommit = {
            persistTransform()
        }
        
        canvasTarget.onSelectionChanged = { cardID in
            selectedCardID = cardID
        }
        
        canvasTarget.getCurrentTransform = {
            (scale: zoomScale, panX: panX, panY: panY)
        }
        
        canvasTarget.getWindowSize = {
            windowSize
        }
        
        canvasTarget.getCanvasRect = {
            viewCanvasRect()
        }
        
        // Register canvas target first; nodes will be registered after and thus win taps over canvas
        print("Registering canvas target")
        handler.registerTarget(canvasTarget)
        
        // Setup node targets for each card on the board (sort by zIndex so topmost registers last)
        if let nodeArray = board?.nodes {
            let sortedNodes = nodeArray.sorted { $0.zIndex < $1.zIndex }
            for node in sortedNodes {
                guard let card = node.card else { continue }
                let primaryCard = node.board?.primaryCard
                let isPrimary = (card.id == primaryCard?.id)
                
                let nodeTarget = NodeGestureTarget(cardID: card.id, isPrimary: isPrimary)
                
                // Configure node target callbacks
                nodeTarget.onSelectionChanged = { cardID in
                    selectedCardID = cardID
                }
                
                nodeTarget.onNodeMoved = { cardID, worldPos in
                    // Look up from the live board each time (avoid captured snapshots)
                    if let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }) {
                        targetNode.posX = worldPos.x
                        targetNode.posY = worldPos.y
                    }
                }
                
                nodeTarget.onNodeMoveCommit = { _ in
                    try? modelContext.save()
                }
                
                nodeTarget.onRightClick = { cardID, location in
                    #if DEBUG
                    print("[MB] Right-click on node \(cardID)")
                    #endif
                    
                    // Create popup menu for the node
                    guard let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }),
                          let card = targetNode.card else { return }
                    
                    // Check if this is the primary card
                    let isPrimaryCard = (card.id == board?.primaryCard?.id)
                    
                    let menuItems = [
                        PopupMenuItem(
                            title: "Remove \(card.name) from Board",
                            systemImage: "minus.circle",
                            isDestructive: false,
                            isDisabled: isPrimaryCard,
                            action: {
                                removeCardFromBoard(cardID)
                            }
                        )
                    ]
                    
                    // Show popup through gesture handler
                    if let handler = gestureHandler {
                        let coordinateInfo = CoordinateSpaceInfo(
                            spaceName: canvasCoordSpace,
                            transform: CGAffineTransform(scaleX: zoomScale, y: zoomScale).translatedBy(x: panX, y: panY),
                            zoomScale: zoomScale,
                            panOffset: CGPoint(x: panX, y: panY)
                        )
                        
                        let popup = PopupMenu(
                            items: menuItems,
                            position: location,
                            coordinateSpace: coordinateInfo
                        )
                        
                        handler.showPopup(popup)
                    }
                }
                
                nodeTarget.getNodeWorldBounds = { cardID in
                    // Compute world-space bounds for the node using live board lookup
                    guard let targetNode = board?.nodes?.first(where: { $0.card?.id == cardID }) else {
                        return CGRect.zero
                    }
                    
                    let nodeCenter = CGPoint(x: targetNode.posX, y: targetNode.posY)
                    
                    // Use visual size if available, otherwise fall back to layout size
                    let sizePoints: CGSize
                    if let visualSize = nodeVisualSizes[cardID] {
                        sizePoints = visualSize
                    } else if let layoutSize = nodeSizes[cardID] {
                        sizePoints = layoutSize
                    } else {
                        sizePoints = CGSize(width: 50, height: 50) // Fallback
                    }
                    
                    // Convert to world space
                    _ = max(zoomScale, 0.000001)
                    let worldSize = CGSize(
                        width: sizePoints.width,
                        height: sizePoints.height
                    )
                    
                    let worldRect = CGRect(
                        x: nodeCenter.x - worldSize.width / 2,
                        y: nodeCenter.y - worldSize.height / 2,
                        width: worldSize.width,
                        height: worldSize.height
                    )
                    
                    return worldRect
                }
                
                // Register node target
                #if DEBUG
                print("Registering node target for card \(card.name) with visual size: \(nodeVisualSizes[card.id] ?? CGSize.zero)")
                #endif
                handler.registerTarget(nodeTarget)
                nodeGestureTargets[card.id] = nodeTarget
            }
        }
    }
}

// MARK: - Constants

private let windowCornerRadius: CGFloat = 18
private let windowBorderWidth: CGFloat = 12

private var windowBorderColor: Color { .secondary.opacity(0.55) }
private var windowInnerShadowColor: Color { .white.opacity(0.18) }

// MARK: Shuffle geometry tuning (smaller, tighter rings)

private let shuffleInitialAnchorFactor: CGFloat = 0.35
private let shuffleInitialNodeSpanFactor: CGFloat = 0.45
private let shuffleBaseMarginWorldFactor: CGFloat = 0.10
private let shuffleBaseMarginViewPadding: CGFloat = 8.0
private let shuffleSpacingMultiplier: CGFloat = 1.15
private let shuffleRingSeparationMultiplier: CGFloat = 0.75
private let shuffleRadialJitterWorld: ClosedRange<Double> = -0.06...0.06
private let shuffleAngularJitter: ClosedRange<Double> = -0.12...0.12

// MARK: - Transform Helper (file-scoped to enable direct tests)

// MARK: - Canvas

fileprivate extension MurderBoardView {
    // World→View transform: v = w*S + T
    func worldToView(_ world: CGPoint) -> CGPoint {
        CanvasLayerTransform.worldToView(world, scale: zoomScale, panX: panX, panY: panY)
    } //end func worldToView

    // View→World inverse: w = (v − T)/S
    func viewToWorld(_ view: CGPoint) -> CGPoint {
        CanvasLayerTransform.viewToWorld(view, scale: zoomScale, panX: panX, panY: panY)
    } //end func viewToWorld

    // View Canvas Rectangle in world coordinates (0080)
    func viewCanvasRect(worldForWindowSize size: CGSize) -> CGRect {
        CanvasLayerTransform.viewCanvasRect(worldForWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    } //end func viewCanvasRect

    // World center corresponding to the View Window’s geometric center (0140)
    func worldCenter(forWindowSize size: CGSize) -> CGPoint {
        CanvasLayerTransform.worldCenter(forWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    } //end func worldCenter

    // Convert a world-space rect to a view-space rect (axis-aligned since transform is uniform scale + translation)
    func worldRectToViewRect(_ rectWorld: CGRect) -> CGRect {
        let p0 = worldToView(CGPoint(x: rectWorld.minX, y: rectWorld.minY))
        let p1 = worldToView(CGPoint(x: rectWorld.maxX, y: rectWorld.maxY))
        return CGRect(x: min(p0.x, p1.x),
                      y: min(p1.y, p0.y) == min(p0.y, p1.y) ? min(p0.y, p1.y) : min(p0.y, p1.y), // keep as before
                      width: abs(p1.x - p0.x),
                      height: abs(p1.y - p0.y))
    } //end func worldRectToViewRect

    // Compute Nodes Extents in world coordinates using CardView visual sizes + padding (0160)
    func computeNodesExtentsWorld() -> CGRect? {
        guard let b = board else { return nil }
        let nodes = (b.nodes ?? [])
        var rect: CGRect?

        // Padding to include shadows and selection borders (expressed in VIEW points), then normalized to world units.
        let paddingView: CGFloat = 24
        let s = max(zoomScale, 0.000001)
        let paddingWorld = paddingView / s

        for node in nodes {
            guard let id = node.card?.id else { continue }
            let sizeWorld = nodeSizeInWorldPoints(for: id)
            let centerWorld = CGPoint(x: node.posX, y: node.posY)
            var r = CGRect(
                x: centerWorld.x - sizeWorld.width / 2.0,
                y: centerWorld.y - sizeWorld.height / 2.0,
                width: sizeWorld.width,
                height: sizeWorld.height
            ) //end CGRect
            r = r.insetBy(dx: -paddingWorld, dy: -paddingWorld)
            if let existing = rect {
                rect = existing.union(r)
            } else {
                rect = r
            } //end if let existing... else
        } //end for node in nodes
        return rect
    } //end func computeNodesExtentsWorld
} //end extension MurderBoardView

// MARK: - Toolbar

fileprivate extension MurderBoardView {
    @ToolbarContentBuilder
    func toolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button { stepZoom(-0.05, windowSize: windowSize) } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")
            .keyboardShortcut("-", modifiers: [.command])

            Slider(value: Binding(
                get: { zoomScale },
                set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
            ), in: Board.minZoom...Board.maxZoom)
            .frame(width: 160)
            .help("Zoom")

            Button { stepZoom(+0.05, windowSize: windowSize) } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")
            .keyboardShortcut("=", modifiers: [.command])

            HStack(spacing: 6) {
                TextField(
                    "Zoom %",
                    text: Binding(
                        get: { "\(Int(round(zoomScale * 100)))" },
                        set: { raw in
                            if let v = Double(raw) {
                                let s = (v / 100.0).clamped(to: Board.minZoom...Board.maxZoom)
                                setZoomKeepingCenter(s, windowSize: windowSize)
                            }
                        }
                    )
                )
                .frame(width: 60)
                .textFieldStyle(.roundedBorder)
                Text("%").foregroundStyle(.secondary)
            }
            .help("Enter zoom percentage (1–200)")

            Divider()

            Button { recenterOnPrimaryOrFirst(windowSize: windowSize) } label: {
                Label("Recenter", systemImage: "dot.scope")
            }
            .help("Recenter on primary (or first) node")

            Button { shuffleAroundPrimary() } label: {
                Label("Shuffle", systemImage: "shuffle")
            }
            .help("Arrange nodes around the primary in a ring; repeat to reshuffle")

            Divider()
            
            #if DEBUG


            #endif
        }
    }

    func stepZoom(_ delta: Double, windowSize: CGSize) {
        let proposed = (zoomScale + delta).clamped(to: Board.minZoom...Board.maxZoom)
        setZoomKeepingCenter(proposed, windowSize: windowSize)
    }

    func setZoomKeepingCenter(_ newScale: Double, windowSize: CGSize) {
        let sNew = newScale.clamped(to: Board.minZoom...Board.maxZoom)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        let cWorld = viewToWorld(cView)
        panX = (cView.x.dg - cWorld.x * sNew)
        panY = (cView.y.dg - cWorld.y * sNew)
        zoomScale = sNew
        persistTransformDebounced()
    }

    func recenterOnPrimaryOrFirst(windowSize: CGSize) {
        guard let b = board else { return }
        let nodePairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !nodePairs.isEmpty else { return }
        let primaryID = b.primaryCard?.id
        let targetNode: BoardNode = nodePairs.first(where: { $0.1.id == primaryID })?.0 ?? nodePairs.first!.0
        let world = CGPoint(x: targetNode.posX, y: targetNode.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()
    }

    func shuffleAroundPrimary() {
        guard let b = board else { return }
        guard var nodes = b.nodes, !nodes.isEmpty else { return }

        // Identify anchor (primary or first)
        let primaryID = b.primaryCard?.id
        let anchorNode = nodes.first(where: { $0.card?.id == primaryID }) ?? nodes.first!
        let anchor = CGPoint(x: anchorNode.posX, y: anchorNode.posY)

        // Remove anchor from placement list
        nodes.removeAll(where: { $0.id == anchorNode.id })

        // Early exit if nothing to place
        let count = max(0, nodes.count)
        guard count > 0 else { return }

        // CA-15: Adaptive ring geometry in WORLD space (zoom-independent)
        // Measure world-space sizes
        func worldSize(for node: BoardNode) -> CGSize {
            guard let id = node.card?.id else { return CGSize(width: 240, height: 160) }
            return nodeSizeInWorldPoints(for: id)
        }
        let anchorSize = worldSize(for: anchorNode)
        let nodeWorldSizes: [CGSize] = nodes.map(worldSize(for:))

        let maxNodeSpan = nodeWorldSizes.map { max($0.width, $0.height) }.max() ?? max(anchorSize.width, anchorSize.height)
        let avgNodeWidth = nodeWorldSizes.map { $0.width }.reduce(0, +) / CGFloat(nodeWorldSizes.count)

        // Base margins (WORLD units)
        let baseMargin: CGFloat = (maxNodeSpan * shuffleBaseMarginWorldFactor)
            + (shuffleBaseMarginViewPadding / max(CGFloat(zoomScale), 0.000001)) // include a small view->world normalized margin
        let spacingMultiplier: CGFloat = shuffleSpacingMultiplier // arc-length spacing factor vs avg width
        let ringSeparationMultiplier: CGFloat = shuffleRingSeparationMultiplier // radial separation vs max node span

        // Start radius: clear the anchor's size plus margin (tighter factors)
        var radius: CGFloat = (max(anchorSize.width, anchorSize.height) * shuffleInitialAnchorFactor)
            + (maxNodeSpan * shuffleInitialNodeSpanFactor)
            + baseMargin

        // Mutable pool
        var pool: [BoardNode] = nodes
        var remaining = pool.count
        var ringIndex = 0

        // Random seed angles per ring
        while remaining > 0 {
            // Desired arc spacing along circumference to avoid overlap
            let desiredArcSpacing = max(avgNodeWidth, 1.0) * spacingMultiplier

            // Ensure capacity for this ring; grow radius until capacity >= 1
            func capacity(at r: CGFloat) -> Int {
                let circ = 2.0 * .pi * r
                return max(1, Int(floor(circ / desiredArcSpacing)))
            }
            var cap = capacity(at: radius)

            // If we still have many nodes, make sure this ring can hold a reasonable share;
            // grow radius until we can place at least 1 and up to remaining
            while cap == 0 {
                radius += max(6.0, maxNodeSpan * 0.20) // smaller growth step
                cap = capacity(at: radius)
            }

            let take = min(remaining, cap)
            let angleStep = (2.0 * .pi) / CGFloat(take)
            let startAngle = Double.random(in: 0..<(2.0 * Double.pi))

            for i in 0..<take {
                if let node = pool.popLast() {
                    // Even placement with small jitter (reduced)
                    let theta = startAngle + Double(i) * Double(angleStep)
                    let jitterR = Double.random(in: shuffleRadialJitterWorld) * Double(maxNodeSpan)
                    let jitterT = Double.random(in: shuffleAngularJitter)
                    let r = Double(radius) + jitterR
                    let x = anchor.x + (r * cos(theta + jitterT))
                    let y = anchor.y + (r * sin(theta + jitterT))
                    node.posX = x
                    node.posY = y
                }
            }

            remaining = pool.count
            ringIndex += 1
            // Increase radius for next ring with separation based on node spans in WORLD units (tighter)
            let ringSeparationWorld = max(maxNodeSpan * ringSeparationMultiplier + baseMargin, maxNodeSpan * 0.7)
            radius += ringSeparationWorld
        }

        try? modelContext.save()
    }
}

// MARK: - Board load, prefetch staging, and transform persistence

fileprivate extension MurderBoardView {
    @MainActor
    func loadBoardIfNeeded() async {
        if board == nil {
            let b = Board.fetchOrCreatePrimaryBoard(for: primary, in: modelContext)
            b.clampState()
            board = b
            zoomScale = b.zoomScale
            panX = b.panX
            panY = b.panY
            await stageThumbnailsIfNeeded()
        }
    }

    func applyBoardTransform() {
        guard let b = board else { return }
        zoomScale = b.zoomScale
        panX = b.panX
        panY = b.panY
    }

    @MainActor
    func stageThumbnailsIfNeeded() async {
        guard isContentReady == false else { return }
        let cards = (board?.nodes ?? []).compactMap { $0.card }
        guard !cards.isEmpty else {
            isContentReady = true
            return
        }

        prefetchProgress = (0, cards.count)

        let maxConcurrent = 2
        let launchStagger: UInt64 = 15_000_000 // 15 ms

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

        try? await Task.sleep(nanoseconds: 80_000_000) // 80 ms
        withAnimation(.easeInOut(duration: 0.15)) {
            isContentReady = true
        }
    }

    func persistTransformDebounced() {
        persistTransformNow()
    }

    func persistTransformNow() {
        guard let b = board else { return }
        let sBefore = b.zoomScale
        let txBefore = b.panX
        let tyBefore = b.panY

        b.zoomScale = zoomScale.clamped(to: Board.minZoom...Board.maxZoom)
        b.panX = panX.clamped(to: Board.minPan...Board.maxPan)
        b.panY = panY.clamped(to: Board.minPan...Board.maxPan)
        b.clampState()
        try? modelContext.save()

        #if DEBUG
        // Lightweight transform persistence log
        if sBefore != b.zoomScale || txBefore != b.panX || tyBefore != b.panY {
            let s = String(format: "%.4f", b.zoomScale)
            let tx = String(format: "%.2f", b.panX)
            let ty = String(format: "%.2f", b.panY)
            print("[MB] Persist transform: S=\(s) T=(\(tx), \(ty))")
        }
        #endif
    }

    // Initial recenter logic (0240–0280, 0250)
    func initialRecenterIfNeeded(on b: Board, windowSize: CGSize) {
        guard didInitialRecenter == false else { return }

        b.ensurePrimaryPresence(in: modelContext)

        let pairs = (b.nodes ?? []).compactMap { n -> (BoardNode, Card)? in
            guard let c = n.card else { return nil }
            return (n, c)
        }
        guard !pairs.isEmpty else {
            didInitialRecenter = true
            return
        }
        let primaryID = b.primaryCard?.id
        let target = pairs.first(where: { $0.1.id == primaryID })?.0 ?? pairs.first!.0

        if abs(target.posX) < 0.0001 && abs(target.posY) < 0.0001 {
            let rect = viewCanvasRect(worldForWindowSize: windowSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            target.posX = center.x.dg
            target.posY = center.y.dg
            try? modelContext.save()
        }

        let world = CGPoint(x: target.posX, y: target.posY)
        let cView = CGPoint(x: windowSize.width / 2.0, y: windowSize.height / 2.0)
        panX = (cView.x.dg - world.x * zoomScale)
        panY = (cView.y.dg - world.y * zoomScale)
        persistTransformNow()

        didInitialRecenter = true
    }
}

// MARK: - Node Size and Board Management

fileprivate extension MurderBoardView {
    // Calculate node size in world points (transform-adjusted)
    func nodeSizeInWorldPoints(for cardID: UUID) -> CGSize {
        guard let viewSize = nodeSizes[cardID] else {
            // Fallback size if not measured yet
            return CGSize(width: 240, height: 160)
        }
        
        // Convert view size to world size by dividing by zoom scale
        let scale = max(zoomScale, 0.000001)
        return CGSize(
            width: viewSize.width / scale,
            height: viewSize.height / scale
        )
    }
    
    // Handle card drop from backlog to board
    func handleCardDrop(cards: [CardTransferData], at location: CGPoint) -> Bool {
        guard let board = board else { return false }
        
        // Convert drop location to world coordinates
        let worldLocation = viewToWorld(location)
        
        var addedAny = false
        
        for cardData in cards {
            // Find the card in our model context
            let request = FetchDescriptor<Card>(
                predicate: #Predicate { $0.id == cardData.id }
            )
            
            guard let card = try? modelContext.fetch(request).first else { continue }
            
            // Check if card is already on the board
            let existingNode = (board.nodes ?? []).first { $0.card?.id == card.id }
            if existingNode != nil { continue }
            
            // Create new node at drop location
            let node = board.node(
                for: card, 
                in: modelContext, 
                createIfMissing: true, 
                defaultPosition: (worldLocation.x, worldLocation.y)
            )
            
            // Add slight offset for multiple cards
            if cards.count > 1 {
                let offset = Double(cards.firstIndex(where: { $0.id == card.id }) ?? 0) * 50.0
                node?.posX += offset
                node?.posY += offset * 0.3 // slight diagonal offset
            }
            
            addedAny = true
        }
        
        if addedAny {
            try? modelContext.save()
            
            // Clear selection of added cards from backlog
            for cardData in cards {
                selectedBacklogCards.remove(cardData.id)
            }
        }
        
        return addedAny
    }
    
    // Remove card from board
    func removeCardFromBoard(cardID: UUID) {
        guard let board = board else { return }
        
        // Find and remove the node
        if let nodeToRemove = (board.nodes ?? []).first(where: { $0.card?.id == cardID }) {
            modelContext.delete(nodeToRemove)
            
            // Clear selection if this was the selected card
            if selectedCardID == cardID {
                selectedCardID = nil
            }
            
            try? modelContext.save()
        }
    }
    
    // Add selected backlog cards to the board
    func addSelectedCardsToBoard() {
        guard !selectedBacklogCards.isEmpty else { return }
        guard let board = board else { return }
        
        // Get current view center in world coordinates for placement
        let windowCenter = CGPoint(x: 400, y: 300) // Approximate window center
        let worldCenter = viewToWorld(windowCenter)
        
        var addedCount = 0
        let selectedCards = backlogCards.filter { selectedBacklogCards.contains($0.id) }
        
        for (index, card) in selectedCards.enumerated() {
            // Check if card is already on the board
            let existingNode = (board.nodes ?? []).first { $0.card?.id == card.id }
            if existingNode != nil { continue }
            
            // Calculate position with slight offset for multiple cards
            let angle = (Double(index) / Double(selectedCards.count)) * 2.0 * .pi
            let radius = 100.0 + Double(index) * 20.0
            let x = worldCenter.x + cos(angle) * radius
            let y = worldCenter.y + sin(angle) * radius
            
            // Create node
            _ = board.node(
                for: card,
                in: modelContext,
                createIfMissing: true,
                defaultPosition: (x, y)
            )
            
            addedCount += 1
        }
        
        if addedCount > 0 {
            try? modelContext.save()
            selectedBacklogCards.removeAll()
        }
    }
}


// MARK: - Context Menu Support (CA-22: ✓ Completed using SwiftUI's native contextMenu with simultaneousGesture)

#if DEBUG && os(macOS)
// Diagnostic helper to detect right-click events at the NSView level
struct RightClickDetector: NSViewRepresentable {
    let onRightClick: (String) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = RightClickDetectView()
        view.onRightClick = onRightClick
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? RightClickDetectView)?.onRightClick = onRightClick
    }
    
    class RightClickDetectView: NSView {
        var onRightClick: ((String) -> Void)?
        
        override func rightMouseDown(with event: NSEvent) {
            onRightClick?("rightMouseDown")
            super.rightMouseDown(with: event)
        }
        
        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                onRightClick?("ctrl+click")
            }
            super.mouseDown(with: event)
        }
        
        override func otherMouseDown(with event: NSEvent) {
            onRightClick?("otherMouseDown")
            super.otherMouseDown(with: event)
        }
        
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
        override var acceptsFirstResponder: Bool { true }
    }
}
#elseif DEBUG
// Placeholder for non-macOS platforms
struct RightClickDetector: View {
    let onRightClick: (String) -> Void
    var body: some View { Color.clear }
}
#endif

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
