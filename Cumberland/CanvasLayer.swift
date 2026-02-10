//
//  MBCanvasLayer.swift
//  Cumberland
//
//  Created by Assistant on 11/1/25.
//

import SwiftUI
import SwiftData

// MARK: - Canvas Layer

/****
 * MurderBoard Canvas Layer
 */
struct CanvasLayer: View {
    let board: Board?
    let windowSize: CGSize
    let windowCenter: CGPoint
    let selectedCardID: UUID?
    let primaryCardID: UUID?
    let scheme: ColorScheme
    let isContentReady: Bool
    let canvasCoordSpace: String
    
    // Drop state
    @Binding var isDropTargetActive: Bool
    
    // Gesture state
    @Binding var zoomScale: Double
    @Binding var panX: Double
    @Binding var panY: Double
    
    // Node state
    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]
    
    // Sidebar state for nodes layer
    let selectedKindFilter: Kinds?
    @Binding var selectedBacklogCards: Set<UUID>
    let isSidebarVisible: Bool
    let backlogCards: [Card]
    
    // Callbacks
    let worldToView: (CGPoint) -> CGPoint
    let viewToWorld: (CGPoint) -> CGPoint
    let onCardDrop: ([CardTransferData], CGPoint) -> Bool
    let onRemoveCard: (UUID) -> Void
    let onSelectCard: (UUID) -> Void

    // Edge creation state (DR-0076)
    @Bindable var edgeCreationState: EdgeCreationState
    let onEdgeCreated: (UUID, UUID) -> Void
    
    var body: some View {
        // Attach coordinate space on the SAME view (CA-13.2).
        GeometryReader { geo in
            ZStack {
                // Background container: base fill + grid overlay.
                ZStack {
                    Rectangle()
                        .fill(scheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.04))

                    GridBackground(
                        tileSize: 40,
                        lineWidth: 0.5,
                        primaryOpacity: scheme == .dark ? 0.22 : 0.10,
                        secondaryEvery: 5,
                        secondaryOpacity: scheme == .dark ? 0.28 : 0.14
                    ) //end GridBackground
                } //end ZStack
                .ignoresSafeArea()

                // Phase 5: Edges layer (renders above grid, below nodes)
                EdgesLayer(
                    board: board,
                    scheme: scheme,
                    worldToView: worldToView
                ) //end EdgesLayer
                .allowsHitTesting(false)

                if isContentReady {
                    MurderBoardNodesLayer(
                        board: board,
                        selectedCardID: selectedCardID,
                        primaryCardID: primaryCardID,
                        scheme: scheme,
                        isContentReady: isContentReady,
                        windowSize: windowSize,
                        onRemove: onRemoveCard,
                        onSelect: onSelectCard,
                        zoomScale: zoomScale,
                        panX: panX,
                        panY: panY,
                        nodeSizes: $nodeSizes,
                        nodeVisualSizes: $nodeVisualSizes,
                        selectedKindFilter: selectedKindFilter,
                        selectedBacklogCards: $selectedBacklogCards,
                        isSidebarVisible: isSidebarVisible,
                        backlogCards: backlogCards
                    ) //endMurderBoardNodesLayer
                    // Apply transform to nodes layer
                    .modifier(CanvasLayerTransformModifier(
                        debugEnabled: false,
                        zoomScale: zoomScale,
                        panX: panX,
                        panY: panY
                    )) //end .modfifier
                    .transition(.opacity.combined(with: .scale))
                } //end if contentReady

                // 0710: Blue drop target indicator when dragging cards from backlog
                if isDropTargetActive {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                        ) //end .overlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .allowsHitTesting(false)
                        .accessibilityLabel("Drop target for adding cards to board")
                }  //end if isDropTargetActive

                // DR-0076: Edge creation layers (in view coordinates, not transformed)
                if isContentReady {
                    // Edge handles layer - small circles on the trailing edge of each node
                    EdgeHandlesLayer(
                        board: board,
                        scheme: scheme,
                        zoomScale: zoomScale,
                        edgeCreationState: edgeCreationState,
                        nodeSizes: nodeVisualSizes,
                        worldToView: worldToView,
                        onEdgeCreated: onEdgeCreated
                    )

                    // Edge creation line layer - draws the temporary line during drag
                    EdgeCreationLineLayer(
                        edgeCreationState: edgeCreationState,
                        scheme: scheme,
                        worldToView: worldToView,
                        getSourceCenter: { cardID in
                            // Return the edge handle position (straddling the trailing edge of node)
                            guard let node = board?.nodes?.first(where: { $0.card?.id == cardID }) else {
                                return nil
                            }
                            let nodeSize = nodeVisualSizes[cardID] ?? CGSize(width: 240, height: 160)
                            // Handle center is at the card's trailing edge (straddling position)
                            let handleWorldX = node.posX + nodeSize.width / 2
                            let handleWorldY = node.posY
                            return worldToView(CGPoint(x: handleWorldX, y: handleWorldY))
                        }
                    )
                }

            } //end ZStack
            // Note: .coordinateSpace(name: canvasCoordSpace) is NOT registered here.
            // It is registered by MultiGestureModifier on the parent ZStack in MurderBoardView,
            // ensuring the DragGesture's named coordinate space resolves to the gesture target view.
            // Registering it here (on a child) caused a duplicate registration that made
            // DragGesture report coordinates in the child's local space on iOS (DR-0085).
            .contentShape(Rectangle())
            // Add drop receiver for cards from backlog (0690-0710)
            .dropDestination(for: CardTransferData.self) { items, location in
                onCardDrop(items, location)
            } isTargeted: { isTargeted in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDropTargetActive = isTargeted
                }
            }
            // Capture CardView size preferences bubbling up from nodes to populate hit-test dictionaries
            .onPreferenceChange(CardViewActualSizeKey.self) { newSizes in
                // Merge, preferring the latest measurements
                if !newSizes.isEmpty {
                    nodeSizes.merge(newSizes, uniquingKeysWith: { _, new in new })
                }
            }
            .onPreferenceChange(CardViewVisualSizeKey.self) { newVisualSizes in
                // Merge, preferring the latest measurements
                if !newVisualSizes.isEmpty {
                    nodeVisualSizes.merge(newVisualSizes, uniquingKeysWith: { _, new in new })
                }
            }
        }
    }
}

