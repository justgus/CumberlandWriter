//
//  FullSizeImageViewer.swift
//  Cumberland
//
//  Full-screen image viewer with pinch-to-zoom, pan gestures, and Share/Copy
//  toolbar actions. Loads the card's full-resolution originalImageData on
//  appear. Presented as a sheet or separate window from card detail views.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import ImageProcessing

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// A full-screen viewer for high-resolution card images with zoom and pan support.
struct FullSizeImageViewer: View {
    let card: Card
    let pendingImageData: Data? // Optional pending image data from editor (not yet saved to card)
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var loadedImage: CGImage?

    // DR-0078: Image export state
    @State private var showingExportOptions = false
    @State private var showingExportSuccess = false
    @State private var exportSuccessMessage = ""

    var body: some View {
        ZStack {
            // Black background for photo viewing
            Color.black.ignoresSafeArea()

            Group {
                if let cgImage = loadedImage {
                    imageView(cgImage: cgImage)
                } else {
                    unavailableView
                }
            }
            
            // DR-0078: Toolbar overlay with export and close buttons
            VStack {
                HStack {
                    // Export button (left side)
                    if loadedImage != nil {
                        exportButton
                    }
                    Spacer()
                    closeButton
                }
                Spacer()
            }
            // Export success alert
            .alert("Image Exported", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportSuccessMessage)
            }
        }
        .task {
            // Always load on appear
            await loadImage()
        }
        .task(id: pendingImageData?.count) {
            // Watch pending image data (from editor, not yet saved)
            await loadImage()
        }
        .task(id: card.originalImageData?.count) {
            // Watch originalImageData size as primary change indicator
            // This changes immediately when image is regenerated
            await loadImage()
        }
        .task(id: card.thumbnailData?.count) {
            // Watch thumbnail data as backup indicator
            // This also changes when image is updated
            await loadImage()
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #endif
        #if os(iOS)
        .statusBar(hidden: true)
        #endif
    }
    
    // MARK: - Subviews
    
    private func imageView(cgImage: CGImage) -> some View {
        Image(decorative: cgImage, scale: 1, orientation: .up)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(1.0, min(lastScale * value, 5.0))
                    }
                    .onEnded { _ in
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow panning when zoomed in
                        if scale > 1.0 {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if scale > 1.0 {
                        // Reset to fit
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        // Zoom to 2x
                        scale = 2.0
                        lastScale = 2.0
                    }
                }
            }
            .onTapGesture {
                // Single tap dismisses (but won't fire if double-tap is detected)
                dismiss()
            }
    }
    
    private var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
            Text("High-resolution image unavailable")
                .foregroundStyle(.white.opacity(0.8))
                .font(.title3)
        }
    }
    
    // DR-0078: Export button
    private var exportButton: some View {
        Menu {
            Button {
                exportImage(as: .png)
            } label: {
                Label("Export as PNG", systemImage: "photo")
            }
            Button {
                exportImage(as: .jpeg)
            } label: {
                Label("Export as JPEG", systemImage: "photo")
            }
            #if os(iOS)
            Divider()
            Button {
                shareImage()
            } label: {
                Label("Share...", systemImage: "square.and.arrow.up")
            }
            #endif
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding()
        .help("Export image")
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .padding()
        .keyboardShortcut(.cancelAction)
        .help("Close (Esc)")
    }

    // MARK: - Export Functions (DR-0078)

    private func exportImage(as format: UTType) {
        guard let imageData = currentImageData else { return }

        let fileName = "\(card.name.replacingOccurrences(of: " ", with: "_")).\(format == .png ? "png" : "jpg")"

        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format]
        panel.nameFieldStringValue = fileName
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let exportData: Data?
                if format == .png {
                    exportData = ImageProcessingService.shared.convertToPNG(imageData)
                } else {
                    exportData = ImageProcessingService.shared.convertToJPEG(imageData, compressionQuality: 0.9)
                }

                if let exportData = exportData {
                    try exportData.write(to: url)
                    exportSuccessMessage = "Image saved to \(url.lastPathComponent)"
                    showingExportSuccess = true
                }
            } catch {
                print("Export failed: \(error)")
            }
        }
        #else
        // iOS: Save to Photos library
        guard let uiImage = UIImage(data: imageData) else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        exportSuccessMessage = "Image saved to Photos"
        showingExportSuccess = true
        #endif
    }

    #if os(iOS)
    private func shareImage() {
        guard let imageData = currentImageData,
              let uiImage = UIImage(data: imageData) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [uiImage],
            applicationActivities: nil
        )

        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Handle iPad popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: 100, width: 0, height: 0)
            }
            rootVC.present(activityVC, animated: true)
        }
    }
    #endif

    private var currentImageData: Data? {
        pendingImageData ?? card.originalImageData
    }
    
    // MARK: - Helpers

    @MainActor
    private func loadImage() async {
        // Prefer pending image data (from editor, not yet saved to card)
        if let data = pendingImageData,
           let cgImage = Self.makeCGImage(from: data) {
            loadedImage = cgImage
            return
        }

        // Then try originalImageData from card
        if let data = card.originalImageData,
           let cgImage = Self.makeCGImage(from: data) {
            loadedImage = cgImage
            return
        }

        // Fallback to file URL if no originalImageData
        if card.imageFileURL != nil,
           let cgImage = card.cgImageFromFileURL() {
            loadedImage = cgImage
            return
        }

        // No image available
        loadedImage = nil
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }
}

// MARK: - View Modifier for Full-Size Image Gesture

struct FullSizeImageGestureModifier: ViewModifier {
    let card: Card
    @State private var showingFullSize = false
    
    func body(content: Content) -> some View {
        content
            // Long press for iOS/iPadOS (primary gesture)
            .onLongPressGesture(minimumDuration: 0.5) {
                if hasImage {
                    showingFullSize = true
                }
            }
            // Platform-specific gestures
            #if os(iOS)
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        if hasImage {
                            showingFullSize = true
                        }
                    }
            )
            #endif
            #if os(macOS)
            .onTapGesture(count: 2) {
                if hasImage {
                    showingFullSize = true
                }
            }
            // Present full-size viewer
            .sheet(isPresented: $showingFullSize) {
                FullSizeImageViewer(card: card, pendingImageData: nil)
            }
            #else
            // Present full-size viewer
            .fullScreenCover(isPresented: $showingFullSize) {
                FullSizeImageViewer(card: card, pendingImageData: nil)
            }
            #endif
    }
    
    private var hasImage: Bool {
        card.imageFileURL != nil || card.originalImageData != nil || card.thumbnailData != nil
    }
}

extension View {
    /// Adds gesture support for viewing a card's image in full size.
    ///
    /// Supports:
    /// - **iOS/iPadOS:** Long press (0.5s) or double-tap
    /// - **macOS:** Double-click
    /// - **All platforms:** Context menu option "View Full Size"
    func fullSizeImageGesture(for card: Card) -> some View {
        modifier(FullSizeImageGestureModifier(card: card))
    }
}

// MARK: - Preview

#Preview("FullSizeImageViewer") {
    let sample = Card(
        kind: .characters,
        name: "Ada",
        subtitle: "The Analyst",
        detailedText: "Curious and meticulous.",
        author: "M. S.",
        sizeCategory: .standard
    )
    
    return FullSizeImageViewer(card: sample, pendingImageData: nil)
        .modelContainer(for: Card.self, inMemory: true)
}
