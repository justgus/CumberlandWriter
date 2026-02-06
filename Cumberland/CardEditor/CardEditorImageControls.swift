//
//  CardEditorImageControls.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Image control buttons for CardEditorView
/// Handles image import, AI generation, copy/paste, history, and removal
struct CardEditorImageControls: View {

    @Bindable var viewModel: CardEditorViewModel

    let hasAnyImage: Bool
    let descriptionAnalysis: DescriptionAnalyzer.AnalysisResult?

    let onImportImage: () -> Void
    let onGenerateImage: () -> Void
    let onShowHistory: () -> Void
    let onRemoveImage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Choose Image
            Button {
                onImportImage()
            } label: {
                #if os(iOS)
                Image(systemName: "photo.on.rectangle")
                #else
                Label("Choose Image…", systemImage: "photo.on.rectangle")
                #endif
            }
            .help("Choose Image")

            // Generate Image (AI)
            Button {
                onGenerateImage()
            } label: {
                #if os(iOS)
                Image(systemName: "wand.and.stars")
                #else
                Label(hasAnyImage ? "Regenerate Image…" : "Generate Image…", systemImage: "wand.and.stars")
                #endif
            }
            .disabled(!(descriptionAnalysis?.isSufficient ?? true))
            .help(hasAnyImage ?
                (descriptionAnalysis?.recommendation ?? "Regenerate AI image from the card description") :
                (descriptionAnalysis?.recommendation ?? "Generate an AI image from the card description"))

            // Copy Image
            Button {
                viewModel.copyImageToClipboard()
            } label: {
                #if os(iOS)
                Image(systemName: "doc.on.doc")
                #else
                Label("Copy Image", systemImage: "doc.on.doc")
                #endif
            }
            .disabled(!hasAnyImage)
            .help("Copy image to clipboard")
            .keyboardShortcut("c", modifiers: [.command])

            // Paste Image
            Button {
                viewModel.pasteImageFromClipboard()
            } label: {
                #if os(iOS)
                Image(systemName: "doc.on.clipboard")
                #else
                Label("Paste Image", systemImage: "doc.on.clipboard")
                #endif
            }
            .disabled(!viewModel.clipboardHasImage)
            .help("Paste image from clipboard")
            .keyboardShortcut("v", modifiers: [.command])

            // Image History
            Button {
                onShowHistory()
            } label: {
                #if os(iOS)
                Image(systemName: "clock.arrow.circlepath")
                #else
                Label("Image History…", systemImage: "clock.arrow.circlepath")
                #endif
            }
            .disabled(!hasAnyImage)
            .help("View and restore previous versions")

            // Remove Image
            Button(role: .destructive) {
                onRemoveImage()
            } label: {
                #if os(iOS)
                Image(systemName: "trash")
                #else
                Label("Remove Image", systemImage: "trash")
                #endif
            }
            .disabled(!hasAnyImage)
            .help("Remove the image")
        }
        .buttonStyle(.bordered)
        #if os(iOS)
        .labelStyle(.iconOnly)
        #endif
        .onAppear {
            viewModel.checkClipboard()
        }
    }
}
