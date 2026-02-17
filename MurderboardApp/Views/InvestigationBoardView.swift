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

    let configuration = BoardConfiguration.cumberland
    let canvasCoordSpace = "InvestigationCanvasSpace"

    var body: some View {
        GeometryReader { proxy in
            let contentSize = proxy.size

            ZStack {
                if let ds = dataSource {
                    // Canvas
                    BoardCanvasView(
                        dataSource: ds,
                        configuration: configuration,
                        selectedNodeID: selectedNodeID,
                        scheme: scheme,
                        isContentReady: true,
                        isDropTargetActive: $isDropTargetActive,
                        zoomScale: $zoomScale,
                        panX: $panX,
                        panY: $panY,
                        nodeSizes: $nodeSizes,
                        nodeVisualSizes: $nodeVisualSizes,
                        edgeCreationState: edgeCreationState,
                        onDropNodeIDs: { _, _ in false },
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
                        }
                    ) { node, isSelected, isPrimary in
                        InvestigationNodeView(
                            node: node,
                            isSelected: isSelected,
                            scheme: scheme
                        )
                    }
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
                        }
                    ))

                    // Bottom zoom strip
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
            ds.loadOrCreateBoard(name: "My Investigation")
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
                    let worldCenter = BoardCanvasTransform.worldCenter(
                        forWindowSize: CGSize(width: 800, height: 600),
                        scale: zoomScale,
                        panX: panX,
                        panY: panY
                    )
                    _ = ds.createNode(
                        name: name,
                        subtitle: subtitle,
                        category: category,
                        at: worldCenter
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
    }
}
