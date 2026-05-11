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
    @Environment(\.services) private var services

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
        guard let services = services else { return [] }

        // Fetch incoming edges to master, then filter by type if needed
        var edges = services.edgeRepository.fetchIncoming(to: master)
        if let t = typeFilter {
            edges = edges.filter { $0.type?.code == t.code }
        }

        // Sort by sortIndex, then createdAt
        edges.sort { a, b in
            if a.sortIndex != b.sortIndex {
                return a.sortIndex < b.sortIndex
            }
            return a.createdAt < b.createdAt
        }

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
        let relTypeManager = RelationTypeManager(modelContext: modelContext)
        return relTypeManager.ensureRelationType(
            code: "references",
            forwardLabel: "references",
            inverseLabel: "referenced by"
        )
    }

    @MainActor
    private func edgeExists(from: Card, to: Card, type: RelationType) -> Bool {
        guard let services = services else { return false }
        let outgoing = services.edgeRepository.fetchOutgoing(from: from)
        return outgoing.contains { edge in
            edge.to?.id == to.id && edge.type?.code == type.code
        }
    }

    @MainActor
    private func relateCardAppend(with id: UUID, to master: Card) -> Bool {
        guard let services = services else { return false }
        guard let card = services.cardRepository.fetch(byUUID: id) else { return false }
        let chosenType = relationTypeFilter ?? defaultRelationType()
        guard let type = chosenType else { return false }
        guard !edgeExists(from: card, to: master, type: type) else { return false }

        // Append to end: sortIndex = currentMax + 1.0
        var existing = services.edgeRepository.fetchIncoming(to: master)
        existing = existing.filter { $0.type?.code == type.code }
        existing.sort { $0.sortIndex < $1.sortIndex }
        let maxIndex = existing.last?.sortIndex ?? 0.0
        let newIndex = maxIndex + 1.0

        // Use a fast animation so the lane update feels immediate
        withAnimation(.snappy(duration: 0.22)) {
            try? services.edgeRepository.createRelationship(
                from: card,
                to: master,
                relationType: type,
                sortIndex: newIndex
            )
        }
        return true
    }
}

#Preview("SwimlaneViewer - Mixed Directions (Light)") { @MainActor in
    let container = ModelContainerFactory.makeInMemoryContainer([
        Card.self, RelationType.self, CardEdge.self,
        StoryStructure.self, StructureElement.self,
        Board.self, BoardNode.self,
        Citation.self, Source.self,
        CalendarSystem.self, AppSettings.self, SuggestionFeedback.self
    ])
    let ctx = container.mainContext
    let services = ServiceContainer(modelContext: ctx)

    let relTypeManager = RelationTypeManager(modelContext: ctx)
    let relType = relTypeManager.ensureRelationType(
        code: "references",
        forwardLabel: "references",
        inverseLabel: "referenced by"
    )

    let cardRepo = CardRepository(modelContext: ctx)

    func loremLines(_ count: Int) -> String {
        let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
    }
    let longText = loremLines(20)

    // Masters
    let masterA = try! cardRepo.createCard(kind: .projects, name: "Project Alpha", subtitle: "Root A", detailedText: "Alpha master")
    masterA.sizeCategory = .standard
    let masterB = try! cardRepo.createCard(kind: .projects, name: "Project Beta", subtitle: "Root B", detailedText: "Beta master")
    masterB.sizeCategory = .standard
    let masterC = try! cardRepo.createCard(kind: .projects, name: "Project Gamma", subtitle: "Root C", detailedText: "Gamma master")
    masterC.sizeCategory = .standard

    // Related for A
    let a1 = try! cardRepo.createCard(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText)
    a1.sizeCategory = .compact
    let a2 = try! cardRepo.createCard(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText)
    a2.sizeCategory = .standard
    let a3 = try! cardRepo.createCard(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText)
    a3.sizeCategory = .large

    let edgeRepo = EdgeRepository(modelContext: ctx)
    try? edgeRepo.createRelationship(from: a1, to: masterA, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: a2, to: masterA, relationType: relType, sortIndex: 2)
    try? edgeRepo.createRelationship(from: a3, to: masterA, relationType: relType, sortIndex: 3)

    // Related for B
    let b1 = try! cardRepo.createCard(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText)
    b1.sizeCategory = .standard
    let b2 = try! cardRepo.createCard(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText)
    b2.sizeCategory = .compact
    try? edgeRepo.createRelationship(from: b1, to: masterB, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: b2, to: masterB, relationType: relType, sortIndex: 2)

    // Related for C
    let g1 = try! cardRepo.createCard(kind: .scenes, name: "Docks", subtitle: "Foggy morning", detailedText: longText)
    g1.sizeCategory = .standard
    let g2 = try! cardRepo.createCard(kind: .vehicles, name: "Hauler", subtitle: "Freight", detailedText: longText)
    g2.sizeCategory = .compact
    let g3 = try! cardRepo.createCard(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: longText)
    g3.sizeCategory = .large
    let g4 = try! cardRepo.createCard(kind: .worlds, name: "Nox", subtitle: "Nightside colony", detailedText: longText)
    g4.sizeCategory = .standard
    try? edgeRepo.createRelationship(from: g1, to: masterC, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: g2, to: masterC, relationType: relType, sortIndex: 2)
    try? edgeRepo.createRelationship(from: g3, to: masterC, relationType: relType, sortIndex: 3)
    try? edgeRepo.createRelationship(from: g4, to: masterC, relationType: relType, sortIndex: 4)
    try? ctx.save()

    let lanes: [SwimlaneViewer.LaneDescriptor] = [
        .init(master: masterA, direction: .topToBottom, showsHeader: true),
        .init(master: masterB, direction: .bottomToTop, showsHeader: true),
        .init(master: masterC, direction: .topToBottom, showsHeader: true)
    ]

    return SwimlaneViewer(laneDescriptors: lanes, relationTypeFilter: nil, laneWidth: 420, laneSpacing: 16, contentPadding: 16, showsIndicators: true)
        .modelContainer(container)
        .serviceContainer(services)
        .frame(height: 520)
        .padding()
}

