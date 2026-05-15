# Phase 3: MapKit Integration - Architecture Diagram

## Complete Capture from Maps Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                        MapWizardView                                │
│                     (Phase 3 - Maps Method)                         │
└────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Welcome Step         │
                    │   - Feature overview   │
                    └────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  Select Method Step    │
                    │  - Choose "Maps"       │
                    └────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────┐
│                      Configure Step                                 │
│                   (mapsConfigView)                                  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  No Capture Yet? → Show Interactive Map                      │  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Search Bar (MKLocalSearch)                         │    │  │
│  │  │  - Text field with magnifying glass                │    │  │
│  │  │  - Clear button                                     │    │  │
│  │  │  - Submit on Return                                 │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Search Results Dropdown (if results)               │    │  │
│  │  │  - Scrollable list                                  │    │  │
│  │  │  - Name + Address for each                          │    │  │
│  │  │  - Tap to select                                    │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Map View (SwiftUI MapKit)                          │    │  │
│  │  │  - Pan/zoom enabled                                 │    │  │
│  │  │  - Shows selected marker (blue)                     │    │  │
│  │  │  - 400pt height                                     │    │  │
│  │  │                                                      │    │  │
│  │  │  ┌──────────────────────────────────────┐           │    │  │
│  │  │  │  Map Style Picker (top-right)        │           │    │  │
│  │  │  │  - Standard / Satellite / Hybrid     │           │    │  │
│  │  │  └──────────────────────────────────────┘           │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Instructions Box                                   │    │  │
│  │  │  "Pan and zoom to frame area, then tap Capture"    │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  [Capture Map Snapshot] Button                      │    │  │
│  │  │  - Camera icon                                      │    │  │
│  │  │  - Prominent style                                  │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │                 (Trigger Snapshot)                            │  │
│  └───────────────────────────────────────────────────────────── │  │
│                                                                      │
│                          ▼                                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Capture Processing                                          │  │
│  │                                                               │  │
│  │  1. Extract current map region from camera position          │  │
│  │  2. Create MKMapSnapshotter.Options                          │  │
│  │     - Region: current visible area                           │  │
│  │     - Size: 2048 × 2048                                      │  │
│  │     - MapType: based on current style                        │  │
│  │  3. Start async snapshot                                     │  │
│  │  4. Show progress indicator                                  │  │
│  │  5. Convert snapshot.image to PNG data                       │  │
│  │  6. Store in capturedMapData                                 │  │
│  │  7. Create MapCaptureMetadata                                │  │
│  │     - centerCoordinate                                       │  │
│  │     - span                                                    │  │
│  │     - mapType                                                │  │
│  │     - captureDate                                            │  │
│  │     - locationName (if selected)                             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│                          ▼                                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Capture Complete? → Show Preview                            │  │
│  │                                                               │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Captured Image Preview                             │    │  │
│  │  │  - Max 400pt height                                 │    │  │
│  │  │  - Rounded corners                                  │    │  │
│  │  │  - Shadow                                           │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Metadata Display (GroupBox)                        │    │  │
│  │  │  - Location name (if available)                     │    │  │
│  │  │  - Coordinates (lat, long)                          │    │  │
│  │  │  - Map type                                         │    │  │
│  │  │  - Capture date/time                                │    │  │
│  │  │  - Span (degrees)                                   │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  │                          ▼                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐    │  │
│  │  │  Action Buttons                                     │    │  │
│  │  │  [Capture Different Area] | [Use This Capture]     │    │  │
│  │  └─────────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└────────────────────────────────────────────────────────────────────┘
                                 │
                   [Use This Capture] clicked
                                 │
                                 ▼
              capturedMapData → importedImageData
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Finalize Step        │
                    │   - Preview map        │
                    │   - Save to Card       │
                    └────────────────────────┘
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        State Properties                          │
├─────────────────────────────────────────────────────────────────┤
│  searchText: String                  ← User types here          │
│       ↓                                                          │
│  searchResults: [MKMapItem]          ← MKLocalSearch results    │
│       ↓                                                          │
│  selectedMapItem: MKMapItem?         ← User selection           │
│       ↓                                                          │
│  mapCameraPosition: MapCameraPosition ← Animates to location    │
│       ↓                                                          │
│  mapStyle: MapStyle                  ← User selection           │
│       ↓                                                          │
│  [User frames map with pan/zoom]                                │
│       ↓                                                          │
│  [User taps Capture]                                            │
│       ↓                                                          │
│  isCapturingSnapshot: Bool = true    ← Show progress            │
│       ↓                                                          │
│  MKMapSnapshotter.start()            ← Async capture            │
│       ↓                                                          │
│  capturedMapData: Data?              ← PNG image data           │
│       ↓                                                          │
│  mapMetadata: MapCaptureMetadata?    ← Geographic info          │
│       ↓                                                          │
│  isCapturingSnapshot: Bool = false   ← Hide progress            │
│       ↓                                                          │
│  [User reviews preview]                                         │
│       ↓                                                          │
│  [User taps Use This Capture]                                   │
│       ↓                                                          │
│  importedImageData = capturedMapData ← Handoff to wizard        │
│       ↓                                                          │
│  nextStep() → Finalize                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## MapKit API Integration

