//
//  ToolPaletteState.swift
//  Cumberland
//
//  State management for the floating tool palette UI
//

import SwiftUI
import Foundation

// MARK: - Tool Palette State

/// Observable state for the floating tool palette
@Observable
class ToolPaletteState: Codable {
    // MARK: - UI State

    /// Position of the palette (offset from alignment anchor)
    /// DR-0011: Default position pulls palette onto screen from trailing edge
    #if os(iOS)
    var position: CGPoint = CGPoint(x: -300, y: 100)
    #else
    var position: CGPoint = CGPoint(x: 0, y: 100)
    #endif

    /// Whether the palette is visible
    var isVisible: Bool = true

    /// Currently selected tab
    var selectedTab: PaletteTab = .tools

    /// Width of the palette
    var width: CGFloat = 280

    /// Currently selected brush ID for the inspector
    var selectedBrushID: UUID?

    // MARK: - Initialization

    init(
        position: CGPoint? = nil,
        isVisible: Bool = true,
        selectedTab: PaletteTab = .tools,
        width: CGFloat = 280
    ) {
        // DR-0011: Use platform-specific default position if not provided
        if let position = position {
            self.position = position
        } else {
            #if os(iOS)
            self.position = CGPoint(x: -300, y: 100)
            #else
            self.position = CGPoint(x: 0, y: 100)
            #endif
        }
        self.isVisible = isVisible
        self.selectedTab = selectedTab
        self.width = width
    }

    // MARK: - Palette Tab Enum

    /// Available tabs in the tool palette
    enum PaletteTab: String, CaseIterable, Codable {
        case tools = "Tools"
        case layers = "Layers"

        /// SF Symbol icon for this tab
        var icon: String {
            switch self {
            case .tools:
                return "hammer.fill"
            case .layers:
                return "square.stack.3d.up"
            }
        }

        /// Display name for this tab
        var displayName: String { rawValue }
    }

    // MARK: - Helper Methods

    /// Toggle palette visibility
    func toggleVisibility() {
        isVisible.toggle()
    }

    /// Switch to a specific tab
    func selectTab(_ tab: PaletteTab) {
        selectedTab = tab
    }

    /// Reset to default position
    /// DR-0011: Use platform-specific default position
    func resetPosition() {
        #if os(iOS)
        position = CGPoint(x: -300, y: 100)
        #else
        position = CGPoint(x: 0, y: 100)
        #endif
    }

    /// Clamp position to keep palette visible within bounds
    func clampPosition(within bounds: CGRect, paletteSize: CGSize) {
        let minVisibleWidth: CGFloat = 100
        let minVisibleHeight: CGFloat = 100

        // Ensure at least minVisibleWidth is visible from the right edge
        let maxX = bounds.width - minVisibleWidth
        let minX = -(paletteSize.width - minVisibleWidth)

        // Ensure at least minVisibleHeight is visible from the bottom edge
        let maxY = bounds.height - minVisibleHeight
        let minY: CGFloat = 0

        position.x = max(minX, min(maxX, position.x))
        position.y = max(minY, min(maxY, position.y))
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case position
        case isVisible
        case selectedTab
        case width
        case selectedBrushID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode position from separate x and y values or as CGPoint
        if let x = try? container.decode(CGFloat.self, forKey: .position),
           let y = try? container.decode(CGFloat.self, forKey: .position) {
            position = CGPoint(x: x, y: y)
        } else {
            // DR-0011: Fallback to platform-specific default if decoding fails
            #if os(iOS)
            position = CGPoint(x: -300, y: 100)
            #else
            position = CGPoint(x: 0, y: 100)
            #endif
        }

        isVisible = (try? container.decode(Bool.self, forKey: .isVisible)) ?? true
        selectedTab = (try? container.decode(PaletteTab.self, forKey: .selectedTab)) ?? .tools
        width = (try? container.decode(CGFloat.self, forKey: .width)) ?? 280
        selectedBrushID = try? container.decode(UUID.self, forKey: .selectedBrushID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode position as a custom structure
        var positionContainer = container.nestedContainer(keyedBy: PositionKeys.self, forKey: .position)
        try positionContainer.encode(position.x, forKey: .x)
        try positionContainer.encode(position.y, forKey: .y)

        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(selectedTab, forKey: .selectedTab)
        try container.encode(width, forKey: .width)
        try container.encodeIfPresent(selectedBrushID, forKey: .selectedBrushID)
    }

    private enum PositionKeys: String, CodingKey {
        case x, y
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ToolPaletteState {
    /// Sample state for previews
    static var sample: ToolPaletteState {
        ToolPaletteState()
    }

    /// Sample state with layers tab selected
    static var sampleLayersTab: ToolPaletteState {
        let state = ToolPaletteState()
        state.selectedTab = .layers
        return state
    }
}
#endif
