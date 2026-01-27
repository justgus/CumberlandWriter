//
//  CalendarSystemEditor.swift
//  Cumberland
//
//  Created by Claude Code on 1/24/26.
//  ER-0008: Calendar System Editor - Phase 4B
//

import SwiftUI
import SwiftData

/// Editor for creating and modifying calendar systems
/// Part of ER-0008 Phase 4B: Calendar Editor & Epoch UI
struct CalendarSystemEditor: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    /// The calendar being edited (nil for new calendar)
    let calendar: CalendarSystem?

    /// Whether this is creating a new calendar
    private var isCreating: Bool {
        calendar == nil
    }

    // MARK: - State

    @State private var name: String
    @State private var calendarDescription: String
    @State private var divisions: [TimeDivision]
    @State private var validationError: String?
    @State private var showDeleteConfirmation = false

    // MARK: - Initialization

    init(calendar: CalendarSystem? = nil) {
        self.calendar = calendar

        // Initialize state from calendar or defaults
        _name = State(initialValue: calendar?.name ?? "")
        _calendarDescription = State(initialValue: calendar?.calendarDescription ?? "")
        _divisions = State(initialValue: calendar?.divisions ?? [])
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calendar Information")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        TextField("Calendar Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)

                        TextField("Description (optional)", text: $calendarDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Divisions Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Time Divisions")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Smallest → Largest")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        if divisions.isEmpty {
                            emptyDivisionsView
                        } else {
                            ForEach(divisions.indices, id: \.self) { index in
                                DivisionRow(
                                    division: $divisions[index],
                                    hierarchyLevel: index
                                )
                            }
                            .onMove(perform: moveDivisions)
                            .onDelete(perform: deleteDivisions)
                        }

                        Button {
                            addDivision()
                        } label: {
                            Label("Add Time Division", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.bordered)

                        Text("Divisions are ordered from smallest (e.g., second) to largest (e.g., year). Each division's length indicates how many of the previous division it contains.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Validation Section
                    if let error = validationError {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Validation")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Label {
                                Text(error)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Preview Section
                    if !divisions.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            calendarPreview
                        }
                        .padding(.horizontal)
                    }

                    // Bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.vertical)
            }
            .navigationTitle(isCreating ? "New Calendar" : "Edit Calendar")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreating ? "Create" : "Save") {
                        save()
                    }
                    .disabled(!canSave)
                }

                #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    if !isCreating {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                #endif
            }
            .alert("Delete Calendar?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCalendar()
                }
            } message: {
                Text("This will remove the calendar. Timelines using this calendar will revert to ordinal mode.")
            }
        }
        .frame(maxWidth: 700, maxHeight: 700)
        #if !os(macOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        #endif
        .onChange(of: name) { validateCalendar() }
        .onChange(of: divisions) { validateCalendar() }
    }

    // MARK: - Subviews

    /// Empty state for divisions list
    private var emptyDivisionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No Time Divisions")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Add divisions to define your calendar structure")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    /// Preview of calendar structure
    private var calendarPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structure")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            ForEach(divisions.indices, id: \.self) { index in
                let division = divisions[index]
                HStack(spacing: 8) {
                    // Indent based on hierarchy
                    ForEach(0..<index, id: \.self) { _ in
                        Text("  ")
                    }

                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)

                    Text("1 \(division.name)")
                        .font(.caption)

                    if index > 0 {
                        Text("=")
                            .foregroundStyle(.tertiary)
                        Text("\(division.length) \(divisions[index - 1].pluralName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if division.isVariable {
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .help("Variable length")
                        }
                    }
                }
            }

            if let total = calculateTotalUnits() {
                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("Total:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    if let smallest = divisions.first, let largest = divisions.last {
                        Text("\(total) \(smallest.pluralName) per \(largest.name)")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Actions

    /// Add a new time division
    private func addDivision() {
        let newDivision = TimeDivision(
            name: "",
            pluralName: "",
            length: 1,
            isVariable: false
        )
        divisions.append(newDivision)
    }

    /// Move divisions (reorder)
    private func moveDivisions(from source: IndexSet, to destination: Int) {
        divisions.move(fromOffsets: source, toOffset: destination)
    }

    /// Delete divisions
    private func deleteDivisions(at offsets: IndexSet) {
        divisions.remove(atOffsets: offsets)
    }

    /// Validate current calendar state
    private func validateCalendar() {
        // Name required
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationError = "Calendar name is required"
            return
        }

        // At least one division required
        guard !divisions.isEmpty else {
            validationError = "Calendar must have at least one time division"
            return
        }

        // Check for duplicate division names
        let names = divisions.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let uniqueNames = Set(names)
        if names.count != uniqueNames.count {
            validationError = "Calendar has duplicate division names"
            return
        }

        // Check for empty division names
        for (index, division) in divisions.enumerated() {
            if division.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationError = "Division \(index + 1) has no name"
                return
            }
            if division.pluralName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationError = "Division '\(division.name)' has no plural name"
                return
            }
        }

        // Check for reasonable division lengths
        for division in divisions {
            if division.length < 1 {
                validationError = "Division '\(division.name)' has invalid length: \(division.length)"
                return
            }
            if division.length > 10000 {
                validationError = "Division '\(division.name)' length is unreasonably large: \(division.length)"
                return
            }
        }

        // All valid
        validationError = nil
    }

    /// Calculate total smallest units in largest unit
    private func calculateTotalUnits() -> Int? {
        guard divisions.count >= 2 else {
            return nil
        }

        var total = 1
        for division in divisions.dropFirst() {
            total *= division.length
        }

        return total
    }

    /// Whether save button should be enabled
    private var canSave: Bool {
        validationError == nil &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !divisions.isEmpty
    }

    /// Save calendar
    private func save() {
        guard canSave else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = calendarDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if let calendar = calendar {
            // Update existing calendar
            calendar.name = trimmedName
            calendar.calendarDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            calendar.divisions = divisions
            calendar.modifiedAt = Date()
        } else {
            // Create new calendar
            let newCalendar = CalendarSystem(
                name: trimmedName,
                divisions: divisions
            )
            newCalendar.calendarDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            modelContext.insert(newCalendar)
        }

        dismiss()
    }

    /// Delete calendar
    private func deleteCalendar() {
        guard let calendar = calendar else { return }
        modelContext.delete(calendar)
        dismiss()
    }
}

