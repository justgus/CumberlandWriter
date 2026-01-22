//
//  MurderBoardNodeView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/1/25.
//

import SwiftUI
import Combine

// MARK: - Murder Board Node View

struct MurderBoardNodeView: View {
    let card: Card
    let node: BoardNode
    let isSelected: Bool
    let isPrimary: Bool
    let zIndex: Double
    let nodeCenterWorld: CGPoint
    let scheme: ColorScheme
    let onRemove: () -> Void
    let onSelect: () -> Void
    
    init(card: Card, node: BoardNode, isSelected: Bool, isPrimary: Bool, zIndex: Double, nodeCenterWorld: CGPoint, scheme: ColorScheme, onRemove: @escaping () -> Void, onSelect: @escaping () -> Void) {
        self.card = card
        self.node = node
        self.isSelected = isSelected
        self.isPrimary = isPrimary
        self.zIndex = zIndex
        self.nodeCenterWorld = nodeCenterWorld
        self.scheme = scheme
        self.onRemove = onRemove
        self.onSelect = onSelect
        #if DEBUG
        //print("MurderBoardNodeView: \(card.id) name: \(card.name) isPrimary: \(isPrimary)")
        #endif
    }

    var body: some View {
        let hitShape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        CardView(card: card, showAIBadge: false)
            // Selection border overlay — make it non-interactive so it cannot steal gestures
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 4 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.12), value: isSelected)
            )
            // Measure the actual CardView size (pre-transform, in view points)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: NodeSizesKey.self,
                            value: [card.id: geo.size]
                        )
                }
            )
            // Position in world coordinates; parent layer applies v = w*S + T
            .position(nodeCenterWorld)
            .contentShape(hitShape)
            .zIndex(zIndex)
            // Keep the node fully interactive; hover handling and glow are layered by the parent
    }
}