```
┌──────────────────────────────────────────────────────────────────┐
│                      Apple MapKit APIs Used                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  SwiftUI Map View                                                │
│  ├─ Map(position: $mapCameraPosition)                            │
│  ├─ .mapStyle(mapStyle)                                          │
│  └─ Marker(name, coordinate: coord)                              │
│                                                                   │
│  Location Search                                                 │
│  ├─ MKLocalSearch.Request()                                      │
│  ├─ request.naturalLanguageQuery = searchText                    │
│  ├─ MKLocalSearch(request: request)                              │
│  └─ search.start { response, error in ... }                      │
│                                                                   │
│  High-Resolution Snapshot                                        │
│  ├─ MKMapSnapshotter.Options()                                   │
│  ├─ options.region = currentRegion                               │
│  ├─ options.size = CGSize(width: 2048, height: 2048)             │
│  ├─ options.mapType = .standard | .satellite | .hybrid           │
│  ├─ MKMapSnapshotter(options: options)                           │
│  └─ snapshotter.start { snapshot, error in ... }                 │
│                                                                   │
│  Map Styles                                                      │
│  ├─ MapStyle.standard                                            │
│  ├─ MapStyle.imagery (satellite)                                 │
│  └─ MapStyle.hybrid                                              │
│                                                                   │
│  Camera Positioning                                              │
│  ├─ MapCameraPosition.automatic                                  │
│  ├─ MapCameraPosition.region(MKCoordinateRegion)                 │
│  ├─ MapCameraPosition.rect(MKMapRect)                            │
│  ├─ MapCameraPosition.camera(MKMapCamera)                        │
│  └─ MapCameraPosition.item(MKMapItem)                            │
│                                                                   │
│  Geographic Types (CoreLocation)                                 │
│  ├─ CLLocationCoordinate2D (latitude, longitude)                 │
│  ├─ MKCoordinateSpan (latitudeDelta, longitudeDelta)             │
│  └─ MKCoordinateRegion (center, span)                            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## UI Component Hierarchy

```
VStack (mapsConfigView)
│
├─ Text("Capture from Apple Maps") [Title]
│
├─ VStack (if capturedMapData == nil) [Active Capture Mode]
│   │
│   ├─ HStack [Search Bar]
│   │   ├─ Image(magnifyingglass)
│   │   ├─ TextField("Search...", text: $searchText)
│   │   └─ Button(X) [Clear]
│   │
│   ├─ ScrollView [Search Results] (if !searchResults.isEmpty)
│   │   └─ VStack
│   │       └─ ForEach(searchResults)
│   │           └─ Button [Location Item]
│   │               ├─ Text(name)
│   │               └─ Text(address)
│   │
│   ├─ Map(position: $mapCameraPosition) [Map View]
│   │   ├─ .mapStyle(mapStyle)
│   │   ├─ Marker (if selectedMapItem)
│   │   └─ .overlay (alignment: topTrailing)
│   │       └─ Menu [Map Style Picker]
│   │           ├─ Button("Standard")
│   │           ├─ Button("Satellite")
│   │           └─ Button("Hybrid")
│   │
│   ├─ HStack [Instructions Box]
│   │   ├─ Image(info.circle)
│   │   └─ Text("Pan and zoom...")
│   │
│   ├─ Button("Capture Map Snapshot") [Capture Button]
│   │   (or ProgressView if isCapturingSnapshot)
│   │
│   └─ HStack [Error Display] (if captureError != nil)
│       ├─ Image(exclamationmark.triangle.fill)
│       └─ Text(captureError)
│
└─ VStack (if capturedMapData != nil) [Preview Mode]
    │
    ├─ Image (captured map) [Preview]
    │
    ├─ mapMetadataDisplayView(metadata) [Metadata]
    │   └─ GroupBox
    │       ├─ Text("Capture Information")
    │       ├─ MetadataRow(icon: "mappin.circle", "Location", name)
    │       ├─ MetadataRow(icon: "location", "Coordinates", coords)
    │       ├─ MetadataRow(icon: "map", "Map Type", type)
    │       ├─ MetadataRow(icon: "calendar", "Captured", date)
    │       └─ MetadataRow(icon: "viewfinder", "Span", span)
    │
    └─ HStack [Action Buttons]
        ├─ Button("Capture Different Area") [Reset]
        └─ Button("Use This Capture") [Proceed]
