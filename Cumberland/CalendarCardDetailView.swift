//
//  CalendarCardDetailView.swift
//  Cumberland
//
//  Created by Claude Code on 1/27/26.
//  Phase 7.5: Calendar Cards Architecture
//

import SwiftUI
import SwiftData

struct CalendarCardDetailView: View {
    @Bindable var card: Card
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: CalendarTab = .details

    enum CalendarTab: String, CaseIterable {
        case details = "Details"
        case timelines = "Timelines"
        case multiTimeline = "Multi-Timeline"

        var icon: String {
            switch self {
            case .details: return "info.circle"
            case .timelines: return "list.bullet"
            case .multiTimeline: return "chart.line.uptrend.xyaxis"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Tab", selection: $selectedTab) {
                ForEach(CalendarTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .details:
                    detailsTab
                case .timelines:
                    timelinesTab
                case .multiTimeline:
                    multiTimelineTab
                }
            }
        }
        .navigationTitle(card.name)
    }

    // MARK: - Details Tab

    private var detailsTab: some View {
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
                    Button("Create Calendar System") {
                        let newSystem = CalendarSystem(name: card.name)
                        modelContext.insert(newSystem)
                        card.calendarSystemRef = newSystem
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    // MARK: - Timelines Tab

    @Query private var allTimelines: [Card]

    private var timelinesUsingThisCalendar: [Card] {
        guard let calendar = card.calendarSystemRef else { return [] }
        return allTimelines.filter { timeline in
            timeline.kind == .timelines && timeline.calendarSystem == calendar
        }
    }

    private var timelinesTab: some View {
        Group {
            if timelinesUsingThisCalendar.isEmpty {
                ContentUnavailableView(
                    "No Timelines",
                    systemImage: "calendar.badge.clock",
                    description: Text("No timelines are currently using this calendar system.")
                )
            } else {
                List {
                    ForEach(timelinesUsingThisCalendar) { timeline in
                        NavigationLink(value: timeline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timeline.name)
                                    .font(.headline)
                                if !timeline.subtitle.isEmpty {
                                    Text(timeline.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Multi-Timeline Tab (Phase 8 Placeholder)

    private var multiTimelineTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Multi-Timeline Graph")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Coming in Phase 8")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This tab will show all timelines using this calendar on a synchronized graph.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 8) {
                Text("Timelines using this calendar:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if timelinesUsingThisCalendar.isEmpty {
                    Text("No timelines yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(timelinesUsingThisCalendar) { timeline in
                        Label(timeline.name, systemImage: "calendar")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}
