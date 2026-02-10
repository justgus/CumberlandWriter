//
//  StructureBoardView.swift
//  Cumberland
//
//  Kanban-style structure board for a project card. Renders a "Backlog" lane
//  for unassigned scenes plus one lane per StoryStructure element. Supports
//  drag-and-drop assignment between lanes, zoom controls, and "Fit to Width"
//  layout. Uses StructureAssignmentManager for many-to-many element↔card bindings.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct StructureBoardView: View {
    let project: Card

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // App settings (for persisted zoom)
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]
    private var appSettings: AppSettings? { settingsResults.first }

    // Layout
    var laneWidth: CGFloat = 420
    var laneSpacing: CGFloat = 16
    var contentPadding: CGFloat = 16
    var showsIndicators: Bool = true

    // Zoom
    @State private var zoom: CGFloat = 1.0
    @State private var gestureStartZoom: CGFloat? = nil
    private let minZoom: CGFloat = 0.6
    private let maxZoom: CGFloat = 1.8
    private let zoomStep: CGFloat = 0.1

    // For “Fit to Width” calculation
    @State private var availableWidth: CGFloat = 0

    @State private var structure: StoryStructure?
    @State private var elements: [StructureElement] = []
    @State private var backlogScenes: [Card] = []

    var body: some View {
        ZStack {
            background

            if elements.isEmpty && backlogScenes.isEmpty {
                emptyState
            } else {
                GeometryReader { geo in
                    ScrollView(.horizontal, showsIndicators: showsIndicators) {
                        LazyHStack(alignment: .top, spacing: laneSpacing) {
                            // Leading Backlog lane
                            BacklogLane(
                                projectID: project.id,
                                scenes: backlogScenes,
                                laneWidth: laneWidth,
                                contentPadding: contentPadding,
                                onChanged: { Task { await reloadBacklog() } }
                            )
                            .frame(width: laneWidth)
                            .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.18), radius: 16, x: 0, y: 10)

                            // Structure element lanes
                            ForEach(elements, id: \.id) { element in
                                StructureLane(
                                    projectID: project.id,
                                    element: element,
                                    laneWidth: laneWidth,
                                    contentPadding: contentPadding,
                                    onChanged: { Task { await reloadBacklog() } }
                                )
                                .frame(width: laneWidth)
                                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.18), radius: 16, x: 0, y: 10)
                            }
                        }
                        .padding(.horizontal, contentPadding)
                        .padding(.top, 28)
                        .padding(.bottom, 8)
                        // Expand pre-scale height so that after scaling, the effective height matches the viewport.
                        // This allows more scenes to be visible vertically when zooming out.
                        .frame(height: geo.size.height / max(zoom, 0.0001), alignment: .top)
                        .scaleEffect(zoom, anchor: .topLeading)
                        .contentShape(Rectangle())
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    if gestureStartZoom == nil {
                                        gestureStartZoom = zoom
                                    }
                                    let proposed = (gestureStartZoom ?? zoom) * value
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        setZoomPersisted(proposed)
                                    }
                                }
                                .onEnded { _ in
                                    gestureStartZoom = nil
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.snappy) {
                                setZoomPersisted(1.0)
                            }
                        }
                    }
                    .onAppear {
                        availableWidth = geo.size.width
                    }
                    .onChange(of: geo.size) { _, newSize in
                        availableWidth = newSize.width
                    }
                }
            }
        }
        .task(id: project.id) {
            await loadStructure()
            await reloadBacklog()
        }
        .onAppear {
            // Initialize zoom from persisted settings, clamped
            let persisted = appSettings?.structureBoardZoom ?? 1.0
            zoom = CGFloat(persisted).clamped(to: minZoom...maxZoom)
        }
        // Keep local zoom in sync if Settings pane changes it while the board is open
        .onChange(of: appSettings?.structureBoardZoom ?? 1.0) { _, newValue in
            let clamped = CGFloat(newValue).clamped(to: minZoom...maxZoom)
            if abs(clamped - zoom) > 0.0001 {
                withAnimation(.snappy) {
                    zoom = clamped
                }
            }
        }
        .navigationTitle("Structure Board")
        .toolbar {
            ToolbarItemGroup(placement: .status) {
                if let structure {
                    Label(structure.name, systemImage: "list.number")
                        .foregroundStyle(.secondary)
                } else {
                    Text("No structure")
                        .foregroundStyle(.secondary)
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Button {
                    stepZoom(-zoomStep)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out")
                .keyboardShortcut("-", modifiers: [.command])

                Slider(value: Binding(
                    get: { zoom },
                    set: { setZoomPersisted($0) }
                ), in: minZoom...maxZoom)
                .frame(width: 140)
                .help("Zoom")

                Button {
                    stepZoom(+zoomStep)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In")
                .keyboardShortcut("=", modifiers: [.command])

                Button {
                    withAnimation(.snappy) { setZoomPersisted(1.0) }
                } label: {
                    // Reflect the current zoom in the button label (acts as reset to 100%)
                    Text("\(Int(round(zoom * 100)))%")
                }
                .help("Actual Size")
                .keyboardShortcut("0", modifiers: [.command])

                Button {
                    fitAllLanesToWidth()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help("Fit to Width")
            }
        }
    }

    private func stepZoom(_ delta: CGFloat) {
        withAnimation(.snappy) {
            setZoomPersisted(zoom + delta)
        }
    }

    private func fitAllLanesToWidth() {
        let laneCount = 1 + elements.count // backlog + structure lanes
        guard laneCount > 0, availableWidth > 0 else { return }

        // Base content width before scaling:
        // Horizontal padding on both sides + widths of lanes + spacings between lanes
        let baseContentWidth = (contentPadding * 2)
            + (CGFloat(laneCount) * laneWidth)
            + (CGFloat(max(0, laneCount - 1)) * laneSpacing)

        let proposed = (availableWidth / max(1, baseContentWidth)).clamped(to: minZoom...maxZoom)
        withAnimation(.snappy) {
            setZoomPersisted(proposed)
        }
    }

    // Persist to AppSettings whenever zoom changes
    private func setZoomPersisted(_ value: CGFloat) {
        let clamped = value.clamped(to: minZoom...maxZoom)
        zoom = clamped
        if let s = appSettings {
            let newVal = Double(clamped)
            if abs(s.structureBoardZoom - newVal) > 0.0001 {
                s.structureBoardZoom = newVal
                try? modelContext.save()
            }
        }
    }

    private var background: some View {
        let baseTop = Color.black.opacity(scheme == .dark ? 0.45 : 0.06)
        let baseBottom = Color.black.opacity(scheme == .dark ? 0.65 : 0.10)
        return LinearGradient(
            colors: [baseTop, baseBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(scheme == .dark ? 0.35 : 0.25)
                .ignoresSafeArea()
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.number")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No structure for this project")
                .font(.headline)
            Text("Create or attach a story structure from the Project’s editor (flip to Project Options).")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding()
    }

    @MainActor
    private func loadStructure() async {
        let projectIDOpt: UUID? = project.id
        let fetch = FetchDescriptor<StoryStructure>(
            predicate: #Predicate { $0.projectID == projectIDOpt },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let found = (try? modelContext.fetch(fetch)) ?? []
        structure = found.first
        let ordered = (structure?.elements ?? [])?.sorted(by: { $0.orderIndex < $1.orderIndex }) ?? []
        elements = ordered
    }

    // MARK: - Backlog loading

    @MainActor
    private func reloadBacklog() async {
        backlogScenes = await computeBacklogScenes()
    }

    // Use direct Scene→Project "stories" edges to determine which scenes belong to this project,
    // then filter out the ones already assigned to this project's structure elements.
    @MainActor
    private func computeBacklogScenes() async -> [Card] {
        // 1) Fetch the "stories" relation type (Scenes → Projects)
        guard let storiesType = try? modelContext.fetch(
            FetchDescriptor<RelationType>(predicate: #Predicate { $0.code == "stories/is-storied-by" })
        ).first else {
            return []
        }

        // 2) Fetch Scene → this Project edges of that type
        let projectIDOpt: UUID? = project.id
        let storiesTypeCodeOpt: String? = storiesType.code
        let edgesFetch = FetchDescriptor<CardEdge>(
            predicate: #Predicate {
                $0.to?.id == projectIDOpt && $0.type?.code == storiesTypeCodeOpt
            }
        )
        let edges = (try? modelContext.fetch(edgesFetch)) ?? []
        let scenesInProject = edges.compactMap { $0.from }.filter { $0.kind == .scenes }

        // 3) Filter to those not assigned to this project's structure elements
        let backlog = scenesInProject.filter { scene in
            let assigned = scene.structureElements ?? []
            return !assigned.contains(where: { $0.storyStructure?.projectID == project.id })
        }

        // 4) Sort for stable presentation
        return backlog.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Backlog Lane

private struct BacklogLane: View {
    let projectID: UUID?
    let scenes: [Card]
    var laneWidth: CGFloat
    var contentPadding: CGFloat
    var onChanged: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    private let laneCornerRadius: CGFloat = 20
    private let dropZoneHeight: CGFloat = 56

    @State private var headerIsTargeted = false
    @State private var listIsTargeted = false
    @State private var bottomIsTargeted = false

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: Kinds.scenes.systemImage)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        Kinds.scenes.accentColor(for: scheme).opacity(0.95),
                        .white.opacity(scheme == .dark ? 0.7 : 0.9)
                    )
                    .font(.caption2)
                Text("Backlog")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Unassigned Scenes")
                .font(.title3).bold()
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 0.5, x: 0, y: 0.5)
            Text("Scenes in this project not yet placed in the structure.")
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Kinds.scenes.accentColor(for: scheme).opacity(headerIsTargeted ? 0.8 : 0.0), lineWidth: 2)
        )
        .dropDestination(for: String.self,
                         action: { items, _ in
                             return handleDropToBacklog(items)
                         },
                         isTargeted: { isTargeted in
                             headerIsTargeted = isTargeted
                         })
    }

    private var laneBackground: some View {
        RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.20 : 0.35), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .background(
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.18), radius: 18, x: 0, y: 10)
            )
    }

    private var insetPanelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.12 : 0.28), lineWidth: 1)
                    .blendMode(.overlay)
                    .opacity(0.9)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.28 : 0.10), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.quaternary.opacity(0.6), lineWidth: 0.5)
            )
    }

    private var hairline: some View {
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
            laneBackground

            VStack(spacing: 0) {
                header
                    .padding([.top, .horizontal], contentPadding)
                    .padding(.bottom, 8)

                hairline

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(scenes, id: \.id) { card in
                            CardView(card: card)
                                .onDrag {
                                    NSItemProvider(object: card.id.uuidString as NSString)
                                }
                                .contextMenu {
                                    Button {
                                        // No-op: it’s already unassigned
                                    } label: {
                                        Label("Unassigned", systemImage: "tray")
                                    }
                                    .disabled(true)
                                }
                        }
                    }
                    .padding(.top, 16)
                    .padding([.horizontal, .bottom], contentPadding)
                    .background(insetPanelBackground)
                    .dropDestination(for: String.self,
                                     action: { items, _ in
                                         return handleDropToBacklog(items)
                                     },
                                     isTargeted: { isTargeted in
                                         listIsTargeted = isTargeted
                                     })
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Kinds.scenes.accentColor(for: scheme).opacity(listIsTargeted ? 0.5 : 0.0), lineWidth: 2)
                    )
                }
                // Ensure the list expands to fill the lane’s available vertical space
                .frame(maxHeight: .infinity, alignment: .top)

                hairline

                GlassDropZone(
                    height: dropZoneHeight,
                    cornerRadius: laneCornerRadius,
                    isTargeted: bottomIsTargeted,
                    contentPadding: contentPadding,
                    label: "Drop to unassign"
                )
                .dropDestination(for: String.self,
                                 action: { items, _ in
                                     return handleDropToBacklog(items)
                                 },
                                 isTargeted: { hovering in
                                     bottomIsTargeted = hovering
                                 })
                .padding(.horizontal, 0)
                .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous))
        }
        .padding(8)
    }

    @MainActor
    private func handleDropToBacklog(_ items: [String]) -> Bool {
        guard let idString = items.first, let uuid = UUID(uuidString: idString) else { return false }
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == uuid })
        guard let dropped = try? modelContext.fetch(descriptor).first else { return false }
        guard dropped.kind == .scenes else { return false }
        // Unassign the scene from any StructureElement that belongs to this project's structure
        let priorCount = dropped.structureElements?.count ?? 0
        dropped.structureElements?.removeAll(where: { $0.storyStructure?.projectID == projectID })

        // Clean inverse side across all elements referencing this project
        let fetchElems = FetchDescriptor<StructureElement>()
        if let allElems = try? modelContext.fetch(fetchElems) {
            for el in allElems {
                if el.storyStructure?.projectID == projectID {
                    el.assignedCards?.removeAll(where: { $0.id == dropped.id })
                }
            }
        }

        if priorCount != (dropped.structureElements?.count ?? 0) {
            try? modelContext.save()
            onChanged()
        }
        return true
    }
}