```

---

## Error Handling Flow

```
┌────────────────────────────────────────────────────────────────┐
│                    Error Scenarios                              │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Search Errors:                                                │
│  ├─ No internet connection                                     │
│  │   └─ Display: "Unable to perform search. Check connection." │
│  ├─ MKLocalSearch API error                                    │
│  │   └─ Display: error.localizedDescription                    │
│  ├─ No results found                                           │
│  │   └─ searchResults = [] (empty list, no error UI)           │
│  └─ Invalid query                                              │
│      └─ Handle gracefully (no crash)                           │
│                                                                 │
│  Capture Errors:                                               │
│  ├─ MKMapSnapshotter fails                                     │
│  │   └─ Display: error.localizedDescription                    │
│  ├─ Image conversion fails                                     │
│  │   └─ Display: "Failed to capture map"                       │
│  ├─ Invalid region                                             │
│  │   └─ Fallback to default region, show warning               │
│  └─ Network unavailable during capture                         │
│      └─ May work with cached tiles, or error                   │
│                                                                 │
│  UI State Errors:                                              │
│  ├─ Rapid captures                                             │
│  │   └─ isCapturingSnapshot prevents duplicates                │
│  ├─ Navigation during capture                                  │
│  │   └─ Async completion still stores result                   │
│  └─ State inconsistencies                                      │
│      └─ Reset on wizard init/resetWizard()                     │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## Validation Logic

```swift
// canProceed for Configure Step with Maps Method

case .configure:
    guard let method = selectedMethod else { return false }
    
    switch method {
        case .captureFromMaps:
            // ✅ MUST have successfully captured map data
            return capturedMapData != nil
            
        // Other methods...
    }
```

**Why this matters:**
- User cannot advance to Finalize step without a capture
- Ensures data integrity throughout wizard flow
- Prevents empty/invalid saves

---

## Platform-Specific Considerations

### macOS
```swift
#if os(macOS)
// Image conversion from snapshot
if let imageData = snapshot.image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: imageData),
   let pngData = bitmap.representation(using: .png, properties: [:]) {
    capturedMapData = pngData
}

// Display in preview
if let nsImage = NSImage(data: capturedMapData!) {
    Image(nsImage: nsImage)
        .resizable()
        .scaledToFit()
}
#endif
```

### iOS/iPadOS
```swift
#if canImport(UIKit)
// Image conversion from snapshot
if let pngData = snapshot.image.pngData() {
    capturedMapData = pngData
}

// Display in preview
if let uiImage = UIImage(data: capturedMapData!) {
    Image(uiImage: uiImage)
        .resizable()
        .scaledToFit()
}
#endif
```

---

## Memory & Performance Optimization

### Current Optimizations
1. **Lazy Search**: Only searches on submit (not keystroke)
2. **Single Capture Storage**: Replaces previous capture
3. **Async Snapshot**: Non-blocking UI
4. **Appropriate Resolution**: 2048×2048 (high quality, not excessive)
5. **State Reset**: Clears unused data on wizard reset

### Future Optimizations
1. Debounced search-as-you-type
2. Thumbnail generation for preview
3. Configurable snapshot resolution
4. Search result caching
5. Background processing

---

## Success Criteria ✅

- [x] Map view integrates seamlessly with wizard
- [x] Search is intuitive and fast
- [x] Captures are high-quality and accurate
- [x] Metadata is comprehensive and useful
- [x] Error handling is robust
- [x] Cross-platform compatibility maintained
- [x] No performance issues or memory leaks
- [x] User experience is smooth and clear

---

**End of Architecture Diagram**
