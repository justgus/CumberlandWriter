// TimelineChartView.swift
import SwiftUI
import SwiftData
import Charts
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct TimelineChartView: View {
    let timeline: Card // kind == .timelines

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Lane mode: which secondary lanes to show alongside "All"
    private enum LaneMode: String, CaseIterable, Identifiable {
        case characters
        case chapters

        var id: String { rawValue }
        var title: String {
            switch self {
            case .characters: return "Characters"
            case .chapters:   return "Chapters"
            }
        }
        var kind: Kinds {
            switch self {
            case .characters: return .characters
            case .chapters:   return .chapters
            }
        }
        var systemImage: String {
            switch self {
            case .characters: return Kinds.characters.systemImage
            case .chapters:   return Kinds.chapters.systemImage
            }
        }
    }

    // Data snapshot
    @State private var scenes: [SceneRow] = []

    // Characters dataset
    @State private var characters: [Card] = [] // Participants present in these scenes
    @State private var characterThumbnails: [UUID: Image] = [:]
    @State private var selectedCharacterIDs: Set<UUID> = []
    @State private var participationCharacters: [UUID: [UUID]] = [:] // character.id -> [scene.id]

    // Chapters dataset
    @State private var chapters: [Card] = []
    @State private var chapterThumbnails: [UUID: Image] = [:]
    @State private var selectedChapterIDs: Set<UUID> = []
    @State private var participationChapters: [UUID: [UUID]] = [:] // chapter.id -> [scene.id]

    // Which secondary lanes to render
    @State private var laneMode: LaneMode = .characters

    // X-axis zoom (ordinal domain)
    @State private var visibleStart: Int = 1
    @State private var visibleEnd: Int = 20

    // Visible window width (in "scene units") and scroll position
    @State private var visibleLength: Int = 20
    @State private var scrollX: Int? = nil

    // Plot area width for min-points-per-scene enforcement
    @State private var plotWidth: CGFloat = 0
    private let minPointsPerScene: CGFloat = 26 // tweak as needed (px per scene)

    // UI tuning
    @State private var barHeight: CGFloat = 0
    @State private var labelVisibility: Bool = true

    // Codes
    private let sceneTimelineCode = "describes/described-by"
    private let characterSceneCode = "appears-in/is-appeared-by"
    private let chapterSceneCode = "part-of/has-scene" // Scene -> Chapter (forward "part-of")

    // Reorder UI
    @State private var isPresentingReorder: Bool = false

    // Fixed header height (compact toolbar-like)
    #if os(iOS)
    private let headerHeight: CGFloat = 44
    #else
    private let headerHeight: CGFloat = 36
    #endif

    // Ensure initial scroll shows the names column
    @State private var didEnsureInitialNamesVisible: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            header

            if scenes.isEmpty {
                emptyState
            } else {
                chartArea
                    .layoutPriority(1) // keep chart prominent
            }
        }
        .padding()
        .task(id: timeline.id) {
            await loadData()
        }
        .navigationTitle(timeline.name.isEmpty ? "Timeline" : timeline.name)
        .sheet(isPresented: $isPresentingReorder) {
            ReorderScenesSheet(
                scenes: scenes.map { $0.scene },
                onDone: { newOrder in
                    Task { @MainActor in
                        await persistSceneOrder(newOrderIDs: newOrder.map(\.id))
                        await loadData()
                    }
                    isPresentingReorder = false
                },
                onCancel: {
                    isPresentingReorder = false
                }
            )
            #if os(iOS)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            #else
            .frame(minWidth: 420, minHeight: 420)
            #endif
        }
    }

    // MARK: - Header

    private var header: some View {
        // Horizontal scroll prevents vertical growth; fixed height keeps toolbar compact
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Label("Timeline", systemImage: Kinds.timelines.systemImage)
                    .font(.title3.bold())

                Spacer(minLength: 8)

                // Lane mode picker (Characters / Chapters)
                Picker("Lanes", selection: $laneMode) {
                    Label(LaneMode.characters.title, systemImage: LaneMode.characters.systemImage)
                        .tag(LaneMode.characters)
                    Label(LaneMode.chapters.title, systemImage: LaneMode.chapters.systemImage)
                        .tag(LaneMode.chapters)
                }
                .pickerStyle(.menu)
                .help("Choose which lanes to show")

                // Filter menu (adapts to lane mode)
                Menu {
                    Button {
                        clearSelectionForCurrentMode()
                    } label: {
                        Label("All \(laneMode.title)", systemImage: currentSelectionIsEmpty ? "checkmark" : laneMode.systemImage)
                    }

                    Divider()

                    ForEach(currentLaneCards, id: \.id) { card in
                        let isOn = currentSelectedIDs.contains(card.id)
                        Toggle(isOn: Binding(
                            get: { isOn },
                            set: { newValue in
                                updateSelection(for: card.id, isSelected: newValue)
                            }
                        )) {
                            Text(card.name.isEmpty ? "Untitled" : card.name)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: laneMode.systemImage)
                        Text(filterMenuTitle())
                            .lineLimit(1)
                    }
                }
                .help("Filter lanes by one or more \(laneMode.title.lowercased())")

                // Label toggle
                Toggle("Labels", isOn: $labelVisibility)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .help("Show scene names as labels")

                // Zoom controls
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .foregroundStyle(.secondary)
                    Button {
                        zoomOut()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    Button {
                        zoomIn()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    Button {
                        fitAll()
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }

                Divider().frame(height: 18)

                // Reorder scenes
                Button {
                    isPresentingReorder = true
                } label: {
                    Label("Reorder…", systemImage: "arrow.up.arrow.down")
                        .lineLimit(1)
                }
                .help("Drag to reorder scenes in this timeline")
                .disabled(scenes.count < 2)
            }
            .frame(height: headerHeight)
            .padding(.horizontal, 2)
        }
        .frame(height: headerHeight)
        .controlSize(.small) // slightly more compact controls to reduce header height
        .onChange(of: laneMode) { _, _ in
            // Clear selection when switching modes to avoid confusion
            clearSelectionForCurrentMode(resetAll: true)
        }
    }

    // Filter menu helpers
    private var currentLaneCards: [Card] {
        switch laneMode {
        case .characters: return characters
        case .chapters:   return chapters
        }
    }
    private var currentSelectedIDs: Set<UUID> {
        get {
            switch laneMode {
            case .characters: return selectedCharacterIDs
            case .chapters:   return selectedChapterIDs
            }
        }
        nonmutating set {
            switch laneMode {
            case .characters: selectedCharacterIDs = newValue
            case .chapters:   selectedChapterIDs = newValue
            }
        }
    }
    private var currentSelectionIsEmpty: Bool { currentSelectedIDs.isEmpty }

    private func updateSelection(for id: UUID, isSelected: Bool) {
        var s = currentSelectedIDs
        if isSelected { s.insert(id) } else { s.remove(id) }
        currentSelectedIDs = s
    }

    private func clearSelectionForCurrentMode(resetAll: Bool = false) {
        currentSelectedIDs = []
        if resetAll {
            // no-op besides clearing current mode selection
        }
    }

    private func filterMenuTitle() -> String {
        let selected = currentSelectedIDs
        let cards = currentLaneCards
        if selected.isEmpty {
            return "All \(laneMode.title)"
        } else if selected.count == 1, let id = selected.first, let name = cards.first(where: { $0.id == id })?.name {
            return name.isEmpty ? "1 Selected" : name
        } else {
            return "\(selected.count) Selected"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("No scenes in this timeline")
                .font(.headline)
            Text("Link scenes to this timeline using the “describes/described-by” relationship.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    // MARK: - Chart

    private var chartArea: some View {
        // Move heavy inference out of the Chart builder
        let lanes = effectiveLanes()

        // Lane keys: stable identifiers for Y domain
        let allKey = laneKeyAll()
        let itemKeys: [String] = lanes.items.map { laneKey(for: $0) }

        // Y categorical domain: keep "All" at top when shown, then item lanes
        let yDomainKeys: [String] = {
            var domain: [String] = []
            if lanes.all { domain.append(allKey) }
            domain.append(contentsOf: itemKeys)
            return domain
        }()

        // Display labels (for measuring label column width)
        let yDisplayLabels: [String] = {
            var labels: [String] = []
            if lanes.all { labels.append("All") }
            labels.append(contentsOf: lanes.items.map { $0.name.isEmpty ? "Untitled" : $0.name })
            return labels
        }()

        // Precompute orders and names per scene
        let sceneOrderByID: [UUID: Int] = scenes.reduce(into: [:]) { dict, row in
            dict[row.id] = row.order
        }

        // Precompute items for the "All" lane as 1-unit ranged bars [order, order+1)
        let allLaneItems: [AllLaneItem] = scenes.map { row in
            AllLaneItem(id: row.id, start: row.order, end: row.order + 1, sceneName: row.scene.name)
        }

        // Precompute items for secondary lanes as merged contiguous runs
        let laneRunItems: [LaneRunItem] = {
            var items: [LaneRunItem] = []
            items.reserveCapacity(scenes.count * max(1, lanes.items.count))

            // Choose the appropriate participation map based on lane kind
            let participationMap: [UUID: [UUID]] = (lanes.kind == .characters) ? participationCharacters : participationChapters

            for card in lanes.items {
                let displayName = card.name.isEmpty ? "Untitled" : card.name
                let key = laneKey(for: card)

                // Map participation scene IDs to orders and sort
                let orders: [Int] = (participationMap[card.id] ?? [])
                    .compactMap { sceneOrderByID[$0] }
                    .sorted()

                guard !orders.isEmpty else { continue }

                // Merge contiguous orders into runs
                var runStart = orders[0]
                var prev = orders[0]

                func appendRun(start: Int, endInclusive: Int) {
                    let id = LaneRunItem.makeID(entityID: card.id, start: start, endInclusive: endInclusive)
                    items.append(LaneRunItem(
                        id: id,
                        start: start,
                        end: endInclusive + 1, // ranged bars use end-exclusive
                        laneKey: key,
                        laneLabel: displayName,
                        runLabel: "\(start)–\(endInclusive)"
                    ))
                }

                for i in 1..<orders.count {
                    let ord = orders[i]
                    if ord == prev + 1 {
                        // still contiguous
                        prev = ord
                    } else {
                        // close previous run
                        appendRun(start: runStart, endInclusive: prev)
                        // start new
                        runStart = ord
                        prev = ord
                    }
                }
                // close last run
                appendRun(start: runStart, endInclusive: prev)
            }
            return items
        }()

        // Adjusted colors per scheme for better contrast
        let sceneColor = adjustedAccent(Kinds.scenes.accentColor(for: scheme))
        let entityKind: Kinds = lanes.kind
        let entityColor = adjustedAccent(entityKind.accentColor(for: scheme))
        let _ = scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.14)
        let _ = scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)

        // Full x-scale domain across all scenes for proper scrolling
        let fullStart: Int = scenes.map(\.order).min() ?? 1
        let fullEnd: Int = scenes.map(\.order).max() ?? 1
        let fullMid: Int = (fullStart + fullEnd) / 2
        let totalUnits: Int = max(1, fullEnd - fullStart + 1)

        // Compute label column width in pixels from longest lane label
        let labelFontSize: CGFloat = captionFontSize()
        let labelPadding: CGFloat = 10 // left + a bit of right
        let maxLabelWidthPx: CGFloat = maxLaneLabelWidth(in: yDisplayLabels, fontSize: labelFontSize) + labelPadding

        // First-pass points-per-scene based on current visibleLength without label column,
        // to convert label pixel width into "scene units".
        let maxUnitsByPixels: Int = max(1, Int(floor(plotWidth / max(minPointsPerScene, 1))))
        let firstPassVisibleUnits: Int = max(1, min(visibleLength, maxUnitsByPixels, totalUnits))
        let pointsPerScene: CGFloat = firstPassVisibleUnits > 0 ? (plotWidth / CGFloat(firstPassVisibleUnits)) : plotWidth

        // Convert label width (px) to scene units, at least 1
        let computedLabelUnits: Int = max(1, Int(ceil(maxLabelWidthPx / max(pointsPerScene, 1))))

        // Now compute the actual visible length, including the label column
        let effectiveVisibleLength: Int = max(1, min(visibleLength, maxUnitsByPixels, totalUnits + computedLabelUnits))

        return Chart {
            // Left label column background per lane
            ForEach(yDomainKeys, id: \.self) { laneKey in
                RectangleMark(
                    xStart: .value("Start", fullStart - computedLabelUnits),
                    xEnd: .value("End", fullStart),
                    y: .value("Lane", laneKey)
                )
                .foregroundStyle(
                    (scheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                )
                .cornerRadius(2)
                .annotation(position: .overlay, alignment: .leading) {
                    // Render the lane label inside the left column
                    HStack(spacing: 6) {
                        if laneKey == allKey {
                            Image(systemName: Kinds.scenes.systemImage)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text("All")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        } else if let card = entityForLaneKey(laneKey) {
                            Image(systemName: entityKind.systemImage)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)

                            if let thumb = thumbnailForEntity(card.id, kind: entityKind) {
                                thumb
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 14, height: 14)
                                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                                            .stroke(.quaternary, lineWidth: 0.6)
                                    )
                            }

                            Text(card.name.isEmpty ? "Untitled" : card.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 6)
                }
                .accessibilityHidden(true)
            }

            // Vertical separator between label column and first scene
            RuleMark(x: .value("Separator", fullStart))
                .foregroundStyle(.separator)
                .accessibilityHidden(true)

            // Actual bars
            makeChartMarks(
                allLaneItems: allLaneItems,
                laneRunItems: laneRunItems,
                allLaneKey: allKey,
                sceneColor: sceneColor,
                entityColor: entityColor,
                showLabels: labelVisibility
            )
        }
        // Hide default Y axis to avoid duplicate labels; we draw our own in the left column
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { value in
                AxisGridLine()
                AxisTick()
                if let intVal = value.as(Int.self), intVal >= fullStart {
                    AxisValueLabel("\(intVal)")
                } else {
                    AxisValueLabel("") // suppress label in the left label column
                }
            }
        }
        .chartLegend(.hidden)
        .chartScrollableAxes(.horizontal)
        // Bind scroll position so gestures don't snap back; default to data mid if not set yet
        .chartScrollPosition(x: Binding(
            get: { scrollX ?? fullMid },
            set: { scrollX = $0 }
        ))
        // Visible window width in "scene units", including the label column
        .chartXVisibleDomain(length: effectiveVisibleLength)
        // Scale over the full data range plus the label column on the left
        .chartXScale(domain: (fullStart - computedLabelUnits)...(fullEnd + 1))
        .chartYScale(domain: yDomainKeys)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        )
        // Capture the plot area width so we can enforce min points per scene
        .chartOverlay { _ in
            GeometryReader { geo in
                Color.clear
                    .onAppear { plotWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, new in
                        plotWidth = new
                    }
            }
        }
        // Tweak bar thickness via symbol size proxy
        .chartPlotStyle { plot in
            plot.frame(minHeight: CGFloat((effectiveLaneCount() * Int(barHeight * 3))).clamped(to: CGFloat(160)...CGFloat(2000)))
        }
        // Ensure the names column is visible on first appearance
        .onAppear {
            if !didEnsureInitialNamesVisible, plotWidth > 0 {
                let center = (fullStart - max(1, computedLabelUnits / 2))
                    .clamped(to: (fullStart - computedLabelUnits)...(fullEnd + 1))
                scrollX = center
                didEnsureInitialNamesVisible = true
            }
        }
        .onChange(of: plotWidth) { _, new in
            if !didEnsureInitialNamesVisible, new > 0 {
                let center = (fullStart - max(1, computedLabelUnits / 2))
                    .clamped(to: (fullStart - computedLabelUnits)...(fullEnd + 1))
                scrollX = center
                didEnsureInitialNamesVisible = true
            }
        }
    }

    @ChartContentBuilder
    private func makeChartMarks(
        allLaneItems: [AllLaneItem],
        laneRunItems: [LaneRunItem],
        allLaneKey: String,
        sceneColor: Color,
        entityColor: Color,
        showLabels: Bool
    ) -> some ChartContent {
        let _ = scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.14)
        let shadowColor = scheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)

        // All Scenes lane (1-unit ranged bars)
        ForEach(allLaneItems) { item in
            BarMark(
                xStart: .value("Start", item.start),
                xEnd: .value("End", item.end),
                y: .value("Lane", allLaneKey)
            )
            .foregroundStyle(sceneColor) // avoid extra opacity to keep color strong
            .cornerRadius(2)
            .shadow(color: shadowColor, radius: 1, x: 0, y: 1)
            .annotation(position: .overlay, alignment: .center) {
                if showLabels {
                    LabelOverlay(text: item.sceneName, fontSize: 9)
                }
            }
            .accessibilityLabel(item.sceneName)
            .accessibilityValue("All lane, position \(item.start)")
        }

        // Secondary lanes (merged contiguous runs as ranged bars)
        ForEach(laneRunItems) { item in
            BarMark(
                xStart: .value("Start", item.start),
                xEnd: .value("End", item.end),
                y: .value("Lane", item.laneKey)
            )
            .foregroundStyle(entityColor) // avoid extra opacity to keep color strong
            .cornerRadius(2)
            .shadow(color: shadowColor, radius: 1, x: 0, y: 1)
            // No annotation on secondary rows (per request)
            .accessibilityLabel("\(item.laneLabel) — scenes \(item.start) to \(item.end - 1)")
            .accessibilityValue("Lane, positions \(item.start) to \(item.end - 1)")
        }
    }

    // MARK: - Derived

    private struct SceneRow: Identifiable, Hashable {
        let id: UUID
        let scene: Card
        let order: Int
    }

    // Flattened chart data for type-checker friendliness
    private struct AllLaneItem: Identifiable {
        let id: UUID
        let start: Int
        let end: Int // end-exclusive
        let sceneName: String
    }

    private struct LaneRunItem: Identifiable {
        let id: String
        let start: Int
        let end: Int // end-exclusive
        let laneKey: String
        let laneLabel: String
        let runLabel: String

        static func makeID(entityID: UUID, start: Int, endInclusive: Int) -> String {
            entityID.uuidString + "-\(start)-\(endInclusive)"
        }
    }

    private func effectiveLanes() -> (all: Bool, items: [Card], kind: Kinds) {
        switch laneMode {
        case .characters:
            if !selectedCharacterIDs.isEmpty {
                let selected = characters.filter { selectedCharacterIDs.contains($0.id) }
                return (true, selected, .characters)
            }
            return (true, characters, .characters)
        case .chapters:
            if !selectedChapterIDs.isEmpty {
                let selected = chapters.filter { selectedChapterIDs.contains($0.id) }
                return (true, selected, .chapters)
            }
            return (true, chapters, .chapters)
        }
    }

    private func effectiveLaneCount() -> Int {
        let lanes = effectiveLanes()
        return (lanes.all ? 1 : 0) + lanes.items.count
    }

    // Returns the inclusive start/end scene orders and the number of scenes in the visible domain.
    private func xDomain() -> (start: Int, end: Int, length: Int) {
        guard let minOrder = scenes.map(\.order).min(),
              let maxOrder = scenes.map(\.order).max() else {
            return (1, 1, 1)
        }
        let start = max(minOrder, visibleStart)
        let end = min(maxOrder, max(visibleEnd, start + 4))
        return (start, end, max(1, end - start + 1))
    }

    private func shortLabel(for name: String) -> String {
        // Abbreviate longer scene names for secondary lanes
        if name.count <= 18 { return name }
        let trimmed = name.prefix(16)
        return "\(trimmed)…"
    }

    // Lane key helpers
    private func laneKeyAll() -> String { "all" }
    private func laneKey(for entity: Card) -> String {
        switch entity.kind {
        case .characters: return "char-\(entity.id.uuidString)"
        case .chapters:   return "chap-\(entity.id.uuidString)"
        default:          return "ent-\(entity.id.uuidString)"
        }
    }
    private func entityForLaneKey(_ key: String) -> Card? {
        if key.hasPrefix("char-") {
            let idStr = String(key.dropFirst("char-".count))
            if let id = UUID(uuidString: idStr) {
                return characters.first(where: { $0.id == id })
            }
        } else if key.hasPrefix("chap-") {
            let idStr = String(key.dropFirst("chap-".count))
            if let id = UUID(uuidString: idStr) {
                return chapters.first(where: { $0.id == id })
            }
        } else if key.hasPrefix("ent-") {
            let idStr = String(key.dropFirst("ent-".count))
            if let id = UUID(uuidString: idStr) {
                return (characters + chapters).first(where: { $0.id == id })
            }
        }
        return nil
    }

    private func thumbnailForEntity(_ id: UUID, kind: Kinds) -> Image? {
        switch kind {
        case .characters: return characterThumbnails[id]
        case .chapters:   return chapterThumbnails[id]
        default:          return nil
        }
    }

    // MARK: - Zoom

    private func fitAll() {
        // Show all scenes at once (still scrollable if longer than view)
        visibleLength = max(1, scenes.count)
        // Center the scroll on the data
        if let minOrder = scenes.map(\.order).min(),
           let maxOrder = scenes.map(\.order).max() {
            scrollX = (minOrder + maxOrder) / 2
        }
        // Keep legacy fields synced (optional)
        visibleStart = 1
        visibleEnd = max(visibleLength, 1)
    }

    private func zoomIn() {
        // Halve visible window, with a floor
        visibleLength = max(5, visibleLength / 2)
        // Keep scroll position unchanged so user stays where they are
    }

    private func zoomOut() {
        // Double visible window, bounded by total scenes (+ a little headroom)
        let maxLen = max(10, scenes.count + 2)
        visibleLength = min(maxLen, max(10, visibleLength * 2))
    }

    // MARK: - Data loading

    @MainActor
    private func loadData() async {
        // 1) Fetch Scene → Timeline edges (forward direction) regardless of specific type code.
        let tlIDOpt: UUID? = timeline.id
        let sceneEdgesFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.to?.id == tlIDOpt
            },
            sortBy: [
                SortDescriptor(\.sortIndex, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        let edges = (try? modelContext.fetch(sceneEdgesFetch)) ?? []

        // 2) Build ordered scene rows (ordinal index 1...N based on edge order)
        var rows: [SceneRow] = []
        rows.reserveCapacity(edges.count)
        var idx = 1
        for e in edges {
            if let s = e.from, s.kind == .scenes {
                rows.append(SceneRow(id: s.id, scene: s, order: idx))
                idx += 1
            }
        }
        scenes = rows

        // 3) Fetch Characters → Scene participation edges; filter to our scenes
        guard !rows.isEmpty else {
            characters = []
            chapters = []
            participationCharacters = [:]
            participationChapters = [:]
            characterThumbnails = [:]
            chapterThumbnails = [:]
            // Reset scroll/zoom defaults
            visibleLength = 20
            scrollX = nil
            didEnsureInitialNamesVisible = false
            return
        }

        // Characters
        let charCodeOpt: String? = characterSceneCode
        let charSceneFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.type?.code == charCodeOpt
            }
        )
        let allCharEdges = (try? modelContext.fetch(charSceneFetch)) ?? []

        let sceneIDs = Set(rows.map(\.id))
        var charToScenes: [UUID: [UUID]] = [:]
        var charCards: [UUID: Card] = [:]

        for e in allCharEdges {
            guard let ch = e.from, ch.kind == .characters,
                  let sc = e.to, sc.kind == .scenes,
                  sceneIDs.contains(sc.id) else { continue }
            charToScenes[ch.id, default: []].append(sc.id)
            if charCards[ch.id] == nil {
                charCards[ch.id] = ch
            }
        }

        let chars = charCards.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        characters = chars
        participationCharacters = charToScenes

        // Chapters (Scene -> Chapter using "part-of/has-scene")
        let chapCodeOpt: String? = chapterSceneCode
        let chapSceneFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.type?.code == chapCodeOpt
            }
        )
        let allChapEdges = (try? modelContext.fetch(chapSceneFetch)) ?? []

        var chapToScenes: [UUID: [UUID]] = [:] // chapter.id -> [scene.id]
        var chapCards: [UUID: Card] = [:]

        for e in allChapEdges {
            guard let sc = e.from, sc.kind == .scenes,
                  let ch = e.to, ch.kind == .chapters,
                  sceneIDs.contains(sc.id) else { continue }
            chapToScenes[ch.id, default: []].append(sc.id)
            if chapCards[ch.id] == nil {
                chapCards[ch.id] = ch
            }
        }

        let chaps = chapCards.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        chapters = chaps
        participationChapters = chapToScenes

        // Preload small thumbnails (best-effort) for currently available entities
        Task { @MainActor in
            // Characters
            for ch in chars {
                if self.characterThumbnails[ch.id] != nil { continue }
                if let img = await ch.makeThumbnailImage() {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        self.characterThumbnails[ch.id] = img
                    }
                }
            }
            // Chapters
            for chap in chaps {
                if self.chapterThumbnails[chap.id] != nil { continue }
                if let img = await chap.makeThumbnailImage() {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        self.chapterThumbnails[chap.id] = img
                    }
                }
            }
        }

        // 4) Initialize visible window and scroll position
        let minOrder = scenes.map(\.order).min() ?? 1
        let maxOrder = scenes.map(\.order).max() ?? 1
        visibleLength = min(20, maxOrder - minOrder + 1)
        scrollX = (minOrder + maxOrder) / 2

        // Keep legacy fields synced (optional)
        visibleStart = minOrder
        visibleEnd = maxOrder

        // Allow initial adjustment to show names column once plot width is known
        didEnsureInitialNamesVisible = false
    }

    // Persist a new ordering by updating CardEdge.sortIndex for Scene→Timeline edges.
    @MainActor
    private func persistSceneOrder(newOrderIDs: [UUID]) async {
        guard !newOrderIDs.isEmpty else { return }
        let tlIDOpt: UUID? = timeline.id
        let scenesKindRaw: String = Kinds.scenes.rawValue
        // Fetch all Scene→Timeline edges for this timeline (any type), keyed by scene ID
        let fetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate { $0.to?.id == tlIDOpt && $0.from?.kindRaw == scenesKindRaw }
        )
        let edges = (try? modelContext.fetch(fetch)) ?? []

        // Map: sceneID -> edge
        var byScene: [UUID: CardEdge] = [:]
        for e in edges {
            if let sid = e.from?.id {
                byScene[sid] = e
            }
        }

        // Apply new 1-based sortIndex in the order received
        var idx = 1.0
        var touched = false
        for sid in newOrderIDs {
            if let edge = byScene[sid] {
                if edge.sortIndex != idx {
                    edge.sortIndex = idx
                    touched = true
                }
                idx += 1
            }
        }

        if touched {
            try? modelContext.save()
        }
    }

    // Adjust color for better contrast by scheme, returning a Color (not a View)
    private func adjustedAccent(_ color: Color) -> Color {
        #if canImport(UIKit)
        let ui = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if scheme == .dark {
                s = min(1.0, s * 1.2)
                b = min(1.0, b + 0.15)
            } else {
                b = max(0.0, b - 0.06)
            }
            return Color(hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: Double(a))
        }
        return color
        #elseif canImport(AppKit)
        let ns = NSColor(color)
        let rgb = ns.usingColorSpace(.deviceRGB) ?? ns
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        rgb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        if scheme == .dark {
            s = min(1.0, s * 1.2)
            b = min(1.0, b + 0.15)
        } else {
            b = max(0.0, b - 0.06)
        }
        return Color(hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: Double(a))
        #else
        return color
        #endif
    }

    // MARK: - Text measurement helpers

    private func captionFontSize() -> CGFloat {
        #if canImport(UIKit)
        return UIFont.preferredFont(forTextStyle: .caption1).pointSize
        #elseif canImport(AppKit)
        // Approximate caption size on macOS
        return NSFont.systemFontSize(for: .small)
        #else
        return 12
        #endif
    }

    private func maxLaneLabelWidth(in labels: [String], fontSize: CGFloat) -> CGFloat {
        var maxW: CGFloat = 0
        for s in labels {
            maxW = max(maxW, textWidth(s, fontSize: fontSize))
        }
        return maxW
    }

    private func textWidth(_ text: String, fontSize: CGFloat) -> CGFloat {
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attrs).width
        #elseif canImport(AppKit)
        let font = NSFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attrs).width
        #else
        return CGFloat(text.count) * 7 // rough fallback
        #endif
    }
}

