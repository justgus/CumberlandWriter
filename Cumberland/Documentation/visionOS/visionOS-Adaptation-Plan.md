# Cumberland visionOS Adaptation Plan

**Created:** November 7, 2025  
**Status:** Planning Phase

---

## Summary

This document outlines the strategy for adapting Cumberland, a creative writing workspace app, to visionOS. The adaptation focuses on leveraging visionOS's spatial computing paradigm through **ornaments** (the visionOS equivalent of macOS menu bars) while maintaining backward compatibility with macOS and iOS/iPadOS.

---

## Current Architecture Overview

Cumberland is built with:
- **Three-pane NavigationSplitView**: Sidebar → Content List → Detail
- **14 card types**: Projects, Worlds, Characters, Scenes, Chapters, Timelines, Maps, Locations, Buildings, Vehicles, Artifacts, Rules, Sources, Structure
- **Multiple detail views**: 
  - Details (CardSheetView)
  - Relationships (CardRelationshipView)
  - Boards (StructureBoardView for Projects, MurderBoardView for Worlds/Characters/Scenes)
  - Timeline (TimelineChartView for Timelines)
  - Aggregate Text (AggregateTextView for Chapters)
- **Platform support**: macOS and iOS/iPadOS with adaptive UI
- **Complex state management**: 
  - Per-kind column visibility preferences
  - Tab memory per card kind
  - Focus mode for distraction-free editing
  - Search-driven navigation

---

## visionOS Design Philosophy

### Key Concepts

**Ornaments** are the visionOS metaphor for traditional menus and toolbars:
- Floating UI containers attached to windows
- Positioned around window edges (bottom, top, leading, trailing)
- Blend naturally with the spatial environment using glass materials
- Respond to gaze, pinch, and pointer interactions

**Why Ornaments?**
- Menu bars don't exist in visionOS's spatial interface
- Toolbars automatically adapt but ornaments provide better control
- Allows actions to "float" near content without obscuring it
- Natural fit for multi-window spatial environments

---

## Adaptation Strategy

### Phase 1: Ornament-Based Navigation ✅ **Priority**
Replace traditional toolbars with visionOS ornaments for spatial UI.

**Changes Required:**
1. **Add primary actions ornament** (bottom placement)
   - New Card button
   - Edit Card button
   - Developer Boards button (DEBUG only)
2. **Add settings ornament** (trailing placement)
   - Settings button
   - Future: additional utility actions
3. **Add detail tab picker ornament** (trailing placement, detail column)
   - Tab selection picker for switching between Details/Relationships/Board/etc.
4. **Conditional compilation** (`#if os(visionOS)`)
   - Preserve existing toolbar for macOS/iOS
   - Enable ornaments only on visionOS

**Files Modified:**
- `MainAppView.swift`

**New Files:**
- `OrnamentViews.swift` (centralized ornament components)

---

### Phase 2: Spatial Window Management ✅ **COMPLETE** (Nov 9, 2025)
Leverage visionOS's unique window capabilities.

**Changes Required:**
1. **WindowGroup for main app** ✅ DONE
   - Standard three-pane layout in a floating window
   - Existing NavigationSplitView works as-is
2. **Separate WindowGroup for card editors** ✅ DONE
   - Allow card creation/editing in independent floating windows
   - Users can position editors alongside main content
   - Use `WindowGroup(for: AppModel.CardEditorRequest.self)`
3. **Volume for 3D board views** (optional, exploratory) 🔮 FUTURE
   - StructureBoardView could become a true 3D spatial experience
   - MurderBoardView nodes could float in 3D space
   - Requires significant 3D visualization work
4. **ImmersiveSpace consideration** (optional, future) 🔮 FUTURE
   - Full-canvas writing mode for distraction-free work
   - Surrounds user with their creative workspace

**Files Modified:**
- `CumberlandApp.swift` ✅ (added WindowGroup for card editors)
- `AppModel.swift` ✅ (added CardEditorRequest tracking)
- `MainAppView.swift` ✅ (updated to use openWindow on visionOS)
- `CardEditorWindowView.swift` ✅ NEW FILE (window wrapper for editors)

---
### Phase 3: Material & Visual Refinements 🎨 **Polish**
Apply visionOS design language throughout the interface.

**Changes Required:**
1. **Glass background effects** on ornaments
   - `.glassBackgroundEffect()` modifier on all ornament buttons/containers
   - Provides proper depth and integration with environment
2. **Hover effects** for interactive elements
   - Built-in to SwiftUI buttons in visionOS
   - Custom hover effects for card list rows using `.hoverEffect()`
