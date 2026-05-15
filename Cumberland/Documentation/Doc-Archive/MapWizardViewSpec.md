# MapWizardView Specification

**Component:** MapWizardView  
**Purpose:** A procedural wizard for creating, importing, and editing maps for Map-kind cards  
**Created:** November 11, 2025  
**Status:** Initial Implementation (Phase 1 - Stub)

---

## Overview

The MapWizardView provides a guided, multi-step interface for writers to create and manage maps associated with their Map cards. The wizard supports four primary methods of map creation, each tailored to different use cases and workflows.

## Architecture

### Wizard Flow

The wizard follows a linear, four-step progression:

1. **Welcome** - Introduction and feature overview
2. **Select Method** - Choose creation approach
3. **Configure** - Method-specific configuration UI
4. **Finalize** - Review and save

### Integration Points

- **Card Model**: Reuses existing Card image infrastructure (`setOriginalImageData`, `thumbnailData`)
- **CardDetailTab**: Registered as `.mapWizard` tab, available only for `.maps` kind
- **Storage**: Leverages Card's file-based image storage system
- **SwiftData**: Uses environment modelContext for persistence

---

## Supported Map Creation Methods

### 1. Import Image ✅ (Implemented)

**Icon:** `photo.on.rectangle`  
**Purpose:** Import existing map images from files or Photos library

**Features:**
- File picker integration (`.fileImporter`)
- Photos library integration (`PhotosPicker`)
- Drag & drop support (future enhancement)
- Preview before saving
- Supports all standard image formats (PNG, JPEG, HEIC, etc.)

**Use Cases:**
- Pre-made maps from external tools
- Scanned hand-drawn maps
- Downloaded reference maps
- AI-generated maps from external services

**Implementation Status:** ✅ Phase 1 Complete, 🚧 Phase 1.5 In Progress
- [x] File import
- [x] Photos picker
- [x] Preview
- [x] Save to Card
- [🚧] Drag & drop to wizard
- [🚧] Image metadata extraction
- [📋] Batch import (flagged for future enhancement)

---

### 2. Draw Map ✅ (Implemented)

**Icon:** `pencil.and.scribble`  
**Purpose:** Create custom maps using drawing tools

**Features:**
- **Canvas Engine**: Full PencilKit integration with Apple Pencil support
- **Drawing Tools**:
  - ✅ Pen (fine precision lines)
  - ✅ Pencil (textured, sketch-style)
  - ✅ Marker (thick, semi-transparent)
  - ✅ Eraser (vector-based, removes individual strokes)
  - ✅ Lasso (selection tool)
- **Color & Style**:
  - ✅ Full color picker with opacity support
  - ✅ 8 quick color swatches (black, gray, red, orange, yellow, green, blue, purple)
  - ✅ Line width slider (1-20pt range)
  - ✅ Real-time tool updates
- **Canvas Options**:
  - ✅ Configurable canvas size (1024×1024, 2048×2048, 4096×4096)
  - ✅ Background color selection (white, black, parchment, gray)
  - ✅ Grid overlay (square grid, configurable spacing)
  - ✅ Ruler tool for straight lines
- **Undo/Redo**:
  - ✅ Full undo manager integration
  - ✅ Visual feedback for undo/redo availability
  - ✅ Clear canvas with confirmation dialog
- **Export**:
  - ✅ Export as PNG image (high resolution)
  - ✅ Export raw PKDrawing data for re-editing
  - ✅ Platform-specific rendering (UIKit/AppKit)

**Technical Implementation:**
- ✅ macOS: NSViewRepresentable wrapper for PKCanvasView
- ✅ iOS/iPadOS: UIViewRepresentable wrapper for PKCanvasView
- ✅ @Observable model (DrawingCanvasModel) for state management
- ✅ Cross-platform color conversion
- ✅ High-quality image export at device scale
- ✅ Delegate pattern for drawing change notifications

**Use Cases:**
- Fantasy world maps
- City/town layouts
- Building floor plans
- Custom location diagrams
- Concept sketches
- Annotated maps

