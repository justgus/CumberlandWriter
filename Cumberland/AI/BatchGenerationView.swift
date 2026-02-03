//
//  BatchGenerationView.swift
//  Cumberland
//
//  Created by Claude Code on 2/2/26.
//  ER-0017 Phase 1: Batch Image Generation Queue UI
//

import SwiftUI
import SwiftData

/// View for displaying and controlling batch image generation
struct BatchGenerationView: View {

    // MARK: - Properties

    /// The batch generation queue
    @Bindable var queue: BatchGenerationQueue

    /// Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            if queue.tasks.isEmpty {
                emptyState
            } else {
                contentSection
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 400, idealHeight: 500)
        .navigationTitle("Batch Image Generation")
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        #endif
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and statistics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generating Images")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(queue.result.displaySummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Queue controls
                HStack(spacing: 12) {
                    if queue.canStart {
                        Button {
                            Task {
                                await queue.start()
                            }
                        } label: {
                            Label("Start", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if queue.canPause {
                        Button {
                            queue.pause()
                        } label: {
                            Label("Pause", systemImage: "pause.fill")
                        }
                    }

                    if queue.canResume {
                        Button {
                            Task {
                                await queue.resume()
                            }
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if queue.canCancel {
                        Button(role: .destructive) {
                            queue.cancel()
                        } label: {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                        }
                    }

                    if (queue.state == .completed || queue.state == .cancelled) && queue.failedCount > 0 {
                        Button {
                            Task {
                                await queue.retryFailed()
                            }
                        } label: {
                            Label("Retry Failed", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            // Progress bar
            if queue.totalTasks > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: queue.progress) {
                        HStack {
                            Text("\(queue.completedCount + queue.failedCount + queue.cancelledCount) of \(queue.totalTasks)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            if queue.isRunning {
                                Text("\(queue.remainingCount) remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .progressViewStyle(.linear)

                    // Statistics
                    HStack(spacing: 16) {
                        if queue.completedCount > 0 {
                            Label("\(queue.completedCount) completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }

                        if queue.failedCount > 0 {
                            Label("\(queue.failedCount) failed", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        if queue.cancelledCount > 0 {
                            Label("\(queue.cancelledCount) cancelled", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let avgTime = queue.result.averageTime, queue.completedCount > 0 {
                            Text("Avg: \(formatDuration(avgTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }

    // MARK: - Content Section

    private var contentSection: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(Array(queue.tasks.enumerated()), id: \.element.id) { index, task in
                    TaskRowView(task: task, index: index + 1)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Cards Selected")
                .font(.title3)
                .fontWeight(.medium)

            Text("Select cards from the list view and choose \"Generate Images for Selected\" to begin batch generation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

// MARK: - Task Row View

private struct TaskRowView: View {
    let task: BatchGenerationQueue.BatchTask
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)

            // Status icon
            statusIcon
                .frame(width: 20)

            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(task.card.name)
                    .font(.body)
                    .lineLimit(1)

                Text(task.prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Status and time
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge

                if let elapsed = task.elapsedTime {
                    Text(formatDuration(elapsed))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(rowBackground)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch task.status {
        case .queued:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .generating:
            ProgressView()
                .controlSize(.small)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .cancelled:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch task.status {
        case .queued:
            Text("Queued")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        case .generating:
            Text("Generating...")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .foregroundStyle(.blue)
                .cornerRadius(4)
        case .completed:
            Text("Completed")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundStyle(.green)
                .cornerRadius(4)
        case .failed(let error):
            Text("Failed")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .foregroundStyle(.orange)
                .cornerRadius(4)
                .help(error)
        case .cancelled:
            Text("Cancelled")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }

    private var rowBackground: Color {
        switch task.status {
        case .generating:
            return Color.blue.opacity(0.05)
        case .completed:
            return Color.green.opacity(0.05)
        case .failed:
            return Color.orange.opacity(0.05)
        default:
            return Color.clear
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct BatchGenerationView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        let queue = BatchGenerationQueue()

        // Add some sample tasks
        let sampleCards = [
            Card(kind: .characters, name: "Captain Drake", subtitle: "Space Explorer", detailedText: "A brave captain exploring the stars"),
            Card(kind: .locations, name: "New Haven Station", subtitle: "Space Station", detailedText: "A bustling space station orbiting Mars"),
            Card(kind: .artifacts, name: "Plasma Rifle", subtitle: "Advanced Weapon", detailedText: "A powerful energy weapon")
        ]

        queue.addCards(sampleCards)

        return BatchGenerationView(queue: queue)
            .frame(width: 700, height: 500)
    }
}
#endif
