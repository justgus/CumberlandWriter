//
//  EdgeCreationSystem.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-09.
//  DR-0076: Edge creation UI for MurderBoard
//

import SwiftUI
import SwiftData

// MARK: - Pending Edge Creation

/// Identifiable struct for sheet(item:) presentation - ensures data is available when sheet renders
struct PendingEdgeCreation: Identifiable {
    let id = UUID()
    let sourceCardID: UUID
    let targetCardID: UUID
}

// MARK: - Edge Creation State

/// Observable state for edge creation drag operation
@Observable
final class EdgeCreationState {
    /// The card ID that is the source of the edge being created
    var sourceCardID: UUID?

    /// Current drag position in view coordinates
    var currentDragPosition: CGPoint?

    /// The card ID currently being hovered over as a potential target
    var hoveredTargetID: UUID?

    /// Whether an edge creation drag is currently active
    var isDragging: Bool {
        sourceCardID != nil && currentDragPosition != nil
    }

    /// Start a new edge creation drag
    func startDrag(from cardID: UUID, at position: CGPoint) {
        sourceCardID = cardID
        currentDragPosition = position
        hoveredTargetID = nil
    }

    /// Update the current drag position
    func updateDrag(to position: CGPoint) {
        currentDragPosition = position
    }

    /// Set the hovered target
    func setHoveredTarget(_ cardID: UUID?) {
        hoveredTargetID = cardID
    }

    /// End the drag and return the target if valid
    func endDrag() -> UUID? {
        let target = hoveredTargetID
        sourceCardID = nil
        currentDragPosition = nil
        hoveredTargetID = nil
        return target
    }

    /// Cancel the drag without creating an edge
    func cancelDrag() {
        sourceCardID = nil
        currentDragPosition = nil
        hoveredTargetID = nil
    }
}

// MARK: - Edge Handle View

/// A visual handle on the trailing edge of a node for creating edges
/// Note: Drag handling is done via MultiGestureHandler (EdgeHandleGestureTarget) on macOS
/// because SwiftUI DragGesture doesn't work with .dropDestination() present
struct EdgeHandle: View {
    let cardID: UUID
    let cardKind: Kinds
    let nodeViewCenter: CGPoint  // Node center in VIEW coordinates
    let nodeViewSize: CGSize     // Node size in VIEW coordinates (already scaled)
    let zoomScale: Double
    let scheme: ColorScheme

    @Bindable var edgeCreationState: EdgeCreationState

    // Not used on macOS (gesture handled by MultiGestureHandler), but kept for iOS compatibility
    let onEdgeCreated: (UUID, UUID) -> Void

    // Handle appearance
    private let handleSize: CGFloat = 20

    /// Position of the handle in view coordinates (straddling the trailing edge - half on, half off the card)
    private var handleViewPosition: CGPoint {
        // Position so handle center is exactly on the card's trailing edge
        // This puts half the handle inside the card and half outside
        CGPoint(
            x: nodeViewCenter.x + nodeViewSize.width / 2,
            y: nodeViewCenter.y
        )
    }

