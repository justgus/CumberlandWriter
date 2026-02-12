//
//  SceneTemporalPositionEditor.swift
//  Cumberland
//
//  Part of ER-0008: Timeline System with Temporal Positioning.
//  Sheet editor for setting a scene's start position, duration, and temporal
//  unit on a specific Timeline card. Writes values to the CardEdge linking
//  the scene to the timeline. Presented from TimelineChartView.
//

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

    // DR-0090: Direct year/month/day entry for standard date mode
    @State private var inputYear: Int = 2025
    @State private var inputMonth: Int = 1
    @State private var inputDay: Int = 1
    @State private var inputHour: Int = 12
    @State private var inputMinute: Int = 0

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

    /// Resolved epoch: uses the timeline's explicit epoch, falling back to the
    /// calendar's standard epoch for well-known calendars (DR-0089)
    private var resolvedEpoch: Date? {
        timeline.epochDate ?? timeline.calendarSystem?.standardEpochDate
    }

    init(scene: Card, timeline: Card, edge: CardEdge) {
        print("🔷 [SceneTemporalPositionEditor] === INITIALIZING EDITOR ===")
        print("🔷 [SceneTemporalPositionEditor] Scene: \(scene.name) (ID: \(scene.id))")
        print("🔷 [SceneTemporalPositionEditor] Timeline: \(timeline.name) (ID: \(timeline.id))")
        print("🔷 [SceneTemporalPositionEditor] Edge exists: true")
        print("🔷 [SceneTemporalPositionEditor] Edge.temporalPosition: \(edge.temporalPosition?.description ?? "nil")")
        print("🔷 [SceneTemporalPositionEditor] Edge.duration: \(edge.duration?.description ?? "nil")")

        self.scene = scene
        self.timeline = timeline
        self.edge = edge

        // Initialize state from edge
        let initialPosition = edge.temporalPosition ?? Date()
        let initialDuration = edge.duration ?? 3600 // Default 1 hour

        print("🔷 [SceneTemporalPositionEditor] Initial position: \(initialPosition)")
        print("🔷 [SceneTemporalPositionEditor] Initial duration: \(initialDuration) seconds")

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

        print("🔷 [SceneTemporalPositionEditor] Duration in smallest units: \(max(1, units))")

        // Initialize calendar-aware input — for standard calendars, default to
        // standard date mode since users expect a normal date picker (DR-0089)
        let hasCalendar = timeline.calendarSystem != nil
        let isStandard = timeline.calendarSystem?.isStandardCalendar ?? false
        _useCalendarInput = State(initialValue: hasCalendar && !isStandard)

        print("🔷 [SceneTemporalPositionEditor] Has calendar: \(hasCalendar), isStandard: \(isStandard)")
        if let calendar = timeline.calendarSystem {
            print("🔷 [SceneTemporalPositionEditor] Calendar: \(calendar.name)")
            print("🔷 [SceneTemporalPositionEditor] Divisions: \(calendar.divisions.count)")
        }

        // DR-0089: Resolve epoch from explicit setting OR standard calendar default
        let resolvedEpoch = timeline.epochDate ?? timeline.calendarSystem?.standardEpochDate
        if let epoch = resolvedEpoch {
            print("🔷 [SceneTemporalPositionEditor] Resolved epoch: \(epoch)")
        } else {
            print("⚠️ [SceneTemporalPositionEditor] WARNING: No epoch available! Calendar conversion will not work!")
        }

        // Initialize division values (start with zeros, user will set them)
        let divisionCount = timeline.calendarSystem?.divisions.count ?? 0
        _calendarDivisionValues = State(initialValue: Array(repeating: 0, count: divisionCount))

        // Initialize displayed calculated date
        _displayedCalculatedDate = State(initialValue: initialPosition)

        // DR-0090: Initialize year/month/day/hour/minute from the initial position
        let cal = Foundation.Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: initialPosition)
        _inputYear = State(initialValue: comps.year ?? 2025)
        _inputMonth = State(initialValue: comps.month ?? 1)
        _inputDay = State(initialValue: comps.day ?? 1)
        _inputHour = State(initialValue: comps.hour ?? 12)
        _inputMinute = State(initialValue: comps.minute ?? 0)

        print("🔷 [SceneTemporalPositionEditor] === INITIALIZATION COMPLETE ===")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Temporal Position")
                    .font(.title2.bold())
                Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // Temporal Position Section
                Section {
                    // Toggle between calendar-aware and standard date input
                    // Only show the toggle for custom (non-standard) calendars.
                    // Standard calendars (Gregorian, Julian) use the Standard Date
                    // fields which handle variable-length months correctly.
                    if let cal = timeline.calendarSystem, !cal.isStandardCalendar {
                        Picker("Input Mode", selection: $useCalendarInput) {
                            Text("Custom Calendar").tag(true)
                            Text("Standard Date").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: useCalendarInput) { _, newValue in
                            print("📅 [SceneTemporalPositionEditor] Input mode changed to: \(newValue ? "Custom Calendar" : "Standard Date")")
                            if newValue, let calendar = timeline.calendarSystem, let epoch = resolvedEpoch {
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
                        // DR-0090: Direct year/month/day entry for historical dates
                        standardDateInputFields
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
                    if let epoch = resolvedEpoch {
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

                            TextField("1", value: $durationInSmallestUnit, format: .number.grouping(.never))
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
                            ), format: .number.grouping(.never))
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
            print("📅 [SceneTemporalPositionEditor] useCalendarInput: \(useCalendarInput)")
            print("📅 [SceneTemporalPositionEditor] Has calendar system: \(timeline.calendarSystem != nil)")
            print("📅 [SceneTemporalPositionEditor] Has resolved epoch: \(resolvedEpoch != nil)")

            if useCalendarInput, let calendar = timeline.calendarSystem, let epoch = resolvedEpoch {
                let calculated = convertCalendarUnitsToDate(divisions: calendar.divisions, values: newValues, epoch: epoch)
                displayedCalculatedDate = calculated
                temporalPosition = calculated
                print("📅 [SceneTemporalPositionEditor] Updated displayed date to: \(calculated)")
            } else {
                print("⚠️ [SceneTemporalPositionEditor] Cannot convert calendar date - missing epoch!")
                print("   - useCalendarInput: \(useCalendarInput)")
                print("   - calendar exists: \(timeline.calendarSystem != nil)")
                print("   - resolvedEpoch exists: \(resolvedEpoch != nil)")
            }
        }
    }

    // MARK: - Computed Properties

    private var calculatedTemporalPosition: Date {
        if useCalendarInput, let calendar = timeline.calendarSystem, let epoch = resolvedEpoch {
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

    /// Format date in calendar representation (DR-0091: generic implementation)
    private func formatDateInCalendar(_ date: Date) -> String {
        guard let calendar = timeline.calendarSystem, let epoch = resolvedEpoch else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        let divisions = calendar.divisions
        guard !divisions.isEmpty else {
            return date.formatted(date: .abbreviated, time: .shortened)
        }

        // Determine real-time duration of one smallest unit
        let smallestDivName = divisions[0].name.lowercased()
        let secondsPerSmallestUnit: TimeInterval
        switch smallestDivName {
        case "second", "seconds": secondsPerSmallestUnit = 1.0
        case "minute", "minutes": secondsPerSmallestUnit = 60.0
        case "hour", "hours": secondsPerSmallestUnit = 3600.0
        case "segment", "segments": secondsPerSmallestUnit = 3600.0
        default: secondsPerSmallestUnit = 1.0
        }

        let secondsSinceEpoch = date.timeIntervalSince(epoch)
        var remaining = Int(secondsSinceEpoch / secondsPerSmallestUnit)

        // Decompose from smallest to largest
        // divisions[i].length = how many of [i] in one [i+1]
        var divisionValues: [Int] = Array(repeating: 0, count: divisions.count)

        for i in 0..<(divisions.count - 1) {
            let length = divisions[i].length
            divisionValues[i] = remaining % length
            remaining = remaining / length
        }
        // Largest division gets whatever remains
        divisionValues[divisions.count - 1] = remaining

        // Format as "Division Value, Division Value, ..."
        // Show from largest to smallest
        var parts: [String] = []
        for i in stride(from: divisions.count - 1, through: 0, by: -1) {
            let name = divisions[i].name.capitalized
            parts.append("\(name) \(divisionValues[i])")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Standard Date Input (DR-0090)

    /// Direct year/month/day/time entry — replaces the graphical DatePicker
    /// that was unusable for historical dates spanning centuries
    @ViewBuilder
    private var standardDateInputFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Year
            HStack {
                Text("Year:")
                    .frame(width: 60, alignment: .leading)
                TextField("Year", value: $inputYear, format: .number.grouping(.never))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                Stepper("", value: $inputYear, in: 1...9999)
                    .labelsHidden()
            }

            // Month
            HStack {
                Text("Month:")
                    .frame(width: 60, alignment: .leading)
                Picker("Month", selection: $inputMonth) {
                    ForEach(1...12, id: \.self) { m in
                        Text(Foundation.Calendar(identifier: .gregorian)
                            .monthSymbols[m - 1])
                            .tag(m)
                    }
                }
                .labelsHidden()
                #if os(macOS)
                .pickerStyle(.menu)
                #else
                .pickerStyle(.menu)
                #endif
            }

            // Day
            HStack {
                Text("Day:")
                    .frame(width: 60, alignment: .leading)
                Picker("Day", selection: $inputDay) {
                    ForEach(1...daysInSelectedMonth, id: \.self) { d in
                        Text("\(d)").tag(d)
                    }
                }
                .labelsHidden()
                #if os(macOS)
                .pickerStyle(.menu)
                #else
                .pickerStyle(.menu)
                #endif
            }

            Divider()

            // Time
            HStack {
                Text("Time:")
                    .frame(width: 60, alignment: .leading)
                Picker("Hour", selection: $inputHour) {
                    ForEach(0...23, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .labelsHidden()
                .frame(width: 60)
                Text(":")
                Picker("Minute", selection: $inputMinute) {
                    ForEach(0...59, id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            }

            // Preview of assembled date
            if let assembled = assembledDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(assembled.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.top, 4)
            }
        }
        .onChange(of: inputYear) { _, _ in syncDateFromComponents() }
        .onChange(of: inputMonth) { _, newMonth in
            // Clamp day if needed when month changes
            let maxDay = daysInMonth(newMonth, year: inputYear)
            if inputDay > maxDay { inputDay = maxDay }
            syncDateFromComponents()
        }
        .onChange(of: inputDay) { _, _ in syncDateFromComponents() }
        .onChange(of: inputHour) { _, _ in syncDateFromComponents() }
        .onChange(of: inputMinute) { _, _ in syncDateFromComponents() }
    }

    /// Number of days in the currently selected month/year
    private var daysInSelectedMonth: Int {
        daysInMonth(inputMonth, year: inputYear)
    }

    private func daysInMonth(_ month: Int, year: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let cal = Foundation.Calendar(identifier: .gregorian)
        return cal.range(of: .day, in: .month, for: cal.date(from: comps) ?? Date())?.count ?? 30
    }

    /// Assemble a Date from the individual year/month/day/hour/minute fields
    private var assembledDate: Date? {
        var comps = DateComponents()
        comps.year = inputYear
        comps.month = inputMonth
        comps.day = inputDay
        comps.hour = inputHour
        comps.minute = inputMinute
        comps.second = 0
        return Foundation.Calendar(identifier: .gregorian).date(from: comps)
    }

    /// Sync the component fields back to `temporalPosition`
    private func syncDateFromComponents() {
        if let date = assembledDate {
            temporalPosition = date
        }
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
                    TextField("0", value: $calendarDivisionValues[index], format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)

                    Stepper("", value: $calendarDivisionValues[index], in: 0...10000)
                        .labelsHidden()
                }
            }
        }

        // Help text
        let exampleParts = calendar.divisions.suffix(3).reversed().map { "\($0.name.capitalized) 1" }
        let exampleText = exampleParts.joined(separator: ", ")
        Text("Enter values for each time division. For example: \(exampleText)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    // MARK: - Calendar Conversion (DR-0091: Generic implementation)

    /// Converts calendar division values to a Date based on the timeline's epoch.
    ///
    /// DR-0091: Rewritten to work generically with any calendar's divisions
    /// instead of being hardcoded for the Imperial Meridian Calendar.
    ///
    /// Divisions are ordered smallest-to-largest. Each division's `length` tells
    /// how many of that unit compose one of the next-larger unit. We accumulate
    /// from largest to smallest, then convert the total smallest-units to seconds.
    private func convertCalendarUnitsToDate(divisions: [TimeDivision], values: [Int], epoch: Date) -> Date {
        guard values.count == divisions.count else {
            print("⚠️ [SceneTemporalPositionEditor] Division count mismatch: \(divisions.count) divisions, \(values.count) values")
            return epoch
        }

        guard !divisions.isEmpty else { return epoch }

        // Accumulate from largest division down to smallest.
        // Each division's `length` = how many of THIS unit fit into one of the NEXT LARGER unit.
        // Walking from largest (last) to smallest (first):
        //   running total = value[i] + running_total * divisions[i].length
        // After processing all divisions, we have total count of the smallest unit.

        // Process divisions from largest (last index) to smallest (index 0)
        var totalSmallestUnits: Double = 0

        for i in stride(from: divisions.count - 1, through: 0, by: -1) {
            let value = Double(values[i])
            if i < divisions.count - 1 {
                // Multiply accumulated total by this division's length to convert
                // from "next larger" units down to this level
                totalSmallestUnits = totalSmallestUnits * Double(divisions[i + 1].length) + value
            } else {
                // Largest division — just start with its value
                // But we need to convert it to the next-smaller unit using its own length
                // Actually, for the largest unit, we just take the value and will multiply down
                totalSmallestUnits = value
            }
        }

        // Wait — the above is walking from largest to smallest but the multiplication
        // needs to go: accumulate = accumulate * length_of_current + value_of_current
        // Let me reconsider. Divisions[0] is smallest. Divisions[last] is largest.
        // Each divisions[i].length = how many of divisions[i] compose one of divisions[i+1].
        //
        // Example: [second(60), minute(60), hour(24), day(365), year(1)]
        //   Values: [30, 15, 8, 100, 2]
        //   Total seconds = 2*(365*24*60*60) + 100*(24*60*60) + 8*(60*60) + 15*60 + 30
        //
        // Walking from largest to smallest:
        //   acc = 2  (years)
        //   acc = 2 * 365 + 100 = 830  (days)
        //   acc = 830 * 24 + 8 = 19928  (hours)
        //   acc = 19928 * 60 + 15 = 1195695  (minutes)
        //   acc = 1195695 * 60 + 30 = 71741730  (seconds)
        //
        // At each step, multiply by divisions[i].length (the length of the CURRENT level,
        // which tells us how many of current-level units fit in one of the next-larger)
        // Actually no. divisions[i].length is how many of [i] compose one [i+1].
        // So to go from next-larger count to current count: multiply by divisions[i].length.

        // Redo: walk from largest (index N-1) down to smallest (index 0)
        totalSmallestUnits = 0
        for i in stride(from: divisions.count - 1, through: 0, by: -1) {
            let value = Double(values[i])

            if i == divisions.count - 1 {
                // Start with the largest division's value
                totalSmallestUnits = value
            } else {
                // Convert accumulated total from [i+1]-level units to [i]-level units
                // divisions[i].length = how many of [i] in one [i+1]
                totalSmallestUnits = totalSmallestUnits * Double(divisions[i].length) + value
            }
        }

        // Now totalSmallestUnits is in the smallest division's units.
        // Determine real-time duration of one smallest unit.
        let smallestDivName = divisions[0].name.lowercased()
        let secondsPerSmallestUnit: TimeInterval
        switch smallestDivName {
        case "second", "seconds":
            secondsPerSmallestUnit = 1.0
        case "minute", "minutes":
            secondsPerSmallestUnit = 60.0
        case "hour", "hours":
            secondsPerSmallestUnit = 3600.0
        case "segment", "segments":
            // Legacy: Imperial Meridian Calendar convention (1 segment = 1 hour)
            secondsPerSmallestUnit = 3600.0
        default:
            // For unknown smallest units, assume 1 second per unit
            secondsPerSmallestUnit = 1.0
        }

        let totalSeconds = totalSmallestUnits * secondsPerSmallestUnit

        print("📅 [SceneTemporalPositionEditor] Converting calendar date (generic):")
        print("   Input values: \(values)")
        print("   Division names: \(divisions.map { $0.name })")
        print("   Division lengths: \(divisions.map { $0.length })")
        print("   → Total smallest units (\(divisions[0].name)): \(totalSmallestUnits)")
        print("   → Seconds per \(divisions[0].name): \(secondsPerSmallestUnit)")
        print("   → Total seconds from epoch: \(totalSeconds)")
        print("   → Epoch date: \(epoch)")
        print("   → Result date: \(epoch.addingTimeInterval(totalSeconds))")

        return epoch.addingTimeInterval(totalSeconds)
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        print("💾 [SceneTemporalPositionEditor] === SAVE OPERATION STARTED ===")
        print("💾 [SceneTemporalPositionEditor] Scene: \(scene.name) (ID: \(scene.id))")
        print("💾 [SceneTemporalPositionEditor] Timeline: \(timeline.name) (ID: \(timeline.id))")
        print("💾 [SceneTemporalPositionEditor] Edge reference is non-optional and present")
        print("💾 [SceneTemporalPositionEditor] Edge context: \(edge.modelContext != nil ? "has context" : "NO CONTEXT")")
        print("💾 [SceneTemporalPositionEditor] Save context: \(modelContext)")

        // Update edge with new temporal position and duration
        if useCalendarInput {
            print("💾 [SceneTemporalPositionEditor] Using calendar input mode")
            print("💾 [SceneTemporalPositionEditor] Calendar values: \(calendarDivisionValues)")
            print("💾 [SceneTemporalPositionEditor] Calculated date: \(displayedCalculatedDate)")

            if resolvedEpoch == nil {
                print("⚠️⚠️⚠️ [SceneTemporalPositionEditor] CRITICAL: No resolved epoch available!")
                print("⚠️⚠️⚠️ [SceneTemporalPositionEditor] Calendar conversion cannot work without an epoch!")
                print("⚠️⚠️⚠️ [SceneTemporalPositionEditor] Please set the timeline's epoch date on its back face.")
            } else {
                print("💾 [SceneTemporalPositionEditor] Resolved epoch: \(resolvedEpoch!)")
            }

            if let formatted = timeline.calendarSystem != nil ? formatDateInCalendar(displayedCalculatedDate) : nil {
                print("💾 [SceneTemporalPositionEditor] As calendar: \(formatted)")
            }

            let oldPosition = edge.temporalPosition
            edge.temporalPosition = displayedCalculatedDate
            print("💾 [SceneTemporalPositionEditor] Position changed: \(oldPosition ?? Date()) → \(displayedCalculatedDate)")
        } else {
            print("💾 [SceneTemporalPositionEditor] Using standard date input mode")
            print("💾 [SceneTemporalPositionEditor] Standard date: \(temporalPosition)")

            let oldPosition = edge.temporalPosition
            edge.temporalPosition = temporalPosition
            print("💾 [SceneTemporalPositionEditor] Position changed: \(oldPosition ?? Date()) → \(temporalPosition)")
        }

        let oldDuration = edge.duration
        edge.duration = duration
        print("💾 [SceneTemporalPositionEditor] Duration changed: \(oldDuration ?? 0) → \(duration) seconds")

        // Verify the changes were applied
        print("💾 [SceneTemporalPositionEditor] Edge.temporalPosition after assignment: \(edge.temporalPosition ?? Date())")
        print("💾 [SceneTemporalPositionEditor] Edge.duration after assignment: \(edge.duration ?? 0)")

        // Save context
        do {
            try modelContext.save()
            print("✅ [SceneTemporalPositionEditor] Context saved successfully")
            print("✅ [SceneTemporalPositionEditor] Edge.temporalPosition after save: \(edge.temporalPosition ?? Date())")
            print("✅ [SceneTemporalPositionEditor] Edge.duration after save: \(edge.duration ?? 0)")
        } catch {
            print("❌ [SceneTemporalPositionEditor] Failed to save context: \(error)")
        }

        print("💾 [SceneTemporalPositionEditor] === SAVE OPERATION COMPLETE ===")
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

