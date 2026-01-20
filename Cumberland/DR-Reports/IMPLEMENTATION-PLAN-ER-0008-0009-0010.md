# Implementation Plan: ER-0008, ER-0009, ER-0010

**Major Enhancement Requests - AI and Timeline System**

**Date Created:** 2026-01-20
**Status:** Planning Phase
**Target Completion:** TBD

---

## Executive Summary

This implementation plan coordinates three major enhancement requests that will transform Cumberland's capabilities:

- **ER-0008:** Time-Based Timeline System with Custom Calendars and Multi-Timeline Visualization
- **ER-0009:** AI Image Generation for Cards (Apple Intelligence and Third-Party APIs)
- **ER-0010:** AI Assistant for Content Analysis and Structured Data Extraction

These features are interconnected and share infrastructure, requiring careful sequencing and dependency management.

**Key Dependencies:**
- ER-0009 and ER-0010 share AI provider infrastructure
- ER-0010 can generate Calendar Systems for ER-0008
- ER-0008 is independent but enhanced by ER-0010

**Estimated Complexity:**
- **ER-0008:** High (new data models, major UI changes, backward compatibility)
- **ER-0009:** Medium-High (AI integration, attribution, metadata)
- **ER-0010:** High (NER, entity extraction, complex suggestion system)

**Testing Approach:** **Hybrid (Incremental + Comprehensive)**
- **Incremental Testing:** Continuous testing at the end of each phase (Phases 0-9)
- **Comprehensive Testing:** Full integration testing in Phase 10
- **Test Coverage Targets:** >80% for logic, >90% for models
- **See:** [Comprehensive Test Plan](./TEST-PLAN-ER-0008-0009-0010.md) and [Test Plan Analysis](./TEST-PLAN-ANALYSIS-AND-RECOMMENDATIONS.md)

---

## Part 1: Dependency Analysis

### Shared Infrastructure

**AI Provider System (ER-0009 & ER-0010):**
- Both require Apple Intelligence integration
- Both need ChatGPT/OpenAI API support
- Share settings panel for API keys
- Share provider protocol and architecture

**Recommendation:** Implement AI provider infrastructure first, use for both ER-0009 and ER-0010.

### Direct Dependencies

**ER-0010 → ER-0008:**
- ER-0010 can extract and generate Calendar Systems
- Calendar extraction requires Calendar System model from ER-0008
- Can implement ER-0008 calendar model first, then ER-0010 extraction

**ER-0009 ↔ ER-0010:**
- Both can work together (analyze → create cards → generate images)
- Independent functionality, but complementary workflow
- No blocking dependencies

### Independence Analysis

**ER-0008 (Timeline System):**
- Fully independent of AI features
- Can be implemented in parallel
- Calendar model needed for ER-0010 integration

**ER-0009 (Image Generation):**
- Independent of ER-0008
- Shares infrastructure with ER-0010
- Can proceed after AI provider foundation

**ER-0010 (Content Analysis):**
- Independent of ER-0008 (except calendar extraction)
- Shares infrastructure with ER-0009
- Can proceed after AI provider foundation

---

## Part 2: Implementation and Testing Strategy

### Strategy: Phased Parallel Development with Continuous Testing

**Development Approach:**
1. **Foundation Phase:** Build shared infrastructure (AI providers, settings)
2. **Parallel Development:** Work on ER-0008 and ER-0009 simultaneously
3. **Advanced Features:** Add ER-0010, integrate calendar extraction with ER-0008
4. **Comprehensive Integration & Testing Phase (Phase 10):** Full integration testing, beta testing, production readiness

**Testing Approach: Hybrid (Incremental + Comprehensive)**

**Incremental Testing (Phases 0-9):**
- Test at the end of each development phase
- Unit tests written alongside code
- Integration tests for phase deliverables
- CI/CD runs tests on every commit
- **Benefits:** Early bug detection, fast feedback, reduced risk

**Comprehensive Testing (Phase 10):**
- Full integration testing after all features complete
- Cross-ER integration validation
- End-to-end workflow testing
- Cross-platform testing (macOS, iOS, iPadOS, visionOS)
- Performance and security audits
- Beta testing with real users
- **Benefits:** System-level validation, regression detection, production confidence

**Test Targets:**
- **CumberlandTests** (Primary) - All unit and integration tests
- **CumberlandUITests** - macOS UI tests
- **Cumberland IOSUITests** - iOS/iPadOS UI tests
- **CumberlandVisionOSUITests** (New) - visionOS UI tests
- **TestApp** - Manual exploratory testing

**Rationale:**
- Maximizes development velocity through parallel work
- Reduces risk via continuous validation (incremental testing)
- Ensures system quality via comprehensive integration testing
- Allows early user feedback on each feature
- Shared infrastructure reduces duplication

---

## Part 3: Detailed Phase Breakdown

### Phase 0: Planning & Architecture (2-3 days)

**Goals:**
- Finalize architecture decisions
- Resolve open design questions
- Set up project structure and test infrastructure

**Tasks:**
1. **AI Provider Architecture**
   - Define `AIProviderProtocol`
   - Design settings data model (`AISettings`)
   - Plan keychain integration for API keys

2. **Data Model Planning**
   - Calendar System model design (ER-0008)
   - Scene temporal positioning schema (ER-0008)
   - Image metadata schema (ER-0009)
   - Suggestion tracking schema (ER-0010)

3. **Decision Points (Open Design Questions)**
   - **ER-0008:** Calendar representation (JSON vs. dedicated model?)
   - **ER-0008:** Epoch storage (property vs. separate model?)
   - **ER-0009:** Attribution display prominence (badge vs. overlay?)
   - **ER-0010:** Analysis triggers (manual only or auto-analyze option?)

4. **Test Infrastructure Setup**
   - **Create visionOS test targets:**
     - [ ] Create `CumberlandVisionOSTests` (unit tests)
     - [ ] Create `CumberlandVisionOSUITests` (UI tests)
   - **Organize CumberlandTests:**
     - [ ] Create folders: `ER-0008-Timeline/`, `ER-0009-ImageGeneration/`, `ER-0010-ContentAnalysis/`, `Integration/`
     - [ ] Move existing tests to `Existing/` folder
     - [ ] Create test file templates for each ER
   - **Set up CI/CD:**
     - [ ] Configure GitHub Actions or Xcode Cloud
     - [ ] Enable automatic test runs on commits
     - [ ] Set up nightly comprehensive test runs
   - **Create test data fixtures:**
     - [ ] Sample Gregorian calendar
     - [ ] Sample fantasy calendar
     - [ ] Sample scenes with rich descriptions
     - [ ] Sample cards for analysis testing

**Deliverables:**
- Architecture decision record (ADR) document
- Data model diagrams
- File structure plan
- Test infrastructure configured
- Test target organization complete
- Test data fixtures created

**Risk:** Medium - Decisions made here affect entire implementation

**Testing Activities:**
- [ ] Verify test targets build successfully
- [ ] Run existing tests to establish baseline
- [ ] Validate CI/CD pipeline configuration

---

### Phase 1: Shared AI Infrastructure (1-2 weeks)

**Priority:** HIGH - Blocks ER-0009 and ER-0010

**Goals:**
- Implement AI provider infrastructure
- Apple Intelligence integration (default provider)
- Settings panel for AI configuration

**Tasks:**

#### 1.1: AI Provider Protocol & Architecture
- [ ] Create `AIProviderProtocol.swift`
  - Image generation method signatures
  - Text analysis method signatures (for ER-0010)
  - Error handling
  - Provider metadata (name, capabilities, licensing)
- [ ] Create `AIProviderError` enum
- [ ] Create provider base classes/utilities

#### 1.2: Apple Intelligence Integration
- [ ] Create `AppleIntelligenceProvider.swift`
- [ ] Import ImagePlayground framework (iOS 18.2+, macOS 15.2+)
- [ ] Implement image generation
- [ ] Implement text analysis (for ER-0010)
- [ ] Handle availability checks (OS version)
- [ ] Error handling and fallbacks

#### 1.3: Settings Infrastructure
- [ ] Create `AISettings.swift` (data model)
- [ ] Create `AISettingsView.swift` (UI)
- [ ] Provider selection (Apple Intelligence, ChatGPT, future)
- [ ] API key management (keychain storage)
- [ ] Provider availability status display
- [ ] Settings persistence (AppStorage or SwiftData)

#### 1.4: Testing
- [ ] Unit tests for provider protocol
- [ ] Integration tests for Apple Intelligence
- [ ] Settings persistence tests
- [ ] Keychain security tests

**Deliverables:**
- Working Apple Intelligence integration
- Settings panel for AI configuration
- Provider architecture ready for additional providers

**Success Criteria:**
- Can generate image with Apple Intelligence
- Settings persist correctly
- Clean provider abstraction for future expansion

