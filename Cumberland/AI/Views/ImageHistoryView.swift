//
//  ImageHistoryView.swift
//  Cumberland
//
//  Created by Claude Code on 2/2/26.
//  ER-0017 Phase 3: Image History Browser UI
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// View for browsing and managing image version history
struct ImageHistoryView: View {

    // MARK: - Properties

    /// The card whose history to display
    let card: Card

    /// Model context for operations
    @Environment(\.modelContext) private var modelContext

    /// Dismiss action
    @Environment(\.dismiss) private var dismiss

    /// Selected version for actions
    @State private var selectedVersion: ImageVersion?

    /// Show comparison view
    @State private var showingComparison = false

    /// Show export dialog
    @State private var showingExport = false

    /// Show delete confirmation
    @State private var showingDeleteConfirmation = false

    /// Show clear all confirmation
    @State private var showingClearAllConfirmation = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            if card.hasVersionHistory {
                historyContent
            } else {
                emptyState
            }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 400, idealHeight: 500)
        .navigationTitle("Image History")
        .sheet(isPresented: $showingComparison) {
            if let version = selectedVersion {
                ComparisonView(card: card, version: version)
            }
        }
        .sheet(isPresented: $showingExport) {
            if let version = selectedVersion {
                ExportVersionView(version: version)
            }
        }
        .alert("Delete Version", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let version = selectedVersion {
                    deleteVersion(version)
                }
            }
        } message: {
            Text("Are you sure you want to delete this version? This action cannot be undone.")
        }
        .alert("Clear All History", isPresented: $showingClearAllConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                clearAllVersions()
            }
        } message: {
            Text("Are you sure you want to delete all \(card.versionStatistics.versionCount) versions? This will free up \(card.versionStatistics.totalSizeFormatted) of storage. This action cannot be undone.")
        }
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
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image History")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(card.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Statistics
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(card.versionStatistics.versionCount) versions")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(card.versionStatistics.totalSizeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Actions
            HStack(spacing: 12) {
                if card.hasVersionHistory {
                    Button(role: .destructive) {
                        showingClearAllConfirmation = true
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Text("History Limit: \(AISettings.shared.imageHistoryLimit) versions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }

    // MARK: - History Content

    private var historyContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(card.sortedVersions) { version in
                    VersionRowView(
                        version: version,
                        isSelected: selectedVersion?.id == version.id,
                        onSelect: {
                            selectedVersion = version
                        },
                        onRestore: {
                            restoreVersion(version)
                        },
                        onCompare: {
                            selectedVersion = version
                            showingComparison = true
                        },
                        onExport: {
                            selectedVersion = version
                            showingExport = true
                        },
                        onDelete: {
                            selectedVersion = version
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Version History")
                .font(.title3)
                .fontWeight(.medium)

            Text("Previous versions of generated images will appear here when you regenerate.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Actions

    private func restoreVersion(_ version: ImageVersion) {
        ImageVersionManager.shared.restoreVersion(version, for: card, in: modelContext)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after restoring version: \(error)")
        }
    }

    private func deleteVersion(_ version: ImageVersion) {
        ImageVersionManager.shared.deleteVersion(version, for: card, in: modelContext)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after deleting version: \(error)")
        }

        selectedVersion = nil
    }

    private func clearAllVersions() {
        ImageVersionManager.shared.clearAllVersions(for: card, in: modelContext)

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after clearing versions: \(error)")
        }

        selectedVersion = nil
    }
}

// MARK: - Version Row View

private struct VersionRowView: View {
    let version: ImageVersion
    let isSelected: Bool
    let onSelect: () -> Void
    let onRestore: () -> Void
    let onCompare: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let image = version.makeImage() {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }

            // Version info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Version \(version.versionNumber)")
                        .font(.headline)

                    Spacer()

                    Text(version.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(version.promptPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(version.provider, systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(version.fileSizeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onRestore()
                } label: {
                    Label("Restore", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                }
                .help("Restore this version as current")

                Button {
                    onCompare()
                } label: {
                    Label("Compare", systemImage: "rectangle.2.swap")
                        .labelStyle(.iconOnly)
                }
                .help("Compare with current")

                Button {
                    onExport()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .help("Export to file")

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .help("Delete this version")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Comparison View

private struct ComparisonView: View {
    let card: Card
    let version: ImageVersion

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compare Versions")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05))

            Divider()

            // Comparison
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Current image
                    VStack(spacing: 8) {
                        Text("Current")
                            .font(.headline)
                            .foregroundStyle(.green)

                        if let data = card.originalImageData {
                            #if os(macOS)
                            if let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: geometry.size.width / 2 - 20)
                            }
                            #else
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: geometry.size.width / 2 - 20)
                            }
                            #endif
                        }

                        if let prompt = card.imageAIPrompt {
                            Text(prompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .padding(.horizontal)
                        }
                    }
                    .frame(width: geometry.size.width / 2)

                    Divider()

                    // Version image
                    VStack(spacing: 8) {
                        Text("Version \(version.versionNumber)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        if let image = version.makeImage() {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geometry.size.width / 2 - 20)
                        }

                        Text(version.prompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .padding(.horizontal)
                    }
                    .frame(width: geometry.size.width / 2)
                }
            }
        }
        .frame(minWidth: 800, idealWidth: 1000, minHeight: 500, idealHeight: 600)
    }
}

// MARK: - Export Version View

private struct ExportVersionView: View {
    let version: ImageVersion

    @Environment(\.dismiss) private var dismiss
    @State private var exportURL: URL?
    @State private var showingFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Version \(version.versionNumber)")
                .font(.title2)
                .fontWeight(.semibold)

            if let image = version.makeImage() {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Provider:")
                        .foregroundStyle(.secondary)
                    Text(version.provider)
                }

                HStack {
                    Text("Generated:")
                        .foregroundStyle(.secondary)
                    Text(version.formattedDate)
                }

                HStack {
                    Text("Size:")
                        .foregroundStyle(.secondary)
                    Text(version.fileSizeString)
                }
            }
            .font(.subheadline)

            Spacer()

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Export…") {
                    exportVersion()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }

    private func exportVersion() {
        guard let imageData = version.imageData else { return }

        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.nameFieldStringValue = "version-\(version.versionNumber).png"
        savePanel.message = "Export image version"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try imageData.write(to: url)
                    dismiss()
                } catch {
                    print("❌ Failed to export version: \(error)")
                }
            }
        }
        #else
        // iOS: Share sheet
        let activityVC = UIActivityViewController(
            activityItems: [imageData],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }

        dismiss()
        #endif
    }
}

// MARK: - Preview

#if DEBUG
struct ImageHistoryView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Card.self, ImageVersion.self, configurations: config)
        let context = container.mainContext

        let card = Card(kind: .characters, name: "Captain Drake", subtitle: "Space Explorer", detailedText: "A brave captain")
        context.insert(card)

        return ImageHistoryView(card: card)
            .modelContainer(container)
    }
}
#endif