// MARK: - Small helper views

private struct LabelOverlay: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

// MARK: - Reorder sheet

private struct ReorderScenesSheet: View {
    let scenes: [Card] // kind == .scenes
    var onDone: ([Card]) -> Void
    var onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var working: [Card]

    init(scenes: [Card], onDone: @escaping ([Card]) -> Void, onCancel: @escaping () -> Void) {
        self.scenes = scenes
        self.onDone = onDone
        self.onCancel = onCancel
        self._working = State(initialValue: scenes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reorder Scenes")
                .font(.title3.bold())

            if working.isEmpty {
                Text("No scenes to reorder.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List {
                    ForEach(working, id: \.id) { scene in
                        HStack(spacing: 8) {
                            Image(systemName: Kinds.scenes.systemImage)
                                .foregroundStyle(.secondary)
                            Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .onMove { indices, newOffset in
                        working.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                #if canImport(UIKit)
                .environment(\.editMode, .constant(.active)) // enable drag handles on iOS
                #endif
            }

            Spacer(minLength: 0)

            HStack {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    onDone(working)
                    dismiss()
                } label: {
                    Label("Save Order", systemImage: "checkmark.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(working == scenes)
            }
        }
        .padding()
        .frame(minWidth: 420, minHeight: 420, alignment: .topLeading)
    }
}

#Preview {
    // In-memory preview with a small synthetic dataset
    let schema = Schema([Card.self, RelationType.self, CardEdge.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let ctx = container.mainContext

    // Seed types
    let sceneTimeline = RelationType(code: "describes/described-by", forwardLabel: "describes", inverseLabel: "described by", sourceKind: .scenes, targetKind: .timelines)
    let appearsIn = RelationType(code: "appears-in/is-appeared-by", forwardLabel: "appears in", inverseLabel: "is appeared by", sourceKind: .characters, targetKind: .scenes)
    let partOf = RelationType(code: "part-of/has-scene", forwardLabel: "part of", inverseLabel: "has scene", sourceKind: .scenes, targetKind: .chapters)
    ctx.insert(sceneTimeline); ctx.insert(appearsIn); ctx.insert(partOf)

    // Timeline + scenes
    let tl = Card(kind: .timelines, name: "Arc A", subtitle: "", detailedText: "")
    let s1 = Card(kind: .scenes, name: "Opening", subtitle: "", detailedText: "")
    let s2 = Card(kind: .scenes, name: "Market Chase", subtitle: "", detailedText: "")
    let s3 = Card(kind: .scenes, name: "Cliffhanger", subtitle: "", detailedText: "")
    ctx.insert(tl); ctx.insert(s1); ctx.insert(s2); ctx.insert(s3)

    // Order with sortIndex
    ctx.insert(CardEdge(from: s1, to: tl, type: sceneTimeline, sortIndex: 1))
    ctx.insert(CardEdge(from: s2, to: tl, type: sceneTimeline, sortIndex: 2))
    ctx.insert(CardEdge(from: s3, to: tl, type: sceneTimeline, sortIndex: 3))

    // Characters + participation
    let c1 = Card(kind: .characters, name: "Mira", subtitle: "", detailedText: "")
    let c2 = Card(kind: .characters, name: "Aiden", subtitle: "", detailedText: "")
    ctx.insert(c1); ctx.insert(c2)

    ctx.insert(CardEdge(from: c1, to: s1, type: appearsIn))
    ctx.insert(CardEdge(from: c1, to: s2, type: appearsIn))
    ctx.insert(CardEdge(from: c2, to: s2, type: appearsIn))
    ctx.insert(CardEdge(from: c2, to: s3, type: appearsIn))

    // Chapters + participation (Scene -> Chapter via "part-of/has-scene")
    let ch1 = Card(kind: .chapters, name: "Chapter 1", subtitle: "", detailedText: "")
    let ch2 = Card(kind: .chapters, name: "Chapter 2", subtitle: "", detailedText: "")
    ctx.insert(ch1); ctx.insert(ch2)

    // s1 part of ch1, s2 part of ch1, s3 part of ch2
    ctx.insert(CardEdge(from: s1, to: ch1, type: partOf))
    ctx.insert(CardEdge(from: s2, to: ch1, type: partOf))
    ctx.insert(CardEdge(from: s3, to: ch2, type: partOf))

    try? ctx.save()

    return TimelineChartView(timeline: tl)
        .modelContainer(container)
        .frame(minWidth: 820, minHeight: 520)
}