// MARK: - Division Row

/// Row for editing a single time division
private struct DivisionRow: View {

    @Binding var division: TimeDivision
    let hierarchyLevel: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Hierarchy indicator
                Text("\(hierarchyLevel + 1).")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)

                // Name fields
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Singular (e.g., day)", text: $division.name)
                        .textFieldStyle(.plain)
                        .font(.body)

                    TextField("Plural (e.g., days)", text: $division.pluralName)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                // Length field
                HStack(spacing: 4) {
                    Text("Contains:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Stepper(
                        value: $division.length,
                        in: 1...10000,
                        step: 1
                    ) {
                        Text("\(division.length)")
                            .font(.body.monospacedDigit())
                    }

                    if hierarchyLevel > 0 {
                        Text("units")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Variable toggle
                Toggle(isOn: $division.isVariable) {
                    HStack(spacing: 4) {
                        Image(systemName: division.isVariable ? "waveform" : "minus")
                            .font(.caption)
                        Text("Variable")
                            .font(.caption)
                    }
                }
                .toggleStyle(.button)
                .help(division.isVariable ? "Length varies (e.g., months)" : "Fixed length")
            }
            .padding(.leading, 32)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("New Calendar") {
    CalendarSystemEditor()
        .modelContainer(for: CalendarSystem.self, inMemory: true)
}

#Preview("Edit Gregorian") {
    CalendarSystemEditor(calendar: .gregorian())
        .modelContainer(for: CalendarSystem.self, inMemory: true)
}

#Preview("Fantasy Calendar") {
    let calendar = CalendarSystem(
        name: "Eldarian",
        divisions: [
            TimeDivision(name: "moment", pluralName: "moments", length: 100, isVariable: false),
            TimeDivision(name: "cycle", pluralName: "cycles", length: 10, isVariable: false),
            TimeDivision(name: "day", pluralName: "days", length: 5, isVariable: false),
            TimeDivision(name: "moon", pluralName: "moons", length: 13, isVariable: true),
            TimeDivision(name: "year", pluralName: "years", length: 100, isVariable: false),
            TimeDivision(name: "age", pluralName: "ages", length: 1, isVariable: false)
        ]
    )
    calendar.calendarDescription = "The Eldarian calendar uses a base-5 and base-10 system"

    return CalendarSystemEditor(calendar: calendar)
        .modelContainer(for: CalendarSystem.self, inMemory: true)
}
#endif