#Preview("SwimlaneViewer - Mixed Directions (Dark)") { @MainActor in
    let container = ModelContainerFactory.makeInMemoryContainer([
        Card.self, RelationType.self, CardEdge.self,
        StoryStructure.self, StructureElement.self,
        Board.self, BoardNode.self,
        Citation.self, Source.self,
        CalendarSystem.self, AppSettings.self, SuggestionFeedback.self
    ])
    let ctx = container.mainContext
    let services = ServiceContainer(modelContext: ctx)

    let relTypeManager = RelationTypeManager(modelContext: ctx)
    let relType = relTypeManager.ensureRelationType(
        code: "references",
        forwardLabel: "references",
        inverseLabel: "referenced by"
    )

    let cardRepo = CardRepository(modelContext: ctx)

    func loremLines(_ count: Int) -> String {
        let base = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        return (1...count).map { "\($0). \(base)" }.joined(separator: "\n")
    }
    let longText = loremLines(20)

    // Masters
    let masterA = try! cardRepo.createCard(kind: .projects, name: "Project Alpha", subtitle: "Root A", detailedText: "Alpha master")
    masterA.sizeCategory = .standard
    let masterB = try! cardRepo.createCard(kind: .projects, name: "Project Beta", subtitle: "Root B", detailedText: "Beta master")
    masterB.sizeCategory = .standard
    let masterC = try! cardRepo.createCard(kind: .projects, name: "Project Gamma", subtitle: "Root C", detailedText: "Gamma master")
    masterC.sizeCategory = .standard

    // Related for A
    let a1 = try! cardRepo.createCard(kind: .characters, name: "Mira", subtitle: "Scout", detailedText: longText)
    a1.sizeCategory = .compact
    let a2 = try! cardRepo.createCard(kind: .vehicles, name: "Skiff", subtitle: "Courier", detailedText: longText)
    a2.sizeCategory = .standard
    let a3 = try! cardRepo.createCard(kind: .scenes, name: "Market", subtitle: "Evening bustle", detailedText: longText)
    a3.sizeCategory = .large

    let edgeRepo = EdgeRepository(modelContext: ctx)
    try? edgeRepo.createRelationship(from: a1, to: masterA, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: a2, to: masterA, relationType: relType, sortIndex: 2)
    try? edgeRepo.createRelationship(from: a3, to: masterA, relationType: relType, sortIndex: 3)

    // Related for B
    let b1 = try! cardRepo.createCard(kind: .characters, name: "Aiden", subtitle: "Pilot", detailedText: longText)
    b1.sizeCategory = .standard
    let b2 = try! cardRepo.createCard(kind: .worlds, name: "Aether", subtitle: "Geography", detailedText: longText)
    b2.sizeCategory = .compact
    try? edgeRepo.createRelationship(from: b1, to: masterB, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: b2, to: masterB, relationType: relType, sortIndex: 2)

    // Related for C
    let g1 = try! cardRepo.createCard(kind: .scenes, name: "Docks", subtitle: "Foggy morning", detailedText: longText)
    g1.sizeCategory = .standard
    let g2 = try! cardRepo.createCard(kind: .vehicles, name: "Hauler", subtitle: "Freight", detailedText: longText)
    g2.sizeCategory = .compact
    let g3 = try! cardRepo.createCard(kind: .characters, name: "Rhea", subtitle: "Mechanic", detailedText: longText)
    g3.sizeCategory = .large
    let g4 = try! cardRepo.createCard(kind: .worlds, name: "Nox", subtitle: "Nightside colony", detailedText: longText)
    g4.sizeCategory = .standard
    try? edgeRepo.createRelationship(from: g1, to: masterC, relationType: relType, sortIndex: 1)
    try? edgeRepo.createRelationship(from: g2, to: masterC, relationType: relType, sortIndex: 2)
    try? edgeRepo.createRelationship(from: g3, to: masterC, relationType: relType, sortIndex: 3)
    try? edgeRepo.createRelationship(from: g4, to: masterC, relationType: relType, sortIndex: 4)
    try? ctx.save()

    let lanes: [SwimlaneViewer.LaneDescriptor] = [
        .init(master: masterA, direction: .topToBottom, showsHeader: true),
        .init(master: masterB, direction: .bottomToTop, showsHeader: true),
        .init(master: masterC, direction: .topToBottom, showsHeader: true)
    ]

    return SwimlaneViewer(laneDescriptors: lanes, relationTypeFilter: nil, laneWidth: 420, laneSpacing: 16, contentPadding: 16, showsIndicators: true)
        .modelContainer(container)
        .serviceContainer(services)
        .frame(height: 520)
        .padding()
        .preferredColorScheme(.dark)
}
