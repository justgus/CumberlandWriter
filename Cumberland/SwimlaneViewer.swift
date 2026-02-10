//
//  SwimlaneViewer.swift
//  Cumberland
//
//  Horizontal scroll container that renders multiple Swimlane columns side by
//  side. Accepts LaneDescriptor array (explicit) or master card list (auto-
//  grouped by related card). Supports an optional relation-type filter and
//  drop using a default "references" relation type.
//

import SwiftUI
import SwiftData
import Combine

struct SwimlaneViewer: View {
    // Lane sources: either provide laneDescriptors or provide masters
    private let laneDescriptors: [LaneDescriptor]

    // Optional relation type filter (nil = all types; drop uses default "references")
    var relationTypeFilter: RelationType? = nil

    // Layout
    var laneWidth: CGFloat = 420
    var laneSpacing: CGFloat = 16
    var contentPadding: CGFloat = 16
    var showsIndicators: Bool = true

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Track resolved frames for drop hit-testing
    @State private var laneFrames: [UUID: CGRect] = [:]

    // Ambient background motion
    @State private var time: Double = 0

    struct LaneDescriptor: Identifiable {
        var id: UUID { master.id }
        let master: Card
        var direction: SwimlaneDirection = .topToBottom
        var showsHeader: Bool = true
    }

    init(laneDescriptors: [LaneDescriptor],
         relationTypeFilter: RelationType? = nil,
         laneWidth: CGFloat = 420,
         laneSpacing: CGFloat = 16,
         contentPadding: CGFloat = 16,
         showsIndicators: Bool = true)
    {
        self.laneDescriptors = laneDescriptors
        self.relationTypeFilter = relationTypeFilter
        self.laneWidth = laneWidth
        self.laneSpacing = laneSpacing
        self.contentPadding = contentPadding
        self.showsIndicators = showsIndicators
    }

    init(masters: [Card],
         directions: [UUID: SwimlaneDirection] = [:],
         showsHeaders: [UUID: Bool] = [:],
         relationTypeFilter: RelationType? = nil,
         laneWidth: CGFloat = 420,
         laneSpacing: CGFloat = 16,
         contentPadding: CGFloat = 16,
         showsIndicators: Bool = true)
    {
        self.laneDescriptors = masters.map { master in
            let dir = directions[master.id] ?? .topToBottom
            let showHeader = showsHeaders[master.id] ?? true
            return LaneDescriptor(master: master, direction: dir, showsHeader: showHeader)
        }
        self.relationTypeFilter = relationTypeFilter
        self.laneWidth = laneWidth
        self.laneSpacing = laneSpacing
        self.contentPadding = contentPadding
        self.showsIndicators = showsIndicators
    }

    private struct LaneFrameKey: PreferenceKey {
        static var defaultValue: [UUID: Anchor<CGRect>] = [:]
        static func reduce(value: inout [UUID: Anchor<CGRect>], nextValue: () -> [UUID: Anchor<CGRect>]) {
            value.merge(nextValue(), uniquingKeysWith: { _, new in new })
        }
    }

