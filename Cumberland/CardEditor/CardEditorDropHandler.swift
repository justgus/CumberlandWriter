//
//  CardEditorDropHandler.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Handles drag and drop operations for CardEditorView
@MainActor
final class CardEditorDropHandler {

    private let viewModel: CardEditorViewModel
    private let mode: CardEditorView.Mode
    private let onPendingAttribution: (PendingAttribution) -> Void

    init(
        viewModel: CardEditorViewModel,
        mode: CardEditorView.Mode,
        onPendingAttribution: @escaping (PendingAttribution) -> Void
    ) {
        self.viewModel = viewModel
        self.mode = mode
        self.onPendingAttribution = onPendingAttribution
    }

    // MARK: - Text Drop Handling

    func handleTextDrop(_ providers: [NSItemProvider]) -> Bool {
        var didHandle = false

        // Try to extract a URL (if present) to prefill source
        var suggestedURL: URL?
        if let urlProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let u = item as? URL, u.scheme?.hasPrefix("http") == true {
                    suggestedURL = u
                }
            }
            didHandle = true
        }

        // Plain text (primary trigger for the citation prompt)
        if let textProvider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ||
            $0.hasItemConformingToTypeIdentifier(UTType.text.identifier)
        }) {
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                let s: String? = (item as? String) ?? (item as? NSString).map { String($0) }
                if let s, !s.isEmpty {
                    Task { @MainActor in
                        self.appendIntoDetails(s)
                        // Only prompt when editing an existing card (we need a Card to attach the citation)
                        if case .edit = self.mode {
                            let excerpt = String(s.prefix(280))
                            self.onPendingAttribution(PendingAttribution(
                                kind: .quote,
                                suggestedURL: suggestedURL,
                                prefilledExcerpt: excerpt
                            ))
                        }
                    }
                }
            }
            didHandle = true
        }

        return didHandle
    }

    private func appendIntoDetails(_ incoming: String) {
        let textToInsert = incoming

        // Ensure separation with a newline
        if !viewModel.detailedText.isEmpty && !viewModel.detailedText.hasSuffix("\n") {
            viewModel.detailedText.append("\n")
        }
        viewModel.detailedText.append(textToInsert)
    }

    // MARK: - Image Drop Handling

    func handleImageDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }

        for provider in providers {
            // 0) Try object-based images first (UIKit/AppKit)
            #if canImport(UIKit)
            if provider.canLoadObject(ofClass: UIImage.self) {
                nonisolated(unsafe) let provider = provider
                provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
                    guard let self else { return }
                    if let ui = obj as? UIImage {
                        let data = ui.pngData() ?? ui.jpegData(compressionQuality: 0.9)
                        if let data {
                            Task { @MainActor in
                                self.setImageData(data)
                                if self.isEditing {
                                    self.onPendingAttribution(PendingAttribution(
                                        kind: .image,
                                        suggestedURL: nil,
                                        prefilledExcerpt: nil
                                    ))
                                }
                            }
                        }
                    } else {
                        Task { @MainActor in
                            self.tryURLOrData(provider: provider)
                        }
                    }
                }
                continue
            }
            #endif
            #if canImport(AppKit)
            if provider.canLoadObject(ofClass: NSImage.self) {
                nonisolated(unsafe) let provider = provider
                provider.loadObject(ofClass: NSImage.self) { [weak self] obj, _ in
                    guard let self else { return }
                    if let img = obj as? NSImage {
                        var outData: Data?
                        if let tiff = img.tiffRepresentation,
                           let rep = NSBitmapImageRep(data: tiff) {
                            outData = rep.representation(using: .png, properties: [:])
                                ?? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                        }
                        if let data = outData {
                            Task { @MainActor in
                                self.setImageData(data)
                                if self.isEditing {
                                    self.onPendingAttribution(PendingAttribution(
                                        kind: .image,
                                        suggestedURL: nil,
                                        prefilledExcerpt: nil
                                    ))
                                }
                            }
                        }
                    } else {
                        Task { @MainActor in
                            self.tryURLOrData(provider: provider)
                        }
                    }
                }
                continue
            }
            #endif

            // 1) Raw image data (PNG/JPEG/etc.)
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.tiff.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heic.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.heif.identifier) ||
               provider.hasItemConformingToTypeIdentifier(UTType.bmp.identifier)
            {
                nonisolated(unsafe) let provider = provider
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                    guard let self else { return }
                    if let data, !data.isEmpty {
                        Task { @MainActor in
                            self.setImageData(data)
                            if self.isEditing {
                                self.onPendingAttribution(PendingAttribution(
                                    kind: .image,
                                    suggestedURL: nil,
                                    prefilledExcerpt: nil
                                ))
                            }
                        }
                    } else {
                        Task { @MainActor in
                            self.tryURLOrData(provider: provider)
                        }
                    }
                }
                continue
            }

            // 2) File URL (Finder drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                tryLoadFileURL(provider: provider)
                continue
            }

            // 3) Web URL (Safari drag)
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                tryLoadRemoteURL(provider: provider)
                continue
            }
        }
    }

    // MARK: - Helper Methods

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func setImageData(_ data: Data) {
        viewModel.imageData = data
        viewModel.imageMetadata = ImageMetadataExtractor.extract(from: data)

        // Generate thumbnail
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            viewModel.thumbnail = Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: data) {
            viewModel.thumbnail = Image(uiImage: uiImage)
        }
        #endif
    }

    private func tryURLOrData(provider: NSItemProvider) {
        provider.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, _ in
            if let data, !data.isEmpty {
                Task { @MainActor in
                    self.setImageData(data)
                    if self.isEditing {
                        self.onPendingAttribution(PendingAttribution(
                            kind: .image,
                            suggestedURL: nil,
                            prefilledExcerpt: nil
                        ))
                    }
                }
            }
        }
    }

    private func tryLoadFileURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let url = item as? URL else { return }
            guard url.isFileURL else { return }

            do {
                let data = try Data(contentsOf: url)
                Task { @MainActor in
                    self.setImageData(data)
                    if self.isEditing {
                        self.onPendingAttribution(PendingAttribution(
                            kind: .image,
                            suggestedURL: url,
                            prefilledExcerpt: nil
                        ))
                    }
                }
            } catch {
                print("Failed to load file: \(error)")
            }
        }
    }

    private func tryLoadRemoteURL(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
            guard let url = item as? URL else { return }
            guard !url.isFileURL else { return }
            guard url.scheme == "http" || url.scheme == "https" else { return }

            // Download image from URL
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    await MainActor.run {
                        self.setImageData(data)
                        if self.isEditing {
                            self.onPendingAttribution(PendingAttribution(
                                kind: .image,
                                suggestedURL: url,
                                prefilledExcerpt: nil
                            ))
                        }
                    }
                } catch {
                    print("Failed to download image: \(error)")
                }
            }
        }
    }
}
