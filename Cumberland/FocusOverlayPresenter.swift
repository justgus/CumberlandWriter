//
//  FocusOverlayPresenter.swift
//  Cumberland
//
//  macOS stub for the "Focus Mode" overlay presenter. Holds weak references
//  to focus state bindings while focus is active; satisfies the CardSheetView
//  API without presenting a real overlay window. Replace with a full
//  NSWindow-based implementation when focus mode is fully built out.
//

import SwiftUI

#if os(macOS)

/// Minimal placeholder presenter for macOS "Focus" mode.
/// This stub satisfies the CardSheetView API without showing a real overlay.
/// Replace with your actual overlay window/presenter when ready.
final class FocusOverlayPresenter {

    static let shared = FocusOverlayPresenter()

    private init() {}

    // Keep weak references just to hold onto bindings while "presented"
    private var onExitHandler: (() -> Void)?

    // Generic toolbar parameter so call sites can pass `some View` without type erasure.
    func present<Toolbar: View>(
        for card: Card,
        text: Binding<String>,
        selection: Binding<NSRange>,
        toolbar: Toolbar,
        onExit: @escaping () -> Void
    ) {
        // In a real implementation, you'd create and show a borderless overlay window
        // that hosts a rich text editor bound to `text`/`selection` and shows `toolbar`.
        // This stub just stores the exit handler so `dismiss()` can call it if needed.
        self.onExitHandler = onExit
        // No UI shown in this stub.
    }

    func dismiss() {
        // In a real implementation, close the overlay window.
        // Here we just clear the exit handler.
        self.onExitHandler = nil
    }
}

#endif
