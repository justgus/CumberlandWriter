//
//  MultiTimelineGraphView.swift
//  Cumberland
//
//  Created by Claude Code on 2026-01-28.
//  Phase 8: Multi-Timeline Graph Visualization
//

import SwiftUI
import SwiftData
import Charts

/// A view that displays multiple timelines on a shared calendar axis.
/// This allows comparison of multiple storylines occurring in the same calendar system.
struct MultiTimelineGraphView: View {
    let calendarSystem: CalendarSystem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // All timelines using this calendar
    @State private var allTimelines: [Card] = []

    // Timeline tracks with scene data
    @State private var timelineTracks: [TimelineTrack] = []

    // Track visibility toggles (timeline ID -> enabled)
    @State private var enabledTrackIDs: Set<UUID> = []

    // Temporal zoom levels (reuse from TimelineChartView)
    private enum TemporalZoomLevel: CaseIterable {
        case hour
        case day
        case week
        case month
        case year
        case decade
        case century

        var timeInterval: TimeInterval {
            switch self {
            case .hour:    return 3600
            case .day:     return 86400
            case .week:    return 604800
            case .month:   return 2592000  // ~30 days
            case .year:    return 31536000 // ~365 days
            case .decade:  return 315360000
            case .century: return 3153600000
            }
        }

        var label: String {
            switch self {
            case .hour:    return "Hour"
            case .day:     return "Day"
            case .week:    return "Week"
            case .month:   return "Month"
            case .year:    return "Year"
            case .decade:  return "Decade"
            case .century: return "Century"
            }
        }
    }

    // Current zoom level
    @State private var zoomLevel: TemporalZoomLevel = .month

    // Scroll position (shared across all timelines)
    @State private var scrollPosition: Date? = nil