**Implementation Status:** ✅ Phase 2 Complete (November 13, 2025)
- [x] PencilKit canvas integration (both macOS and iOS/iPadOS)
- [x] Drawing tool palette (5 tools)
- [x] Color picker with quick swatches
- [x] Line width controls
- [x] Grid overlay system
- [x] Ruler tool integration
- [x] Undo/Redo management
- [x] Export as PNG image
- [x] Export/import raw drawing data for re-editing
- [x] Cross-platform support
- [📋] Layer management (deferred to Phase 2.5)
- [📋] Shape tools (rectangles, circles) (deferred to Phase 2.5)
- [📋] Text annotation (deferred to Phase 2.5)
- [📋] Hex grid support (deferred to Phase 2.5)

---

### 3. Capture from Maps ✅ (Implemented)

**Icon:** `map`  
**Purpose:** Import real-world locations from Apple Maps

**Features:**
- **Map Selection**:
  - Embedded MapKit view ✅
  - Location search ✅
  - Pan/zoom controls ✅
  - Map type selection (standard, satellite, hybrid) ✅
- **Capture Options**:
  - Screenshot capture of current view ✅
  - High-resolution export (2048×2048) ✅
  - Apple Maps UI elements excluded automatically ✅
  - Async processing with progress indicator ✅
- **Metadata Preservation**:
  - Store lat/long coordinates ✅
  - Map scale (span) ✅
  - Attribution data (automatic in snapshots) ✅
  - Location name ✅
  - Capture date ✅
  - Map type ✅

**Technical Approach:**
- MapKit SwiftUI integration (`Map` view)
- `MKLocalSearch` for location search
- `MKMapSnapshotter` for high-res capture
- Store geographic metadata alongside image
- PNG format for quality

**Use Cases:**
- Real-world setting research
- Location scouting
- Historical setting reference
- Modern/contemporary story settings

**Implementation Status:** ✅ Phase 3 Complete
- [x] MapKit view integration
- [x] Location search
- [x] Map type picker
- [x] Snapshot capture (MKMapSnapshotter)
- [x] Metadata storage and display
- [x] Attribution handling (automatic)
- [x] Preview and review flow
- [x] Error handling
- [📋] Annotation tools (future Phase 3.5)
- [📋] Custom resolution options (future Phase 3.5)
- [📋] Metadata persistence to Card model (future Phase 3.5)

---

### 4. AI-Assisted Generation 🔮 (Placeholder)

**Icon:** `wand.and.stars`  
**Purpose:** Generate maps using AI/procedural generation with natural language prompts

**Planned Features:**
- **Prompt Interface**:
  - Natural language description
  - Guided prompts (terrain, climate, features)
  - Example templates
  - Refinement iterations
- **Generation Options**:
  - Style selection (fantasy, realistic, stylized)
  - Detail level (overview, detailed)
  - Color scheme
  - Feature density
- **On-Device vs Cloud**:
  - Phase 1: External API integration (if available)
  - Phase 2: On-device Foundation Models integration (if capable)
- **Editing Pipeline**:
  - Generate base map
  - Refine with additional prompts
  - Export to drawing tools for manual touch-up

**Prompt Examples:**
```
"A fantasy kingdom with mountains in the north, 
a great forest to the east, a river running 
through the center, and a coastal city in the south."

"A medieval town with a castle on a hill, 
surrounded by farmland and a defensive wall."

"An alien planet surface with three moons, 
purple vegetation, and crystalline structures."
```

**Technical Approach:**
- **Option A**: Integrate with image generation API (Stable Diffusion, DALL-E)
- **Option B**: Procedural generation algorithm (Perlin noise for terrain)
- **Option C**: Apple Foundation Models (if image generation supported in future)
- Store prompt metadata for regeneration
- Seed control for reproducibility

**Use Cases:**
- Quick concept maps
- Inspiration/brainstorming
- Base layer for manual refinement
- Rapid prototyping

**Implementation Status:** 🔮 Phase 4 (Conceptual)
- [ ] Prompt UI
- [ ] Generation backend integration
- [ ] Style selection
- [ ] Iterative refinement
- [ ] Prompt history/templates
- [ ] Export to drawing tools

---

## User Experience Flow

### Complete Wizard Journey

```
[Welcome Screen]
    ↓
[Method Selection]
    ↓
[Configure Method] ← (varies by method)
    ↓ [Import] → File picker or Photos picker → Preview
    ↓ [Draw] → Canvas with tools → Draw → Preview
    ↓ [Maps] → MapKit view → Select region → Capture → Preview
    ↓ [AI] → Prompt input → Generate → Refine → Preview
    ↓
[Finalize & Review]
    ↓
[Save to Card]
```

