//
//  Swimlane.swift
//  Cumberland
//
//  A single vertical or horizontal lane in the StructureBoardView / SwimlaneViewer.
//  Displays a header label and a scrollable stack of CardView tiles for cards
//  assigned to that lane. Accepts drag-and-drop to reassign cards between lanes.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

enum SwimlaneDirection {
    case topToBottom
    case bottomToTop
}

struct Swimlane: View {
    let master: Card
    let relatedCards: [Card]
    var relationTypeFilter: RelationType? = nil
    var direction: SwimlaneDirection = .topToBottom
    var showsHeader: Bool = true
    var spacing: CGFloat = 12
    var contentPadding: CGFloat = 16

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Appearance
    private let laneCornerRadius: CGFloat = 20

    // Drop zone / persistent padding
    private let dropZoneHeight: CGFloat = 56

    // Track row frames to compute insertion indices from cursor location
    private struct RowFrameKey: PreferenceKey {
        static var defaultValue: [UUID: Anchor<CGRect>] = [:]
        static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }
    @State private var rowFrames: [UUID: CGRect] = [:]

    // Track bottom inset hover/drag targeting for glow
    @State private var isBottomDropTargeted: Bool = false

    // Ambient motion for tint gradient
    @State private var time: Double = 0

    private var orderedCards: [Card] {
        switch direction {
        case .topToBottom:
            return relatedCards
        case .bottomToTop:
            return Array(relatedCards.reversed())
        }
    }

    private var orderedCardIDs: [UUID] {
        orderedCards.map(\.id)
    }

    // Etched hairline divider
    private var hairlineDividerFullWidth: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .white.opacity(scheme == .dark ? 0.18 : 0.35),
                        .black.opacity(scheme == .dark ? 0.20 : 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .blendMode(.overlay)
            .opacity(0.9)
    }

