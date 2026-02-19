//
//  InvestigationNodeDetailSheet.swift
//  MurderboardApp
//
//  Lightweight detail sheet for inspecting a backlog investigation node.
//  Shows name, subtitle, category, and provides an "Add to Board" action.
//
//  ER-0031: Backlog sidebar for standalone MurderBoard app.
//

import SwiftUI

struct InvestigationNodeDetailSheet: View {
    let node: InvestigationNode
    let onAddToBoard: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    init(node: InvestigationNode, onAddToBoard: ((UUID) -> Void)? = nil) {
        self.node = node
        self.onAddToBoard = onAddToBoard
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: node.category.systemImage)
                            .font(.title2)
                            .foregroundStyle(node.category.defaultColor)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.name)
                                .font(.headline)

                            if !node.subtitle.isEmpty {
                                Text(node.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(node.category.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(node.category.defaultColor.opacity(0.15), in: .capsule)
                                .foregroundStyle(node.category.defaultColor)
                        }

                        Spacer()
                    }

                    Divider()

                    // Status
                    Label("Not on board", systemImage: "tray")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Add to board action
                    if let onAddToBoard {
                        Button {
                            onAddToBoard(node.id)
                            dismiss()
                        } label: {
                            Label("Add to Board", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle(node.name)
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 300)
        #endif
    }
}
