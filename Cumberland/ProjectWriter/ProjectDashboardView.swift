//
//  ProjectDashboardView.swift
//  Cumberland
//
//  Project-scale instrument panel for Cumberland Writer.
//  Shows project status, structure, issues, threads, and resumption points.
//
//  Design principles:
//  - Dense but readable information display
//  - Show state through geometry, continuity, weight, position
//  - Use text only where necessary (issue resolution, thread labels)
//  - Remain useful at early, mid, and late project stages
//
//  Key regions:
//  - Project header and structure band (upper center-left)
//  - Project status glyph (upper center-right) - three concentric rings
//  - Resume/return strip (lower center-left) - Last/Resume/Next
//  - Cast shelf (lower right, upper)
//  - Issues shelf (lower right, middle)
//  - Thread shelf (lower right, lower)
//

import SwiftUI
import SwiftData

struct ProjectDashboardView: View {
    let project: Card

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var dashboardModel: ProjectDashboardModel?
    @State private var dashboardService: ProjectDashboardService?
    @State private var showingStructureSelector = false
    @State private var thumbnailImage: Image?
    @State private var isEditingName = false
    @State private var nameDraft = ""
    @State private var showingCardEditor = false

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                // Upper region: Header, Structure Band, Status Glyph
                HStack(alignment: .top, spacing: 32) {
                    VStack(alignment: .leading, spacing: 16) {
                        projectHeader
                        structureBand
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    projectStatusGlyph
                        .frame(width: 280, height: 280)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal, 24)

                // Lower region: Resume strip and shelves
                HStack(alignment: .top, spacing: 32) {
                    VStack(alignment: .leading, spacing: 20) {
                        returnStrip
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 24) {
                        castShelf
                        issuesShelf
                        threadShelf
                    }
                    .frame(width: 320)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(themeManager.currentTheme.colors.surfacePrimary.platformResolved.asBackground())
        .sheet(isPresented: $showingStructureSelector) {
            StructureSelectionSheet(project: project)
                .onDisappear {
                    // Reload dashboard when structure changes
                    loadDashboardModel()
                }
        }
        .sheet(isPresented: $showingCardEditor) {
            CardEditorView(mode: .edit(card: project, onComplete: {
                //
            }))
                .onDisappear {
                    // Reload thumbnail after editing
                    Task {
                        thumbnailImage = await project.makeThumbnailImage()
                    }
                }
        }
        .onAppear {
            loadDashboardModel()
        }
    }

    // MARK: - Project Header

    private var projectHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    nameField

                    Button {
                        showingCardEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Edit Project Details")
                }

                if let model = dashboardModel {
                    HStack(spacing: 16) {
                        Label("\(model.statusGlyph.chapterRing.spans.count) chapters", systemImage: "book.closed")
                        Label("\(model.statusGlyph.sceneRing.spans.count) scenes", systemImage: "rectangle.stack")
                        Label("\(model.castShelf.characters.count) characters", systemImage: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                }

                HStack(spacing: 8) {
                    phaseBadge("Drafting")
                    if let model = dashboardModel, !model.issuesShelf.issues.isEmpty {
                        stateBadge("\(model.issuesShelf.issues.count) issue\(model.issuesShelf.issues.count == 1 ? "" : "s")")
                    }
                }
            }

            Spacer()

            projectThumbnail
        }
        .padding()
        .background(
            themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground()
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var nameField: some View {
        if isEditingName {
            TextField("Project Name", text: $nameDraft, onCommit: commitNameEdit)
                .textFieldStyle(.plain)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
        } else {
            Text(project.name.isEmpty ? "Untitled Project" : project.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                .contentShape(Rectangle())
                .onTapGesture {
                    nameDraft = project.name
                    isEditingName = true
                }
        }
    }

    private func commitNameEdit() {
        isEditingName = false
        if !nameDraft.isEmpty && nameDraft != project.name {
            project.name = nameDraft
        }
    }

    @ViewBuilder
    private var projectThumbnail: some View {
        Group {
            if let thumbnailImage {
                thumbnailImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.8)
                    )
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 120, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.regularMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.quaternary, lineWidth: 0.8)
                )
            }
        }
        .task(id: project.id) {
            thumbnailImage = await project.makeThumbnailImage()
        }
    }

    private func phaseBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(themeManager.currentTheme.colors.accentPrimary.opacity(0.2))
            )
    }

    private func stateBadge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground())
            )
    }

    // MARK: - Structure Band

    private var structureBand: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Story Structure")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

                Spacer()

                Button {
                    showingStructureSelector = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "text.book.closed")
                            .font(.caption)
                        Text("Change")
                            .font(.caption)
                    }
                    .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)
                }
                .buttonStyle(.plain)
            }

            if let model = dashboardModel {
                if model.structureBand.beats.isEmpty {
                    // No structure defined
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Baseline
                            Rectangle()
                                .fill(themeManager.currentTheme.colors.border)
                                .frame(height: 2)

                            Text("No structure defined")
                                .font(.caption2)
                                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .frame(height: 60)
                } else if let arc = model.structureBand.narrativeArc,
                          let arcSegmentData = model.structureBand.arcSegments {
                    // NEW: Tufte-style narrative arc visualization
                    narrativeArcView(
                        arc: arc,
                        arcSegmentData: arcSegmentData,
                        beats: model.structureBand.beats,
                        activePosition: model.structureBand.activePositionFraction
                    )
                } else {
                    // LEGACY: Horizontal contour showing structural beats and content density
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Baseline
                            Rectangle()
                                .fill(themeManager.currentTheme.colors.border)
                                .frame(height: 2)

                            // Contour segments (density visualization)
                            ForEach(Array(model.structureBand.contourSegments.enumerated()), id: \.offset) { _, segment in
                                contourSegmentView(segment: segment, width: geometry.size.width)
                            }

                            // Structure beats
                            ForEach(model.structureBand.beats, id: \.beatID) { beat in
                                structureBeatNodeView(
                                    beat: beat,
                                    width: geometry.size.width
                                )
                            }

                            // Active position marker
                            if model.structureBand.activePositionFraction > 0 {
                                activePositionMarker(
                                    position: model.structureBand.activePositionFraction,
                                    width: geometry.size.width
                                )
                            }
                        }
                    }
                    .frame(height: 60)
                }
            } else {
                ProgressView()
                    .frame(height: 60)
            }
        }
    }

    private func narrativeArcView(
        arc: NarrativeArc,
        arcSegmentData: [ArcSegmentData],
        beats: [StructureBeat],
        activePosition: Double
    ) -> some View {
        // Convert ArcSegmentData to ArcSegment (for NarrativeArcVisualization)
        let arcSegments = arcSegmentData.map { segmentData in
            ArcSegment(
                startPosition: segmentData.startPosition,
                endPosition: segmentData.endPosition,
                startTension: arc.tension(at: segmentData.startPosition),
                endTension: arc.tension(at: segmentData.endPosition),
                sceneCount: segmentData.sceneCount,
                beatLabel: segmentData.beatLabel,
                beatID: segmentData.beatID
            )
        }

        return VStack(spacing: 0) {
            NarrativeArcVisualization(
                arc: arc,
                segments: arcSegments,
                activePositionFraction: activePosition > 0 ? activePosition : nil,
                height: 80
            )

            // Beat labels below
            GeometryReader { geometry in
                ForEach(beats, id: \.beatID) { beat in
                    Text(beat.label)
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                        .lineLimit(1)
                        .frame(width: 60)
                        .offset(
                            x: (geometry.size.width * beat.normalizedPosition) - 30,
                            y: 0
                        )
                }
            }
            .frame(height: 20)
        }
        .frame(height: 100)
    }

    private func contourSegmentView(segment: ContourSegment, width: CGFloat) -> some View {
        let xStart = width * segment.startFraction
        let xEnd = width * segment.endFraction
        let segmentWidth = xEnd - xStart

        let color: Color = {
            switch segment.state {
            case .formed:
                return themeManager.currentTheme.colors.accentPrimary
            case .thin:
                return themeManager.currentTheme.colors.textSecondary.opacity(0.4)
            case .broken:
                return Color.clear
            }
        }()

        let lineHeight = 2.0 * segment.visualWeight

        return Rectangle()
            .fill(color)
            .frame(width: segmentWidth, height: lineHeight)
            .offset(x: xStart, y: 0)
    }

    private func structureBeatNodeView(beat: StructureBeat, width: CGFloat) -> some View {
        let xPosition = width * beat.normalizedPosition

        return ZStack {
            // Node circle
            Circle()
                .fill(beat.isMaterialized ? themeManager.currentTheme.colors.accentPrimary : Color.clear)
                .strokeBorder(
                    themeManager.currentTheme.colors.accentPrimary,
                    lineWidth: beat.isDefined ? 2 : 1
                )
                .frame(width: 16, height: 16)

            // Label below
            Text(beat.label)
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                .offset(y: 24)

            // Scene count badge (if materialized)
            if beat.isMaterialized && beat.attachedSceneCount > 0 {
                Text("\(beat.attachedSceneCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 12, height: 12)
                    .background(Circle().fill(themeManager.currentTheme.colors.accentPrimary))
                    .offset(x: 8, y: -8)
            }
        }
        .offset(x: xPosition)
    }

    private func activePositionMarker(position: Double, width: CGFloat) -> some View {
        let xPosition = width * position

        return Rectangle()
            .fill(themeManager.currentTheme.colors.accentPrimary)
            .frame(width: 2, height: 16)
            .offset(x: xPosition, y: -7)
    }

    // MARK: - Project Status Glyph

    private var projectStatusGlyph: some View {
        ZStack {
            if let model = dashboardModel {
                // Outer ring - Timeline/Story events
                timelineRingView(model.statusGlyph.timelineRing)
                    .frame(width: 240, height: 240)

                // Middle ring - Chapter formation
                chapterRingView(model.statusGlyph.chapterRing)
                    .frame(width: 180, height: 180)

                // Inner ring - Scene realization
                sceneRingView(model.statusGlyph.sceneRing)
                    .frame(width: 120, height: 120)

                // Center labels
                centerLabels(model.statusGlyph)
            } else {
                // Loading state
                ProgressView()
            }
        }
        .padding(20)
    }

    private func timelineRingView(_ ring: TimelineRing) -> some View {
        ZStack {
            // Base circle
            Circle()
                .stroke(themeManager.currentTheme.colors.border.opacity(0.3), lineWidth: 2)

            // Event nodes
            ForEach(ring.events, id: \.eventID) { event in
                eventNode(event)
            }
        }
    }

    private func eventNode(_ event: TimelineEventNode) -> some View {
        Circle()
            .fill(event.isActive
                ? themeManager.currentTheme.colors.accentPrimary
                : themeManager.currentTheme.colors.textSecondary.opacity(0.5))
            .frame(width: event.isMajor ? 8 : 4, height: event.isMajor ? 8 : 4)
            .offset(x: 120 * cos(event.normalizedAngle), y: 120 * sin(event.normalizedAngle))
    }

    private func chapterRingView(_ ring: ChapterRing) -> some View {
        ZStack {
            ForEach(ring.spans, id: \.chapterID) { span in
                spanArc(
                    startAngle: span.startAngle,
                    endAngle: span.endAngle,
                    state: span.state,
                    lineWidth: 16,
                    opacity: 0.6
                )
            }
        }
    }

    private func sceneRingView(_ ring: SceneRing) -> some View {
        ZStack {
            ForEach(ring.spans, id: \.sceneID) { span in
                spanArc(
                    startAngle: span.startAngle,
                    endAngle: span.endAngle,
                    state: span.state,
                    lineWidth: 16,
                    opacity: 1.0,
                    isOrphan: span.isOrphanSpill
                )
            }
        }
    }

    private func spanArc(
        startAngle: Double,
        endAngle: Double,
        state: GlyphSpanState,
        lineWidth: CGFloat,
        opacity: Double,
        isOrphan: Bool = false
    ) -> some View {
        let totalAngle = Double.pi * 2.0
        let from = startAngle / totalAngle
        let to = endAngle / totalAngle

        let color: Color = {
            if isOrphan {
                return .orange
            }
            switch state {
            case .formed:
                return themeManager.currentTheme.colors.accentPrimary
            case .thinDefined:
                return themeManager.currentTheme.colors.textSecondary.opacity(0.4)
            case .missing:
                return Color.clear
            }
        }()

        return Circle()
            .trim(from: from, to: to)
            .stroke(color.opacity(opacity), lineWidth: lineWidth)
            .rotationEffect(.radians(-Double.pi / 2)) // Start at top
    }

    private func centerLabels(_ statusGlyph: StatusGlyphModel) -> some View {
        let sceneSpans = statusGlyph.sceneRing.spans
        let formedCount = sceneSpans.filter { $0.state == .formed }.count
        let totalCount = sceneSpans.count

        return VStack(spacing: 4) {
            if totalCount == 0 {
                // Empty state
                Text("Empty")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                Text("No content yet")
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
            } else {
                // Normal state with percentage
                let percentage = Int((Double(formedCount) / Double(totalCount)) * 100)
                Text("\(percentage)%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                Text("Complete")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
            }
        }
    }

    // MARK: - Return Strip

    private var returnStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resume Writing")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            if let model = dashboardModel {
                HStack(spacing: 12) {
                    // Last node
                    if let lastNode = model.returnStrip.lastNode {
                        returnNodeView(node: lastNode, label: "Last", isActive: false)
                            .frame(width: 140)
                    }

                    // Resume node (primary)
                    returnNodeView(node: model.returnStrip.resumeNode, label: "Resume", isActive: true)
                        .frame(width: 180)

                    // Next node
                    if let nextNode = model.returnStrip.nextNode {
                        returnNodeView(node: nextNode, label: "Next", isActive: false)
                            .frame(width: 140)
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func returnNodeView(node: ReturnNode, label: String, isActive: Bool) -> some View {
        Button {
            // TODO: Jump to this scene/chapter
            // Navigate to node.targetID based on node.targetType
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

                Text(node.title)
                    .font(isActive ? .callout.weight(.semibold) : .callout)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    .lineLimit(1)

                if !node.subtitle.isEmpty {
                    Text(node.subtitle)
                        .font(.caption2)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(themeManager.currentTheme.colors.accentPrimary.opacity(0.15))
                } else {
                    themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 8)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isActive
                            ? themeManager.currentTheme.colors.accentPrimary
                            : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Cast Shelf

    private var castShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cast")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            if let model = dashboardModel {
                if model.castShelf.characters.isEmpty {
                    Text("No characters")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(model.castShelf.characters.prefix(8), id: \.characterID) { character in
                            castPortraitView(character: character)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func castPortraitView(character: CastCharacter) -> some View {
        Button {
            // TODO: Open character card (character.characterID)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    themeManager.currentTheme.colors.surfaceTertiary.platformResolved.asBackground(cornerRadius: 28)
                        .frame(width: 56, height: 56)

                    if let thumbnailData = character.thumbnailData {
                        #if os(macOS)
                        if let nsImage = NSImage(data: thumbnailData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        }
                        #else
                        if let uiImage = UIImage(data: thumbnailData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        }
                        #endif
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                    }
                }

                Text(character.displayLabel)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Issues Shelf

    private var issuesShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            if let model = dashboardModel {
                if model.issuesShelf.issues.isEmpty {
                    Text("No issues")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.issuesShelf.issues) { issue in
                            issueRowView(issue: issue)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func issueRowView(issue: ProjectIssue) -> some View {
        Button {
            // TODO: Open issue detail pane or jump to affected cards
            // issue.linkedTargets contains affected card IDs
            // issue.resolutionActions contains action labels
        } label: {
            HStack(spacing: 8) {
                Image(systemName: issueIcon(issue.issueType))
                    .font(.caption)
                    .foregroundStyle(severityColor(issue.severity))
                    .frame(width: 20)

                Text(issue.displayText)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 6).opacity(0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func issueIcon(_ issueType: IssueType) -> String {
        switch issueType {
        case .orphanedScenes, .orphanedChapters:
            return "exclamationmark.triangle"
        case .continuityGap:
            return "arrow.triangle.branch"
        case .unresolvedCitation:
            return "link.badge.plus"
        case .unassignedCard:
            return "questionmark.circle"
        }
    }

    private func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    // MARK: - Thread Shelf

    private var threadShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Narrative Threads")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            if let model = dashboardModel {
                if model.threadShelf.threads.isEmpty {
                    Text("No threads defined")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.threadShelf.threads) { thread in
                            threadTagView(thread: thread)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }

    private func threadTagView(thread: NarrativeThread) -> some View {
        Button {
            // TODO: Focus thread - highlight linked scenes/events
            // thread.linkedSceneIDs, thread.linkedEventIDs, thread.linkedCardIDs
        } label: {
            HStack(spacing: 6) {
                // Small thread glyph
                Image(systemName: "arrow.triangle.pull")
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)

                Text(thread.label)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground(cornerRadius: 100)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        themeManager.currentTheme.colors.accentPrimary.opacity(thread.weight),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadDashboardModel() {
        // Initialize service
        dashboardService = ProjectDashboardService(modelContext: modelContext)

        // Build dashboard model
        dashboardModel = dashboardService?.buildDashboardModel(for: project)
    }
}

// MARK: - Dashboard Model
// Models now defined in Cumberland/Data/ProjectDashboardModels.swift

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Card.self, configurations: config)
    let context = container.mainContext

    let project = Card(kind: .projects, name: "The Lantern Chronicles", subtitle: "A Fantasy Epic", detailedText: "")
    context.insert(project)

    // Add sample data
    for i in 1...5 {
        let chapter = Card(kind: .chapters, name: "Chapter \(i)", subtitle: "", detailedText: "")
        context.insert(chapter)
    }

    for i in 1...12 {
        let scene = Card(kind: .scenes, name: "Scene \(i)", subtitle: "", detailedText: "")
        context.insert(scene)
    }

    for name in ["Aria", "Mira", "Kael", "Lysander"] {
        let character = Card(kind: .characters, name: name, subtitle: "", detailedText: "")
        context.insert(character)
    }

    return NavigationStack {
        ProjectDashboardView(project: project)
            .modelContainer(container)
            .environmentObject(ThemeManager())
    }
}
