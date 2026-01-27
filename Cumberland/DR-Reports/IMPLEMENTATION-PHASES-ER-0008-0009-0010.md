# Implementation Plan: ER-0008, ER-0009, ER-0010

**Major Enhancement Requests - AI and Timeline System**

**Date Created:** 2026-01-20
**Last Updated:** 2026-01-27
**Status:** In Progress - Active Development
**Target Completion:** TBD

**Progress Summary (as of 2026-01-27):**
- ✅ **Phase 0:** Foundation & Planning - COMPLETED
- ✅ **Phase 1:** AI Provider Infrastructure (ER-0009) - COMPLETED
- ✅ **Phase 2A:** AI Image Generation MVP (ER-0009) - COMPLETED & VERIFIED
- ✅ **Phase 2B:** Timeline Data Model (ER-0008) - COMPLETED & VERIFIED
- ✅ **Phase 3B:** Timeline Temporal Visualization (ER-0008) - COMPLETED
  - ✅ Phase 3B.1: Mode detection & temporal X-axis
  - ✅ Phase 3B.2: Gantt-style visualization with duration
  - ✅ Phase 3B.3: Smart zoom controls (7 levels)
  - ✅ Phase 3B.4: Calendar integration UI
  - ✅ Phase 3B.5: Scene temporal position editor
- ✅ **Phase 3A:** Smart Prompt Extraction (ER-0009) - COMPLETED (2026-01-23)
- ✅ **Phase 4A:** Enhanced Attribution & Metadata (ER-0009) - COMPLETED (2026-01-24)
- ✅ **Phase 4B:** Calendar Editor (ER-0008) - COMPLETED (2026-01-24)
- ✅ **Phase 5:** Content Analysis MVP (ER-0010) - COMPLETED & VERIFIED (2026-01-24)
  - ✅ Entity extraction with NER
  - ✅ Text preprocessing for chapter-length prose
  - ✅ Suggestion review UI
  - ✅ Card creation from suggestions
  - ✅ Fixed DR-0050 (timeout) and DR-0052 (parsing + case sensitivity)
- ✅ **Phase 6:** Relationship Inference (ER-0010) - COMPLETED & VERIFIED (2026-01-26)
  - ✅ Pattern-based relationship detection (13 patterns)
  - ✅ Fuzzy name matching for pronouns and partial names
  - ✅ Bidirectional relationship creation (forward + reverse edges)
  - ✅ Smart timing (immediate vs deferred based on card existence)
  - ✅ Fixed DR-0055 (workflow timing) and DR-0056 (bidirectional edges)
- ✅ **Phase 7:** Calendar Extraction (ER-0010 + ER-0008) - COMPLETED & VERIFIED (2026-01-26)
  - ✅ AI-powered calendar extraction from text
  - ✅ Multi-calendar support (array-based)
  - ✅ Calendar suggestions in SuggestionReviewView
  - ✅ Automatic TimeDivision hierarchy generation
  - ✅ OpenAI GPT-4 integration for calendar extraction
- ✅ **Phase 7.5:** Calendar Cards Architecture (ER-0008) - COMPLETED & VERIFIED (2026-01-27)
  - ✅ Added .calendars kind to Kinds enum
  - ✅ Card.calendarSystemRef relationship (one-to-one with CalendarSystem)
  - ✅ CalendarCardDetailView with 3 tabs (Details, Timelines, Multi-Timeline)
  - ✅ Migration helper for orphaned CalendarSystem objects
  - ✅ Deduplication for duplicate calendar cards
  - ✅ Updated AI extraction to create Calendar cards (not standalone systems)
  - ✅ CalendarSystemPicker updated to use Calendar cards
  - ✅ CardEditorView support for calendar creation/editing
  - ✅ Fixed event classification (events → chronicles, not scenes)
  - ✅ Expanded calendar extraction to 8 card types
  - ✅ All SF Symbol issues resolved (tilde, gearshape)
- ⏸️ **Remaining Phases:** See detailed timeline below

---

**Note:** This document contains detailed phase-by-phase implementation steps. For strategic planning, dependencies, testing strategy, and risk management, see [IMPLEMENTATION-STRATEGY-ER-0008-0009-0010.md](./IMPLEMENTATION-STRATEGY-ER-0008-0009-0010.md).

---

## Part 3: Detailed Phase Breakdown

### Phase 0: Planning & Architecture ✅ COMPLETED (2026-01-20/21)

**Goals:**
- Finalize architecture decisions
- Resolve open design questions
- Set up project structure and test infrastructure

**Status:** ✅ Planning and architecture decisions completed

**Tasks:**
1. **AI Provider Architecture** ✅
   - [x] Define `AIProviderProtocol` - COMPLETED
   - [x] Design settings data model (`AISettings`) - COMPLETED
   - [x] Plan keychain integration for API keys - COMPLETED

2. **Data Model Planning** ✅
   - [x] Calendar System model design (ER-0008) - DECIDED: Dedicated SwiftData model
   - [x] Scene temporal positioning schema (ER-0008) - DECIDED: Optional properties on CardEdge
   - [x] Image metadata schema (ER-0009) - DECIDED: Optional properties on Card
   - [ ] Suggestion tracking schema (ER-0010) - NOT YET STARTED

3. **Decision Points (Open Design Questions)** ✅
   - [x] **ER-0008:** Calendar representation - DECIDED: Dedicated SwiftData model for queryability
   - [x] **ER-0008:** Epoch storage - DECIDED: Property on Timeline card (simpler)
   - [x] **ER-0009:** Attribution display prominence - DECIDED: Badge overlay (purple gradient with wand icon)
   - [ ] **ER-0010:** Analysis triggers - NOT YET DECIDED

4. **Test Infrastructure Setup** ⏸️
   - **Create visionOS test targets:** (Deferred to Phase 10)
     - [ ] Create `CumberlandVisionOSTests` (unit tests)
     - [ ] Create `CumberlandVisionOSUITests` (UI tests)
   - **Organize CumberlandTests:** (Deferred to Phase 10)
     - [ ] Create folders: `ER-0008-Timeline/`, `ER-0009-ImageGeneration/`, `ER-0010-ContentAnalysis/`, `Integration/`
     - [ ] Move existing tests to `Existing/` folder
     - [ ] Create test file templates for each ER
   - **Set up CI/CD:** ✅ PARTIALLY COMPLETE
     - [x] GitHub Actions workflow exists (`.github/workflows/test.yml`)
     - [ ] Enable automatic test runs on commits
     - [ ] Set up nightly comprehensive test runs
   - **Create test data fixtures:** (Deferred to Phase 10)
     - [ ] Sample Gregorian calendar
     - [ ] Sample fantasy calendar
     - [ ] Sample scenes with rich descriptions
     - [ ] Sample cards for analysis testing

**Deliverables:** ✅ (Core deliverables completed, test infrastructure deferred)
- ✅ Architecture decision record - Documented in implementation
- ✅ Data model designs - Finalized and implemented
- ⏸️ Test infrastructure configured - Deferred to comprehensive testing phase
- ⏸️ Test target organization complete - Deferred to comprehensive testing phase
- ⏸️ Test data fixtures created - Deferred to comprehensive testing phase

**Risk:** Medium - Decisions made here affect entire implementation
**Resolution:** Key architectural decisions successfully made and implemented

**Testing Activities:**
- [x] Verify test targets build successfully - VERIFIED (existing tests pass)
- [x] Run existing tests to establish baseline - VERIFIED
- [ ] Validate CI/CD pipeline configuration - DEFERRED

---

### Phase 1: Shared AI Infrastructure ✅ COMPLETED (2026-01-20/21)

**Priority:** HIGH - Blocks ER-0009 and ER-0010

**Goals:**
- Implement AI provider infrastructure
- Apple Intelligence integration (default provider)
- Settings panel for AI configuration

**Status:** ✅ Completed and verified

**Tasks:**

#### 1.1: AI Provider Protocol & Architecture ✅
- [x] Create `AIProviderProtocol.swift`
  - Image generation method signatures
  - Text analysis method signatures (for ER-0010) - Placeholder added
  - Error handling
  - Provider metadata (name, capabilities, licensing)
- [x] Create `AIProviderError` enum
- [x] Create provider base classes/utilities (AIProviderRegistry)

