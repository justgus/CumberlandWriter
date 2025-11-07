//
//  MBNodesLayer.swift
//  Cumberland
//
//  Created by Assistant on 11/1/25.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Nodes Layer

struct MurderBoardNodesLayer: View {
    let board: Board?
    let selectedCardID: UUID?
    let primaryCardID: UUID?
    let scheme: ColorScheme
    let isContentReady: Bool
    let windowSize: CGSize
    let onRemove: (UUID) -> Void
    let onSelect: (UUID) -> Void
    
    // Transform parameters (moved from parent layer)
    let zoomScale: Double
    let panX: Double
    let panY: Double
    
    // State bindings
    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]
    
    // Gesture and UI state
    let selectedKindFilter: Kinds?
    @Binding var selectedBacklogCards: Set<UUID>
    let isSidebarVisible: Bool
    let backlogCards: [Card]
    
    // Debug state
    #if DEBUG
    @State private var debugContextMenuEnabled: Bool = false
    #endif
    
    var body: some View {
        let nodes = (board?.nodes ?? []).compactMap { node -> (BoardNode, Card)? in
            guard let c = node.card else { return nil }
            return (node, c)
        }
        let nodeIDs = nodes.map { $0.1.id }

        ZStack {
            ForEach(nodes, id: \.0.id) { pair in
                let node = pair.0
                let card = pair.1
                let isSelected = (selectedCardID == card.id)
                let isPrimary = (primaryCardID == card.id)
                
                MurderBoardNodeView(
                    card: card,
                    node: node,
                    isSelected: isSelected,
                    isPrimary: isPrimary,
                    zIndex: isSelected ? 1 : 0,
                    nodeCenterWorld: CGPoint(x: node.posX, y: node.posY),
                    scheme: scheme,
                    onRemove: { onRemove(card.id) },
                    onSelect: { onSelect(card.id) }
                ) //end MurderBoardNodeView
            } //end ForEach
        } //end ZStack
        // Collect full-layout sizes for all nodes (fallback measurement)
        .onPreferenceChange(NodeSizesKey.self) { value in
            if !value.isEmpty {
               var next = nodeSizes
                next.merge(value) { _, new in new }
                if next != nodeSizes {
                    nodeSizes = next
                }
            }
        }
        // Collect visual “card shape” sizes for all nodes (reported by CardView)
        .onPreferenceChange(CardViewVisualSizeKey.self) { reported in
            if !reported.isEmpty {
                var next = nodeVisualSizes
                next.merge(reported) { _, new in new }
                if next != nodeVisualSizes {
                    nodeVisualSizes = next
                }
            }
        }
        .modifier(NodeLayerEventModifier(
            nodeIDs: nodeIDs,
            selectedCardID: .constant(selectedCardID),
            selectedKindFilter: selectedKindFilter,
            selectedBacklogCards: $selectedBacklogCards,
            isSidebarVisible: isSidebarVisible,
            backlogCards: backlogCards,
            onSelect: onSelect
        ))
        .opacity(isContentReady ? 1.0 : 0.0)
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Node Layer Event Modifier

struct NodeLayerEventModifier: ViewModifier {
    let nodeIDs: [UUID]
    @Binding var selectedCardID: UUID?
    let selectedKindFilter: Kinds?
    @Binding var selectedBacklogCards: Set<UUID>
    let isSidebarVisible: Bool
    let backlogCards: [Card]
    let onSelect: (UUID) -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: nodeIDs) { _, ids in
                if let sel = selectedCardID, !ids.contains(sel) {
                    selectedCardID = nil
                }
            }
            .onChange(of: selectedKindFilter) { _, _ in
                selectedBacklogCards.removeAll()
            }
            .onKeyPress(.escape) {
                if !selectedBacklogCards.isEmpty {
                    selectedBacklogCards.removeAll()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.init("a"), phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) && isSidebarVisible && !backlogCards.isEmpty {
                    selectedBacklogCards = Set(backlogCards.map { $0.id })
                    return .handled
                }
                return .ignored
            }
    }
}

// MARK: - Node Size Preference

struct NodeSizesKey: PreferenceKey {
    static var defaultValue: [UUID: CGSize] = [:]
    static func reduce(value: inout [UUID: CGSize], nextValue: () -> [UUID: CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#if DEBUG
// MARK: - Debug helper for inspecting GeometryReader sizes
@inline(never)
func debugRecordNodeSize(id: UUID, size: CGSize) {
    _ = id
    _ = size
}
#endif