**Risk:** Medium - Apple Intelligence API availability, OS version requirements

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):**
  - [ ] Test `AIProviderProtocol` conformance
  - [ ] Test `AppleIntelligenceProvider` image generation
  - [ ] Test provider error handling (unavailable, API errors)
  - [ ] Test `AISettings` persistence (AppStorage)
  - [ ] Test keychain storage/retrieval for API keys
- [ ] **Integration Tests:**
  - [ ] Test Apple Intelligence availability detection
  - [ ] Test provider switching in settings
  - [ ] Test settings sync across devices (CloudKit)
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test settings panel navigation
  - [ ] Test provider selection UI
  - [ ] Test API key input and validation
- [ ] **Performance Tests:**
  - [ ] Measure provider initialization time (< 100ms)
- [ ] **CI/CD Validation:**
  - [ ] Ensure all tests pass in CI pipeline
  - [ ] Establish baseline coverage metrics

---

### Phase 2A: ER-0009 Image Generation MVP (2-3 weeks)

**Priority:** HIGH - High user value, enables visual worldbuilding

**Goals:**
- Manual image generation with user-provided prompts
- Basic attribution and metadata
- Card detail view integration

**Tasks:**

#### 2A.1: Core Image Generation
- [ ] Create `AIImageGenerator.swift`
  - Use provider infrastructure from Phase 1
  - Prompt → Image pipeline
  - Progress tracking
  - Error handling
- [ ] Image format conversion and storage
- [ ] Integration with Card `originalImageData`

#### 2A.2: Card Model Updates
- [ ] Schema migration (AppSchemaV6)
- [ ] Add properties to Card:
  - `imageGeneratedByAI: Bool?`
  - `imageAIProvider: String?`
  - `imageAIPrompt: String?`
  - `imageAIGeneratedAt: Date?`
- [ ] Migration plan for existing cards

#### 2A.3: UI Integration
- [ ] Add "Generate Image" button to `CardEditorView.swift`
  - Button placement and styling
  - Enabled/disabled states
  - Tooltip
- [ ] Create `AIImageGenerationView.swift` (sheet/modal)
  - Prompt input field
  - Provider selection (if multiple available)
  - "Generate" button
  - Progress indicator
  - Image preview
  - Accept/Retry/Discard actions
- [ ] Attribution badge display
  - "AI Generated" badge on card images
  - Tappable for details

#### 2A.4: Basic Attribution
- [ ] Store provider and date in Card metadata
- [ ] Display simple "AI Generated" badge
- [ ] Basic image info panel (provider, date, prompt)

#### 2A.5: Testing
- [ ] Unit tests for image generation pipeline
- [ ] UI tests for generation workflow
- [ ] Test prompt → image → save → display flow
- [ ] Test error scenarios (network, API failure)

**Deliverables:**
- Working manual image generation
- Images saved to cards with attribution
- Clean UI for generation workflow

**Success Criteria:**
- User can generate image with custom prompt
- Image appears on card with attribution
- Regeneration works correctly

**Risk:** Low-Medium - Relies on Phase 1 infrastructure

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):**
  - [ ] Test `AIImageGenerator` prompt-to-image pipeline
  - [ ] Test image format conversion and storage
  - [ ] Test Card model schema migration (V6)
  - [ ] Test AI metadata properties (imageGeneratedByAI, etc.)
  - [ ] Test error scenarios (network failure, API errors)
- [ ] **Integration Tests:**
  - [ ] Test full generation workflow (prompt → generate → save → display)
  - [ ] Test image storage in `originalImageData`
  - [ ] Test thumbnail generation for AI images
  - [ ] Test attribution data persistence
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test "Generate Image" button visibility and states
  - [ ] Test `AIImageGenerationView` sheet presentation
  - [ ] Test prompt input and validation
  - [ ] Test progress indicator during generation
  - [ ] Test accept/retry/discard actions
  - [ ] Test attribution badge display
- [ ] **Manual Testing:**
  - [ ] Visual quality of generated images
  - [ ] Image preview clarity
  - [ ] Attribution badge appearance (light/dark mode)
- [ ] **Migration Tests:**
  - [ ] Test V5 → V6 schema migration
  - [ ] Verify existing cards unaffected

---

### Phase 2B: ER-0008 Timeline Data Model (2-3 weeks)

**Priority:** HIGH - Foundation for timeline enhancements

**Goals:**
- Calendar System model
- Scene temporal positioning
- Backward compatibility with ordinal timelines

**Tasks:**

#### 2B.1: Calendar System Model
- [ ] Design decision: JSON in Rules card vs. dedicated model
  - **Recommendation:** Dedicated SwiftData model for queryability
- [ ] Create `CalendarSystem` model (or extend Rules card)
  - Time division hierarchy (seconds → minutes → hours → days → weeks → months → years → eras)
  - Division names and lengths
  - Custom vs. fixed divisions
  - Validation rules
- [ ] Create Gregorian calendar template
  - Pre-populated calendar for immediate use
  - Standard time divisions
  - Seed on first launch or on-demand

#### 2B.2: Epoch Model
- [ ] Design decision: Property on Timeline or separate model?
  - **Recommendation:** Property on Timeline card (simpler)
- [ ] Add to Card model (for Timeline cards):
  - `epochDate: Date?` (or custom temporal type)
  - `epochDescription: String?` (human-readable)
- [ ] Epoch formatting/parsing for custom calendars

#### 2B.3: Scene Temporal Positioning
- [ ] Add to CardEdge (Scene→Timeline relationship):
  - `temporalPosition: Date?` (new, optional)
  - `duration: TimeInterval?` (new, optional)
  - Keep existing `sortIndex` for backward compatibility
- [ ] Migration: Existing scenes keep ordinal ordering
- [ ] Logic to detect timeline mode (ordinal vs. temporal)

#### 2B.4: Relationship Types
- [ ] Create new RelationType: "uses/used-by" (Timeline → Calendar)
- [ ] Register in default relationship types
- [ ] Update relationship UI to support new type

#### 2B.5: Testing
- [ ] Unit tests for calendar model
- [ ] Unit tests for temporal positioning
- [ ] Migration tests (ordinal → temporal, backward compat)
- [ ] Gregorian calendar validation

**Deliverables:**
- Calendar System model with Gregorian template
- Scene temporal positioning support
- Backward-compatible with existing timelines

**Success Criteria:**
- Can create custom calendar system
- Can associate timeline with calendar
- Existing ordinal timelines still work

**Risk:** Medium - Data model complexity, migration safety

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):**
  - [ ] Test `CalendarSystem` model creation and validation
  - [ ] Test Gregorian calendar template structure
  - [ ] Test time division hierarchy logic
  - [ ] Test epoch model (property on Timeline)
  - [ ] Test scene temporal positioning (CardEdge properties)
  - [ ] Test ordinal vs. temporal mode detection
  - [ ] Test RelationType "uses/used-by" creation
- [ ] **Integration Tests:**
  - [ ] Test Timeline → Calendar relationship
  - [ ] Test Scene → Timeline temporal positioning
  - [ ] Test backward compatibility (existing ordinal timelines)
  - [ ] Test schema migration (existing scenes keep sortIndex)
- [ ] **Data Integrity Tests:**
  - [ ] Test calendar validation rules
  - [ ] Test epoch date formatting/parsing
  - [ ] Test temporal position boundaries
- [ ] **Migration Tests:**
  - [ ] Test migration preserves existing timeline data
  - [ ] Test ordinal timelines still functional after migration
  - [ ] Test rollback scenarios
- [ ] **Performance Tests:**
  - [ ] Measure calendar query performance
  - [ ] Test with complex calendar systems (100+ divisions)

---

### Phase 2C: Parallel Work Summary

**Timeline:** Weeks 3-6 (after Phase 1 complete)

**Parallel Tracks:**
- **Track A (ER-0009):** Image generation MVP
- **Track B (ER-0008):** Timeline data model

**Benefits of Parallel Development:**
- Faster overall progress
- Independent features reduce blocking
- Early user feedback on both features
- Spreads risk across multiple workstreams

**Coordination Points:**
- Both touch Card model (different properties)
- Both need schema migrations (coordinate version bumps)
- Weekly sync to avoid conflicts

---

### Phase 3A: ER-0009 Smart Prompt Extraction (1-2 weeks)

**Priority:** MEDIUM - Enhances image generation UX

**Goals:**
- Auto-extract prompts from card descriptions
- Description quality detection
- Smart "Generate Image" button enable/disable

**Tasks:**

#### 3A.1: Prompt Extraction
- [ ] Create `PromptExtractor.swift`
- [ ] Analyze card type for context
  - Character → "Portrait of..."
  - Location → "Landscape of..."
  - Building → "Architecture of..."
  - Vehicle → "Technical illustration of..."
  - Etc.
- [ ] Extract key visual phrases from `detailedText`
- [ ] Filter out non-visual content (dialogue, plot)
- [ ] Format prompts for AI providers