3. **Depth and elevation** through proper layering
   - Ornaments naturally float above window surface
   - Card thumbnails could gain subtle 3D depth
4. **Updated card list styling**
   - More generous spacing for gaze/pointer interaction
   - Larger tap targets (minimum 44pt, preferably 60pt)
   - Enhanced visual feedback on selection

**Files Modified:**
- `MainAppView.swift` (CardListRow adjustments)
- `OrnamentViews.swift` (ornament styling)
- Potentially: `CardSheetView.swift`, other detail views

---

### Phase 4: Interaction Model Updates ✅ **COMPLETE** (Nov 11, 2025)
Adapt for spatial input (gaze, pinch, pointer).

**Changes Completed:**
1. **Larger tap targets** in card lists ✅
   - Current: 52pt thumbnail + 10pt vertical padding = 72pt total row height
   - Exceeds visionOS 60pt recommended minimum
   - Enhanced corner radius (8pt) and spacing for comfort
2. **Enhanced context menus** with better visual hierarchy ✅
   - Sectioned menus for visionOS (Primary/Future/Destructive)
   - Platform-specific behavior (simpler for macOS/iOS)
   - "Edit Card" opens floating window on visionOS
3. **Comprehensive accessibility** ✅
   - VoiceOver labels and hints on all interactive elements
   - Keyboard shortcuts for primary actions (⌘N, ⌘E, ⌘,, etc.)
   - Proper focus management and element grouping
   - Clear accessibility announcements throughout UI
4. **Enhanced hover effects** ✅
   - Changed from `.lift` to `.highlight` for natural spatial feel
   - Full-area tappability with `.contentShape(Rectangle())`
   - Improved visual feedback on all interactive elements
5. **Typography and visual refinements** ✅
   - Larger fonts for spatial readability (`.title3` for card names)
   - Kind badges with subtle background styling
   - Better visual hierarchy throughout card list

**Files Modified:**
- `MainAppView.swift` ✅ (CardListRow, context menus, accessibility)
- `OrnamentViews.swift` ✅ (accessibility, keyboard shortcuts)

**Summary Document:**
- `visionOS-Phase4-Implementation-Summary.md` ✅ CREATED

---

## Detailed Implementation Outline

### File: MainAppView.swift

#### Section A: Ornament Integration

Add after the existing `.toolbar { }` block:

```swift
#if os(visionOS)
.ornament(attachmentAnchor: .scene(.bottom)) {
    primaryActionsOrnament
}
.ornament(attachmentAnchor: .scene(.trailing)) {
    settingsOrnament
}
#endif
```

Add to detail column view:

```swift
#if os(visionOS)
.ornament(attachmentAnchor: .scene(.trailing)) {
    detailTabPickerOrnament
}
#endif
```

**New computed properties to add:**
- `primaryActionsOrnament` → HStack with New Card, Edit buttons
- `settingsOrnament` → Settings button (+ developer boards in DEBUG)
- `detailTabPickerOrnament` → Picker for tab switching

#### Section B: Conditional Toolbar

Modify existing `.toolbar { }` blocks:

```swift
.toolbar {
    #if !os(visionOS)
    // Existing toolbar items for macOS/iOS
    ToolbarItem(placement: .navigation) {
        Button { showingSettings = true } label: {
            Label("Settings", systemImage: "gear")
        }
    }
    // ... rest of toolbar
    #endif
}
```

**Rationale:**
- macOS and iOS keep their native toolbar behavior
- visionOS users interact via ornaments instead
- No functional loss, just platform-appropriate presentation

#### Section C: Visual Refinements

Modify `CardListRow` for visionOS:

```swift
private struct CardListRow: View {
    let card: Card
    @State private var thumbnailImage: Image?

    #if os(visionOS)
    private let thumbSize: CGFloat = 48
    private let thumbWidth: CGFloat = 72
    #else
    private let thumbSize: CGFloat = 40
    private let thumbWidth: CGFloat = 60
    #endif
    
    var body: some View {
        HStack(spacing: 12) {
            // ... existing thumbnail code
            // ... existing text labels
        }
        #if os(visionOS)
        .padding(.vertical, 8)
        .hoverEffect(.lift)
        #else
        .padding(.vertical, 4)
        #endif
        // ... rest of implementation
    }
}
```

---

### File: OrnamentViews.swift (NEW)

Create a new file to centralize ornament UI components for visionOS.

**Purpose:**
- Keep MainAppView.swift from becoming cluttered
- Reusable ornament components
- Shared styling utilities

