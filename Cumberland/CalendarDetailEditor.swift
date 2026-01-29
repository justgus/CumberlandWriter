//
//  CalendarDetailEditor.swift
//  Cumberland
//
//  Created by Claude Code on 2026-01-28.
//  Phase 8: Calendar Detail Editor for MainAppView Tab 1
//

import SwiftUI
import SwiftData

/// Detail editor for Calendar cards, displayed in MainAppView Tab 1
struct CalendarDetailEditor: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Basic info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Calendar Name", text: $card.name)
                        .textFieldStyle(.roundedBorder)

                    Text("Subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Brief description", text: $card.subtitle)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                // Calendar system editor
                if let calendarSystem = card.calendarSystemRef {
                    CalendarSystemEditor(calendar: calendarSystem)
                } else {
                    // Create new calendar system
                    VStack(spacing: 12) {
                        Label("No Calendar System", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        Text("This calendar card needs a calendar system to define time divisions and structure.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Create Calendar System") {
                            let newSystem = CalendarSystem(name: card.name)
                            modelContext.insert(newSystem)
                            card.calendarSystemRef = newSystem
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
            }
            .padding()
        }
    }
}
