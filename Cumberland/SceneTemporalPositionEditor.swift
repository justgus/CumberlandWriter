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

    // Custom duration input
    @State private var customDays: Int = 0
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0

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

        // Break down duration into days/hours/minutes for custom input
        let days = Int(initialDuration / 86400)
        let hours = Int((initialDuration.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((initialDuration.truncatingRemainder(dividingBy: 3600)) / 60)

        _customDays = State(initialValue: days)
        _customHours = State(initialValue: hours)
        _customMinutes = State(initialValue: minutes)
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

            Form {
                // Temporal Position Section
                Section {
                    // Date picker (graphical calendar)
                    DatePicker(
                        "Date",
                        selection: $temporalPosition,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)

                    // Time picker (separate for better UX)
                    DatePicker(
                        "Time",
                        selection: $temporalPosition,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)

                    Divider()

                    // Show end time
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
                    Picker("Duration Preset", selection: $selectedPreset) {
                        ForEach(DurationPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .onChange(of: selectedPreset) { _, newValue in
                        if let interval = newValue.timeInterval {
                            duration = interval
                            useCustomDuration = false
                        } else {
                            useCustomDuration = true
                        }
                    }

                    // Custom duration input
                    if selectedPreset == .custom {
                        HStack {
                            Stepper("Days: \(customDays)", value: $customDays, in: 0...365)
                            Spacer()
                        }

                        HStack {
                            Stepper("Hours: \(customHours)", value: $customHours, in: 0...23)
                            Spacer()
                        }

                        HStack {
                            Stepper("Minutes: \(customMinutes)", value: $customMinutes, in: 0...59)
                            Spacer()
                        }

                        Text("Total: \(formattedDuration)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Duration: \(formattedDuration)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Duration", systemImage: "clock")
                } footer: {
                    Text("How long does this scene last?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

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
        .onChange(of: customDays) { _, _ in updateCustomDuration() }
        .onChange(of: customHours) { _, _ in updateCustomDuration() }
        .onChange(of: customMinutes) { _, _ in updateCustomDuration() }
    }

    // MARK: - Computed Properties

    private var endTime: Date {
        temporalPosition.addingTimeInterval(duration)
    }

    private var formattedDuration: String {
        let totalSeconds = selectedPreset == .custom ? customDuration : duration

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

    private var customDuration: TimeInterval {
        TimeInterval(customDays * 86400 + customHours * 3600 + customMinutes * 60)
    }

    // MARK: - Actions

    private func updateCustomDuration() {
        if selectedPreset == .custom {
            duration = customDuration
        }
    }

    private func saveAndDismiss() {
        // Update edge with new temporal position and duration
        edge.temporalPosition = temporalPosition
        edge.duration = duration

        // Save context
        try? modelContext.save()

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
