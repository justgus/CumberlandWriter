//
//  CardRelationshipHeader.swift
//  Cumberland
//
//  Extracted from CardRelationshipView.swift as part of ER-0022 Phase 4.5
//  Contains the primary card header display for CardRelationshipView.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// The header section displaying the primary card's information in CardRelationshipView.
struct CardRelationshipHeader: View {
    let primary: Card
    let headerImage: Image?
    let hasFullSizeImage: Bool
    let onShowFullSizeImage: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Kind indicator
            HStack(spacing: 6) {
                Image(systemName: primary.kind.systemImage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(primary.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Main content row
            HStack(alignment: .top, spacing: 10) {
                // Name and subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(primary.name)
                        .font(.title3).bold()
                    if !primary.subtitle.isEmpty {
                        Text(primary.subtitle)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(minWidth: 160, alignment: .leading)
                .layoutPriority(3)

                // Detailed text (if no image, show more lines)
                if !primary.detailedText.isEmpty {
                    let maxLines = (headerImage == nil) ? 10 : 6
                    Text(primary.detailedText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(maxLines)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(0)
                }

                // Thumbnail image
                if let headerImage {
                    headerImageView(headerImage)
                }
            }
        }
    }

    @ViewBuilder
    private func headerImageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.quaternary, lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            .accessibilityLabel("Card Image")
            .contentShape(Rectangle())
            // Double-tap must come before single-tap
            .onTapGesture(count: 2) {
                if hasFullSizeImage {
                    onShowFullSizeImage()
                }
            }
            .onTapGesture(count: 1) {
                // Single tap could do something else, or just nothing
            }
            #if os(macOS)
            .onHover { hovering in
                if hovering && hasFullSizeImage {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            #endif
            #if os(iOS)
            .onLongPressGesture(minimumDuration: 0.5) {
                if hasFullSizeImage {
                    onShowFullSizeImage()
                }
            }
            #endif
            .contextMenu {
                if hasFullSizeImage {
                    Button {
                        onShowFullSizeImage()
                    } label: {
                        Label("View Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    #if os(macOS)
                    .keyboardShortcut(.space)
                    #endif
                }
            }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("CardRelationshipHeader") {
    CardRelationshipHeader(
        primary: {
            let card = Card(kind: .characters, name: "Test Character", subtitle: "Hero of the Story", detailedText: "A brave warrior who embarks on an epic journey to save the kingdom from darkness. Known for wielding the legendary sword Excalibur.")
            return card
        }(),
        headerImage: Image(systemName: "person.fill"),
        hasFullSizeImage: true,
        onShowFullSizeImage: {}
    )
    .padding()
}
#endif
