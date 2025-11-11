//
//  MapWizardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// A procedural wizard for creating and editing maps attached to Map cards.
/// Supports: importing images, drawing custom maps, capturing from Maps app, and AI-assisted generation.
struct MapWizardView: View {
    let card: Card
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Wizard State
    
    /// Current step in the map creation/editing flow
    @State private var currentStep: WizardStep = .welcome
    
    /// Selected creation method
    @State private var selectedMethod: MapCreationMethod?
    
    // MARK: - Import State
    @State private var isImportingImage = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImageData: Data?
    
    // MARK: - Drawing State
    @State private var drawingCanvas: DrawingCanvasState = .init()
    
    // MARK: - Maps Integration State
    @State private var isCapturingFromMaps = false
    @State private var mapsScreenshotData: Data?
    
    // MARK: - AI Generation State
    @State private var generationPrompt: String = ""
    @State private var isGenerating = false
    @State private var generationError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main content area based on current step
            ScrollView {
                stepContentView
                    .padding()
            }
            
            Divider()
            
            // Navigation footer
            footerView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "map.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Map Wizard")
                    .font(.headline)
                Text(currentStep.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            HStack(spacing: 4) {
                ForEach(WizardStep.allCases.indices, id: \.self) { index in
                    Circle()
                        .fill(index <= WizardStep.allCases.firstIndex(of: currentStep)! ? Color.blue : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case .welcome:
            welcomeStepView
        case .selectMethod:
            methodSelectionView
        case .configure:
            configureStepView
        case .finalize:
            finalizeStepView
        }
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStepView: some View {
        VStack(spacing: 24) {
            Image(systemName: "map.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            Text("Welcome to the Map Wizard")
                .font(.title)
                .bold()
            
            Text("Create or edit a map for **\(card.name)**")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("You can:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                FeatureRow(icon: "photo.on.rectangle", title: "Import an Image", description: "Use an existing map image from your library or files")
                FeatureRow(icon: "pencil.and.scribble", title: "Draw a Map", description: "Create a custom map using drawing tools")
                FeatureRow(icon: "map", title: "Capture from Maps", description: "Import a location from Apple Maps")
                FeatureRow(icon: "wand.and.stars", title: "AI-Assisted Generation", description: "Describe your map and let AI help create it")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .frame(maxWidth: 600)
    }
    
    // MARK: - Method Selection Step
    
    private var methodSelectionView: some View {
        VStack(spacing: 20) {
            Text("How would you like to create your map?")
                .font(.title2)
                .bold()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                MethodCard(
                    method: .importImage,
                    isSelected: selectedMethod == .importImage,
                    action: { selectedMethod = .importImage }
                )
                
                MethodCard(
                    method: .draw,
                    isSelected: selectedMethod == .draw,
                    action: { selectedMethod = .draw }
                )
                
                MethodCard(
                    method: .captureFromMaps,
                    isSelected: selectedMethod == .captureFromMaps,
                    action: { selectedMethod = .captureFromMaps }
                )
                
                MethodCard(
                    method: .aiGenerate,
                    isSelected: selectedMethod == .aiGenerate,
                    action: { selectedMethod = .aiGenerate }
                )
            }
        }
        .frame(maxWidth: 800)
    }
    
    // MARK: - Configure Step
    
    @ViewBuilder
    private var configureStepView: some View {
        if let method = selectedMethod {
            switch method {
            case .importImage:
                importImageConfigView
            case .draw:
                drawConfigView
            case .captureFromMaps:
                mapsConfigView
            case .aiGenerate:
                aiGenerateConfigView
            }
        } else {
            Text("Please select a method")
                .foregroundStyle(.secondary)
        }
    }
    
    private var importImageConfigView: some View {
        VStack(spacing: 20) {
            Text("Import Map Image")
                .font(.title2)
                .bold()
            
            if let data = importedImageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 5)
                
                Button("Choose Different Image") {
                    isImportingImage = true
                }
                .buttonStyle(.bordered)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("No image selected")
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Button {
                            isImportingImage = true
                        } label: {
                            Label("Choose from Files", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Choose from Photos", systemImage: "photo")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .frame(maxWidth: 600)
        .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
            if case let .success(url) = result {
                importedImageData = try? Data(contentsOf: url)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    importedImageData = data
                }
            }
        }
    }
    
    private var drawConfigView: some View {
        VStack(spacing: 20) {
            Text("Draw Your Map")
                .font(.title2)
                .bold()
            
            Text("Drawing tools coming soon")
                .foregroundStyle(.secondary)
            
            // Placeholder for future drawing canvas
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 400)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "pencil.and.scribble")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Canvas Drawing Interface")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Future: PencilKit integration with layers, shapes, and custom brushes")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
        }
        .frame(maxWidth: 800)
    }
    
    private var mapsConfigView: some View {
        VStack(spacing: 20) {
            Text("Capture from Apple Maps")
                .font(.title2)
                .bold()
            
            Text("Maps integration coming soon")
                .foregroundStyle(.secondary)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 400)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Apple Maps Integration")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Future: MapKit integration for location selection and screenshot capture")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
        }
        .frame(maxWidth: 800)
    }
    
    private var aiGenerateConfigView: some View {
        VStack(spacing: 20) {
            Text("AI-Assisted Map Generation")
                .font(.title2)
                .bold()
            
            Text("Describe your map and we'll help generate it")
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Map Description")
                    .font(.headline)
                
                TextEditor(text: $generationPrompt)
                    .frame(height: 150)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary, lineWidth: 1)
                    )
                
                Text("Example: \"A fantasy kingdom with mountains in the north, a forest to the east, a river running through the center, and a coastal city in the south.\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if isGenerating {
                ProgressView("Generating map...")
                    .padding()
            }
            
            if let error = generationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                )
            }
            
            Text("⚠️ AI generation not yet implemented")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: 600)
    }
    
    // MARK: - Finalize Step
    
    private var finalizeStepView: some View {
        VStack(spacing: 20) {
            Text("Review & Save")
                .font(.title2)
                .bold()
            
            Text("Your map is ready to be saved")
                .foregroundStyle(.secondary)
            
            // Preview area
            GroupBox("Preview") {
                if let data = importedImageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Text("No map data available")
                        .foregroundStyle(.secondary)
                        .frame(height: 200)
                }
            }
            
            Button {
                saveMap()
            } label: {
                Label("Save Map to Card", systemImage: "checkmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(importedImageData == nil) // For now, only enable if we have data
        }
        .frame(maxWidth: 600)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            if currentStep != .welcome {
                Button {
                    previousStep()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            if currentStep != .finalize {
                Button {
                    nextStep()
                } label: {
                    Label("Continue", systemImage: "chevron.right")
                        .labelStyle(.trailingIcon)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
        }
        .padding()
    }
    
    // MARK: - Navigation Logic
    
    private var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .selectMethod:
            return selectedMethod != nil
        case .configure:
            return true // TODO: Add validation per method
        case .finalize:
            return false // Last step
        }
    }
    
    private func nextStep() {
        guard let currentIndex = WizardStep.allCases.firstIndex(of: currentStep),
              currentIndex < WizardStep.allCases.count - 1 else {
            return
        }
        withAnimation {
            currentStep = WizardStep.allCases[currentIndex + 1]
        }
    }
    
    private func previousStep() {
        guard let currentIndex = WizardStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        withAnimation {
            currentStep = WizardStep.allCases[currentIndex - 1]
        }
    }
    
    // MARK: - Save Logic
    
    private func saveMap() {
        guard let data = importedImageData else { return }
        
        // Save to card (reusing existing image infrastructure)
        let ext = inferFileExtension(from: data) ?? "jpg"
        try? card.setOriginalImageData(data, preferredFileExtension: ext)
        
        try? modelContext.save()
        
        // Reset wizard
        currentStep = .welcome
        selectedMethod = nil
        importedImageData = nil
    }
    
    private func inferFileExtension(from data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String? else {
            return nil
        }
        return UTType(type as String)?.preferredFilenameExtension
    }
}

// MARK: - Supporting Types

extension MapWizardView {
    enum WizardStep: String, CaseIterable {
        case welcome = "Welcome"
        case selectMethod = "Select Method"
        case configure = "Configure"
        case finalize = "Finalize"
        
        var title: String { rawValue }
    }
    
    enum MapCreationMethod: String, CaseIterable, Identifiable {
        case importImage = "Import Image"
        case draw = "Draw Map"
        case captureFromMaps = "Capture from Maps"
        case aiGenerate = "AI Generate"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .importImage: return "photo.on.rectangle"
            case .draw: return "pencil.and.scribble"
            case .captureFromMaps: return "map"
            case .aiGenerate: return "wand.and.stars"
            }
        }
        
        var description: String {
            switch self {
            case .importImage: return "Use an existing image file"
            case .draw: return "Create with drawing tools"
            case .captureFromMaps: return "Import from Apple Maps"
            case .aiGenerate: return "Generate with AI assistance"
            }
        }
    }
    
    struct DrawingCanvasState {
        var paths: [DrawingPath] = []
        var currentColor: Color = .black
        var currentLineWidth: CGFloat = 2.0
    }
    
    struct DrawingPath: Identifiable {
        let id = UUID()
        var points: [CGPoint] = []
        var color: Color
        var lineWidth: CGFloat
    }
}

// MARK: - Helper Views

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MethodCard: View {
    let method: MapWizardView.MapCreationMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: method.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                VStack(spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                    Text(method.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue.opacity(0.1) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    // Replace .quaternary ShapeStyle with a Color approximation to avoid type mismatch
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == TrailingIconLabelStyle {
    static var trailingIcon: TrailingIconLabelStyle { TrailingIconLabelStyle() }
}

import UniformTypeIdentifiers
import ImageIO
