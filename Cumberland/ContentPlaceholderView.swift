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

    var body: some View {
        VStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.title3).bold()
                .multilineTextAlignment(.center)

            Text(subtitle)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