    var body: some View {
        let isActive = edgeCreationState.sourceCardID == cardID
        let scaledSize = handleSize * zoomScale

        Circle()
            .fill(cardKind.accentColor(for: scheme).opacity(isActive ? 1.0 : 0.7))
            .frame(width: scaledSize, height: scaledSize)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 2 * zoomScale)
            )
            .overlay(
                Image(systemName: "arrow.right")
                    .font(.system(size: 10 * zoomScale, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 3 * zoomScale, x: 0, y: 1 * zoomScale)
            .position(handleViewPosition)
            // Note: On macOS, hit testing and drag handling is done by EdgeHandleGestureTarget
            // via NSEvent monitors in MultiGestureHandler. SwiftUI gestures don't work here
            // due to .dropDestination() intercepting events.
            .allowsHitTesting(false)  // Let MultiGestureHandler handle all input
            // Highlight when active with glow instead of scale to avoid position jump
            .overlay(
                Circle()
                    .stroke(cardKind.accentColor(for: scheme), lineWidth: isActive ? 3 * zoomScale : 0)
                    .blur(radius: isActive ? 4 * zoomScale : 0)
                    .frame(width: scaledSize + 8 * zoomScale, height: scaledSize + 8 * zoomScale)
                    .position(handleViewPosition)
                    .allowsHitTesting(false)
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Edge Creation Line Layer

/// Draws the temporary line during edge creation drag
struct EdgeCreationLineLayer: View {
    let edgeCreationState: EdgeCreationState
    let scheme: ColorScheme
    let worldToView: (CGPoint) -> CGPoint

    /// Get the source node center in view coordinates
    let getSourceCenter: (UUID) -> CGPoint?

    var body: some View {
        if edgeCreationState.isDragging,
           let sourceID = edgeCreationState.sourceCardID,
           let sourceCenter = getSourceCenter(sourceID),
           let dragPosition = edgeCreationState.currentDragPosition {

            let isValidTarget = edgeCreationState.hoveredTargetID != nil
            let lineColor = isValidTarget ? Color.green : Color.accentColor

            Canvas { context, size in
                var path = Path()
                path.move(to: sourceCenter)
                path.addLine(to: dragPosition)

                // Draw simple line without arrowhead (relationships are bidirectional)
                context.stroke(
                    path,
                    with: .color(lineColor),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: isValidTarget ? [] : [8, 4]
                    )
                )
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Node Drop Target Highlight

/// Modifier that highlights a node when it's a valid drop target during edge creation
struct EdgeDropTargetHighlight: ViewModifier {
    let cardID: UUID
    let edgeCreationState: EdgeCreationState
    let scheme: ColorScheme

    private var isValidTarget: Bool {
        guard let sourceID = edgeCreationState.sourceCardID else { return false }
        // Can't create edge to self
        return sourceID != cardID
    }

    private var isHovered: Bool {
        edgeCreationState.hoveredTargetID == cardID
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if edgeCreationState.isDragging && isValidTarget {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isHovered ? Color.green : Color.accentColor.opacity(0.5),
                                lineWidth: isHovered ? 4 : 2
                            )
                            .animation(.easeInOut(duration: 0.15), value: isHovered)
                    }
                }
                .allowsHitTesting(false)
            )
    }
}

// MARK: - Edge Creation RelationType Sheet

/// Sheet for selecting a RelationType when creating an edge on the MurderBoard
struct EdgeCreationRelationTypeSheet: View {
    let sourceCardID: UUID
    let targetCardID: UUID
    let allRelationTypes: [RelationType]
    let allCards: [Card]
    let onSelect: (RelationType) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var selectedTypeCode: String?
    @State private var showingCreateNew: Bool = false

    private var sourceCard: Card? {
        allCards.first { $0.id == sourceCardID }
    }

    private var targetCard: Card? {
        allCards.first { $0.id == targetCardID }
    }

    private var sourceKind: Kinds {
        sourceCard?.kind ?? .projects
    }

    private var targetKind: Kinds {
        targetCard?.kind ?? .projects
    }

    /// Filter relation types that are applicable for the source→target kind combination
    private var applicableTypes: [RelationType] {
        allRelationTypes.filter { type in
            // Types with no kind restrictions apply to all
            if type.sourceKind == nil && type.targetKind == nil {
                return true
            }
            // Check if source kind matches (or is unrestricted)
            let sourceMatches = type.sourceKind == nil || type.sourceKind == sourceKind
            // Check if target kind matches (or is unrestricted)
            let targetMatches = type.targetKind == nil || type.targetKind == targetKind
            return sourceMatches && targetMatches
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Relationship")
                .font(.title3).bold()

            // Show source and target cards
            GroupBox("Connecting") {
                HStack(spacing: 12) {
                    if let source = sourceCard {
                        HStack(spacing: 6) {
                            Image(systemName: source.kind.systemImage)
                                .foregroundStyle(source.kind.accentColor(for: scheme))
                            Text(source.name)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Unknown")
                    }

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    if let target = targetCard {
                        HStack(spacing: 6) {
                            Image(systemName: target.kind.systemImage)
                                .foregroundStyle(target.kind.accentColor(for: scheme))
                            Text(target.name)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Unknown")
                    }

                    Spacer()
                }
            }

            // RelationType list
            GroupBox("Relation Type") {
                if applicableTypes.isEmpty {
                    VStack(spacing: 8) {
                        Text("No relation types available for this combination.")
                            .foregroundStyle(.secondary)
                        Button("Create New Type…") {
                            showingCreateNew = true
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    List(selection: $selectedTypeCode) {
                        ForEach(applicableTypes, id: \.code) { type in
                            HStack(spacing: 8) {
                                Text(type.forwardLabel)
                                    .font(.body)
                                Text("↔︎")
                                    .foregroundStyle(.secondary)
                                Text(type.inverseLabel)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .tag(type.code)
                            .contentShape(Rectangle())
                        }
                    }
                    .frame(minHeight: 140)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("New Type…") {
                    showingCreateNew = true
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    if let typeCode = selectedTypeCode,
                       let type = applicableTypes.first(where: { $0.code == typeCode }) {
                        onSelect(type)
                        dismiss()
                    }
                } label: {
                    Label("Create", systemImage: "link.badge.plus")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTypeCode == nil)
            }
        }
        .padding()
        .onAppear {
            // Pre-select first type if available
            if selectedTypeCode == nil {
                selectedTypeCode = applicableTypes.first?.code
            }
        }
        .sheet(isPresented: $showingCreateNew) {
            RelationTypeCreatorSheet(
                sourceKind: sourceKind,
                targetKind: targetKind,
                onCreate: { newType in
                    onSelect(newType)
                    showingCreateNew = false
                    dismiss()
                },
                onCancel: {
                    showingCreateNew = false
                }
            )
            .frame(minWidth: 420, minHeight: 300)
        }
    }
}

// MARK: - Edge Handles Layer

/// Layer that contains all edge handles for nodes on the board
struct EdgeHandlesLayer: View {
    let board: Board?
    let scheme: ColorScheme
    let zoomScale: Double
    @Bindable var edgeCreationState: EdgeCreationState

    let nodeSizes: [UUID: CGSize]  // These are VIEW sizes (already scaled)
    let worldToView: (CGPoint) -> CGPoint
    let onEdgeCreated: (UUID, UUID) -> Void

    var body: some View {
        let nodes = (board?.nodes ?? []).compactMap { node -> (BoardNode, Card)? in
            guard let c = node.card else { return nil }
            return (node, c)
        }

        ZStack {
            ForEach(nodes, id: \.0.id) { pair in
                let node = pair.0
                let card = pair.1

                // Convert world center to view center
                let nodeWorldCenter = CGPoint(x: node.posX, y: node.posY)
                let nodeViewCenter = worldToView(nodeWorldCenter)

                // Get view size: nodeSizes are pre-transform, multiply by zoomScale for actual view size
                let preTransformSize = nodeSizes[card.id] ?? CGSize(width: 240, height: 160)
                let nodeViewSize = CGSize(width: preTransformSize.width * zoomScale, height: preTransformSize.height * zoomScale)

                EdgeHandle(
                    cardID: card.id,
                    cardKind: card.kind,
                    nodeViewCenter: nodeViewCenter,
                    nodeViewSize: nodeViewSize,
                    zoomScale: zoomScale,
                    scheme: scheme,
                    edgeCreationState: edgeCreationState,
                    onEdgeCreated: onEdgeCreated
                )
            }
        }
        // The ZStack itself shouldn't capture events - only the Circle handles should
        // Each EdgeHandle has its own contentShape(Circle()) for hit testing
    }
}
