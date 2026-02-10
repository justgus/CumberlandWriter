//
//  MurderBoardToolbar.swift
//  Cumberland
//
//  Extracted from MurderBoardView.swift as part of ER-0022 Phase 3.3.
//  Provides the Murderboard toolbar (fit-to-screen, add-node, backlog
//  toggle, edge-creation mode) and the macOS zoom strip with an editable
//  ZoomTextField that commits only on Return or focus loss.
//

import SwiftUI
import SwiftData

// MARK: - Zoom Text Field (macOS bottom strip)

#if os(macOS)
/// Editable zoom percentage field that only commits on Return or focus loss,
/// preventing mid-edit clamp side-effects (e.g. erasing "100" clamps to min).
private struct ZoomTextField: View {
    let zoomScale: Double
    let windowSize: CGSize
    let setZoom: (Double, CGSize) -> Void

    @State private var draft: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            TextField("100", text: $draft, onEditingChanged: { editing in
                isEditing = editing
                if editing {
                    draft = "\(Int(round(zoomScale * 100)))"
                } else {
                    commitDraft()
                }
            }, onCommit: {
                commitDraft()
            })
            .font(.caption.monospacedDigit())
            .multilineTextAlignment(.trailing)
            .frame(width: 30)
            .textFieldStyle(.plain)
            .onChange(of: zoomScale) { _, newScale in
                // Keep display in sync when zoom changes externally (slider, buttons)
                if !isEditing {
                    draft = "\(Int(round(newScale * 100)))"
                }
            }
            .onAppear {
                draft = "\(Int(round(zoomScale * 100)))"
            }
            Text("%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func commitDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if let v = Double(trimmed), v >= 1 {
            let s = (v / 100.0).clamped(to: Board.minZoom...Board.maxZoom)
            setZoom(s, windowSize)
        }
        // Reset to current actual zoom (handles invalid input)
        draft = "\(Int(round(zoomScale * 100)))"
    }
}
#endif

// MARK: - Bottom Zoom Strip (macOS)

#if os(macOS)
extension MurderBoardView {
    /// Compact floating zoom / recenter / shuffle strip rendered at the bottom-centre
    /// of the MurderBoard canvas, similar to the zoom HUD in office applications.
    /// On macOS the window-toolbar approach produces left-side placement for nested views,
    /// so we render the controls as an in-canvas overlay instead.
    @ViewBuilder
    func bottomZoomStrip(windowSize: CGSize) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Button { stepZoom(-0.05, windowSize: windowSize) } label: {
                    Image(systemName: "minus")
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Zoom Out (⌘-)")

                Slider(value: Binding(
                    get: { zoomScale },
                    set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
                ), in: Board.minZoom...Board.maxZoom)
                .frame(width: 100)
                .controlSize(.small)
                .help("Zoom")

                Button { stepZoom(+0.05, windowSize: windowSize) } label: {
                    Image(systemName: "plus")
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Zoom In (⌘=)")
                .keyboardShortcut("=", modifiers: [.command])

                ZoomTextField(
                    zoomScale: zoomScale,
                    windowSize: windowSize,
                    setZoom: { s, ws in setZoomKeepingCenter(s, windowSize: ws) }
                )

                Divider()
                    .frame(height: 14)

                Button { recenterOnPrimaryOrFirst(windowSize: windowSize) } label: {
                    Image(systemName: "dot.scope")
                }
                .buttonStyle(.plain)
                .help("Recenter (⌘R)")

                Button { shuffleAroundPrimary() } label: {
                    Image(systemName: "shuffle")
                }
                .buttonStyle(.plain)
                .help("Shuffle nodes")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .padding(.bottom, 14)
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity)
    }
}
#endif

// MARK: - Bottom Zoom Strip (iOS)

#if os(iOS)
extension MurderBoardView {
    @ViewBuilder
    func bottomZoomStrip(windowSize: CGSize) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Button { stepZoom(-0.05, windowSize: windowSize) } label: {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Slider(value: Binding(
                    get: { zoomScale },
                    set: { newValue in setZoomKeepingCenter(newValue, windowSize: windowSize) }
                ), in: Board.minZoom...Board.maxZoom)
                .frame(width: 120)

                Button { stepZoom(+0.05, windowSize: windowSize) } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("\(Int(round(zoomScale * 100)))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)

                Divider()
                    .frame(height: 16)

                Button { recenterOnPrimaryOrFirst(windowSize: windowSize) } label: {
                    Image(systemName: "dot.scope")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button { shuffleAroundPrimary() } label: {
                    Image(systemName: "shuffle")
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
    }
}
#endif

// MARK: - Toolbar Extension

extension MurderBoardView {
    @ToolbarContentBuilder
    func toolbarContent(windowSize: CGSize) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
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
            // Debug controls can go here
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
}

// MARK: - Shuffle Geometry Constants

let shuffleInitialAnchorFactor: CGFloat = 0.35
let shuffleInitialNodeSpanFactor: CGFloat = 0.45
let shuffleBaseMarginWorldFactor: CGFloat = 0.10
let shuffleBaseMarginViewPadding: CGFloat = 8.0
let shuffleSpacingMultiplier: CGFloat = 1.15
let shuffleRingSeparationMultiplier: CGFloat = 0.75
let shuffleRadialJitterWorld: ClosedRange<Double> = -0.06...0.06
let shuffleAngularJitter: ClosedRange<Double> = -0.12...0.12

// MARK: - Shuffle Implementation

extension MurderBoardView {
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