**Contents:**

```swift
import SwiftUI

#if os(visionOS)

// MARK: - Primary Actions Ornament

struct PrimaryActionsOrnament: View {
    let onNewCard: () -> Void
    let onEditCard: () -> Void
    let canEdit: Bool
    let isStructureSelected: Bool
    #if DEBUG
    let onDeveloperBoards: () -> Void
    #endif
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onNewCard()
            } label: {
                Label("New Card", systemImage: "plus")
            }
            .disabled(isStructureSelected)
            .glassBackgroundEffect()
            
            Button {
                onEditCard()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .disabled(!canEdit)
            .glassBackgroundEffect()
            
            #if DEBUG
            Button {
                onDeveloperBoards()
            } label: {
                Label("Developer Boards", systemImage: "wrench.and.screwdriver")
            }
            .glassBackgroundEffect()
            #endif
        }
        .padding()
    }
}

// MARK: - Settings Ornament

struct SettingsOrnament: View {
    let onSettings: () -> Void
    
    var body: some View {
        Button {
            onSettings()
        } label: {
            Label("Settings", systemImage: "gear")
        }
        .glassBackgroundEffect()
        .padding()
    }
}

// MARK: - Detail Tab Picker Ornament

struct DetailTabPickerOrnament: View {
    let tabs: [CardDetailTab]
    @Binding var selectedTab: CardDetailTab
    
    var body: some View {
        Picker("Card View", selection: $selectedTab) {
            ForEach(tabs) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 420)
        .glassBackgroundEffect()
        .padding()
    }
}

#endif // os(visionOS)
```

---

### File: CumberlandApp.swift (FUTURE)

Main app entry point needs conditional WindowGroup setup.

**Current (assumed):**
```swift
@main
struct CumberlandApp: App {
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .modelContainer(for: Card.self)
        }
    }
}
```

**visionOS Enhancement (Phase 2):**
```swift
@main
struct CumberlandApp: App {
    var body: some Scene {
        #if os(visionOS)
        // Main window
        WindowGroup(id: "main") {
            MainAppView()
                .modelContainer(for: Card.self)
        }
        
        // Floating card editor
        WindowGroup(id: "cardEditor", for: Card.ID.self) { $cardID in
            if let cardID {
                CardEditorWindowView(cardID: cardID)
                    .modelContainer(for: Card.self)
            }
        }
        
        // Optional: 3D board volume
        WindowGroup(id: "boardVolume", for: Card.ID.self) { $cardID in
            if let cardID {
                Board3DView(cardID: cardID)
                    .modelContainer(for: Card.self)
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 800, height: 600, depth: 400, in: .points)
        
        #else
        // macOS/iOS: single window group
        WindowGroup {
            MainAppView()
                .modelContainer(for: Card.self)
        }
        #endif
    }
}
```

---

## Key Design Decisions

### ✅ Keep NavigationSplitView
**Decision:** Retain existing three-pane NavigationSplitView architecture.

**Rationale:**
- Works beautifully in visionOS as a floating window
- Three-pane layout provides excellent information density in spatial canvas
- No need to redesign core navigation—saves significant development time
- Users familiar with macOS/iOS version will feel at home

**Trade-offs:**
- Could explore more "spatial native" layouts in future (Phase 3+)
- For v1.0 visionOS support, this is the right call

---

### ✅ Ornaments for Actions
**Decision:** Use ornaments for primary actions, settings, and tab switching.

**Layout:**
- **Bottom ornament**: New Card + Edit Card buttons (primary actions)
- **Trailing ornament (main window)**: Settings button
- **Trailing ornament (detail column)**: Tab picker (Details/Relationships/Board/etc.)

**Rationale:**
- Ornaments are the visionOS-native way to provide persistent controls
- Bottom placement for primary actions follows Apple's guidelines
- Keeps actions visible but non-intrusive
- Natural discoverability for spatial input (gaze/pinch)

**Alternative considered:** Toolbar-only approach
- Rejected because toolbars feel "flatter" in visionOS
- Ornaments provide better spatial depth and context

---

### ✅ Glass Material
**Decision:** All ornament backgrounds use `.glassBackgroundEffect()`.

**Rationale:**
- Provides proper depth and integration with visionOS environment
- Follows Apple's design language for spatial UI
- Automatically adapts to lighting conditions in user's space
- Signals "system-level" interaction (like Control Center)

**Implementation:**
- Apply to each ornament container
- Individual buttons within ornaments also get glass effect for consistency

---

