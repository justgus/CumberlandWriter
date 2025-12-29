//
//  InspectorTabView.swift
//  Cumberland
//
//  Inspector tab content for the floating palette
//

import SwiftUI

// MARK: - Inspector Tab View

/// Displays the inspector tab content: layer and brush properties
struct InspectorTabView: View {
    @Binding var canvasState: DrawingCanvasModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let layerManager = canvasState.layerManager,
               let activeLayer = layerManager.activeLayer {
                // Layer inspector
                layerInspectorSection(layer: activeLayer, layerManager: layerManager)
            } else {
                emptyStateView
            }
        }
    }

    // MARK: - Layer Inspector

    private func layerInspectorSection(layer: DrawingLayer, layerManager: LayerManager) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Layer Properties")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            // Layer name
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(layer.name)
                    .font(.subheadline)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }

            // Layer type
            VStack(alignment: .leading, spacing: 4) {
                Text("Type")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: layer.layerType.icon)
                        .font(.caption)
                    Text(layer.layerType.rawValue)
                        .font(.subheadline)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }

            // Opacity slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Opacity")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(layer.opacity * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: Binding(
                    get: { layer.opacity },
                    set: { newValue in
                        layerManager.setOpacity(id: layer.id, opacity: newValue)
                    }
                ), in: 0...1)
            }

            // Blend mode
            VStack(alignment: .leading, spacing: 4) {
                Text("Blend Mode")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(LayerBlendMode.allCases, id: \.self) { mode in
                        Button {
                            layerManager.setBlendMode(id: layer.id, blendMode: mode)
                        } label: {
                            HStack {
                                Text(mode.rawValue)
                                if layer.blendMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(layer.blendMode.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Base layer fill info
            if layer.isBaseLayer, let fill = layer.layerFill {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Base Fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack {
                        Circle()
                            .fill(fill.effectiveColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )

                        Image(systemName: fill.fillType.icon)
                            .font(.caption)

                        Text(fill.fillType.displayName)
                            .font(.subheadline)

                        Spacer()
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No layer selected")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Select a layer to view properties")
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
struct InspectorTabView_Previews: PreviewProvider {
    static var previews: some View {
        InspectorTabView(canvasState: .constant({
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