#### 3A.2: Description Analysis
- [ ] Create `DescriptionAnalyzer.swift`
- [ ] Word count analysis
- [ ] Visual keyword detection (colors, sizes, moods)
- [ ] Quality scoring (0-100%)
- [ ] Minimum threshold (default: 50 words)

#### 3A.3: UI Enhancement
- [ ] "Generate Image" button smart enable/disable
  - Enabled when: no image OR sufficient description
  - Disabled when: insufficient description
  - Tooltip explains why disabled
- [ ] Show extracted prompt before generation (optional)
- [ ] Allow manual editing of extracted prompt

#### 3A.4: Testing
- [ ] Unit tests for prompt extraction (various card types)
- [ ] Description analysis accuracy tests
- [ ] UI state tests (button enable/disable)

**Deliverables:**
- Smart prompt extraction from descriptions
- Auto-enable "Generate Image" button
- Improved UX for image generation

**Success Criteria:**
- Extracted prompts produce relevant images
- Button disables appropriately for insufficient descriptions
- User can override extracted prompts

**Risk:** Low - Enhances existing Phase 2A work

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):**
  - [ ] Test `PromptExtractor` for various card types (Character, Location, Building, etc.)
  - [ ] Test visual keyword extraction from `detailedText`
  - [ ] Test non-visual content filtering (dialogue, plot)
  - [ ] Test `DescriptionAnalyzer` word count and quality scoring
  - [ ] Test threshold detection (50-word minimum)
- [ ] **Integration Tests:**
  - [ ] Test prompt extraction → image generation flow
  - [ ] Test button enable/disable logic
  - [ ] Test manual prompt override
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test "Generate Image" button states (enabled/disabled/tooltip)
  - [ ] Test extracted prompt preview display
  - [ ] Test manual editing of extracted prompts
- [ ] **Quality Tests:**
  - [ ] Manual review: Do extracted prompts produce relevant images?
  - [ ] Test with 10 sample cards of each type
  - [ ] Measure extraction accuracy (>70% relevant)

---

### Phase 3B: ER-0008 Timeline UI - Temporal Mode (2-3 weeks)

**Priority:** HIGH - Delivers core timeline visualization

**Goals:**
- Gantt-style timeline chart for temporal mode
- Adaptive X-axis (ordinal vs. temporal)
- Backward compatibility with ordinal mode

**Tasks:**

#### 3B.1: TimelineChartView Enhancement
- [ ] Detect timeline mode:
  - Has Calendar associated? → Temporal mode
  - No Calendar? → Ordinal mode (existing behavior)
- [ ] Implement temporal X-axis
  - Date/time domain instead of ordinal
  - Calendar-aware formatting
  - Zoom levels (hour/day/week/month/year/decade)
- [ ] Scene positioning logic
  - Use `temporalPosition` for temporal mode
  - Use `sortIndex` for ordinal mode
  - Handle scenes without temporal position (fallback to ordinal)

#### 3B.2: Gantt-Style Visualization
- [ ] X-axis: Calendar timeline
- [ ] Y-axis: Scenes (as bars)
- [ ] Scene duration visualization
  - Default: 1-pixel minimum width
  - If duration specified: scale to duration
- [ ] Character resources display
  - Show characters as "resources" on scenes
  - Similar to Gantt resource allocation

#### 3B.3: Zoom & Scroll Controls
- [ ] Smart zoom levels
  - Hour → Day → Week → Month → Year → Decade → Century
  - Logarithmic or adaptive zoom
- [ ] Scroll position awareness
  - Minimap or breadcrumb (optional)
  - "Jump to date" feature
- [ ] Fit-to-view controls

#### 3B.4: Calendar Integration UI
- [ ] Timeline detail view: Select Calendar
- [ ] Timeline detail view: Set Epoch
- [ ] Calendar-aware date picker for scenes
- [ ] Display mode toggle (ordinal vs. temporal)

#### 3B.5: Testing
- [ ] Unit tests for temporal positioning logic
- [ ] UI tests for Gantt-style chart
- [ ] Backward compatibility tests (ordinal mode)
- [ ] Zoom/scroll behavior tests

**Deliverables:**
- Gantt-style timeline chart for temporal mode
- Calendar integration UI
- Fully backward-compatible with ordinal timelines

**Success Criteria:**
- Temporal timeline displays correctly with calendar
- Ordinal timelines continue working unchanged
- Zoom and scroll feel intuitive
- Scenes position correctly on calendar dates

**Risk:** Medium-High - Complex UI changes, backward compatibility critical

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):**
  - [ ] Test timeline mode detection (ordinal vs. temporal)
  - [ ] Test temporal X-axis domain calculation
  - [ ] Test calendar-aware date formatting
  - [ ] Test zoom level calculations (hour/day/week/month/year/decade)
  - [ ] Test scene positioning logic (temporalPosition vs. sortIndex)
  - [ ] Test scene duration visualization
- [ ] **Integration Tests:**
  - [ ] Test `TimelineChartView` with temporal timeline
  - [ ] Test `TimelineChartView` with ordinal timeline (backward compatibility)
  - [ ] Test calendar integration (Timeline → Calendar relationship)
  - [ ] Test epoch-based positioning
  - [ ] Test scene without temporal position (fallback to ordinal)
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test Gantt-style chart rendering
  - [ ] Test zoom controls (in/out, fit-to-view)
  - [ ] Test scroll behavior
  - [ ] Test calendar-aware date picker
  - [ ] Test display mode toggle (ordinal ↔ temporal)
  - [ ] Test "Jump to date" feature
- [ ] **Performance Tests:**
  - [ ] Test timeline rendering with 100 scenes (< 100ms target)
  - [ ] Test zoom/scroll responsiveness
  - [ ] Test with large time spans (1000+ years)
- [ ] **Backward Compatibility Tests:**
  - [ ] Test existing ordinal timelines unchanged
  - [ ] Test mixed timeline project (some ordinal, some temporal)
  - [ ] Verify no regressions in ordinal mode
- [ ] **Visual/Manual Testing:**
  - [ ] Gantt chart readability
  - [ ] Character resource display clarity
  - [ ] Minimap/breadcrumb usability

---

### Phase 4A: ER-0009 Enhanced Attribution & Metadata (1-2 weeks)

**Priority:** MEDIUM - Legal compliance, professional polish

**Goals:**
- EXIF/IPTC metadata embedding
- Detailed attribution UI
- Export persistence

**Tasks:**

#### 4A.1: Metadata Management
- [ ] Create `ImageMetadataManager.swift`
- [ ] EXIF/IPTC writing (using CoreGraphics/ImageIO)
  - Creator: "Cumberland App + [Provider]"
  - Copyright: User-configurable
  - Description: Original prompt
  - Keywords: "AI-generated", card type, name
  - Software: "Cumberland [version]"
  - Source: "[Provider] Image Generation"
  - DateCreated: ISO timestamp
  - UserComment: JSON with full details
- [ ] EXIF/IPTC reading (for display)
- [ ] Metadata validation

#### 4A.2: Attribution UI Components
- [ ] Create `AttributionView.swift`
  - Badge display ("AI Generated")
  - Provider icon
  - Tappable for details
- [ ] Create `ImageInfoPanel.swift`
  - Provider name
  - Generation date/time
  - Prompt used
  - Model version (if available)
  - Licensing info
  - Copyright text

#### 4A.3: Export Persistence
- [ ] Ensure metadata embedded before export
- [ ] Test export to Files, Photos, Share Sheet
- [ ] Verify metadata survives export
- [ ] Handle formats without metadata support (warn user)

#### 4A.4: Attribution Settings
- [ ] "Always show AI attribution" toggle
- [ ] Copyright text template editor
- [ ] Attribution placement preference
- [ ] Export behavior preference

#### 4A.5: Testing
- [ ] Metadata embedding tests
- [ ] Export/import round-trip tests
- [ ] Attribution display tests
- [ ] Settings persistence tests

**Deliverables:**
- Full EXIF/IPTC metadata in generated images
- Detailed attribution UI
- Persistent attribution through export

**Success Criteria:**
- Metadata readable by standard image viewers
- Attribution persists through export/share
- User can customize attribution settings

**Risk:** Low-Medium - Platform metadata API quirks

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):**
  - [ ] Test `ImageMetadataManager` EXIF/IPTC writing
  - [ ] Test EXIF/IPTC reading and parsing
  - [ ] Test metadata validation
  - [ ] Test all metadata fields (Creator, Copyright, Description, Keywords, etc.)
  - [ ] Test metadata with special characters and Unicode
- [ ] **Integration Tests:**
  - [ ] Test metadata embedding before export
  - [ ] Test export to Files (metadata preserved)
  - [ ] Test export to Photos (metadata preserved)
  - [ ] Test share sheet export (metadata preserved)
  - [ ] Test round-trip (export → import → verify metadata)
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test `AttributionView` badge display
  - [ ] Test badge tap → `ImageInfoPanel` presentation
  - [ ] Test attribution settings panel
  - [ ] Test copyright text editor
  - [ ] Test attribution placement preferences
