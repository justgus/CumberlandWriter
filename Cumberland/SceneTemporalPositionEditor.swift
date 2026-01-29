// SceneTemporalPositionEditor.swift
// Part of ER-0008: Timeline System with Temporal Positioning

import SwiftUI
import SwiftData

/// Editor for setting a scene's temporal position and duration on a timeline
struct SceneTemporalPositionEditor: View {
    let scene: Card // kind == .scenes
    let timeline: Card // kind == .timelines
    let edge: CardEdge // Scene → Timeline relationship

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // Editable temporal properties
    @State private var temporalPosition: Date
    @State private var duration: TimeInterval
    @State private var useCustomDuration: Bool

    // Calendar-aware date input mode
    @State private var useCalendarInput: Bool = false
    @State private var calendarDivisionValues: [Int] = [] // Values for each division
    @State private var displayedCalculatedDate: Date = Date() // Explicitly tracked for view updates

    // Duration presets
    private enum DurationPreset: String, CaseIterable, Identifiable {
        case minutes15 = "15 minutes"
        case minutes30 = "30 minutes"
        case hour1 = "1 hour"
        case hours2 = "2 hours"
        case hours4 = "4 hours"
        case hours8 = "8 hours"
        case day1 = "1 day"
        case days3 = "3 days"
        case week1 = "1 week"
        case custom = "Custom"

        var id: String { rawValue }

        var timeInterval: TimeInterval? {
            switch self {
            case .minutes15: return 900
            case .minutes30: return 1800
            case .hour1: return 3600
            case .hours2: return 7200
            case .hours4: return 14400
            case .hours8: return 28800
            case .day1: return 86400
            case .days3: return 259200
            case .week1: return 604800
            case .custom: return nil
            }
        }
    }

    @State private var selectedPreset: DurationPreset = .hour1

    // Duration input - use calendar units if available
    @State private var durationInSmallestUnit: Int = 1 // e.g., 1 segment = 3600 seconds

