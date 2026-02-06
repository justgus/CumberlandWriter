//
//  CalendarSystemPicker.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI
import SwiftData

/// Picker view for selecting a CalendarSystem from available options
/// Phase 7.5: Now uses Calendar cards instead of standalone CalendarSystem objects
struct CalendarSystemPicker: View {
    @Binding var selection: CalendarSystem?
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Card> { $0.kindRaw == "Calendars" }, sort: \Card.name, order: .forward)
    private var calendarCards: [Card]

    // Extract calendar systems from cards
    private var calendars: [CalendarSystem] {
        calendarCards.compactMap { $0.calendarSystemRef }
    }

    @State private var showCalendarEditor = false
    @State private var calendarToEdit: CalendarSystem?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Calendar System", systemImage: "calendar")
                    .font(.subheadline.bold())

                Spacer()

                // Create new calendar button
                Button {
                    calendarToEdit = nil
                    showCalendarEditor = true
                } label: {
                    Label("New", systemImage: "plus.circle")
                        .labelStyle(.iconOnly)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Create a new calendar system")
            }

            if calendars.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No calendar systems available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        calendarToEdit = nil
                        showCalendarEditor = true
                    } label: {
                        Label("Create Calendar", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                }
            } else {
                Picker("Calendar", selection: $selection) {
                    Text("None (Ordinal Timeline)")
                        .tag(nil as CalendarSystem?)

                    ForEach(calendars) { calendar in
                        Text(calendar.name)
                            .tag(calendar as CalendarSystem?)
                    }
                }
                #if os(macOS)
                .pickerStyle(.menu)
                #else
                .pickerStyle(.navigationLink)
                #endif

                if let selected = selection {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            if let description = selected.calendarDescription {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle")
                                        .font(.caption2)
                                    Text(description)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }

                            Text("\(selected.divisions.count) divisions")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Button {
                            calendarToEdit = selected
                            showCalendarEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil.circle")
                                .labelStyle(.iconOnly)
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Edit this calendar system")
                    }
                }
            }
        }
        .sheet(isPresented: $showCalendarEditor) {
            CalendarSystemEditor(calendar: calendarToEdit)
        }
    }
}
