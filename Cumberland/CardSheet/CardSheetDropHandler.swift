//
//  CardSheetDropHandler.swift
//  Cumberland
//
//  Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2.
//  Handles drag-and-drop and clipboard paste of images and text into a card.
//  Resolves image data from UTType.image and UTType.fileURL payloads,
//  triggers quick-attribution sheets, and appends dropped text to the
//  card's detail field.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Handles drop and paste operations for CardSheetView
@MainActor
class CardSheetDropHandler {
    let card: Card
    let modelContext: ModelContext
    let undoManager: UndoManager?
    let onImageLoaded: () async -> Void
    let onAttributionNeeded: (CardSheetPendingAttribution) -> Void

    init(
        card: Card,
        modelContext: ModelContext,
        undoManager: UndoManager?,
        onImageLoaded: @escaping () async -> Void,
        onAttributionNeeded: @escaping (CardSheetPendingAttribution) -> Void
    ) {
        self.card = card
        self.modelContext = modelContext
        self.undoManager = undoManager
        self.onImageLoaded = onImageLoaded
        self.onAttributionNeeded = onAttributionNeeded
    }

    // MARK: - Image Drop Handling

    func handleDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }

        for provider in providers {
            #if canImport(UIKit)
            if provider.canLoadObject(ofClass: UIImage.self) {
                nonisolated(unsafe) let unsafeProvider = provider
                provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                    if let ui = obj as? UIImage {
                        let data = ui.pngData() ?? ui.jpegData(compressionQuality: 0.9)
                        if let data {
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    self.onAttributionNeeded(CardSheetPendingAttribution(
                                        suggestedURL: nil,
                                        isWeb: false,
                                        kind: .image,
                                        prefilledExcerpt: nil
                                    ))
                                }
                            }
                        }
                    } else {
                        Task { @MainActor [weak self] in
                            self?.tryURLOrData(provider: unsafeProvider)
                        }
                    }
                }
                continue
            }
            #endif

            #if canImport(AppKit)
            if provider.canLoadObject(ofClass: NSImage.self) {
                nonisolated(unsafe) let unsafeProvider = provider
                provider.loadObject(ofClass: NSImage.self) { [weak self] obj, _ in
                    if let img = obj as? NSImage {
                        guard let tiff = img.tiffRepresentation else { return }
                        let data = ImageProcessingService.shared.convertToPNG(tiff)
                            ?? ImageProcessingService.shared.convertToJPEG(tiff, compressionQuality: 0.9)
                        if let data {
                            Task { @MainActor [weak self] in
                                guard let self else { return }
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    self.onAttributionNeeded(CardSheetPendingAttribution(
                                        suggestedURL: nil,
                                        isWeb: false,
                                        kind: .image,
                                        prefilledExcerpt: nil
                                    ))
                                }
                            }
                        }
                    } else {
                        Task { @MainActor [weak self] in
                            self?.tryURLOrData(provider: unsafeProvider)
                        }
                    }
                }
                continue
            }
            #endif

            // Raw image data
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.tiff.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heic.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.bmp.identifier) {
                nonisolated(unsafe) let unsafeProvider = provider
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                    if let data, !data.isEmpty {
                        Task { @MainActor [weak self] in
                            guard let self else { return }
                            let ok = self.handleDroppedImageData(data)
                            if ok {
                                self.onAttributionNeeded(CardSheetPendingAttribution(
                                    suggestedURL: nil,
                                    isWeb: false,
                                    kind: .image,
                                    prefilledExcerpt: nil
                                ))
                            }
                        }
                    } else {
                        Task { @MainActor [weak self] in
                            self?.tryURLOrData(provider: unsafeProvider)
                        }
                    }
                }
                continue
            }

            // File URL (Finder drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                tryLoadFileURL(provider: provider)
                continue
            }

            // Web URL (Safari drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                tryLoadRemoteURL(provider: provider)
                continue
            }
        }
    }

    private func tryURLOrData(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            tryLoadFileURL(provider: provider)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            tryLoadRemoteURL(provider: provider)
        } else {
            provider.loadItem(forTypeIdentifier: UTType.data.identifier, options: nil) { [weak self] item, _ in
                if let data = item as? Data, !data.isEmpty {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        let ok = self.handleDroppedImageData(data)
                        if ok {
                            self.onAttributionNeeded(CardSheetPendingAttribution(
                                suggestedURL: nil,
                                isWeb: false,
                                kind: .image,
                                prefilledExcerpt: nil
                            ))
                        }
                    }
                }
            }
        }
    }

    private func tryLoadFileURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] item, _ in
            if let url = item as? URL, url.isFileURL, let data = try? Data(contentsOf: url) {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    let ok = self.handleDroppedImageData(data)
                    if ok {
                        self.onAttributionNeeded(CardSheetPendingAttribution(
                            suggestedURL: nil,
                            isWeb: false,
                            kind: .image,
                            prefilledExcerpt: nil
                        ))
                    }
                }
            }
        }
    }

    private func tryLoadRemoteURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
            if let url = item as? URL, url.scheme?.hasPrefix("http") == true {
                Task.detached {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if !data.isEmpty {
                            await MainActor.run { [weak self] in
                                guard let self else { return }
                                let ok = self.handleDroppedImageData(data)
                                if ok {
                                    self.onAttributionNeeded(CardSheetPendingAttribution(
                                        suggestedURL: url,
                                        isWeb: true,
                                        kind: .image,
                                        prefilledExcerpt: nil
                                    ))
                                }
                            }
                        }
                    } catch {
                        // Ignore failed remote fetch
                    }
                }
            }
        }
    }

    // MARK: - Handle Dropped Image Data

    @discardableResult
    func handleDroppedImageData(_ data: Data) -> Bool {
        do {
            let oldURL = card.imageFileURL
            try card.setOriginalImageData(data, preferredFileExtension: nil)
            registerUndo(actionName: "Replace Image") { [weak self] in
                guard let self else { return }
                if let prev = oldURL, let prevData = try? Data(contentsOf: prev) {
                    try? self.card.setOriginalImageData(prevData, preferredFileExtension: prev.pathExtension)
                } else {
                    self.card.removeOriginalImage()
                    self.card.thumbnailData = nil
                    self.card.clearImageCaches()
                }
            }
            try? modelContext.save()
            Task { await onImageLoaded() }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Remove Image

    func removeImage() {
        let prevURL = card.imageFileURL
        let prevThumb = card.thumbnailData
        registerUndo(actionName: "Remove Image") { [weak self] in
            guard let self else { return }
            if let u = prevURL, let data = try? Data(contentsOf: u) {
                try? self.card.setOriginalImageData(data, preferredFileExtension: u.pathExtension)
                self.card.thumbnailData = prevThumb
            }
        }
        card.removeOriginalImage()
        card.thumbnailData = nil
        card.clearImageCaches()
        try? modelContext.save()
        Task { await onImageLoaded() }
    }

    // MARK: - Undo Helper

    private func registerUndo(actionName: String, _ undoBlock: @escaping () -> Void) {
        undoManager?.registerUndo(withTarget: UndoBox(action: undoBlock)) { box in
            box.action()
        }
        undoManager?.setActionName(actionName)
    }

    private final class UndoBox {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
    }
}

// MARK: - Text Drop Handler

@MainActor
class CardSheetTextDropHandler {
    let isDetailsEditable: () -> Bool
    let insertTextAtSelection: (String) -> Void
    let onAttributionNeeded: (CardSheetPendingAttribution) -> Void

    init(
        isDetailsEditable: @escaping () -> Bool,
        insertTextAtSelection: @escaping (String) -> Void,
        onAttributionNeeded: @escaping (CardSheetPendingAttribution) -> Void
    ) {
        self.isDetailsEditable = isDetailsEditable
        self.insertTextAtSelection = insertTextAtSelection
        self.onAttributionNeeded = onAttributionNeeded
    }

    func handleTextDrop(providers: [NSItemProvider]) -> Bool {
        guard isDetailsEditable() else { return false }

        // Try to extract a URL for source prefill
        var suggestedURL: URL?
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let u = item as? URL, u.scheme?.hasPrefix("http") == true {
                    suggestedURL = u
                }
            }
        }

        guard let textProvider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ||
            $0.hasItemConformingToTypeIdentifier(UTType.text.identifier)
        }) else {
            return false
        }

        var handled = false
        textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
            let dropped: String? = (item as? String) ?? (item as? NSString).map { String($0) }
            guard let s = dropped, !s.isEmpty else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.insertTextAtSelection(s)
                let excerpt = String(s.prefix(280))
                self.onAttributionNeeded(CardSheetPendingAttribution(
                    suggestedURL: suggestedURL,
                    isWeb: suggestedURL != nil,
                    kind: .quote,
                    prefilledExcerpt: excerpt
                ))
            }
            handled = true
        }

        return handled
    }
}

// MARK: - Pending Attribution Model

struct CardSheetPendingAttribution: Identifiable, Equatable {
    let id = UUID()
    let suggestedURL: URL?
    let isWeb: Bool
    let kind: CitationKind
    let prefilledExcerpt: String?
}