    var body: some View {
        ZStack {
            glassViewerBackground

            ScrollView(.horizontal, showsIndicators: showsIndicators) {
                LazyHStack(alignment: .top, spacing: laneSpacing) {
                    ForEach(laneDescriptors) { lane in
                        let related = orderedRelatedCards(for: lane.master, typeFilter: relationTypeFilter, direction: lane.direction)
                        Swimlane(
                            master: lane.master,
                            relatedCards: related,
                            relationTypeFilter: relationTypeFilter,
                            direction: lane.direction,
                            showsHeader: lane.showsHeader,
                            spacing: 12,
                            contentPadding: contentPadding
                        )
                        .frame(width: laneWidth)
                        .brightness(scheme == .dark ? 0.06 : 0.0)
                        .saturation(scheme == .dark ? 1.06 : 1.0)
                        .anchorPreference(key: LaneFrameKey.self, value: .bounds) { anchor in
                            [lane.master.id: anchor]
                        }
                        .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.18), radius: 16, x: 0, y: 10)
                    }
                }
                .padding(.horizontal, contentPadding)
                .padding(.top, 28)
                .padding(.bottom, 8)
                .backgroundPreferenceValue(LaneFrameKey.self) { anchors in
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                var resolved: [UUID: CGRect] = [:]
                                for (id, anchor) in anchors {
                                    resolved[id] = proxy[anchor]
                                }
                                laneFrames = resolved
                            }
                            // Recompute when the set of lane IDs changes
                            .task(id: anchors.keys.sorted(by: { $0.uuidString < $1.uuidString })) {
                                var resolved: [UUID: CGRect] = [:]
                                for (id, anchor) in anchors {
                                    resolved[id] = proxy[anchor]
                                }
                                laneFrames = resolved
                            }
                    }
                }
            }
            .dropDestination(for: String.self) { items, location in
                guard let idString = items.first, let uuid = UUID(uuidString: idString) else {
                    return false
                }
                if let laneID = laneFrames.first(where: { $0.value.contains(location) })?.key,
                   let lane = laneDescriptors.first(where: { $0.master.id == laneID }) {
                    // Append by default when dropping anywhere onto a lane background.
                    return relateCardAppend(with: uuid, to: lane.master)
                }
                return false
            }
        }
        .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 3.0)) {
                time = (time + 1).truncatingRemainder(dividingBy: 1000)
            }
        }
    }

    // MARK: - Viewer background

    private var glassViewerBackground: some View {
        let baseTop = Color.black.opacity(scheme == .dark ? 0.45 : 0.06)
        let baseBottom = Color.black.opacity(scheme == .dark ? 0.65 : 0.10)
        return ZStack {
            LinearGradient(
                colors: [baseTop, baseBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle moving caustic tint layer
            AngularGradient(
                gradient: Gradient(colors: [
                    .accentColor.opacity(scheme == .dark ? 0.10 : 0.06),
                    .clear,
                    .accentColor.opacity(scheme == .dark ? 0.06 : 0.04),
                    .clear
                ]),
                center: .center,
                startAngle: .degrees(30 + time * 18),
                endAngle: .degrees(220 + time * 18)
            )
            .blendMode(.softLight)
            .ignoresSafeArea()

            // Very subtle material film to tie the scene together
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(scheme == .dark ? 0.35 : 0.25)
                .ignoresSafeArea()
        }
    }

    // MARK: - Related via edges (ordered by sortIndex, then createdAt)

    @MainActor
    private func orderedRelatedCards(for master: Card, typeFilter: RelationType?, direction: SwimlaneDirection) -> [Card] {
        let predicate: Predicate<CardEdge>
        let masterIDOpt: UUID? = master.id
        if let t = typeFilter {
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
        // Map to 'from' and keep the edge order; unique by id preserving first occurrence
        var seen: Set<UUID> = []
        var ordered: [Card] = []
        for e in edges {
            guard let c = e.from else { continue }
            if !seen.contains(c.id) {
                seen.insert(c.id)
                ordered.append(c)
            }
        }
        switch direction {
        case .topToBottom: return ordered
        case .bottomToTop: return ordered.reversed()
        }
    }

    // MARK: - Relationship helpers (drop create via edges)

    @MainActor
    private func defaultRelationType() -> RelationType? {
        let fetch = FetchDescriptor<RelationType>(
            predicate: #Predicate { $0.code == "references" }
        )
        return try? modelContext.fetch(fetch).first
    }

    @MainActor
    private func edgeExists(from: Card, to: Card, type: RelationType) -> Bool {
        let fromIDOpt: UUID? = from.id
        let toIDOpt: UUID? = to.id
        let typeCodeOpt: String? = type.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.from?.id == fromIDOpt && $0.to?.id == toIDOpt && $0.type?.code == typeCodeOpt }
        )
        let found = try? modelContext.fetch(fetch)
        return (found?.isEmpty == false)
    }

    @MainActor
    private func relateCardAppend(with id: UUID, to master: Card) -> Bool {
        let cardFetch = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        guard let card = try? modelContext.fetch(cardFetch).first else { return false }
        let chosenType = relationTypeFilter ?? defaultRelationType()
        guard let type = chosenType else { return false }
        guard !edgeExists(from: card, to: master, type: type) else { return false }

        // Append to end: sortIndex = currentMax + 1.0
        let masterIDOpt: UUID? = master.id
        let typeCodeOpt: String? = type.code
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.to?.id == masterIDOpt && $0.type?.code == typeCodeOpt },
            sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
        )
        let existing = (try? modelContext.fetch(fetch)) ?? []
        let maxIndex = existing.last?.sortIndex ?? 0.0
        let newIndex = maxIndex + 1.0

        let edge = CardEdge(from: card, to: master, type: type, note: nil, createdAt: Date(), sortIndex: newIndex)

        // Use a fast animation so the lane update feels immediate
        withAnimation(.snappy(duration: 0.22)) {
            modelContext.insert(edge)
            try? modelContext.save()
        }
        return true
    }
}