    var body: some View {
        ZStack {
            glassLaneBackground

            VStack(spacing: 0) {
                if showsHeader && direction == .topToBottom {
                    header
                        .padding([.top, .horizontal], contentPadding)
                        .padding(.bottom, 8)
                        .dropDestination(for: String.self) { items, location in
                            return handleDroppedStrings(items, location: location, targetRegion: .headerTop)
                        }
                    hairlineDividerFullWidth
                }

                scrollArea

                if showsHeader && direction == .bottomToTop {
                    hairlineDividerFullWidth
                    header
                        .padding([.horizontal, .bottom], contentPadding)
                        .padding(.top, 8)
                        .dropDestination(for: String.self) { items, location in
                            return handleDroppedStrings(items, location: location, targetRegion: .headerBottom)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous))
        }
        .padding(8)
        .onReceive(Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()) { _ in
            // Very slow ambient motion for tint gradient
            withAnimation(.easeInOut(duration: 2.5)) {
                time = (time + 1).truncatingRemainder(dividingBy: 1000)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: master.kind.systemImage)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        master.kind.accentColor(for: scheme).opacity(0.95),
                        .white.opacity(scheme == .dark ? 0.7 : 0.9)
                    )
                    .font(.caption2)
                Text(master.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(master.name)
                .font(.title3).bold()
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 0.5, x: 0, y: 0.5)

            if !master.subtitle.isEmpty {
                Text(master.subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private enum TargetRegion {
        case headerTop
        case headerBottom
        case body
        case bottomInset
    }

    private var scrollArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(orderedCards, id: \.id) { card in
                        CardRow(card: card) {
                            removeCardFromLane(card)
                        }
                        .id(card.id)
                        .anchorPreference(key: RowFrameKey.self, value: .bounds) { anchor in
                            [card.id: anchor]
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                // Animate row moves/inserts/removals quickly when the set/order changes
                .animation(.snappy(duration: 0.22), value: orderedCardIDs)
                .padding(.top, 16)
                .padding([.horizontal, .bottom], contentPadding)
                .background(insetPanelBackground)
                .backgroundPreferenceValue(RowFrameKey.self) { anchors in
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                rowFrames = resolve(anchors, in: proxy)
                            }
                            .task(id: anchors.keys.sorted(by: { $0.uuidString < $1.uuidString })) {
                                rowFrames = resolve(anchors, in: proxy)
                            }
                    }
                }
                .dropDestination(for: String.self) { items, location in
                    return handleDroppedStrings(items, location: location, targetRegion: .body)
                }
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 10)
            }
            .safeAreaInset(edge: .bottom) {
                GlassDropZone(
                    height: dropZoneHeight,
                    cornerRadius: laneCornerRadius,
                    isTargeted: isBottomDropTargeted,
                    contentPadding: contentPadding,
                    label: "Drop to append"
                )
                .dropDestination(for: String.self, action: { items, location in
                    handleDroppedStrings(items, location: location, targetRegion: .bottomInset)
                }, isTargeted: { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isBottomDropTargeted = hovering
                    }
                })
                .padding(.horizontal, 0)
            }
            .onAppear {
                if direction == .bottomToTop, let lastID = orderedCards.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
            .onChange(of: orderedCardIDs) { _, _ in
                if direction == .bottomToTop, let lastID = orderedCards.last?.id {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }

    private var insetPanelBackground: some View {
        // Translucent inner panel that looks like glass inset into the lane
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                // Inner bevel: soft shadow at bottom, highlight at top
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.12 : 0.28), lineWidth: 1)
                    .blendMode(.overlay)
                    .opacity(0.9)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.28 : 0.10), radius: 8, x: 0, y: 4)
            .modifier(RectInnerBevel(
                shadowColor: .black.opacity(scheme == .dark ? 0.45 : 0.30),
                highlightColor: .white.opacity(scheme == .dark ? 0.16 : 0.35),
                shadowRadius: 3,
                shadowOffsetY: 2,
                highlightRadius: 2,
                highlightOffsetY: -1
            ))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.quaternary.opacity(0.6), lineWidth: 0.5)
            )
    }

    private var glassLaneBackground: some View {
        let accent = master.kind.accentColor(for: scheme)
        return RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                // Subtle angled tint gradient that slowly animates
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                accent.opacity(scheme == .dark ? 0.18 : 0.10),
                                .clear,
                                accent.opacity(scheme == .dark ? 0.10 : 0.06),
                                .clear
                            ]),
                            center: .center,
                            startAngle: .degrees(10 + time * 22),
                            endAngle: .degrees(200 + time * 22)
                        )
                    )
                    .blendMode(.softLight)
            )
            .overlay(
                // Inner hairline highlight near top edge
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.20 : 0.35), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .background(
                // Soft shadow to float the lane above the viewer background
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.18), radius: 18, x: 0, y: 10)
            )
    }

    private func resolve(_ anchors: [UUID: Anchor<CGRect>], in proxy: GeometryProxy) -> [UUID: CGRect] {
        var resolved: [UUID: CGRect] = [:]
        for (id, anchor) in anchors {
            resolved[id] = proxy[anchor]
        }
        return resolved
    }

    // MARK: - Drop handling (String-based with insertion index, sortIndex persistence)

    @MainActor
    private func handleDroppedStrings(_ items: [String], location: CGPoint, targetRegion: TargetRegion) -> Bool {
        guard let idString = items.first, let uuid = UUID(uuidString: idString) else {
            return false
        }
        guard let droppedCard = fetchCard(by: uuid) else {
            return false
        }

        let index: Int
        switch targetRegion {
        case .headerTop:
            index = (direction == .topToBottom) ? 0 : orderedCards.count
        case .headerBottom:
            index = (direction == .bottomToTop) ? 0 : orderedCards.count
        case .bottomInset:
            index = (direction == .topToBottom) ? orderedCards.count : 0
        case .body:
            index = insertionIndex(for: location)
        }

        insertCardIntoLane(droppedCard, at: index)
        return true
    }

    private func insertionIndex(for location: CGPoint) -> Int {
        // Compute insertion index by comparing to row midY positions in visual order
        let ids = orderedCardIDs
        guard !ids.isEmpty else { return 0 }
        let rects: [(UUID, CGRect)] = ids.compactMap { id in
            guard let r = rowFrames[id] else { return nil }
            return (id, r)
        }
        guard !rects.isEmpty else { return 0 }

        for (idx, pair) in rects.enumerated() {
            let rect = pair.1
            let midY = rect.midY
            if location.y < midY {
                return idx
            }
        }
        return rects.count
    }

    @MainActor
    private func fetchCard(by id: UUID) -> Card? {
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.id == id },
            sortBy: []
        )
        return try? modelContext.fetch(descriptor).first
    }

    @MainActor
    private func defaultRelationType() -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == "references" }
        )
        return try? modelContext.fetch(fetch).first
    }

    @MainActor
    private func edgeFor(from: Card, to: Card, type: RelationType?) -> CardEdge? {
        let fromIDOpt: UUID? = from.id
        let toIDOpt: UUID? = to.id
        if let t = type {
            let typeCodeOpt: String? = t.code
            let fetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { $0.from?.id == fromIDOpt && $0.to?.id == toIDOpt && $0.type?.code == typeCodeOpt }
            )
            return try? modelContext.fetch(fetch).first
        } else {
            let fetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate { $0.from?.id == fromIDOpt && $0.to?.id == toIDOpt }
            )
            return try? modelContext.fetch(fetch).first
        }
    }

    @MainActor
    private func neighborIndicesForInsertion(at index: Int) -> (before: Double?, after: Double?) {
        // Fetch edges to master sorted by sortIndex for the same filter
        let masterIDOpt: UUID? = master.id
        let predicate: Predicate<CardEdge>
        if let t = relationTypeFilter {
            let typeCodeOpt: String? = t.code
            predicate = #Predicate { $0.to?.id == masterIDOpt && $0.type?.code == typeCodeOpt }
        } else {
            predicate = #Predicate { $0.to?.id == masterIDOpt }
        }
        let fetch = FetchDescriptor<CardEdge>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.sortIndex, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        let edges = (try? modelContext.fetch(fetch)) ?? []

        // Map into visual order (respecting direction)
        var visual: [CardEdge] = []
        for c in orderedCards {
            if let e = edges.first(where: { $0.from?.id == Optional(c.id) }) {
                visual.append(e)
            }
        }

        let before = (index - 1) >= 0 && (index - 1) < visual.count ? visual[index - 1].sortIndex : nil
        let after = index < visual.count ? visual[index].sortIndex : nil
        return (before, after)
    }

    @MainActor
    private func indexBetween(_ a: Double?, _ b: Double?) -> Double {
        if let a, let b {
            return (a + b) / 2.0
        } else if let a { // after a
            return a + 1.0
        } else if let b { // before b
            return b - 1.0
        } else {
            return 0.0
        }
    }

    @MainActor
    private func insertCardIntoLane(_ card: Card, at index: Int) {
        let chosenType = relationTypeFilter ?? defaultRelationType()
        guard let type = chosenType else { return }

        // Determine new sortIndex from neighbor indices in visual order
        let clamped = max(0, min(index, orderedCards.count))
        let (before, after) = neighborIndicesForInsertion(at: clamped)
        let newIndex = indexBetween(before, after)

        if let edge = edgeFor(from: card, to: master, type: relationTypeFilter) {
            // Already in lane: reorder by updating sortIndex
            withAnimation(.snappy(duration: 0.22)) {
                edge.sortIndex = newIndex
                try? modelContext.save()
            }
            return
        }

        // Not yet in lane: create edge at computed position
        let edge = CardEdge(from: card, to: master, type: type, note: nil, createdAt: Date(), sortIndex: newIndex)
        withAnimation(.snappy(duration: 0.22)) {
            modelContext.insert(edge)
            try? modelContext.save()
        }
    }

    @MainActor
    private func removeCardFromLane(_ card: Card) {
        // Remove any edge(s) from card -> master that match our filter (if any), or any type if filter is nil
        let fromIDOpt: UUID? = card.id
        let masterIDOpt: UUID? = master.id

        let predicate: Predicate<CardEdge>
        if let t = relationTypeFilter {
            let typeCodeOpt: String? = t.code
            predicate = #Predicate { $0.from?.id == fromIDOpt && $0.to?.id == masterIDOpt && $0.type?.code == typeCodeOpt }
        } else {
            predicate = #Predicate { $0.from?.id == fromIDOpt && $0.to?.id == masterIDOpt }
        }

        let fetch = FetchDescriptor<CardEdge>(predicate: predicate)
        if let edges = try? modelContext.fetch(fetch) {
            withAnimation(.snappy(duration: 0.22)) {
                if let um = modelContext.undoManager {
                    um.beginUndoGrouping()
                    um.setActionName("Remove from Swimlane")
                }
                for e in edges {
                    modelContext.delete(e)
                }
                try? modelContext.save()
                modelContext.undoManager?.endUndoGrouping()
            }
        }
    }
}

