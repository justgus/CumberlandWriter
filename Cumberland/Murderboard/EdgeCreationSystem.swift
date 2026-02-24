//
//  EdgeCreationSystem.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-09.
//  DR-0076: Edge creation UI for MurderBoard
//
//  Contains Cumberland-specific edge creation types:
//  - PendingEdgeCreation: Data for the RelationType selection sheet
//  - EdgeCreationRelationTypeSheet: UI for choosing a RelationType when connecting nodes
//
//  Canvas-level edge creation state, handles, line rendering, and drop target
//  highlight have been extracted to BoardEngine (ER-0026).
//

import SwiftUI
import SwiftData

// MARK: - Pending Edge Creation

/// Identifiable struct for sheet(item:) presentation - ensures data is available when sheet renders
struct PendingEdgeCreation: Identifiable {
    let id = UUID()
    let sourceCardID: UUID
    let targetCardID: UUID
}

// MARK: - Edge Creation RelationType Sheet

/// Sheet for selecting a RelationType when creating an edge on the MurderBoard
struct EdgeCreationRelationTypeSheet: View {
    let sourceCardID: UUID
    let targetCardID: UUID
    let allRelationTypes: [RelationType]
    let allCards: [Card]
    let onSelect: (RelationType) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedTypeCode: String?
    @State private var showingCreateNew: Bool = false

    private var sourceCard: Card? {
        allCards.first { $0.id == sourceCardID }
    }

    private var targetCard: Card? {
        allCards.first { $0.id == targetCardID }
    }

    private var sourceKind: Kinds {
        sourceCard?.kind ?? .projects
    }

    private var targetKind: Kinds {
        targetCard?.kind ?? .projects
    }

    /// Filter relation types that are applicable for the source->target kind combination
    private var applicableTypes: [RelationType] {
        allRelationTypes.filter { type in
            // Types with no kind restrictions apply to all
            if type.sourceKind == nil && type.targetKind == nil {
                return true
            }
            // Check if source kind matches (or is unrestricted)
            let sourceMatches = type.sourceKind == nil || type.sourceKind == sourceKind
            // Check if target kind matches (or is unrestricted)
            let targetMatches = type.targetKind == nil || type.targetKind == targetKind
            return sourceMatches && targetMatches
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Relationship")
                .font(.title3).bold()

            // Show source and target cards
            GroupBox("Connecting") {
                HStack(spacing: 12) {
                    if let source = sourceCard {
                        HStack(spacing: 6) {
                            Image(systemName: source.kind.systemImage)
                                .foregroundStyle(source.kind.accentColor(for: scheme))
                            Text(source.name)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Unknown")
                    }

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    if let target = targetCard {
                        HStack(spacing: 6) {
                            Image(systemName: target.kind.systemImage)
                                .foregroundStyle(target.kind.accentColor(for: scheme))
                            Text(target.name)
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Text("Unknown")
                    }

                    Spacer()
                }
            }

            // RelationType list
            GroupBox("Relation Type") {
                if applicableTypes.isEmpty {
                    VStack(spacing: 8) {
                        Text("No relation types available for this combination.")
                            .foregroundStyle(.secondary)
                        Button("Create New Type...") {
                            showingCreateNew = true
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    List(selection: $selectedTypeCode) {
                        ForEach(applicableTypes, id: \.code) { type in
                            HStack(spacing: 8) {
                                Text(type.forwardLabel)
                                    .font(.body)
                                Text("\u{2194}\u{FE0E}")
                                    .foregroundStyle(.secondary)
                                Text(type.inverseLabel)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .tag(type.code)
                            .contentShape(Rectangle())
                        }
                    }
                    .frame(minHeight: 140)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button("New Type...") {
                    showingCreateNew = true
                }

                Spacer()

                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    if let typeCode = selectedTypeCode,
                       let type = applicableTypes.first(where: { $0.code == typeCode }) {
                        onSelect(type)
                        dismiss()
                    }
                } label: {
                    Label("Create", systemImage: "link.badge.plus")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTypeCode == nil)
            }
        }
        .padding()
        .onAppear {
            // Pre-select first type if available
            if selectedTypeCode == nil {
                selectedTypeCode = applicableTypes.first?.code
            }
        }
        .sheet(isPresented: $showingCreateNew) {
            RelationTypeCreatorSheet(
                sourceKind: sourceKind,
                targetKind: targetKind,
                onCreate: { newType in
                    onSelect(newType)
                    showingCreateNew = false
                    dismiss()
                },
                onCancel: {
                    showingCreateNew = false
                }
            )
            .frame(minWidth: 420, minHeight: 300)
            .environmentObject(themeManager)
        }
    }
}
