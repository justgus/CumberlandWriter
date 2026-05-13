//
//  CalendarSystemCleanupView.swift
//  Cumberland
//
//  Developer tool (DR-0065) for manually repairing broken CalendarSystem
//  relationship data. Invokes CalendarSystemCleanup.fixAll() and displays
//  a report of how many records were repaired. Manual execution only —
//  not run automatically for end users.
//

import SwiftUI
import SwiftData

/// Developer tool for fixing broken CalendarSystem relationships (DR-0065)
/// Manual execution only - should not run automatically for all users
@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
struct CalendarSystemCleanupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isRunning = false
    @State private var report = ""
    @State private var calendarCount = 0
    @State private var fixedCount = 0
    @State private var hasError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Label("Fix CalendarSystem Relationships (DR-0065)", systemImage: "calendar.badge.exclamationmark")
                    .font(.title3.bold())

                Text("This tool fixes CalendarSystem objects created before the DR-0065 fix by recreating them with proper SwiftData relationship structure.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("⚠️ Only run this if you have existing calendar cards that crash when deleted.")
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            }

            Divider()

            // Statistics
            if calendarCount > 0 || fixedCount > 0 {
                HStack(spacing: 24) {
                    statView(title: "Calendars Found", value: calendarCount, color: .secondary)
                    statView(title: "Recreated", value: fixedCount, color: .green)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Actions
            HStack(spacing: 12) {
                Button {
                    Task { await diagnose() }
                } label: {
                    Label("Diagnose", systemImage: "stethoscope")
                }
                .disabled(isRunning)

                Button {
                    Task { await runFix() }
                } label: {
                    Label("Fix Relationships", systemImage: "wrench.and.screwdriver.fill")
                }
                .disabled(isRunning || calendarCount == 0)
                .buttonStyle(.borderedProminent)

                Button {
                    report = ""
                    calendarCount = 0
                    fixedCount = 0
                    hasError = false
                    errorMessage = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(isRunning || report.isEmpty)

                Spacer()

                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                }

                if !report.isEmpty {
                    Button {
                        copyToClipboard(report)
                    } label: {
                        Label("Copy Report", systemImage: "doc.on.doc")
                    }
                }
            }

            // Error display
            if hasError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Report
            GroupBox("Report") {
                ScrollView {
                    Text(report.isEmpty ? "Click 'Diagnose' to check for broken calendars, or 'Fix Relationships' to repair them." : report)
                        .textSelection(.enabled)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .frame(minHeight: 300)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
    }

    private func statView(title: String, value: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
        }
    }

    // MARK: - Actions

    @MainActor
    private func diagnose() async {
        isRunning = true
        hasError = false
        defer { isRunning = false }

        var lines: [String] = []
        lines.append("=== CalendarSystem Relationship Diagnostics ===")
        lines.append("Date: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")

        do {
            let descriptor = FetchDescriptor<CalendarSystem>()
            let calendars = try modelContext.fetch(descriptor)

            calendarCount = calendars.count
            lines.append("Found \(calendars.count) calendar system(s):")
            lines.append("")

            for calendar in calendars {
                lines.append("📅 \(calendar.name)")
                lines.append("   ID: \(calendar.id)")
                lines.append("   Divisions: \(calendar.divisions.count)")

                if let card = calendar.calendarCard {
                    lines.append("   Owning card: \(card.name) (ID: \(card.id))")
                } else {
                    lines.append("   Owning card: NONE ⚠️")
                }

                let timelineCount = calendar.timelines?.count ?? 0
                lines.append("   Used by timelines: \(timelineCount)")

                if let timelines = calendar.timelines, !timelines.isEmpty {
                    for timeline in timelines {
                        lines.append("      - \(timeline.name)")
                    }
                }

                lines.append("")
            }

            lines.append("--- Analysis ---")
            if calendars.isEmpty {
                lines.append("✅ No calendars found - nothing to fix")
            } else {
                lines.append("ℹ️ Found \(calendars.count) calendar(s)")
                lines.append("ℹ️ These may have broken relationships if created before DR-0065 fix")
                lines.append("ℹ️ Click 'Fix Relationships' to recreate them with proper structure")
            }

        } catch {
            hasError = true
            errorMessage = "Failed to diagnose: \(error.localizedDescription)"
            lines.append("❌ ERROR: \(error.localizedDescription)")
        }

        report = lines.joined(separator: "\n")
    }

    @MainActor
    private func runFix() async {
        isRunning = true
        hasError = false
        defer { isRunning = false }

        var lines: [String] = []
        lines.append("=== Fix CalendarSystem Relationships ===")
        lines.append("Date: \(Date().formatted(date: .abbreviated, time: .standard))")
        lines.append("")

        do {
            let count = try CalendarSystemCleanup.fixExistingCalendarRelationships(context: modelContext)

            fixedCount = count
            lines.append("✅ Successfully recreated \(count) calendar system(s)")
            lines.append("")
            lines.append("--- What Happened ---")
            lines.append("1. Collected data from \(count) existing calendars")
            lines.append("2. Broke all relationships (set to nil)")
            lines.append("3. Deleted old CalendarSystem objects")
            lines.append("4. Created new CalendarSystem objects with same data")
            lines.append("5. Restored relationships with proper SwiftData structure")
            lines.append("")
            lines.append("✅ Your calendars can now be deleted without crashing!")

        } catch {
            hasError = true
            errorMessage = "Failed to fix relationships: \(error.localizedDescription)"
            lines.append("❌ ERROR: \(error.localizedDescription)")
            lines.append("")
            lines.append("The fix failed. Your data is unchanged.")
        }

        report = lines.joined(separator: "\n")
    }

    private func copyToClipboard(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
    }
}

#Preview {
    CalendarSystemCleanupView()
        .modelContainer(for: CalendarSystem.self, inMemory: true)
}