### Navigation Controls

- **Back button**: Returns to previous step (when not on Welcome)
- **Continue button**: Advances to next step (disabled until current step valid)
- **Progress indicator**: Dots showing current position in flow
- **Cancel**: Exits wizard without saving (future: confirmation dialog if data entered)

### Validation & Error Handling

- Each step validates before allowing progression
- Method-specific validation (e.g., image selected, drawing not empty)
- Clear error messages for failed operations
- Graceful fallback for unavailable features

---

## Technical Implementation Notes

### Current Status (Phase 1-3)

**Phase 1 - Completed:**
- ✅ Wizard shell and navigation structure
- ✅ All four method cards/placeholders
- ✅ Import image workflow (file + Photos)
- ✅ Save to Card infrastructure
- ✅ Preview UI
- ✅ Integration with CardDetailTab

**Phase 1.5 - Completed:**
- ✅ Drag & drop to wizard
- ✅ Image metadata extraction
- ✅ **Universal attribution expansion** - All views now extract metadata

**Phase 2 - Completed (November 13, 2025):**
- ✅ Full PencilKit integration (macOS, iOS, iPadOS)
- ✅ Drawing canvas with @Observable model
- ✅ 5 drawing tools (pen, pencil, marker, eraser, lasso)
- ✅ Color picker with 8 quick swatches
- ✅ Line width controls (1-20pt slider)
- ✅ Canvas size options (1024, 2048, 4096)
- ✅ Background color customization
- ✅ Grid overlay system
- ✅ Ruler tool for straight lines
- ✅ Undo/Redo with UndoManager
- ✅ Export as PNG image
- ✅ Export/import raw PKDrawing data
- ✅ Cross-platform rendering

**Phase 3 - Completed:**
- ✅ MapKit view integration
- ✅ Location search
- ✅ Map type selection (standard/satellite/hybrid)
- ✅ High-resolution snapshot capture
- ✅ Map metadata storage and display
- ✅ Preview and review flow
- ✅ Error handling

**Deferred to Future Phases:**
- Layer system for drawings (Phase 2.5)
- Shape tools (Phase 2.5)
- Text annotation (Phase 2.5)
- Annotation tools for maps (Phase 3.5)
- Metadata persistence (Phase 3.5)
- AI generation (Phase 4)

### Code Organization

```
MapWizardView.swift
├── Main View
│   ├── Header (title, progress)
│   ├── Step Content (dynamic based on currentStep)
│   └── Footer (navigation)
├── Step Views
│   ├── welcomeStepView
│   ├── methodSelectionView
│   ├── configureStepView (dynamic)
│   └── finalizeStepView
├── Supporting Types
│   ├── WizardStep enum
│   ├── MapCreationMethod enum
│   └── DrawingCanvasState (future)
└── Helper Views
    ├── FeatureRow
    ├── MethodCard
    └── (future: drawing tools, map controls)
```

### State Management

All wizard state is `@State` local to MapWizardView:
- `currentStep`: Current position in wizard
- `selectedMethod`: User's chosen creation method
- `importedImageData`: Image data from import flow
- `drawingCanvas`: Future drawing state
- `generationPrompt`: AI prompt text
- `isWorking`: Loading/processing indicator

### Performance Considerations

- Lazy loading of method-specific views
- Async image loading from Photos picker
- Future: Background processing for AI generation
- Future: Incremental canvas rendering for large drawings

---

## Future Enhancements

### Short Term (Phase 1.5 - ✅ Complete)
1. ~~**Drag & drop** support for image import~~ ✅
2. ~~**Image metadata extraction** (dimensions, file size, format, GPS)~~ ✅
3. ~~**Batch import** for multiple images~~ → Future Enhancement 📋

### Short Term (Phase 2 - ✅ Complete)
1. ~~**PencilKit drawing** implementation~~ ✅
2. ~~**Canvas templates** (grid, shapes)~~ ✅ (Grid overlay implemented)
3. ~~**Layer support** for drawings~~ → Deferred to Phase 2.5 📋
4. ~~**Undo/Redo** system~~ ✅

### Medium Term (Phase 2.5 - Planned)
1. **Layer system** for complex drawings
2. **Shape tools** (rectangles, circles, polygons, lines)
3. **Text annotation** on canvas
4. **Hex grid** overlay option
5. **Custom brush library** for terrain types
6. **Drawing templates** (island, continent, city layouts)