- [ ] **Cross-Platform Tests:**
  - [ ] Test metadata on macOS, iOS, iPadOS
  - [ ] Verify metadata readable by macOS Preview
  - [ ] Verify metadata readable by iOS Photos app
- [ ] **Format Compatibility Tests:**
  - [ ] Test JPEG export (full metadata support)
  - [ ] Test PNG export (limited metadata support)
  - [ ] Test HEIC export (full metadata support)
  - [ ] Test formats without metadata (warn user)
- [ ] **Settings Persistence Tests:**
  - [ ] Test "Always show AI attribution" toggle
  - [ ] Test copyright template persistence
  - [ ] Test attribution placement preference

---

### Phase 4B: ER-0008 Calendar Editor & Epoch UI (1-2 weeks)

**Priority:** MEDIUM - Enables custom calendar creation

**Goals:**
- Calendar system editor
- Epoch configuration UI
- Pre-populated Gregorian calendar

**Tasks:**

#### 4B.1: Calendar Editor View
- [ ] Create `CalendarEditorView.swift`
- [ ] Time division configuration
  - Add/remove divisions
  - Set division names
  - Set division lengths (fixed or variable)
  - Hierarchy management (days → weeks → months → years)
- [ ] Validation
  - Ensure logical hierarchy
  - Prevent circular dependencies
  - Warn about missing divisions
- [ ] Preview/test calendar structure

#### 4B.2: Epoch Editor
- [ ] Create `EpochEditorView.swift` or integrate into Timeline detail
- [ ] Calendar-aware date picker
  - Display in calendar's format
  - Handle custom month/day names
  - Support eras/ages
- [ ] Epoch description editor (human-readable text)
- [ ] Validation (ensure epoch within calendar bounds)

#### 4B.3: Pre-Populated Gregorian Calendar
- [ ] Create Gregorian calendar on first launch (or on-demand)
- [ ] Standard time divisions:
  - 60 seconds/minute
  - 60 minutes/hour
  - 24 hours/day
  - 7 days/week
  - 12 months/year (with standard names)
  - Variable month lengths (28-31 days)
- [ ] Gregorian calendar as default selection

#### 4B.4: Integration with Timeline
- [ ] Timeline detail view: "Select Calendar" picker
- [ ] Timeline detail view: "Set Epoch" button
- [ ] Display selected calendar name
- [ ] Display epoch date (formatted in calendar)

#### 4B.5: Testing
- [ ] Calendar editor validation tests
- [ ] Epoch picker tests
- [ ] Gregorian calendar structure tests
- [ ] Integration tests (Timeline ↔ Calendar)

**Deliverables:**
- Full calendar editor for custom time systems
- Epoch configuration UI
- Pre-populated Gregorian calendar

**Success Criteria:**
- User can create fantasy calendar with custom months/years
- Gregorian calendar available by default
- Epoch sets timeline starting point correctly

**Risk:** Medium - Complex UI, calendar logic validation

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):**
  - [ ] Test `CalendarEditorView` validation logic
  - [ ] Test time division add/remove/edit operations
  - [ ] Test hierarchy management (days → weeks → months → years → eras)
  - [ ] Test circular dependency detection
  - [ ] Test epoch date formatting in custom calendars
  - [ ] Test epoch description persistence
- [ ] **Integration Tests:**
  - [ ] Test Gregorian calendar creation on first launch
  - [ ] Test calendar-aware date picker with custom calendars
  - [ ] Test Timeline → Calendar selection
  - [ ] Test epoch configuration workflow
  - [ ] Test calendar as default selection
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test `CalendarEditorView` form interactions
  - [ ] Test division add/remove buttons
  - [ ] Test validation error messages
  - [ ] Test preview/test calendar functionality
  - [ ] Test `EpochEditorView` (or integrated UI)
  - [ ] Test timeline detail view calendar picker
  - [ ] Test timeline detail view epoch button
- [ ] **Validation Tests:**
  - [ ] Test invalid calendars rejected (circular dependencies)
  - [ ] Test warning for missing divisions
  - [ ] Test logical hierarchy enforcement
- [ ] **Data Tests:**
  - [ ] Test Gregorian calendar structure accuracy (12 months, correct day counts)
  - [ ] Test custom calendar storage and retrieval
  - [ ] Test era/age support in calendars

---

### Phase 5: ER-0010 Content Analysis MVP (2-3 weeks)

**Priority:** HIGH - High user value, encourages detailed writing

**Goals:**
- Basic entity extraction (Locations, Artifacts, Characters)
- "Analyze" button in card editors
- Suggestion review UI
- Card creation from accepted suggestions

**Tasks:**

#### 5.1: Entity Extraction Engine
- [ ] Create `EntityExtractor.swift`
- [ ] Use AI provider (reuse from Phase 1)
- [ ] NER (Named Entity Recognition)
  - Proper noun detection
  - Entity type inference (Location vs. Artifact vs. Character)
  - Confidence scoring (0-100%)
  - Context extraction (surrounding text)
- [ ] Structured output parsing
- [ ] Error handling

#### 5.2: Suggestion Engine
- [ ] Create `SuggestionEngine.swift`
- [ ] Generate card creation suggestions
  - Entity name
  - Card type
  - Initial description (from context)
  - Confidence score
- [ ] Deduplication (match against existing cards)
  - Fuzzy matching
  - Case-insensitive comparison
  - Suggest linking instead of creating duplicate
- [ ] Suggestion ranking (by confidence)

#### 5.3: UI Integration
- [ ] Add "Analyze" button to card editors
  - Placement: Near description editor
  - Button states: Available, Analyzing, Disabled
  - Tooltip: "Analyze description to find mentioned entities"
  - Minimum text requirement (e.g., 25 words)
- [ ] Create `SuggestionReviewView.swift` (sheet/modal)
  - Grouped by type: "New Cards", "Relationships"
  - Each suggestion shows:
    - Entity name
    - Card type
    - Confidence score (%)
    - Context snippet
    - Preview
  - Actions: Accept, Reject, Never Suggest, Edit
  - Batch actions: Accept All High Confidence, Accept All, Reject All

#### 5.4: Card Creation from Suggestions
- [ ] Create cards from accepted suggestions
- [ ] Pre-populate name, type, description
- [ ] Add relationship to source card ("mentioned in...")
- [ ] Batch creation support

#### 5.5: Settings
- [ ] "Enable Assistant" master toggle
- [ ] Analysis scope (Conservative/Moderate/Aggressive)
- [ ] Confidence threshold slider
- [ ] Entity type toggles

#### 5.6: Testing
- [ ] Unit tests for entity extraction
- [ ] Deduplication tests
- [ ] Suggestion generation tests
- [ ] UI tests for analyze workflow
- [ ] Card creation tests

**Deliverables:**
- Working content analysis with entity extraction
- "Analyze" button in card editors
- Suggestion review and card creation workflow

**Success Criteria:**
- Can extract entities from scene descriptions
- Suggestions are accurate (low false positives)
- Created cards are properly linked
- Deduplication prevents duplicates

**Risk:** Medium-High - NER accuracy depends on AI provider quality

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0010-ContentAnalysis/):**
  - [ ] Test `EntityExtractor` NER functionality
  - [ ] Test entity type inference (Location vs. Artifact vs. Character)
  - [ ] Test confidence scoring accuracy
  - [ ] Test context extraction (surrounding text)
  - [ ] Test structured output parsing
  - [ ] Test `SuggestionEngine` card suggestion generation
  - [ ] Test deduplication (fuzzy matching, case-insensitive)
  - [ ] Test suggestion ranking by confidence
- [ ] **Integration Tests:**
  - [ ] Test full analysis workflow (analyze → suggestions → create cards)
  - [ ] Test deduplication against existing cards
  - [ ] Test "mentioned in..." relationship creation
  - [ ] Test batch card creation
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test "Analyze" button placement and states
  - [ ] Test minimum text requirement (25 words)
  - [ ] Test `SuggestionReviewView` sheet presentation
  - [ ] Test suggestion grouping (by type)
  - [ ] Test accept/reject/never suggest actions
  - [ ] Test batch actions (Accept All High Confidence, etc.)
  - [ ] Test preview functionality
- [ ] **Quality Tests (Manual):**
  - [ ] Test with 20 sample scene descriptions
  - [ ] Measure precision: % of suggestions that are correct
  - [ ] Target: >80% precision at 70% confidence threshold
  - [ ] Measure recall: % of entities found
  - [ ] Test false positive rate (< 20% goal)
- [ ] **Settings Tests:**
  - [ ] Test "Enable Assistant" master toggle
  - [ ] Test analysis scope settings (Conservative/Moderate/Aggressive)
  - [ ] Test confidence threshold slider
  - [ ] Test entity type toggles
- [ ] **Error Handling Tests:**
  - [ ] Test with AI provider unavailable
  - [ ] Test with network failures
  - [ ] Test with malformed API responses

