//
//  BacklogCardDetailSheet.swift
//  Cumberland
//
//  Lightweight read-only card detail sheet for quick inspection from
//  the MurderBoard backlog sidebar. Shows card metadata, description
//  preview, and relationship summary without opening the full editor.
//
//  Created as part of ER-0031: Enhance Existing Backlog Sidebar.
//

import SwiftUI
import SwiftData

struct BacklogCardDetailSheet: View {
    let card: Card

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private var edgeCount: Int {
        (card.outgoingEdges?.count ?? 0) + (card.incomingEdges?.count ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header: kind icon, name, subtitle
                    HStack(alignment: .top, spacing: 12) {
                        card.kind.symbolImage(filled: true)
                            .font(.title2)
                            .foregroundStyle(card.kind.accentColor(for: scheme))
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.name)
                                .font(.headline)

                            if !card.subtitle.isEmpty {
                                Text(card.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text(card.kind.title)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        // Thumbnail
                        AsyncImage(url: card.thumbnailURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } placeholder: {
                            EmptyView()
                        }
                    }

                    // Description preview
                    if !card.detailedText.isEmpty {
                        Divider()

                        Text(card.detailedText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(8)
                    }

                    // Relationship summary
                    if edgeCount > 0 {
                        Divider()

                        RelatedEdgesList(card: card)
                    }
                }
                .padding()
            }
            .navigationTitle(card.name)
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
        .frame(minWidth: 380, minHeight: 400)
        #endif
    }
}
