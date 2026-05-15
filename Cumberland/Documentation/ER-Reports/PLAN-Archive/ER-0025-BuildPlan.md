# ER-0025: Integrate Map Generation into Storyscapes with Workspace - Build Plan

**Status:** 🔵 Proposed
**Component:** Map Generation, Storyscapes Integration, Xcode Workspace
**Priority:** High
**Date Requested:** 2026-02-03
**Dependencies:** ER-0024 (BrushEngine package must be created first)

---

## Overview

Integrate Cumberland's powerful map generation capabilities into the existing Storyscapes application by creating a unified Xcode workspace. This will allow Storyscapes to use the same BrushEngine package, while maintaining independent development and release cycles for both applications.

**Key Benefit:** Shared map generation technology between Cumberland (worldbuilding tool) and Storyscapes (dedicated map creation app), with improvements in one benefiting the other.

**Note:** Cumberland.xcodeproj is located at ./Cumberland.xcodeproj
    Storyscapes.xcodeproj is located at ../Storyscapes/Storyscapes.xcodeproj


---

## Current State

### Cumberland Map Generation
- Location: `Cumberland/DrawCanvas/` folder
- ~14,000 lines of code across 22 files
- Integrated with Card model and SwiftData
- Supports draft persistence via CloudKit
- Cross-platform (macOS, iOS, iPadOS, visionOS)

