//
//  CardEditorTimelineSection.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Timeline configuration panel for Timeline cards
struct CardEditorTimelineSection: View {

    @Bindable var viewModel: CardEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.vertical, 2)

            // Calendar system selection
            CalendarSystemPicker(selection: $viewModel.selectedCalendar)

            // Epoch date configuration (only show if calendar is selected)
            if viewModel.selectedCalendar != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Epoch Date (Required for calendar conversion)")
                        .font(.subheadline.bold())

                    DatePicker("Epoch Date", selection: Binding(
                        get: {
                            viewModel.epochDate ?? Date()
                        },
                        set: { newValue in
                            viewModel.epochDate = newValue
                        }
                    ), displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)

                    if viewModel.epochDate == nil {
                        Text("⚠️ Warning: No epoch date set. Calendar temporal positioning will not work.")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    TextField("Epoch Description (optional)", text: $viewModel.epochDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)

                    Text("The epoch is the starting point/zero-date for this timeline. Example: Jan 1, 1847")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Calendar configuration panel for Calendar cards (Phase 7.5)
struct CardEditorCalendarSection: View {

    @Bindable var viewModel: CardEditorViewModel
    let cardName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().padding(.vertical, 2)

            if let calendarSystem = viewModel.selectedCalendar {
                CalendarSystemEditor(calendar: calendarSystem)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No calendar system attached.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        let newSystem = CalendarSystem(name: cardName)
                        viewModel.selectedCalendar = newSystem
                    } label: {
                        Label("Create Calendar System", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
