//
//  InvestigationBoardView.swift
//  MurderboardApp
//
//  Root view using BoardEngine's BoardCanvasView with custom node rendering.
//

import SwiftUI
import SwiftData
import BoardEngine

// MARK: - Investigation Board View

struct InvestigationBoardView: View {
    /// When set, the view loads this specific board. When nil, falls back to loadOrCreateBoard.
    private let initialBoard: InvestigationBoard?

    // MARK: - Initializers

    /// Initialize with a specific board (used by MurderBoardRootView).
    init(board: InvestigationBoard) {
        self.initialBoard = board
    }

    /// Initialize without a board (legacy, loads first available).
    init() {
        self.initialBoard = nil
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var dataSource: InvestigationDataSource?
    @State private var selectedNodeID: UUID?
    @State private var zoomScale: Double = 1.0
    @State private var panX: Double = 0.0
    @State private var panY: Double = 0.0
    @State private var nodeSizes: [UUID: CGSize] = [:]
    @State private var nodeVisualSizes: [UUID: CGSize] = [:]
    @State private var isDropTargetActive = false
    @State private var edgeCreationState = BoardEdgeCreationState()
    @State private var gestureHandler: MultiGestureHandler?
    @State private var canvasGestureTarget: CanvasGestureTarget?
    @State private var nodeGestureTargets: [UUID: NodeGestureTarget] = [:]

    @State private var showingCreateNode = false
    @State private var showingEdgeLabelSheet = false
    @State private var pendingEdgeSource: UUID?
    @State private var pendingEdgeTarget: UUID?
    @State private var selectedEdgeSourceTarget: (UUID, UUID)? = nil

    // MARK: - Sidebar State (ER-0031)
    @State private var isSidebarVisible: Bool = true
    @State private var selectedCategoryFilter: NodeCategory? = nil
    @State private var detailNode: InvestigationNode? = nil
    @State private var selectedBacklogNodeIDs: Set<UUID> = []

    let configuration = BoardConfiguration.cumberland
    let canvasCoordSpace = "InvestigationCanvasSpace"

    // MARK: - Backlog (ER-0031)

    var backlogNodes: [InvestigationNode] {
        guard let ds = dataSource else { return [] }
        let all = ds.fetchBacklogNodes()
        if let filter = selectedCategoryFilter {
            return all.filter { $0.category == filter }
        }
        return all
    }

    private func addBacklogNodesToBoard(_ nodeIDs: [UUID]) {
        guard let ds = dataSource else { return }
        let worldCenter = BoardCanvasTransform.worldCenter(
            forWindowSize: CGSize(width: 800, height: 600),
            scale: zoomScale,
            panX: panX,
            panY: panY
        )
        ds.addNodes(nodeIDs, at: worldCenter)
    }

    var body: some View {
        GeometryReader { proxy in
            let contentSize = proxy.size

            ZStack {
                if let ds = dataSource {
                    let border = configuration.windowBorderWidth

                    // Inner ZStack: canvas + drop destination (matches Cumberland pattern)
                    ZStack {
                        BoardCanvasView(
                            dataSource: ds,
                            configuration: configuration,
                            selectedNodeID: selectedNodeID,
                            selectedEdgeSourceTarget: selectedEdgeSourceTarget,
                            scheme: scheme,
                            isContentReady: true,
                            isDropTargetActive: $isDropTargetActive,
                            zoomScale: $zoomScale,
                            panX: $panX,
                            panY: $panY,
                            nodeSizes: $nodeSizes,
                            nodeVisualSizes: $nodeVisualSizes,
                            edgeCreationState: edgeCreationState,
                            onDropNodeIDs: { nodeIDs, location in
                                guard let ds = dataSource else { return false }
                                ds.addNodes(nodeIDs, at: location)
                                return !nodeIDs.isEmpty
                            },
                            onRemoveNode: { nodeID in
                                ds.removeNode(nodeID)
                                if selectedNodeID == nodeID { selectedNodeID = nil }
                            },
                            onSelectNode: { nodeID in
                                selectedNodeID = nodeID
                            },
                            onEdgeCreated: { sourceID, targetID in
                                pendingEdgeSource = sourceID
                                pendingEdgeTarget = targetID
                                showingEdgeLabelSheet = true
                            },
                            onSelectEdge: { sourceID, targetID, typeCode in
                                selectedEdgeSourceTarget = (sourceID, targetID)
                                selectedNodeID = nil
                            }
                        ) { node, isSelected, isPrimary in
                            InvestigationNodeView(
                                node: node,
                                isSelected: isSelected,
                                scheme: scheme
                            )
                        }
                        // ER-0031: Drop destination for backlog node drags
                        .dropDestination(for: InvestigationNodeTransferData.self) { items, location in
                            guard let ds = dataSource else { return false }
                            let worldLocation = BoardCanvasTransform.viewToWorld(
                                location, scale: zoomScale, panX: panX, panY: panY
                            )
                            // If the dragged node is part of a multi-selection, add all selected nodes
                            var nodeIDs = items.map { $0.id }
                            let draggedSet = Set(nodeIDs)
                            if !selectedBacklogNodeIDs.isEmpty && !draggedSet.isDisjoint(with: selectedBacklogNodeIDs) {
                                let extra = selectedBacklogNodeIDs.subtracting(draggedSet)
                                nodeIDs.append(contentsOf: extra)
                            }
                            ds.addNodes(nodeIDs, at: worldLocation)
                            selectedBacklogNodeIDs.subtract(nodeIDs)
                            return !nodeIDs.isEmpty
                        } isTargeted: { isTargeted in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isDropTargetActive = isTargeted
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
                        selectedNodeID: $selectedNodeID,
                        onCanvasBackgroundTap: {
                            selectedEdgeSourceTarget = nil
                        },
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
                            pendingEdgeSource = sourceID
                            pendingEdgeTarget = targetID
                            showingEdgeLabelSheet = true
                        },
                        onSelectEdge: { sourceID, targetID, typeCode in
                            selectedEdgeSourceTarget = (sourceID, targetID)
                            selectedNodeID = nil
                        },
                        onRightClickNode: { nodeID, location, handler, coordinateInfo in
                            handleNodeRightClick(nodeID: nodeID, location: location, handler: handler, coordinateInfo: coordinateInfo)
                        },
                        onRightClickCanvas: { location, handler, coordinateInfo in
                            handleCanvasRightClick(location: location, handler: handler, coordinateInfo: coordinateInfo)
                        },
                        isSidebarVisible: isSidebarVisible
                    ))

                    // ER-0031: Backlog Sidebar (outside gesture-modified view)
                    InvestigationSidebarPanel(
                        contentSize: contentSize,
                        scheme: scheme,
                        isSidebarVisible: $isSidebarVisible,
                        selectedCategoryFilter: $selectedCategoryFilter,
                        detailNode: $detailNode,
                        selectedNodeIDs: $selectedBacklogNodeIDs,
                        backlogNodes: backlogNodes,
                        edgeCountProvider: { nodeID in
                            ds.edgeCount(for: nodeID)
                        },
                        onAddNodes: { nodeIDs in
                            addBacklogNodesToBoard(nodeIDs)
                            selectedBacklogNodeIDs.subtract(nodeIDs)
                        }
                    )

                    // Bottom zoom strip (outside gesture-modified view)
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
                                    nodeVisualSizes[nodeID] ?? CGSize(width: 200, height: 80)
                                },
                                zoomScale: zoomScale,
                                configuration: configuration
                            )
                        }
                    )
                    #endif
                } else {
                    ProgressView("Loading board...")
                }
            }
            .overlay(
                BoardBorderOverlay(configuration: configuration, scheme: scheme)
            )
            .clipShape(RoundedRectangle(cornerRadius: configuration.windowCornerRadius, style: .continuous))
        }
        .task {
            let ds = InvestigationDataSource(modelContext: modelContext)
            if let board = initialBoard {
                ds.loadBoard(board)
            } else {
                ds.loadOrCreateBoard(name: "My Investigation")
            }
            dataSource = ds
            zoomScale = ds.zoomScale
            panX = ds.panX
            panY = ds.panY
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Node", systemImage: "plus.circle") {
                    showingCreateNode = true
                }
            }
        }
        .sheet(isPresented: $showingCreateNode) {
            NodeEditorSheet(
                onCreate: { name, subtitle, category in
                    guard let ds = dataSource else { return }
                    _ = ds.createNode(
                        name: name,
                        subtitle: subtitle,
                        category: category
                    )
                }
            )
        }
        .sheet(isPresented: $showingEdgeLabelSheet) {
            EdgeLabelSheet(
                onConfirm: { label in
                    guard let ds = dataSource,
                          let source = pendingEdgeSource,
                          let target = pendingEdgeTarget else { return }
                    ds.createEdge(from: source, to: target, label: label)
                    pendingEdgeSource = nil
                    pendingEdgeTarget = nil
                },
                onCancel: {
                    pendingEdgeSource = nil
                    pendingEdgeTarget = nil
                }
            )
        }
        // ER-0031: Node detail inspection from sidebar
        .sheet(item: $detailNode) { node in
            InvestigationNodeDetailSheet(
                node: node,
                onAddToBoard: { nodeID in
                    addBacklogNodesToBoard([nodeID])
                }
            )
            #if os(iOS) || os(visionOS)
            .presentationDetents([.medium, .large])
            #endif
        }
    }

    // MARK: - ER-0033: Context Menu Handlers

    private func handleNodeRightClick(nodeID: UUID, location: CGPoint, handler: MultiGestureHandler?, coordinateInfo: CoordinateSpaceInfo) {
        guard let ds = dataSource,
              let board = ds.board,
              (board.nodes ?? []).contains(where: { $0.id == nodeID }) else { return }

        let isPrimary = (nodeID == board.primaryNodeID)

        var menuItems: [PopupMenuItem] = []

        // Remove from board → backlog
        menuItems.append(PopupMenuItem(
            title: "Remove from Board",
            systemImage: "tray.and.arrow.down",
            isDestructive: false,
            isDisabled: isPrimary,
            action: {
                ds.removeNode(nodeID)
                if selectedNodeID == nodeID { selectedNodeID = nil }
            }
        ))

        // Set as primary
        if !isPrimary {
            menuItems.append(PopupMenuItem(
                title: "Set as Primary",
                systemImage: "star",
                isDestructive: false,
                isDisabled: false,
                action: {
                    ds.setPrimaryNode(nodeID)
                }
            ))
        }

        // Delete permanently
        menuItems.append(PopupMenuItem(
            title: "Delete Permanently",
            systemImage: "trash",
            isDestructive: true,
            isDisabled: isPrimary,
            action: {
                ds.deleteNodePermanently(nodeID)
                if selectedNodeID == nodeID { selectedNodeID = nil }
            }
        ))

        if let handler {
            handler.showPopup(PopupMenu(items: menuItems, position: location, coordinateSpace: coordinateInfo))
        }
    }

    private func handleCanvasRightClick(location: CGPoint, handler: MultiGestureHandler?, coordinateInfo: CoordinateSpaceInfo) {
        let menuItems = [
            PopupMenuItem(
                title: "Add Node Here",
                systemImage: "plus.circle",
                isDestructive: false,
                isDisabled: false,
                action: { [self] in
                    showingCreateNode = true
                }
            )
        ]

        if let handler {
            handler.showPopup(PopupMenu(items: menuItems, position: location, coordinateSpace: coordinateInfo))
        }
    }
}
