//
//  SceneSelectionGrip.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  Scene Selection Grip - 4pt vertical bar on leading edge for scene-level operations.
//
//  Phase 2 Implementation (ER-0056)
//

import SwiftUI

/// Scene Selection Grip - Leading edge UI for scene operations
struct SceneSelectionGrip: View {
    let scene: Card
    let isActive: Bool

    @State private var isHovered: Bool = false
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(gripColor)
            .frame(width: 4)
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                // TODO: Select entire scene text
            }
            .contextMenu {
                Button("Cut Scene") {
                    // TODO: Phase 5 - Cut scene operation
                }
                Button("Copy Scene") {
                    // TODO: Phase 5 - Copy scene operation
                }
                Button("Duplicate Scene") {
                    // TODO: Phase 5 - Duplicate scene
                }
                Divider()
                Button("Delete Scene") {
                    // TODO: Phase 5 - Delete scene (ER-0053)
                }
                Divider()
                Button("Insert Scene Above") {
                    // TODO: Phase 5 - Insert scene above
                }
                Button("Insert Scene Below") {
                    // TODO: Phase 5 - Insert scene below
                }
            }
    }

    private var gripColor: Color {
        let baseColor = themeManager.currentTheme.colors.accentPrimary

        if isHovered {
            return baseColor.opacity(0.5)
        } else if isActive {
            return baseColor.opacity(0.3)
        } else {
            return baseColor.opacity(0.2)  // Always visible
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        SceneSelectionGrip(scene: Card.sampleScene, isActive: true)
            .frame(height: 200)

        Text("Sample scene text goes here...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
    }
    .frame(width: 400, height: 200)
}

// Sample data for preview
extension Card {
    static var sampleScene: Card {
        Card(kind: .scenes, name: "Sample Scene", subtitle: "", detailedText: "This is sample scene text for preview purposes.")
    }
}