#Preview("SwimlaneViewer - Mixed Directions (Light)") {
    // Build an in-memory container and INSERT all sample data into it
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    context.insert(relType)

    // Masters
    let masterA = Card(kind: .projects, name: "Project Alpha", subtitle: "Root A", detailedText: "Alpha master", sizeCategory: .standard)
    let masterB = Card(kind: .projects, name: "Project Beta", subtitle: "Root B", detailedText: "Beta master", sizeCategory: .standard)
    let masterC = Card(kind: .projects, name: "Project Gamma", subtitle: "Root C", detailedText: "Gamma master", sizeCategory: .standard)
    [masterA, masterB, masterC].forEach { context.insert($0) }

    func loremLines(_ count: Int) -> String {
        let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
    }
    let longText = loremLines(20)

    // Related for A
    let a1 = Card(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText, sizeCategory: .compact)
    let a2 = Card(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText, sizeCategory: .standard)
    let a3 = Card(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText, sizeCategory: .large)
    [a1, a2, a3].forEach { context.insert($0) }
    [CardEdge(from: a1, to: masterA, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: a2, to: masterA, type: relType, createdAt: Date(), sortIndex: 2),
     CardEdge(from: a3, to: masterA, type: relType, createdAt: Date(), sortIndex: 3)
    ].forEach { context.insert($0) }

    // Related for B
    let b1 = Card(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText, sizeCategory: .standard)
    let b2 = Card(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText, sizeCategory: .compact)
    [b1, b2].forEach { context.insert($0) }
    [CardEdge(from: b1, to: masterB, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: b2, to: masterB, type: relType, createdAt: Date(), sortIndex: 2)
    ].forEach { context.insert($0) }

    // Related for C
    let g1 = Card(kind: .scenes, name: "Docks", subtitle: "Foggy morning", detailedText: longText, sizeCategory: .standard)
    let g2 = Card(kind: .vehicles, name: "Hauler", subtitle: "Freight", detailedText: longText, sizeCategory: .compact)
    let g3 = Card(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: longText, sizeCategory: .large)
    let g4 = Card(kind: .worlds, name: "Nox", subtitle: "Nightside colony", detailedText: longText, sizeCategory: .standard)
    [g1, g2, g3, g4].forEach { context.insert($0) }
    [CardEdge(from: g1, to: masterC, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: g2, to: masterC, type: relType, createdAt: Date(), sortIndex: 2),
     CardEdge(from: g3, to: masterC, type: relType, createdAt: Date(), sortIndex: 3),
     CardEdge(from: g4, to: masterC, type: relType, createdAt: Date(), sortIndex: 4)
    ].forEach { context.insert($0) }

    let lanes: [SwimlaneViewer.LaneDescriptor] = [
        .init(master: masterA, direction: .topToBottom, showsHeader: true),
        .init(master: masterB, direction: .bottomToTop, showsHeader: true),
        .init(master: masterC, direction: .topToBottom, showsHeader: true)
    ]

    return SwimlaneViewer(laneDescriptors: lanes, relationTypeFilter: nil, laneWidth: 420, laneSpacing: 16, contentPadding: 16, showsIndicators: true)
        .modelContainer(container)
        .frame(height: 520)
        .padding()
}