// MARK: - Structure Lanes

// PreferenceKey to collect item frames (in lane coordinate space) by Card ID
private struct ItemFramesKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct StructureLane: View {
    let projectID: UUID?
    let element: StructureElement
    var laneWidth: CGFloat
    var contentPadding: CGFloat
    var onChanged: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    private let laneCornerRadius: CGFloat = 20
    private let dropZoneHeight: CGFloat = 56

    // Local ordered scenes reflecting the element.assignedCards order
    @State private var orderedScenes: [Card] = []
    // Live frames of each card in lane coords
    @State private var itemFrames: [UUID: CGRect] = [:]
    // Drag hover state
    @State private var isTargeted: Bool = false
    @State private var draggingCardID: UUID? = nil
    @State private var hoverIndex: Int? = nil

    private var laneCoordSpace: String { "lane-\(element.id.uuidString)" }

    var body: some View {
        ZStack {
            laneBackground
                .overlay(
                    RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                        .stroke(element.displayColor.opacity(isTargeted ? 0.6 : 0.0), lineWidth: 2)
                        .animation(.easeInOut(duration: 0.12), value: isTargeted)
                )

            VStack(spacing: 0) {
                header
                    .padding([.top, .horizontal], contentPadding)
                    .padding(.bottom, 8)

                hairline
                scrollArea
                hairline

                bottomDropZone
                    .padding(.horizontal, 0)
                    .padding(.bottom, 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous))
        }
        .padding(8)
        // Whole-lane reordering and insertion
        .onDrop(of: [UTType.text], delegate: LaneDropDelegate(
            projectID: projectID,
            element: element,
            orderedScenes: $orderedScenes,
            itemFrames: $itemFrames,
            isTargeted: $isTargeted,
            draggingCardID: $draggingCardID,
            hoverIndex: $hoverIndex,
            modelContext: modelContext,
            onChanged: onChanged
        ))
        .onAppear {
            syncFromModel()
        }
        .onChange(of: element.assignedCards ?? []) { _, _ in
            // Keep local order in sync with model updates
            syncFromModel()
        }
    }