---

### Phase 6: ER-0010 Relationship Inference (1-2 weeks)

**Priority:** MEDIUM - Adds intelligent relationship suggestions

**Goals:**
- Infer relationships from sentence structure
- Relationship suggestions in review UI
- Automated relationship creation

**Tasks:**

#### 6.1: Relationship Inference
- [ ] Create `RelationshipInference.swift`
- [ ] Analyze sentence structure
  - "X drew the Y" → owns/uses
  - "entered the Z" → location/building
  - "born in W" → birthplace
  - "trained at V" → education/training
  - "member of U" → organization
- [ ] Map to existing RelationTypes
- [ ] Confidence scoring for relationships

#### 6.2: Suggestion UI Enhancement
- [ ] Add "Relationships to Add" section to `SuggestionReviewView`
- [ ] Display: Source → Relationship Type → Target
- [ ] Preview relationship before creation
- [ ] Allow manual relationship type override

#### 6.3: Automated Relationship Creation
- [ ] Create CardEdge from accepted suggestions
- [ ] Use appropriate RelationType
- [ ] Handle bidirectional relationships
- [ ] Validate relationship (source/target types match)

#### 6.4: Testing
- [ ] Relationship inference tests (various sentence patterns)
- [ ] Relationship creation tests
- [ ] Bidirectional relationship tests
- [ ] Type validation tests

**Deliverables:**
- Intelligent relationship suggestions
- Automated relationship creation
- Enhanced suggestion review UI

**Success Criteria:**
- Relationships inferred correctly from context
- Created relationships are valid
- User can override suggested relationship types

**Risk:** Medium - Relationship inference accuracy

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0010-ContentAnalysis/):**
  - [ ] Test `RelationshipInference` sentence parsing
  - [ ] Test relationship type mapping ("X drew Y" → owns/uses)
  - [ ] Test confidence scoring for relationships
  - [ ] Test mapping to existing `RelationType` values
  - [ ] Test bidirectional relationship detection
- [ ] **Integration Tests:**
  - [ ] Test relationship suggestion → `CardEdge` creation
  - [ ] Test bidirectional relationship creation
  - [ ] Test relationship type validation (source/target compatibility)
  - [ ] Test "Relationships to Add" section in suggestion UI
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test relationship suggestions display in `SuggestionReviewView`
  - [ ] Test relationship preview (Source → Type → Target)
  - [ ] Test manual relationship type override
  - [ ] Test accept/reject for individual relationships
- [ ] **Quality Tests (Manual):**
  - [ ] Test with 15 sample sentences with relationships
  - [ ] Measure relationship inference accuracy (>75% target)
  - [ ] Test various relationship patterns (owns, location, birthplace, etc.)
- [ ] **Validation Tests:**
  - [ ] Test invalid relationship rejection (incompatible types)
  - [ ] Test duplicate relationship prevention
  - [ ] Test relationship consistency (if A→B exists, handle B→A appropriately)

---

### Phase 7: ER-0010 + ER-0008 Integration - Calendar Extraction (1-2 weeks)

**Priority:** MEDIUM - Powerful integration of two features

**Goals:**
- Extract calendar systems from scene/timeline descriptions
- Generate calendar structure suggestions
- Create Calendar cards from suggestions

**Tasks:**

#### 7.1: Calendar System Extraction
- [ ] Create `CalendarSystemExtractor.swift`
- [ ] Temporal vocabulary detection
  - Month names ("Month of Harvest")
  - Day names ("First-Day")
  - Year types ("Long Year")
  - Era names ("Age of Ice", "Time of Fire")
  - Events/Festivals ("Festival of Stars")
- [ ] Hierarchy detection (days → months → years → eras)
- [ ] Confidence scoring

#### 7.2: Calendar Generation
- [ ] Generate calendar structure from extracted data
- [ ] Populate time divisions
- [ ] Suggest division lengths (if not specified)
- [ ] Create CalendarSystem model instance

#### 7.3: Suggestion UI Integration
- [ ] Add "Calendar System Detected" section to `SuggestionReviewView`
- [ ] Display detected calendar structure
  - Month names
  - Era names
  - Events/festivals
  - Hierarchy
- [ ] Preview calendar before creation
- [ ] Allow editing before acceptance

#### 7.4: Calendar Card Creation
- [ ] Create Rules card (or CalendarSystem model)
- [ ] Populate with extracted data
- [ ] Link to source Timeline/Scene ("extracted from...")
- [ ] Suggest as Timeline's calendar

#### 7.5: Testing
- [ ] Temporal vocabulary detection tests
- [ ] Calendar structure generation tests
- [ ] Integration tests (analysis → calendar creation → timeline association)

**Deliverables:**
- Calendar system extraction from text
- Calendar card generation from suggestions
- Integration with ER-0008 timeline system

**Success Criteria:**
- Can extract calendar from fantasy descriptions
- Generated calendar is valid and usable
- Calendar automatically associated with timeline

**Risk:** Medium-High - Complex pattern detection, calendar structure validation

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/Integration/):**
  - [ ] Test `CalendarSystemExtractor` temporal vocabulary detection
  - [ ] Test month name extraction ("Month of Harvest")
  - [ ] Test day name extraction ("First-Day")
  - [ ] Test era name extraction ("Age of Ice")
  - [ ] Test event/festival extraction
  - [ ] Test hierarchy detection (days → months → years → eras)
  - [ ] Test calendar structure generation from extracted data
  - [ ] Test division length inference
- [ ] **Integration Tests:**
  - [ ] Test full workflow: Analyze → extract calendar → create Calendar card → associate with Timeline
  - [ ] Test calendar card creation (Rules or CalendarSystem model)
  - [ ] Test "extracted from..." relationship creation
  - [ ] Test timeline auto-association with extracted calendar
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test "Calendar System Detected" section in `SuggestionReviewView`
  - [ ] Test detected calendar structure display (months, eras, events)
  - [ ] Test calendar preview before creation
  - [ ] Test calendar editing before acceptance
- [ ] **Quality Tests (Manual):**
  - [ ] Test with 10 sample fantasy/sci-fi descriptions
  - [ ] Measure extraction accuracy (>70% target)
  - [ ] Test various calendar types (lunar, decimal, irregular)
- [ ] **Validation Tests:**
  - [ ] Test generated calendar structure validity
  - [ ] Test calendar hierarchy correctness
  - [ ] Test handling of incomplete calendar data
- [ ] **Cross-Feature Integration Tests:**
  - [ ] Test extracted calendar → timeline visualization workflow
  - [ ] Test calendar extraction → timeline epoch setting
  - [ ] Verify calendar usable in temporal timeline immediately

---

### Phase 8: ER-0008 Multi-Timeline Graph (2 weeks)

**Priority:** LOW-MEDIUM - Advanced visualization, high value for complex projects

**Goals:**
- Visualize multiple timelines on shared calendar
- Third tab on Calendar card detail
- Synchronized timeline visualization

**Tasks:**

#### 8.1: Multi-Timeline Graph View
- [ ] Create `MultiTimelineGraphView.swift`
- [ ] Query all timelines using this calendar
- [ ] Render as horizontal timelines
  - X-axis: Calendar time (shared)
  - Y-axis: Multiple timeline tracks
  - Scenes as labeled tickmarks
- [ ] Synchronized X-axis zoom/scroll

#### 8.2: Integration with Calendar Card
- [ ] Add third tab to Calendar detail view
- [ ] "Multi-Timeline Graph" tab
- [ ] List timelines using this calendar
- [ ] Enable/disable timeline tracks (show/hide)

#### 8.3: Visualization Features
- [ ] Color-code timelines (by project/world)
- [ ] Scene hover/tap for details
- [ ] Jump to scene in timeline
- [ ] Zoom controls (shared with TimelineChartView)

#### 8.4: Testing
- [ ] Multi-timeline rendering tests
- [ ] Synchronization tests (zoom/scroll)
- [ ] Performance tests (many timelines/scenes)

**Deliverables:**
- Multi-timeline visualization on Calendar cards
- Synchronized timeline comparison
- Professional graph UI

**Success Criteria:**
- Can view multiple timelines simultaneously
- X-axis synchronization works correctly
- Performance acceptable with 5+ timelines

**Risk:** Medium - Performance with many timelines, UI complexity

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):**
  - [ ] Test `MultiTimelineGraphView` rendering logic
  - [ ] Test query for all timelines using a calendar
  - [ ] Test X-axis synchronization across timeline tracks
  - [ ] Test timeline track color-coding logic
  - [ ] Test scene hover/tap data retrieval
- [ ] **Integration Tests:**
  - [ ] Test multi-timeline graph with 2 timelines
  - [ ] Test multi-timeline graph with 5+ timelines
  - [ ] Test Calendar detail view third tab integration
  - [ ] Test timeline enable/disable (show/hide tracks)
  - [ ] Test "Jump to scene in timeline" navigation
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test third tab on Calendar card detail view
  - [ ] Test timeline track list display
  - [ ] Test timeline enable/disable toggles
  - [ ] Test synchronized zoom controls
  - [ ] Test synchronized scroll behavior
  - [ ] Test scene hover/tap for details
  - [ ] Test color-coding display