#### 1.2: Apple Intelligence Integration ✅
- [x] Create `AppleIntelligenceProvider.swift`
- [x] Import ImagePlayground framework (iOS 18.2+, macOS 15.2+)
- [x] Implement image generation
- [ ] Implement text analysis (for ER-0010) - Deferred to Phase 5
- [x] Handle availability checks (OS version)
- [x] Error handling and fallbacks

#### 1.3: Settings Infrastructure ✅
- [x] Settings UI integrated into SettingsView.swift
- [x] Provider selection (Apple Intelligence, OpenAI DALL-E 3)
- [x] API key management (keychain storage via KeychainHelper)
- [x] Provider availability status display
- [x] Settings persistence (UserDefaults with @AppStorage)
- [x] Fixed keychain key generation bug (provider key mismatch)

#### 1.4: Testing ✅
- [x] Manual testing for provider protocol
- [x] Manual testing for Apple Intelligence and OpenAI providers
- [x] Manual testing for settings persistence
- [x] Manual testing for keychain security (API key storage/retrieval)

**Additional Implementation:**
- [x] OpenAIProvider.swift - Added third-party provider support
- [x] Network entitlement added (com.apple.security.network.client)
- [x] Provider registry system for managing multiple providers

**Deliverables:** ✅
- ✅ Working Apple Intelligence integration
- ✅ Working OpenAI DALL-E 3 integration
- ✅ Settings panel for AI configuration
- ✅ Provider architecture ready for additional providers
- ✅ Keychain-based API key management

**Success Criteria:** ✅ VERIFIED
- ✅ Can generate image with Apple Intelligence
- ✅ Can generate image with OpenAI DALL-E 3
- ✅ Settings persist correctly
- ✅ Clean provider abstraction for future expansion
- ✅ API keys stored securely in keychain

**Risk:** Medium - Apple Intelligence API availability, OS version requirements
**Resolution:** Successfully implemented with availability checks and fallbacks

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):** (Deferred to Phase 10)
  - [ ] Test `AIProviderProtocol` conformance
  - [ ] Test `AppleIntelligenceProvider` image generation
  - [ ] Test `OpenAIProvider` image generation
  - [ ] Test provider error handling (unavailable, API errors)
  - [ ] Test settings persistence (UserDefaults)
  - [ ] Test keychain storage/retrieval for API keys
- [x] **Integration Tests:** ✅ MANUAL VERIFICATION COMPLETED (2026-01-20/21)
  - [x] Test Apple Intelligence availability detection - VERIFIED WORKING
  - [x] Test OpenAI provider availability and API calls - VERIFIED WORKING
  - [x] Test provider switching in settings - VERIFIED WORKING
  - [x] Test API key persistence in keychain - VERIFIED WORKING (after fix)
  - [ ] Test settings sync across devices (CloudKit) - Not applicable (UserDefaults)
- [x] **UI Tests (CumberlandUITests, Cumberland IOSUITests):** ✅ MANUAL VERIFICATION COMPLETED
  - [x] Test settings panel navigation - VERIFIED WORKING
  - [x] Test provider selection UI - VERIFIED WORKING
  - [x] Test API key input and validation - VERIFIED WORKING
- [ ] **Performance Tests:** (Deferred to Phase 10)
  - [ ] Measure provider initialization time (< 100ms)
- [ ] **CI/CD Validation:** (Deferred to Phase 10)
  - [ ] Ensure all tests pass in CI pipeline
  - [ ] Establish baseline coverage metrics

---

### Phase 2A: ER-0009 Image Generation MVP ✅ COMPLETED (2026-01-21/22)

**Priority:** HIGH - High user value, enables visual worldbuilding

**Goals:**
- Manual image generation with user-provided prompts
- Basic attribution and metadata
- Card detail view integration

**Status:** ✅ Completed and verified

**Tasks:**

#### 2A.1: Core Image Generation ✅
- [x] Create `AIImageGenerator.swift`
  - Use provider infrastructure from Phase 1
  - Prompt → Image pipeline
  - Progress tracking
  - Error handling
- [x] Image format conversion and storage
- [x] Integration with Card `originalImageData`

#### 2A.2: Card Model Updates ✅
- [x] Schema migration - Used CloudKit auto-migration with optional properties
- [x] Add properties to Card:
  - `imageGeneratedByAI: Bool?`
  - `imageAIProvider: String?`
  - `imageAIPrompt: String?`
  - `imageAIGeneratedAt: Date?`
- [x] Migration plan for existing cards - Optional properties, no explicit migration needed

#### 2A.3: UI Integration ✅
- [x] Add "Generate Image" button to `CardEditorView.swift`
  - Button placement and styling
  - Enabled/disabled states
  - Tooltip
- [x] Create `AIImageGenerationView.swift` (sheet/modal)
  - Prompt input field
  - Provider selection (Apple Intelligence, OpenAI)
  - "Generate" button
  - Progress indicator
  - Image preview
  - Accept/Retry/Discard actions
- [x] Attribution badge display
  - "AI Generated" badge on card images (purple gradient)
  - Tappable for details

#### 2A.4: Basic Attribution ✅
- [x] Store provider and date in Card metadata
- [x] Display "AI Generated" badge with wand.and.stars icon
- [x] Image info panel (AIImageInfoView) showing provider, date, prompt
- [x] EXIF/IPTC metadata embedding via ImageMetadataWriter
- [x] Auto-create Citation for AI-generated images

#### 2A.5: Testing ✅
- [x] Manual testing for image generation pipeline
- [x] Manual testing for generation workflow
- [x] Manual testing for prompt → image → save → display flow
- [x] Manual testing for error scenarios (API key issues, network)

**Deliverables:** ✅
- ✅ Working manual image generation
- ✅ Images saved to cards with attribution
- ✅ Clean UI for generation workflow
- ✅ Metadata embedding and auto-citation

**Success Criteria:** ✅ VERIFIED
- ✅ User can generate image with custom prompt
- ✅ Image appears on card with attribution
- ✅ Regeneration works correctly (pre-fills prompt)
- ✅ Badge visibility control (shown in large views, hidden in small cards)

**Risk:** Low-Medium - Relies on Phase 1 infrastructure
**Resolution:** Successfully integrated with AI provider infrastructure

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0009-ImageGeneration/):** (Deferred to Phase 10)
  - [ ] Test `AIImageGenerator` prompt-to-image pipeline
  - [ ] Test image format conversion and storage
  - [ ] Test Card model schema migration (CloudKit auto-migration)
  - [ ] Test AI metadata properties (imageGeneratedByAI, etc.)
  - [ ] Test error scenarios (network failure, API errors)
- [x] **Integration Tests:** ✅ MANUAL VERIFICATION COMPLETED (2026-01-21/22)
  - [x] Test full generation workflow (prompt → generate → save → display) - VERIFIED WORKING
  - [x] Test image storage in `originalImageData` - VERIFIED WORKING
  - [x] Test thumbnail generation for AI images - VERIFIED WORKING
  - [x] Test attribution data persistence - VERIFIED WORKING
  - [x] Test EXIF/IPTC metadata embedding - VERIFIED WORKING
  - [x] Test auto-citation creation - VERIFIED WORKING
- [x] **UI Tests (CumberlandUITests, Cumberland IOSUITests):** ✅ MANUAL VERIFICATION COMPLETED
  - [x] Test "Generate Image" button visibility and states - VERIFIED WORKING
  - [x] Test `AIImageGenerationView` sheet presentation - VERIFIED WORKING
  - [x] Test prompt input and validation - VERIFIED WORKING
  - [x] Test progress indicator during generation - VERIFIED WORKING
  - [x] Test accept/retry/discard actions - VERIFIED WORKING
  - [x] Test attribution badge display - VERIFIED WORKING
  - [x] Test badge visibility control (shown/hidden in different contexts) - VERIFIED WORKING
  - [x] Test prompt pre-fill on regeneration - VERIFIED WORKING
- [x] **Manual Testing:** ✅ VERIFIED (2026-01-21/22)
  - [x] Visual quality of generated images - VERIFIED WORKING
  - [x] Image preview clarity - VERIFIED WORKING
  - [x] Attribution badge appearance (light/dark mode) - VERIFIED WORKING
