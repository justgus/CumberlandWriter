//
//  BoardZoomStrip.swift
//  BoardEngine
//
//  Compact floating zoom / recenter / shuffle strip for the board canvas.
//  Provides platform-specific implementations for macOS (with editable
//  zoom text field) and iOS (with read-only percentage display).
//

import SwiftUI

// MARK: - Board Zoom Strip

/// Floating zoom control strip rendered at the bottom of the board canvas.
public struct BoardZoomStrip: View {
    let configuration: BoardConfiguration
    @Binding var zoomScale: Double
    let windowSize: CGSize
    let onStepZoom: (Double, CGSize) -> Void
    let onSetZoom: (Double, CGSize) -> Void
    let onRecenter: (CGSize) -> Void
    let onShuffle: () -> Void

    public init(
        configuration: BoardConfiguration,
        zoomScale: Binding<Double>,
        windowSize: CGSize,
        onStepZoom: @escaping (Double, CGSize) -> Void,
        onSetZoom: @escaping (Double, CGSize) -> Void,
        onRecenter: @escaping (CGSize) -> Void,
        onShuffle: @escaping () -> Void
    ) {
        self.configuration = configuration
        self._zoomScale = zoomScale
        self.windowSize = windowSize
        self.onStepZoom = onStepZoom
        self.onSetZoom = onSetZoom
        self.onRecenter = onRecenter
        self.onShuffle = onShuffle
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack(spacing: platformSpacing) {
                Button { onStepZoom(-0.05, windowSize) } label: {
                    Image(systemName: "minus")
                        .frame(width: buttonSize, height: buttonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .help("Zoom Out (⌘-)")
                #endif

                Slider(value: Binding(
                    get: { zoomScale },
                    set: { newValue in onSetZoom(newValue, windowSize) }
                ), in: configuration.minZoom...configuration.maxZoom)
                .frame(width: sliderWidth)
                #if os(macOS)
                .controlSize(.small)
                .help("Zoom")
                #endif

                Button { onStepZoom(+0.05, windowSize) } label: {
                    Image(systemName: "plus")
                        .frame(width: buttonSize, height: buttonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .help("Zoom In (⌘=)")
                .keyboardShortcut("=", modifiers: [.command])
                #endif

                #if os(macOS)
                BoardZoomTextField(
                    zoomScale: zoomScale,
                    configuration: configuration,
                    windowSize: windowSize,
                    setZoom: onSetZoom
                )
                #else
                Text("\(Int(round(zoomScale * 100)))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .trailing)
                #endif

                Divider()
                    .frame(height: dividerHeight)

                Button { onRecenter(windowSize) } label: {
                    Image(systemName: "dot.scope")
                        .frame(width: buttonSize, height: buttonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .help("Recenter (⌘R)")
                #endif

                Button { onShuffle() } label: {
                    Image(systemName: "shuffle")
                        .frame(width: buttonSize, height: buttonSize)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                #if os(macOS)
                .help("Shuffle nodes")
                #endif
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            .padding(.bottom, bottomPadding)
        }
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Platform Constants

    private var platformSpacing: CGFloat {
        #if os(macOS)
        6
        #else
        10
        #endif
    }

    private var buttonSize: CGFloat {
        #if os(macOS)
        16
        #else
        24
        #endif
    }

    private var sliderWidth: CGFloat {
        #if os(macOS)
        100
        #else
        120
        #endif
    }

    private var dividerHeight: CGFloat {
        #if os(macOS)
        14
        #else
        16
        #endif
    }

    private var horizontalPadding: CGFloat {
        #if os(macOS)
        12
        #else
        14
        #endif
    }

    private var verticalPadding: CGFloat {
        #if os(macOS)
        5
        #else
        7
        #endif
    }

    private var bottomPadding: CGFloat {
        #if os(macOS)
        14
        #else
        20
        #endif
    }
}

// MARK: - Zoom Text Field (macOS)

#if os(macOS)
/// Editable zoom percentage field that only commits on Return or focus loss.
struct BoardZoomTextField: View {
    let zoomScale: Double
    let configuration: BoardConfiguration
    let windowSize: CGSize
    let setZoom: (Double, CGSize) -> Void

    @State private var draft: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            TextField("100", text: $draft, onEditingChanged: { editing in
                isEditing = editing
                if editing {
                    draft = "\(Int(round(zoomScale * 100)))"
                } else {
                    commitDraft()
                }
            }, onCommit: {
                commitDraft()
            })
            .font(.caption.monospacedDigit())
            .multilineTextAlignment(.trailing)
            .frame(width: 30)
            .textFieldStyle(.plain)
            .onChange(of: zoomScale) { _, newScale in
                if !isEditing {
                    draft = "\(Int(round(newScale * 100)))"
                }
            }
            .onAppear {
                draft = "\(Int(round(zoomScale * 100)))"
            }
            Text("%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func commitDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespaces)
        if let v = Double(trimmed), v >= 1 {
            let s = (v / 100.0).clamped(to: configuration.minZoom...configuration.maxZoom)
            setZoom(s, windowSize)
        }
        draft = "\(Int(round(zoomScale * 100)))"
    }
}
#endif