- [ ] **Performance Tests:**
  - [ ] Test rendering with 5 timelines, 50 scenes each (< 200ms target)
  - [ ] Test rendering with 10 timelines, 100 scenes each
  - [ ] Test zoom/scroll responsiveness with many timelines
  - [ ] Test memory usage with large datasets
- [ ] **Visual/Manual Testing:**
  - [ ] Graph readability with multiple timelines
  - [ ] Scene label clarity
  - [ ] Color contrast for different timelines
  - [ ] Zoom behavior feels smooth

---

### Phase 9: ER-0009 Third-Party APIs & Advanced Features (2 weeks)

**Priority:** LOW-MEDIUM - Expands provider options, advanced capabilities

**Goals:**
- ChatGPT/DALL-E integration
- Auto-generation on card save
- Batch generation
- Regeneration history

**Tasks:**

#### 9.1: OpenAI/ChatGPT Integration
- [ ] Create `OpenAIProvider.swift`
- [ ] Implement DALL-E API client
- [ ] API key management (keychain)
- [ ] Rate limiting and quotas
- [ ] Error handling (API errors, network issues)
- [ ] Cost tracking (token usage)

#### 9.2: Provider Selection UI
- [ ] Multi-provider selection in settings
- [ ] Per-generation provider override
- [ ] Provider availability status
- [ ] Licensing information display

#### 9.3: Auto-Generation
- [ ] "Auto Generate Images" setting
- [ ] Trigger on card save (if enabled)
- [ ] Check conditions:
  - No image present
  - Sufficient description
  - User enabled auto-generation
- [ ] Background generation with notification

#### 9.4: Batch Generation
- [ ] Select multiple cards for generation
- [ ] Progress tracking
- [ ] Queue management
- [ ] Batch results review

#### 9.5: Regeneration History
- [ ] Store previous generated images (optional)
- [ ] Version tracking (v1, v2, v3...)
- [ ] Revert to previous version
- [ ] Version comparison (side-by-side)

#### 9.6: Testing
- [ ] OpenAI integration tests (with test API key)
- [ ] Auto-generation workflow tests
- [ ] Batch generation tests
- [ ] History management tests

**Deliverables:**
- ChatGPT/DALL-E provider integration
- Auto-generation capability
- Batch generation
- Regeneration history

**Success Criteria:**
- Can use ChatGPT as alternative to Apple Intelligence
- Auto-generation works reliably
- Batch generation handles errors gracefully
- History management preserves all versions

**Risk:** Medium - Third-party API reliability, cost management

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):**
  - [ ] Test `OpenAIProvider` DALL-E API client
  - [ ] Test API key validation and storage (keychain)
  - [ ] Test rate limiting logic
  - [ ] Test quota tracking
  - [ ] Test cost calculation (token usage)
  - [ ] Test error handling (API errors, rate limits, network issues)
  - [ ] Test auto-generation trigger logic
  - [ ] Test background generation queue
  - [ ] Test regeneration history storage (last 5 versions)
  - [ ] Test version tracking and comparison
- [ ] **Integration Tests:**
  - [ ] Test OpenAI provider integration (with test API key)
  - [ ] Test multi-provider switching (Apple Intelligence ↔ ChatGPT)
  - [ ] Test auto-generation workflow (card save → check conditions → generate)
  - [ ] Test batch generation queue management
  - [ ] Test batch progress tracking
  - [ ] Test history management (revert, compare)
- [ ] **UI Tests (CumberlandUITests, Cumberland IOSUITests):**
  - [ ] Test provider selection UI in settings
  - [ ] Test per-generation provider override
  - [ ] Test provider availability status display
  - [ ] Test licensing information display
  - [ ] Test "Auto Generate Images" setting toggle
  - [ ] Test batch generation UI (select multiple cards)
  - [ ] Test batch progress indicator
  - [ ] Test batch results review
  - [ ] Test regeneration history UI (version list)
  - [ ] Test version comparison (side-by-side)
- [ ] **Cost Management Tests:**
  - [ ] Test rate limiting prevents API overuse
  - [ ] Test cost tracking accuracy
  - [ ] Test quota warning display
- [ ] **Error Handling Tests:**
  - [ ] Test API key invalid/expired
  - [ ] Test rate limit exceeded
  - [ ] Test network timeout
  - [ ] Test batch generation with mixed success/failure
- [ ] **Settings Tests:**
  - [ ] Test auto-generation enable/disable
  - [ ] Test background notification delivery
  - [ ] Test history limit configuration (5 versions default)

---

### Phase 10: Polish, Testing, Documentation (1-2 weeks)

**Priority:** HIGH - Production readiness

**Goals:**
- Comprehensive testing across all features
- Performance optimization
- Documentation updates
- Bug fixes

**Tasks:**

#### 10.1: Integration Testing
- [ ] End-to-end workflows
  - ER-0008: Create calendar → create timeline → add scenes → visualize
  - ER-0009: Generate image → edit → regenerate → export
  - ER-0010: Analyze scene → create cards → generate images
  - ER-0010 + ER-0008: Extract calendar → associate with timeline
- [ ] Cross-platform testing (macOS, iOS, iPadOS, visionOS)
- [ ] CloudKit sync testing
- [ ] Migration testing (old projects → new features)

#### 10.2: Performance Optimization
- [ ] Timeline rendering performance (large timelines)
- [ ] AI request batching
- [ ] Image generation queue management
- [ ] Database query optimization
- [ ] Memory management (large images)

#### 10.3: Error Handling & Edge Cases
- [ ] Network failures
- [ ] API errors (rate limits, invalid keys)
- [ ] Invalid calendar structures
- [ ] Malformed temporal positions
- [ ] Degenerate cases (no data, empty descriptions)

#### 10.4: User Documentation
- [ ] Update in-app help
- [ ] Create user guides (screenshots/videos)
- [ ] Calendar system examples
- [ ] AI feature usage guidelines
- [ ] Troubleshooting guide

#### 10.5: Code Documentation
- [ ] Inline documentation (comments)
- [ ] API documentation
- [ ] Architecture diagrams
- [ ] Update CLAUDE.md

#### 10.6: Bug Fixes
- [ ] Address issues from testing
- [ ] User-reported bugs (if beta testing)
- [ ] Edge case handling

**Deliverables:**
- Production-ready features
- Comprehensive test coverage
- User and developer documentation
- Performance optimizations

**Success Criteria:**
- All features work reliably
- Performance meets targets
- Documentation complete
- Zero critical bugs

**Risk:** Low - Final polish, predictable scope

**Testing Activities:**

**This phase IS the comprehensive testing phase. All testing activities below are PRIMARY work, not supplementary.**

- [ ] **Comprehensive End-to-End Integration Tests (CumberlandTests/Integration/):**
  - [ ] **ER-0008 Full Workflow:** Create calendar → create timeline → set epoch → add temporal scenes → visualize in Gantt chart
  - [ ] **ER-0009 Full Workflow:** Extract prompt → generate image → apply attribution → export with metadata → verify in external viewer
  - [ ] **ER-0010 Full Workflow:** Analyze scene → review suggestions → create cards → create relationships → generate images for new cards
  - [ ] **ER-0010 + ER-0008 Integration:** Analyze timeline description → extract calendar → create calendar card → associate with timeline → visualize
  - [ ] **Multi-Feature Workflow:** Create world → analyze description → create entities → generate images → build timeline → extract calendar → visualize multi-timeline graph

- [ ] **Cross-Platform Testing:**
  - [ ] **macOS:** All features functional, performance acceptable
  - [ ] **iOS:** All features functional, touch interactions correct
  - [ ] **iPadOS:** All features functional, split-screen support
  - [ ] **visionOS:** All features functional, spatial UI appropriate (using new test targets)
  - [ ] Test feature parity across platforms
  - [ ] Test UI adaptations (ornaments on visionOS, toolbars on macOS, etc.)

- [ ] **CloudKit Sync Testing:**
  - [ ] Test all new models sync correctly (CalendarSystem, AI metadata, suggestions)
  - [ ] Test conflict resolution (concurrent edits)
  - [ ] Test sync across devices (macOS ↔ iOS ↔ iPad)
  - [ ] Test offline → online sync
  - [ ] Test large data sync (many images, complex calendars)

- [ ] **Migration Testing:**
  - [ ] Test clean migration from AppSchemaV5 → V6 (or V7, V8 depending on schema versions used)
  - [ ] Test migration with large existing projects (100+ cards)
  - [ ] Test migration preserves all existing data
  - [ ] Test rollback scenarios (if migration fails)
  - [ ] Test migration on all platforms

