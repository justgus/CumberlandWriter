//
//  StorageModeOnboardingView.swift
//  Cumberland
//
//  Created by Claude on 2026-04-13.
//  ER-0058 Phase 4: First-launch storage mode selection
//

import SwiftUI
import CloudKit

/// Onboarding view for selecting storage mode on first launch
struct StorageModeOnboardingView: View {

    @StateObject private var availability = CloudKitAvailability.shared
    @State private var selectedMode: StorageMode
    @Environment(\.dismiss) private var dismiss

    /// Callback when user confirms storage mode
    let onComplete: (StorageMode) -> Void

    init(onComplete: @escaping (StorageMode) -> Void) {
        self.onComplete = onComplete

        // Pre-select based on iCloud availability
        // Note: This is a best guess - will be updated after availability check
        _selectedMode = State(initialValue: .cloudKit("iCloud.CumberlandCloud"))
    }

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)

                Text("Choose How to Store Your Data")
                    .font(.title.bold())

                Text("You can change this later in Settings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Storage mode options
            VStack(spacing: 16) {
                // iCloud option
                StorageModeOption(
                    icon: "icloud",
                    title: "iCloud Sync",
                    description: "Sync across all your devices automatically",
                    isAvailable: availability.isCurrentlyAvailable,
                    unavailableReason: unavailableReason,
                    isSelected: selectedMode.rawValue == "cloudKit",
                    action: {
                        selectedMode = .cloudKit("iCloud.CumberlandCloud")
                    }
                )

                // Local option
                StorageModeOption(
                    icon: "internaldrive",
                    title: "Local Storage Only",
                    description: "Keep data on this device only. Works offline.",
                    isAvailable: true,
                    unavailableReason: nil,
                    isSelected: selectedMode.rawValue == "local",
                    action: {
                        selectedMode = .local
                    }
                )
            }

            Spacer()

            // Continue button
            Button(action: {
                // Save preference and dismiss
                UserDefaults.standard.set(selectedMode.rawValue, forKey: "storageMode")
                onComplete(selectedMode)
                dismiss()
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(width: 560, height: 520)
        .task {
            // Refresh availability on appear
            await availability.refresh()

            // Auto-select based on availability
            if availability.isCurrentlyAvailable {
                selectedMode = .cloudKit("iCloud.CumberlandCloud")
            } else {
                selectedMode = .local
            }
        }
    }

    private var unavailableReason: String? {
        guard !availability.isCurrentlyAvailable else { return nil }

        switch availability.accountStatus {
        case .noAccount:
            return "Sign in to iCloud in System Settings to enable sync"
        case .restricted:
            return "iCloud access is restricted on this device"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        default:
            return "iCloud is not available"
        }
    }
}

/// Individual storage mode option card
private struct StorageModeOption: View {
    let icon: String
    let title: String
    let description: String
    let isAvailable: Bool
    let unavailableReason: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isAvailable {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isAvailable ? .blue : .secondary)
                    .frame(width: 50)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isAvailable ? .primary : .secondary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !isAvailable, let reason = unavailableReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.top, 4)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1.0 : 0.6)
    }
}

// MARK: - Previews

#Preview("iCloud Available") {
    StorageModeOnboardingView { mode in
        print("Selected mode: \(mode)")
    }
}

#Preview("iCloud Unavailable") {
    StorageModeOnboardingView { mode in
        print("Selected mode: \(mode)")
    }
}