#Preview("SwimlaneViewer - Mixed Directions (Dark)") {
    // Build an in-memory container and INSERT all sample data into it
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let relType = RelationType(code: "references", forwardLabel: "references", inverseLabel: "referenced by")
    context.insert(relType)

    let masterA = Card(kind: .projects, name: "Project Alpha", subtitle: "Root A", detailedText: "Alpha master", sizeCategory: .standard)
    let masterB = Card(kind: .projects, name: "Project Beta", subtitle: "Root B", detailedText: "Beta master", sizeCategory: .standard)
    let masterC = Card(kind: .projects, name: "Project Gamma", subtitle: "Root C", detailedText: "Gamma master", sizeCategory: .standard)
    [masterA, masterB, masterC].forEach { context.insert($0) }

    func loremLines(_ count: Int) -> String {
        let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
    }
    let longText = loremLines(20)

    let a1 = Card(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText, sizeCategory: .compact)
    let a2 = Card(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText, sizeCategory: .standard)
    let a3 = Card(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText, sizeCategory: .large)
    [a1, a2, a3].forEach { context.insert($0) }
    [CardEdge(from: a1, to: masterA, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: a2, to: masterA, type: relType, createdAt: Date(), sortIndex: 2),
     CardEdge(from: a3, to: masterA, type: relType, createdAt: Date(), sortIndex: 3)
    ].forEach { context.insert($0) }

    let b1 = Card(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText, sizeCategory: .standard)
    let b2 = Card(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText, sizeCategory: .compact)
    [b1, b2].forEach { context.insert($0) }
    [CardEdge(from: b1, to: masterB, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: b2, to: masterB, type: relType, createdAt: Date(), sortIndex: 2)
    ].forEach { context.insert($0) }

    let g1 = Card(kind: .scenes, name: "Docks", subtitle: "Foggy morning", detailedText: longText, sizeCategory: .standard)
    let g2 = Card(kind: .vehicles, name: "Hauler", subtitle: "Freight", detailedText: longText, sizeCategory: .compact)
    let g3 = Card(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: longText, sizeCategory: .large)
    let g4 = Card(kind: .worlds, name: "Nox", subtitle: "Nightside colony", detailedText: longText, sizeCategory: .standard)
    [g1, g2, g3, g4].forEach { context.insert($0) }
    [CardEdge(from: g1, to: masterC, type: relType, createdAt: Date(), sortIndex: 1),
     CardEdge(from: g2, to: masterC, type: relType, createdAt: Date(), sortIndex: 2),
     CardEdge(from: g3, to: masterC, type: relType, createdAt: Date(), sortIndex: 3),
     CardEdge(from: g4, to: masterC, type: relType, createdAt: Date(), sortIndex: 4)
    ].forEach { context.insert($0) }

    let lanes: [SwimlaneViewer.LaneDescriptor] = [
        .init(master: masterA, direction: .topToBottom, showsHeader: true),
        .init(master: masterB, direction: .bottomToTop, showsHeader: true),
        .init(master: masterC, direction: .topToBottom, showsHeader: true)
    ]

    return SwimlaneViewer(laneDescriptors: lanes, relationTypeFilter: nil, laneWidth: 420, laneSpacing: 16, contentPadding: 16, showsIndicators: true)
        .modelContainer(container)
        .frame(height: 520)
        .padding()
        .preferredColorScheme(.dark)
}
