//
//  AggregateTextView.swift
//  Cumberland
//
//  Assembles and displays all scene text belonging to a chapter card in reading
//  order by following timeline/chapter relationships. Provides a continuous
//  prose view for chapters and projects used in the "Aggregate" detail tab.
//

import SwiftUI
import SwiftData

struct AggregateTextView: View {
    let card: Card

    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext

    // Aggregated, ordered scenes and concatenated text
    @State private var orderedScenes: [Card] = []
    @State private var aggregatedText: String = ""
    @State private var isLoading: Bool = false

    // Relation type codes
    private let sceneTimelineCode = "describes/described-by"    // Scene -> Timeline
    private let sceneChapterCode = "part-of/has-scene"          // Scene -> Chapter (forward)
    private let chapterSceneInverseCode = "has-scene/part-of"   // Chapter -> Scene (inverse, if present)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                Divider()
                content
            }
            .padding()
        }
        .background(card.kind.backgroundColor(for: scheme).opacity(scheme == .dark ? 0.12 : 0.08))
        .task(id: card.id) {
            await loadAggregatedScenesAndText()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: card.kind.systemImage)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text(card.name.isEmpty ? card.kind.singularTitle : card.name)
                    .font(.title3.bold())
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator.opacity(0.5), lineWidth: 0.5)
        )
    }

    private var content: some View {
        Group {
            if isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading related scenes…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.8)
                )
            } else if aggregatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No related scene text to aggregate.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.8)
                )
            } else {
                Text(aggregatedText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.8)
                    )
            }
        }
    }

    // MARK: - Data loading

    @MainActor
    private func loadAggregatedScenesAndText() async {
        isLoading = true
        defer { isLoading = false }

        let scenes = await fetchRelatedScenes(for: card)
        let ordered = await orderScenes(scenes)
        orderedScenes = ordered

        // Concatenate detailedText from ordered scenes
        let pieces = ordered.map { $0.detailedText.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        aggregatedText = pieces.joined(separator: "\n\n")
    }

    // Fetch scenes related to the given card using the specified relationship types.
    // - Timelines: Scene -> Timeline edges with code "describes/described-by"
    // - Chapters:  prefer Chapter -> Scene edges with code "has-scene/part-of" if present,
    //              otherwise fallback to Scene -> Chapter edges with code "part-of/has-scene".
    private func fetchRelatedScenes(for card: Card) async -> [Card] {
        let myID: UUID = card.id
        let scenesKindRaw: String = Kinds.scenes.rawValue
        let _: String = Kinds.chapters.rawValue
        let _: String = Kinds.timelines.rawValue

        switch card.kind {
        case .timelines:
            // Scene -> Timeline for this timeline
            let fetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.type?.code == sceneTimelineCode &&
                    $0.to?.id == myID &&
                    $0.from?.kindRaw == scenesKindRaw
                },
                sortBy: [
                    SortDescriptor(\.sortIndex, order: .forward),
                    SortDescriptor(\.createdAt, order: .forward)
                ]
            )
            let edges = (try? modelContext.fetch(fetch)) ?? []
            return edges.compactMap { $0.from }.filter { $0.kind == .scenes }

        case .chapters:
            // Try inverse type first: Chapter -> Scene ("has-scene/part-of")
            let inverseFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.type?.code == chapterSceneInverseCode &&
                    $0.from?.id == myID &&
                    $0.to?.kindRaw == scenesKindRaw
                }
            )
            let inverseEdges = (try? modelContext.fetch(inverseFetch)) ?? []

            if !inverseEdges.isEmpty {
                return inverseEdges.compactMap { $0.to }.filter { $0.kind == .scenes }
            }

            // Fallback to forward type: Scene -> Chapter ("part-of/has-scene")
            let forwardFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.type?.code == sceneChapterCode &&
                    $0.to?.id == myID &&
                    $0.from?.kindRaw == scenesKindRaw
                }
            )
            let forwardEdges = (try? modelContext.fetch(forwardFetch)) ?? []
            return forwardEdges.compactMap { $0.from }.filter { $0.kind == .scenes }

        default:
            // For other kinds, we currently don't aggregate.
            return []
        }
    }

    // Order scenes:
    // - If the aggregate is a Timeline, scenes are already fetched sorted by sortIndex.
    // - If the aggregate is a Chapter, choose the Timeline that contains the most of the chapter's scenes
    //   (via Scene -> Timeline "describes/described-by"), then order by that Timeline's sortIndex.
    //   Any scenes not present on the chosen Timeline are appended afterward, sorted by name.
    private func orderScenes(_ scenes: [Card]) async -> [Card] {
        guard !scenes.isEmpty else { return [] }

        switch card.kind {
        case .timelines:
            // Already sorted during fetch by sortIndex
            return scenes

        case .chapters:
            let sceneIDs = scenes.map(\.id)
            let sceneIDSet = Set(sceneIDs)

            // Simplify the predicate to only match the relation type, then filter in memory.
            let fetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate {
                    $0.type?.code == sceneTimelineCode
                }
            )
            let allTypeEdges = (try? modelContext.fetch(fetch)) ?? []

            // Keep only edges where from is one of our Scenes and to is a Timeline
            let edges = allTypeEdges.compactMap { edge -> CardEdge? in
                guard
                    let sc = edge.from, sc.kind == .scenes,
                    sceneIDSet.contains(sc.id),
                    let tl = edge.to, tl.kind == .timelines
                else { return nil }
                return edge
            }

            // Group by timeline (to.id), count coverage and keep per-scene sortIndex
            struct TLGroup {
                var timeline: Card
                var coverageCount: Int
                var sceneIndex: [UUID: Double] // sceneID -> sortIndex
            }

            var byTimeline: [UUID: TLGroup] = [:]
            for e in edges {
                guard let tl = e.to, tl.kind == .timelines,
                      let sc = e.from, sc.kind == .scenes else { continue }
                if byTimeline[tl.id] == nil {
                    byTimeline[tl.id] = TLGroup(timeline: tl, coverageCount: 0, sceneIndex: [:])
                }
                // Only count a scene once toward coverage for a given timeline
                if byTimeline[tl.id]!.sceneIndex[sc.id] == nil {
                    byTimeline[tl.id]!.coverageCount += 1
                }
                byTimeline[tl.id]!.sceneIndex[sc.id] = e.sortIndex
            }

            // Pick the timeline with the highest coverage; tie-breaker by timeline name
            let chosen: TLGroup? = byTimeline.values.max { a, b in
                if a.coverageCount == b.coverageCount {
                    return (a.timeline.name.localizedCaseInsensitiveCompare(b.timeline.name) == .orderedDescending)
                }
                return a.coverageCount < b.coverageCount
            }

            guard let selected = chosen else {
                // No timelines found for these scenes; fallback to name
                return scenes.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }

            let indexMap = selected.sceneIndex

            // Partition scenes into those present on the chosen timeline and those not
            var onTimeline: [Card] = []
            var offTimeline: [Card] = []
            for s in scenes {
                if indexMap[s.id] != nil {
                    onTimeline.append(s)
                } else {
                    offTimeline.append(s)
                }
            }

            // Sort on-timeline scenes by sortIndex asc; stable tie-breaker by name
            onTimeline.sort { a, b in
                let ia = indexMap[a.id] ?? .greatestFiniteMagnitude
                let ib = indexMap[b.id] ?? .greatestFiniteMagnitude
                if ia == ib {
                    return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
                return ia < ib
            }

            // Sort off-timeline scenes by name
            offTimeline.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            return onTimeline + offTimeline

        default:
            return scenes
        }
    }
}