- [ ] **Performance Benchmarking:**
  - [ ] Timeline rendering: < 100ms for 100 scenes ✓
  - [ ] AI image generation: User-acceptable with progress UI ✓
  - [ ] Entity extraction: < 5s for typical scene description ✓
  - [ ] Database queries: < 50ms for typical queries ✓
  - [ ] Memory profiling: No leaks, acceptable memory usage
  - [ ] Battery impact testing (iOS/iPadOS)

- [ ] **Error Handling & Edge Cases:**
  - [ ] Network failures (AI providers, CloudKit)
  - [ ] API errors (rate limits, invalid keys, provider unavailable)
  - [ ] Invalid calendar structures (user-created errors)
  - [ ] Malformed temporal positions
  - [ ] Degenerate cases (no data, empty descriptions, zero-length timelines)
  - [ ] Concurrent operations (multiple generations, analyses)
  - [ ] Very large datasets (1000+ scenes, 100+ timelines)

- [ ] **Accessibility Testing:**
  - [ ] VoiceOver support (all new UI elements labeled)
  - [ ] Dynamic Type support (text scales correctly)
  - [ ] Keyboard navigation (macOS)
  - [ ] Contrast ratios (WCAG AA compliance)
  - [ ] Reduced motion support

- [ ] **Security Testing:**
  - [ ] API keys stored securely in keychain
  - [ ] No API keys in logs or crash reports
  - [ ] EXIF metadata doesn't leak sensitive info
  - [ ] User content not sent to AI without consent

- [ ] **Beta Testing (if applicable):**
  - [ ] Recruit 10-20 beta testers
  - [ ] Provide beta testing guide
  - [ ] Collect feedback via surveys and bug reports
  - [ ] Track feature adoption metrics
  - [ ] Address critical issues before release

- [ ] **Regression Testing:**
  - [ ] Run all existing tests (baseline from Phase 0)
  - [ ] Verify no regressions in existing features
  - [ ] Test backward compatibility thoroughly

- [ ] **Test Coverage Analysis:**
  - [ ] Measure final code coverage (target: >80% logic, >90% models)
  - [ ] Identify untested code paths
  - [ ] Add tests for gaps if critical

- [ ] **Documentation Verification:**
  - [ ] Verify all test plans executed
  - [ ] Document known issues
  - [ ] Create release notes
  - [ ] Update CLAUDE.md with new features

---

## Part 4: Risk Management

### High-Risk Areas

**1. ER-0008: Backward Compatibility**
- **Risk:** Breaking existing ordinal timelines
- **Mitigation:**
  - Comprehensive migration testing
  - Preserve `sortIndex` alongside temporal positioning
  - Feature flag for temporal mode (only when calendar associated)
  - Rollback plan if issues found

**2. ER-0010: NER Accuracy**
- **Risk:** Poor entity extraction (too many false positives)
- **Mitigation:**
  - Confidence thresholds (adjustable)
  - User can reject/train system
  - Conservative mode for high precision
  - Fallback to manual card creation

**3. ER-0009: Third-Party API Reliability**
- **Risk:** API downtime, rate limits, cost overruns
- **Mitigation:**
  - Default to Apple Intelligence (on-device)
  - Rate limiting and queue management
  - Cost tracking and warnings
  - Graceful degradation

**4. Cross-Feature Integration**
- **Risk:** ER-0010 calendar extraction depends on ER-0008 model
- **Mitigation:**
  - Implement ER-0008 calendar model first
  - Clear interfaces between features
  - Integration testing phase

### Medium-Risk Areas

**1. Schema Migrations**
- **Risk:** Data loss or corruption during migration
- **Mitigation:**
  - Test migrations extensively
  - Backup recommendation before update
  - Incremental schema versions (V6, V7, V8...)
  - Migration rollback capability

**2. UI Complexity (Timeline Chart)**
- **Risk:** Gantt-style chart too complex, performance issues
- **Mitigation:**
  - Prototype early
  - Performance profiling
  - Simplify if needed
  - Progressive disclosure (hide complexity)

**3. Attribution Compliance**
- **Risk:** Failing to meet AI provider ToS
- **Mitigation:**
  - Legal review of attribution implementation
  - Clear documentation of provider requirements
  - User education about licensing
  - Regular ToS review

### Low-Risk Areas

**1. Settings Persistence**
**2. UI Component Development**
**3. Documentation Updates**

---

## Part 5: Testing Strategy

### Unit Testing

**Coverage Targets:**
- Core logic: 80%+ coverage
- Data models: 90%+ coverage
- UI components: 60%+ coverage

**Key Test Areas:**
- Calendar system validation
- Temporal positioning logic
- Entity extraction and deduplication
- Relationship inference
- Image generation pipeline
- Metadata embedding/reading
- Suggestion ranking and filtering

### Integration Testing

**Test Scenarios:**
1. **Timeline End-to-End:**
   - Create calendar → Associate with timeline → Add temporal scenes → Visualize
2. **Image Generation End-to-End:**
   - Extract prompt → Generate image → Apply attribution → Export with metadata
3. **Content Analysis End-to-End:**
   - Analyze scene → Review suggestions → Create cards → Generate images
4. **Calendar Extraction Integration:**
   - Analyze timeline → Extract calendar → Create calendar card → Associate with timeline

### UI Testing

**Automated UI Tests:**
- Button states and interactions
- Sheet/modal presentation
- Form validation
- Navigation flows
- Error state display

**Manual UI Testing:**
- Visual polish
- Accessibility (VoiceOver, font sizes)
- Dark mode appearance
- Multi-platform consistency

### Performance Testing

**Metrics:**
- Timeline rendering: < 100ms for 100 scenes
- AI image generation: User perception managed with progress UI
- Entity extraction: < 5s for typical scene description
- Database queries: < 50ms for typical queries

**Stress Testing:**
- 1000+ scenes in timeline
- 100+ cards in analysis batch
- 10+ concurrent image generations
- Large calendar systems (100+ divisions)

### Beta Testing

**Phases:**
1. **Internal Alpha:** Developer testing (weeks 1-10)
2. **Closed Beta:** Small group of trusted users (weeks 11-12)
3. **Open Beta (optional):** TestFlight public beta
4. **Release:** App Store submission

**Feedback Collection:**
- Bug reports (GitHub Issues or in-app)
- Feature requests
- UX friction points
- Performance issues

---

## Part 6: Milestones & Decision Points

### Milestone 1: AI Infrastructure Complete (End of Phase 1)
**Date Target:** Week 2
**Deliverables:**
- Apple Intelligence working
- Settings panel functional
- Provider architecture tested

**Decision Point:**
- Proceed with ER-0009 and ER-0008 in parallel? (YES/NO)
- Add ChatGPT provider now or defer to Phase 9? (Defer recommended)

---

### Milestone 2: Image Generation MVP (End of Phase 2A)
**Date Target:** Week 5
**Deliverables:**
- Manual image generation working
- Basic attribution in place
- Card integration complete

**Decision Point:**
- User feedback on image quality and UX?
- Proceed with smart prompt extraction (Phase 3A)? (YES/NO)
- Adjust attribution display based on feedback?

---

### Milestone 3: Timeline Data Model Complete (End of Phase 2B)
**Date Target:** Week 5
**Deliverables:**
- Calendar System model functional
- Scene temporal positioning working
- Backward compatibility verified

**Decision Point:**
- Calendar model design satisfactory? (JSON vs. dedicated model)
- Proceed with timeline UI (Phase 3B)? (YES/NO)
- Epoch implementation acceptable?

---

### Milestone 4: Timeline Temporal Visualization (End of Phase 3B)
**Date Target:** Week 8
**Deliverables:**
- Gantt-style timeline chart working
- Calendar integration complete
- Ordinal mode still functional

**Decision Point:**
- User feedback on timeline UX?
- Performance acceptable for large timelines?
- Proceed with calendar editor (Phase 4B)? (YES/NO)

---

### Milestone 5: Content Analysis MVP (End of Phase 5)
**Date Target:** Week 11
**Deliverables:**
- Entity extraction working
- Suggestion review UI functional
- Card creation from suggestions working

**Decision Point:**
- NER accuracy acceptable? (Target: >80% precision at 70% confidence)
- Proceed with relationship inference (Phase 6)? (YES/NO)
- Defer calendar extraction to Phase 7? (Recommended)

---

### Milestone 6: Full Feature Set Complete (End of Phase 8)
**Date Target:** Week 14
**Deliverables:**
- All three ERs fully implemented
- Integration features working (calendar extraction)
- Multi-timeline graph functional

**Decision Point:**
- Ready for beta testing?
- Additional polish needed?
- Performance optimization required?

---

### Milestone 7: Production Ready (End of Phase 10)
**Date Target:** Week 16
**Deliverables:**
- All testing complete
- Documentation finished
- Bug fixes applied
- Performance optimized

**Decision Point:**
- Release immediately or further beta testing?
- Marketing/announcement strategy?
- Phased rollout or full release?

---