    private func syncFromModel() {
        // Respect the existing array order; do not sort by name
        orderedScenes = (element.assignedCards ?? []).filter { $0.kind == .scenes }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: Kinds.structure.systemImage)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        element.displayColor.opacity(0.95),
                        .white.opacity(scheme == .dark ? 0.7 : 0.9)
                    )
                    .font(.caption2)
                Text("Structure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(element.name.isEmpty ? "Untitled Element" : element.name)
                .font(.title3).bold()
                .foregroundStyle(.primary)
                .shadow(color: .black.opacity(scheme == .dark ? 0.35 : 0.08), radius: 0.5, x: 0, y: 0.5)

            if !element.elementDescription.isEmpty {
                Text(element.elementDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var scrollArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(orderedScenes, id: \.id) { card in
                    CardView(card: card)
                        .onDrag {
                            draggingCardID = card.id
                            return NSItemProvider(object: card.id.uuidString as NSString)
                        }
                        .background(GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ItemFramesKey.self,
                                    value: [card.id: geo.frame(in: .named(laneCoordSpace))]
                                )
                        })
                        .contextMenu {
                            Button(role: .destructive) {
                                unassign(card)
                            } label: {
                                Label("Remove from \(element.name)", systemImage: "tray.and.arrow.up")
                            }
                        }
                }
            }
            .padding(.top, 16)
            .padding([.horizontal, .bottom], contentPadding)
            .background(insetPanelBackground)
        }
        // Ensure the list expands to fill the lane’s available vertical space
        .frame(maxHeight: .infinity, alignment: .top)
        .coordinateSpace(name: laneCoordSpace)
        .onPreferenceChange(ItemFramesKey.self) { value in
            itemFrames = value
        }
        .animation(.snappy, value: orderedScenes.map(\.id))
    }

    private var bottomDropZone: some View {
        GlassDropZone(
            height: dropZoneHeight,
            cornerRadius: laneCornerRadius,
            isTargeted: isTargeted, // share the same highlight
            contentPadding: contentPadding,
            label: "Drop Scene to add"
        )
    }

    private var laneBackground: some View {
        RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.20 : 0.35), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .background(
                RoundedRectangle(cornerRadius: laneCornerRadius, style: .continuous)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.18), radius: 18, x: 0, y: 10)
            )
    }

    private var insetPanelBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(scheme == .dark ? 0.12 : 0.28), lineWidth: 1)
                    .blendMode(.overlay)
                    .opacity(0.9)
            )
            .shadow(color: .black.opacity(scheme == .dark ? 0.28 : 0.10), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.quaternary.opacity(0.6), lineWidth: 0.5)
            )
    }

    private var hairline: some View {
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

    @MainActor
    private func unassign(_ scene: Card) {
        // Remove this element from the scene’s assignments
        scene.structureElements?.removeAll { $0.id == element.id }
        // Remove the scene from the element’s assignedCards
        element.assignedCards?.removeAll { $0.id == scene.id }
        // Update local order
        orderedScenes.removeAll { $0.id == scene.id }
        try? modelContext.save()
        onChanged()
    }
}

