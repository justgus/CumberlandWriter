//
//  ContentPlaceholderView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/4/25.
//

import Foundation
import SwiftUI

struct ContentPlaceholderView: View {
    let title: String
    let subtitle: String
    var systemImage: String? = "rectangle.and.text.magnifyingglass"
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(colorScheme == .dark ? .secondary : .tertiary)
                    .accessibilityHidden(true)
                    // Add internal padding BEFORE the circular glass to avoid clipping
                    .padding(10)
                    .glassEffect(GlassEffect.regular, in: Circle())
                    .padding()
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(colorScheme == .dark ? .secondary : .tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .glassEffect(GlassEffect.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .background {
            // Subtle animated gradient background
            LinearGradient(
                colors: [
                    .clear,
                    Color.accentColor.opacity(0.03),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#Preview {
    Group {
        ContentPlaceholderView(
            title: "No items yet",
            subtitle: "Create a new item to see it here."
        )
        ContentPlaceholderView(
            title: "Select an item",
            subtitle: "Choose an item from the list to see its details.",
            systemImage: "hand.tap"
        )
        .preferredColorScheme(.dark)
    }
    .padding()
}