## Part 7: Resource Estimates

### Development Time Estimates

| Phase | ER | Duration | Complexity |
|-------|-----|----------|------------|
| Phase 0 | All | 2-3 days | Medium |
| Phase 1 | Shared | 1-2 weeks | Medium-High |
| Phase 2A | ER-0009 | 2-3 weeks | Medium |
| Phase 2B | ER-0008 | 2-3 weeks | Medium-High |
| Phase 3A | ER-0009 | 1-2 weeks | Medium |
| Phase 3B | ER-0008 | 2-3 weeks | High |
| Phase 4A | ER-0009 | 1-2 weeks | Medium |
| Phase 4B | ER-0008 | 1-2 weeks | Medium |
| Phase 5 | ER-0010 | 2-3 weeks | High |
| Phase 6 | ER-0010 | 1-2 weeks | Medium |
| Phase 7 | ER-0010 + ER-0008 | 1-2 weeks | Medium-High |
| Phase 8 | ER-0008 | 2 weeks | Medium |
| Phase 9 | ER-0009 | 2 weeks | Medium |
| Phase 10 | All | 1-2 weeks | Medium |

**Total Estimated Time:** 14-20 weeks (3.5-5 months)

**Parallel Work Opportunities:**
- Phases 2A and 2B can run in parallel (saves 2-3 weeks)
- Phases 3A and 3B can overlap partially
- Phases 4A and 4B can run in parallel (saves 1-2 weeks)

**Realistic Timeline with Parallelization:** 12-16 weeks (3-4 months)

### Complexity Assessment

**High Complexity:**
- ER-0008: Timeline temporal visualization (Phase 3B)
- ER-0010: Entity extraction and NER (Phase 5)
- ER-0010 + ER-0008: Calendar extraction (Phase 7)

**Medium-High Complexity:**
- AI provider infrastructure (Phase 1)
- ER-0008: Calendar data model (Phase 2B)
- ER-0010: Relationship inference (Phase 6)

**Medium Complexity:**
- ER-0009: Image generation MVP (Phase 2A)
- ER-0009: Smart prompt extraction (Phase 3A)
- ER-0009: Attribution & metadata (Phase 4A)
- ER-0008: Calendar editor (Phase 4B)
- ER-0008: Multi-timeline graph (Phase 8)
- ER-0009: Third-party APIs (Phase 9)

---

## Part 8: Success Metrics

### Feature Adoption Metrics

**ER-0008 (Timeline System):**
- % of timelines using calendar systems (target: 30% within 3 months)
- % of scenes with temporal positioning (target: 50% of calendar-based timelines)
- Multi-timeline graph usage (target: 10% of users)

**ER-0009 (AI Image Generation):**
- % of cards with AI-generated images (target: 40% within 3 months)
- Images generated per user (target: 10+ per active user)
- Attribution display satisfaction (qualitative feedback)

**ER-0010 (Content Analysis):**
- "Analyze" button usage (target: 50% of users try it)
- Suggestion acceptance rate (target: >60% of suggestions accepted)
- Cards created via analysis (target: 30% of all cards)

### Quality Metrics

**ER-0008:**
- Timeline rendering performance (< 100ms for 100 scenes)
- Calendar system validation errors (< 1% of custom calendars)
- Backward compatibility (0 regressions in ordinal mode)

**ER-0009:**
- Image generation success rate (> 95%)
- Attribution metadata persistence (100% through export)
- User satisfaction with generated images (> 70% positive)

**ER-0010:**
- Entity extraction precision (> 80% at 70% confidence)
- Duplicate prevention (< 5% duplicate suggestions)
- Relationship inference accuracy (> 75% correct)

### User Satisfaction

**Surveys:**
- Post-release user survey (2 weeks after launch)
- Feature-specific feedback forms
- App Store reviews (target: maintain 4.5+ rating)

**Support Metrics:**
- Support tickets related to new features (< 10% of total tickets)
- Feature-related bugs (< 5 critical bugs in first month)
- Documentation clarity (< 20% of users request help)

---

## Part 9: Rollback & Contingency Plans

### Rollback Scenarios

**Scenario 1: Critical Bug in ER-0008**
- **Trigger:** Timeline visualization completely broken for some users
- **Action:**
  - Disable temporal mode via feature flag
  - Fall back to ordinal mode for all timelines
  - Release hotfix within 24 hours
  - Resume temporal mode after fix verified

**Scenario 2: AI Provider Failures (ER-0009/0010)**
- **Trigger:** Apple Intelligence or ChatGPT consistently failing
- **Action:**
  - Disable problematic provider
  - Fall back to other providers
  - Display error message with explanation
  - Allow manual retry after provider recovery

**Scenario 3: Data Migration Issues (ER-0008)**
- **Trigger:** Schema migration causes data loss or corruption
- **Action:**
  - Halt rollout immediately
  - Restore from CloudKit backup (if available)
  - Revert to previous app version
  - Fix migration, re-test extensively
  - Phased re-rollout

### Feature Flags

**Recommended Feature Flags:**
- `enableTemporalTimelines` (ER-0008)
- `enableAIImageGeneration` (ER-0009)
- `enableContentAnalysis` (ER-0010)
- `enableCalendarExtraction` (ER-0010 + ER-0008)
- `enableMultiTimelineGraph` (ER-0008)

**Benefits:**
- Quick disable if issues found
- A/B testing possible
- Gradual rollout (e.g., 10% → 50% → 100%)
- Per-user control for beta testers

### Phased Rollout Strategy

**Option 1: Feature-by-Feature**
1. Release ER-0009 (Image Generation) first
2. Release ER-0008 (Timeline System) second
3. Release ER-0010 (Content Analysis) third
4. Release integration features (calendar extraction, multi-timeline)

**Option 2: All-at-Once with Feature Flags**
1. Release all features with flags disabled
2. Enable ER-0009 for all users (low risk)
3. Enable ER-0008 for 50% of users (monitor performance)
4. Enable ER-0010 for 50% of users (monitor NER quality)
5. Enable all features for 100% after 1 week

**Recommendation:** Option 2 (All-at-once with gradual enable) for faster feedback and easier coordination.

---

## Part 10: Open Questions & Next Steps

### Open Questions Requiring Decisions

**ER-0008:**
1. Calendar representation: JSON in Rules card vs. dedicated SwiftData model?
   - **Recommendation:** Dedicated model for queryability
2. Epoch storage: Property on Timeline vs. separate model?
   - **Recommendation:** Property on Timeline (simpler)
3. Zoom behavior: Linear vs. logarithmic for large time spans?
   - **Recommendation:** Adaptive (automatic based on data range)

**ER-0009:**
1. Attribution display prominence: Subtle badge vs. visible overlay?
   - **Recommendation:** Subtle badge (tappable), user preference to show overlay
2. Regeneration history: Store all versions vs. latest only?
   - **Recommendation:** Configurable limit (e.g., last 5 versions)
3. Auto-generation trigger: On save vs. on-demand only?
   - **Recommendation:** Optional setting, off by default

**ER-0010:**
1. Analysis triggers: Manual only vs. auto-analyze option?
   - **Recommendation:** Manual only (MVP), auto-analyze as future enhancement
2. Suggestion persistence: Store for later vs. discard on close?
   - **Recommendation:** Discard on close (MVP), queue as future enhancement
3. Learning from user: Track accept/reject patterns?
   - **Recommendation:** Yes, but anonymized and local-only (privacy)

### Next Steps

**Immediate (Week 1):**
1. Review and approve this implementation plan
2. Make architecture decisions (resolve open questions above)
3. Set up project structure and feature flags
4. Create Phase 0 architecture decision record

**Short-Term (Weeks 2-3):**
1. Begin Phase 1 (AI infrastructure)
2. Prototype calendar data model (ER-0008)
3. Research Apple Intelligence API (ER-0009)
4. Set up testing infrastructure

**Medium-Term (Weeks 4-8):**
1. Execute Phases 2A and 2B in parallel
2. Weekly sync meetings to coordinate
3. First round of integration testing
4. User feedback on early MVPs

**Long-Term (Weeks 9-16):**
1. Complete all phases
2. Comprehensive testing
3. Beta testing with users
4. Documentation and polish
5. Release preparation

---

## Conclusion

This implementation plan provides a structured approach to delivering three major enhancement requests:

- **ER-0008:** Time-Based Timeline System
- **ER-0009:** AI Image Generation
- **ER-0010:** AI Content Analysis

**Key Principles:**
- Phased, incremental delivery
- Parallel development where possible
- Shared infrastructure reduces duplication
- Comprehensive testing at each milestone
- Feature flags for safe rollout
- User feedback drives iteration

**Timeline:** 12-16 weeks (3-4 months) with parallelization

**Next Step:** Review and approve plan, then begin Phase 0 (Planning & Architecture).

---

*Document Version: 1.0*
*Last Updated: 2026-01-20*
*Author: Claude (AI Assistant) in collaboration with User*