- [x] **Migration Tests:** ✅ VERIFIED
  - [x] CloudKit auto-migration with optional properties - VERIFIED WORKING
  - [x] Verify existing cards unaffected - VERIFIED WORKING

---

### Phase 2B: ER-0008 Timeline Data Model ✅ COMPLETED (2026-01-22)

**Priority:** HIGH - Foundation for timeline enhancements

**Goals:**
- Calendar System model
- Scene temporal positioning
- Backward compatibility with ordinal timelines

**Status:** ✅ Completed and verified

**Tasks:**

#### 2B.1: Calendar System Model ✅
- [x] Design decision: JSON in Rules card vs. dedicated model
  - **Decision:** Dedicated SwiftData model for queryability
- [x] Create `CalendarSystem` model
  - Time division hierarchy (seconds → minutes → hours → days → weeks → months → years → eras)
  - Division names and lengths
  - Custom vs. fixed divisions
  - Validation rules
  - **CloudKit compliant:** All properties have defaults, inverse relationships declared
- [x] Create Gregorian calendar template
  - Pre-populated calendar with 10 divisions (second → millennium)
  - Seeded automatically on first launch via `seedCalendarSystemsIfNeeded()`

#### 2B.2: Epoch Model ✅
- [x] Design decision: Property on Timeline or separate model?
  - **Decision:** Property on Timeline card (simpler)
- [x] Add to Card model (for Timeline cards):
  - `epochDate: Date?` - Optional starting point for timeline
  - `epochDescription: String?` - Human-readable epoch description
  - Properties are optional for CloudKit auto-migration

#### 2B.3: Scene Temporal Positioning ✅
- [x] Add to CardEdge (Scene→Timeline relationship):
  - `temporalPosition: Date?` (new, optional)
  - `duration: TimeInterval?` (new, optional)
  - Kept existing `sortIndex` for backward compatibility
- [x] Migration: CloudKit auto-migrates optional properties
- [x] Logic foundation for detecting timeline mode (ordinal vs. temporal)

#### 2B.4: Relationship Types ✅
- [x] RelationType "uses/used-by" already enabled in relationship seeds
- [x] Available for Timeline → Calendar relationships

#### 2B.5: Testing
- [ ] Unit tests for calendar model (deferred to comprehensive testing phase)
- [ ] Unit tests for temporal positioning (deferred to comprehensive testing phase)
- [ ] Migration tests (ordinal → temporal, backward compat) (deferred to comprehensive testing phase)
- [x] Gregorian calendar validation - manual verification successful

**Deliverables:** ✅
- ✅ Calendar System model with Gregorian template
- ✅ Scene temporal positioning support (CardEdge properties)
- ✅ Backward-compatible with existing timelines (optional properties)
- ✅ CloudKit-compliant data model

**Success Criteria:** ✅ VERIFIED
- ✅ Can create custom calendar system (model and seeding implemented)
- ✅ Can associate timeline with calendar (relationship working)
- ✅ Existing ordinal timelines still work (backward compatible)

**Risk:** Medium - Data model complexity, migration safety
**Resolution:** Used CloudKit auto-migration with optional properties to avoid explicit schema migration

**Implementation Note:** Chose "Option A" approach - did NOT modify AppSchemaV5. SwiftData automatically discovers the CalendarSystem @Model, and CloudKit auto-migrates all optional properties. This avoids the complexity and risks of explicit schema versioning.

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):** (Deferred to Phase 10)
  - [ ] Test `CalendarSystem` model creation and validation
  - [ ] Test Gregorian calendar template structure
  - [ ] Test time division hierarchy logic
  - [ ] Test epoch model (property on Timeline)
  - [ ] Test scene temporal positioning (CardEdge properties)
  - [ ] Test ordinal vs. temporal mode detection
  - [ ] Test RelationType "uses/used-by" creation
- [x] **Integration Tests:** ✅ MANUAL VERIFICATION COMPLETED (2026-01-22)
  - [x] Test Timeline → Calendar relationship - VERIFIED WORKING
  - [x] Test backward compatibility (existing ordinal timelines) - VERIFIED WORKING
  - [ ] Test Scene → Timeline temporal positioning (deferred - no UI yet)
  - [x] Test schema migration (CloudKit auto-migration) - VERIFIED WORKING
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

### Phase 3A: ER-0009 Smart Prompt Extraction ✅ COMPLETED (1-2 weeks)

**Priority:** MEDIUM - Enhances image generation UX

**Status:** COMPLETED (2026-01-23)

**Goals:**
- Auto-extract prompts from card descriptions
- Description quality detection
- Smart "Generate Image" button enable/disable

**Tasks:**

#### 3A.1: Prompt Extraction ✅ COMPLETED
- [x] Create `PromptExtractor.swift`
- [x] Analyze card type for context
  - Character → "A detailed portrait of..."
  - Location → "A landscape illustration of..."
  - Building → "Architectural concept art of..."
  - Vehicle → "Technical illustration of..."
  - Maps → "A map illustration of..."
  - Artifacts → "A detailed rendering of..."
  - Worlds → "A world map or globe visualization of..."
- [x] Extract key visual phrases from `detailedText`
  - Extracts visual keywords (colors, materials, lighting, mood, physical attributes)
  - Filters dialogue and non-visual content
  - Generates 3 prompt variations (detailed, simple, atmospheric)
- [x] Format prompts for AI providers

**Implementation Details:**
- **VisualKeyword categories**: color, physical, mood, material, lighting
- **Keyword collections**: 60+ visual descriptors
- **Prompt variations**: Detailed (with keywords), Simple (with style), Atmospheric (mood-focused)
- **extractVisualSentence()**: Intelligently extracts first visual sentence, skips dialogue
- **kindToPromptPrefix()**: Context-aware prompt prefixes for each card type

#### 3A.2: Description Analysis ✅ COMPLETED
- [x] Create `DescriptionAnalyzer.swift`
- [x] Word count analysis
- [x] Visual keyword detection (colors, sizes, moods, materials, lighting)
- [x] Quality scoring (0-100%)
  - Word count: 0-60 points (minimum 50 words, ideal 150 words)
  - Visual keywords: 0-30 points (3 points per keyword, max 30)
  - Dialogue penalty: -10 points
  - Rich description bonus: +10 points (150+ words + 10+ keywords)
- [x] Minimum threshold: 50% quality score (default)

**Implementation Details:**
- **Quality thresholds**: <50% insufficient, 50-60% sufficient, 60-80% good, 80%+ excellent
- **User recommendations**: Specific advice (e.g., "Add more details (35/50 words)")
- **detectDialogue()**: Identifies quotation marks and dialogue tags
- **60+ visual keywords** across categories

#### 3A.3: UI Enhancement ✅ COMPLETED
- [x] "Generate Image" button smart enable/disable
  - Enabled when: sufficient description (quality >= 50%)
  - Disabled when: insufficient description
  - Tooltip shows recommendation from analyzer
- [x] Extracted prompt suggestions shown in AIImageGenerationView
  - 3 variations displayed with lightbulb icons
  - Click to use suggestion
- [x] Manual editing always allowed in prompt TextEditor

**Implementation Details:**
- **CardEditorView**: Real-time description analysis on text changes
- **descriptionAnalysis** state variable tracks quality
- **onChange(of: detailedText)**: Re-analyzes on every change
- **Button.disabled()**: Bound to analysis result
- **Button.help()**: Shows recommendation message
- **AIImageGenerationView**: Passes description + kind for prompt extraction

#### 3A.4: Testing
- [x] Build verification - all code compiles successfully
- [ ] Manual testing with various card types (deferred)
- [ ] Unit tests for prompt extraction (deferred to Phase 10)
- [ ] Description analysis accuracy tests (deferred to Phase 10)

**Deliverables:**
- ✅ `PromptExtractor.swift` - Smart prompt extraction with 3 variations
- ✅ `DescriptionAnalyzer.swift` - Quality scoring system
- ✅ Smart "Generate Image" button enable/disable
- ✅ Real-time description analysis
- ✅ Contextual prompt suggestions
- ✅ Improved UX for image generation

**Files Created/Modified:**
- `AI/PromptExtractor.swift` - NEW: Smart prompt extraction component
- `AI/DescriptionAnalyzer.swift` - NEW: Description quality analyzer
- `AI/AIImageGenerationView.swift` - Updated to use PromptExtractor
- `CardEditorView.swift` - Added real-time description analysis

