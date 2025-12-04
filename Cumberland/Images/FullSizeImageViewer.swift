// FullSizeImageViewer.swift
import SwiftUI
import SwiftData

/// A full-screen viewer for high-resolution card images with zoom and pan support.
struct FullSizeImageViewer: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Black background for photo viewing
            Color.black.ignoresSafeArea()
            
            Group {
                if let _ = card.imageFileURL,
                   let cgImage = card.cgImageFromFileURL() {
                    imageView(cgImage: cgImage)
                } else if let data = card.originalImageData,
                          let cgImage = Self.makeCGImage(from: data) {
                    imageView(cgImage: cgImage)
                } else {
                    unavailableView
                }
            }
            
            // Close button overlay
            VStack {
                HStack {
                    Spacer()
                    closeButton
                }
                Spacer()
            }
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
    
    // MARK: - Helpers
    
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
                FullSizeImageViewer(card: card)
            }
            #else
            // Present full-size viewer
            .fullScreenCover(isPresented: $showingFullSize) {
                FullSizeImageViewer(card: card)
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
    
    return FullSizeImageViewer(card: sample)
        .modelContainer(for: Card.self, inMemory: true)
}
