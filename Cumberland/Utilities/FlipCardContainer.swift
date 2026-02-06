//
//  FlipCardContainer.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-06.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 3
//  Extracted from CardEditorView.swift
//

import SwiftUI

/// Animated flip container for card-style views
struct FlipCardContainer<Front: View, Back: View>: View {
    @Binding var isFlipped: Bool
    let front: Front
    let back: Back

    init(isFlipped: Binding<Bool>, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self._isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }

    var body: some View {
        ZStack {
            front
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0.0 : 1.0)
                .allowsHitTesting(!isFlipped)

            back
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1.0 : 0.0)
                .allowsHitTesting(isFlipped)
        }
        .animation(.easeInOut(duration: 0.45), value: isFlipped)
        .rotation3DEffect(.degrees(0.0001), axis: (x: 0, y: 0, z: 1)) // nudge to enable perspective on some platforms
        .modifier(Perspective())
    }
}

// Adds a bit of perspective for the 3D flip.
private struct Perspective: ViewModifier {
    func body(content: Content) -> some View {
        #if os(visionOS)
        content
            .compositingGroup()
            .rotation3DEffect(.degrees(0), axis: (x: 0, y: 0, z: 0))
        #else
        content
            .compositingGroup()
            .rotation3DEffect(.degrees(0), axis: (x: 0, y: 0, z: 0), perspective: 0.8)
        #endif
    }
}