    init(scene: Card, timeline: Card, edge: CardEdge) {
        self.scene = scene
        self.timeline = timeline
        self.edge = edge

        // Initialize state from edge
        let initialPosition = edge.temporalPosition ?? Date()
        let initialDuration = edge.duration ?? 3600 // Default 1 hour

        _temporalPosition = State(initialValue: initialPosition)
        _duration = State(initialValue: initialDuration)
        _useCustomDuration = State(initialValue: false)

        // Determine initial preset
        let preset = DurationPreset.allCases.first { $0.timeInterval == initialDuration } ?? .hour1
        _selectedPreset = State(initialValue: preset)

        // Calculate duration in smallest calendar unit (e.g., segments)
        // 1 segment = 3600 seconds (1 hour)
        let smallestUnitSeconds: TimeInterval = 3600
        let units = Int(initialDuration / smallestUnitSeconds)
        _durationInSmallestUnit = State(initialValue: max(1, units))

        // Initialize calendar-aware input
        let hasCustomCalendar = timeline.calendarSystem != nil
        _useCalendarInput = State(initialValue: hasCustomCalendar)

        // Initialize division values (start with zeros, user will set them)
        let divisionCount = timeline.calendarSystem?.divisions.count ?? 0
        _calendarDivisionValues = State(initialValue: Array(repeating: 0, count: divisionCount))

        // Initialize displayed calculated date
        _displayedCalculatedDate = State(initialValue: initialPosition)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temporal Position")
                        .font(.title2.bold())
                    Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Done") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // Temporal Position Section
                Section {
                    // Toggle between calendar-aware and standard date input
                    if timeline.calendarSystem != nil {
                        Picker("Input Mode", selection: $useCalendarInput) {
                            Text("Custom Calendar").tag(true)
                            Text("Standard Date").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useCalendarInput) { _, newValue in
                            print("📅 [SceneTemporalPositionEditor] Input mode changed to: \(newValue ? "Custom Calendar" : "Standard Date")")
                            if newValue, let calendar = timeline.calendarSystem, let epoch = timeline.epochDate {
                                // Switching to calendar mode - recalculate
                                let calculated = convertCalendarUnitsToDate(divisions: calendar.divisions, values: calendarDivisionValues, epoch: epoch)
                                displayedCalculatedDate = calculated
                                temporalPosition = calculated
                            }
                        }
                    }

                    if useCalendarInput, let calendar = timeline.calendarSystem {
                        // Calendar-aware date inputs
                        calendarDateInputs(for: calendar)
                    } else {
                        // Standard date picker (graphical calendar)
                        DatePicker(
                            "Date",
                            selection: $temporalPosition,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .frame(minHeight: 280) // Ensure graphical calendar has proper size

                        // Time picker (separate for better UX)
                        DatePicker(
                            "Time",
                            selection: $temporalPosition,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }

                    Divider()

                    // Show calculated date/time
                    if useCalendarInput {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calculated Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Show in calendar format
                            if let _ = timeline.calendarSystem {
                                Text(formatDateInCalendar(displayedCalculatedDate))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }

                            // Show in Gregorian for reference
                            HStack {
                                Text("(")
                                Text(displayedCalculatedDate, style: .date)
                                Text(displayedCalculatedDate, style: .time)
                                Text(")")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Show end time
                    if useCalendarInput, let _ = timeline.calendarSystem {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scene End Time:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(formatDateInCalendar(endTime))
                                .font(.subheadline)
                                .foregroundStyle(.primary)

                            HStack {
                                Text("(")
                                Text(endTime, style: .date)
                                Text(endTime, style: .time)
                                Text(")")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Text("Scene End Time:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(endTime, style: .date)
                                .foregroundStyle(.primary)
                            Text(endTime, style: .time)
                                .foregroundStyle(.primary)
                        }
                        .font(.subheadline)
                    }
                } header: {
                    Label("When", systemImage: "calendar")
                } footer: {
                    if let calendar = timeline.calendarSystem {
                        Text("Timeline uses the \(calendar.name) calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let epoch = timeline.epochDate {
                        Text("Timeline epoch: \(epoch, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Duration Section
                Section {
                    if let calendar = timeline.calendarSystem {
                        // Calendar-aware duration input
                        let smallestUnitPlural = calendar.divisions.first?.pluralName ?? "units"

                        HStack {
                            Text(smallestUnitPlural.capitalized + ":")
                                .frame(width: 100, alignment: .leading)

                            Spacer()

                            TextField("1", value: $durationInSmallestUnit, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: durationInSmallestUnit) { _, newValue in
                                    // Convert calendar units to seconds
                                    // 1 segment = 3600 seconds
                                    duration = TimeInterval(newValue) * 3600
                                }

                            Stepper("", value: $durationInSmallestUnit, in: 1...1000)
                                .labelsHidden()
                        }

                        // Show equivalent in standard time
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Equivalent:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formattedDurationForCalendar)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        // Standard duration input (no calendar)
                        HStack {
                            Text("Seconds:")
                                .frame(width: 100, alignment: .leading)

                            Spacer()

                            TextField("3600", value: Binding(
                                get: { Int(duration) },
                                set: { duration = TimeInterval($0) }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        }

                        Text("Duration: \(formattedDuration)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Duration", systemImage: "clock")
                } footer: {
                    if let calendar = timeline.calendarSystem, let smallestUnit = calendar.divisions.first {
                        Text("How long does this scene last? 1 \(smallestUnit.name) = 1 hour (3600 seconds)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("How long does this scene last?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()

            // Action buttons
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Clear Position") {
                    clearPosition()
                }
                .foregroundStyle(.red)

                Button("Save") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
        .onChange(of: calendarDivisionValues) { _, newValues in
            // Recalculate temporal position when calendar values change
            print("📅 [SceneTemporalPositionEditor] Calendar values changed: \(newValues)")
            if useCalendarInput, let calendar = timeline.calendarSystem, let epoch = timeline.epochDate {
                let calculated = convertCalendarUnitsToDate(divisions: calendar.divisions, values: newValues, epoch: epoch)
                displayedCalculatedDate = calculated
                temporalPosition = calculated
                print("📅 [SceneTemporalPositionEditor] Updated displayed date to: \(calculated)")
            }
        }
    }

    // MARK: - Computed Properties

    private var calculatedTemporalPosition: Date {
        if useCalendarInput, let calendar = timeline.calendarSystem, let epoch = timeline.epochDate {
            return convertCalendarUnitsToDate(divisions: calendar.divisions, values: calendarDivisionValues, epoch: epoch)
        }
        return temporalPosition
    }

    private var endTime: Date {
        let startTime = useCalendarInput ? displayedCalculatedDate : temporalPosition
        return startTime.addingTimeInterval(duration)
    }

    private var formattedDuration: String {
        let totalSeconds = duration

        let days = Int(totalSeconds / 86400)
        let hours = Int((totalSeconds.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)

        var components: [String] = []
        if days > 0 {
            components.append("\(days) day\(days == 1 ? "" : "s")")
        }
        if hours > 0 {
            components.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        if minutes > 0 {
            components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }

        return components.isEmpty ? "0 minutes" : components.joined(separator: ", ")
    }

    private var formattedDurationForCalendar: String {
        let totalSeconds = duration
        let hours = Int(totalSeconds / 3600)
        let days = hours / 24
        let remainingHours = hours % 24

        if days > 0 && remainingHours > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(remainingHours) hour\(remainingHours == 1 ? "" : "s")"
        } else if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }

    /// Format date in calendar representation
    private func formatDateInCalendar(_ date: Date) -> String {
        guard let _ = timeline.calendarSystem, let epoch = timeline.epochDate else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        // Calculate time since epoch in seconds
        let secondsSinceEpoch = date.timeIntervalSince(epoch)

        // Convert to segments (base unit, 3600 seconds each)
        let totalSegments = Int(secondsSinceEpoch / 3600)

        // Convert to rotations
        let totalRotations = totalSegments / 24
        let segments = totalSegments % 24

        // Convert to cycles and seasons
        let cycles = totalRotations / 360
        let rotationsInCycle = totalRotations % 360
        let seasons = rotationsInCycle / 90
        let rotations = rotationsInCycle % 90

        return "Cycle \(cycles), Season \(seasons), Rotation \(rotations), Segment \(segments)"
    }

    // MARK: - Calendar Date Input Views

    @ViewBuilder
    private func calendarDateInputs(for calendar: CalendarSystem) -> some View {
        ForEach(Array(calendar.divisions.enumerated()), id: \.offset) { index, division in
            if calendarDivisionValues.indices.contains(index) {
                HStack {
                    Text(division.name.capitalized + ":")
                        .frame(width: 100, alignment: .leading)

                    Spacer()

                    // Use direct binding to array element for proper @State updates
                    TextField("0", value: $calendarDivisionValues[index], format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)

                    Stepper("", value: $calendarDivisionValues[index], in: 0...10000)
                        .labelsHidden()
                }
            }
        }

        // Help text
        Text("Enter values for each time division. For example: Cycle 1847, Season 2 (Spring), Rotation 1, Segment 8")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    // MARK: - Calendar Conversion

    /// Converts calendar division values to a Date based on the timeline's epoch
    /// Imperial Meridian Calendar structure (user enters in this order):
    ///   - Epoch (variable, eras) - usually 0
    ///   - Cycle (years, 360 rotations each)
    ///   - Season (quarters, 90 rotations each, 4 per cycle)
    ///   - Rotation (days, 24 segments each)
    ///   - Segment (hours, 3600 seconds each)
    private func convertCalendarUnitsToDate(divisions: [TimeDivision], values: [Int], epoch: Date) -> Date {
        guard values.count == divisions.count else {
            print("⚠️ [SceneTemporalPositionEditor] Division count mismatch: \(divisions.count) divisions, \(values.count) values")
            return epoch
        }

        // For Imperial Meridian Calendar specifically:
        // Convert everything to segments (the base unit = 1 hour = 3600 seconds)

        // Find division indices by name
        var cycleValue = 0
        var seasonValue = 0
        var rotationValue = 0
        var segmentValue = 0

        for (index, division) in divisions.enumerated() {
            let value = values[index]
            let divName = division.name.lowercased()

            if divName == "epoch" {
                // Epochs are variable-length eras, typically not used in date calculation
                // We start from the epoch date itself
                continue
            } else if divName == "cycle" {
                cycleValue = value
            } else if divName == "season" {
                seasonValue = value
            } else if divName == "rotation" {
                rotationValue = value
            } else if divName == "segment" {
                segmentValue = value
            }
        }

        // Calculate total segments
        // 1 Cycle = 360 Rotations
        // 1 Season = 90 Rotations (but we add this to the cycle's rotations)
        // 1 Rotation = 24 Segments
        // 1 Segment = 3600 seconds

        var totalRotations = 0
        totalRotations += cycleValue * 360  // Cycles to rotations
        totalRotations += seasonValue * 90  // Seasons to rotations
        totalRotations += rotationValue     // Direct rotations

        var totalSegments = 0
        totalSegments += totalRotations * 24  // Rotations to segments
        totalSegments += segmentValue         // Direct segments

        let totalSeconds = TimeInterval(totalSegments) * 3600  // Segments to seconds

        print("📅 [SceneTemporalPositionEditor] Converting calendar date:")
        print("   Input: Cycle \(cycleValue), Season \(seasonValue), Rotation \(rotationValue), Segment \(segmentValue)")
        print("   → Total rotations: \(totalRotations)")
        print("   → Total segments: \(totalSegments)")
        print("   → Total seconds from epoch: \(totalSeconds)")
        print("   → Epoch date: \(epoch)")
        print("   → Result date: \(epoch.addingTimeInterval(totalSeconds))")

        return epoch.addingTimeInterval(totalSeconds)
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        // Update edge with new temporal position and duration
        if useCalendarInput {
            edge.temporalPosition = displayedCalculatedDate
            print("💾 [SceneTemporalPositionEditor] Saving calendar date: \(displayedCalculatedDate)")
            print("💾 [SceneTemporalPositionEditor] Calendar values: \(calendarDivisionValues)")
            if let formatted = timeline.calendarSystem != nil ? formatDateInCalendar(displayedCalculatedDate) : nil {
                print("💾 [SceneTemporalPositionEditor] As calendar: \(formatted)")
            }
        } else {
            edge.temporalPosition = temporalPosition
            print("💾 [SceneTemporalPositionEditor] Saving standard date: \(temporalPosition)")
        }
        edge.duration = duration
        print("💾 [SceneTemporalPositionEditor] Saving duration: \(duration) seconds")

        // Save context
        do {
            try modelContext.save()
            print("✅ [SceneTemporalPositionEditor] Context saved successfully")
        } catch {
            print("❌ [SceneTemporalPositionEditor] Failed to save context: \(error)")
        }

        dismiss()
    }

    private func clearPosition() {
        // Clear temporal position (revert to ordinal positioning)
        edge.temporalPosition = nil
        edge.duration = nil

        // Save context
        try? modelContext.save()

        dismiss()
    }
}

#Preview {
    let schema = Schema([Card.self, CardEdge.self, RelationType.self, CalendarSystem.self])
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let ctx = container.mainContext

    // Create test data
    let calendar = CalendarSystem.gregorian()
    ctx.insert(calendar)

    let timeline = Card(kind: .timelines, name: "Chapter 1", subtitle: "", detailedText: "")
    timeline.calendarSystem = calendar
    timeline.epochDate = Date()
    ctx.insert(timeline)

    let scene = Card(kind: .scenes, name: "Opening Scene", subtitle: "", detailedText: "")
    ctx.insert(scene)

    let relType = RelationType(
        code: "describes/described-by",
        forwardLabel: "describes",
        inverseLabel: "described by",
        sourceKind: .scenes,
        targetKind: .timelines
    )
    ctx.insert(relType)

    let edge = CardEdge(from: scene, to: timeline, type: relType)
    edge.temporalPosition = Date()
    edge.duration = 3600
    ctx.insert(edge)

    try? ctx.save()

    return SceneTemporalPositionEditor(scene: scene, timeline: timeline, edge: edge)
        .modelContainer(container)
}