#Preview("AggregateTextView") {
    // Build an in-memory container and seed a small graph:
    // Chapter <-part-of- Scene, Scene -> Timeline (describes) with sortIndex ordering.
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let ctx = container.mainContext

    // Relation types
    let describes = RelationType(code: "describes/described-by", forwardLabel: "describes", inverseLabel: "described by", sourceKind: .scenes, targetKind: .timelines)
    let partOf = RelationType(code: "part-of/has-scene", forwardLabel: "part of", inverseLabel: "has scene", sourceKind: .scenes, targetKind: .chapters)
    // Optional: if you also store inverse edges explicitly, uncomment to test
    // let hasScene = RelationType(code: "has-scene/part-of", forwardLabel: "has scene", inverseLabel: "part of", sourceKind: .chapters, targetKind: .scenes)

    ctx.insert(describes); ctx.insert(partOf) // ; ctx.insert(hasScene)

    // Entities
    let timeline = Card(kind: .timelines, name: "Arc A", subtitle: "", detailedText: "")
    let chapter = Card(kind: .chapters, name: "Chapter 1", subtitle: "A Beginning", detailedText: "")
    let s1 = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "Opening scene text.")
    let s2 = Card(kind: .scenes, name: "Market Chase", subtitle: "", detailedText: "Chase scene text.")
    let s3 = Card(kind: .scenes, name: "Cliffhanger", subtitle: "", detailedText: "Cliffhanger scene text.")

    ctx.insert(timeline); ctx.insert(chapter); ctx.insert(s1); ctx.insert(s2); ctx.insert(s3)

    // Scene -> Timeline order
    ctx.insert(CardEdge(from: s1, to: timeline, type: describes, sortIndex: 1))
    ctx.insert(CardEdge(from: s2, to: timeline, type: describes, sortIndex: 2))
    ctx.insert(CardEdge(from: s3, to: timeline, type: describes, sortIndex: 3))

    // Scene -> Chapter membership (forward)
    ctx.insert(CardEdge(from: s1, to: chapter, type: partOf))
    ctx.insert(CardEdge(from: s2, to: chapter, type: partOf))
    // s3 not in this chapter

    try? ctx.save()

    return NavigationStack {
        AggregateTextView(card: chapter)
            .navigationTitle("Aggregate: \(chapter.name)")
    }
    .modelContainer(container)
}
