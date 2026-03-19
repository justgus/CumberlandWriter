//
//  MapWizardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//
//  Multi-step map creation wizard for Map cards. Offers four creation paths:
//  (1) Import Image from file/Photos/drag-drop, (2) Draw with PencilKit layers,
//  (3) Capture from MapKit with location search, (4) AI Generate (placeholder).
//  Persists draft drawing work to allow cross-device resumption.
//

import SwiftUI
import SwiftData
import PhotosUI
import MapKit
import CoreLocation
import Contacts
import BrushEngine
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
    @EnvironmentObject private var themeManager: ThemeManager
    
    // MARK: - Wizard State

    /// Current step in the map creation/editing flow
    // DR-0017: Start directly at method selection (Welcome step removed as redundant)
    @State private var currentStep: WizardStep = .selectMethod
    
    // MARK: - Focus Mode State
    
    /// Persist focus mode state for this wizard session
    @State private var isFocusModeEnabled: Bool = false
    
    /// Selected creation method
    @State private var selectedMethod: MapCreationMethod?
    
    // MARK: - Import State
    @State private var isImportingImage = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedImageData: Data?
    @State private var imageMetadata: ImageMetadataExtractor.ImageMetadata?
    @State private var isDragTargeted = false
    
    // MARK: - Drawing State
    @State private var drawingCanvasModel: DrawingCanvasModel = DrawingCanvasModel()
    
    // Interior-specific UI state (UI-only; drawing still uses DrawingCanvasModel)
    @State private var interiorUnits: InteriorUnits = .feet
    @State private var interiorSnapToGrid: Bool = true

    // MARK: - Terrain/Base Layer State (DR-0016)
    @State private var selectedBaseLayerType: BaseLayerFillType?
    @State private var terrainMapSizeMiles: Double = 100.0 // Default to medium scale

    // MARK: - Maps Integration State
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var currentMapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedMapStyleType: MapStyleType = .standard
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching: Bool = false
    @State private var capturedMapData: Data?
    @State private var mapMetadata: MapCaptureMetadata?
    @State private var isCapturingSnapshot: Bool = false
    @State private var captureError: String?
    
    // MARK: - AI Generation State
    @State private var generationPrompt: String = ""
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var showAIMapGeneration = false

    // MARK: - Draft Restoration State
    @State private var showDraftRestorationPrompt = false
    @State private var hasPendingDraftToRestore = false
    
    // MARK: - Navigation Warning State
    @State private var showBackWarning = false
    @State private var pendingNavigationStep: WizardStep?
    
    // MARK: - Auto-save Timer
    @State private var autoSaveTimer: Timer?
    @State private var debounceSaveTask: Task<Void, Never>?
    
    var body: some View {
        normalWizardView
            #if os(macOS)
            .sheet(isPresented: $isFocusModeEnabled) {
                focusedWorkSurface
                    .frame(minWidth: 1200, idealWidth: 1400, minHeight: 900, idealHeight: 1000)
                    .environmentObject(themeManager)
            }
            #else
            .fullScreenCover(isPresented: $isFocusModeEnabled) {
                focusedWorkSurface
                    .environmentObject(themeManager)
            }
            #endif
            .onAppear {
                checkForDraftWork()
            }
            .onChange(of: isFocusModeEnabled) { _, newValue in
                // Save draft when entering or exiting focus mode
                if newValue {
                    saveDraftWork()
                }
            }
            .onChange(of: selectedMethod) { _, newMethod in
                // ER-0001: Set map category based on creation method
                if let method = newMethod {
                    switch method {
                    case .draw:
                        drawingCanvasModel.mapCategory = .exterior
                    case .interior:
                        drawingCanvasModel.mapCategory = .interior
                    default:
                        // Other methods don't use the drawing canvas base layer system
                        break
                    }
                }
            }
            #if !os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // Save draft when app goes to background on iOS
                saveDraftWork()
            }
            #endif
            .alert("Restore Draft Work?", isPresented: $showDraftRestorationPrompt) {
                Button("Restore") {
                    hasPendingDraftToRestore = false
                    restoreDraftWork()
                }
                Button("Start Fresh", role: .destructive) {
                    hasPendingDraftToRestore = false
                    card.clearDraftMapWork()
                    try? modelContext.save()
                }
                Button("Cancel", role: .cancel) {
                    hasPendingDraftToRestore = false
                }
            } message: {
                if let age = card.draftMapWorkAge {
                    Text("You have unsaved map work from \(relativeTimeString(for: age)). Would you like to continue where you left off?")
                } else {
                    Text("You have unsaved map work. Would you like to continue where you left off?")
                }
            }
            .alert("Discard Unsaved Work?", isPresented: $showBackWarning) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    performBackNavigation()
                }
            } message: {
                Text("Going back will discard your unsaved map work. This cannot be undone.")
            }
            // AI Map Generation sheet (ER-0009 Phase 9.4)
            .sheet(isPresented: $showAIMapGeneration) {
                AIImageGenerationView(
                    cardName: card.name.isEmpty ? "Map" : card.name,
                    cardDescription: generationPrompt,
                    cardKind: .maps,
                    initialPrompt: generationPrompt.isEmpty ? nil : generationPrompt,
                    onImageGenerated: { generatedData in
                        // Store generated map image
                        importedImageData = generatedData.imageData

                        // Clear any error state
                        generationError = nil

                        #if DEBUG
                        print("✅ [MapWizard] AI-generated map ready (\(generatedData.imageData.count) bytes)")
                        #endif
                    }
                )
                .environmentObject(themeManager)
            }
    }
    
    // MARK: - Normal Wizard View
    
    @ViewBuilder
    private var normalWizardView: some View {
        VStack(spacing: 0) {
            // Header (fixed at top)
            headerView
            
            Divider()
            
            // Main content area based on current step
            // Use ScrollView for most steps, but let drawing canvas and map capture fill available space
            // The key is to use flexible space but not let it push the footer off screen
            Group {
                if currentStep == .configure && (selectedMethod == .draw || selectedMethod == .interior || selectedMethod == .captureFromMaps) {
                    stepContentView
                        .padding()
                } else {
                    ScrollView {
                        stepContentView
                            .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // This allows the content to expand
            
            Divider()
            
            // Navigation footer (fixed at bottom)
            footerView
        }
        .background(platformBackgroundColor.opacity(0.5))
        .themeBackground(\.wizardHero, mode: .stretch, opacity: 0.20, theme: themeManager.currentTheme)
    }
    
    // MARK: - Focused Work Surface
    
    @ViewBuilder
    private var focusedWorkSurface: some View {
        ZStack(alignment: .topTrailing) {
            // Full-screen work area
            VStack(spacing: 0) {
                // Minimal header with title and exit button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Map Wizard")
                            .font(.title2)
                            .bold()
                        Text(currentStep.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            isFocusModeEnabled = false
                        }
                    } label: {
                        Label("Exit Focus", systemImage: "arrow.down.right.and.arrow.up.left")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding()
                
                Divider()
                
                // Full work surface based on current method
                if let method = selectedMethod {
                    switch method {
                    case .draw:
                        drawConfigView
                    case .captureFromMaps:
                        mapsConfigView
                    case .importImage:
                        ScrollView {
                            importImageConfigView
                        }
                    case .aiGenerate:
                        ScrollView {
                            aiGenerateConfigView
                        }
                    case .interior:
                        interiorConfigView
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(platformBackgroundColor)
        }
        #if os(macOS)
        .frame(minWidth: 900, idealWidth: 1200, minHeight: 700, idealHeight: 900)
        #endif
    }
    
    // MARK: - Focus Mode Helpers
    
    /// Only show focus mode when in the configure step with a valid method selected
    private var canShowFocusMode: Bool {
        currentStep == .configure && selectedMethod != nil
    }
    
    // Cross-platform background color
    private var platformBackgroundColor: Color {
        #if os(macOS)
        return Color(nsColor: NSColor.controlBackgroundColor)
        #else
        return Color(uiColor: UIColor.systemGroupedBackground)
        #endif
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
            
            // Focus mode toggle (only show when in configure step)
            if canShowFocusMode {
                Button {
                    withAnimation {
                        isFocusModeEnabled.toggle()
                    }
                } label: {
                    Image(systemName: isFocusModeEnabled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.borderless)
                .help(isFocusModeEnabled ? "Exit Focus Mode" : "Enter Focus Mode")
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
            
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
        // DR-0017: Welcome step removed (merged with Select Method)
        case .selectMethod:
            methodSelectionView
        case .configure:
            configureStepView
        case .finalize:
            finalizeStepView
        }
    }
    
    // MARK: - Method Selection Step

    private var methodSelectionView: some View {
        VStack(spacing: 24) {
            // DR-0017: Welcome message merged with method selection
            VStack(spacing: 12) {
                Text("Welcome to Cumberland Map Creator")
                    .font(.title)
                    .bold()

                Text("Create beautiful, professional maps for your tabletop RPG campaigns, worldbuilding projects, or storytelling adventures.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 600)

                Divider()
                    .padding(.vertical, 8)
            }

            // Method selection
            VStack(spacing: 16) {
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
                        method: .interior,
                        isSelected: selectedMethod == .interior,
                        action: { selectedMethod = .interior }
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
                } //end lazyvgrid
            } //end method selection VStack
        } //end outer VStack
        .frame(maxWidth: 800)
    } //end methodSelectionView
    
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
            case .interior:
                interiorConfigView
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
            
            #if os(macOS)
            if let data = importedImageData, let nsImage = NSImage(data: data) {
                VStack(spacing: 16) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                    
                    // Metadata display
                    if let metadata = imageMetadata {
                        metadataDisplayView(metadata)
                    }
                    
                    Button("Choose Different Image") {
                        isImportingImage = true
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Drop zone
                VStack(spacing: 16) {
                    Image(systemName: isDragTargeted ? "photo.badge.plus.fill" : "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(isDragTargeted ? .blue : .secondary)
                        .animation(.easeInOut(duration: 0.2), value: isDragTargeted)
                    
                    Text(isDragTargeted ? "Drop image here" : "Drag & drop image here")
                        .font(.headline)
                        .foregroundStyle(isDragTargeted ? .blue : .secondary)
                    
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
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
                        .fill(isDragTargeted ? Color.blue.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDragTargeted ? Color.blue : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
                .onDrop(of: [.image], isTargeted: $isDragTargeted) { providers in
                    handleDrop(providers: providers)
                }
            }
            #else
            // iOS/iPadOS version
            if let data = importedImageData, let uiImage = UIImage(data: data) {
                VStack(spacing: 16) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                    
                    // Metadata display
                    if let metadata = imageMetadata {
                        metadataDisplayView(metadata)
                    }
                    
                    Button("Choose Different Image") {
                        isImportingImage = true
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: isDragTargeted ? "photo.badge.plus.fill" : "photo.badge.plus")
                        .font(.system(size: 60))
                        .foregroundStyle(isDragTargeted ? .blue : .secondary)
                    
                    Text(isDragTargeted ? "Drop image here" : "Drag & drop image here")
                        .font(.headline)
                        .foregroundStyle(isDragTargeted ? .blue : .secondary)
                    
                    Text("or")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
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
                        .fill(isDragTargeted ? Color.blue.opacity(0.1) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isDragTargeted ? Color.blue : Color.secondary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
                .onDrop(of: [.image], isTargeted: $isDragTargeted) { providers in
                    handleDrop(providers: providers)
                }
            }
            #endif
        }
        .frame(maxWidth: 600)
        .fileImporter(isPresented: $isImportingImage, allowedContentTypes: [.image]) { result in
            if case let .success(url) = result {
                loadImage(from: url)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    loadImage(data: data)
                }
            }
        }
    }
    
    // MARK: - Metadata Display
    
    @ViewBuilder
    private func metadataDisplayView(_ metadata: ImageMetadataExtractor.ImageMetadata) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Image Information")
                    .font(.headline)
                
                if let dims = metadata.formattedDimensions {
                    MetadataRow(icon: "aspectratio", label: "Dimensions", value: dims)
                }
                
                if let size = metadata.formattedFileSize {
                    MetadataRow(icon: "doc", label: "File Size", value: size)
                }
                
                if let format = metadata.format {
                    MetadataRow(icon: "photo", label: "Format", value: format)
                }
                
                if let dpi = metadata.formattedDPI {
                    MetadataRow(icon: "ruler", label: "Resolution", value: dpi)
                }
                
                if let camera = metadata.cameraModel {
                    MetadataRow(icon: "camera", label: "Camera", value: camera)
                }
                
                if metadata.hasGPSData {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("GPS location data available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Image Loading Helpers
    
    private func loadImage(from url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        loadImage(data: data)
    }
    
    private func loadImage(data: Data) {
        importedImageData = data
        imageMetadata = ImageMetadataExtractor.extract(from: data)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                guard let data = data, error == nil else { return }
                
                DispatchQueue.main.async {
                    loadImage(data: data)
                }
            }
            return true
        }
        
        return false
    }
    
    // MARK: - MapKit Search Helpers
    
    private func formatAddress(for item: MKMapItem) -> String? {
        // Simply return the name for now since placemark is deprecated
        // MKMapItem.name contains the place name/address information
        return item.name
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            
            guard let response = response, error == nil else {
                captureError = error?.localizedDescription
                return
            }
            
            searchResults = response.mapItems
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        selectedMapItem = item
        searchResults = []
        
        // Zoom to location
        let coordinate = item.location.coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        // Update our tracked region
        currentMapRegion = region
        
        withAnimation {
            mapCameraPosition = .region(region)
        }
    }
    
    private func captureMapSnapshot() {
        isCapturingSnapshot = true
        captureError = nil
        
        // Use the tracked current map region
        let region = currentMapRegion
        
        // Create snapshot options
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 2048, height: 2048) // High resolution
        
        // Match the current map style
        switch selectedMapStyleType {
        case .standard:
            options.mapType = .standard
        case .imagery:
            options.mapType = .satellite
        case .hybrid:
            options.mapType = .hybrid
        }
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { snapshot, error in
            DispatchQueue.main.async {
                self.isCapturingSnapshot = false
                
                guard let snapshot = snapshot, error == nil else {
                    self.captureError = error?.localizedDescription ?? "Failed to capture map"
                    return
                }
                
                // Determine the map type string for metadata
                let mapTypeString: String = self.selectedMapStyleType.rawValue
                
                // Convert snapshot to image data
                #if os(macOS)
                if let imageData = snapshot.image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: imageData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    self.capturedMapData = pngData
                    self.importedImageData = pngData // Also set this for the wizard flow
                    
                    // Store metadata
                    self.mapMetadata = MapCaptureMetadata(
                        centerCoordinate: region.center,
                        span: region.span,
                        mapType: mapTypeString,
                        captureDate: Date(),
                        locationName: self.selectedMapItem?.name
                    )
                }
                #else
                if let pngData = snapshot.image.pngData() {
                    self.capturedMapData = pngData
                    self.importedImageData = pngData // Also set this for the wizard flow
                    
                    // Store metadata
                    self.mapMetadata = MapCaptureMetadata(
                        centerCoordinate: region.center,
                        span: region.span,
                        mapType: mapTypeString,
                        captureDate: Date(),
                        locationName: self.selectedMapItem?.name
                    )
                }
                #endif
            }
        }
    }
    
    // MARK: - Map Metadata Display
    
    @ViewBuilder
    private func mapMetadataDisplayView(_ metadata: MapCaptureMetadata) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Capture Information")
                    .font(.headline)
                
                if let name = metadata.locationName {
                    MetadataRow(icon: "mappin.circle", label: "Location", value: name)
                }
                
                MetadataRow(
                    icon: "location",
                    label: "Coordinates",
                    value: String(format: "%.4f, %.4f", metadata.centerCoordinate.latitude, metadata.centerCoordinate.longitude)
                )
                
                MetadataRow(icon: "map", label: "Map Type", value: metadata.mapType.capitalized)
                
                MetadataRow(
                    icon: "calendar",
                    label: "Captured",
                    value: metadata.captureDate.formatted(date: .abbreviated, time: .shortened)
                )
                
                MetadataRow(
                    icon: "viewfinder",
                    label: "Span",
                    value: String(format: "%.3f° × %.3f°", metadata.span.latitudeDelta, metadata.span.longitudeDelta)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var drawConfigView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Draw Your Map")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                // Canvas options menu
                Menu {
                    Menu("Canvas Size") {
                        Button("Small (1024×1024)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 1024, height: 1024)
                        }
                        Button("Medium (2048×2048)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 2048, height: 2048)
                        }
                        Button("Large (4096×4096)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 4096, height: 4096)
                        }
                    }
                    
                    Menu("Background Color") {
                        Button("White") { drawingCanvasModel.backgroundColor = .white }
                        Button("Black") { drawingCanvasModel.backgroundColor = .black }
                        Button("Parchment") { drawingCanvasModel.backgroundColor = Color(red: 0.96, green: 0.93, blue: 0.85) }
                        Button("Gray") { drawingCanvasModel.backgroundColor = .gray.opacity(0.2) }
                    }

                    // DR-0016: Base layer fill selection
                    Menu("Base Layer") {
                        Button("None") {
                            selectedBaseLayerType = nil
                            Task { await applyBaseLayerFillAsync(nil) }
                        }

                        Divider()

                        Menu("Exterior") {
                            ForEach(BaseLayerFillType.exteriorTypes) { fillType in
                                Button(fillType.displayName) {
                                    selectedBaseLayerType = fillType
                                    Task { await applyBaseLayerFillAsync(fillType) }
                                }
                            }
                        }

                        Menu("Interior") {
                            ForEach(BaseLayerFillType.interiorTypes) { fillType in
                                Button(fillType.displayName) {
                                    selectedBaseLayerType = fillType
                                    Task { await applyBaseLayerFillAsync(fillType) }
                                }
                            }
                        }
                    }

                    Divider()

                    Toggle("Show Grid", isOn: $drawingCanvasModel.showGrid)
                    
                    if drawingCanvasModel.showGrid {
                        Menu("Grid Spacing") {
                            Button("Small (25pt)") { drawingCanvasModel.gridSpacing = 25 }
                            Button("Medium (50pt)") { drawingCanvasModel.gridSpacing = 50 }
                            Button("Large (100pt)") { drawingCanvasModel.gridSpacing = 100 }
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.blue)
                }
                .menuStyle(.borderlessButton)
                .help("Canvas Options")
            }
            .padding()

            // DR-0016: Terrain scale selector for exterior base layers
            if let baseLayerType = selectedBaseLayerType, baseLayerType.category == .exterior {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Map Scale", systemImage: "ruler")
                            .font(.headline)
                        Spacer()
                        Text(currentScaleCategory.displayText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }

                    HStack(spacing: 12) {
                        Text("Width:")
                            .foregroundStyle(.secondary)

                        TextField("Miles", value: $terrainMapSizeMiles, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: terrainMapSizeMiles) { _, _ in
                                Task { await applyBaseLayerFillAsync(selectedBaseLayerType) }
                            }

                        Text("mi")
                            .foregroundStyle(.secondary)

                        Spacer()

                        // Quick presets
                        Button("5 mi") { terrainMapSizeMiles = 5 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("50 mi") { terrainMapSizeMiles = 50 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        Button("500 mi") { terrainMapSizeMiles = 500 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }

                    Text(currentScaleCategory.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))
                .padding(.horizontal)

                Divider()
            }

            // Drawing canvas - flexible height within available space
            DrawingCanvasView(canvasState: $drawingCanvasModel)
                .frame(minWidth: 400, minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 3)
                .padding()
                // ER-0006: Progress indicator overlay during base layer rendering
                .overlay {
                    if drawingCanvasModel.isGeneratingBaseLayer {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Generating Base Layer...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        .padding()
                    }
                }
        }
        .onChange(of: drawingCanvasModel.drawing) { _, _ in
            // DR-0013: Trigger immediate debounced save when drawing changes
            debouncedSave()
        }
    }
    
    // MARK: - Interior/Architectural Config
    
    private var interiorConfigView: some View {
        VStack(spacing: 0) {
            // DR-0036: Compact header with hamburger menu (like exterior maps)
            HStack {
                Text("Interior / Architectural Maps")
                    .font(.title2)
                    .bold()

                Spacer()

                // DR-0036: Compact options menu (hamburger menu)
                Menu {
                    // Map Presets
                    Menu("Map Presets") {
                        Button {
                            applyInteriorPreset(.floorplan)
                        } label: {
                            Label("Floorplan", systemImage: "house")
                        }

                        Button {
                            applyInteriorPreset(.dungeon)
                        } label: {
                            Label("Dungeon", systemImage: "square.grid.3x3")
                        }

                        Button {
                            applyInteriorPreset(.caverns)
                        } label: {
                            Label("Caverns", systemImage: "mountain.2")
                        }
                    }

                    Divider()

                    // Canvas Settings
                    Menu("Canvas Size") {
                        Button("Small (1024×1024)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 1024, height: 1024)
                        }
                        Button("Medium (2048×2048)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 2048, height: 2048)
                        }
                        Button("Large (4096×4096)") {
                            drawingCanvasModel.canvasSize = CGSize(width: 4096, height: 4096)
                        }
                    }

                    Menu("Background") {
                        Button("White") { drawingCanvasModel.backgroundColor = .white }
                        Button("Dark") { drawingCanvasModel.backgroundColor = .black }
                        Button("Parchment") {
                            drawingCanvasModel.backgroundColor = Color(red: 0.96, green: 0.93, blue: 0.85)
                        }
                        Button("Gray") { drawingCanvasModel.backgroundColor = .gray.opacity(0.2) }
                    }

                    Divider()

                    // Units
                    Picker("Units", selection: $interiorUnits) {
                        ForEach(InteriorUnits.allCases) { u in
                            Text(u.displayName).tag(u)
                        }
                    }

                    Divider()

                    // Grid Settings
                    Toggle("Show Grid", isOn: $drawingCanvasModel.showGrid)

                    if drawingCanvasModel.showGrid {
                        Picker("Grid Type", selection: $drawingCanvasModel.gridType) {
                            ForEach(GridType.allCases) { gt in
                                Text(gt.rawValue).tag(gt)
                            }
                        }

                        Menu("Grid Spacing") {
                            Button("1 ft") { drawingCanvasModel.gridSpacing = 20 }
                            Button("5 ft") { drawingCanvasModel.gridSpacing = 80 }
                            Button("10 ft") { drawingCanvasModel.gridSpacing = 160 }

                            Divider()

                            Button("Custom...") {
                                // Could show a dialog, but slider below also works
                            }
                        }

                        Toggle("Snap to Grid", isOn: $interiorSnapToGrid)
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.blue)
                }
                .menuStyle(.borderlessButton)
                .help("Canvas Options")
            }
            .padding()
            
            Divider()
            
            // Canvas area - flexible height within available space
            DrawingCanvasView(canvasState: $drawingCanvasModel)
                .frame(minWidth: 400, minHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 3)
                .padding()
                // ER-0006: Progress indicator overlay during base layer rendering
                .overlay {
                    if drawingCanvasModel.isGeneratingBaseLayer {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Generating Base Layer...")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        .padding()
                    }
                }
        }
        .onChange(of: drawingCanvasModel.drawing) { _, _ in
            // DR-0013: Trigger immediate debounced save when drawing changes
            debouncedSave()
        }
    }
    
    private func applyInteriorPreset(_ preset: InteriorPreset) {
        switch preset {
        case .floorplan:
            interiorUnits = .feet
            drawingCanvasModel.backgroundColor = .white
            drawingCanvasModel.showGrid = true
            drawingCanvasModel.gridType = .square
            drawingCanvasModel.gridSpacing = 40 // ~2 ft in our arbitrary UI points
            drawingCanvasModel.gridColor = Color.gray.opacity(0.25)
        case .dungeon:
            interiorUnits = .feet
            drawingCanvasModel.backgroundColor = Color(red: 0.96, green: 0.93, blue: 0.85) // parchment
            drawingCanvasModel.showGrid = true
            drawingCanvasModel.gridType = .square
            drawingCanvasModel.gridSpacing = 80 // ~5 ft
            drawingCanvasModel.gridColor = Color.black.opacity(0.15)
        case .caverns:
            interiorUnits = .feet
            drawingCanvasModel.backgroundColor = Color(red: 0.94, green: 0.90, blue: 0.80) // parchment-ish
            drawingCanvasModel.showGrid = true
            drawingCanvasModel.gridType = .square
            drawingCanvasModel.gridSpacing = 80 // ~5 ft
            drawingCanvasModel.gridColor = Color.gray.opacity(0.2)
        }
    }
    
    // MARK: - AI Generate
    
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

            // Show generated map preview if available
            if let imageData = importedImageData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated Map Preview")
                        .font(.headline)

                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(8)
                    }
                    #endif

                    Button("Generate New Map") {
                        showAIMapGeneration = true
                    }
                    .buttonStyle(.bordered)
                }
            }
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
                #if os(macOS)
                previewImageView
                #else
                previewImageView
                #endif
            }
            
            Button {
                saveMap()
            } label: {
                Label("Save Map to Card", systemImage: "checkmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSaveMap)
        }
        .frame(maxWidth: 600)
    }
    
    @ViewBuilder
    private var previewImageView: some View {
        if let method = selectedMethod {
            switch method {
            case .importImage, .captureFromMaps, .aiGenerate:
                // Show imported/captured image
                #if os(macOS)
                if let data = importedImageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    emptyPreviewView
                }
                #else
                if let data = importedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    emptyPreviewView
                }
                #endif
                
            case .draw, .interior:
                // Show drawing preview
                if let imageData = drawingCanvasModel.exportAsImageData() {
                    #if os(macOS)
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                    }
                    #else
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                    }
                    #endif
                } else {
                    emptyPreviewView
                }
            }
        } else {
            emptyPreviewView
        }
    }
    
    private var emptyPreviewView: some View {
        Text("No map data available")
            .foregroundStyle(.secondary)
            .frame(height: 200)
    }
    
    private var canSaveMap: Bool {
        guard let method = selectedMethod else { return false }
        
        switch method {
        case .importImage, .captureFromMaps, .aiGenerate:
            return importedImageData != nil
        case .draw, .interior:
            return !drawingCanvasModel.isEmpty
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // DR-0017: Always show back button (no welcome step to hide it for)
            if currentStep != .selectMethod {
                Button {
                    handleBackButtonTapped()
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
        // DR-0017: Welcome step removed
        case .selectMethod:
            return selectedMethod != nil
        case .configure:
            // Check if we have valid data for the selected method
            guard let method = selectedMethod else { return false }
            switch method {
            case .importImage:
                return importedImageData != nil
            case .draw:
                return !drawingCanvasModel.isEmpty
            case .captureFromMaps:
                return capturedMapData != nil
            case .aiGenerate:
                // Can proceed if prompt is filled (Continue button triggers generation)
                return !generationPrompt.isEmpty
            case .interior:
                return !drawingCanvasModel.isEmpty
            }
        case .finalize:
            return false // Last step
        }
    }
    
    /// Check if navigating back would lose unsaved work
    private var wouldLoseWorkByGoingBack: Bool {
        // Only warn if we're in configure step and have actual work
        guard currentStep == .configure, let method = selectedMethod else {
            return false
        }
        
        switch method {
        case .importImage:
            return importedImageData != nil
        case .draw, .interior:
            return !drawingCanvasModel.isEmpty
        case .captureFromMaps:
            return capturedMapData != nil
        case .aiGenerate:
            return !generationPrompt.isEmpty || importedImageData != nil
        }
    }
    
    /// Handle back button tap with optional warning
    private func handleBackButtonTapped() {
        if wouldLoseWorkByGoingBack {
            showBackWarning = true
        } else {
            previousStep()
        }
    }
    
    /// Actually perform the back navigation (after warning if needed)
    private func performBackNavigation() {
        // Clear draft work when going back from configure step
        if currentStep == .configure {
            card.clearDraftMapWork()
            try? modelContext.save()
        }
        
        previousStep()
    }
    
    private func nextStep() {
        #if DEBUG
        print("➡️ nextStep called - current: \(currentStep.rawValue)")
        #endif

        // ER-0009 Phase 9.4: Trigger AI map generation before advancing
        if currentStep == .configure, selectedMethod == .aiGenerate, importedImageData == nil {
            #if DEBUG
            print("🎨 [MapWizard] Triggering AI map generation")
            #endif
            showAIMapGeneration = true
            return // Don't advance yet - user will return after generation
        }

        guard let currentIndex = WizardStep.allCases.firstIndex(of: currentStep),
              currentIndex < WizardStep.allCases.count - 1 else {
            #if DEBUG
            print("⚠️ Cannot advance - already at last step or invalid index")
            #endif
            return
        }

        let nextStepValue = WizardStep.allCases[currentIndex + 1]
        #if DEBUG
        print("➡️ Advancing from \(currentStep.rawValue) to \(nextStepValue.rawValue)")
        #endif

        // Save draft work before moving to next step
        saveDraftWork()

        withAnimation {
            currentStep = nextStepValue
            // Exit focus mode when navigating steps
            if !canShowFocusMode {
                isFocusModeEnabled = false
            }
        }

        #if DEBUG
        print("✅ Step advanced to: \(currentStep.rawValue)")
        #endif
    }
    
    private func previousStep() {
        guard let currentIndex = WizardStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        
        withAnimation {
            currentStep = WizardStep.allCases[currentIndex - 1]
            // Exit focus mode when navigating steps
            if !canShowFocusMode {
                isFocusModeEnabled = false
            }
        }
    }
    
    // MARK: - Save Logic
    
    private func saveMap() {
        var dataToSave: Data?
        var fileExtension: String = "png"
        
        // Get the appropriate data based on selected method
        if let method = selectedMethod {
            switch method {
            case .importImage, .captureFromMaps, .aiGenerate:
                dataToSave = importedImageData
                fileExtension = inferFileExtension(from: dataToSave ?? Data()) ?? "png"
            case .draw, .interior:
                // Export drawing as PNG image
                dataToSave = drawingCanvasModel.exportAsImageData()
                fileExtension = "png"
                
                // Optionally: Save raw drawing data for future re-editing
                // let drawingData = drawingCanvasModel.exportDrawingData()
                // Store this somewhere if you want to support re-editing later
            }
        }
        
        guard let data = dataToSave else { return }
        
        // Save to card (reusing existing image infrastructure)
        try? card.setOriginalImageData(data, preferredFileExtension: fileExtension)
        
        // Create automatic image attribution citation from metadata
        createAutomaticImageCitation()
        
        // Clear draft work since we've finalized the map
        card.clearDraftMapWork()
        
        try? modelContext.save()
        
        // Stop auto-save
        stopAutoSave()
        
        // Reset wizard
        resetWizard()
    }
    
    /// Create an automatic Citation for the image based on extracted metadata or map capture info
    private func createAutomaticImageCitation() {
        // Determine source and citation details based on image origin
        let sourceTitle: String
        let sourceAuthors: String
        let locator: String
        let contextNote: String?
        
        if let mapMeta = mapMetadata {
            // Map capture - create citation for Apple Maps
            sourceTitle = "Apple Maps"
            sourceAuthors = "Apple Inc."
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let dateStr = formatter.string(from: mapMeta.captureDate)
            
            // Locator includes the location name if available
            if let name = mapMeta.locationName {
                locator = "\(name)"
            } else {
                locator = "\(mapMeta.mapType.capitalized) view"
            }
        
        // Exit focus mode
        isFocusModeEnabled = false

            
            // Context note includes additional details
            var noteComponents: [String] = []
            noteComponents.append("\(mapMeta.mapType.capitalized) map view")
            noteComponents.append("Captured \(dateStr)")
            noteComponents.append("Center: \(String(format: "%.4f", mapMeta.centerCoordinate.latitude)), \(String(format: "%.4f", mapMeta.centerCoordinate.longitude))")
            contextNote = noteComponents.joined(separator: " • ")
            
        } else if let metadata = imageMetadata {
            // Imported image with EXIF metadata
            if let camera = metadata.cameraModel ?? metadata.cameraMake {
                // Photo from camera/phone
                sourceTitle = camera
                sourceAuthors = metadata.cameraMake ?? "Unknown"
                
                // Locator: date and dimensions
                var locatorParts: [String] = []
                if let date = metadata.dateTimeTaken {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    locatorParts.append(formatter.string(from: date))
                }
                if let dims = metadata.formattedDimensions {
                    locatorParts.append(dims)
                }
                locator = locatorParts.isEmpty ? "Image" : locatorParts.joined(separator: " • ")
                
                // Context note: technical details
                var noteComponents: [String] = []
                if let software = metadata.software {
                    noteComponents.append("Software: \(software)")
                }
                if let format = metadata.format {
                    noteComponents.append("Format: \(format)")
                }
                if metadata.hasGPSData {
                    noteComponents.append("📍 Geotagged")
                }
                contextNote = noteComponents.isEmpty ? nil : noteComponents.joined(separator: " • ")
                
            } else if let software = metadata.software {
                // Image from software (screenshot, export, etc.)
                sourceTitle = software
                sourceAuthors = "Digital Image"
                
                var locatorParts: [String] = []
                if let dims = metadata.formattedDimensions {
                    locatorParts.append(dims)
                }
                if let format = metadata.format {
                    locatorParts.append(format)
                }
                locator = locatorParts.isEmpty ? "Image" : locatorParts.joined(separator: " • ")
                contextNote = nil
                
            } else {
                // Generic image with no useful metadata
                return // Don't create automatic citation for generic images
            }
        } else {
            // No metadata available - don't create automatic citation
            return
        }
        
        // Find or create the source
        let fetchDescriptor = FetchDescriptor<Source>(
            predicate: #Predicate<Source> { source in
                source.title == sourceTitle && source.authors == sourceAuthors
            }
        )
        
        let existingSource = try? modelContext.fetch(fetchDescriptor).first
        let source: Source
        
        if let existing = existingSource {
            source = existing
        } else {
            source = Source(
                title: sourceTitle,
                authors: sourceAuthors,
                accessedDate: Date()
            )
            modelContext.insert(source)
        }
        
        // Create the citation
        let citation = Citation(
            card: card,
            source: source,
            kind: .image,
            locator: locator,
            excerpt: "", // Empty excerpt for automatic citations
            contextNote: contextNote,
            createdAt: Date()
        )
        
        modelContext.insert(citation)
    }
    
    private func resetWizard() {
        // DR-0017: Reset to method selection (no welcome step)
        currentStep = .selectMethod
        selectedMethod = nil
        importedImageData = nil
        imageMetadata = nil
        isDragTargeted = false
        
        // Reset map state
        mapCameraPosition = .automatic
        selectedMapStyleType = .standard
        searchText = ""
        searchResults = []
        selectedMapItem = nil
        isSearching = false
        capturedMapData = nil
        mapMetadata = nil
        isCapturingSnapshot = false
        captureError = nil
        
        // Exit focus mode
        isFocusModeEnabled = false
        
        // Stop auto-save timer
        stopAutoSave()
    }
    
    // MARK: - Draft Work Management
    
    /// Format a relative time string for the given age in seconds
    private func relativeTimeString(for age: TimeInterval) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(fromTimeInterval: -age)
    }
    
    /// Check if there's existing draft work and prompt user to restore it
    private func checkForDraftWork() {
        if card.hasDraftMapWork {
            hasPendingDraftToRestore = true
            showDraftRestorationPrompt = true
        } else {
            // No draft work, start auto-save immediately when user starts working
            startAutoSaveIfNeeded()
        }
    }
    
    /// Restore draft work from the card
    private func restoreDraftWork() {
        guard let draftData = card.draftMapWorkData,
              let methodRaw = card.draftMapMethodRaw else {
            #if DEBUG
            print("⚠️ No draft data to restore")
            #endif
            return
        }

        #if DEBUG
        print("📦 Restoring draft work for method: \(methodRaw)")
        #endif

        // Restore the selected method first
        guard let method = MapCreationMethod(rawValue: methodRaw) else {
            #if DEBUG
            print("⚠️ Invalid method: \(methodRaw)")
            #endif
            return
        }

        // Restore method-specific state FIRST before changing wizard state
        switch method {
        case .draw, .interior:
            // Restore drawing canvas state
            guard !draftData.isEmpty else {
                #if DEBUG
                print("⚠️ Canvas state data is empty, skipping restore")
                #endif
                break
            }
            do {
                try drawingCanvasModel.importCanvasState(draftData)
                #if DEBUG
                print("✅ Restored drawing canvas state")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Failed to restore canvas state (data may be corrupted): \(error)")
                #endif
            }

        case .importImage:
            // For imported images, the data is the image itself
            importedImageData = draftData
            imageMetadata = ImageMetadataExtractor.extract(from: draftData)
            #if DEBUG
            print("✅ Restored imported image data")
            #endif

        case .captureFromMaps:
            // For map captures, restore the captured image and metadata
            // Try to restore metadata if it was encoded
            if let container = try? JSONDecoder().decode(MapCaptureMetadataContainer.self, from: draftData) {
                mapMetadata = container.metadata
                capturedMapData = container.imageData
                importedImageData = container.imageData // Also set this for the wizard flow
                #if DEBUG
                print("✅ Restored map capture with metadata")
                #endif
            } else {
                // Fallback if no container structure (legacy data)
                capturedMapData = draftData
                importedImageData = draftData
                #if DEBUG
                print("✅ Restored map capture (legacy format)")
                #endif
            }

        case .aiGenerate:
            // For AI generation, restore the prompt and any generated data
            if let container = try? JSONDecoder().decode(AIGenerationDraft.self, from: draftData) {
                generationPrompt = container.prompt
                importedImageData = container.generatedImageData
                #if DEBUG
                print("✅ Restored AI generation draft")
                #endif
            }
        }

        // Now restore UI state with animation
        withAnimation {
            selectedMethod = method

            // Restore wizard step if saved, otherwise default to configure
            if let stepRaw = card.draftMapWizardStepRaw,
               let step = WizardStep(rawValue: stepRaw) {
                currentStep = step
                #if DEBUG
                print("📍 Restored to step: \(step.rawValue)")
                #endif
            } else {
                currentStep = .configure
                #if DEBUG
                print("📍 Defaulting to configure step")
                #endif
            }

            // DR-0017: Ensure we skip the selectMethod step by going directly to configure if we have draft data
            if currentStep == .selectMethod {
                currentStep = .configure
                #if DEBUG
                print("📍 Corrected to configure step")
                #endif
            }
        }

        // Start auto-save for continued work
        startAutoSaveIfNeeded()
        #if DEBUG
        print("✅ Draft restoration complete - currentStep: \(currentStep.rawValue), method: \(method.rawValue)")
        #endif
    }
    
    /// Start auto-save timer if in a saveable state
    private func startAutoSaveIfNeeded() {
        guard autoSaveTimer == nil else { return }
        
        // Auto-save every 30 seconds when actively working
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await autoSaveDraftWork()
            }
        }
    }
    
    /// Stop auto-save timer
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        debounceSaveTask?.cancel()
        debounceSaveTask = nil
    }

    /// DR-0013: Debounced save - saves 2 seconds after last drawing change
    private func debouncedSave() {
        // Cancel any pending save
        debounceSaveTask?.cancel()

        // Schedule new save after 2 second delay
        debounceSaveTask = Task {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    #if DEBUG
                    print("[DEBOUNCE] Drawing changed - triggering save")
                    #endif
                    Task {
                        await autoSaveDraftWork()
                    }
                }
            } catch {
                // Task was cancelled, ignore
            }
        }

        // Also ensure the periodic timer is running
        startAutoSaveIfNeeded()
    }
    
    /// Auto-save current work as draft
    @MainActor
    private func autoSaveDraftWork() async {
        // Only save if we're in a state where there's actual work to save
        guard let method = selectedMethod else {
            return
        }
        
        // Allow saving from configure and finalize steps
        guard currentStep == .configure || currentStep == .finalize else {
            return
        }
        
        var draftData: Data?
        
        switch method {
        case .draw, .interior:
            // Save complete canvas state
            #if DEBUG
            print("[SAVE] autoSaveDraftWork - Exporting canvas state for \(method)")
            #endif
            draftData = drawingCanvasModel.exportCanvasState()
            #if DEBUG
            print("[SAVE] Got \(draftData?.count ?? 0) bytes of canvas state")
            #endif

        case .importImage:
            // Save the imported image data
            draftData = importedImageData
            
        case .captureFromMaps:
            // Save map capture with metadata
            if let imageData = capturedMapData {
                let container = MapCaptureMetadataContainer(
                    imageData: imageData,
                    metadata: mapMetadata
                )
                draftData = try? JSONEncoder().encode(container)
            }
            
        case .aiGenerate:
            // Save prompt and any generated image
            let draft = AIGenerationDraft(
                prompt: generationPrompt,
                generatedImageData: importedImageData
            )
            draftData = try? JSONEncoder().encode(draft)
        }
        
        if let data = draftData, !data.isEmpty {
            #if DEBUG
            print("[SAVE] Persisting \(data.count) bytes to card as draft")
            #endif
            card.saveDraftMapWork(data, method: method.rawValue, wizardStep: currentStep.rawValue)

            // DR-0010: Properly handle save errors to diagnose CloudKit sync issues
            do {
                try modelContext.save()
                #if DEBUG
                print("[SAVE] ✅ Draft saved successfully to local store")
                print("[SAVE] 📡 CloudKit will sync in background (if enabled)")
                #endif
            } catch {
                #if DEBUG
                print("[SAVE] ❌ Failed to save draft: \(error)")
                print("[SAVE] ⚠️ Draft data will NOT sync to other devices")
                #endif
                // Don't throw - allow app to continue but log the failure
            }
        } else {
            #if DEBUG
            print("[SAVE] ⚠️ No data to save (draftData is nil or empty)")
            #endif
        }
    }
    
    /// Manually save draft work (called when user navigates away or enters focus mode)
    private func saveDraftWork() {
        Task {
            await autoSaveDraftWork()
        }
    }
    
    private func inferFileExtension(from data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String? else {
            return nil
        }
        return UTType(type as String)?.preferredFilenameExtension
    }
    
    // MARK: - Maps Config View (NEW)
    private var mapsConfigView: some View {
        VStack(spacing: 16) {
            // Header and controls
            HStack(spacing: 12) {
                Text("Capture from Apple Maps")
                    .font(.title2).bold()
                Spacer()
                // Map style picker
                Picker("Style", selection: $selectedMapStyleType) {
                    ForEach(MapStyleType.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            
            // Search bar
            HStack(spacing: 8) {
                TextField("Search places or addresses", text: $searchText, onCommit: performSearch)
                    .textFieldStyle(.roundedBorder)
                Button {
                    performSearch()
                } label: {
                    if isSearching {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // Results list
            if !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectLocation(item)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "mappin.circle")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Unnamed")
                                        .font(.subheadline).bold()
                                    if let address = formatAddress(for: item) {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        Divider().opacity(0.2)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.background)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.quaternary, lineWidth: 1)
                )
            }
            
            // Map view
            VStack(spacing: 8) {
                Map(position: $mapCameraPosition) {
                    if let selected = selectedMapItem {
                        Annotation(selected.name ?? "Selected", coordinate: selected.location.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .mapStyle(selectedMapStyleType.mapStyle)
                .frame(minHeight: 320, idealHeight: 500, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .onMapCameraChange { context in
                    // Track region for snapshotter
                    currentMapRegion = context.region
                }
                
                HStack {
                    Button {
                        // Center on user’s approximate region if available (no location permission required)
                        withAnimation {
                            mapCameraPosition = .region(currentMapRegion)
                        }
                    } label: {
                        Label("Reset View", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button {
                        captureMapSnapshot()
                    } label: {
                        if isCapturingSnapshot {
                            ProgressView()
                                .padding(.horizontal, 8)
                        } else {
                            Label("Capture Snapshot", systemImage: "camera.viewfinder")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Error
            if let captureError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(captureError)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8).fill(.orange.opacity(0.1))
                )
            }
            
            // Captured preview + metadata
            if let data = capturedMapData {
                #if os(macOS)
                if let img = NSImage(data: data) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                        if let meta = mapMetadata {
                            mapMetadataDisplayView(meta)
                        }
                    }
                }
                #else
                if let img = UIImage(data: data) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                        if let meta = mapMetadata {
                            mapMetadataDisplayView(meta)
                        }
                    }
                }
                #endif
            }
        }
        .padding()
    }
}

// MARK: - Supporting Types

extension MapWizardView {
    enum MapStyleType: String, CaseIterable {
        case standard
        case imagery
        case hybrid
        
        var mapStyle: MapStyle {
            switch self {
            case .standard:
                return .standard
            case .imagery:
                return .imagery
            case .hybrid:
                return .hybrid
            }
        }
        
        var displayName: String {
            switch self {
            case .standard: return String(localized: "Standard")
            case .imagery:  return String(localized: "Satellite")
            case .hybrid:   return String(localized: "Hybrid")
            }
        }
    }

    enum WizardStep: String, CaseIterable {
        // DR-0017: Welcome step removed (merged with Select Method)
        case selectMethod = "Select Method"
        case configure = "Configure"
        case finalize = "Finalize"

        var title: String {
            switch self {
            case .selectMethod: return String(localized: "Select Method")
            case .configure:    return String(localized: "Configure")
            case .finalize:     return String(localized: "Finalize")
            }
        }
    }

    enum MapCreationMethod: String, CaseIterable, Identifiable {
        case importImage = "Import Image"
        case draw = "Draw Map"
        case interior = "Interior / Architectural"
        case captureFromMaps = "Capture from Maps"
        case aiGenerate = "AI Generate"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .importImage: return "photo.on.rectangle"
            case .draw: return "pencil.and.scribble"
            case .interior: return "square.grid.3x3"
            case .captureFromMaps: return "map"
            case .aiGenerate: return "wand.and.stars"
            }
        }

        var description: String {
            switch self {
            case .importImage:    return String(localized: "Use an existing image file")
            case .draw:           return String(localized: "Create with drawing tools")
            case .interior:       return String(localized: "Floorplans, dungeons, caverns with grid presets")
            case .captureFromMaps: return String(localized: "Import from Apple Maps")
            case .aiGenerate:     return String(localized: "Generate with AI assistance")
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
    
    struct MapCaptureMetadata {
        let centerCoordinate: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        let mapType: String
        let captureDate: Date
        let locationName: String?
    }
    
    enum InteriorPreset {
        case floorplan
        case dungeon
        case caverns
    }
    
    enum InteriorUnits: String, CaseIterable, Identifiable {
        case feet = "Feet"
        case meters = "Meters"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .feet:   return String(localized: "Feet")
            case .meters: return String(localized: "Meters")
            }
        }
    }
    
    // MARK: - Draft Persistence Containers
    
    /// Container for map capture draft data with metadata
    struct MapCaptureMetadataContainer: Codable {
        let imageData: Data
        let metadata: MapCaptureMetadata?
    }
    
    /// Container for AI generation draft data
    struct AIGenerationDraft: Codable {
        let prompt: String
        let generatedImageData: Data?
    }
}

// Make MapCaptureMetadata Codable for persistence
extension MapWizardView.MapCaptureMetadata: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case latitudeDelta
        case longitudeDelta
        case mapType
        case captureDate
        case locationName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        let latitudeDelta = try container.decode(Double.self, forKey: .latitudeDelta)
        let longitudeDelta = try container.decode(Double.self, forKey: .longitudeDelta)
        
        self.centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        self.mapType = try container.decode(String.self, forKey: .mapType)
        self.captureDate = try container.decode(Date.self, forKey: .captureDate)
        self.locationName = try? container.decode(String.self, forKey: .locationName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(centerCoordinate.latitude, forKey: .latitude)
        try container.encode(centerCoordinate.longitude, forKey: .longitude)
        try container.encode(span.latitudeDelta, forKey: .latitudeDelta)
        try container.encode(span.longitudeDelta, forKey: .longitudeDelta)
        try container.encode(mapType, forKey: .mapType)
        try container.encode(captureDate, forKey: .captureDate)
        try container.encodeIfPresent(locationName, forKey: .locationName)
    }
}

// MARK: - Base Layer Helpers (DR-0016)

extension MapWizardView {
    /// Current scale category based on terrain map size
    private var currentScaleCategory: MapScaleCategory {
        if terrainMapSizeMiles < 10 {
            return .small
        } else if terrainMapSizeMiles < 100 {
            return .medium
        } else {
            return .large
        }
    }

    /// ER-0006: Async wrapper for base layer fill with progress indicator
    @MainActor
    private func applyBaseLayerFillAsync(_ fillType: BaseLayerFillType?) async {
        // Show progress indicator
        drawingCanvasModel.isGeneratingBaseLayer = true

        // Critical: Yield immediately to allow UI to update and show the progress indicator
        // This ensures the modal dismisses and the indicator appears before heavy work starts
        await Task.yield()

        // Brief delay to ensure the UI has fully rendered the progress indicator
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Apply the fill (this is where the expensive rendering happens)
        // Note: This still runs on main thread but UI has already updated
        applyBaseLayerFill(fillType)

        // Keep indicator visible for minimum time to be noticeable
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Hide progress indicator
        drawingCanvasModel.isGeneratingBaseLayer = false
    }

    /// Apply base layer fill to the drawing canvas
    /// - Parameter fillType: The fill type to apply, or nil to remove
    private func applyBaseLayerFill(_ fillType: BaseLayerFillType?) {
        // Get or create layer manager
        if drawingCanvasModel.layerManager == nil {
            #if DEBUG
            print("[MapWizard] Creating new LayerManager")
            #endif
            drawingCanvasModel.layerManager = LayerManager()
        }

        guard let layerManager = drawingCanvasModel.layerManager else {
            #if DEBUG
            print("[MapWizard] ERROR: LayerManager is nil after creation")
            #endif
            return
        }

        // Apply fill or remove it
        if let fillType = fillType {
            #if DEBUG
            print("[MapWizard] Applying base layer: \(fillType.displayName), category: \(fillType.category.rawValue)")

            // DR-0018.1: Preserve existing map scale if available
            print("[MapWizard] DEBUG - baseLayer exists: \(layerManager.baseLayer != nil)")
            print("[MapWizard] DEBUG - layerFill exists: \(layerManager.baseLayer?.layerFill != nil)")
            print("[MapWizard] DEBUG - terrainMetadata exists: \(layerManager.baseLayer?.layerFill?.terrainMetadata != nil)")
            #endif

            let existingScale = layerManager.baseLayer?.layerFill?.terrainMetadata?.physicalSizeMiles
            #if DEBUG
            print("[MapWizard] DEBUG - existingScale: \(existingScale?.description ?? "nil")")
            print("[MapWizard] DEBUG - terrainMapSizeMiles fallback: \(terrainMapSizeMiles)")
            #endif

            let mapScale = existingScale ?? terrainMapSizeMiles

            // DR-0018.2: Preserve existing water percentage override if available
            let existingWaterOverride = layerManager.baseLayer?.layerFill?.terrainMetadata?.waterPercentageOverride

            // Create terrain metadata for exterior types
            var terrainMetadata: TerrainMapMetadata? = nil
            if fillType.category == .exterior {
                terrainMetadata = TerrainMapMetadata(
                    physicalSizeMiles: mapScale,  // Use preserved scale
                    terrainSeed: Int.random(in: 1...999999)
                )

                // Restore water percentage override
                terrainMetadata?.waterPercentageOverride = existingWaterOverride

                #if DEBUG
                print("[MapWizard] Created terrain metadata: \(terrainMetadata!.description)")
                if existingScale != nil {
                    print("[MapWizard] Preserved map scale: \(mapScale) mi")
                }
                if existingWaterOverride != nil {
                    print("[MapWizard] Preserved water override: \(Int(existingWaterOverride! * 100))%")
                }
                #endif
            }

            // Create and apply the fill
            let fill = LayerFill(
                fillType: fillType,
                customColor: nil,
                opacity: 1.0,
                patternSeed: Int.random(in: 1...999999),
                terrainMetadata: terrainMetadata
            )

            #if DEBUG
            print("[MapWizard] LayerFill created - usesProceduralTerrain: \(fill.usesProceduralTerrain), usesProceduralPattern: \(fill.usesProceduralPattern)")
            #endif

            layerManager.applyFillToBaseLayer(fill)

            #if DEBUG
            // Verify the fill was applied
            if let appliedFill = layerManager.baseLayer?.layerFill {
                print("[MapWizard] Fill successfully applied to base layer. Metadata: \(appliedFill.terrainMetadata?.description ?? "none")")
            } else {
                print("[MapWizard] ERROR: Fill was not applied to base layer")
            }

            print("[MapWizard] Applied \(fillType.displayName) base layer" +
                  (terrainMetadata != nil ? " with terrain scale: \(terrainMapSizeMiles) mi (\(currentScaleCategory.rawValue))" : ""))
            #endif
        } else {
            // Remove fill
            layerManager.applyFillToBaseLayer(nil)
            #if DEBUG
            print("[MapWizard] Removed base layer fill")
            #endif
        }

        // @Observable automatically tracks changes - no need for objectWillChange.send()
    }
}

extension MapScaleCategory {
    /// Human-readable display text with icon
    var displayText: String {
        switch self {
        case .small: return "🏘️ Small Scale"
        case .medium: return "🏙️ Medium Scale"
        case .large: return "🌍 Large Scale"
        }
    }

    /// Description of what this scale category represents
    var description: String {
        switch self {
        case .small:
            return "Village/battlefield scale (<10 mi). Highly uniform \(Int(dominantPercentage * 100))% dominant terrain."
        case .medium:
            return "City/region scale (10-100 mi). Moderately varied \(Int(dominantPercentage * 100))% dominant terrain."
        case .large:
            return "Continent/world scale (>100 mi). Naturally diverse \(Int(dominantPercentage * 100))% dominant terrain."
        }
    }
}

// MARK: - Helper Views
// DR-0017: FeatureRow removed (was only used by Welcome step)

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

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}

import UniformTypeIdentifiers
import ImageIO