    // Selected scene for navigation/details
    @State private var selectedScene: Card? = nil
    @State private var isPresentingSceneDetails: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if timelineTracks.isEmpty {
                emptyState
            } else if enabledTracks.isEmpty {
                allDisabledState
            } else {
                chartArea
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $isPresentingSceneDetails) {
            if let scene = selectedScene {
                // Show scene details - for now just a simple sheet
                NavigationStack {
                    VStack(spacing: 16) {
                        Label(scene.name, systemImage: Kinds.scenes.systemImage)
                            .font(.title2)

                        if !scene.subtitle.isEmpty {
                            Text(scene.subtitle)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }

                        if !scene.detailedText.isEmpty {
                            ScrollView {
                                Text(scene.detailedText)
                                    .padding()
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Scene Details")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                isPresentingSceneDetails = false
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Label("Multi-Timeline Graph", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)

            Spacer()

            // Track visibility menu
            Menu {
                Button(enabledTracks.count == timelineTracks.count ? "Deselect All" : "Select All") {
                    if enabledTracks.count == timelineTracks.count {
                        enabledTrackIDs = []
                    } else {
                        enabledTrackIDs = Set(timelineTracks.map(\.timeline.id))
                    }
                }

                Divider()

                ForEach(timelineTracks) { track in
                    let isEnabled = enabledTrackIDs.contains(track.timeline.id)
                    Toggle(isOn: Binding(
                        get: { isEnabled },
                        set: { newValue in
                            if newValue {
                                enabledTrackIDs.insert(track.timeline.id)
                            } else {
                                enabledTrackIDs.remove(track.timeline.id)
                            }
                        }
                    )) {
                        HStack {
                            Circle()
                                .fill(track.color)
                                .frame(width: 10, height: 10)
                            Text(track.timeline.name)
                        }
                    }
                }
            } label: {
                Label("Tracks (\(enabledTracks.count)/\(timelineTracks.count))", systemImage: "line.3.horizontal.decrease.circle")
            }
            .help("Show/hide timeline tracks")

            Divider()
                .frame(height: 18)

            // Zoom controls
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .foregroundStyle(.secondary)

                Text(zoomLevel.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 50)

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
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .controlSize(.small)
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Timelines")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No timelines are using this calendar system.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var allDisabledState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("All Tracks Hidden")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable timeline tracks from the menu above.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Chart Area

    private var enabledTracks: [TimelineTrack] {
        timelineTracks.filter { enabledTrackIDs.contains($0.timeline.id) }
    }

    private var chartArea: some View {
        let tracks = enabledTracks

        // Build lane keys for Y domain
        let yDomainKeys: [String] = tracks.map { laneKey(for: $0.timeline) }

        // Get date range across all enabled tracks
        let allScenes = tracks.flatMap(\.scenes)
        guard !allScenes.isEmpty else {
            return AnyView(noScenesState)
        }

        let minDate = allScenes.map(\.position).min() ?? Date()
        let maxDate = allScenes.map(\.end).max() ?? Date()

        // Ensure at least some range
        let displayMinDate = minDate
        let displayMaxDate = max(minDate.addingTimeInterval(86400), maxDate) // At least 1 day

        // Date formatter
        let dateFormatter = temporalDateFormatter()

        // Calculate visible time span based on zoom level
        let visibleTimeSpan: TimeInterval = {
            switch zoomLevel {
            case .hour:    return 86400        // Show 24 hours (1 day)
            case .day:     return 604800       // Show 7 days (1 week)
            case .week:    return 2592000      // Show ~30 days (1 month)
            case .month:   return 31536000     // Show ~365 days (1 year)
            case .year:    return 315360000    // Show 10 years
            case .decade:  return 3153600000   // Show 100 years
            case .century: return 31536000000  // Show 1000 years
            }
        }()

        // Scroll position (default to midpoint)
        let scrollPos = scrollPosition ?? {
            let midInterval = (displayMinDate.timeIntervalSinceReferenceDate + displayMaxDate.timeIntervalSinceReferenceDate) / 2
            return Date(timeIntervalSinceReferenceDate: midInterval)
        }()

        return AnyView(
            Chart {
                // Render in layers: Chronicles (background), then Scenes (foreground)
                ForEach(tracks) { track in
                    let key = laneKey(for: track.timeline)

                    // Layer 1: Chronicle lozenges (rounded rectangles spanning temporal bounds)
                    ForEach(track.chronicles) { chronicle in
                        RectangleMark(
                            xStart: .value("Start", chronicle.start),
                            xEnd: .value("End", chronicle.end),
                            y: .value("Lane", key)
                        )
                        .foregroundStyle(track.color.opacity(0.2))
                        .cornerRadius(8)
                        .annotation(position: .overlay, alignment: .center) {
                            Text(chronicle.chronicle.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                                .lineLimit(1)
                        }
                    }

                    // Layer 2: Scene markers (small bars or points)
                    ForEach(track.scenes) { sceneMarker in
                        let isInChronicle = sceneMarker.parentChronicle != nil

                        // Scene as a small vertical bar
                        BarMark(
                            xStart: .value("Start", sceneMarker.position),
                            xEnd: .value("End", sceneMarker.end),
                            y: .value("Lane", key)
                        )
                        .foregroundStyle(isInChronicle ? track.color.opacity(0.8) : track.color)
                        .cornerRadius(2)
                        .annotation(position: .top, alignment: .center) {
                            VStack(spacing: 2) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(track.color)
                                Text(sceneMarker.scene.name)
                                    .font(.system(size: 8))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 3))
                                    .lineLimit(1)
                            }
                        }
                        .accessibilityLabel(sceneMarker.scene.name)
                        .accessibilityValue("At \(dateFormatter.string(from: sceneMarker.position))")
                    }

                    // Lane labels on the left
                    RectangleMark(
                        xStart: .value("Start", displayMinDate.addingTimeInterval(-86400 * 30)), // Fake left column
                        xEnd: .value("End", displayMinDate),
                        y: .value("Lane", key)
                    )
                    .foregroundStyle(Color.clear)
                    .annotation(position: .leading, alignment: .leading) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(track.color)
                                .frame(width: 8, height: 8)
                            Text(track.timeline.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.trailing, 8)
                    }
                }
            }
            .chartYAxis(.hidden) // Custom lane labels
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    if let date = value.as(Date.self) {
                        AxisValueLabel(dateFormatter.string(from: date))
                    }
                }
            }
            .chartLegend(.hidden)
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(x: Binding(
                get: { scrollPosition ?? scrollPos },
                set: { scrollPosition = $0 }
            ))
            .chartXVisibleDomain(length: visibleTimeSpan)
            .chartXScale(domain: displayMinDate...displayMaxDate)
            .chartYScale(domain: yDomainKeys)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.thinMaterial)
            )
            .chartPlotStyle { plot in
                plot.frame(minHeight: CGFloat(tracks.count * 80).clamped(to: 200...1000)) // Increased height for chronicles
            }
        )
    }

    private var noScenesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Scenes with Temporal Positions")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Enabled timelines don't have scenes with temporal positions yet. Add scenes to timelines with temporal positions to see them here.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var shadowColor: Color {
        scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }

    // MARK: - Data Loading (ER-0016 Phase 2)

    @MainActor
    private func loadData() async {
        // Query ONLY timelines using this calendar system
        let calID: UUID? = calendarSystem.id
        let timelineKindRaw = Kinds.timelines.rawValue
        let fetch = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { card in
                card.kindRaw == timelineKindRaw && card.calendarSystem?.id == calID
            },
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )

        let timelines = (try? modelContext.fetch(fetch)) ?? []
        allTimelines = timelines

        // For each timeline, build a track with chronicles and scenes
        var tracks: [TimelineTrack] = []
        for (index, timeline) in timelines.enumerated() {
            let tlID: UUID? = timeline.id
            let sceneKindRaw = Kinds.scenes.rawValue
            let chronicleKindRaw = Kinds.chronicles.rawValue

            // 1. Fetch Chronicles related to this Timeline (Chronicle→Timeline edges)
            let chronicleEdgeFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate<CardEdge> { edge in
                    edge.to?.id == tlID && edge.from?.kindRaw == chronicleKindRaw
                }
            )
            let chronicleEdges = (try? modelContext.fetch(chronicleEdgeFetch)) ?? []

            // Build ChronicleSpan objects
            var chronicleSpans: [ChronicleSpan] = []
            var chronicleIDToSpan: [UUID: ChronicleSpan] = [:]

            for edge in chronicleEdges {
                guard let chronicle = edge.from,
                      let temporalPos = edge.temporalPosition,
                      let duration = edge.duration else {
                    continue // Chronicle must have both start and duration to appear
                }

                let span = ChronicleSpan(
                    chronicle: chronicle,
                    start: temporalPos,
                    duration: duration,
                    scenes: [] // Will populate later
                )
                chronicleSpans.append(span)
                chronicleIDToSpan[chronicle.id] = span
            }

            // 2. Fetch Scenes related to this Timeline (Scene→Timeline edges)
            let sceneEdgeFetch = FetchDescriptor<CardEdge>(
                predicate: #Predicate<CardEdge> { edge in
                    edge.to?.id == tlID && edge.from?.kindRaw == sceneKindRaw
                },
                sortBy: [SortDescriptor(\.sortIndex, order: .forward)]
            )
            let sceneEdges = (try? modelContext.fetch(sceneEdgeFetch)) ?? []

            // Build SceneMarker objects
            var sceneMarkers: [SceneMarker] = []

            for edge in sceneEdges {
                guard let scene = edge.from,
                      let temporalPos = edge.temporalPosition else {
                    continue // Scene must have temporal position to appear
                }

                // 3. Check if this Scene is grouped under a Chronicle (Scene→Chronicle edge)
                let sceneID: UUID? = scene.id
                let chronicleForSceneFetch = FetchDescriptor<CardEdge>(
                    predicate: #Predicate<CardEdge> { chronicleEdge in
                        chronicleEdge.from?.id == sceneID && chronicleEdge.to?.kindRaw == chronicleKindRaw
                    }
                )
                let chronicleForSceneEdges = (try? modelContext.fetch(chronicleForSceneFetch)) ?? []
                let parentChronicle = chronicleForSceneEdges.first?.to

                let marker = SceneMarker(
                    scene: scene,
                    position: temporalPos,
                    duration: edge.duration,
                    parentChronicle: parentChronicle
                )
                sceneMarkers.append(marker)
            }

            // 4. Group scenes under their parent chronicles
            var updatedChronicleSpans: [ChronicleSpan] = []
            for span in chronicleSpans {
                let scenesInChronicle = sceneMarkers.filter { $0.parentChronicle?.id == span.chronicle.id }
                let updatedSpan = ChronicleSpan(
                    chronicle: span.chronicle,
                    start: span.start,
                    duration: span.duration,
                    scenes: scenesInChronicle
                )
                updatedChronicleSpans.append(updatedSpan)
            }

            // Assign a color to this timeline (cycle through accent colors)
            let color = colorForTrack(at: index)

            tracks.append(TimelineTrack(
                timeline: timeline,
                chronicles: updatedChronicleSpans,
                scenes: sceneMarkers,
                color: color
            ))
        }

        timelineTracks = tracks

        // Enable all tracks by default
        if enabledTrackIDs.isEmpty {
            enabledTrackIDs = Set(timelines.map(\.id))
        }

        // Auto-select appropriate zoom level
        let allScenes = tracks.flatMap(\.scenes)
        if let minDate = allScenes.map(\.position).min(),
           let maxDate = allScenes.map(\.end).max() {
            let span = maxDate.timeIntervalSince(minDate)
            zoomLevel = autoSelectZoomLevel(for: span)

            // Set scroll position to middle
            let midInterval = (minDate.timeIntervalSinceReferenceDate + maxDate.timeIntervalSinceReferenceDate) / 2
            scrollPosition = Date(timeIntervalSinceReferenceDate: midInterval)
        }
    }

    // MARK: - Helpers

    private func laneKey(for timeline: Card) -> String {
        "timeline-\(timeline.id.uuidString)"
    }

    private func colorForTrack(at index: Int) -> Color {
        // Cycle through distinct colors
        let colors: [Color] = [
            .blue, .purple, .pink, .red, .orange,
            .yellow, .green, .teal, .cyan, .indigo
        ]
        return colors[index % colors.count]
    }

    private func temporalDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch zoomLevel {
        case .hour:
            formatter.dateFormat = "HH:mm"
        case .day:
            formatter.dateFormat = "MMM d"
        case .week:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        case .decade:
            formatter.dateFormat = "yyyy"
        case .century:
            formatter.dateFormat = "yyyy"
        }

        return formatter
    }

    private func autoSelectZoomLevel(for span: TimeInterval) -> TemporalZoomLevel {
        switch span {
        case 0..<3600 * 24:           return .hour
        case 3600 * 24..<3600 * 24 * 7: return .day
        case 3600 * 24 * 7..<3600 * 24 * 60: return .week
        case 3600 * 24 * 60..<3600 * 24 * 365: return .month
        case 3600 * 24 * 365..<3600 * 24 * 3650: return .year
        case 3600 * 24 * 3650..<3600 * 24 * 36500: return .decade
        default: return .century
        }
    }

    // MARK: - Zoom Controls

    private func zoomIn() {
        let currentIndex = TemporalZoomLevel.allCases.firstIndex(of: zoomLevel) ?? 0
        if currentIndex > 0 {
            zoomLevel = TemporalZoomLevel.allCases[currentIndex - 1]
        }
    }

    private func zoomOut() {
        let currentIndex = TemporalZoomLevel.allCases.firstIndex(of: zoomLevel) ?? TemporalZoomLevel.allCases.count - 1
        if currentIndex < TemporalZoomLevel.allCases.count - 1 {
            zoomLevel = TemporalZoomLevel.allCases[currentIndex + 1]
        }
    }

    private func fitAll() {
        let allScenes = enabledTracks.flatMap(\.scenes)
        guard !allScenes.isEmpty else { return }

        let minDate = allScenes.map(\.position).min() ?? Date()
        let maxDate = allScenes.map(\.end).max() ?? Date()
        let span = maxDate.timeIntervalSince(minDate)

        zoomLevel = autoSelectZoomLevel(for: span)

        // Center scroll on midpoint
        let midInterval = (minDate.timeIntervalSinceReferenceDate + maxDate.timeIntervalSinceReferenceDate) / 2
        scrollPosition = Date(timeIntervalSinceReferenceDate: midInterval)
    }
}