**Success Criteria:**
- ✅ Extracted prompts use card context (type-specific prefixes)
- ✅ Button disables for insufficient descriptions
- ✅ User can see and override extracted prompts
- ✅ Real-time feedback via tooltip
- ✅ 3 prompt variations for user choice

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

### Phase 3B: ER-0008 Timeline UI - Temporal Mode ✅ COMPLETED (2-3 weeks)

**Priority:** HIGH - Delivers core timeline visualization

**Status:**
- ✅ Phase 3B.4 (Calendar Integration UI) - COMPLETED & VERIFIED (2026-01-22)
- ✅ Phase 3B.1-3 (Gantt-style visualization) - COMPLETED (2026-01-23)
- ✅ Phase 3B.5 (Scene Temporal Position Editor) - COMPLETED (2026-01-23)

**Goals:**
- Gantt-style timeline chart for temporal mode
- Adaptive X-axis (ordinal vs. temporal)
- Backward compatibility with ordinal mode

**Tasks:**

#### 3B.1: TimelineChartView Enhancement ✅ COMPLETED
- [x] Detect timeline mode:
  - Has Calendar associated? → Temporal mode
  - No Calendar? → Ordinal mode (existing behavior)
- [x] Implement temporal X-axis
  - Date/time domain instead of ordinal
  - Calendar-aware formatting
  - Zoom levels (hour/day/week/month/year/decade/century)
- [x] Scene positioning logic
  - Use `temporalPosition` for temporal mode
  - Use `sortIndex` for ordinal mode
  - Handle scenes without temporal position (shows empty state)

**Implementation Details:**
- Added `TimelineMode` enum (ordinal/temporal)
- Automatic mode detection based on `timeline.calendarSystem != nil`
- Separate data loading paths for ordinal vs temporal
- `SceneRow` updated with optional `temporalPosition` and `duration`
- Auto-sort scenes by temporal position in temporal mode

#### 3B.2: Gantt-Style Visualization ✅ COMPLETED
- [x] X-axis: Calendar timeline (Date domain)
- [x] Y-axis: Scenes (as bars)
- [x] Scene duration visualization
  - Default: 1-hour duration if not specified
  - BarMark renders from start to end time
- [x] Character resources display
  - Characters/chapters shown as "resources" on scenes
  - Same lane structure as ordinal mode

**Implementation Details:**
- Created `temporalChartArea` separate from `ordinalChartArea`
- Uses SwiftUI Charts with Date domain for X-axis
- `TemporalSceneItem` struct for chart data
- Empty state for timelines without temporal data
- Epoch support via `timeline.epochDate`

#### 3B.3: Zoom & Scroll Controls ✅ COMPLETED
- [x] Smart zoom levels
  - 7 levels: Hour → Day → Week → Month → Year → Decade → Century
  - `TemporalZoomLevel` enum with time intervals
- [x] Auto-select appropriate zoom level based on timeline span
- [x] Zoom controls updated for temporal mode
  - Zoom In: More detailed time scale
  - Zoom Out: Broader time scale
  - Fit All: Auto-selects optimal zoom
- [x] Current zoom level displayed in header

**Implementation Details:**
- `autoSelectZoomLevel(for: TimeInterval)` function
- Updated `zoomIn()`, `zoomOut()`, `fitAll()` with temporal mode branches
- `temporalDateFormatter()` adapts to zoom level (HH:mm for hours, yyyy for years)
- Zoom level indicator shown in header (temporal mode only)

#### 3B.5: Scene Temporal Position Editor ✅ COMPLETED (2026-01-23)
- [x] Create SceneTemporalPositionEditor component
  - Date picker for temporal position
  - Duration presets (15 min → 1 week)
  - Custom duration input (days/hours/minutes)
  - Display scene end time
  - Clear position option
- [x] Integrate editor into TimelineChartView
  - "Edit Positions…" menu in header (temporal mode)
  - Lists all scenes with warning indicator for scenes without temporal position
  - Sheet presentation for editor
  - Auto-reload timeline after edits
- [x] Persist temporal data to CardEdge
  - Updates `temporalPosition` (Date?)
  - Updates `duration` (TimeInterval?)
  - Context save on dismiss

**Implementation Details:**
- **File:** `SceneTemporalPositionEditor.swift` (new component)
- Graphical date picker with date + time
- Duration preset picker with common durations
- Custom duration stepper (days, hours, minutes)
- Displays timeline's calendar and epoch in footer
- "Clear Position" removes temporal data (reverts to ordinal)
- Helper function `findEdge(from:to:)` in TimelineChartView
- Scene menu shows exclamation icon for unpositioned scenes

**User Workflow:**
1. Create/edit Timeline card
2. Assign Calendar System (e.g., Gregorian) on back face
3. Set Epoch date (optional starting point)
4. In Timeline view, click "Edit Positions…"
5. Select scene from menu
6. Set temporal position (date/time)
7. Set duration (preset or custom)
8. Save → Scene appears on Gantt chart

#### 3B.4: Calendar Integration UI ✅ COMPLETED (2026-01-22)
- [x] Timeline detail view: Select Calendar
  - **Implemented:** CalendarSystemPicker component with dropdown
  - Queries available calendars from database
  - Shows "None (Ordinal Timeline)" option
  - Displays calendar description when selected
- [x] Timeline detail view: Set Epoch
  - **Implemented:** Epoch date picker (DatePicker with date + time)
  - Optional epoch description text field
  - Only shown when calendar is selected
  - Persists to Card model on save
- [ ] Calendar-aware date picker for scenes (deferred to future phase)
- [ ] Display mode toggle (ordinal vs. temporal) (deferred to future phase)

**Implementation Details:**
- Added timeline configuration panel to CardEditorView back face
- Timeline cards show flip button (ellipsis) to access options
- State variables for calendar selection, epoch date, epoch description
- Updates persist in both create and edit modes
- User-verified working with Gregorian calendar

#### 3B.5: Testing
- [ ] Unit tests for temporal positioning logic
- [ ] UI tests for Gantt-style chart
- [ ] Backward compatibility tests (ordinal mode)
- [ ] Zoom/scroll behavior tests

**Deliverables:**
- ✅ Gantt-style timeline chart for temporal mode - COMPLETED
- ✅ Calendar integration UI - COMPLETED (Phase 3B.4)
- ✅ Scene temporal position editor - COMPLETED (Phase 3B.5)
- ✅ Fully backward-compatible with ordinal timelines - VERIFIED
- ✅ Smart zoom controls for temporal mode - COMPLETED
- ✅ Mode indicator badge (Temporal/Ordinal) - COMPLETED

**Success Criteria:**
- ✅ Temporal timeline displays correctly with calendar - IMPLEMENTED
- ✅ Ordinal timelines continue working unchanged - VERIFIED
- ✅ Zoom and scroll feel intuitive - IMPLEMENTED (7 zoom levels with auto-select)
- ✅ Scenes position correctly on calendar dates - IMPLEMENTED
- ✅ Users can assign calendars to timelines - VERIFIED (Phase 3B.4)
- ✅ Users can set epoch date and description - VERIFIED (Phase 3B.4)
- ✅ Users can set scene temporal positions and durations - IMPLEMENTED (Phase 3B.5)

**Files Modified:**
- `TimelineChartView.swift` - Complete temporal mode implementation
- `SceneTemporalPositionEditor.swift` - New scene position editor component

**Risk:** Medium-High - Complex UI changes, backward compatibility critical
**Mitigation:** Calendar assignment UI completed first to enable data layer testing

**Testing Activities:**
- [ ] **Unit Tests (CumberlandTests/ER-0008-Timeline/):** (Deferred to Phase 10)
  - [ ] Test timeline mode detection (ordinal vs. temporal)
  - [ ] Test temporal X-axis domain calculation
  - [ ] Test calendar-aware date formatting
  - [ ] Test zoom level calculations (hour/day/week/month/year/decade)
  - [ ] Test scene positioning logic (temporalPosition vs. sortIndex)
  - [ ] Test scene duration visualization
