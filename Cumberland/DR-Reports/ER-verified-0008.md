# Enhancement Requests (ER) - Batch: ER-0008, ER-0009, ER-0010

This file contains verified enhancement requests for the major AI and Timeline features.

**Batch Status:** ✅ All Verified (3/3)

---

## ER-0008: Time-Based Timeline System with Custom Calendars and Multi-Timeline Visualization

**Status:** ✅ Verified
**Component:** Timeline System, Card Model, TimelineChartView
**Priority:** High
**Date Requested:** 2026-01-20
**Date Implemented:** 2026-01-28
**Date Verified:** 2026-01-30

**Rationale:**

The current Timeline system uses simple ordinal ordering (1, 2, 3...) which works well for compact visualizations but cannot represent actual temporal relationships. Writers need to:

1. **Place scenes on real timelines** spanning hours, days, months, years, or millennia
2. **Support custom calendar systems** for fantasy/sci-fi worlds with non-standard time divisions
3. **Visualize multiple timelines** sharing a common calendar to show parallel events
4. **Maintain backward compatibility** with existing ordinal-based timelines

This enhancement transforms Timelines from simple sequence lists into true temporal visualization tools, enabling writers to track complex world events across custom time systems.

**Implementation Summary (2026-01-28):**

**✅ Implemented Features (Phases 1-8):**

1. **Calendar System Model** (Phase 1A & 4)
   - `CalendarSystem` model with SwiftData persistence
   - Custom time divisions (moments, hours, days, months, years, etc.)
   - Variable-length divisions support
   - Eras and festivals tracking
   - Gregorian calendar template

2. **Calendar Editor UI** (Phase 4)
   - `CalendarEditorView` with comprehensive editing
   - Time division management (add, edit, reorder, delete)
   - Era and festival management
   - Calendar system selection for Timelines
   - Epoch date and description configuration

3. **Timeline-Calendar Association** (Phase 1B & 4)
   - Timeline cards can select a calendar system
   - Epoch date defines timeline start/zero point
   - Epoch description for context
   - Backward compatible with ordinal timelines

4. **Temporal Positioning** (Phase 5)
   - Scene cards can have `temporalPosition` (Date)
   - Duration support on CardEdge relationships
   - Temporal positioning on Timeline tracks
   - Flexible workflow (can create scenes before calendars)

5. **Multi-Timeline Graph** (Phase 8)
   - `MultiTimelineGraphView` with SwiftUI Charts
   - Visualizes multiple timelines sharing a calendar
   - Scene bars with temporal positioning
   - Color-coded tracks per timeline
   - Zoom and pan controls
   - Date axis with proper formatting

6. **Calendar Picker UI** (Phase 3)
   - `CalendarPickerView` for selecting calendars
   - Used in Timeline editors and AI content analysis
   - Calendar creation workflow integration

7. **AI Calendar Extraction** (Phase 7 - ER-0010 integration)
   - OpenAI GPT-4 extracts calendar structures from text
   - Parses time divisions, eras, festivals
   - Multiple calendar support (can extract several from one text)
   - Confidence scoring

**✅ Files Modified/Created:**
- `Cumberland/Model/CalendarSystem.swift` - Calendar model
- `Cumberland/CalendarEditorView.swift` - Calendar editing UI
- `Cumberland/CalendarPickerView.swift` - Calendar selection UI
- `Cumberland/MultiTimelineGraphView.swift` - Multi-timeline visualization
- `Cumberland/CardEditorView.swift` - Timeline options panel
- `Cumberland/CalendarDetailEditor.swift` - Calendar detail editing
- `Cumberland/Model/Migrations.swift` - Schema migration to AppSchemaV5
- Implementation phases documented in `DR-Reports/IMPLEMENTATION-PHASES-ER-0008-0009-0010.md`

**✅ Unit Tests Complete (2026-01-29):**
- ✅ **42 unit tests created** covering calendar system, temporal positioning, multi-timeline functionality
- ✅ Tests use Swift Testing framework with in-memory SwiftData
- ⚠️ **Manual step required:** Add test files to Xcode project and fix visionOS target
- 📄 See `CumberlandTests/UNIT-TEST-COMPLETION-STATUS.md` for details

**🔄 Integration Testing Deferred to ER-0017:**
- Cross-platform testing (all 4 platforms)
- CloudKit sync testing
- Performance testing with large timelines (100+ scenes)
- UI automation tests

**Verification Completed:**
✅ Create Custom Calendar
✅ Associate Timeline with Calendar
✅ Add Temporal Scenes
✅ Multi-Timeline Visualization
✅ Gregorian Calendar Template
✅ AI Calendar Extraction

---

## ER-0009: AI Image Generation for Cards (Apple Intelligence and Third-Party APIs)

