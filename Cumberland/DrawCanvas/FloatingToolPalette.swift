//
//  FloatingToolPalette.swift
//  Cumberland
//
//  Floating, draggable tool palette for the drawing canvas
//

import SwiftUI

// MARK: - Floating Tool Palette

/// A floating, draggable palette containing tools, layers, and inspector tabs
struct FloatingToolPalette: View {
    @Binding var canvasState: DrawingCanvasModel
    let containerSize: CGSize

    @State private var dragOffset: CGSize = .zero
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandleView

            // Tab bar
            tabBarView

            Divider()

            // Tab content
            currentTabView
        }
        .frame(width: canvasState.toolPaletteState.width)
        .frame(maxHeight: 600)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .offset(
            x: canvasState.toolPaletteState.position.x + dragOffset.width,
            y: canvasState.toolPaletteState.position.y + dragOffset.height
        )
        .gesture(dragGesture(in: containerSize))
        .onAppear {
            // DR-0011: Clamp position on first appearance to ensure visibility
            clampPosition(canvasSize: containerSize)
        }
        .onChange(of: containerSize) { _, newSize in
            // DR-0011: Re-clamp when container size changes (e.g., rotation)
            clampPosition(canvasSize: newSize)
        }
    }

    // MARK: - Drag Handle

    private var dragHandleView: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("Tool Palette")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                canvasState.toolPaletteState.toggleVisibility()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05))
        .contentShape(Rectangle()) // Make entire handle draggable
    }

    // MARK: - Tab Bar

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(ToolPaletteState.PaletteTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    private func tabButton(for tab: ToolPaletteState.PaletteTab) -> some View {
        let isSelected = canvasState.toolPaletteState.selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                canvasState.toolPaletteState.selectTab(tab)
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16))
                Text(tab.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .background(
                isSelected ? Color.accentColor.opacity(0.15) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Current Tab Content

    @ViewBuilder
    private var currentTabView: some View {
        ScrollView {
            Group {
                switch canvasState.toolPaletteState.selectedTab {
                case .tools:
                    ToolsTabView(canvasState: $canvasState)
                case .layers:
                    LayersTabView(canvasState: $canvasState)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    // MARK: - Drag Gesture

    private func dragGesture(in canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                // Update final position
                var newPosition = canvasState.toolPaletteState.position
                newPosition.x += value.translation.width
                newPosition.y += value.translation.height

                canvasState.toolPaletteState.position = newPosition

                // DR-0011: Clamp position after drag to keep palette visible
                clampPosition(canvasSize: canvasSize)

                // Reset drag offset
                dragOffset = .zero
            }
    }

    // MARK: - Helper Methods

    /// DR-0011: Clamp palette position to keep it visible within canvas bounds
    private func clampPosition(canvasSize: CGSize) {
        let paletteSize = CGSize(
            width: canvasState.toolPaletteState.width,
            height: 600 // max height from frame modifier
        )

        let bounds = CGRect(origin: .zero, size: canvasSize)
        canvasState.toolPaletteState.clampPosition(within: bounds, paletteSize: paletteSize)
    }
}

// MARK: - Preview

#if DEBUG
struct FloatingToolPalette_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)

            FloatingToolPalette(
                canvasState: .constant(DrawingCanvasModel()),
                containerSize: CGSize(width: 800, height: 600)
            )
            .frame(width: 280)
        }
    }
}
#endif