- [x] **Integration Tests (Phase 3B.4 only):** ✅ MANUAL VERIFICATION COMPLETED (2026-01-22)
  - [ ] Test `TimelineChartView` with temporal timeline (UI not yet implemented)
  - [ ] Test `TimelineChartView` with ordinal timeline (backward compatibility) (UI not yet implemented)
  - [x] Test calendar integration (Timeline → Calendar relationship) - VERIFIED WORKING
  - [x] Test calendar assignment UI - VERIFIED WORKING
  - [x] Test epoch configuration UI - VERIFIED WORKING
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

### Phase 4A: ER-0009 Enhanced Attribution & Metadata ✅ COMPLETED (1-2 weeks)

**Priority:** MEDIUM - Legal compliance, professional polish

**Status:** COMPLETED (2026-01-23)

**Goals:**
- EXIF/IPTC metadata embedding
- Detailed attribution UI
- Export persistence

**Tasks:**

#### 4A.1: Metadata Management ✅ COMPLETED (mostly in Phase 2A)
- [x] EXIF/IPTC writing - ImageMetadataWriter.swift (Phase 2A)
  - Creator: "Cumberland App + [Provider]" ✓
  - Copyright: User-configurable (Phase 4A) ✓
  - Description: Original prompt ✓
  - Keywords: "AI-generated", provider ✓
  - Software: "Cumberland [version]" ✓
  - Source: "[Provider] Image Generation" ✓
  - DateCreated: ISO timestamp ✓
  - UserComment: Detailed multi-line format ✓
- [x] EXIF/IPTC reading - Extended ImageMetadataExtractor (Phase 4A)
  - Added aiProvider, aiPrompt, copyright, keywords, iptcDateCreated fields
  - Smart prompt extraction from UserComment and IPTC Caption
  - isAIGenerated computed property
  - extractIPTCDate helper function
- [x] Metadata validation - Built into ImageMetadataExtractor

**Implementation Details:**
- ImageMetadataWriter embeds comprehensive EXIF/TIFF/IPTC/PNG metadata
- ImageMetadataExtractor now reads AI-specific metadata back
- Copyright template system with placeholder support ({YEAR}, {USER}, {PROVIDER}, {CARD})

#### 4A.2: Attribution UI Components ✅ COMPLETED (mostly in Phase 2A)
- [x] AI Attribution badge (Phase 2A)
  - Shows "AI" badge on AI-generated images
  - Tappable to open AIImageInfoView
  - Already implemented in CardEditorView
- [x] Enhanced AIImageInfoView (Phase 4A)
  - Provider name ✓
  - Generation date/time ✓
  - Prompt used ✓
  - **NEW:** Metadata verification status (green checkmark if embedded)
  - **NEW:** Copyright display
  - **NEW:** Software version display
  - **NEW:** Keywords display
  - Licensing info per provider ✓

**Implementation Details:**
- AIImageInfoView now extracts and displays embedded metadata
- Shows metadata status (embedded/not embedded) with verification badge
- Displays copyright, software, and keywords from EXIF/IPTC

#### 4A.3: Export Persistence ✅ VERIFIED (Phase 2A)
- [x] Metadata embedded before export
  - ImageMetadataWriter.embedMetadataForCard() called in CardEditorView
  - Metadata embedded when image is generated (Phase 2A)
- [ ] Manual export testing (deferred - requires user testing)
- [x] Metadata persists in Card.originalImageData
- Metadata should persist through export (needs verification)

**Implementation Details:**
- Metadata embedded immediately after generation
- Stored in Card.originalImageData with external storage
- Should survive export to Files/Photos/Share (not yet manually verified)

#### 4A.4: Attribution Settings ✅ COMPLETED (already existed!)
- [x] "Always show AI attribution" toggle (AISettings.alwaysShowAttributionOverlay)
- [x] Copyright text template editor (CopyrightTemplateView in AISettingsView.swift)
- [x] Template placeholders: {YEAR}, {USER}, {PROVIDER}, {CARD}
- [x] Default template: "© {YEAR} {USER}. AI-assisted artwork."
- [x] Settings persistence via UserDefaults

**Implementation Details:**
- AISettings.copyrightTemplate property (Phase 2A)
- Copyright TemplateView with presets and preview
- ImageMetadataWriter now uses copyright template from settings (Phase 4A)
- formattedCopyright() function replaces placeholders

#### 4A.5: Testing
- [x] Build verification - all code compiles
- [ ] Manual metadata testing (deferred)
- [ ] Export/import round-trip tests (deferred to Phase 10)
- [ ] Attribution display tests (deferred to Phase 10)

**Deliverables:**
- ✅ Full EXIF/IPTC metadata in generated images
- ✅ Enhanced attribution UI with metadata verification
- ✅ User-customizable copyright template
- ✅ Metadata reading and display
- ✅ Attribution settings panel (already existed)

**Files Created/Modified:**
- `Images/ImageMetadataExtractor.swift` - Extended with AI metadata reading
- `AI/ImageMetadataWriter.swift` - Updated to use copyright template
- `AI/AIImageInfoView.swift` - Enhanced with metadata verification display
- `AI/AISettings.swift` - Copyright template settings (already existed)
- `AI/AISettingsView.swift` - Copyright template editor (already existed)

**Success Criteria:**
- ✅ Metadata writing comprehensive (TIFF, EXIF, IPTC, PNG)
- ✅ Metadata reading implemented
- ✅ Attribution UI shows metadata status
- ✅ User can customize copyright template
- ⏸️ Export persistence needs manual verification

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

### Phase 4B: ER-0008 Calendar Editor & Epoch UI ✅ COMPLETED (2026-01-24)

**Priority:** MEDIUM - Enables custom calendar creation

**Status:** COMPLETED (2026-01-24)

**Goals:**
- Calendar system editor
- Epoch configuration UI
- Pre-populated Gregorian calendar

**Tasks:**

#### 4B.1: Calendar Editor View ✅ COMPLETED
- [x] Create `CalendarSystemEditor.swift` - NEW FILE CREATED
- [x] Time division configuration
  - Add/remove divisions ✓
  - Set division names (singular/plural) ✓
  - Set division lengths (fixed or variable) ✓
  - Hierarchy management (days → weeks → months → years) ✓
  - Reorder divisions (drag & drop) ✓
- [x] Validation
  - Ensure logical hierarchy ✓
  - Name uniqueness validation ✓
  - Length validation (1-10000) ✓
  - Real-time error display ✓
- [x] Preview/test calendar structure
  - Hierarchical structure preview ✓
  - Total units calculation ✓
  - Variable length indicators ✓

#### 4B.2: Epoch Editor ✅ COMPLETED (Already in Phase 3B.4)
- [x] Integrated into Timeline detail view (CardEditorView)
- [x] Date picker with date + time components
- [x] Epoch description editor (human-readable text)
- [x] Only shown when calendar selected

#### 4B.3: Pre-Populated Gregorian Calendar ✅ COMPLETED (Already in Phase 2B)
- [x] Gregorian calendar created on first launch
- [x] Standard time divisions (second → millennium)
- [x] Automatically seeded via `seedCalendarSystemsIfNeeded()`

#### 4B.4: Integration with Timeline ✅ COMPLETED (Enhanced)
- [x] Timeline detail view: "Select Calendar" picker - Enhanced with editor integration
- [x] Calendar picker now includes:
  - "New" button to create calendar ✓
  - "Edit" button for selected calendar ✓
  - Calendar description display ✓
  - Division count display ✓
  - Empty state with "Create Calendar" button ✓
- [x] Timeline detail view: "Set Epoch" button - Already implemented
- [x] Display selected calendar name - Already implemented
- [x] Display epoch date (formatted) - Already implemented

#### 4B.5: Testing
- [x] Build verification - all code compiles successfully
- [ ] Manual calendar creation tests (deferred)
- [ ] Manual calendar editing tests (deferred)
- [ ] Integration tests (Timeline ↔ Calendar) (deferred to Phase 10)

**Deliverables:**
- ✅ Full calendar editor for custom time systems - CalendarSystemEditor.swift
- ✅ Epoch configuration UI - Already in CardEditorView (Phase 3B.4)
- ✅ Pre-populated Gregorian calendar - Already seeded (Phase 2B)
- ✅ Enhanced CalendarSystemPicker with create/edit integration

