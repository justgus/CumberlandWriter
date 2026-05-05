//
//  ChapterSelectionGrip.swift
//  Cumberland
//
//  Created by Claude Code on 2026-04-26.
//  Chapter Selection Grip - 8pt vertical bar on trailing edge for chapter-level operations.
//
//  Phase 3 Implementation (ER-0056)
//

import SwiftUI

/// Chapter Selection Grip - Trailing edge UI for chapter operations
struct ChapterSelectionGrip: View {
    let chapter: Card
    let sceneCount: Int
    let isActive: Bool

    @State private var isHovered: Bool = false
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(gripColor)
            .frame(width: 8)
            .frame(minHeight: sceneCount == 0 ? 40 : nil)  // Minimum height for empty chapters
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                // TODO: Phase 6 - Select entire chapter
            }
            .contextMenu {
                Button("Cut Chapter") {
                    // TODO: Phase 6 - Cut chapter operation
                }
                Button("Copy Chapter") {
                    // TODO: Phase 6 - Copy chapter operation
                }
                Button("Duplicate Chapter") {
                    // TODO: Phase 6 - Duplicate chapter
                }
                Divider()
                Button("Delete Chapter") {
                    // TODO: Phase 6 - Delete chapter (ER-0053)
                }
                Divider()
                Button("Insert Chapter Above") {
                    // TODO: Phase 6 - Insert chapter above
                }
                Button("Insert Chapter Below") {
                    // TODO: Phase 6 - Insert chapter below
                }
            }
            .overlay {
                // Empty chapter indicator
                if sceneCount == 0 {
                    Text("Empty Chapter")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(90))
                }
            }
    }

    private var gripColor: Color {
        let baseColor = themeManager.currentTheme.colors.textSecondary

        if isHovered {
            return baseColor.opacity(0.6)
        } else if isActive {
            return baseColor.opacity(0.4)
        } else {
            return baseColor.opacity(0.25)  // Always visible
        }
    }
}

// MARK: - Preview

#Preview("Chapter with Scenes") {
    HStack(spacing: 0) {
        #if os(macOS)
        VStack(spacing: 0) {
            Text("Scene 1 text...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.textBackgroundColor))

            Text("Scene 2 text...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(NSColor.textBackgroundColor))
        }
        #else
        VStack(spacing: 0) {
            Text("Scene 1 text...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))

            Text("Scene 2 text...")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
        }
        #endif

        ChapterSelectionGrip(
            chapter: Card.sampleChapter,
            sceneCount: 2,
            isActive: true
        )
    }
    .frame(width: 400, height: 300)
}

#Preview("Empty Chapter") {
    HStack(spacing: 0) {
        Spacer()

        ChapterSelectionGrip(
            chapter: Card.sampleChapter,
            sceneCount: 0,
            isActive: false
        )
    }
    .frame(width: 400, height: 100)
}

// Sample data for preview
extension Card {
    static var sampleChapter: Card {
        Card(kind: .chapters, name: "Chapter 1", subtitle: "", detailedText: "")
    }
}