// MARK: - CardRow (extracted to reduce generic depth)

private struct CardRow: View {
    let card: Card
    var onRemove: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        CardView(card: card)
            .onDrag {
                NSItemProvider(object: card.id.uuidString as NSString)
            }
            .contextMenu {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Remove from Swimlane", systemImage: "tray.and.arrow.up")
                }
            }
            .hoverEffectIfAvailable()
    }
}

// MARK: - Glass helpers

private extension View {
    // Soft glass card inset feel
    func glassCardInset() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
    }

    // macOS-only hover scale; no-op elsewhere
    @ViewBuilder
    func hoverEffectIfAvailable() -> some View {
        #if os(macOS)
        self
            .onHover { hovering in
                // subtle scale/glow handled by the overlay stroke above; keep scale minimal
            }
        #else
        self
        #endif
    }
}

// MARK: - Inner shadow helpers

struct InnerShadow: ViewModifier {
    let cornerRadius: CGFloat
    let color: Color
    let radius: CGFloat
    let offset: CGSize

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: 2)
                    .blur(radius: radius)
                    .offset(offset)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
    }
}

private struct RectInnerBevel: ViewModifier {
    let shadowColor: Color
    let highlightColor: Color
    let shadowRadius: CGFloat
    let shadowOffsetY: CGFloat
    let highlightRadius: CGFloat
    let highlightOffsetY: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .stroke(shadowColor, lineWidth: 2)
                    .blur(radius: shadowRadius)
                    .offset(x: 0, y: shadowOffsetY)
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.black, .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(highlightColor, lineWidth: 2)
                    .blur(radius: highlightRadius)
                    .offset(x: 0, y: highlightOffsetY)
                    .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                )
            )
    }
}