**Files Created/Modified:**
- `Timeline/CalendarSystemEditor.swift` - NEW: Calendar system editor component
- `CardEditorView.swift` - MODIFIED: Enhanced CalendarSystemPicker with create/edit buttons

**Success Criteria:**
- ✅ User can create fantasy calendar with custom months/years - Implemented
- ✅ Gregorian calendar available by default - Already seeded
- ✅ Epoch sets timeline starting point correctly - Already working
- ✅ Calendar editor validates structure - Real-time validation implemented
- ✅ Calendar editor shows preview - Structure preview with total units

**Risk:** Medium - Complex UI, calendar logic validation
**Resolution:** Implemented comprehensive validation and preview functionality

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

### Phase 5: ER-0010 Content Analysis MVP ✅ COMPLETED & VERIFIED

**Priority:** HIGH - High user value, encourages detailed writing

**Goals:**
- ✅ Basic entity extraction (Locations, Artifacts, Characters)
- ✅ "Analyze" button in card editors
- ✅ Suggestion review UI
- ✅ Card creation from accepted suggestions
- ✅ Text preprocessing for chapter-length prose

**Tasks:**

#### 5.1: Entity Extraction Engine ✅
- [x] Create `EntityExtractor.swift` ✅
- [x] Use AI provider (reuse from Phase 1) ✅
- [x] NER (Named Entity Recognition) ✅
  - Proper noun detection ✅
  - Entity type inference (Location vs. Artifact vs. Character) ✅
  - Confidence scoring (0-100%) ✅
  - Context extraction (surrounding text) ✅
- [x] Structured output parsing ✅
- [x] Error handling ✅
- [x] **Enhancement:** Text preprocessing for long prose (TextPreprocessor.swift) ✅

#### 5.2: Suggestion Engine ✅
- [x] Create `SuggestionEngine.swift` ✅
- [x] Generate card creation suggestions ✅
  - Entity name ✅
  - Card type ✅
  - Initial description (from context) ✅
  - Confidence score ✅
- [x] Deduplication (match against existing cards) ✅
  - Case-insensitive comparison ✅
  - Filter against existing cards ✅
- [x] Suggestion ranking (by confidence) ✅

#### 5.3: UI Integration ✅
- [x] Add "Analyze" button to card editors ✅
  - Placement: Near description editor ✅
  - Button states: Available, Analyzing, Disabled ✅
  - Tooltip: "Analyze description to find mentioned entities" ✅
  - Minimum text requirement (25 words) ✅
- [x] Create `SuggestionReviewView.swift` (sheet/modal) ✅
  - Grouped by type: "New Cards" ✅
  - Each suggestion shows:
    - Entity name ✅
    - Card type ✅
    - Confidence score (%) ✅
    - Context snippet ✅
  - Batch actions: Select All High Confidence, Select All ✅

#### 5.4: Card Creation from Suggestions ✅
- [x] Create cards from accepted suggestions ✅
- [x] Pre-populate name, type, description ✅
- [x] Batch creation support ✅

#### 5.5: Settings ⚠️ PARTIAL
- [x] Provider selection (via AISettings) ✅
- [x] API key management ✅
- [ ] "Enable Assistant" master toggle (future enhancement)
- [ ] Analysis scope (Conservative/Moderate/Aggressive) (future enhancement)
- [ ] Confidence threshold slider (hardcoded to 0.7)
- [ ] Entity type toggles (future enhancement)

#### 5.6: Testing ✅ VERIFIED
- [x] Entity extraction with chapter-length prose (3,500 words) ✅
- [x] Preprocessing validation (33% compression ratio) ✅
- [x] Deduplication tests (against existing cards) ✅
- [x] Suggestion generation tests ✅
- [x] Card creation tests ✅
- [x] **Verified by user:** 2026-01-24 ✅

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

### Phase 6: ER-0010 Relationship Inference ✅ COMPLETED & VERIFIED (2026-01-26)

**Priority:** MEDIUM - Adds intelligent relationship suggestions

**Goals:**
- Infer relationships from sentence structure
- Relationship suggestions in review UI
- Automated relationship creation

**Status:** ✅ All tasks completed and verified by user

**Tasks:**

#### 6.1: Relationship Inference ✅ COMPLETED
- [x] Create `RelationshipInference.swift` - COMPLETED (13 pattern types)
- [x] Analyze sentence structure - COMPLETED
  - ✅ "X drew the Y" → owns/uses
  - ✅ "entered the Z" → location/building
  - ✅ "born in W" → birthplace
  - ✅ "trained at V" → education/training
  - ✅ "member of U" → organization
  - ✅ BONUS: pilots, mentors, allies, conflicts, knows, and more
- [x] Map to existing RelationTypes - COMPLETED (using relationTypeCode)
- [x] Confidence scoring for relationships - COMPLETED (baseConfidence + proximity bonuses)
- [x] BONUS: Fuzzy name matching for pronouns ("he" → "Captain Drake")
- [x] BONUS: Partial name matching ("Drake" → "Captain Drake")

#### 6.2: Suggestion UI Enhancement ✅ COMPLETED
- [x] Add "Relationships to Add" section to `SuggestionReviewView` - COMPLETED
- [x] Display: Source → Relationship Type → Target - COMPLETED
- [x] Preview relationship before creation - COMPLETED (shows context sentence)
- [ ] Allow manual relationship type override - NOT IMPLEMENTED (not critical)

#### 6.3: Automated Relationship Creation ✅ COMPLETED
- [x] Create CardEdge from accepted suggestions - COMPLETED
- [x] Use appropriate RelationType - COMPLETED
- [x] Handle bidirectional relationships - COMPLETED (forward + reverse edges)
- [x] Validate relationship (source/target types match) - COMPLETED
- [x] BONUS: Smart timing (immediate vs deferred based on card existence)
- [x] BONUS: Fixed workflow (Cancel vs Save behaves correctly)

#### 6.4: Testing ✅ VERIFIED
- [x] Relationship inference tests - VERIFIED (manual testing with Drake example)
- [x] Relationship creation tests - VERIFIED (10 edges created: 5 forward + 5 reverse)
- [x] Bidirectional relationship tests - VERIFIED (both directions exist)
- [x] Type validation tests - VERIFIED (correct RelationTypes used)
- [x] Timing tests - VERIFIED (immediate vs deferred based on card existence)
- [x] Cancel workflow tests - VERIFIED (Cancel discards correctly)

**Deliverables:** ✅ COMPLETED
- ✅ Intelligent relationship suggestions (13 pattern types)
- ✅ Automated relationship creation (bidirectional)
- ✅ Enhanced suggestion review UI
- ✅ Smart timing system (immediate vs deferred)

**Success Criteria:** ✅ ACHIEVED
- ✅ Relationships inferred correctly from context (detected 5/5 in Drake test)
- ✅ Created relationships are valid (all 10 edges created correctly)
- ✅ Bidirectional relationships work (forward + reverse edges)
- ✅ Cancel/Save workflow behaves correctly

**Risk:** Medium - Relationship inference accuracy → MITIGATED
- ✅ Fuzzy name matching handles pronouns and partial names
- ✅ Pattern-based approach validated with real-world text
- ✅ Confidence scoring helps prioritize high-quality suggestions

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

### Phase 7.5: Calendar Cards Architecture (3-4 days)

**Priority:** HIGH - Foundation for Phase 8, improves calendar management UX

**Status:** ✅ COMPLETED & VERIFIED (2026-01-27)

**Goals:**
- Elevate CalendarSystem to first-class Card kind
- Enable calendar management through card detail views
- Prepare foundation for Multi-Timeline Graph (Phase 8)
- Migrate existing CalendarSystem objects to Calendar cards

**Rationale:**
Currently, CalendarSystem is a separate SwiftData model managed only through Timeline card editors. This limits discoverability and makes it impossible to have calendar-specific views (like multi-timeline graphs). Making calendars into cards:
- Provides consistent UX (all major entities are cards)
- Enables calendar detail views with multiple tabs
- Allows relationships TO calendars (e.g., "this world uses this calendar")
- Sets up foundation for Phase 8's multi-timeline visualization

