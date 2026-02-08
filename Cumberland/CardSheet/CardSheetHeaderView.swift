// CardSheetHeaderView.swift
// Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2
// Contains the header section with image display and name/subtitle editing

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Header view for CardSheetView containing image, name, and subtitle editing
struct CardSheetHeaderView: View {
    let card: Card
    @Binding var fullImage: Image?
    @Binding var isDropTargeted: Bool
    @Binding var isAttributionVisible: Bool
    @Binding var showFullSizeImage: Bool
    @Binding var showAIImageInfo: Bool

    // Name/subtitle editing
    @Binding var nameDraft: String
    @Binding var subtitleDraft: String
    @Binding var isEditingName: Bool
    @Binding var isEditingSubtitle: Bool
    @FocusState.Binding var focusedField: CardSheetFieldFocus?

    // Callbacks
    let onCommitName: () -> Void
    let onCommitSubtitle: () -> Void
    let onPresentImagePicker: () -> Void
    let onPresentPhotosPicker: () -> Void
    let onRemoveImage: () -> Void
    let onHandleDrop: ([NSItemProvider]) -> Void

    // Environment
    @Environment(\.colorScheme) private var scheme

    // Whether image operations are allowed (not in Preview mode)
    let canAcceptImageDrop: Bool

    // Type identifiers for drop
    private static let imageTypeIdentifiers: [String] = [
        UTType.data.identifier, UTType.image.identifier, UTType.png.identifier,
        UTType.jpeg.identifier, UTType.tiff.identifier, UTType.gif.identifier,
        UTType.heic.identifier, UTType.heif.identifier, UTType.bmp.identifier,
        UTType.fileURL.identifier, UTType.url.identifier
    ]

    private static let pasteImageTypes: [UTType] = [
        .data, .image, .png, .jpeg, .tiff, .gif, .heic, .heif, .bmp, .fileURL, .url
    ]