extension View {
    func innerShadow(cornerRadius: CGFloat,
                     color: Color = .black.opacity(0.2),
                     radius: CGFloat = 6,
                     offset: CGSize = CGSize(width: 0, height: 2)) -> some View {
        modifier(InnerShadow(cornerRadius: cornerRadius, color: color, radius: radius, offset: offset))
    }
}

// MARK: - Preview helpers

private func loremLines(_ count: Int) -> String {
    let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
}

private func makeTopToBottomPreview() -> some View {
    let master = Card(kind: .projects, name: "Master Project", subtitle: "Swimlane Root", detailedText: "This is the master card for the swimlane.", sizeCategory: .standard)
    let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")

    let longText = loremLines(20)

    let child1 = Card(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText, sizeCategory: .compact)
    let child2 = Card(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText, sizeCategory: .standard)
    let child3 = Card(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText, sizeCategory: .large)

    let _ = CardEdge(from: child1, to: master, type: relType, createdAt: Date(), sortIndex: 1)
    let _ = CardEdge(from: child2, to: master, type: relType, createdAt: Date(), sortIndex: 2)
    let _ = CardEdge(from: child3, to: master, type: relType, createdAt: Date(), sortIndex: 3)

    return Swimlane(master: master, relatedCards: [child1, child2, child3], relationTypeFilter: nil, direction: .topToBottom)
        .modelContainer(for: [Card.self, RelationType.self, CardEdge.self], inMemory: true)
        .padding()
        .frame(width: 420)
        .preferredColorScheme(.light)
}

private func makeBottomToTopPreview() -> some View {
    let master = Card(kind: .projects, name: "Master Project", subtitle: "Swimlane Root", detailedText: "This is the master card for the swimlane.", sizeCategory: .standard)
    let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")

    let longText = loremLines(20)

    let child1 = Card(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText, sizeCategory: .standard)
    let child2 = Card(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText, sizeCategory: .compact)
    let child3 = Card(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText, sizeCategory: .large)

    let _ = CardEdge(from: child1, to: master, type: relType, createdAt: Date(), sortIndex: 1)
    let _ = CardEdge(from: child2, to: master, type: relType, createdAt: Date(), sortIndex: 2)
    let _ = CardEdge(from: child3, to: master, type: relType, createdAt: Date(), sortIndex: 3)

    return Swimlane(master: master, relatedCards: [child1, child2, child3], relationTypeFilter: nil, direction: .bottomToTop)
        .modelContainer(for: [Card.self, RelationType.self, CardEdge.self], inMemory: true)
        .padding()
        .frame(width: 420)
        .preferredColorScheme(.dark)
}

#Preview("Swimlane - Top to Bottom (Light)") {
    makeTopToBottomPreview()
}

#Preview("Swimlane - Bottom to Top (Dark)") {
    makeBottomToTopPreview()
}

