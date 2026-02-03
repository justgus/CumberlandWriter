//
//  BrushGridView.swift
//  Cumberland
//
//  Displays a grid of brushes from the active brush set
//

import SwiftUI

// MARK: - Brush Grid View

/// Displays brushes in a grid layout with selection support
struct BrushGridView: View {
    @Binding var canvasState: DrawingCanvasModel

    // Access the brush registry
    private var brushRegistry: BrushRegistry { BrushRegistry.shared }

    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with brush set name
            if let activeBrushSet = brushRegistry.activeBrushSet {
                headerView(for: activeBrushSet)

                Divider()

                // Brush grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredBrushes(from: activeBrushSet)) { brush in
                            BrushGridCell(
                                brush: brush,
                                isSelected: brushRegistry.selectedBrushID == brush.id,
                                onSelect: {
                                    selectBrush(brush)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 300)
            } else {
                noBrushSetView
            }
        }
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    // MARK: - Header

    private func headerView(for brushSet: BrushSet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Brush set picker
            // DR-0040: On iOS, show icon-only to save space
            HStack {
                #if !os(iOS)
                Text("Brush Set:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif

                #if os(iOS)
                // Use Menu instead of Picker on iOS for icon-only button
                Menu {
                    ForEach(availableBrushSets()) { brushSet in
                        Button {
                            brushRegistry.setActiveBrushSet(id: brushSet.id)
                            // Update canvas state if needed
                            if let selectedBrush = brushRegistry.selectedBrush {
                                canvasState.updateToolFromBrush(selectedBrush)
                            }
                        } label: {
                            Label(brushSet.name, systemImage: brushSet.mapType.icon)
                        }
                    }
                } label: {
                    // Show only the icon for the selected brush set
                    Image(systemName: brushSet.mapType.icon)
                        .font(.subheadline)
                }
                #else
                // Use Picker on macOS with full labels
                Picker("", selection: Binding(
                    get: { brushRegistry.activeBrushSetID ?? UUID() },
                    set: { newID in
                        brushRegistry.setActiveBrushSet(id: newID)
                        // Update canvas state if needed
                        if let selectedBrush = brushRegistry.selectedBrush {
                            canvasState.updateToolFromBrush(selectedBrush)
                        }
                    }
                )) {
                    ForEach(availableBrushSets()) { brushSet in
                        Label(brushSet.name, systemImage: brushSet.mapType.icon)
                            .tag(brushSet.id)
                    }
                }
                .pickerStyle(.menu)
                .font(.subheadline)
                #endif

                Spacer()

                // Brush count badge
                Text("\(filteredBrushes(from: brushSet).count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }

            // Layer filter info (if applicable)
            if let activeLayer = canvasState.layerManager?.activeLayer {
                if activeLayer.layerType == .generic {
                    Text("Showing all brushes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    // DR-0040: Allow text to wrap on multiple lines to prevent overflow on iOS
                    Text("Filtered for \(activeLayer.layerType.rawValue) layer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - No Brush Set View

    private var noBrushSetView: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No brush set active")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Load a brush set to begin")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Helper Methods

    /// Get brush sets that are appropriate for the current map type
    private func availableBrushSets() -> [BrushSet] {
        // Get the canvas map category
        guard let mapCategory = canvasState.mapCategory else {
            // No map category set - show all brush sets
            return brushRegistry.installedBrushSets
        }

        // Filter brush sets based on map category
        return brushRegistry.installedBrushSets.filter { brushSet in
            switch mapCategory {
            case .exterior:
                // Exterior maps: show exterior, hybrid, and custom brush sets
                return brushSet.mapType == .exterior || brushSet.mapType == .hybrid || brushSet.mapType == .custom
            case .interior:
                // Interior maps: show interior, hybrid, and custom brush sets
                return brushSet.mapType == .interior || brushSet.mapType == .hybrid || brushSet.mapType == .custom
            }
        }
    }

    /// Filter brushes based on active layer type
    private func filteredBrushes(from brushSet: BrushSet) -> [MapBrush] {
        // Get active layer type if available
        guard let activeLayerType = canvasState.layerManager?.activeLayer?.layerType else {
            // No active layer - show all brushes
            return brushSet.brushes
        }

        // Generic layer shows all brushes (it's a "do anything" layer)
        if activeLayerType == .generic {
            return brushSet.brushes
        }

        // Filter brushes that match the layer type or have no specific requirement
        let filtered = brushSet.brushes.filter { brush in
            if let requiredLayer = brush.requiresLayer {
                return requiredLayer == activeLayerType
            }
            // Brush has no layer requirement - show it
            return true
        }

        // If no brushes match, show all brushes (fallback)
        return filtered.isEmpty ? brushSet.brushes : filtered
    }

    /// Select a brush
    private func selectBrush(_ brush: MapBrush) {
        brushRegistry.selectBrush(id: brush.id)

        // Also update the palette state (for potential inspector use)
        canvasState.toolPaletteState.selectedBrushID = brush.id
    }
}

// MARK: - Brush Grid Cell

/// Individual brush cell in the grid
struct BrushGridCell: View {
    let brush: MapBrush
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Icon
                Image(systemName: brush.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        isSelected ? Color.accentColor : (brush.color ?? .primary)
                    )
                    .frame(height: 32)

                // Name
                Text(brush.name)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
struct BrushGridView_Previews: PreviewProvider {
    static var previews: some View {
        BrushGridView(canvasState: .constant(DrawingCanvasModel()))
            .frame(width: 280)
            .padding()
    }
}
#endif
