//
//  DesyncBannerModifier.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-21.
//  Part of ER-0036: Edge Count Sentinel — Live Desync Detection and Recovery
//
//  Subtle banner that appears when a relationship array desync is detected
//  and recovered. Auto-dismisses after 3 seconds.
//

import SwiftUI

struct DesyncBannerModifier: ViewModifier {
    @Binding var isShowing: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isShowing {
                    Text("Relationship data refreshed")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            Task {
                                try? await Task.sleep(for: .seconds(3))
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isShowing = false
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

extension View {
    func desyncBanner(isShowing: Binding<Bool>) -> some View {
        modifier(DesyncBannerModifier(isShowing: isShowing))
    }
}
