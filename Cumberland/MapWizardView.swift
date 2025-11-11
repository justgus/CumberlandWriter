//
//  MapWizardView.swift
//  Cumberland
//
//  Created by Mike Stoddard on 11/11/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import MapKit
import CoreLocation
import Contacts
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
    @State private var imageMetadata: ImageMetadataExtractor.ImageMetadata?
    @State private var isDragTargeted = false
    
    // MARK: - Drawing State
    @State private var drawingCanvas: DrawingCanvasState = .init()
    
    // MARK: - Maps Integration State
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyle = .standard
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
        .background(platformBackgroundColor.opacity(0.5))
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
                            .frame(width: 20)
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
        var addressComponents: [String] = []
        
        // Use the modern addressRepresentations API
        if #available(macOS 26.0, iOS 20.0, *) {
            // Use the new address property which provides a CNPostalAddress
            if let address = item.address {
                if !address.fullAddress.isEmpty {
                    addressComponents.append(address.fullAddress)
                }
            }
        } else {
            // Fall back to the deprecated placemark API for older OS versions
            let placemark = item.placemark
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }
        }
        
        return addressComponents.isEmpty ? nil : addressComponents.joined(separator: ", ")
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
        
        withAnimation {
            mapCameraPosition = .region(region)
        }
    }
    
    private func captureMapSnapshot() {
        isCapturingSnapshot = true
        captureError = nil
        
        // Use a simple default region - the Map view will handle the camera position
        // For snapshot, we'll use a reasonable default
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // Create snapshot options
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 2048, height: 2048) // High resolution
        options.mapType = .standard // Default to standard map
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { snapshot, error in
            DispatchQueue.main.async {
                self.isCapturingSnapshot = false
                
                guard let snapshot = snapshot, error == nil else {
                    self.captureError = error?.localizedDescription ?? "Failed to capture map"
                    return
                }
                
                // Convert snapshot to image data
                #if os(macOS)
                if let imageData = snapshot.image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: imageData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    self.capturedMapData = pngData
                    
                    // Store metadata
                    self.mapMetadata = MapCaptureMetadata(
                        centerCoordinate: region.center,
                        span: region.span,
                        mapType: "standard",
                        captureDate: Date(),
                        locationName: self.selectedMapItem?.name
                    )
                }
                #else
                if let pngData = snapshot.image.pngData() {
                    self.capturedMapData = pngData
                    
                    // Store metadata
                    self.mapMetadata = MapCaptureMetadata(
                        centerCoordinate: region.center,
                        span: region.span,
                        mapType: "standard",
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
        VStack(spacing: 16) {
            // Header
            Text("Capture from Apple Maps")
                .font(.title2)
                .bold()
            
            if capturedMapData == nil {
                // Active map view for selecting region
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search for a location...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Search results dropdown
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        selectLocation(item)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name ?? "Unknown")
                                                .font(.subheadline)
                                                .bold()
                                            if let formattedAddress = formatAddress(for: item) {
                                                Text(formattedAddress)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if item != searchResults.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Map view
                    Map(position: $mapCameraPosition) {
                        if let item = selectedMapItem {
                            Marker(item.name ?? "Selected Location", coordinate: item.location.coordinate)
                                .tint(.blue)
                        }
                    }
                    .mapStyle(mapStyle)
                    .frame(height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        // Map style picker
                        Menu {
                            Button {
                                mapStyle = .standard
                            } label: {
                                Label("Standard", systemImage: "")
                            }
                            
                            Button {
                                mapStyle = .imagery
                            } label: {
                                Label("Satellite", systemImage: "")
                            }
                            
                            Button {
                                mapStyle = .hybrid
                            } label: {
                                Label("Hybrid", systemImage: "")
                            }
                        } label: {
                            Image(systemName: "map")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding(12)
                    }
                    
                    // Instructions
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Pan and zoom to frame your desired capture area, then tap Capture")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
                    
                    // Capture button
                    if isCapturingSnapshot {
                        ProgressView("Capturing map...")
                            .padding()
                    } else {
                        Button {
                            captureMapSnapshot()
                        } label: {
                            Label("Capture Map Snapshot", systemImage: "camera.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    if let error = captureError {
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
                }
            } else {
                // Preview of captured map
                VStack(spacing: 16) {
                    #if os(macOS)
                    if let nsImage = NSImage(data: capturedMapData!) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    #else
                    if let uiImage = UIImage(data: capturedMapData!) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    }
                    #endif
                    
                    // Map metadata display
                    if let metadata = mapMetadata {
                        mapMetadataDisplayView(metadata)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            // Reset to recapture
                            capturedMapData = nil
                            mapMetadata = nil
                            captureError = nil
                        } label: {
                            Label("Capture Different Area", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            // Move captured data to import flow
                            importedImageData = capturedMapData
                            nextStep()
                        } label: {
                            Label("Use This Capture", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .frame(maxWidth: 800)
        .padding()
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
                #if os(macOS)
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
                #else
                if importedImageData != nil {
                    Text("Preview not implemented for this platform yet")
                        .foregroundStyle(.secondary)
                        .frame(height: 200)
                } else {
                    Text("No map data available")
                        .foregroundStyle(.secondary)
                        .frame(height: 200)
                }
                #endif
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
            // Check if we have valid data for the selected method
            guard let method = selectedMethod else { return false }
            switch method {
            case .importImage:
                return importedImageData != nil
            case .draw:
                return false // TODO: Check if drawing has content
            case .captureFromMaps:
                return capturedMapData != nil
            case .aiGenerate:
                return !generationPrompt.isEmpty && importedImageData != nil
            }
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
        
        // Create automatic image attribution citation from metadata
        createAutomaticImageCitation()
        
        try? modelContext.save()
        
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
        currentStep = .welcome
        selectedMethod = nil
        importedImageData = nil
        imageMetadata = nil
        isDragTargeted = false
        
        // Reset map state
        mapCameraPosition = .automatic
        mapStyle = .standard
        searchText = ""
        searchResults = []
        selectedMapItem = nil
        isSearching = false
        capturedMapData = nil
        mapMetadata = nil
        isCapturingSnapshot = false
        captureError = nil
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
    
    struct MapCaptureMetadata {
        let centerCoordinate: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        let mapType: String
        let captureDate: Date
        let locationName: String?
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
