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

    // Query for project-related cards
    @Query private var allCards: [Card]

    @State private var dashboardModel: ProjectDashboardModel?

    private var chapters: [Card] {
        allCards.filter { $0.kind == .chapters }
            .sorted { $0.name < $1.name }
    }

    private var scenes: [Card] {
        allCards.filter { $0.kind == .scenes }
            .sorted { $0.name < $1.name }
    }

    private var characters: [Card] {
        allCards.filter { $0.kind == .characters }
            .sorted { $0.name < $1.name }
    }

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
        .onAppear {
            loadDashboardModel()
        }
    }

    // MARK: - Project Header

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name.isEmpty ? "Untitled Project" : project.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.colors.textPrimary)

            HStack(spacing: 16) {
                Label("\(chapters.count) chapters", systemImage: "book.closed")
                Label("\(scenes.count) scenes", systemImage: "rectangle.stack")
                Label("\(characters.count) characters", systemImage: "person.2")
            }
            .font(.caption)
            .foregroundStyle(themeManager.currentTheme.colors.textSecondary)

            HStack(spacing: 8) {
                phaseBadge("Drafting")
                stateBadge("Active")
            }
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
            Text("Story Structure")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            // Horizontal contour showing structural beats and content density
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Baseline
                    Rectangle()
                        .fill(themeManager.currentTheme.colors.border)
                        .frame(height: 2)

                    // Structure beats (placeholder - should come from StoryStructure)
                    HStack(spacing: 0) {
                        ForEach(0..<5) { index in
                            structureBeatNode(
                                label: "Beat \(index + 1)",
                                position: CGFloat(index) / 4.0,
                                isMaterialized: index < 3,
                                width: geometry.size.width
                            )
                        }
                    }
                }
            }
            .frame(height: 60)
        }
    }

    private func structureBeatNode(label: String, position: CGFloat, isMaterialized: Bool, width: CGFloat) -> some View {
        let xPosition = width * position

        return ZStack {
            // Node circle
            Circle()
                .fill(isMaterialized ? themeManager.currentTheme.colors.accentPrimary : Color.clear)
                .strokeBorder(themeManager.currentTheme.colors.accentPrimary, lineWidth: isMaterialized ? 2 : 1)
                .frame(width: 16, height: 16)

            // Label below
            Text(label)
                .font(.caption2)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)
                .offset(y: 24)
        }
        .offset(x: xPosition)
    }

    // MARK: - Project Status Glyph

    private var projectStatusGlyph: some View {
        ZStack {
            // Outer ring - Timeline/Story events
            Circle()
                .stroke(themeManager.currentTheme.colors.border.opacity(0.3), lineWidth: 2)
                .frame(width: 240, height: 240)

            // Middle ring - Chapter formation
            Circle()
                .trim(from: 0, to: 0.75) // 75% complete
                .stroke(themeManager.currentTheme.colors.accentPrimary.opacity(0.6), lineWidth: 16)
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))

            // Inner ring - Scene realization
            Circle()
                .trim(from: 0, to: 0.6) // 60% complete
                .stroke(themeManager.currentTheme.colors.accentPrimary, lineWidth: 16)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))

            // Center labels
            VStack(spacing: 4) {
                Text("60%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                Text("Complete")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textSecondary)
            }
        }
        .padding(20)
    }

    // MARK: - Return Strip

    private var returnStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resume Writing")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

            HStack(spacing: 12) {
                // Last node
                returnNode(title: "Last", subtitle: "Chapter 2, Scene 5", isActive: false)
                    .frame(width: 140)

                // Resume node (primary)
                returnNode(title: "Resume", subtitle: "Chapter 3, Scene 1", isActive: true)
                    .frame(width: 180)

                // Next node
                returnNode(title: "Next", subtitle: "Chapter 3, Scene 2", isActive: false)
                    .frame(width: 140)
            }
        }
    }

    private func returnNode(title: String, subtitle: String, isActive: Bool) -> some View {
        Button {
            // TODO: Jump to this scene
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.textTertiary)

                Text(subtitle)
                    .font(isActive ? .callout.weight(.semibold) : .callout)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
                    .lineLimit(2)
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

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(characters.prefix(8)) { character in
                    castPortrait(for: character)
                }
            }
        }
    }

    private func castPortrait(for character: Card) -> some View {
        Button {
            // TODO: Open character card
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .background(themeManager.currentTheme.colors.surfaceTertiary.platformResolved.asBackground())
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

                Text(character.name)
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

            VStack(alignment: .leading, spacing: 8) {
                issueRow(icon: "exclamationmark.triangle", text: "Orphan scenes ×3", severity: .warning)
                issueRow(icon: "link.badge.plus", text: "Unresolved citations ×1", severity: .info)
                issueRow(icon: "arrow.triangle.branch", text: "Continuity gap in Ch. 2", severity: .error)
            }
        }
    }

    private func issueRow(icon: String, text: String, severity: IssueSeverity) -> some View {
        Button {
            // TODO: Open issue detail pane
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(severityColor(severity))
                    .frame(width: 20)

                Text(text)
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
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground().opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }

    private enum IssueSeverity {
        case error, warning, info
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

            VStack(alignment: .leading, spacing: 8) {
                threadTag(name: "Lantern mystery")
                threadTag(name: "Mira / Ari")
                threadTag(name: "Archive revelation")
            }
        }
    }

    private func threadTag(name: String) -> some View {
        Button {
            // TODO: Focus thread
        } label: {
            HStack(spacing: 6) {
                // Small thread glyph
                Image(systemName: "arrow.triangle.pull")
                    .font(.caption2)
                    .foregroundStyle(themeManager.currentTheme.colors.accentPrimary)

                Text(name)
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .background(themeManager.currentTheme.colors.surfaceSecondary.platformResolved.asBackground())
            )
            .overlay(
                Capsule()
                    .strokeBorder(themeManager.currentTheme.colors.accentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Loading

    private func loadDashboardModel() {
        // TODO: Build comprehensive dashboard model from project data
        // For now, using placeholder data shown in the UI
    }
}

// MARK: - Dashboard Model

struct ProjectDashboardModel {
    var projectID: UUID
    var title: String
    var phase: String
    var chapterCount: Int
    var sceneCount: Int
    var timelineCount: Int

    // Sub-models for each region
    var currentContext: CurrentContext?
    var structureBand: StructureBandModel?
    var statusGlyph: StatusGlyphModel?
    var returnStrip: ReturnStripModel?
    var castShelf: CastShelfModel?
    var issuesShelf: IssuesShelfModel?
    var threadShelf: ThreadShelfModel?
}

struct CurrentContext {
    var activeChapterID: UUID?
    var activeSceneID: UUID?
    var activeEventID: UUID?
    var sceneContents: [UUID] // Card IDs
    var orphanCounts: [(String, Int)]
}

struct StructureBandModel {
    var beats: [StructureBeat]
    var contourSegments: [ContourSegment]
    var activePositionFraction: Double
    var continuityBreaks: [(after: UUID, before: UUID)]
}

struct StructureBeat {
    var beatID: UUID
    var label: String
    var normalizedPosition: Double
    var isDefined: Bool
    var isMaterialized: Bool
    var attachedSceneCount: Int
}

struct ContourSegment {
    var startFraction: Double
    var endFraction: Double
    var visualWeight: Double
    var state: ContourState
}

enum ContourState {
    case formed, thin, broken
}

struct StatusGlyphModel {
    var timelineRing: TimelineRing
    var chapterRing: ChapterRing
    var sceneRing: SceneRing
    var activeLocus: ActiveLocus?
}

struct TimelineRing {
    var events: [TimelineEventNode]
}

struct TimelineEventNode {
    var eventID: UUID
    var normalizedAngle: Double
    var isActive: Bool
    var isMajor: Bool
}

struct ChapterRing {
    var spans: [ChapterSpan]
}

struct ChapterSpan {
    var chapterID: UUID
    var startAngle: Double
    var endAngle: Double
    var state: GlyphSpanState
}

struct SceneRing {
    var spans: [SceneSpan]
}

struct SceneSpan {
    var sceneID: UUID
    var startAngle: Double
    var endAngle: Double
    var state: GlyphSpanState
    var isOrphanSpill: Bool
}

enum GlyphSpanState {
    case formed, thinDefined, missing
}

struct ActiveLocus {
    var eventID: UUID?
    var chapterID: UUID?
    var sceneID: UUID?
}

struct ReturnStripModel {
    var lastNode: ReturnNode?
    var resumeNode: ReturnNode?
    var nextNode: ReturnNode?
}

struct ReturnNode {
    var targetID: UUID
    var targetType: String
    var title: String
    var subtitle: String
    var excerpt: String
    var contextTokens: [String]
}

struct CastShelfModel {
    var characters: [UUID] // Character card IDs
}

struct IssuesShelfModel {
    var issues: [ProjectIssue]
}

struct ProjectIssue {
    var issueID: UUID
    var issueType: String
    var displayText: String
    var severity: String
    var linkedTargets: [UUID]
}

struct ThreadShelfModel {
    var threads: [NarrativeThread]
}

struct NarrativeThread {
    var threadID: UUID
    var label: String
    var linkedSceneIDs: [UUID]
    var linkedEventIDs: [UUID]
    var linkedCardIDs: [UUID]
    var weight: Double
}

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