    var body: some View {
        let corner: CGFloat = 10
        HStack(alignment: .top, spacing: 16) {
            leftColumn
            Spacer(minLength: 12)
            imageSection
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(.thinMaterial)
                .allowsHitTesting(false)
        )
        .overlay(
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                    .allowsHitTesting(false)
                if isDropTargeted && canAcceptImageDrop {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                }
            }
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.08), radius: 6, x: 0, y: 3)
        .contentShape(Rectangle())
        .onDrop(
            of: Self.imageTypeIdentifiers,
            isTargeted: Binding(
                get: { self.canAcceptImageDrop && self.isDropTargeted },
                set: { newValue in self.isDropTargeted = newValue }
            )
        ) { providers in
            guard canAcceptImageDrop else { return false }
            onHandleDrop(providers)
            return true
        }
        #if os(macOS)
        .onPasteCommand(of: Self.pasteImageTypes) { providers in
            guard canAcceptImageDrop else { return }
            onHandleDrop(providers)
        }
        #endif
    }

    // MARK: - Left Column (Kind badge, name, subtitle)

    @ViewBuilder
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kind badge
            Text(card.kind.title)
                .font(.title2).bold()
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.thinMaterial)
                        .allowsHitTesting(false)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                        .allowsHitTesting(false)
                )

            // Name editing
            nameField

            // Subtitle editing
            subtitleField
        }
    }

    @ViewBuilder
    private var nameField: some View {
        Group {
            if isEditingName {
                TextField("Name", text: $nameDraft, onCommit: onCommitName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .focused($focusedField, equals: .name)
                    .onChange(of: focusedField) { _, newFocus in
                        if newFocus != .name {
                            onCommitName()
                        }
                    }
            } else {
                Text(card.name)
                    .font(.title3)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        nameDraft = card.name
                        isEditingName = true
                        focusedField = .name
                    }
            }
        }
    }

    @ViewBuilder
    private var subtitleField: some View {
        Group {
            if isEditingSubtitle {
                TextField("Subtitle (optional)", text: $subtitleDraft, onCommit: onCommitSubtitle)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .focused($focusedField, equals: .subtitle)
                    .onChange(of: focusedField) { _, newFocus in
                        if newFocus != .subtitle {
                            onCommitSubtitle()
                        }
                    }
            } else {
                if !card.subtitle.isEmpty {
                    Text(card.subtitle)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            subtitleDraft = card.subtitle
                            isEditingSubtitle = true
                            focusedField = .subtitle
                        }
                } else {
                    Text("Add subtitle")
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.regularMaterial)
                                .allowsHitTesting(false)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            subtitleDraft = ""
                            isEditingSubtitle = true
                            focusedField = .subtitle
                        }
                }
            }
        }
    }

    // MARK: - Image Section

    @ViewBuilder
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            imageDisplay

            // Image attribution (hidden by default)
            if isAttributionVisible {
                ImageAttributionViewer(card: card)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.thinMaterial)
                            .allowsHitTesting(false)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.separator.opacity(0.6), lineWidth: 0.5)
                            .allowsHitTesting(false)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: 160)
        .contentShape(Rectangle())
        .background(Color.black.opacity(0.001))
    }

    @ViewBuilder
    private var imageDisplay: some View {
        Group {
            if let fullImage {
                fullImage
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("Full Image")
                    .accessibilityHint(hasFullSizeImage ? "Double-tap to view full size" : "")
                    .frame(maxHeight: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                            .allowsHitTesting(false)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.quaternary, lineWidth: 0.8)
                            .allowsHitTesting(false)
                    )
                    .overlay(alignment: .topTrailing) {
                        if card.imageGeneratedByAI == true {
                            aiAttributionBadge
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        if hasFullSizeImage {
                            showFullSizeImage = true
                        }
                    }
                    .onTapGesture(count: 1) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAttributionVisible.toggle()
                        }
                    }
                    #if os(macOS)
                    .onHover { hovering in
                        if hovering && hasFullSizeImage {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    #else
                    .onLongPressGesture(minimumDuration: 0.5) {
                        if hasFullSizeImage {
                            showFullSizeImage = true
                        }
                    }
                    #endif
                    .contextMenu {
                        imageContextMenu(hasImage: true)
                    }
            } else {
                imagePlaceholder
            }
        }
    }

    @ViewBuilder
    private var imagePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            Text("Drop image here")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.8)
                .allowsHitTesting(false)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isAttributionVisible.toggle()
            }
        }
        .contextMenu {
            imageContextMenu(hasImage: false)
        }
    }

    @ViewBuilder
    private func imageContextMenu(hasImage: Bool) -> some View {
        #if os(iOS)
        Button(hasImage ? "Replace from Photos..." : "Choose from Photos...") {
            onPresentPhotosPicker()
        }
        #endif
        Button(hasImage ? "Replace Image..." : "Choose Image...") {
            onPresentImagePicker()
        }

        if hasImage {
            if hasFullSizeImage {
                Divider()
                Button {
                    showFullSizeImage = true
                } label: {
                    Label("View Full Size", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                #if os(macOS)
                .keyboardShortcut(.space)
                #endif
            }

            Divider()
            Button("Remove Image", role: .destructive) {
                onRemoveImage()
            }
        }
    }

    private var hasFullSizeImage: Bool {
        card.imageFileURL != nil || card.originalImageData != nil
    }

    // MARK: - AI Attribution Badge

    private var aiAttributionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
                .font(.caption2)
            Text("AI")
                .font(.caption2.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.purple.gradient)
        )
        .shadow(radius: 2)
        .padding(6)
        .help(aiAttributionTooltip)
        .onTapGesture {
            showAIImageInfo = true
        }
    }

    private var aiAttributionTooltip: String {
        var parts: [String] = ["AI Generated"]

        if let provider = card.imageAIProvider {
            parts.append("Provider: \(provider)")
        }

        if let date = card.imageAIGeneratedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            parts.append("Generated: \(formatter.string(from: date))")
        }

        if let prompt = card.imageAIPrompt, !prompt.isEmpty {
            parts.append("Tap for details")
        }

        return parts.joined(separator: "\n")
    }
}

// MARK: - Field Focus Enum (shared between CardSheet components)

enum CardSheetFieldFocus: Hashable {
    case name
    case subtitle
    case details
}
