//
//  CardEditorThumbnailView.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Thumbnail/image display and drop target for CardEditorView
struct CardEditorThumbnailView: View {

    @Bindable var viewModel: CardEditorViewModel
    let mode: CardEditorView.Mode
    let onShowFullSize: () -> Void

    #if os(macOS)
    private let thumbnailSide: CGFloat = 72
    #elseif os(visionOS)
    private let thumbnailSide: CGFloat = 96
    #else
    private let thumbnailSide: CGFloat = 72
    #endif

    var body: some View {
        ZStack {
            if let thumbnail = viewModel.thumbnail {
                let hasFullSizeImage: Bool = {
                    if case .edit(let card, _) = mode {
                        return card.imageFileURL != nil || card.originalImageData != nil
                    }
                    return false
                }()

                thumbnail
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Cover Image")
                    .accessibilityHint(hasFullSizeImage ? "Double-click to view full size" : "")
                    .overlay(alignment: .topTrailing) {
                        // AI attribution badge
                        if case .edit(let card, _) = mode, card.imageGeneratedByAI == true {
                            aiAttributionBadge(for: card)
                        }
                    }
                    #if os(macOS)
                    .onTapGesture(count: 2) {
                        if hasFullSizeImage {
                            onShowFullSize()
                        }
                    }
                    .onHover { hovering in
                        if hovering, hasFullSizeImage {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    #else
                    .onTapGesture(count: 2) {
                        if hasFullSizeImage {
                            onShowFullSize()
                        }
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        if hasFullSizeImage {
                            onShowFullSize()
                        }
                    }
                    #endif
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(.fill.tertiary)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title)
                                .symbolRenderingMode(.hierarchical)
                            Text("Drag an image here\nor use buttons below")
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .frame(width: thumbnailSide, height: thumbnailSide)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func aiAttributionBadge(for card: Card) -> some View {
        Button {
            viewModel.showAIImageInfo = true
        } label: {
            Image(systemName: "wand.and.stars")
                .font(.caption2)
                .padding(4)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .help("AI-generated image")
        .padding(4)
    }
}