### 🔄 Progressive Enhancement
**Decision:** Ship Phase 1 first, iterate with Phases 2-4.

**Rationale:**
- Phase 1 (ornaments) provides immediate functional visionOS support
- Users can start using Cumberland in visionOS right away
- Later phases add polish and spatial-specific features
- Allows gathering user feedback before investing in advanced features (volumes, immersive spaces)

**Milestones:**
1. **v1.0 visionOS support**: Phase 1 complete
2. **v1.1**: Phase 3 visual refinements
3. **v1.2**: Phase 2 window management + Phase 4 interaction refinements
4. **v2.0**: Consider 3D volumes for boards, immersive writing mode

---

### ✅ Backward Compatibility Maintained
**Decision:** All visionOS code is conditional (`#if os(visionOS)`).

**Rationale:**
- macOS and iOS/iPadOS are primary platforms—no regressions allowed
- Conditional compilation ensures zero performance/binary size impact on other platforms
- Allows different interaction paradigms per platform (toolbar vs. ornaments)

**Testing requirement:**
- Every change must be tested on all three platforms
- Use Xcode's platform switcher during development

---

## Implementation Steps (When Ready)

### Step 1: Create OrnamentViews.swift
**Estimated time:** 30 minutes

1. Create new Swift file: `OrnamentViews.swift`
2. Add `#if os(visionOS)` wrapper
3. Implement three ornament components:
   - `PrimaryActionsOrnament`
   - `SettingsOrnament`
   - `DetailTabPickerOrnament`
4. Add glass background effects and padding

**Deliverable:** Reusable ornament components ready for integration

---

### Step 2: Update MainAppView.swift - Add Ornaments
**Estimated time:** 45 minutes

1. Add computed properties for ornament views
2. Add `.ornament()` modifiers after toolbar block
3. Wrap existing toolbar in `#if !os(visionOS)`
4. Test compilation on visionOS simulator

**Deliverable:** Ornaments appear in visionOS, toolbars remain on macOS/iOS

---

### Step 3: Refine CardListRow for visionOS
**Estimated time:** 20 minutes

1. Add conditional sizing for thumbnails
2. Increase vertical padding on visionOS
3. Add `.hoverEffect(.lift)` modifier
4. Test interaction with gaze/pinch

**Deliverable:** Card list feels natural with spatial input

---

### Step 4: Test Interaction Model
**Estimated time:** 1 hour

1. Test all primary workflows in visionOS simulator
   - Create card
   - Edit card
   - Switch between card types
   - Navigate detail tabs
   - Search functionality
2. Verify ornaments remain accessible during navigation
3. Test with keyboard (accessibility)
4. Document any quirks or issues

**Deliverable:** Confidence in user experience quality

---

### Step 5: Add WindowGroup Variants (Phase 2 - Optional)
**Estimated time:** 2-3 hours

1. Locate/modify `CumberlandApp.swift`
2. Add conditional WindowGroup setup for visionOS
3. Create floating card editor window
4. Update editor presentation logic to use `openWindow`
5. Test multi-window workflows

**Deliverable:** Card editors can float independently from main window

---

## Estimated Scope

### Phase 1: Minimal Viable visionOS Support
- **New code:** ~100-150 lines (OrnamentViews.swift)
- **Modified code:** ~50 lines of conditionals (MainAppView.swift)
- **Time estimate:** 2-3 hours of focused work
- **Testing time:** 1-2 hours

**Result:** Cumberland launches and functions on visionOS with ornament-based UI.

---

### Phases 2-3: Full Spatial Polish
- **New code:** ~300-400 lines (window management, visual refinements)
- **Modified code:** ~100 lines across multiple files
- **Time estimate:** 6-8 hours of focused work
- **Testing time:** 3-4 hours

**Result:** Cumberland feels native to visionOS with proper spatial behaviors.

---

### Phase 4: Advanced Features (Optional)
- **New code:** ~1000+ lines (3D volumes, immersive spaces)
- **Time estimate:** 20+ hours
- **Requires:** 3D visualization expertise, significant UX testing

**Result:** Cumberland becomes a showcase for visionOS spatial computing.

---

## Open Questions

### Q1: Should card editors open as sheets or separate windows on visionOS?
**Current behavior:** Modal sheets (`.sheet()` modifier)

**Options:**
- **A)** Keep sheets (simpler, familiar)
- **B)** Use separate windows (more spatial, allows side-by-side editing)

**Recommendation:** Start with (A) in Phase 1, add (B) in Phase 2 as an enhancement.

---