### Short Term (Phase 3 - ✅ Complete)
1. ~~**MapKit integration** for location capture~~ ✅
2. ~~**Map type selection** (standard/satellite/hybrid)~~ ✅
3. ~~**Location search**~~ ✅
4. ~~**High-resolution snapshot capture**~~ ✅
5. ~~**Map metadata** storage (location, scale, coordinates)~~ ✅

### Short Term (Phase 3.5 - Planned)
1. **Annotation tools** for maps before capture
2. **Custom resolution options** for snapshots
3. **Map metadata persistence** to Card model
4. **Recent searches** history

### Medium Term (Phase 4)
1. **AI generation** (when APIs available/affordable)
2. **Procedural generation** fallback
3. **Batch import** for multiple images 📋

### Long Term (Phase 4)
1. **AI generation** (when APIs available/affordable)
2. **Procedural generation** fallback
3. **3D map visualization** (SceneKit/RealityKit)
4. **Collaborative editing** (if multi-user support added to app)

### Quality of Life
- [ ] Undo/redo for all operations
- [ ] Keyboard shortcuts
- [ ] Preset styles/themes
- [ ] Export maps independently (not just attached to Card)
- [ ] Map versioning (save multiple iterations)
- [ ] Tutorial/help overlay
- [ ] Sample maps gallery

---

## Design Patterns & Best Practices

### SwiftUI Patterns Used
- **Environment-based dependency injection** (modelContext, colorScheme)
- **Compositional view hierarchy** (step views as computed properties)
- **State-driven UI** (single source of truth for wizard state)
- **ViewBuilder** for dynamic content switching

### Accessibility Considerations
- All buttons have labels
- Images have accessibility descriptions
- Progress indicator visually and semantically clear
- Future: VoiceOver optimizations for drawing tools

### Cross-Platform Support
- macOS-first design (current implementation)
- iOS/iPadOS compatible structure
- Platform-specific imports (`#if canImport(UIKit/AppKit)`)
- Future: iPad-optimized layouts
- visionOS: Consider spatial UI for map manipulation

---

## Testing Strategy

### Unit Tests (Future)
- Wizard state transitions
- Validation logic per step
- File extension inference
- Image data handling

### Integration Tests (Future)
- End-to-end wizard flow
- Save to Card model
- Photos picker integration
- File import flow

### Manual Testing Checklist
- [x] Wizard launches for Map cards
- [x] Navigation between steps works
- [x] Progress indicator updates correctly
- [x] Import image from files works
- [x] Import image from Photos works
- [x] Preview displays correctly
- [x] Save to Card persists image
- [x] Wizard resets after save
- [ ] Error states display properly
- [ ] Cancel without saving works

---

## Dependencies

### Framework Dependencies
- SwiftUI (core UI)
- SwiftData (model persistence)
- PhotosUI (Photos picker)
- UniformTypeIdentifiers (file type handling)
- ImageIO (image metadata)
- UIKit/AppKit (platform-specific image handling)
- **MapKit** (map view, search, snapshots) ✅
- **CoreLocation** (coordinate types) ✅

### Future Dependencies
- PencilKit (drawing - Phase 2)
- Foundation Models (AI generation - Phase 4, if supported)

### App-Internal Dependencies
- Card model (image storage)
- CardDetailTab (registration)
- Kinds enum (`.maps` filtering)

---

## Open Questions & Decisions Needed

1. **Drawing Data Format**: Should we store raw PencilKit data for re-editing, or just final image?
   - **Recommendation**: Store both (PencilKit data in separate field)

2. **AI Generation**: Wait for Apple Foundation Models to mature, or integrate third-party API?
   - **Recommendation**: Phase 4, evaluate when reached

3. **Map Versioning**: Should Cards support multiple map versions/iterations?
   - **Recommendation**: Future enhancement, not MVP

4. **Export Options**: Should maps be exportable independently of Cards?
   - **Recommendation**: Yes, add export button to finalize step

5. **Undo/Redo**: Global undo manager or per-method undo stack?
   - **Recommendation**: Per-method, implement in Phase 2

---

## Success Metrics

