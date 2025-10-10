//
//  CardEditorView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/4/25.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ImageIO
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// Focused value key for inserting the default author via a command.
#if os(macOS)
private struct InsertDefaultAuthorActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var insertDefaultAuthor: (() -> Void)? {
        get { self[InsertDefaultAuthorActionKey.self] }
        set { self[InsertDefaultAuthorActionKey.self] = newValue }
    }
}
#endif

struct CardEditorView: View {
    enum Mode {
        case create(kind: Kinds, onComplete: (Card) -> Void)
        case edit(card: Card, onComplete: () -> Void)

        var kind: Kinds {
            switch self {
            case .create(let kind, _): return kind
            case .edit(let card, _):   return card.kind
            }
        }
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    // App settings (for default author)
    @Query(
        FetchDescriptor<AppSettings>(
            predicate: #Predicate { $0.singletonKey == "AppSettingsSingleton" }
        )
    ) private var settingsResults: [AppSettings]

    // Track focus so we only handle the shortcut when the Author field is focused
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name, subtitle, author, details
    }

    // Editable fields (initialized in init from mode)
    @State private var name: String
    @State private var subtitle: String
    @State private var author: String
    @State private var detailedText: String
    @State private var sizeCategory: SizeCategory

    // Image handling
    @State private var imageData: Data?
    @State private var thumbnail: Image?
    @State private var isWorking: Bool = false

    // File importer
    @State private var isImportingImage: Bool = false

    // Photos picker
    @State private var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Tunable constants (match CardView where sensible)
    private let thumbnailSide: CGFloat = 72
    private let thumbnailTopPadding: CGFloat = 8
    private let maxCardWidth: CGFloat = 430

    private let tabCornerRadius: CGFloat = 8
    private let tabHeight: CGFloat = 22
    private let tabHorizontalPadding: CGFloat = 10
    private let tabVerticalPadding: CGFloat = 2
    private let tabOffsetTop: CGFloat = -10
    private let tabOffsetLeft: CGFloat = 12

