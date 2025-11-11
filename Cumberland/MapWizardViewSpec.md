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

**Implementation Status:** ✅ Phase 1 Complete
- [x] File import
- [x] Photos picker
- [x] Preview
- [x] Save to Card
- [ ] Drag & drop to wizard
- [ ] Batch import
- [ ] Image metadata extraction

---

### 2. Draw Map 🚧 (Placeholder)

**Icon:** `pencil.and.scribble`  
**Purpose:** Create custom maps using drawing tools

**Planned Features:**
- **Canvas Engine**: PencilKit integration for Apple Pencil support
- **Drawing Tools**:
  - Freehand pen/brush
  - Shapes (rectangles, circles, polygons)
  - Lines and connectors
  - Text annotations
- **Layer System**:
  - Background layer (terrain)
  - Feature layers (roads, rivers, cities)
  - Label layer (place names)
  - Overlay layer (annotations, highlights)
- **Color & Style**:
  - Color picker with swatches
  - Line width controls
  - Fill patterns
  - Custom brushes (future)
- **Templates**:
  - Blank canvas
  - Grid overlays (square, hex)
  - Common map shapes (island, continent, region)

**Technical Approach:**
- macOS: NSView-based PencilKit wrapper
- iOS: Native PencilKit canvas
- Export as PNG/SVG
- Store drawing data separately for future editing

**Use Cases:**
- Fantasy world maps
- City/town layouts
- Building floor plans
- Custom location diagrams

**Implementation Status:** 🚧 Phase 2 (Not Started)
- [ ] PencilKit canvas integration
- [ ] Drawing tool palette
- [ ] Layer management
- [ ] Shape tools
- [ ] Text annotation
- [ ] Export as image
- [ ] Save drawing data for re-editing

---

### 3. Capture from Maps 🚧 (Placeholder)

**Icon:** `map`  
**Purpose:** Import real-world locations from Apple Maps

**Planned Features:**
- **Map Selection**:
  - Embedded MapKit view
  - Location search
  - Pan/zoom controls
  - Map type selection (standard, satellite, hybrid)
- **Capture Options**:
  - Screenshot capture of current view
  - Bounding box selection
  - Export at custom resolution
  - Include/exclude Apple Maps UI elements
- **Annotation Support**:
  - Add pins/markers before capture
  - Custom labels
  - Region highlights
- **Metadata Preservation**:
  - Store lat/long bounds
  - Map scale
  - Attribution data
  - Location name

**Technical Approach:**
- MapKit SwiftUI integration
- `MKMapSnapshotter` for high-res capture
- Store geographic metadata alongside image
- Option to link to live Maps for reference

**Use Cases:**
- Real-world setting research
- Location scouting
- Historical setting reference
- Modern/contemporary story settings

**Implementation Status:** 🚧 Phase 3 (Not Started)
- [ ] MapKit view integration
- [ ] Location search
- [ ] Map type picker
- [ ] Snapshot capture (MKMapSnapshotter)
- [ ] Annotation tools
- [ ] Metadata storage
- [ ] Attribution handling

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

### Current Status (Phase 1)

**Completed:**
- ✅ Wizard shell and navigation structure
- ✅ All four method cards/placeholders
- ✅ Import image workflow (file + Photos)
- ✅ Save to Card infrastructure
- ✅ Preview UI
- ✅ Integration with CardDetailTab

**Deferred to Future Phases:**
- Drawing canvas (Phase 2)
- Maps capture (Phase 3)
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

### Short Term (Phase 2)
1. **Drag & drop** support for image import
2. **PencilKit drawing** implementation
3. **Canvas templates** (grid, shapes)
4. **Layer support** for drawings

### Medium Term (Phase 3)
1. **MapKit integration** for location capture
2. **Batch import** for multiple images
3. **Map metadata** storage (location, scale)
4. **Annotation tools** for all methods

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

### Future Dependencies
- PencilKit (drawing - Phase 2)
- MapKit (location capture - Phase 3)
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

### Phase 2 (Drawing)
- [ ] Writers can create simple maps from scratch
- [ ] Drawing tools are responsive and accurate
- [ ] Layers allow complex composition

### Phase 3 (Maps)
- [ ] Real-world locations can be captured easily
- [ ] Captures include useful metadata
- [ ] Attribution data preserved

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

**2025-11-11** - Initial specification created
- Phase 1 implementation complete (import image workflow)
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
