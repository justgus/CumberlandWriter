//
//  LayersTabView.swift
//  Cumberland
//
//  Layers tab content for the floating palette
//

import SwiftUI
import BrushEngine

// MARK: - Layers Tab View

/// Displays the layers tab content: layer list with visibility and management
struct LayersTabView: View {
    @Binding var canvasState: DrawingCanvasModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let layerManager = canvasState.layerManager {
                // Layer list
                layerListSection(layerManager: layerManager)

                Divider()

                // Actions toolbar
                actionsToolbar(layerManager: layerManager)
            } else {
                noLayerManagerView
            }
        }
    }

    // MARK: - Layer List

    private func layerListSection(layerManager: LayerManager) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Layers")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if layerManager.layers.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 4) {
                    ForEach(layerManager.sortedLayers.reversed()) { layer in
                        layerRow(layer: layer, layerManager: layerManager)
                    }
                }
            }
        }
    }

    private func layerRow(layer: DrawingLayer, layerManager: LayerManager) -> some View {
        HStack(spacing: 8) {
            // Layer icon
            Image(systemName: layer.layerType.icon)
                .font(.caption)
                .foregroundColor(layer.id == layerManager.activeLayerID ? .accentColor : .secondary)
                .frame(width: 20)

            // Layer name and type
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: layer.name)
                    .font(.subheadline)
                    .foregroundColor(layer.id == layerManager.activeLayerID ? .primary : .secondary)

                Text(layer.layerType.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Base layer indicator
            if layer.isBaseLayer, let fill = layer.layerFill {
                Circle()
                    .fill(fill.effectiveColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 0.5)
                    )
            }

            // Visibility toggle
            Button {
                layerManager.toggleVisibility(id: layer.id)
            } label: {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.caption)
                    .foregroundColor(layer.isVisible ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // Lock toggle
            Button {
                layerManager.toggleLock(id: layer.id)
            } label: {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.caption)
                    .foregroundStyle(layer.isLocked ? .orange : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(layer.id == layerManager.activeLayerID ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            // DR-0023: When switching layers, load that layer's drawing into the canvas
            layerManager.selectLayer(id: layer.id)

            #if canImport(PencilKit) && canImport(UIKit)
            // iOS: Load the selected layer's PKDrawing into the canvas view
            if let selectedLayer = layerManager.getLayer(id: layer.id) {
                canvasState.drawing = selectedLayer.drawing
            }
            #endif
        }
        .contextMenu {
            // Change layer type submenu
            Menu {
                ForEach(LayerType.allCases) { layerType in
                    Button {
                        layerManager.setLayerType(id: layer.id, type: layerType)
                    } label: {
                        Label {
                            Text(layerType.rawValue)
                        } icon: {
                            Image(systemName: layerType.icon)
                        }
                    }
                }
            } label: {
                Label("Change Type", systemImage: "arrow.triangle.2.circlepath")
            }

            Divider()

            // Duplicate layer
            Button {
                layerManager.duplicateLayer(id: layer.id)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }

            // Delete layer (if not the last one)
            if layerManager.layers.count > 1 {
                Divider()

                Button(role: .destructive) {
                    layerManager.deleteLayer(id: layer.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Actions Toolbar

    private func actionsToolbar(layerManager: LayerManager) -> some View {
        HStack(spacing: 12) {
            // New layer with type selection
            Menu {
                ForEach(LayerType.allCases) { layerType in
                    Button {
                        layerManager.createLayerAboveActive(type: layerType)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(layerType.rawValue)
                                    .font(.subheadline)
                                Text(layerType.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: layerType.icon)
                        }
                    }
                }
            } label: {
                Label("New", systemImage: "plus.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            Spacer()

            // Delete layer
            Button(role: .destructive) {
                if let activeID = layerManager.activeLayerID {
                    layerManager.deleteLayer(id: activeID)
                }
            } label: {
                Image(systemName: "trash.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .disabled(layerManager.layers.count <= 1) // Don't allow deleting the last layer
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No layers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var noLayerManagerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text("No layer manager")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Initialize a LayerManager to manage layers")
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
struct LayersTabView_Previews: PreviewProvider {
    static var previews: some View {
        LayersTabView(canvasState: .constant({
            let model = DrawingCanvasModel()
            let manager = LayerManager()
            manager.createLayer(name: "Water", type: .water)
            manager.createLayer(name: "Terrain", type: .terrain)
            manager.applyFillToBaseLayer(LayerFill(fillType: .water, customColor: nil, opacity: 1.0))
            model.layerManager = manager
            return model
        }()))
        .padding()
        .frame(width: 280)
    }
}
#endif
