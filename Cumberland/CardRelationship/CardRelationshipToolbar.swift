//
//  CardRelationshipToolbar.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5
//  Contains the toolbar controls for CardRelationshipView.
//

import SwiftUI

/// The toolbar controls for CardRelationshipView, including kind picker and action buttons.
struct CardRelationshipToolbar: View {
    let primaryName: String
    @Binding var selectedKind: Kinds
    let selectedRelatedCard: Card?
    let hasExistingCandidates: Bool
    let hasRetypeChoices: Bool

    // Actions
    let onAddCard: () -> Void
    let onAddExisting: () -> Void
    let onEditSelected: () -> Void
    let onChangeRelationType: () -> Void
    let onRemoveRelationship: () -> Void
    let onChangeCardType: () -> Void
    let onManageRelationTypes: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Kind selector
            #if !os(visionOS)
            Text("Related Kind:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            #endif

            Picker(selection: $selectedKind) {
                ForEach(Kinds.orderedCases) { kind in
                    Label(kind.title, systemImage: kind.systemImage)
                        .tag(kind)
                }
            } label: { EmptyView() }
            .labelsHidden()
            .pickerStyle(.menu)
            .glassButtonStyle()

            // Add new card button
            let addTitle: String = (selectedKind == .projects)
                ? "Add Sub \(selectedKind.title.dropLastIfPluralized())"
                : "Add \(selectedKind.title.dropLastIfPluralized())"

            Button {
                onAddCard()
            } label: {
                #if os(macOS)
                Label(addTitle, systemImage: "plus")
                #else
                Label(addTitle, systemImage: "plus")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Create a new \(selectedKind.title.dropLastIfPluralized()) and relate it to '\(primaryName)'")

            // Add existing card button
            Button {
                onAddExisting()
            } label: {
                #if os(macOS)
                Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
                #else
                Label("Add Existing \(selectedKind.title.dropLastIfPluralized())…", systemImage: "link.badge.plus")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(!hasExistingCandidates)

            // Edit selected button
            Button {
                onEditSelected()
            } label: {
                #if os(macOS)
                Label("Edit Selected", systemImage: "pencil")
                #else
                Label("Edit Selected", systemImage: "pencil")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil)
            .help("Edit the selected related card")

            // Change relationship type button
            Button {
                onChangeRelationType()
            } label: {
                #if os(macOS)
                Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
                #else
                Label("Change Relationship Type…", systemImage: "arrow.triangle.2.circlepath")
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil || !hasRetypeChoices)
            .help("Change the relationship type between the selected card and '\(primaryName)'")

            // Remove relationship button
            Button(role: .destructive) {
                onRemoveRelationship()
            } label: {
                #if os(macOS)
                Label("Remove Relationship", systemImage: "link")
                    .symbolVariant(.slash)
                #else
                Label("Remove Relationship", systemImage: "link")
                    .symbolVariant(.slash)
                    .labelStyle(.iconOnly)
                #endif
            }
            .disabled(selectedRelatedCard == nil)
            .help("Remove the relationship between the selected card and '\(primaryName)'")

            Divider().frame(height: 18)

            // Change card type button
            Button {
                onChangeCardType()
            } label: {
                #if os(macOS)
                Label("Change Card Type…", systemImage: "arrow.triangle.swap")
                #else
                Label("Change Card Type…", systemImage: "arrow.triangle.swap")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Change the type of \"\(primaryName)\" (will remove all relationships)")

            // Manage relation types button
            Button {
                onManageRelationTypes()
            } label: {
                #if os(macOS)
                Label("Manage Relation Types…", systemImage: "link")
                #else
                Label("Manage Relation Types…", systemImage: "link")
                    .labelStyle(.iconOnly)
                #endif
            }
            .help("Create, edit, reassign, or delete relation types")

            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("CardRelationshipToolbar") {
    CardRelationshipToolbar(
        primaryName: "Test Character",
        selectedKind: .constant(.locations),
        selectedRelatedCard: nil,
        hasExistingCandidates: true,
        hasRetypeChoices: true,
        onAddCard: {},
        onAddExisting: {},
        onEditSelected: {},
        onChangeRelationType: {},
        onRemoveRelationship: {},
        onChangeCardType: {},
        onManageRelationTypes: {}
    )
    .padding()
}
#endif