**Status:** ✅ Verified
**Component:** Card Image System, Settings, MapWizard, Image Import
**Priority:** High
**Date Requested:** 2026-01-20
**Date Implemented:** 2026-01-29
**Date Verified:** 2026-01-30
**Related:** ER-0017 (Batch generation and history features moved)

**Rationale:**

Visual inspiration is crucial for worldbuilding and narrative design, but writers often lack the artistic skills or resources to create custom imagery for their characters, locations, vehicles, and other story elements. AI image generation can:

1. **Provide visual inspiration** for characters, locations, vehicles, and other story elements
2. **Encourage detailed descriptions** by rewarding descriptive text with generated images
3. **Accelerate worldbuilding** by visualizing concepts quickly
4. **Maintain writer ownership** by generating only images (not text), preserving copyright claims

**CRITICAL CONSTRAINT:** AI must NEVER be used for text generation in this app. Text generation raises copyright and ownership questions that are fundamentally incompatible with the creative writing process. This enhancement is **images only**.

**Implementation Summary (2026-01-29):**

**✅ Implemented Features (Phases 1-9.4):**

1. **Apple Intelligence Integration** (Phase 2A)
   - Full Image Playground integration via `.imagePlaygroundSheet`
   - On-device, privacy-preserving image generation
   - Native iOS/macOS support (18.2+/15.2+)

2. **OpenAI/DALL-E 3 Integration** (Phase 9.1)
   - Complete DALL-E 3 API client in `OpenAIProvider.swift`
   - GPT-4 for content analysis
   - Secure API key storage in Keychain
   - Rate limiting and error handling

3. **Multi-Provider Architecture** (Phase 2B & 9.2)
   - `AIProviderProtocol` for unified provider interface
   - `AIProviderRegistry` for provider management
   - Separate provider selection for image generation and content analysis
   - Provider metadata display (models, rate limits, licensing)

4. **Provider Configuration UI** (Phase 9.2)
   - `AISettingsPane` in Settings with full provider management
   - API key input with show/hide toggle
   - Provider availability indicators
   - Model and capability information display

5. **Smart Prompt Extraction** (Phase 3A)
   - Automatic prompt generation from card name + subtitle + description
   - Card-type-aware prompt prefixes
   - Integrated into both Apple Intelligence and OpenAI providers

6. **Auto-Generation** (Phase 9.3)
   - "Auto Generate Images" setting in AISettings
   - Triggers on card save if conditions met:
     * No existing image
     * Description >= minimum words (default: 50)
     * AI provider available
   - Background generation with full attribution

7. **Map Wizard AI Generation** (Phase 9.4)
   - "AI Generate" method fully implemented in MapWizardView
   - Uses `AIImageGenerationView` modal
   - Supports both Apple Intelligence and OpenAI
   - Generated maps flow into finalize step

8. **Attribution & Metadata** (Phase 4A)
   - `AIImageMetadata` embedded in PNG EXIF data
   - Tracks: prompt, provider, model, timestamp, software
   - Automatic attribution on generation
   - Export preserves metadata

**✅ Files Modified/Created:**
- `Cumberland/AI/OpenAIProvider.swift` - DALL-E 3 and GPT-4 integration
- `Cumberland/AI/AIProviderProtocol.swift` - Provider interface
- `Cumberland/AI/AIProviderRegistry.swift` - Provider management
- `Cumberland/AI/AISettings.swift` - Settings with split providers
- `Cumberland/AI/KeychainHelper.swift` - Secure API key storage
- `Cumberland/AI/AppleIntelligenceProvider.swift` - Image Playground integration
- `Cumberland/SettingsView.swift` - AISettingsPane UI (lines 849-1158)
- `Cumberland/CardEditorView.swift` - Auto-generation on save
- `Cumberland/MapWizardView.swift` - AI map generation
- `Cumberland/AI/AIImageMetadata.swift` - EXIF metadata embedding

**✅ Unit Tests Complete (2026-01-29):**
- ✅ **35+ unit tests created** covering AI providers, workflows, prompts, attribution
- ✅ Tests use Swift Testing framework with in-memory SwiftData
- ⚠️ **Manual step required:** Add test files to Xcode project and fix visionOS target
- 📄 See `CumberlandTests/UNIT-TEST-COMPLETION-STATUS.md` for details

**🔄 Features Moved to ER-0017:**
- Phase 9.5: Batch Generation (select multiple cards, queue management)
- Phase 9.6: Regeneration History (version tracking, restore previous)
- Phase 9.7: Integration Testing (cross-platform, CloudKit sync, performance)
- Phase 10: Polish, Documentation, UI automation

**Why Split:**
ER-0009 Phases 1-9.4 provide complete, usable AI image generation functionality. The deferred features (batch processing, history management, comprehensive testing) are power-user enhancements that can be implemented independently without blocking ER-0009 verification.

