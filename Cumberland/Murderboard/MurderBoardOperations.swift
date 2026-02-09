// MurderBoardOperations.swift
// Extracted from MurderBoardView.swift as part of ER-0022 Phase 3.3
// Contains board operations, loading, persistence, and node management

import SwiftUI
import SwiftData

// MARK: - Constants

let windowCornerRadius: CGFloat = 18
let windowBorderWidth: CGFloat = 12

var windowBorderColor: Color { .secondary.opacity(0.55) }
var windowInnerShadowColor: Color { .white.opacity(0.18) }

// MARK: - Transform Helpers

extension MurderBoardView {
    // World→View transform: v = w*S + T
    func worldToView(_ world: CGPoint) -> CGPoint {
        CanvasLayerTransform.worldToView(world, scale: zoomScale, panX: panX, panY: panY)
    }

    // View→World inverse: w = (v − T)/S
    func viewToWorld(_ view: CGPoint) -> CGPoint {
        CanvasLayerTransform.viewToWorld(view, scale: zoomScale, panX: panX, panY: panY)
    }

    // View Canvas Rectangle in world coordinates
    func viewCanvasRect(worldForWindowSize size: CGSize) -> CGRect {
        CanvasLayerTransform.viewCanvasRect(worldForWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    }

    // World center corresponding to the View Window's geometric center
    func worldCenter(forWindowSize size: CGSize) -> CGPoint {
        CanvasLayerTransform.worldCenter(forWindowSize: size, scale: zoomScale, panX: panX, panY: panY)
    }

    // Convert a world-space rect to a view-space rect (axis-aligned since transform is uniform scale + translation)
    func worldRectToViewRect(_ rectWorld: CGRect) -> CGRect {
        let p0 = worldToView(CGPoint(x: rectWorld.minX, y: rectWorld.minY))
        let p1 = worldToView(CGPoint(x: rectWorld.maxX, y: rectWorld.maxY))
        return CGRect(x: min(p0.x, p1.x),
                      y: min(p1.y, p0.y) == min(p0.y, p1.y) ? min(p0.y, p1.y) : min(p0.y, p1.y),
                      width: abs(p1.x - p0.x),
                      height: abs(p1.y - p0.y))
    }

    // Compute Nodes Extents in world coordinates using CardView visual sizes + padding
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
            )
            r = r.insetBy(dx: -paddingWorld, dy: -paddingWorld)
            if let existing = rect {
                rect = existing.union(r)
            } else {
                rect = r
            }
        }
        return rect
    }
}

// MARK: - Board Load, Prefetch, and Transform Persistence

extension MurderBoardView {
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

    // Initial recenter logic
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

extension MurderBoardView {
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

// MARK: - Edge Creation (DR-0076)

extension MurderBoardView {
    /// Called when an edge handle drag completes over a valid target
    func handleEdgeCreationRequest(sourceCardID: UUID, targetCardID: UUID) {
        #if DEBUG
        print("[MB] Edge creation requested: \(sourceCardID) → \(targetCardID)")
        #endif

        // Set the pending edge creation item - this triggers the sheet via sheet(item:)
        // Using an Identifiable item ensures data is available when sheet content renders
        pendingEdgeCreation = PendingEdgeCreation(
            sourceCardID: sourceCardID,
            targetCardID: targetCardID
        )
    }

    /// Create the actual edge after RelationType is selected
    func createEdge(from sourceID: UUID, to targetID: UUID, type: RelationType) {
        // Find the cards
        guard let sourceCard = allCards.first(where: { $0.id == sourceID }),
              let targetCard = allCards.first(where: { $0.id == targetID }) else {
            #if DEBUG
            print("[MB] Edge creation failed: could not find cards")
            #endif
            return
        }

        // Check if forward edge already exists
        let forwardExists = sourceCard.outgoingEdges?.contains { edge in
            edge.to?.id == targetID && edge.type?.code == type.code
        } ?? false

        // Check if reverse edge already exists
        let reverseExists = targetCard.outgoingEdges?.contains { edge in
            edge.to?.id == sourceID && edge.type?.code == type.code
        } ?? false

        if forwardExists && reverseExists {
            #if DEBUG
            print("[MB] Both edges already exist, skipping creation")
            #endif
            return
        }

        // Create the forward edge (source → target) if needed
        if !forwardExists {
            let forwardEdge = CardEdge(from: sourceCard, to: targetCard, type: type)
            modelContext.insert(forwardEdge)
        }

        // Create the reverse edge (target → source) if needed
        // The relationship is bidirectional - the type's inverseLabel describes the reverse direction
        if !reverseExists {
            let reverseEdge = CardEdge(from: targetCard, to: sourceCard, type: type)
            modelContext.insert(reverseEdge)
        }

        do {
            try modelContext.save()
            #if DEBUG
            print("[MB] Edges created: \(sourceCard.name) ↔ \(targetCard.name) [\(type.forwardLabel)/\(type.inverseLabel)]")
            #endif
        } catch {
            #if DEBUG
            print("[MB] Edge creation save failed: \(error)")
            #endif
        }

        // Clear pending state - this also dismisses the sheet
        pendingEdgeCreation = nil
    }

    /// Get the view-space center of a node by card ID
    func getNodeViewCenter(for cardID: UUID) -> CGPoint? {
        guard let node = board?.nodes?.first(where: { $0.card?.id == cardID }) else {
            return nil
        }
        let worldCenter = CGPoint(x: node.posX, y: node.posY)
        return worldToView(worldCenter)
    }
}

// MARK: - Border Overlay

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
                        ),
                        lineWidth: 2
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous)
                            .stroke(lineWidth: windowBorderWidth)
                    )
                    .blendMode(.overlay)
                    .opacity(scheme == .dark ? 0.5 : 0.8)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Debug Helpers

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
