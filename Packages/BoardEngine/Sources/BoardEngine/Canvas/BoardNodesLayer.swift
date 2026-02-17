//
//  BoardNodesLayer.swift
//  BoardEngine
//
//  Generic nodes layer that renders all board nodes using a consumer-provided
//  @ViewBuilder closure. Collects node size measurements via preference keys
//  and applies hover glow effects.
//

import SwiftUI

// MARK: - Board Nodes Layer

/// Renders all nodes on the board canvas using a consumer-provided view builder.
public struct BoardNodesLayer<DS: BoardDataSource, NodeContent: View>: View {
    let dataSource: DS
    let selectedNodeID: UUID?
    let scheme: ColorScheme
    let isContentReady: Bool

    @Binding var nodeSizes: [UUID: CGSize]
    @Binding var nodeVisualSizes: [UUID: CGSize]

    @ViewBuilder let nodeContent: (_ node: DS.Node, _ isSelected: Bool, _ isPrimary: Bool) -> NodeContent

    // visionOS: track which node is currently hovered by gaze
    @State private var hoveredNodeID: UUID? = nil

    public init(
        dataSource: DS,
        selectedNodeID: UUID?,
        scheme: ColorScheme,
        isContentReady: Bool,
        nodeSizes: Binding<[UUID: CGSize]>,
        nodeVisualSizes: Binding<[UUID: CGSize]>,
        @ViewBuilder nodeContent: @escaping (_ node: DS.Node, _ isSelected: Bool, _ isPrimary: Bool) -> NodeContent
    ) {
        self.dataSource = dataSource
        self.selectedNodeID = selectedNodeID
        self.scheme = scheme
        self.isContentReady = isContentReady
        self._nodeSizes = nodeSizes
        self._nodeVisualSizes = nodeVisualSizes
        self.nodeContent = nodeContent
    }

    public var body: some View {
        let nodes = dataSource.nodes

        ZStack {
            ForEach(nodes, id: \.nodeID) { node in
                let isSelected = (selectedNodeID == node.nodeID)
                let isPrimary = node.isPrimary
                let isHovered = (hoveredNodeID == node.nodeID)

                nodeContent(node, isSelected, isPrimary)
                    // Measure the node view size
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: BoardNodeSizesKey.self,
                                    value: [node.nodeID: geo.size]
                                )
                        }
                    )
                    // Position in world coordinates; parent applies transform
                    .position(CGPoint(x: node.posX, y: node.posY))
                    .zIndex(isSelected ? 1 : Double(node.zIndex))
                    // visionOS gaze hover
                    #if os(visionOS)
                    .onHover { hovering in
                        if hovering {
                            hoveredNodeID = node.nodeID
                        } else if hoveredNodeID == node.nodeID {
                            hoveredNodeID = nil
                        }
                    }
                    #endif
                    // Hover glow
                    .modifier(BoardNodeHoverGlow(
                        isHovered: isHovered,
                        kindAccent: node.accentColor(for: scheme)
                    ))
            }
        }
        .onPreferenceChange(BoardNodeSizesKey.self) { value in
            if !value.isEmpty {
                var next = nodeSizes
                next.merge(value) { _, new in new }
                if next != nodeSizes {
                    nodeSizes = next
                }
            }
        }
        .onPreferenceChange(BoardNodeVisualSizesKey.self) { reported in
            if !reported.isEmpty {
                var next = nodeVisualSizes
                next.merge(reported) { _, new in new }
                if next != nodeVisualSizes {
                    nodeVisualSizes = next
                }
            }
        }
        .opacity(isContentReady ? 1.0 : 0.0)
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Hover Glow Modifier

/// Animated glow effect shown when a node is hovered (visionOS gaze or pointer hover).
public struct BoardNodeHoverGlow: ViewModifier {
    public let isHovered: Bool
    public let kindAccent: Color

    public init(isHovered: Bool, kindAccent: Color) {
        self.isHovered = isHovered
        self.kindAccent = kindAccent
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(kindAccent.opacity(isHovered ? 0.55 : 0.0), lineWidth: isHovered ? 6 : 0)
                    .blur(radius: isHovered ? 3 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(kindAccent.opacity(isHovered ? 0.20 : 0.0), lineWidth: isHovered ? 10 : 0)
                    .blur(radius: isHovered ? 6 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.12), value: isHovered)
            )
    }
}