// MARK: - Grid Background (Non-Canvas implementation)

struct GridBackground: View {
    let tileSize: CGFloat
    let lineWidth: CGFloat
    let primaryOpacity: Double
    let secondaryEvery: Int
    let secondaryOpacity: Double

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let primaryColor = Color.primary.opacity(primaryOpacity)
            let secondaryColor = Color.primary.opacity(secondaryOpacity)

            let paths = makeGridPaths(size: size,
                                      tile: tileSize,
                                      secondaryEvery: max(1, secondaryEvery))

            ZStack {
                paths.primary
                    .stroke(primaryColor, lineWidth: lineWidth)
                paths.secondary
                    .stroke(secondaryColor, lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func makeGridPaths(size: CGSize, tile: CGFloat, secondaryEvery: Int) -> (primary: Path, secondary: Path) {
        var primary = Path()
        var secondary = Path()

        var x: CGFloat = 0
        var column = 0
        while x <= size.width + 0.5 {
            if (column % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: x, y: 0))
                secondary.addLine(to: CGPoint(x: x, y: size.height))
            } else {
                primary.move(to: CGPoint(x: x, y: 0))
                primary.addLine(to: CGPoint(x: x, y: size.height))
            }
            x += tile
            column += 1
        }

        var y: CGFloat = 0
        var row = 0
        while y <= size.height + 0.5 {
            if (row % secondaryEvery) == 0 {
                secondary.move(to: CGPoint(x: 0, y: y))
                secondary.addLine(to: CGPoint(x: size.width, y: y))
            } else {
                primary.move(to: CGPoint(x: 0, y: y))
                primary.addLine(to: CGPoint(x: size.width, y: y))
            }
            y += tile
            row += 1
        }

        return (primary, secondary)
    }
}