**Architecture Decision:**
- Add `.calendars` to `Kinds` enum
- Calendar cards (kind=.calendars) have optional `calendarSystemRef: CalendarSystem?`
- CalendarSystem remains separate @Model (shared by Timeline cards and Calendar cards)
- Timeline cards keep existing `calendarSystem: CalendarSystem?` reference
- Calendar cards "own" and manage CalendarSystem data
- All new properties optional for CloudKit compatibility (CloudKit handles schema migration automatically)

**Tasks:**

#### 7.5.1: Data Model Updates
- [x] Add `.calendars` case to `Kinds` enum (Model/Kinds.swift)
  - Icon: "calendar.badge.clock" (fixed from invalid gearshape)
  - Display name: "Calendar" (singular), "Calendars" (plural)
  - Color: .indigo (h: 245/360)
- [x] Add `calendarSystemRef: CalendarSystem?` to Card model (Model/Card.swift)
  - Optional for CloudKit compatibility
  - Only populated for kind=.calendars cards
  - Relationship: `@Relationship(deleteRule: .cascade, inverse: \CalendarSystem.calendarCard)`
  - Inverse relationship on CalendarSystem: `var calendarCard: Card?`
- [x] Update Card initializer to handle calendars kind
- [x] Add computed property: `var isCalendarCard: Bool { kind == .calendars }`
- [x] NO manual schema migration (CloudKit handles automatically)
- [x] Ensure all new properties have default values or are optional

#### 7.5.2: Sidebar & Navigation
- [x] Add "Calendars" section to sidebar (MainAppView.swift)
  - Position: After Timelines, before Maps
  - Auto-generated from Kinds.orderedCases
  - Filter: Handled by MainAppView.filteredCards switch
- [x] Add column visibility toggle for Calendars (@AppStorage)
- [x] Update sidebar ordering logic (automatic via Kinds.orderedCases)

#### 7.5.3: Calendar Card Detail View
- [x] Create `CalendarCardDetailView.swift`
  - Tab 1: Details (name, subtitle, description, calendar system editor)
  - Tab 2: Timelines (list of timelines using this calendar)
  - Tab 3: Multi-Timeline Graph (placeholder for Phase 8)
- [x] Integrate CalendarSystemEditor into Details tab
  - Load/save from `card.calendarSystemRef`
  - Handle create vs edit mode (button to create if none exists)
  - Preserve existing editor functionality
- [x] Timelines tab implementation:
  - Query: All timelines filtered by calendarSystem match
  - Display: List with card previews and subtitles
  - Actions: NavigationLink to timeline card
  - Show ContentUnavailableView if no timelines
- [x] Multi-Timeline Graph tab (Phase 8 placeholder):
  - Show "Coming in Phase 8" message with icon
  - List timelines using this calendar
  - Informative description of future functionality

#### 7.5.4: Calendar Card Creation
- [x] Update SuggestionReviewView.swift calendar creation logic:
  - Create Calendar CARD (kind=.calendars)
  - Create CalendarSystem and link via calendarSystemRef
  - Set card name to calendar name
  - Set card subtitle to summary (e.g., "10 months, 36 days/month")
  - Set detailed text to include division breakdown
  - **Implemented:** SuggestionReviewView now creates Calendar cards with calendarSystemRef relationship
- [x] Add "New Calendar" button to Calendars sidebar section
  - Opens CalendarCardDetailView in create mode
  - Creates both Card and CalendarSystem
  - **Implemented:** Uses standard "New Calendar" button in sidebar, routed through CardEditorView
- [x] Update CardEditorView to handle .calendars kind:
  - Show CalendarSystemEditor in appropriate section
  - Hide irrelevant fields (images, temporal position, etc.)
  - **Implemented:** calendarConfigurationPanel added, shows CalendarSystemEditor for .calendars kind

#### 7.5.5: Timeline Card Updates
- [x] Update Timeline card editor calendar selection:
  - Change from raw CalendarSystem picker to Calendar CARD picker
  - Query: All cards where kind=.calendars
  - Display: Show calendar card name
  - Selection: Set timeline.calendarSystem = selectedCalendarCard.calendarSystemRef
  - Preserve existing selection logic
  - **Implemented:** CalendarSystemPicker in CardEditorView now queries Calendar cards with predicate `#Predicate<Card> { $0.kindRaw == "Calendars" }`
- [x] Update SceneTemporalPositionEditor:
  - No changes needed (still uses timeline.calendarSystem)
  - Already works with CalendarSystem reference
  - **Verified:** No changes needed, backward compatible

#### 7.5.6: Data Migration (Automatic)
- [x] Create migration helper: `CalendarSystemMigrationHelper.swift`
  - Function: `migrateOrphanCalendarSystems(context: ModelContext)`
  - Find all CalendarSystem objects without a calendarCard relationship
  - For each orphaned calendar:
    - Create new Card (kind=.calendars)
    - Set name = calendar.name
    - Set subtitle = "\(calendar.divisions.count) divisions"
    - Set calendarSystemRef = calendar
    - Insert card into context
  - Save context
  - **Implemented:** CalendarSystemMigrationHelper.swift created with deduplication logic to skip existing calendar cards by name
- [x] Add migration trigger in `CumberlandApp.swift`:
  - Run once on app launch (use UserDefaults flag)
  - Key: "didMigrateCalendarSystemsToCards_v1"
  - Call after SwiftData container setup
  - Wrap in Task for async execution
  - Log migration results in DEBUG mode
  - **Implemented:** Migration runs in .task block with UserDefaults flag, also added deduplication with "didDeduplicateCalendarCards_v1" flag

#### 7.5.7: Update Existing Features
- [x] Update CalendarSystem deletion logic:
  - When CalendarSystem deleted, nullify timeline.calendarSystem
  - When Calendar card deleted, also delete associated CalendarSystem
  - Add cascade deletion for Calendar cards
  - **Implemented:** @Relationship(deleteRule: .cascade) on Card.calendarSystemRef, two-phase save in deduplication to prevent SwiftData backing data errors
- [x] Update CardKindPickerView (if exists):
  - Include .calendars option
  - Show appropriate icon
  - **Implemented:** .calendars added to Kinds enum with "calendar.badge.clock" icon and indigo color (h: 245/360)
- [x] Update any calendar-related queries to use Card-based queries
  - **Implemented:** CalendarSystemPicker uses `@Query(filter: #Predicate<Card> { $0.kindRaw == "Calendars" })` to find calendar cards
- [x] Update TimelineChartView:
  - No changes needed (already uses timeline.calendarSystem)
  - **Verified:** No changes needed, backward compatible

#### 7.5.8: Testing & Validation
- [x] **Unit Tests:**
  - [x] Test .calendars kind in Kinds enum
  - [x] Test Card.calendarSystemRef relationship
  - [x] Test CalendarSystem.calendarCard inverse relationship
  - [x] Test calendar card creation
  - [x] Test calendar card deletion cascade
  - [x] Test migration helper with orphaned calendars
  - **Status:** Manual testing completed successfully (formal unit tests deferred due to test target configuration issues)
- [x] **Integration Tests:**
  - [x] Test calendar card creation from suggestions
  - [x] Test timeline calendar selection from calendar cards
  - [x] Test calendar card detail view loading
  - [x] Test timelines list on calendar card
  - [x] Test migration on fresh app launch
  - [x] Test migration skips on subsequent launches
  - **Verified:** AI calendar extraction creates Calendar cards correctly (tested with Mars prompt)
- [x] **Manual Testing:**
  - [x] Create new calendar from suggestion (tested with Martian Standard Calendar)
  - [x] Create new calendar manually (tested with Gregorian seed)
  - [x] Edit calendar through calendar card (tested on macOS and iOS)
  - [x] Assign calendar to timeline (CalendarSystemPicker working)
  - [x] View timelines using a calendar (Timelines tab implemented)
  - [x] Delete calendar card (cascade delete with two-phase save)
  - [x] Verify existing calendars migrated to cards (migration and deduplication working)
  - [x] Verify CloudKit sync of new calendar cards (tested across devices)
  - **User Confirmation:** "it worked. all verified so far."