// MARK: - Data Models

/// Represents a Timeline track with its associated Chronicles and Scenes (ER-0016 Phase 2)
private struct TimelineTrack: Identifiable {
    let timeline: Card // kind == .timelines
    let chronicles: [ChronicleSpan]  // Chronicles appearing on this timeline
    let scenes: [SceneMarker]  // All scenes on this timeline (includes scenes in chronicles and standalone)
    let color: Color

    var id: UUID { timeline.id }
}

/// Represents a Chronicle's temporal span on a Timeline (ER-0016 Phase 2)
private struct ChronicleSpan: Identifiable {
    let chronicle: Card  // kind == .chronicles
    let start: Date  // temporalPosition from Chronicle→Timeline edge
    let duration: TimeInterval  // duration from Chronicle→Timeline edge
    let scenes: [SceneMarker]  // Scenes grouped under this chronicle

    var id: UUID { chronicle.id }
    var end: Date { start.addingTimeInterval(duration) }
}

/// Represents a Scene marker on a Timeline (ER-0016 Phase 2)
private struct SceneMarker: Identifiable {
    let scene: Card  // kind == .scenes
    let position: Date  // temporalPosition from Scene→Timeline edge
    let duration: TimeInterval?  // optional duration
    let parentChronicle: Card?  // if Scene→Chronicle relationship exists

    var id: UUID { scene.id }
    var end: Date { position.addingTimeInterval(duration ?? 3600) } // Default 1 hour
}