**Verification Completed:**
✅ Apple Intelligence Image Generation
✅ OpenAI DALL-E 3 Image Generation
✅ Auto-Generation
✅ Map Wizard AI Generation
✅ Multi-Provider Switching
✅ Settings & Configuration

---

## ER-0010: AI Assistant for Content Analysis and Structured Data Extraction

**Status:** ✅ Verified
**Component:** Card Editors, AI System, Relationship Manager, Settings
**Priority:** High
**Date Requested:** 2026-01-20
**Date Implemented:** 2026-01-28
**Date Verified:** 2026-01-30

**Rationale:**

Writers create rich descriptive text about their worlds, characters, and scenes, but manually extracting structured data (locations mentioned, artifacts described, rules implied) is tedious and error-prone. AI can analyze text the writer has already written to:

1. **Identify worldbuilding elements** mentioned in descriptions (locations, artifacts, vehicles, buildings, rules)
2. **Suggest relationships** to existing cards
3. **Suggest creation of new cards** for mentioned entities that don't yet exist
4. **Generate calendar systems** from temporal descriptions (complements ER-0008)
5. **Maintain consistency** across the project by surfacing relationships

**CRITICAL DISTINCTION:** The AI analyzes and extracts structure from text **the writer already wrote**. It does not generate narrative content. This preserves copyright and ownership while providing intelligent assistance.

**Implementation Summary (2026-01-28):**

**✅ Implemented Features (Phases 1-7):**

1. **Entity Extraction System** (Phase 3)
   - AI-powered entity identification from card descriptions
   - Support for: Characters, Locations, Buildings, Artifacts, Vehicles, Organizations, Events, Historical Events
   - Confidence scoring for each extracted entity
   - Context snippets for user review

2. **Analyze Button UI** (Phase 2)
   - "Analyze with AI" button in CardEditorView
   - Available for all card types with descriptions
   - Progress indicator during analysis
   - Results displayed in suggestions panel

3. **Suggestion Review System** (Phase 4)
   - `ContentAnalysisSuggestionsView` for reviewing extracted entities
   - Side-by-side display: suggestions vs existing matches
   - Confidence indicators with color coding
   - Context snippets for each suggestion
   - Bulk actions (select all, create all, ignore all)

4. **Card Creation from Suggestions** (Phase 4)
   - One-click card creation from suggestions
   - Automatic type mapping (entity type → card kind)
   - Initial content populated from extracted context
   - Relationship creation between source card and new cards

5. **Duplicate Detection** (Phase 5)
   - Match suggestions against existing cards
   - Fuzzy name matching to identify duplicates
   - Show existing matches with "Already Exists" indicator
   - Allow creating relationships to existing cards instead of duplicates

6. **Calendar Extraction** (Phase 7)
   - Extract calendar systems from narrative descriptions
   - Parse time divisions (hours, days, months, years, custom units)
   - Identify eras, festivals, and special events
   - Multiple calendar support (can extract several from one text)
   - Create calendar cards from extracted data

7. **AI Provider Integration** (Phase 1 & 3)
   - Shared infrastructure with ER-0009
   - Separate provider selection for analysis vs. image generation
   - Apple Intelligence and OpenAI GPT-4 support
   - Async analysis with proper error handling

**✅ Files Modified/Created:**
- `Cumberland/ContentAnalysisSuggestionsView.swift` - Suggestion review UI
- `Cumberland/CardEditorView.swift` - "Analyze with AI" button integration
- `Cumberland/AI/AppleIntelligenceProvider.swift` - Entity extraction implementation
- `Cumberland/AI/OpenAIProvider.swift` - GPT-4 analysis, calendar extraction
- `Cumberland/AI/AIProviderProtocol.swift` - AnalysisTask and AnalysisResult types
- `Cumberland/AI/AISettings.swift` - Analysis settings and provider selection
- Implementation documented in `DR-Reports/IMPLEMENTATION-PHASES-ER-0008-0009-0010.md`

**✅ Unit Tests Complete (2026-01-29):**
- ✅ **45 unit tests created** covering entity extraction, calendar parsing, confidence scoring
- ✅ Tests use Swift Testing framework with in-memory SwiftData
- ⚠️ **Manual step required:** Add test files to Xcode project and fix visionOS target
- 📄 See `CumberlandTests/UNIT-TEST-COMPLETION-STATUS.md` for details

**🔄 Integration Testing Deferred to ER-0017:**
- Integration tests for full analysis workflows
- Cross-platform testing (all 4 platforms)
- Performance testing with long descriptions (1000+ words)
- CloudKit sync testing
- Learning system tests

**Verification Completed:**
✅ Entity Extraction
✅ Card Creation from Suggestions
✅ Duplicate Detection
✅ Calendar Extraction
✅ Apple Intelligence vs. OpenAI
✅ Empty Results Handling

---

*Last Updated: 2026-01-30*
*Status: All 3 ERs verified - Major AI and Timeline features complete!*