// MARK: - Lane DropDelegate

private struct LaneDropDelegate: DropDelegate {
    let projectID: UUID?
    let element: StructureElement

    @Binding var orderedScenes: [Card]
    @Binding var itemFrames: [UUID: CGRect]
    @Binding var isTargeted: Bool
    @Binding var draggingCardID: UUID?
    @Binding var hoverIndex: Int?

    let modelContext: ModelContext
    let onChanged: () -> Void

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }

    func dropEntered(info: DropInfo) {
        withAnimation(.snappy) {
            isTargeted = true
        }
        updateHover(info: info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateHover(info: info)
        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        // Do not block the main thread. Read provider asynchronously and return true to accept.
        guard let provider = info.itemProviders(for: [UTType.text]).first else {
            resetDragState()
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let str: String?
            if let data = item as? Data, let s = String(data: data, encoding: .utf8) {
                str = s
            } else if let s = item as? String {
                str = s
            } else {
                str = nil
            }
            guard let idString = str, let uuid = UUID(uuidString: idString) else {
                Task { @MainActor in resetDragState() }
                return
            }

            Task { @MainActor in
                _ = handleDrop(uuid: uuid, at: currentHoverIndex())
                resetDragState()
            }
        }

        return true
    }

    func dropExited(info: DropInfo) {
        withAnimation(.snappy) {
            isTargeted = false
        }
        draggingCardID = nil
        hoverIndex = nil
    }

    // MARK: - Hover computations

    private func updateHover(info: DropInfo) {
        let idx = computeInsertionIndex(from: info)
        hoverIndex = idx
        guard let draggingID = extractDraggingID(from: info) ?? draggingCardID else { return }
        withAnimation(.snappy) {
            makeRoom(for: draggingID, at: idx)
        }
    }

    private func currentHoverIndex() -> Int {
        hoverIndex ?? orderedScenes.count
    }

    private func computeInsertionIndex(from info: DropInfo) -> Int {
        guard !orderedScenes.isEmpty else { return 0 }
        // Use the vertical position to find the nearest slot
        let y = info.location.y
        // Sort frames by minY (top to bottom)
        let pairs = orderedScenes.compactMap { card -> (UUID, CGRect)? in
            guard let rect = itemFrames[card.id] else { return nil }
            return (card.id, rect)
        }
        .sorted { $0.1.minY < $1.1.minY }

        for (i, pair) in pairs.enumerated() {
            let rect = pair.1
            let mid = rect.midY
            if y < mid {
                return i
            }
        }
        return pairs.count
    }

    private func makeRoom(for id: UUID, at index: Int) {
        // Build a temp array that shows the dragged item placed at index,
        // removing any existing occurrence to avoid duplicates
        var temp = orderedScenes
        if let existingIdx = temp.firstIndex(where: { $0.id == id }) {
            let card = temp.remove(at: existingIdx)
            let target = min(max(0, index), temp.count)
            temp.insert(card, at: target)
        } else {
            // Insert a lightweight placeholder by fetching the Card if available
            if let card = try? fetchCard(id: id) {
                let target = min(max(0, index), temp.count)
                temp.insert(card, at: target)
            }
        }
        orderedScenes = temp
    }

    // MARK: - Persistence

    @MainActor
    private func handleDrop(uuid: UUID, at index: Int) -> Bool {
        guard let dropped = try? fetchCard(id: uuid) else { return false }
        guard dropped.kind == .scenes else { return false }

        // Remove from any prior element in this project's structure (single-assignment semantics)
        if let priorElements = dropped.structureElements {
            for el in priorElements {
                if el.storyStructure?.projectID == projectID {
                    el.assignedCards?.removeAll { $0.id == dropped.id }
                }
            }
            // Remove all such elements from the scene side as well
            dropped.structureElements?.removeAll { $0.storyStructure?.projectID == projectID }
        }

        // Ensure this element has an array
        if element.assignedCards == nil { element.assignedCards = [] }

        // Remove if present already (intra-lane move)
        element.assignedCards?.removeAll { $0.id == dropped.id }

        // Clamp index and insert
        let clampedIndex = min(max(0, index), element.assignedCards?.count ?? 0)
        element.assignedCards?.insert(dropped, at: clampedIndex)

        // Keep the inverse up to date: scene points to exactly this element for this project
        if dropped.structureElements == nil { dropped.structureElements = [] }
        dropped.structureElements?.removeAll { $0.storyStructure?.projectID == projectID }
        dropped.structureElements?.append(element)

        // Sync local state to the persisted array order
        orderedScenes = (element.assignedCards ?? [])

        try? modelContext.save()
        onChanged()
        return true
    }

    private func fetchCard(id: UUID) throws -> Card {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        // First attempt: try the fetch and take the first result
        if let array = try? modelContext.fetch(descriptor), let card = array.first {
            return card
        }
        // If SwiftData faulting caused nil, do a second fetch without optional unwrap
        let all = try modelContext.fetch(descriptor)
        guard let found = all.first else {
            throw NSError(domain: "LaneDropDelegate", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card not found"])
        }
        return found
    }

    private func extractDraggingID(from info: DropInfo) -> UUID? {
        // Best-effort: if we already set draggingCardID via onDrag, prefer that.
        if let id = draggingCardID { return id }
        // Otherwise, we can't synchronously read the provider payload; return nil.
        return nil
    }

    @MainActor
    private func resetDragState() {
        withAnimation(.snappy) {
            isTargeted = false
        }
        draggingCardID = nil
        hoverIndex = nil
    }
}