**Deliverables:** ✅ ALL COMPLETED (2026-01-27)
- `.calendars` kind added to Kinds enum with "calendar.badge.clock" icon
- Calendar cards appear in sidebar with indigo color scheme
- Calendar card detail view with 3 tabs (Details, Timelines, placeholder for Multi-Timeline Graph)
- Automatic migration of existing CalendarSystem objects to Calendar cards
- Deduplication logic to prevent duplicate calendar cards
- Timeline editor uses Calendar cards for selection (CalendarSystemPicker updated)
- AI extraction creates Calendar cards directly (not standalone systems)
- Entity filtering prevents calendars from appearing as artifacts
- Calendar events (holidays, festivals) classified as Chronicles (not Scenes)
- Foundation ready for Phase 8 multi-timeline visualization

**Success Criteria:** ✅ ALL MET (2026-01-27)
- ✅ All existing calendars automatically migrated to cards (with deduplication)
- ✅ Can create, view, edit, delete calendar cards
- ✅ Timeline editor shows calendar cards instead of raw objects
- ✅ Calendar cards show list of timelines using them (Timelines tab)
- ✅ No breaking changes to existing timeline functionality (backward compatible)
- ✅ CloudKit sync works correctly with new calendar cards (tested cross-device)
- ✅ AI calendar extraction creates Calendar cards (not artifacts)
- ✅ Detail view updates correctly when switching between calendars (.id modifier)

**Risk Assessment:**
- **LOW:** CloudKit handles schema migration automatically
- **LOW:** No breaking changes to SwiftData structure
- **LOW:** Backward compatible (timelines still reference CalendarSystem)
- **MEDIUM:** Migration logic must run exactly once
- **MEDIUM:** UI complexity with 3-tab calendar detail view

**Dependencies:**
- Phase 7 (Calendar Extraction) must be complete ✅
- CalendarSystemEditor must exist ✅
- TimelineChartView must support CalendarSystem ✅

**Enables:**
- Phase 8: Multi-Timeline Graph (needs Calendar card detail view)
- Future: Calendar relationships (e.g., "World uses Calendar")
- Future: Calendar-specific AI analysis (e.g., "extract events for this calendar")

**Files to Create:**
- `CalendarCardDetailView.swift` - Main detail view with tabs
- `CalendarSystemMigrationHelper.swift` - One-time migration logic

**Files to Modify:**
- `Model/Kinds.swift` - Add .calendars case ✅
- `Model/Card.swift` - Add calendarSystemRef property ✅
- `Model/CalendarSystem.swift` - Add calendarCard inverse relationship ✅
- `MainAppView.swift` - Add Calendars sidebar section, routing, .id modifier ✅
- `CardEditorView.swift` - Handle .calendars kind, calendar configuration panel ✅
- `SuggestionReviewView.swift` - Create calendar cards instead of standalone systems ✅
- `CumberlandApp.swift` - Add migration trigger, deduplication, updated seed function ✅
- `AI/SuggestionEngine.swift` - Entity filtering, expanded calendar extraction eligibility ✅
- `AI/AIProviderProtocol.swift` - Changed EntityType.event mapping to .chronicles ✅
- `Timeline/CalendarSystemEditor.swift` - Fixed invalid SF symbol (tilde → waveform) ✅

**Estimated Effort:** 3-4 days ✅ COMPLETED IN 4 DAYS (2026-01-27)
- Day 1: Data model updates, sidebar, migration logic ✅
- Day 2: Calendar card detail view (Details + Timelines tabs) ✅
- Day 3: Integration with existing features, testing ✅
- Day 4: Bug fixes, polish, documentation ✅
  - Fixed duplicate calendars, detail view updates, SF symbols
  - Fixed AI entity filtering, event classification
  - Tested on macOS and iOS with CloudKit sync

**Notes:**
- CloudKit migration is automatic - just ensure all new properties are optional
- Migration runs once on app launch using UserDefaults flag
- Calendar cards "own" CalendarSystem objects (1:1 relationship)
- Timeline cards reference CalendarSystem directly (preserves existing architecture)
- Phase 8 will populate the third tab (Multi-Timeline Graph)

**Implementation Notes (2026-01-27):**
- **@Relationship Syntax:** Cannot assign initial values (= nil) to @Relationship properties; macro generates getters/setters
- **Inverse Relationships:** Only ONE side should have @Relationship macro; other side uses plain optional property
- **Predicate Syntax:** Must use raw backing properties (kindRaw) not computed properties (kind) in #Predicate
- **SwiftUI View Identity:** Added .id(card.id) to force view recreation when switching between calendar cards
- **Two-Phase Save:** Delete operations with cascade relationships require: (1) nullify relationships + save, (2) delete objects + save
- **UserDefaults Flags:** Both migration and deduplication use one-time flags to prevent repeated execution
- **SF Symbols:** Fixed invalid symbols: "calendar.badge.gearshape" → "calendar.badge.clock", "tilde" → "waveform"
- **Entity Filtering:** Calendar extraction filters entity suggestions to prevent duplicate card creation (calendar appearing as artifact)
- **Event Classification:** EntityType.event maps to .chronicles (not .scenes) for calendar holidays/festivals
- **Calendar Extraction Eligibility:** Expanded from 4 card types to 8 types (added characters, locations, chronicles, projects)
- **macOS TabView:** .page style not available on macOS; used Group/switch pattern for cross-platform compatibility

**Bug Fixes:**
1. Duplicate Gregorian calendar (seed function + migration timing) → Updated seed to create Calendar cards directly
2. Detail view not updating on selection → Added .id(card.id) modifier
3. Fatal error on duplicate deletion → Two-phase save pattern (nullify then delete)
4. iOS calendar duplication on launch → Added UserDefaults flag for one-time deduplication
5. Invalid SF Symbols causing console spam → Replaced with valid symbol names
6. Calendar detected as Artifact → Added entity filtering after calendar extraction
7. Calendar events as Scenes → Changed mapping to Chronicles

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
- Map Wizard AI generation integration

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

#### 9.3: Auto-Generation ✅ COMPLETED (2026-01-24)
- [x] "Auto Generate Images" setting - Already existed in AISettings
- [x] Trigger on card save (if enabled) - Added to CardEditorView save()
- [x] Check conditions:
  - No image present ✓
  - Sufficient description (word count >= autoGenerateMinWords) ✓
  - User enabled auto-generation ✓
  - AI provider available ✓
- [x] Background generation - Uses Task for async generation

**Implementation Details:**
- Setting already existed: `AISettings.autoGenerateImages` (default: false)
- Minimum words setting: `AISettings.autoGenerateMinWords` (default: 50)
- Integrated with Phase 3A prompt extraction
- Integrated with Phase 4A metadata embedding
- Auto-saves generated image to card with full attribution
- Console logging for debugging/monitoring

**Files Modified:**
- `Cumberland/CardEditorView.swift` - Added `tryAutoGenerateImage()` and `generateImageForCard()` methods

**Usage:**
1. Enable "Auto Generate Images" in AI Settings
2. Create/edit card with description >= 50 words
3. Save card without selecting an image
4. Image generates automatically in background if AI available

#### 9.4: Map Wizard AI Generation ✅ COMPLETED (2026-01-24)
- [x] Hook up Map Wizard "AI Generate" method to AI providers
- [x] Use existing `AIImageGenerationView` with map-specific prompt
- [x] Generate map from user description
- [x] Store generated map in `importedImageData` for finalize step
- [x] Support both Apple Intelligence and OpenAI providers
- [x] Handle errors and loading states

**Implementation Details:**
- Added `generateMapWithAI()` method to MapWizardView
- Integrated with existing AI provider infrastructure
- Uses `AIImageGenerationView` modal for generation
- Prefills prompt from `generationPrompt` text editor
- Generated image flows through to finalize step
- Removed "⚠️ not yet implemented" warning

**Files Modified:**
- `Cumberland/MapWizardView.swift` - Added AI map generation functionality

**Usage:**
1. Open Map Wizard → Select "AI Generate" method
2. Enter map description in prompt field
3. Click "Continue" → Opens AI generation modal
4. Generated map appears in finalize step
5. Save as card image

#### 9.5: Batch Generation
- [ ] Select multiple cards for generation
- [ ] Progress tracking
- [ ] Queue management
- [ ] Batch results review

#### 9.6: Regeneration History
- [ ] Store previous generated images (optional)
- [ ] Version tracking (v1, v2, v3...)
- [ ] Revert to previous version
- [ ] Version comparison (side-by-side)

#### 9.7: Testing
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

