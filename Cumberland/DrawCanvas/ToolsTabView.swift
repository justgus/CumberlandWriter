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
        }
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