### Phase 1 (Current)
- [x] Writers can import existing map images
- [x] Images save correctly to Card model
- [x] Wizard UX is clear and intuitive
- [x] No crashes or data loss

### Phase 1.5 (Current)
- [x] Drag and drop works smoothly
- [x] Metadata extraction is accurate
- [x] Metadata display is informative

### Phase 2 (Drawing) - ✅ Complete
- [x] Writers can create simple maps from scratch
- [x] Drawing tools are responsive and accurate
- [x] Grid overlay allows structured composition
- [x] Undo/Redo works reliably
- [x] Color and line width controls are intuitive
- [x] Canvas exports to high-quality PNG images
- [x] Cross-platform support (macOS, iOS, iPadOS)
- [x] Apple Pencil support (on iPad)

### Phase 3 (Maps) - ✅ Complete
- [x] Real-world locations can be captured easily
- [x] Location search is accurate and fast
- [x] Map styles display correctly
- [x] Captures are high-quality and accurate
- [x] Captures include useful metadata
- [x] Attribution data preserved

### Phase 4 (AI)
- [ ] Prompts generate usable maps
- [ ] Generation is fast enough for iterative refinement
- [ ] Cost/performance acceptable

---

## Related Documentation

- `Card.swift` - Model definition and image handling methods
- `CardDetailTab.swift` - Tab registration and availability logic
- `CardDetailView.swift` - Parent view that hosts wizard
- `Kinds.swift` - Kind definitions (`.maps`)

---

## Changelog

**2025-11-13** - Phase 2 implementation complete (Drawing Canvas)
- ✅ Consolidated duplicate DrawingCanvasView implementations
- ✅ Full PencilKit integration with @Observable model
- ✅ 5 drawing tools: pen, pencil, marker, eraser, lasso
- ✅ Color picker with 8 quick color swatches
- ✅ Line width slider (1-20pt)
- ✅ Canvas size options (1024, 2048, 4096)
- ✅ Background color customization
- ✅ Grid overlay system with configurable spacing
- ✅ Ruler tool for straight line drawing
- ✅ Full undo/redo with UndoManager
- ✅ Export as PNG image (platform-specific rendering)
- ✅ Export/import raw PKDrawing data for re-editing
- ✅ Cross-platform support (macOS NSViewRepresentable, iOS/iPadOS UIViewRepresentable)
- ✅ Integration with MapWizardView
- ✅ Proper validation logic
- 📖 Updated specification with Phase 2 completion status

**2025-11-11** - Universal attribution expansion
- ✅ Extended automatic metadata extraction to all image import locations
- ✅ CardEditorView: PhotosPicker, file importer, all drop handlers
- ✅ CardSheetView: Drop target
- ✅ Consistent behavior across entire app
- 📖 See `Universal-Attribution-Expansion.md` for details

**2025-11-11** - Phase 3 implementation complete (MapKit integration)
- ✅ Interactive MapKit view with pan/zoom
- ✅ Location search with natural language queries
- ✅ Map type selection (standard/satellite/hybrid)
- ✅ High-resolution snapshot capture (2048×2048)
- ✅ Map metadata storage and display
- ✅ Preview and review workflow
- ✅ Error handling for search and capture
- ✅ Cross-platform support (macOS/iOS/iPadOS)
- ✅ Updated validation logic for map captures

**2025-11-11** - Initial specification created
- Phase 1 implementation complete (import image workflow)
- Phase 1.5 implementation complete (drag & drop, metadata)
- Placeholders for Phases 2-4
- Integrated with CardDetailTab for Map cards
- Full wizard shell with navigation and state management

---

## Notes for Future Developers

### Adding a New Creation Method

1. Add case to `MapCreationMethod` enum
2. Add icon and description
3. Create corresponding config view in `configureStepView`
4. Add state properties for method-specific data
5. Update `canProceed` validation logic
6. Implement save logic in `saveMap()`
7. Add tests

### Extending Existing Methods

Each method's config view is self-contained. Enhancements should:
- Maintain the existing state properties
- Add new validation to `canProceed` if needed
- Update preview in `finalizeStepView` if display changes
- Consider backward compatibility with existing saved maps

### Performance Tips

- Large images: Consider thumbnail generation during import
- Drawing: Render incrementally, not on every point
- AI: Show progress, allow cancellation
- Maps: Use `MKMapSnapshotter` asynchronously

---

**End of Specification**
