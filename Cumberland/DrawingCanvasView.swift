//
//  DrawingCanvasView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//

import SwiftUI

#if canImport(PencilKit) && !os(macOS)
import PencilKit
#endif

/// A cross-platform drawing canvas view using PencilKit for creating custom maps

#if canImport(PencilKit) && !os(macOS)
@available(iOS 13.0, *)
struct DrawingCanvasView: View {
    @Binding var canvasData: Data?
    @Binding var hasDrawing: Bool
    
    @State private var canvasView: PKCanvasView = PKCanvasView()
    @State private var selectedTool: DrawingTool = .pen
    @State private var selectedColor: Color = .black
    @State private var showingClearAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            Divider()
            
            // Canvas
            CanvasRepresentable(
                canvasView: $canvasView,
                onDrawingChanged: handleDrawingChanged
            )
            .background(Color(white: 0.95))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onAppear {
            setupCanvas()
            loadExistingDrawing()
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            // Tool selection
            HStack(spacing: 8) {
                ToolButton(
                    tool: .pen,
                    selectedTool: $selectedTool,
                    icon: "pencil.tip"
                )
                
                ToolButton(
                    tool: .marker,
                    selectedTool: $selectedTool,
                    icon: "highlighter"
                )
                
                ToolButton(
                    tool: .pencil,
                    selectedTool: $selectedTool,
                    icon: "pencil"
                )
                
                ToolButton(
                    tool: .eraser,
                    selectedTool: $selectedTool,
                    icon: "eraser.fill"
                )
            }
            
            Divider()
                .frame(height: 24)
            
            // Color picker (not available for eraser)
            if selectedTool != .eraser {
                ColorPicker("Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: selectedColor) { _, newColor in
                        updateToolColor(newColor)
                    }
                
                // Quick color presets
                HStack(spacing: 4) {
                    ForEach([Color.black, .blue, .red, .green, .brown, .orange], id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    canvasView.undoManager?.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!(canvasView.undoManager?.canUndo ?? false))
                .buttonStyle(.bordered)
                
                Button {
                    canvasView.undoManager?.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!(canvasView.undoManager?.canRedo ?? false))
                .buttonStyle(.bordered)
                
                Button {
                    showingClearAlert = true
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .alert("Clear Drawing?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCanvas()
            }
        } message: {
            Text("This will erase all your drawing. This action cannot be undone.")
        }
    }
    
    // MARK: - Canvas Setup
    
    private func setupCanvas() {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        
        // Set initial tool
        updateTool()
    }
    
    private func loadExistingDrawing() {
        guard let data = canvasData,
              let drawing = try? PKDrawing(data: data) else {
            return
        }
        canvasView.drawing = drawing
        hasDrawing = !drawing.bounds.isEmpty
    }
    
    private func updateTool() {
        let tool: PKTool
        
        switch selectedTool {
        case .pen:
            tool = PKInkingTool(.pen, color: platformColor(selectedColor), width: 2)
        case .marker:
            tool = PKInkingTool(.marker, color: platformColor(selectedColor), width: 10)
        case .pencil:
            tool = PKInkingTool(.pencil, color: platformColor(selectedColor), width: 2)
        case .eraser:
            tool = PKEraserTool(.vector)
        case .lasso:
            tool = PKLassoTool()
        }
        
        canvasView.tool = tool
    }
    
    private func updateToolColor(_ color: Color) {
        guard selectedTool != .eraser && selectedTool != .lasso else { return }
        updateTool()
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        hasDrawing = false
        canvasData = nil
    }
    
    private func handleDrawingChanged() {
        let drawing = canvasView.drawing
        hasDrawing = !drawing.bounds.isEmpty
        
        if hasDrawing {
            canvasData = drawing.dataRepresentation()
        } else {
            canvasData = nil
        }
    }
    
    // MARK: - Platform Color Conversion
    
    private func platformColor(_ color: Color) -> PlatformColor {
        return UIColor(color)
    }
}

// MARK: - Drawing Tool

enum DrawingTool {
    case pen
    case marker
    case pencil
    case eraser
    case lasso
}

// MARK: - Tool Button

private struct ToolButton: View {
    let tool: DrawingTool
    @Binding var selectedTool: DrawingTool
    let icon: String
    
    var body: some View {
        Button {
            selectedTool = tool
        } label: {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedTool == tool ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Platform Color Type

typealias PlatformColor = UIColor

// MARK: - Canvas Representable

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let onDrawingChanged: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void
        
        init(onDrawingChanged: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged()
        }
    }
}

#else // PencilKit not available or macOS
// Fallback for platforms without PKCanvasView
struct DrawingCanvasView: View {
    @Binding var canvasData: Data?
    @Binding var hasDrawing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Drawing Not Available")
                .font(.headline)
            
            Text("PKCanvasView is only available on iOS and iPadOS")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
    }
}
#endif
