//
//  ToolsTabView.swift
//  Cumberland
//
//  Tools tab content for the floating palette
//

import SwiftUI

// MARK: - Tools Tab View

/// Displays the tools tab content: base layer button and brush grid
struct ToolsTabView: View {
    @Binding var canvasState: DrawingCanvasModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Base Layer section
            baseLayerSection

            // Divider
            Divider()

            // Brushes section
            brushesSection
        }
    }

    // MARK: - Base Layer Section

    private var baseLayerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Base Layer")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            BaseLayerButton(canvasState: $canvasState)

            // DR-0016.2 + ER-0001: Show scale controls for base layers
            // Exterior maps: show when terrain metadata exists
            // Interior maps: show scale controls with feet units (no terrain metadata needed)
            if let fill = canvasState.layerManager?.baseLayerFill {
                if fill.fillType.category == .exterior && fill.terrainMetadata != nil {
                    terrainScaleControls(for: fill)
                } else if fill.fillType.category == .interior {
                    // ER-0001: Show interior-specific scale controls
                    interiorScaleControls(for: fill)
                }
            }
        }
    }

    // MARK: - Terrain Scale Controls (DR-0016.2)

    private func terrainScaleControls(for fill: LayerFill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Text("Map Scale")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text(scaleCategory(for: fill).displayText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }

            // Scale input and presets
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TextField("Miles", value: Binding(
                        get: { fill.terrainMetadata?.physicalSizeMiles ?? 100.0 },
                        set: { newValue in
                            updateTerrainScale(fill: fill, miles: newValue)
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)

                    Text("mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Quick presets
                HStack(spacing: 6) {
                    scalePresetButton(fill: fill, miles: 5, label: "5")
                    scalePresetButton(fill: fill, miles: 50, label: "50")
                    scalePresetButton(fill: fill, miles: 500, label: "500")
                }

                Text(scaleCategory(for: fill).description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Water percentage slider (only for exterior maps)
            if fill.fillType.category == .exterior {
                waterPercentageSlider(for: fill)
            }
        }
    }

    private func scalePresetButton(fill: LayerFill, miles: Double, label: String) -> some View {
        Button(label) {
            updateTerrainScale(fill: fill, miles: miles)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
    }

    // MARK: - Interior Scale Controls (ER-0001)

    private func interiorScaleControls(for fill: LayerFill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Text("Map Scale")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text("Interior")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }

            // Scale input and presets (feet for interior)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TextField("Feet", value: Binding(
                        get: { fill.terrainMetadata?.physicalSizeMiles ?? 100.0 },
                        set: { newValue in
                            updateInteriorScale(fill: fill, feet: newValue)
                        }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)

                    Text("ft")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Quick presets (feet for interior)
                HStack(spacing: 6) {
                    interiorScalePresetButton(fill: fill, feet: 10, label: "10")
                    interiorScalePresetButton(fill: fill, feet: 50, label: "50")
                    interiorScalePresetButton(fill: fill, feet: 100, label: "100")
                }

                Text("Interior floor scale in feet")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // ER-0001: No water percentage slider for interior maps
        }
    }

    private func interiorScalePresetButton(fill: LayerFill, feet: Double, label: String) -> some View {
        Button(label) {
            updateInteriorScale(fill: fill, feet: feet)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
    }

    // MARK: - Water Percentage Slider

    private func waterPercentageSlider(for fill: LayerFill) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            // Determine label based on terrain type (inverted for water)
            let isWaterType = fill.fillType == .water
            let label = isWaterType ? "Land %" : "Water %"

            // Get current value (use override if present, otherwise terrain type default)
            let currentValue = fill.terrainMetadata?.waterPercentageOverride ?? fill.fillType.waterPercentage

            WaterPercentageSliderView(
                fill: fill,
                isWaterType: isWaterType,
                label: label,
                currentValue: currentValue,
                onUpdate: { newValue in
                    updateWaterPercentage(fill: fill, percentage: newValue)
                }
            )
        }
    }
}

// MARK: - Water Percentage Slider View

private struct WaterPercentageSliderView: View {
    let fill: LayerFill
    let isWaterType: Bool
    let label: String
    let currentValue: Double
    let onUpdate: (Double) -> Void

    @State private var sliderValue: Double
    @State private var isEditing = false