### Storyscapes App
- Existing app with initial development underway
- Needs sophisticated map generation capabilities
- Separate product focus (maps only, not full worldbuilding)
- Will have its own data model (independent of Cumberland's Card)

### Goal Architecture

```
CumberlandWorkspace/
├── CumberlandWorkspace.xcworkspace         # NEW workspace
├── Cumberland/                              # Existing app
│   └── Cumberland.xcodeproj
├── Storyscapes/                             # Existing app
│   └── Storyscapes.xcodeproj
└── Packages/                                # NEW shared packages
    ├── ImageProcessing/                     # ER-0023
    └── BrushEngine/                         # ER-0024
```

---

## Workspace Architecture Strategy

### Benefits of Workspace Approach

**Advantages:**
- ✅ Share Swift Packages between apps (BrushEngine, ImageProcessing)
- ✅ Independent versioning and releases
- ✅ Separate git repositories (optional)
- ✅ Different deployment targets possible
- ✅ Code improvements flow bidirectionally
- ✅ Build both apps from single Xcode window
- ✅ Easier debugging across boundaries

**What Stays Separate:**
- Each app has its own project file (.xcodeproj)
- Each app has its own data model
- Each app has its own UI layer
- Each app can have different team IDs, provisioning profiles
- Each app has independent App Store presence

**What's Shared:**
- Swift Packages (BrushEngine, ImageProcessing)
- Potentially shared assets (brush textures, icons)
- Documentation and build scripts

---

## Storyscapes Data Model Design

### Key Abstraction: MapProject (Not Card)

Storyscapes needs its own data model that's independent of Cumberland's Card-based system.

```swift
// Storyscapes/Models/MapProject.swift
import SwiftData
import BrushEngine

@Model
class MapProject {
    // Identity
    var id: UUID
    var name: String
    var createdDate: Date
    var modifiedDate: Date

    // Map Properties
    var mapWidth: Int
    var mapHeight: Int
    var mapStyle: MapStyle  // Interior, Exterior, etc.

    // Draft Layer Data (from BrushEngine)
    @Attribute(.externalStorage)
    var draftLayerData: Data?

    // Final Rendered Map
    @Attribute(.externalStorage)
    var renderedMapData: Data?

    // Thumbnail
    var thumbnailData: Data?

    // Metadata
    var tags: [String]?
    var notes: String?

    // CloudKit Support
    var isSynced: Bool

    init(name: String, width: Int, height: Int, style: MapStyle) {
        self.id = UUID()
        self.name = name
        self.createdDate = Date()
        self.modifiedDate = Date()
        self.mapWidth = width
        self.mapHeight = height
        self.mapStyle = style
        self.isSynced = false
    }
}

enum MapStyle: String, Codable {
    case exterior = "Exterior"
    case interior = "Interior"
    case hybrid = "Hybrid"
}

// Conform to BrushEngine persistence protocol
extension MapProject: LayerPersistenceDelegate {
    func save(layerData: Data) {
        self.draftLayerData = layerData
        self.modifiedDate = Date()
    }

    func loadDraftWork() -> Data? {
        return draftLayerData
    }
}
```

### Schema Versioning

```swift
// Storyscapes/Models/StoryseapesSchema.swift
import SwiftData

enum StoryscapesSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MapProject.self]
    }
}

typealias StoryscapesSchema = StoryscapesSchemaV1
```

---

## Implementation Plan

### Phase 1: Create Workspace Structure (Week 1, Days 1-2)

**Step 1.1: Create Workspace**

```bash
cd /Users/justgus/Xcode-Projects/

# Create workspace directory if not exists
mkdir -p CumberlandWorkspace
cd CumberlandWorkspace

# Open Xcode
# File > New > Workspace
# Save as "CumberlandWorkspace.xcworkspace" in CumberlandWorkspace folder
```

**Step 1.2: Add Projects to Workspace**

In Xcode with workspace open:
1. File > Add Files to "CumberlandWorkspace"
2. Navigate to `Cumberland/Cumberland.xcodeproj` → Add
3. File > Add Files to "CumberlandWorkspace"
4. Navigate to `Storyscapes/Storyscapes.xcodeproj` → Add

**Workspace structure after this step:**
```
CumberlandWorkspace.xcworkspace
├── Cumberland (project reference)
└── Storyscapes (project reference)
```

**Step 1.3: Create Packages Folder**

```bash
# From CumberlandWorkspace directory
mkdir -p Packages
```

**Step 1.4: Move/Copy BrushEngine Package**

After ER-0024 is complete:
```bash
# Copy (or move) BrushEngine package
cp -r /path/to/BrushEngine Packages/BrushEngine
```

**Step 1.5: Add Packages to Workspace**

In Xcode workspace:
1. File > Add Files to "CumberlandWorkspace"
2. Navigate to `Packages/BrushEngine` → Add
3. File > Add Files to "CumberlandWorkspace"
4. Navigate to `Packages/ImageProcessing` → Add (if ER-0023 is done)

**Final workspace structure:**
```
CumberlandWorkspace/
├── CumberlandWorkspace.xcworkspace
├── Cumberland/
│   └── Cumberland.xcodeproj
├── Storyscapes/
│   └── Storyscapes.xcodeproj
└── Packages/
    ├── BrushEngine/
    │   ├── Package.swift
    │   └── Sources/...
    └── ImageProcessing/
        ├── Package.swift
        └── Sources/...
```

### Phase 2: Storyscapes Data Layer (Week 1, Days 3-5)

**Step 2.1: Create MapProject Model**

Create `Storyscapes/Models/MapProject.swift` (see design above)

**Step 2.2: Create SwiftData Container**

```swift
// Storyscapes/StoryscapesApp.swift
import SwiftUI
import SwiftData

@main
struct StoryscapesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: MapProject.self)
    }
}
```

**Step 2.3: Create MapProject Repository**

```swift
// Storyscapes/Data/MapProjectRepository.swift
import SwiftData

@Observable
@MainActor
class MapProjectRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [MapProject] {
        let descriptor = FetchDescriptor<MapProject>(
            sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func create(name: String, width: Int, height: Int, style: MapStyle) throws -> MapProject {
        let project = MapProject(name: name, width: width, height: height, style: style)
        modelContext.insert(project)
        try modelContext.save()
        return project
    }

    func delete(_ project: MapProject) throws {
        modelContext.delete(project)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }
}
```

### Phase 3: Storyscapes Map Editor (Week 2)

**Step 3.1: Add BrushEngine Dependency to Storyscapes**

In Xcode:
1. Select Storyscapes project
2. Select app target
3. General tab > Frameworks, Libraries, and Embedded Content
4. Click + button
5. Add BrushEngine package

**Step 3.2: Create MapEditorCoordinator**

```swift
// Storyscapes/MapEditor/MapEditorCoordinator.swift
import SwiftUI
import BrushEngine
import Observation

@Observable
@MainActor
class MapEditorCoordinator {
    // Map project being edited
    let project: MapProject

    // BrushEngine components
    let layerManager: LayerManager
    let brushRegistry: BrushRegistry
    let engine: BrushEngine

    // UI State
    var selectedBrush: MapBrush?
    var selectedLayerIndex: Int = 0
    var isDrawing: Bool = false
    var canvasScale: CGFloat = 1.0
    var canvasOffset: CGSize = .zero

    init(project: MapProject) {
        self.project = project

        // Initialize BrushEngine components
        self.layerManager = LayerManager()
        self.brushRegistry = BrushRegistry()
        self.engine = BrushEngine()

        // Connect persistence
        self.layerManager.persistenceDelegate = project

        // Register brush sets
        self.brushRegistry.registerBrushSet(ExteriorBrushSet())
        self.brushRegistry.registerBrushSet(InteriorBrushSet())

        // Load existing draft work
        self.layerManager.loadDraftWork()

        // If no layers, create default base layer
        if layerManager.layers.isEmpty {
            let baseLayer = DrawingLayer(
                name: "Base Layer",
                layerType: .base
            )
            layerManager.addLayer(baseLayer)
        }
    }

    // MARK: - Canvas Operations

    func renderCurrentCanvas(size: CGSize) -> CGImage? {
        return layerManager.compositeLayers(size: size)
    }

    func exportMap() -> Data? {
        let exportSize = CGSize(
            width: project.mapWidth,
            height: project.mapHeight
        )

        guard let cgImage = layerManager.compositeLayers(size: exportSize) else {
            return nil
        }

        // Convert to PNG data (using ImageProcessing package if available)
        #if canImport(ImageProcessing)
        return ImageProcessingService.shared.convertToPNG(cgImage)
        #else
        // Fallback conversion
        return convertCGImageToPNG(cgImage)
        #endif
    }

    func saveDraftWork() {
        layerManager.saveDraftWork()
    }

    // MARK: - Layer Operations

    func addLayer(name: String, type: LayerType) {
        let newLayer = DrawingLayer(name: name, layerType: type)
        layerManager.addLayer(newLayer)
        selectedLayerIndex = layerManager.layers.count - 1
    }

    func deleteLayer(at index: Int) {
        layerManager.removeLayer(at: index)
        selectedLayerIndex = min(selectedLayerIndex, layerManager.layers.count - 1)
    }

    func duplicateLayer(at index: Int) {
        layerManager.duplicateLayer(at: index)
    }
}
```

**Step 3.3: Create MapEditorView**

```swift
// Storyscapes/MapEditor/MapEditorView.swift
import SwiftUI
import BrushEngine

struct MapEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator: MapEditorCoordinator

    let project: MapProject

    init(project: MapProject) {
        self.project = project
        self._coordinator = State(initialValue: MapEditorCoordinator(project: project))
    }

    var body: some View {
        HSplitView {
            // Canvas Area
            MapCanvasView(coordinator: coordinator)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Tools Sidebar
            MapToolsSidebar(coordinator: coordinator)
                .frame(width: 300)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Export") {
                    exportMap()
                }

                Button("Save") {
                    coordinator.saveDraftWork()
                }
            }
        }
        .navigationTitle(project.name)
    }

    private func exportMap() {
        guard let mapData = coordinator.exportMap() else {
            print("Failed to export map")
            return
        }

        // Save to project
        project.renderedMapData = mapData
        project.modifiedDate = Date()

        // Generate thumbnail
        #if canImport(ImageProcessing)
        project.thumbnailData = ImageProcessingService.shared.generateThumbnail(from: mapData)
        #endif

        try? modelContext.save()
    }
}
```

**Step 3.4: Adapt Cumberland's DrawingCanvas UI**

Storyscapes can reuse much of Cumberland's drawing UI, but adapted:

Files to adapt/copy from Cumberland:
1. `DrawingCanvasView.swift` → `Storyscapes/MapEditor/MapCanvasView.swift`
2. `FloatingToolPalette.swift` → `Storyscapes/MapEditor/ToolPalette.swift`
3. `LayersTabView.swift` → `Storyscapes/MapEditor/LayersSidebar.swift`
4. `BrushGridView.swift` → `Storyscapes/MapEditor/BrushGrid.swift`

**Modifications needed:**
- Remove Card references → use MapProject
- Remove SwiftData @Query → use coordinator's state
- Simplify to focus on map editing (no need for worldbuilding features)

**Estimated code reuse:** ~60% of Cumberland's drawing UI can be adapted

### Phase 4: Storyscapes UI Integration (Week 2-3)

**Step 4.1: Create Project List View**

```swift
// Storyscapes/ProjectList/ProjectListView.swift
import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MapProject.modifiedDate, order: .reverse)
    private var projects: [MapProject]

    @State private var showingNewProjectSheet = false

    var body: some View {
        NavigationSplitView {
            List(projects) { project in
                NavigationLink(value: project) {
                    ProjectRowView(project: project)
                }
            }
            .navigationTitle("Map Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Map", systemImage: "plus") {
                        showingNewProjectSheet = true
                    }
                }
            }
        } detail: {
            Text("Select a map project")
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet()
        }
    }
}

struct ProjectRowView: View {
    let project: MapProject

    var body: some View {
        HStack {
            // Thumbnail
            if let thumbnailData = project.thumbnailData,
               let image = loadImage(from: thumbnailData) {
                Image(image, scale: 1.0, label: Text(project.name))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "map")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                Text("\(project.mapWidth) × \(project.mapHeight)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(project.modifiedDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func loadImage(from data: Data) -> CGImage? {
        #if os(macOS)
        return NSImage(data: data)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #else
        return UIImage(data: data)?.cgImage
        #endif
    }
}
```

**Step 4.2: Create New Project Sheet**

```swift
// Storyscapes/ProjectList/NewProjectSheet.swift
import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var projectName = ""
    @State private var mapWidth = 2048
    @State private var mapHeight = 2048
    @State private var mapStyle: MapStyle = .exterior

    let presetSizes = [
        ("Small", 1024, 1024),
        ("Medium", 2048, 2048),
        ("Large", 4096, 4096),
        ("Ultra", 8192, 8192)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                }

                Section("Map Size") {
                    Picker("Preset Size", selection: Binding(
                        get: { (mapWidth, mapHeight) },
                        set: { mapWidth = $0.0; mapHeight = $0.1 }
                    )) {
                        ForEach(presetSizes, id: \.0) { preset in
                            Text("\(preset.0) (\(preset.1) × \(preset.2))")
                                .tag((preset.1, preset.2))
                        }
                    }

                    HStack {
                        TextField("Width", value: $mapWidth, format: .number)
                        Text("×")
                        TextField("Height", value: $mapHeight, format: .number)
                    }
                }

                Section("Map Style") {
                    Picker("Style", selection: $mapStyle) {
                        Text("Exterior").tag(MapStyle.exterior)
                        Text("Interior").tag(MapStyle.interior)
                        Text("Hybrid").tag(MapStyle.hybrid)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Map Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }

    private func createProject() {
        let project = MapProject(
            name: projectName,
            width: mapWidth,
            height: mapHeight,
            style: mapStyle
        )

        modelContext.insert(project)
        try? modelContext.save()

        dismiss()
    }
}
```

### Phase 5: Testing and Refinement (Week 3)

**Step 5.1: Workspace Build Testing**

1. Open `CumberlandWorkspace.xcworkspace`
2. Select Cumberland scheme → Build
3. Verify builds successfully
4. Select Storyscapes scheme → Build
5. Verify builds successfully
6. Verify both can build simultaneously

**Step 5.2: Integration Testing**

**Test Cumberland:**
1. Map Wizard still works
2. Draft persistence still works
3. Layer management still works
4. No regressions in map generation

**Test Storyscapes:**
1. Create new map project
2. Use all brush types
3. Create multiple layers
4. Export high-resolution map
5. Verify quality matches Cumberland

**Step 5.3: Package Testing**

1. Modify BrushEngine package (add test feature)
2. Rebuild Cumberland → verify change reflected
3. Rebuild Storyscapes → verify change reflected
4. Confirms package sharing works correctly

---

## File Organization Summary

### New Files in Storyscapes

**Models:** (~200 lines)
- `Models/MapProject.swift`
- `Models/StoryscapesSchema.swift`

**Data Layer:** (~150 lines)
- `Data/MapProjectRepository.swift`

**Map Editor:** (~800 lines)
- `MapEditor/MapEditorCoordinator.swift` (~300 lines)
- `MapEditor/MapEditorView.swift` (~200 lines)
- `MapEditor/MapCanvasView.swift` (adapted from Cumberland, ~150 lines)
- `MapEditor/ToolPalette.swift` (adapted, ~100 lines)
- `MapEditor/LayersSidebar.swift` (adapted, ~50 lines)

**Project Management:** (~300 lines)
- `ProjectList/ProjectListView.swift` (~100 lines)
- `ProjectList/ProjectRowView.swift` (~50 lines)
- `ProjectList/NewProjectSheet.swift` (~150 lines)

**Total New Storyscapes Code:** ~1,450 lines

**Reused from Cumberland (adapted):** ~400 lines of UI code

**Shared via Packages:** ~5,600 lines (BrushEngine) + ~490 lines (ImageProcessing)

---

## Testing Strategy

### Unit Tests (Storyscapes)

**MapProject Tests:**
```swift
@Test func testMapProjectCreation() {
    let project = MapProject(name: "Test Map", width: 2048, height: 2048, style: .exterior)
    #expect(project.name == "Test Map")
    #expect(project.mapWidth == 2048)
    #expect(project.mapStyle == .exterior)
}

@Test func testLayerPersistence() {
    let project = MapProject(name: "Test", width: 1024, height: 1024, style: .interior)
    let testData = Data([1, 2, 3, 4])

    project.save(layerData: testData)
    let loaded = project.loadDraftWork()

    #expect(loaded == testData)
}
```

**MapEditorCoordinator Tests:**
```swift
@Test func testCoordinatorInitialization() {
    let project = MapProject(name: "Test", width: 1024, height: 1024, style: .exterior)
    let coordinator = MapEditorCoordinator(project: project)

    #expect(coordinator.layerManager.layers.count >= 1) // Should have base layer
    #expect(coordinator.brushRegistry.getAllBrushes().count > 0)
}

@Test func testMapExport() {
    let project = MapProject(name: "Test", width: 512, height: 512, style: .exterior)
    let coordinator = MapEditorCoordinator(project: project)

    let exportedData = coordinator.exportMap()
    #expect(exportedData != nil)
}
```

### Integration Tests

**Test Scenarios:**
1. **Create → Edit → Save → Reopen:**
   - Create new map project
   - Add layers and draw terrain
   - Save and close
   - Reopen project
   - Verify layers restored correctly

2. **Export High-Resolution:**
   - Create 4096×4096 map
   - Add complex terrain
   - Export as PNG
   - Verify file size and quality

3. **Multiple Projects:**
   - Create several map projects
   - Switch between them
   - Verify each maintains separate state

4. **Cross-Platform (if applicable):**
   - Create map on macOS
   - If Storyscapes has iOS version, sync and edit
   - Verify consistency

---

## Documentation

### Workspace README

Create `CumberlandWorkspace/README.md`:

```markdown
# Cumberland Workspace

This workspace contains multiple related applications that share common Swift packages.

## Projects

### Cumberland
Full-featured worldbuilding and narrative design application.
- **Platforms:** macOS, iOS, iPadOS, visionOS
- **Features:** Cards, relationships, timelines, maps, AI analysis

### Storyscapes
Dedicated map creation application.
- **Platforms:** macOS (iOS planned)
- **Features:** High-resolution map generation, procedural terrain

## Shared Packages

### BrushEngine
Procedural brush rendering engine for map generation.
- Used by: Cumberland, Storyscapes
- Location: `Packages/BrushEngine/`

### ImageProcessing
Image processing utilities (thumbnails, format conversion).
- Used by: Cumberland, Storyscapes
- Location: `Packages/ImageProcessing/`

## Building

1. Open `CumberlandWorkspace.xcworkspace` in Xcode
2. Select desired scheme (Cumberland or Storyscapes)
3. Build and run

## Package Development

When making changes to shared packages:
1. Edit package source in `Packages/[PackageName]/`
2. Rebuild all dependent projects to test changes
3. Changes are immediately reflected in both apps

## Requirements

- Xcode 26.2+
- macOS 26.2+
- Swift 6.0+
```

### Storyscapes README

Update `Storyscapes/README.md` to explain integration:

```markdown
# Storyscapes

Dedicated map creation application powered by the BrushEngine.

## Architecture

Storyscapes is part of the Cumberland workspace and shares core rendering technology:
- **BrushEngine package:** Procedural terrain generation
- **ImageProcessing package:** Thumbnail and format conversion

## Data Model

Maps are stored as `MapProject` entities with SwiftData, independent of Cumberland's data model.

## Building

Open `CumberlandWorkspace.xcworkspace` and select the Storyscapes scheme.
```

---

## Success Criteria

- [ ] Workspace created and configured correctly
- [ ] Both Cumberland and Storyscapes build successfully
- [ ] BrushEngine package integrated into both apps
- [ ] Storyscapes can create and edit maps
- [ ] Map quality matches Cumberland
- [ ] Draft persistence works in Storyscapes
- [ ] Export functionality works
- [ ] No regressions in Cumberland
- [ ] Package changes reflected in both apps
- [ ] Documentation complete

---

## Risks and Mitigations

### Risk 1: Workspace Complexity

**Risk:** Managing two projects in one workspace may be confusing

**Mitigation:**
- Clear documentation (README)
- Consistent naming conventions
- Use schemes to switch between apps easily

### Risk 2: Package Versioning Issues

**Risk:** Changes to BrushEngine may break one app while fixing another

**Mitigation:**
- Comprehensive testing before package changes
- Version packages properly
- Use semantic versioning
- Consider branch strategy for major package changes

### Risk 3: Storyscapes Data Model Divergence

**Risk:** Storyscapes' MapProject may not support all Cumberland features

**Mitigation:**
- Document intentional differences
- Keep models focused on their use cases
- Don't try to unify data models unnecessarily

---

## Timeline Estimate

**Total Duration:** 3 weeks

- **Week 1:**
  - Days 1-2: Create workspace structure
  - Days 3-5: Storyscapes data layer (MapProject, repository)

- **Week 2:**
  - Days 1-3: Map editor coordinator and canvas integration
  - Days 4-5: UI adaptation from Cumberland

- **Week 3:**
  - Days 1-2: Project list and management UI
  - Days 3-4: Testing and refinement
  - Day 5: Documentation and polish

---

## Dependencies

**Required:**
- ER-0024 (BrushEngine package) **MUST be completed first**

**Optional:**
- ER-0023 (ImageProcessing package) - beneficial but not blocking

---

## Future Enhancements

### Potential Storyscapes Features

1. **Advanced Export Options:**
   - Multiple file formats (PNG, JPEG, SVG, PDF)
   - Layer export (separate files per layer)
   - Tileset export for game engines

2. **Map Collections:**
   - Group related maps
   - World atlases
   - Campaign maps

3. **Collaboration Features:**
   - Share maps via CloudKit
   - Collaborative editing
   - Map libraries/marketplace

4. **Game Engine Integration:**
   - Unity export
   - Unreal Engine export
   - Godot integration

---

*Last Updated: 2026-02-03*