    // Initialize state from mode
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create(_, _):
            _name = State(initialValue: "")
            _subtitle = State(initialValue: "")
            _author = State(initialValue: "")
            _detailedText = State(initialValue: "")
            _sizeCategory = State(initialValue: .standard)
            _imageData = State(initialValue: nil)
        case .edit(let card, _):
            _name = State(initialValue: card.name)
            _subtitle = State(initialValue: card.subtitle)
            _author = State(initialValue: card.author ?? "")
            _detailedText = State(initialValue: card.detailedText)
            _sizeCategory = State(initialValue: card.sizeCategory)
            _imageData = State(initialValue: nil) // only set when user selects/replaces
        }
    }

    var body: some View {
        let kind = mode.kind
        let cardShape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let shadowColor = Color.black.opacity(scheme == .dark ? 0.25 : 0.10)
        let tabTopAllowance = max(0, -tabOffsetTop)

        VStack(spacing: 16) {
            // Editor "card" surface (mirrors CardView styling)
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 8) {
                    thumbnailDropView
                        .frame(width: thumbnailSide, height: thumbnailSide)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.quaternary, lineWidth: 1)
                        }
                        .padding(.top, thumbnailTopPadding)

                    // Compact image attribution panel (only for edit mode)
                    if case .edit(let card, _) = mode {
                        ImageAttributionViewer(card: card)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .focused($focusedField, equals: .name)

                        sizePicker
                    }

                    TextField("Subtitle (optional)", text: $subtitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .subtitle)

                    TextField("Author (optional)", text: $author)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .author)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Details (Markdown supported)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $detailedText)
                            .focused($focusedField, equals: .details)
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(.background)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.top, 20 + tabTopAllowance)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .background(
                cardShape
                    .fill(.background)
                    .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
            )
            .overlay(
                cardShape
                    .strokeBorder(kind.accentColor(for: scheme), lineWidth: 12)
            )
            .overlay(alignment: .topLeading) {
                kindTab(kind: kind)
                    .offset(x: tabOffsetLeft, y: tabOffsetTop)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: maxCardWidth, alignment: .topLeading)

            // Image actions
            HStack(spacing: 12) {
                Button {
                    isImportingImage = true
                } label: {
                    Label("Choose Image…", systemImage: "photo.on.rectangle")
                }

                if isEditing {
                    Button {
                        Task { await regenerateThumbnailFromOriginalIfPossible() }
                    } label: {
                        Label("Regenerate Thumbnail", systemImage: "arrow.clockwise")
                    }
                    .disabled(!hasAnyImage)
                }

                Button(role: .destructive) {
                    removeImage()
                } label: {
                    Label("Remove Image", systemImage: "trash")
                }
                .disabled(!hasAnyImage)

                Spacer()

                if isWorking {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(maxWidth: maxCardWidth)
            .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
                if case let .success(url) = result,
                   let data = try? Data(contentsOf: url) {
                    imageData = data
                }
            }

            // Citations section (edit mode only)
            if isEditing, case .edit(let card, _) = mode {
                CitationViewer(card: card)
                    .frame(maxWidth: maxCardWidth)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Create") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(maxWidth: maxCardWidth)
        }
        .padding()
        .frame(minWidth: 520)
        .navigationTitle(isEditing ? "Edit \(kind.title.dropLastIfPluralized())" : "New \(kind.title.dropLastIfPluralized())")
        .task(id: imageData) {
            await loadThumbnailPreview()
        }
        .task {
            if thumbnail == nil {
                await loadInitialThumbnailIfEditing()
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task { await setImageDataFromPickerItem(newItem) }
        }
        .dropDestination(for: Data.self) { items, _ in
            if let data = items.first, Self.isSupportedImageData(data) {
                imageData = data
                return true
            }
            return false
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, Self.isSupportedImageURL(url),
                  let data = try? Data(contentsOf: url) else { return false }
            imageData = data
            return true
        }
        #if os(macOS)
        // Expose a focused action so the app-level Commands can trigger it with a shortcut.
        .focusedValue(
            \.insertDefaultAuthor,
            (focusedField == .author && !defaultAuthorTrimmed.isEmpty) ? { insertDefaultAuthorIfAvailable() } : nil
        )
        #endif
    }

    // MARK: - Derived

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var hasAnyImage: Bool {
        switch mode {
        case .create:
            return imageData != nil
        case .edit(let card, _):
            return imageData != nil || card.thumbnailData != nil || card.imageFileURL != nil
        }
    }

    private var defaultAuthorTrimmed: String {
        (settingsResults.first?.defaultAuthor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var thumbnailDropView: some View {
        ZStack {
            if let thumbnail {
                thumbnail
                    .resizable()
                    .scaledToFit() // Preserve aspect ratio; no cropping
                    .accessibilityLabel("Cover Image")
            } else {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundStyle(.secondary)
                        Text("Drop image here")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                isImportingImage = true
            } label: {
                Label("Choose Image…", systemImage: "photo.on.rectangle")
            }
            if #available(iOS 16.0, macOS 13.0, *) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Label("Import from Photos…", systemImage: "photo")
                }
            }
        }
    }

    private var sizePicker: some View {
        Picker("Size", selection: $sizeCategory) {
            ForEach(SizeCategory.allCases, id: \.self) { sc in
                Text(sc.displayName).tag(sc)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel("Card size")
    }

    private func kindTab(kind: Kinds) -> some View {
        HStack(spacing: 6) {
            Image(systemName: kind.systemImage)
                .font(.caption2)
            Text(kind.title)
                .font(.caption).bold()
                .lineLimit(1)
        }
        .foregroundStyle(.primary.opacity(scheme == .dark ? 0.9 : 0.95))
        .padding(.horizontal, tabHorizontalPadding)
        .padding(.vertical, tabVerticalPadding)
        .frame(height: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: tabCornerRadius, style: .continuous)
                .fill(kind.accentColor(for: scheme))
        )
    }

    // MARK: - Author shortcut

    @MainActor
    private func insertDefaultAuthorIfAvailable() {
        let val = defaultAuthorTrimmed
        guard !val.isEmpty, focusedField == .author else { return }
        author = val
    }

    // MARK: - Save

    @MainActor
    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        let authorValue: String? = trimmedAuthor.isEmpty ? nil : trimmedAuthor

        switch mode {
        case .create(let kind, let onComplete):
            let card = Card(
                kind: kind,
                name: trimmedName,
                subtitle: subtitle,
                detailedText: detailedText,
                author: authorValue,
                sizeCategory: sizeCategory
            )
            modelContext.insert(card)

            if let data = imageData {
                let ext = Self.inferFileExtension(from: data) ?? "jpg"
                try? card.setOriginalImageData(data, preferredFileExtension: ext)
            }

            try? modelContext.save()
            onComplete(card)
            dismiss()

        case .edit(let card, let onComplete):
            card.name = trimmedName
            card.subtitle = subtitle
            card.detailedText = detailedText
            card.author = authorValue
            card.sizeCategory = sizeCategory

            if let data = imageData {
                let ext = Self.inferFileExtension(from: data) ?? "jpg"
                try? card.setOriginalImageData(data, preferredFileExtension: ext)
            }

            try? modelContext.save()
            onComplete()
            dismiss()
        }
    }

    // MARK: - Thumbnail loading

    @MainActor
    private func loadThumbnailPreview() async {
        if let data = imageData, let cg = Self.makeCGImage(from: data) {
            let img = Image(decorative: cg, scale: 1, orientation: .up)
            withAnimation(.easeInOut(duration: 0.15)) {
                self.thumbnail = img
            }
            return
        }
        await loadInitialThumbnailIfEditing()
    }

    @MainActor
    private func loadInitialThumbnailIfEditing() async {
        guard case .edit(let card, _) = mode else {
            thumbnail = nil
            return
        }
        let img = await card.makeThumbnailImage()
        withAnimation(.easeInOut(duration: 0.15)) {
            self.thumbnail = img
        }
    }

    // MARK: - Image operations

    @MainActor
    private func regenerateThumbnailFromOriginalIfPossible() async {
        guard case .edit(let card, _) = mode else { return }
        isWorking = true
        defer { isWorking = false }
        card.regenerateThumbnailFromOriginal()
        await loadInitialThumbnailIfEditing()
    }

    private func removeImage() {
        switch mode {
        case .create:
            imageData = nil
            thumbnail = nil
        case .edit(let card, _):
            card.removeOriginalImage()
            card.thumbnailData = nil
            card.clearImageCaches()
            Task { await loadInitialThumbnailIfEditing() }
        }
    }

    // MARK: - Photos picker handling

    @MainActor
    private func setImageDataFromPickerItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isWorking = true
        defer { isWorking = false }
        // Try to load raw image data first
        if let data = try? await item.loadTransferable(type: Data.self),
           Self.isSupportedImageData(data) {
            imageData = data
            return
        }
        // Fallback: try platform image -> data
        #if canImport(UIKit)
        if let uiImage = try? await item.loadTransferable(type: UIImage.self),
           let data = uiImage.jpegData(compressionQuality: 0.95) ?? uiImage.pngData() {
            imageData = data
            return
        }
        #elseif canImport(AppKit)
        if let nsImage = try? await item.loadTransferable(type: NSImage.self) {
            if let tiff = nsImage.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let data = rep.representation(using: .png, properties: [:]) {
                imageData = data
                return
            }
        }
        #endif
    }

    // MARK: - Image helpers

    private static func isSupportedImageURL(_ url: URL) -> Bool {
        guard let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return type.conforms(to: .image)
    }

    private static func isSupportedImageData(_ data: Data) -> Bool {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return false }
        return CGImageSourceGetType(src) != nil
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    private static func inferFileExtension(from data: Data) -> String? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(src) as String?,
              let utType = UTType(type) else {
            return nil
        }
        return utType.preferredFilenameExtension
    }
}