### Q2: How should Focus Mode work in visionOS?
**Current behavior:** Hides content column on iPad, shows only detail view.

**visionOS considerations:**
- Could hide ornaments entirely for minimal distraction
- Could dim/hide other windows in the environment
- Could transition to immersive space

**Recommendation:** Start with current behavior (hide content column), explore immersive space in later phase.

---

### Q3: Should boards (StructureBoardView, MurderBoardView) be 3D volumes?
**Current behavior:** 2D canvas with node positioning.

**visionOS opportunity:**
- Nodes could exist in 3D space with depth
- Connections could arc through 3D space
- User could walk around the board

**Recommendation:** Extremely cool but significant work. Phase 4 exploration, not required for initial visionOS launch.

---

### Q4: What about Apple Pencil support on visionOS?
**Context:** Future visionOS may support drawing input.

**Cumberland implications:**
- Sketching on cards
- Annotating relationships
- Drawing on boards

**Recommendation:** Monitor visionOS releases. Not actionable yet.

---

## Success Criteria

### Phase 1 Launch (visionOS v1.0)
- ✅ App launches and runs on visionOS
- ✅ All card types are accessible via ornaments
- ✅ Card creation/editing works via sheets
- ✅ Navigation between views is smooth
- ✅ No regressions on macOS or iOS
- ✅ Basic gaze/pinch interaction feels natural

---

### Phase 2-3 (visionOS v1.1-1.2)
- ✅ Card editors can open in separate floating windows
- ✅ Visual polish matches visionOS design language
- ✅ Hover effects and glass materials throughout
- ✅ Larger tap targets for spatial comfort
- ✅ Enhanced accessibility (VoiceOver, keyboard)

---

### Phase 4 (visionOS v2.0 - Aspirational)
- ✅ 3D board volumes for visual exploration
- ✅ Immersive writing mode for deep focus
- ✅ Spatial gestures for relationship creation
- ✅ Featured in Apple's visionOS showcase (aspirational!)

---

## Resources & References

### Apple Documentation
- [Building spatial experiences with RealityKit](https://developer.apple.com/documentation/visionos/building-spatial-experiences)
- [Ornaments in visionOS](https://developer.apple.com/documentation/swiftui/view/ornament(attachmentanchor:contentanchor:ornament:))
- [WindowGroup for visionOS](https://developer.apple.com/documentation/swiftui/windowgroup)
- [Glass materials and effects](https://developer.apple.com/documentation/swiftui/view/glassbackgroundeffect(in:displaymode:))

### Design Guidelines
- [Human Interface Guidelines: visionOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-visionos)
- [Spatial design principles](https://developer.apple.com/design/human-interface-guidelines/spatial-design)

### Internal References
- `MainAppView.swift` - Main three-pane interface
- `CardDetailTab.swift` - Tab enumeration and availability logic
- `NavigationCoordinator.swift` - Routing coordinator
- `Kinds.swift` - Card type definitions and theming

---

## Version History

### v1.0 - November 7, 2025
- Initial plan created
- Four phases outlined
- Implementation steps defined
- Open questions documented

### v1.1 - November 9, 2025
- **Phase 2 Complete**: Spatial Window Management
- Card editors now open in floating windows on visionOS
- Added CardEditorWindowView wrapper
- Updated AppModel with CardEditorRequest tracking
- Modified MainAppView to use openWindow API
- Created Phase 2 implementation summary document

### v1.2 - November 11, 2025
- **Phase 4 Complete**: Interaction Model Updates
- Enhanced card list rows with larger tap targets (72pt total height)
- Improved context menus with sectioned hierarchy for visionOS
- Comprehensive accessibility enhancements (VoiceOver, keyboard shortcuts)
- Better hover effects and visual feedback for spatial input
- Typography improvements for spatial readability
- Created Phase 4 implementation summary document

---

## Next Steps

**Immediate:**
1. Review this plan with team/stakeholders
2. Decide on Phase 1 timeline
3. Set up visionOS simulator for testing
4. Begin implementation with OrnamentViews.swift

**Short-term (1-2 weeks):**
1. Complete Phase 1 implementation
2. Test on visionOS simulator
3. Gather feedback from TestFlight beta (if available)
4. Plan Phase 2-3 enhancements

**Long-term (3-6 months):**
1. Ship Phase 2-3 refinements
2. Explore Phase 4 advanced features
3. Consider visionOS-exclusive capabilities
4. Submit Cumberland for visionOS App Store

---

**Document maintained by:** Cumberland Development Team  
**Last updated:** November 7, 2025