    init(fill: LayerFill, isWaterType: Bool, label: String, currentValue: Double, onUpdate: @escaping (Double) -> Void) {
        self.fill = fill
        self.isWaterType = isWaterType
        self.label = label
        self.currentValue = currentValue
        self.onUpdate = onUpdate
        self._sliderValue = State(initialValue: currentValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(Int((isEditing ? sliderValue : currentValue) * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }

            VStack(alignment: .leading, spacing: 6) {
                Slider(
                    value: $sliderValue,
                    in: 0.01...0.90,
                    step: 0.01,
                    onEditingChanged: { editing in
                        isEditing = editing
                        if !editing {
                            // Only regenerate when slider is released
                            onUpdate(sliderValue)
                        }
                    }
                )

                HStack {
                    Text("1%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("90%")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // Reset button
                Button("Reset to Default") {
                    onUpdate(fill.fillType.waterPercentage)
                }
                .buttonStyle(.plain)
                .font(.caption2)
                .foregroundStyle(.blue)

                if isWaterType {
                    Text("Controls land percentage (inverted)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Controls water/underwater percentage")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - ToolsTabView Continued

extension ToolsTabView {

    private func updateWaterPercentage(fill: LayerFill, percentage: Double?) {
        guard var metadata = fill.terrainMetadata else { return }

        // Generate new terrain seed to show different pattern with new water percentage
        let newSeed = Int.random(in: 1...999999)

        if let percentage = percentage {
            print("[ToolsTabView] Updating water percentage to \(Int(percentage * 100))% with new seed: \(newSeed)")
            metadata.waterPercentageOverride = percentage
        } else {
            print("[ToolsTabView] Resetting water percentage to default with new seed: \(newSeed)")
            metadata.waterPercentageOverride = nil
        }

        // Update terrain seed for new pattern
        metadata.terrainSeed = newSeed

        // Create new fill with updated metadata
        let newFill = LayerFill(
            fillType: fill.fillType,
            customColor: fill.customColor,
            opacity: fill.opacity,
            patternSeed: fill.patternSeed,
            terrainMetadata: metadata
        )

        // Apply to base layer
        canvasState.layerManager?.applyFillToBaseLayer(newFill)

        let displayValue = percentage ?? fill.fillType.waterPercentage
        print("[ToolsTabView] Water percentage updated: \(Int(displayValue * 100))%, new terrain seed: \(newSeed)")
    }

    private func scaleCategory(for fill: LayerFill) -> MapScaleCategory {
        guard let metadata = fill.terrainMetadata else {
            return .medium
        }
        return metadata.scaleCategory
    }

    private func updateTerrainScale(fill: LayerFill, miles: Double) {
        print("[ToolsTabView] Updating terrain scale to \(miles) miles")

        // DR-0016.3: Generate new seed when scale changes
        // Different scales have different compositions, so a fresh terrain pattern makes more sense
        let newSeed = Int.random(in: 1...999999)

        // Preserve water percentage override from existing metadata
        let existingOverride = fill.terrainMetadata?.waterPercentageOverride

        // Create new metadata with updated scale and new seed
        var newMetadata = TerrainMapMetadata(
            physicalSizeMiles: miles,
            terrainSeed: newSeed
        )

        // Restore the water percentage override
        newMetadata.waterPercentageOverride = existingOverride

        // Create new fill with updated metadata
        let newFill = LayerFill(
            fillType: fill.fillType,
            customColor: fill.customColor,
            opacity: fill.opacity,
            patternSeed: fill.patternSeed,
            terrainMetadata: newMetadata
        )

        // Apply to base layer
        canvasState.layerManager?.applyFillToBaseLayer(newFill)

        print("[ToolsTabView] Scale updated - new category: \(newMetadata.scaleCategory.rawValue), dominant: \(Int(newMetadata.dominantTerrainPercentage * 100))%, new seed: \(newSeed)")
    }

    // ER-0001: Update interior scale (stored in terrain metadata for now, but will be used for fixed-scale patterns)
    private func updateInteriorScale(fill: LayerFill, feet: Double) {
        print("[ToolsTabView] Updating interior scale to \(feet) feet")

        // For interior maps, we store the scale in feet using the same metadata structure
        // ER-0001 Phase 4 will use this for fixed-scale floor pattern rendering
        let newSeed = Int.random(in: 1...999999)

        // Create metadata with scale (stored as feet in physicalSizeMiles for now)
        let newMetadata = TerrainMapMetadata(
            physicalSizeMiles: feet,  // Repurposing this field to store feet for interior maps
            terrainSeed: newSeed
        )

        // Create new fill with updated metadata
        let newFill = LayerFill(
            fillType: fill.fillType,
            customColor: fill.customColor,
            opacity: fill.opacity,
            patternSeed: fill.patternSeed,
            terrainMetadata: newMetadata
        )

        // Apply to base layer
        canvasState.layerManager?.applyFillToBaseLayer(newFill)

        print("[ToolsTabView] Interior scale updated: \(feet) ft, new seed: \(newSeed)")
    }

    // MARK: - Brushes Section

    @ViewBuilder
    private var brushesSection: some View {
        if let activeLayer = canvasState.layerManager?.activeLayer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Brushes for \(activeLayer.layerType.rawValue)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                // Placeholder for brush grid
                // This will be replaced with BrushGridView once implemented
                brushGridPlaceholder
            }
        } else {
            // No layer manager - show message
            noLayerManagerView
        }
    }

    private var brushGridPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Brush grid will appear here")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Brushes will be filtered by layer type")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }

    private var noLayerManagerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("No layer manager")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Initialize a LayerManager to use brushes")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#if DEBUG
struct ToolsTabView_Previews: PreviewProvider {
    static var previews: some View {
        ToolsTabView(canvasState: .constant({
            let model = DrawingCanvasModel()
            let manager = LayerManager()
            manager.applyFillToBaseLayer(LayerFill(fillType: .water, customColor: nil, opacity: 1.0))
            model.layerManager = manager
            return model
        }()))
        .padding()
        .frame(width: 280)
    }
}
#endif
