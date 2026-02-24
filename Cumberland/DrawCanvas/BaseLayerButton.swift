//
//  BaseLayerButton.swift
//  Cumberland
//
//  Button for selecting base layer fills with platform-specific gestures
//

import SwiftUI
import BrushEngine

// MARK: - Base Layer Button

/// Button for selecting and displaying the current base layer fill
struct BaseLayerButton: View {
    @Binding var canvasState: DrawingCanvasModel
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showingFillMenu: Bool = false
    @State private var showingColorPicker: Bool = false
    @State private var customColor: Color = .white

    var body: some View {
        Button {
            // On macOS, contextMenu handles the menu
            // On iOS, we can optionally show menu on tap
            #if os(iOS) || os(visionOS)
            showingFillMenu = true
            #endif
        } label: {
            HStack(spacing: 8) {
                // Icon
                fillIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text("Base Layer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(fillLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        // macOS: right-click/context menu
        .contextMenu {
            fillMenuContent
        }
        // iOS/visionOS: long-press menu
        #if os(iOS) || os(visionOS)
        .sheet(isPresented: $showingFillMenu) {
            NavigationStack {
                fillMenuList
                    .navigationTitle("Select Base Fill")
                    #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingFillMenu = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .environmentObject(themeManager)
        }
        #endif
        .sheet(isPresented: $showingColorPicker) {
            NavigationStack {
                ColorPicker("Custom Fill Color", selection: $customColor)
                    .padding()
                    .navigationTitle("Custom Color")
                    #if os(iOS) || os(visionOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingColorPicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Apply") {
                                applyCustomColor()
                                showingColorPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
            .environmentObject(themeManager)
        }
    }

    // MARK: - Current Fill Display

    private var fillIcon: some View {
        Group {
            if let fill = currentFill {
                ZStack {
                    Circle()
                        .fill(fill.effectiveColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: fill.fillType.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(contrastingColor(for: fill.effectiveColor))
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: "square.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var fillLabel: String {
        if let fill = currentFill {
            return fill.fillType.displayName
        }
        return "None"
    }

    private var currentFill: LayerFill? {
        canvasState.layerManager?.baseLayerFill
    }

    // ER-0001: Available fill types based on map category
    private var availableFillTypes: [BaseLayerFillType] {
        guard let category = canvasState.mapCategory else {
            // Backward compatibility: show all types if no category set
            return BaseLayerFillType.allCases
        }

        // Filter based on map category
        return BaseLayerFillType.types(for: category)
    }

    // MARK: - Fill Menu (macOS context menu)

    @ViewBuilder
    private var fillMenuContent: some View {
        // ER-0001: Show fill types based on map category
        if canvasState.mapCategory != nil {
            // Category-specific menu (filtered)
            ForEach(availableFillTypes) { fillType in
                fillButton(for: fillType)
            }
        } else {
            // Backward compatibility: show all types in sections
            Section("Exterior") {
                ForEach(BaseLayerFillType.exteriorTypes) { fillType in
                    fillButton(for: fillType)
                }
            }

            Section("Interior") {
                ForEach(BaseLayerFillType.interiorTypes) { fillType in
                    fillButton(for: fillType)
                }
            }
        }

        Divider()

        // Clear fill
        Button(role: .destructive) {
            clearFill()
        } label: {
            Label("Clear Fill", systemImage: "xmark.circle")
        }

        // Custom color
        Button {
            customColor = currentFill?.effectiveColor ?? .white
            showingColorPicker = true
        } label: {
            Label("Custom Color...", systemImage: "eyedropper")
        }
    }

    // MARK: - Fill Menu (iOS/visionOS sheet)

    private var fillMenuList: some View {
        List {
            // ER-0001: Show fill types based on map category
            if canvasState.mapCategory != nil {
                // Category-specific menu (filtered)
                Section {
                    ForEach(availableFillTypes) { fillType in
                        fillRow(for: fillType)
                    }
                }
            } else {
                // Backward compatibility: show all types in sections
                Section("Exterior") {
                    ForEach(BaseLayerFillType.exteriorTypes) { fillType in
                        fillRow(for: fillType)
                    }
                }

                Section("Interior") {
                    ForEach(BaseLayerFillType.interiorTypes) { fillType in
                        fillRow(for: fillType)
                    }
                }
            }

            // Actions
            Section {
                Button(role: .destructive) {
                    clearFill()
                    showingFillMenu = false
                } label: {
                    Label("Clear Fill", systemImage: "xmark.circle")
                }

                Button {
                    showingFillMenu = false
                    customColor = currentFill?.effectiveColor ?? .white
                    showingColorPicker = true
                } label: {
                    Label("Custom Color...", systemImage: "eyedropper")
                }
            }
        }
    }

    private func fillButton(for fillType: BaseLayerFillType) -> some View {
        Button {
            applyFill(fillType)
        } label: {
            Label {
                Text(fillType.displayName)
            } icon: {
                Image(systemName: fillType.icon)
                    .foregroundStyle(fillType.defaultColor)
            }
        }
    }

    private func fillRow(for fillType: BaseLayerFillType) -> some View {
        Button {
            applyFill(fillType)
            showingFillMenu = false
        } label: {
            HStack {
                Circle()
                    .fill(fillType.defaultColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )

                Image(systemName: fillType.icon)
                    .foregroundStyle(fillType.defaultColor)

                Text(fillType.displayName)

                Spacer()

                if currentFill?.fillType == fillType {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Actions

    private func applyFill(_ fillType: BaseLayerFillType) {
        Task {
            await applyFillAsync(fillType)
        }
    }

    @MainActor
    private func applyFillAsync(_ fillType: BaseLayerFillType) async {
        // Show progress indicator
        canvasState.isGeneratingBaseLayer = true

        // Yield to allow UI to update
        await Task.yield()

        // Brief delay to ensure progress indicator is visible
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Perform the actual fill application
        applySynchronousFill(fillType)

        // Keep indicator visible for minimum time
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Hide progress indicator
        canvasState.isGeneratingBaseLayer = false
    }

    private func applySynchronousFill(_ fillType: BaseLayerFillType) {
        // DR-0016.1 + DR-0020: Create terrain metadata for both exterior and interior types
        var terrainMetadata: TerrainMapMetadata? = nil

        // Preserve existing scale regardless of type (for both exterior and interior)
        let existingScale = canvasState.layerManager?.baseLayer?.layerFill?.terrainMetadata?.physicalSizeMiles

        if fillType.category == .exterior {
            // DR-0018.1: Preserve existing map scale if available
            let mapScale = existingScale ?? 100.0  // Default to 100 miles only if no existing scale

            // DR-0018.2: Preserve existing water percentage override if available
            let existingWaterOverride = canvasState.layerManager?.baseLayer?.layerFill?.terrainMetadata?.waterPercentageOverride

            // Create terrain metadata with preserved or default scale
            terrainMetadata = TerrainMapMetadata(
                physicalSizeMiles: mapScale,
                terrainSeed: Int.random(in: 1...999999)
            )

            // Restore water percentage override if it exists
            terrainMetadata?.waterPercentageOverride = existingWaterOverride

            print("[BaseLayerButton] Creating terrain metadata for \(fillType.displayName): \(terrainMetadata!.description)")
            if let existingScale = existingScale {
                print("[BaseLayerButton] Preserved map scale: \(existingScale) mi")
            }
            if let existingWaterOverride = existingWaterOverride {
                print("[BaseLayerButton] Preserved water override: \(Int(existingWaterOverride * 100))%")
            }
        } else if fillType.category == .interior {
            // DR-0020: Preserve scale for interior maps (stored in feet)
            let mapScale = existingScale ?? 100.0  // Default to 100 feet only if no existing scale

            // Create terrain metadata for interior (repurposing physicalSizeMiles to store feet)
            terrainMetadata = TerrainMapMetadata(
                physicalSizeMiles: mapScale,  // Storing feet for interior maps
                terrainSeed: Int.random(in: 1...999999)
            )

            print("[BaseLayerButton] Creating interior metadata for \(fillType.displayName): \(mapScale) ft")
            if let existingScale = existingScale {
                print("[BaseLayerButton] Preserved interior scale: \(existingScale) ft")
            }
        }

        let fill = LayerFill(
            fillType: fillType,
            customColor: nil,
            opacity: 1.0,
            patternSeed: Int.random(in: 1...999999),
            terrainMetadata: terrainMetadata
        )
        canvasState.layerManager?.applyFillToBaseLayer(fill)

        print("[BaseLayerButton] Applied \(fillType.displayName) base layer - usesProceduralTerrain: \(fill.usesProceduralTerrain)")

        // Add haptic feedback on iOS (not available on visionOS)
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    private func clearFill() {
        Task {
            await clearFillAsync()
        }
    }

    @MainActor
    private func clearFillAsync() async {
        // Show progress indicator
        canvasState.isGeneratingBaseLayer = true
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        canvasState.layerManager?.applyFillToBaseLayer(nil)

        // Add haptic feedback on iOS (not available on visionOS)
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif

        try? await Task.sleep(nanoseconds: 300_000_000)
        canvasState.isGeneratingBaseLayer = false
    }

    private func applyCustomColor() {
        Task {
            await applyCustomColorAsync()
        }
    }

    @MainActor
    private func applyCustomColorAsync() async {
        // Show progress indicator
        canvasState.isGeneratingBaseLayer = true
        await Task.yield()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Create fill with current type or default to land
        let fillType = currentFill?.fillType ?? .land
        let fill = LayerFill(fillType: fillType, color: customColor, opacity: 1.0)
        canvasState.layerManager?.applyFillToBaseLayer(fill)

        // Add haptic feedback on iOS (not available on visionOS)
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        try? await Task.sleep(nanoseconds: 300_000_000)
        canvasState.isGeneratingBaseLayer = false
    }

    // MARK: - Helpers

    /// Get contrasting color (black or white) for icon visibility
    private func contrastingColor(for color: Color) -> Color {
        // Simple luminance check
        // This is a basic implementation - could be enhanced
        return color.description.contains("white") || color.description.contains("1.0") ? .black : .white
    }
}

// MARK: - Preview

#if DEBUG
struct BaseLayerButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BaseLayerButton(canvasState: .constant({
                let model = DrawingCanvasModel()
                model.layerManager = LayerManager()
                return model
            }()))

            BaseLayerButton(canvasState: .constant({
                let model = DrawingCanvasModel()
                let manager = LayerManager()
                manager.applyFillToBaseLayer(LayerFill(fillType: .water, customColor: nil, opacity: 1.0))
                model.layerManager = manager
                return model
            }()))
        }
        .padding()
    }
}
#endif
