//
//  CardSheetFocusMode.swift
//  Cumberland
//
//  Extracted from CardSheetView.swift as part of ER-0022 Phase 3.2.
//  Contains the CardSheetFocusButton that toggles distraction-free focus
//  mode, persisting the active card ID via @AppStorage and notifying the
//  FocusOverlayPresenter on macOS.
//

import SwiftUI

/// Focus mode glass button for CardSheetView
struct CardSheetFocusButton: View {
    let cardID: UUID
    @Binding var isFocusModeEnabled: Bool
    @Binding var focusModeCardIDRaw: String
    let onToggle: () -> Void

    @Environment(\.colorScheme) private var scheme

    #if os(macOS)
    @State private var isHovering: Bool = false
    #endif

    private var isActive: Bool {
        isFocusModeEnabled && focusModeCardIDRaw == cardID.uuidString
    }

    var body: some View {
        let icon = isActive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"

        Button {
            onToggle()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .background(
            Circle().fill(.ultraThinMaterial)
        )
        .overlay(
            Circle()
                .stroke(.white.opacity(scheme == .dark ? 0.15 : 0.30), lineWidth: 0.6)
                .blendMode(.overlay)
        )
        .overlay(
            Circle()
                .stroke(.separator.opacity(0.6), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(scheme == .dark ? 0.22 : 0.12), radius: 6, x: 0, y: 3)
        .accessibilityLabel(isActive ? "Exit Focus" : "Enter Focus")
        .help(isActive ? "Exit Focus" : "Enter Focus")
        #if os(macOS)
        .opacity(isActive ? 1.0 : (isHovering ? 1.0 : 0.0))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovering = hovering
            }
        }
        #endif
    }
}

/// Inline focus overlay (iOS fallback / reference)
struct CardSheetFocusInlineOverlay: View {
    let cardName: String
    @Binding var detailsDraft: String
    @Binding var detailsSelection: NSRange
    let toolbar: AnyView
    let onExit: () -> Void
    let onIndent: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                // Top bar with Exit
                HStack {
                    Button {
                        onExit()
                    } label: {
                        Label("Exit Focus", systemImage: "xmark.circle.fill")
                    }
                    .keyboardShortcut(.cancelAction)
                    Spacer()
                }
                .padding(.bottom, 4)

                toolbar
                    .glassToolbarStyle()

                RichTextEditor(
                    text: $detailsDraft,
                    selectedRange: $detailsSelection,
                    isFirstResponder: true,
                    editable: true,
                    onTab: { onIndent(false) },
                    onBacktab: { onIndent(true) }
                )
                .frame(minHeight: 280)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .allowsHitTesting(false)
                )
            }
            .padding()
        }
    }
}

#if os(iOS)
/// Full screen focus cover for iOS
struct FocusFullScreen: View {
    @Binding var isPresented: Bool
    let title: String
    @Binding var detailsText: String
    @Binding var selection: NSRange
    let toolbar: AnyView
    let onExit: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {
                    toolbar
                        .glassToolbarStyle()

                    RichTextEditor(
                        text: $detailsText,
                        selectedRange: $selection,
                        isFirstResponder: true,
                        editable: true
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                    )
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onExit()
                        isPresented = false
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Focus Mode Helper Functions

/// Helper to toggle focus mode for a specific card
func toggleFocusModeForCard(
    cardID: UUID,
    isFocusModeEnabled: Bool,
    focusModeCardIDRaw: String
) {
    if isFocusModeEnabled && focusModeCardIDRaw == cardID.uuidString {
        // Turn off
        UserDefaults.standard.set(false, forKey: "CardDetailFocusModeEnabled")
        UserDefaults.standard.set("", forKey: "CardDetailFocusModeCardID")
    } else {
        // Turn on for this card
        UserDefaults.standard.set(cardID.uuidString, forKey: "CardDetailFocusModeCardID")
        UserDefaults.standard.set(true, forKey: "CardDetailFocusModeEnabled")
    }
}

/// Exit focus mode and optionally save
func exitFocusMode(save: Bool, saveAction: () -> Void) {
    if save {
        saveAction()
    }
    #if os(macOS)
    FocusOverlayPresenter.shared.dismiss()
    #endif
}
