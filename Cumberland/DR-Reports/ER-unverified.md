# Enhancement Requests (ER) - Unverified

This document tracks enhancement requests that are proposed, in progress, or implemented but awaiting user verification.

**Status:** Currently **9 active ERs** (6 Proposed, 0 Implemented - Not Verified, 3 Verified Awaiting Move)

---


## ER-0006: Display Working Indicator During Base Layer Rendering - REOPENED

**Status:** 🔴 Regression - Interior Base Layer Not Showing Indicator
**Component:** MapWizardView, BaseLayerButton (Interior), ToolsTabView
**Priority:** Medium
**Date Originally Verified:** 2026-01-09
**Date Reopened:** 2026-01-10
**Regression Identified:** 2026-01-10

**Regression Description:**

ER-0006 was previously implemented and verified for base layer rendering progress indicators. However, the working indicator is not appearing when generating interior base layers, specifically:
- **Wood floor texture on iPad** is particularly time-consuming
- No progress indicator appears during interior base layer generation
- User experiences frozen UI without feedback
- The implementation may be incomplete for interior base layers or only working for exterior layers

**Original Implementation (2026-01-09):**
- Added `isGeneratingBaseLayer` state to `DrawingCanvasModel`
- Created async wrappers for base layer generation in MapWizardView, BaseLayerButton, ToolsTabView
- Added progress overlays to `drawConfigView` (exterior) and `interiorConfigView`
- Verified for exterior base layers ✅
- **Assumed verified for interior base layers** ❌

**Current Behavior (Regression):**
- **Exterior base layers**: Progress indicator works correctly ✅
- **Interior base layers**: No progress indicator appears ❌
- Wood floor texture generation on iPad takes several seconds with no feedback
- User wonders if app has frozen

**Investigation Needed:**

1. Verify interior base layer code path sets `isGeneratingBaseLayer = true`
2. Check if `BaseLayerButton` interior flow calls async wrappers
3. Verify interior base layer menu items call `applyBaseLayerFillAsync()` not direct `applyFill()`
4. Test all interior fill types (Stone Floor, Wood Floor, Tile, etc.)
5. Specifically test Wood Floor on iPad (reported as slow)

**Possible Root Causes:**

1. **Interior base layer menu** may be calling synchronous `applyFill()` instead of `applyFillAsync()`
2. **Interior base layer button** code path may bypass async wrapper
3. **Interior preset buttons** (Floorplan, Dungeon, Caverns) may not use async approach
4. Progress overlay may not be attached to interior canvas view

**Expected Fix:**

1. Audit all interior base layer trigger points
2. Ensure all call `applyBaseLayerFillAsync()` or equivalent async wrapper
3. Verify `isGeneratingBaseLayer` flag is set/cleared correctly for interior
4. Add specific test case for Wood Floor on iPad
5. Consider adding explicit loading indicator for slow patterns like Wood Floor

**Files to Review:**
- `Cumberland/MapWizardView.swift` - Interior base layer menu items
- `Cumberland/DrawCanvas/BaseLayerButton.swift` - Interior base layer button
- `Cumberland/DrawCanvas/BaseLayerPatterns.swift` - Interior fill pattern generation
- `Cumberland/DrawCanvas/ProceduralPatternView.swift` - Interior pattern rendering

**Test Steps:**

1. Open Map Wizard → Interior/Architectural tab
2. Select Base Layer → Interior → Wood Floor
3. Observe on iPad (slower device more noticeable)
4. **Expected**: Progress indicator appears immediately, shows "Generating Base Layer..."
5. **Actual**: No indicator, appears frozen for several seconds

**Priority:** Medium - Affects user experience on iPad, creates impression of frozen app

---

## ER-0008: Time-Based Timeline System with Custom Calendars and Multi-Timeline Visualization

**Status:** 🔵 Proposed
**Component:** Timeline System, Card Model, TimelineChartView
**Priority:** High
**Date Requested:** 2026-01-20

**Rationale:**

The current Timeline system uses simple ordinal ordering (1, 2, 3...) which works well for compact visualizations but cannot represent actual temporal relationships. Writers need to:

1. **Place scenes on real timelines** spanning hours, days, months, years, or millennia
2. **Support custom calendar systems** for fantasy/sci-fi worlds with non-standard time divisions
3. **Visualize multiple timelines** sharing a common calendar to show parallel events
4. **Maintain backward compatibility** with existing ordinal-based timelines

This enhancement transforms Timelines from simple sequence lists into true temporal visualization tools, enabling writers to track complex world events across custom time systems.

**Current Behavior:**

- **SceneRow** uses simple integer `order` field (1, 2, 3...)
- **TimelineChartView** displays scenes in ordinal sequence along X-axis
- **No temporal positioning** - scenes are evenly spaced regardless of time passage
- **No calendar system** - assumes standard Gregorian calendar implicitly
- **Single timeline view** - cannot compare multiple timelines
- **Relations:**
  - Scene → Timeline: "describes/described-by"
  - Character → Scene: "appears-in/is-appeared-by"
  - Scene → Chapter: "part-of/has-scene"

**Desired Behavior:**

### Phase 1: Time-Based Scene Positioning

- **Gantt-chart style visualization:**
  - X-axis: Timeline (dates/times, not ordinals)
  - Y-axis: Scenes
  - Resources: Characters appearing in scenes (similar to Gantt resource allocation)
- **Scene temporal properties:**
  - Start date/time
  - Optional duration (defaults to minimum visual width)
- **Zoom controls:**
  - Scenes become 1-pixel minimum when zoomed out
  - Scroll controls maintain scope awareness
- **Backward compatibility:**
  - Timelines without calendars continue using ordinal ordering

### Phase 2: Calendar Systems

- **Calendar Card Type:**
  - New subset of "Rules" card type (`kindDetail` or similar)
  - Defines custom time divisions and subdivisions
- **Time Divisions:**
  - **Sub-day:** seconds, minutes, hours (customizable)
  - **Days and weeks:** custom day names, week length
  - **Months:** custom month names, month lengths
  - **Years:** custom year names (e.g., Chinese calendar style)
  - **Longer periods:** decades, centuries, millennia
  - **Eras/Ages:** variable length, named periods
- **Pre-populated Gregorian Calendar:**
  - Default calendar available immediately
  - Standard Earth time divisions
- **Relations:**
  - Timeline → "uses/used-by" ← Calendar

### Phase 3: Epochs

- **Epoch Definition:**
  - Starting point for a timeline
  - Defines "zero" on the calendar
  - Format: date/time in the associated Calendar System
  - Example: "00:00:00 First-Day, Month-of-Awakening, Year-1 of the First Age"
- **Timeline Requirements:**
  - Timeline with Calendar must have an Epoch
  - Epoch is specific to each Timeline
  - Scene positions calculated relative to Epoch

### Phase 4: Multi-Timeline Graph

- **New Visualization:**
  - Shows multiple timelines sharing a Calendar System
  - X-axis: Calendar timeframe (common to all timelines)
  - Y-axis: Multiple timelines (each as a horizontal line)
  - Scenes shown as labeled tickmarks on timeline lines
- **UI Location:**
  - Third tab view on Calendar Card detail page
  - Lists all timelines using this calendar
- **Use Case:**
  - Visualize parallel storylines
  - Track simultaneous world events
  - Compare different character arcs over same period

**Requirements:**

### Data Model Requirements:

1. **Calendar System Model** (subset of Rules card or new model)
   - Time division definitions (configurable hierarchy)
   - Division names and lengths
   - Support for both fixed and variable-length divisions
   - Pre-populated Gregorian calendar

2. **Epoch Model or Properties**
   - Associated with a specific Calendar
   - Stores zero-point date/time in calendar format
   - One Epoch per Timeline (when calendar is associated)

3. **Enhanced Scene Positioning**
   - Current: `order: Int` (ordinal)
   - New: `temporalPosition: Date?` or calendar-specific timestamp
   - Optional: `duration: TimeInterval?` for scene length

4. **New Relation Types**
   - Timeline → "uses/used-by" ← Calendar
   - Timeline → "starts-at" ← Epoch (or Epoch as Timeline property)

### UI Requirements:

5. **Enhanced TimelineChartView**
   - Detect if Timeline has associated Calendar
   - If yes: use temporal positioning (Gantt-style)
   - If no: use current ordinal positioning (backward compatible)
   - Adaptive X-axis: ordinal or temporal
   - Scene minimum width: 1 pixel when zoomed out

6. **Calendar Editor View**
   - Create/edit custom calendar systems
   - Define time divisions and subdivisions
   - Name divisions (days, months, years, etc.)
   - Preview calendar structure

7. **Epoch Editor**
   - Set Timeline starting date/time
   - Calendar-aware date picker
   - Display in associated Calendar's format

8. **Multi-Timeline Graph View**
   - Third tab on Calendar card detail
   - List all timelines using this calendar
   - Horizontal timeline visualization
   - Scene tickmarks with labels
   - Synchronized X-axis (calendar time)

### Backward Compatibility Requirements:

9. **Existing Timelines**
   - Continue working with ordinal ordering
   - No required migration
   - Optional upgrade path to calendar-based

10. **Data Migration Safety**
    - New properties optional (nil-safe)
    - Schema migration for new models
    - Preserve existing Scene order values

**Design Approach:**

### Phase 1: Data Model Foundation

1. **Create Calendar System Model**
   - Extend Rules card type or create dedicated model
   - Define time division schema (JSON or structured SwiftData)
   - Implement Gregorian calendar template

2. **Add Epoch Support**
   - New model or Timeline property
   - Calendar-specific date/time representation
   - Association with Timeline

3. **Enhance Scene Properties**
   - Add optional temporal position
   - Add optional duration
   - Maintain backward compatibility with `order`

4. **New Relation Types**
   - "uses/used-by" for Timeline-Calendar
   - Register in RelationType system

### Phase 2: Core Logic

5. **Calendar System Logic**
   - Date/time parsing and formatting
   - Duration calculations
   - Calendar-aware date arithmetic

6. **Timeline Positioning Logic**
   - Detect calendar association
   - Calculate scene positions (ordinal vs temporal)
   - Handle zoom levels and minimum widths

### Phase 3: UI Implementation

7. **Update TimelineChartView**
   - Conditional rendering (ordinal vs temporal)
   - Gantt-style layout for temporal mode
   - Adaptive X-axis formatting

8. **Calendar Editor Views**
   - Calendar creation/editing
   - Division configuration
   - Preview and validation

9. **Epoch Editor**
   - Date/time picker for calendar
   - Integration with Timeline detail view

10. **Multi-Timeline Graph**
    - New view for Calendar card
    - Timeline aggregation
    - Synchronized visualization

**Components Affected:**

- **Model/Card.swift** - Potential new properties for temporal positioning
- **Model/Migrations.swift** - Schema updates for new models
- **TimelineChartView.swift** - Major enhancements for temporal visualization
- **CardEditorView.swift** - Calendar and Epoch editing UI
- **New: CalendarSystemModel.swift** - Calendar system data model
- **New: EpochModel.swift** - Epoch definition (or Timeline extension)
- **New: CalendarEditorView.swift** - Calendar system editor
- **New: EpochEditorView.swift** - Epoch configuration
- **New: MultiTimelineGraphView.swift** - Multi-timeline visualization
- **RelationType.swift** - New relation types

**Implementation Details:**

*To be filled in during implementation*

**Test Steps:**

*To be defined during implementation planning*

**Notes:**

### Open Design Questions:

1. **Scene Duration:**
   - Should scenes have explicit duration?
   - Default duration value (e.g., 1 hour, 1 scene-unit)?
   - How to handle scenes with unknown/undefined duration?

2. **Calendar Representation:**
   - Store as JSON in Rules card?
   - Dedicated SwiftData model?
   - Hybrid approach (Rules card with structured data)?

3. **Epoch Storage:**
   - Property on Timeline card?
   - Separate Epoch model with relation?
   - Embed in Calendar association?

4. **Multi-Timeline Performance:**
   - Limit number of timelines in multi-view?
   - Lazy loading for large timelines?
   - Aggregation strategies?

5. **Date/Time Formatting:**
   - Custom formatters per calendar?
   - Localization support for custom calendars?
   - Display format preferences?

6. **Zoom Behavior:**
   - Logarithmic vs linear zoom for large time spans?
   - Smart zoom levels (hour, day, month, year, decade, century)?
   - Minimap for context when zoomed in?

### Future Enhancements (Out of Scope for ER-0008):

- Import/export calendar definitions
- Calendar templates library (historical calendars)
- Calendar conversion tools (between systems)
- Recurring events on timelines
- Time-based queries (scenes in date range)
- Timeline analytics (time passage analysis)

### Related Systems:

- **Structure Board** - May benefit from temporal visualization
- **Card Relationships** - Temporal relationships between cards
- **Citations** - Date-based source tracking

### Implementation Phases:

This is a large enhancement that should be implemented incrementally:

1. **Phase 1-A:** Calendar System model and basic editor
2. **Phase 1-B:** Epoch support and Timeline-Calendar association
3. **Phase 2-A:** Enhanced scene temporal positioning
4. **Phase 2-B:** TimelineChartView temporal mode (Gantt-style)
5. **Phase 3:** Multi-Timeline Graph visualization
6. **Phase 4:** Polish, performance optimization, edge cases

---

## ER-0009: AI Image Generation for Cards (Apple Intelligence and Third-Party APIs)

**Status:** 🔵 Proposed
**Component:** Card Image System, Settings, MapWizard, Image Import
**Priority:** High
**Date Requested:** 2026-01-20

**Rationale:**

Visual inspiration is crucial for worldbuilding and narrative design, but writers often lack the artistic skills or resources to create custom imagery for their characters, locations, vehicles, and other story elements. AI image generation can:

1. **Provide visual inspiration** for characters, locations, vehicles, and other story elements
2. **Encourage detailed descriptions** by rewarding descriptive text with generated images
3. **Accelerate worldbuilding** by visualizing concepts quickly
4. **Maintain writer ownership** by generating only images (not text), preserving copyright claims

**CRITICAL CONSTRAINT:** AI must NEVER be used for text generation in this app. Text generation raises copyright and ownership questions that are fundamentally incompatible with the creative writing process. This enhancement is **images only**.

**Current Behavior:**

- **Images imported manually** via file picker, Photos, drag & drop
- **No AI generation** capability
- **Map Wizard** has placeholder for AI generation (not implemented)
- **All card types** support images but require manual sourcing

**Desired Behavior:**

### Core Capabilities:

1. **AI Provider Configuration (Settings)**
   - Default: Apple Intelligence (Image Playground API) - no API key needed
   - Optional: ChatGPT API key
   - Optional: Claude API key (Anthropic)
   - Provider selection per generation or default in settings

2. **Image Generation Modes:**
   - **Manual Generation:** User provides prompt, clicks "Generate Image"
   - **Smart Auto-Generation:** App extracts prompt from card type + description, generates automatically
   - **Semi-Automatic:** "Generate Image" button appears when sufficient description detected

3. **Auto-Generation Settings:**
   - **Auto Generate Images** toggle (off by default)
   - **Only generate for cards without images**
   - **Only generate when sufficient descriptive text available**
   - **Minimum description length** threshold (configurable, e.g., 50 words)

4. **Smart Prompt Extraction:**
   - Use card type (Character, Location, Vehicle, etc.) as context
   - Extract key descriptive phrases from `detailedText`
   - Combine card name + subtitle + relevant description excerpts
   - Generate appropriate image prompt for AI provider

5. **UI Integration:**
   - **Card Detail View:** "Generate Image" button near image area
   - **Map Wizard:** AI Generation tab (already has placeholder)
   - **Batch Generation:** Generate images for multiple cards (optional)
   - **Generation History:** Track generated images, allow regeneration

6. **Generation Feedback:**
   - Progress indicator during generation
   - Success/failure notifications
   - Option to retry with modified prompt
   - Option to discard and try again

**Requirements:**

### Settings Requirements:

1. **AI Provider Settings Panel**
   - Default provider selection (Apple Intelligence, ChatGPT, Claude)
   - API key storage (secure, keychain)
   - API key validation
   - Provider availability check (Apple Intelligence requires iOS 18.2+)

2. **Auto-Generation Settings**
   - "Auto Generate Images" toggle
   - "Minimum Description Length" slider (25-200 words)
   - "Auto-generate only for cards without images" checkbox (always on)
   - "Prompt Prefix" field (optional, e.g., "In the style of fantasy art...")

### Data Model Requirements:

3. **Track AI-Generated Images**
   - Flag on Card: `imageGeneratedByAI: Bool?`
   - AI provider used: `imageAIProvider: String?` (e.g., "AppleIntelligence", "ChatGPT", "Claude")
   - Generation prompt: `imageAIPrompt: String?` (for regeneration)
   - Generation timestamp: `imageAIGeneratedAt: Date?`

4. **Generation Metadata**
   - Store prompts for regeneration
   - Track success/failure
   - Optional: Store multiple generated variants

### AI Integration Requirements:

5. **Apple Intelligence Integration**
   - Use Image Playground API (iOS 18.2+, macOS 15.2+)
   - Native integration, no API key needed
   - On-device processing (privacy-preserving)
   - Fallback for older OS versions

6. **ChatGPT Integration**
   - OpenAI DALL-E API
   - Requires API key
   - Cloud-based generation
   - Handle rate limits and errors

7. **Claude Integration (Anthropic)**
   - Note: As of 2026-01, Claude does not generate images
   - Future-proofing for when/if Anthropic adds image generation
   - May need to use alternative (Stable Diffusion, Midjourney API)

### Prompt Engineering Requirements:

8. **Smart Prompt Extraction**
   - Analyze `card.kind` for context
   - Extract key phrases from `detailedText`
   - Identify visual descriptions (appearance, colors, mood)
   - Ignore non-visual content (dialogue, plot, relationships)
   - Format prompts appropriately for each AI provider

9. **Prompt Templates by Card Type**
   - **Characters:** "Portrait of [name], [description]"
   - **Locations:** "Landscape of [name], [description]"
   - **Buildings:** "Architecture of [name], [description]"
   - **Vehicles:** "Technical illustration of [name], [description]"
   - **Maps:** "Fantasy map of [name], [description]" (Map Wizard)
   - **Artifacts:** "Object illustration of [name], [description]"
   - And so on for all card types

### UI Requirements:

10. **Card Detail View Integration**
    - "Generate Image" button appears when:
      - No image currently set, OR
      - User explicitly wants to regenerate
      - Description meets minimum length threshold
    - Button states: Available, Generating, Unavailable (insufficient description)
    - Tooltip explains why button is disabled

11. **Map Wizard AI Generation Tab**
    - Prompt input field (pre-populated from card description if available)
    - Provider selection
    - "Generate" button
    - Preview generated image
    - Accept/Retry/Discard options

12. **Generation Progress UI**
    - Modal or inline progress indicator
    - "Generating image with [Provider]..."
    - Estimated time (if available from provider)
    - Cancel option

13. **Generated Image Review**
    - Preview before accepting
    - "Use This Image" button
    - "Regenerate" button (reuses prompt)
    - "Edit Prompt & Regenerate" option
    - "Discard" option

### Quality & Safety Requirements:

14. **Description Quality Detection**
    - Minimum word count (configurable, default 50 words)
    - Detect visual descriptions (color words, size words, etc.)
    - Confidence score for prompt quality
    - Warning if description is likely insufficient

15. **Error Handling**
    - Network errors (retry logic)
    - API key invalid
    - Rate limiting (queue and retry)
    - Provider unavailable
    - Content policy violations (inappropriate prompts)

16. **Privacy & Security**
    - API keys stored in Keychain (not in SwiftData)
    - Option to use on-device only (Apple Intelligence)
    - Clear disclosure when data sent to cloud APIs
    - Option to disable AI features entirely

### Attribution & Metadata Requirements:

17. **Image Attribution**
    - **CRITICAL:** All AI-generated images must include proper attribution
    - Attribution text format:
      - Apple Intelligence: "Generated by Apple Intelligence"
      - ChatGPT/DALL-E: "Generated by DALL-E (OpenAI)"
      - Claude/Future: "Generated by [Provider Name]"
    - Attribution storage:
      - Embed in image EXIF/IPTC metadata
      - Store in Card metadata (`imageAIProvider`, `imageAIPrompt`, `imageAIGeneratedAt`)
      - Persist attribution even if image is exported/shared
    - Attribution display:
      - Small text overlay or caption when viewing image
      - Visible in image detail view
      - Include in image info panel

18. **Image Metadata (EXIF/IPTC)**
    - **Creator:** "Cumberland App + [AI Provider]"
    - **Copyright:** User-configurable (default: writer's name/copyright)
    - **Description:** Original prompt used for generation
    - **Keywords:** "AI-generated", card type, card name
    - **Software:** "Cumberland [version]"
    - **Source:** "[AI Provider] Image Generation"
    - **DateCreated:** ISO timestamp of generation
    - **UserComment:** Full generation details JSON (prompt, provider, model version, settings)
    - **ImageHistory:** Track if image has been regenerated (version tracking)

19. **Attribution UI Display**
    - **Card Detail View:**
      - Small badge/label: "AI Generated" with provider icon
      - Tappable for full attribution details
    - **Image Detail/Fullscreen View:**
      - Footer text: "Generated by [Provider] on [Date]"
      - "View Generation Details" button
    - **Image Info Panel:**
      - Provider name
      - Generation date/time
      - Prompt used
      - Model version (if available)
      - Regeneration history (if applicable)

20. **Attribution Persistence**
    - Attribution must survive:
      - Image export (to Files, Photos, etc.)
      - Project export/backup
      - CloudKit sync across devices
      - Image replacement/regeneration
    - Metadata embedded in image file (EXIF/IPTC)
    - Metadata also stored in Card properties (redundancy)

21. **Licensing Information**
    - **Apple Intelligence:**
      - User owns generated images (as of iOS 18.2 policy)
      - Can be used commercially in user's creative work
      - Attribution recommended but not legally required (include anyway)
    - **ChatGPT/DALL-E:**
      - OpenAI grants user rights to generated images (as of 2024 policy)
      - Commercial use permitted
      - Attribution recommended
      - Check current OpenAI terms and include reference
    - **Future Providers:**
      - Display licensing terms in settings when API key is configured
      - Link to provider's terms of service
      - Warn if provider has restrictive licensing

22. **Attribution Settings**
    - **"Always show AI attribution"** toggle (on by default)
    - **Copyright text template** (e.g., "© 2026 [Writer Name]. Image generated by AI.")
    - **Attribution placement** (subtle badge vs. visible caption)
    - **Export behavior:** "Include attribution in exported images" (on by default)

23. **Legal Compliance**
    - Comply with AI provider terms of service (attribution requirements)
    - Comply with App Store guidelines for AI-generated content
    - Transparency about AI usage
    - Clear disclosure to users about generated content
    - Option to disable AI features if user has concerns

24. **Regeneration Tracking**
    - If image is regenerated:
      - Store previous image (optional, user setting)
      - Track generation history (version 1, 2, 3...)
      - Metadata shows regeneration count
      - User can revert to previous version
    - History format in metadata:
      - "Generated 2026-01-20 (v1), Regenerated 2026-01-22 (v2)"

**Design Approach:**

### Phase 1: Apple Intelligence Foundation

1. **Settings UI for AI Configuration**
   - Create AISettings view
   - Provider selection
   - Auto-generation toggle
   - Minimum description threshold

2. **Apple Intelligence Integration**
   - Import ImagePlayground framework (iOS 18.2+)
   - Implement basic image generation
   - Test with simple prompts

3. **UI Integration in Card Detail**
   - Add "Generate Image" button
   - Description quality detection
   - Progress indicator
   - Image preview and acceptance

### Phase 2: Smart Prompt Extraction

4. **Prompt Engineering System**
   - Analyze card type and description
   - Extract visual elements
   - Template-based prompt generation
   - Test with various card types

5. **Description Analysis**
   - Word count
   - Visual keyword detection
   - Quality scoring
   - Feedback to user

### Phase 3: Third-Party API Integration

6. **ChatGPT/DALL-E Integration**
   - OpenAI API client
   - API key management
   - Rate limiting
   - Error handling

7. **Future Provider Support**
   - Plugin architecture for new providers
   - Stable Diffusion
   - Midjourney (if/when API available)

### Phase 4: Auto-Generation & Polish

8. **Auto-Generation Logic**
   - Trigger on card save (if enabled)
   - Check conditions (no image, sufficient description)
   - Background generation
   - Notification on completion

9. **Map Wizard Integration**
   - AI Generation tab implementation
   - Custom prompt input
   - Map-specific prompt templates

10. **Batch Generation (Optional)**
    - Select multiple cards
    - Generate images for all
    - Progress tracking
    - Review generated images

**Components Affected:**

- **Settings/SettingsView.swift** - New AI configuration panel, attribution settings
- **Model/Card.swift** - New properties for AI-generated image metadata, attribution data
- **Model/Migrations.swift** - Schema updates for new properties
- **CardEditorView.swift** - "Generate Image" button integration, attribution display
- **MapWizardView.swift** - AI Generation tab implementation
- **New: AIImageGenerator.swift** - Core AI integration logic, metadata embedding
- **New: AISettings.swift** - Settings data model, attribution preferences
- **New: PromptExtractor.swift** - Smart prompt generation from card data
- **New: AppleIntelligenceProvider.swift** - Apple Intelligence integration
- **New: OpenAIProvider.swift** - ChatGPT/DALL-E integration
- **New: AIProviderProtocol.swift** - Protocol for AI providers
- **New: AIImageGenerationView.swift** - Image generation UI component, attribution display
- **New: DescriptionAnalyzer.swift** - Description quality detection
- **New: ImageMetadataManager.swift** - EXIF/IPTC metadata writing and reading
- **New: AttributionView.swift** - UI component for displaying attribution badges and details
- **New: ImageInfoPanel.swift** - Detailed image info view (prompt, provider, metadata)

**Implementation Details:**

*To be filled in during implementation*

**Test Steps:**

*To be defined during implementation planning*

**Notes:**

### Open Design Questions:

1. **Image Storage:**
   - Store generated images same as imported images (originalImageData)?
   - Keep generation metadata separate?
   - Allow multiple generated variants per card?

2. **Regeneration Strategy:**
   - Overwrite existing AI-generated image?
   - Keep history of generated images?
   - Allow comparison between variants?

3. **Prompt Editing:**
   - Always allow manual prompt editing?
   - Show extracted prompt before generation?
   - Save custom prompts for reuse?

4. **Auto-Generation Triggers:**
   - On card save?
   - On description threshold reached?
   - On user request only?
   - Background vs foreground generation?

5. **Cost Management (Cloud APIs):**
   - Token/credit usage tracking?
   - Warn user about API costs?
   - Limit generations per day?

6. **Image Style Consistency:**
   - Global style settings ("fantasy art", "realistic", etc.)?
   - Per-card style override?
   - Style presets library?

7. **Multi-Platform Considerations:**
   - Apple Intelligence available on macOS 15.2+, iOS 18.2+
   - Fallback for visionOS?
   - Fallback for older OS versions?

8. **Description Analysis Accuracy:**
   - Simple word count sufficient?
   - NLP-based quality detection?
   - User override option?

9. **Attribution Display:**
   - How prominent should attribution be?
   - Subtle badge vs. visible text overlay?
   - Always visible or only on hover/tap?
   - User preference for attribution visibility?

10. **Metadata Export:**
    - Ensure EXIF/IPTC data survives export?
    - Include attribution in exported file names (e.g., "character_AIgen.png")?
    - Export attribution as separate text file alongside image?
    - Handle cases where export format doesn't support metadata?

11. **Regeneration History:**
    - Store all previous versions or just latest?
    - Storage limit (e.g., max 5 versions)?
    - Allow user to delete history to save space?
    - Display version comparison (side-by-side)?

### Implementation Priorities:

**Phase 1 (MVP):**
- Apple Intelligence integration (default provider)
- Manual generation with user-provided prompts
- Card detail view integration
- Basic settings panel
- **Basic attribution:** Provider name, generation date in Card metadata
- **Attribution display:** Simple "AI Generated" badge

**Phase 2 (Smart Features):**
- Smart prompt extraction from descriptions
- Description quality detection
- "Generate Image" button auto-enable
- Map Wizard AI generation tab
- **Enhanced attribution:** EXIF/IPTC metadata embedding
- **Attribution UI:** Detailed image info panel

**Phase 3 (Advanced):**
- Auto-generation on card save
- Third-party API integration (ChatGPT)
- Batch generation
- Generation history and regeneration
- **Attribution persistence:** Ensure metadata survives export/sync
- **Licensing display:** Show provider terms in settings

**Phase 4 (Polish):**
- Style presets
- Cost tracking for cloud APIs
- Advanced prompt editing
- Multi-variant generation
- **Regeneration tracking:** Version history with attribution per version
- **Attribution preferences:** User control over display/export behavior

### Security & Privacy Considerations:

- **API Keys:** Store in Keychain, never in SwiftData or CloudKit
- **Cloud Disclosure:** Clearly indicate when images sent to cloud services
- **On-Device Priority:** Default to Apple Intelligence (on-device)
- **Data Minimization:** Send only necessary data to cloud APIs (prompt only, not full card data)
- **User Control:** Easy to disable AI features entirely

### Related Systems:

- **Image Import System** - Integrate generation as alternative to import
- **Map Wizard** - AI generation as fourth creation method
- **Settings** - New AI configuration panel
- **Card Detail Views** - Generation UI integration

### Future Enhancements (Out of Scope for ER-0009):

- Image editing/refinement (inpainting, outpainting)
- Style transfer (apply one image's style to another)
- Image-to-image generation (refine imported images)
- AI-assisted tagging/categorization of images
- Character consistency across multiple generations
- Background removal and composition
- Image variations for same prompt

### Why Images Only (No Text Generation):

**Copyright & Ownership Concerns:**
- AI-generated text raises questions about authorship
- Copyright law unclear on AI-written content
- Publishers may reject AI-written manuscripts
- Writer's voice and style must remain authentic

**Images Are Different:**
- Visual inspiration, not creative output
- Similar to reference photos or concept art
- Writer still creates all narrative content
- No ownership ambiguity for the written work

**App Philosophy:**
- Cumberland supports writers, not replaces them
- AI as tool for visualization, not creation
- Writer maintains full creative control
- All narrative content is human-authored

---

## ER-0010: AI Assistant for Content Analysis and Structured Data Extraction

**Status:** 🔵 Proposed
**Component:** Card Editors, AI System, Relationship Manager, Settings
**Priority:** High
**Date Requested:** 2026-01-20

**Rationale:**

Writers create rich descriptive text about their worlds, characters, and scenes, but manually extracting structured data (locations mentioned, artifacts described, rules implied) is tedious and error-prone. AI can analyze text the writer has already written to:

1. **Identify worldbuilding elements** mentioned in descriptions (locations, artifacts, vehicles, buildings, rules)
2. **Suggest relationships** to existing cards
3. **Suggest creation of new cards** for mentioned entities that don't yet exist
4. **Generate calendar systems** from temporal descriptions (complements ER-0008)
5. **Maintain consistency** across the project by surfacing relationships

**CRITICAL DISTINCTION:** The AI analyzes and extracts structure from text **the writer already wrote**. It does not generate narrative content. This preserves copyright and ownership while providing intelligent assistance.

**Current Behavior:**

- **Manual card creation** - Writer must manually create cards for every entity
- **Manual relationship management** - Writer must manually link related cards
- **No analysis tools** - Mentions of locations/artifacts in scenes require manual tracking
- **Consistency challenges** - Easy to forget to create cards for mentioned entities

**Desired Behavior:**

### Core Capabilities:

1. **"Analyze" Button Integration**
   - Appears near description editor in all card types
   - On-demand analysis (not automatic)
   - Analyzes current card's description text
   - Presents suggestions in a review UI

2. **Entity Extraction**
   - Identify mentions of:
     - **Locations** (cities, regions, buildings)
     - **Artifacts** (objects, weapons, tools)
     - **Vehicles** (ships, mounts, transports)
     - **Buildings** (structures, landmarks)
     - **Rules** (magic systems, laws, customs)
     - **Characters** (people, creatures)
     - **Temporal Systems** (calendar mentions, time periods)
   - Match against existing cards
   - Suggest new cards for unmatched entities

3. **Relationship Suggestions**
   - "Character X appears in Scene Y" (appears-in relationship)
   - "Location Z is part of World W" (part-of relationship)
   - "Artifact A is owned by Character C" (custom relationship)
   - Present suggestions for user approval

4. **Calendar System Generation** (ER-0008 Enhancement)
   - Analyze temporal descriptions in scenes/timelines
   - Extract time divisions mentioned (months, seasons, holidays)
   - Generate calendar system definition
   - Suggest names for time periods based on descriptions
   - Example: "the Month of Harvest" → calendar month name

5. **Assistant Settings**
   - **"Enable Assistant"** master toggle
   - **Analysis scope:** (Conservative / Moderate / Aggressive)
   - **Auto-suggest relationships:** (on/off)
   - **Minimum confidence threshold:** (slider, 50-95%)
   - **Entity types to detect:** (checkboxes for each type)

6. **Suggestion Review UI**
   - Non-intrusive presentation of suggestions
   - Approve/Reject individual suggestions
   - Batch approve/reject
   - "Never suggest this again" option
   - Preview of what will be created/linked

### Use Case Examples:

**Example 1: Scene Analysis**

Scene description contains:
> "Aria drew the **Sunblade** from its sheath as she entered the **Temple of Shadows** in **Blackrock City**. The ancient **law of sanctuary** protected her here."

AI Analysis suggests:
- ✅ Create Artifact card: "Sunblade" → Link to Aria (character) via "owned-by"
- ✅ Create Building card: "Temple of Shadows" → Link to scene via "setting"
- ✅ Link to existing Location card: "Blackrock City" → Relationship already exists
- ✅ Create Rules card: "Law of Sanctuary" → Link to Temple and City

**Example 2: Character Analysis**

Character description contains:
> "Born in the **Frostlands**, trained at the **Academy of Blades**, now serves in the **Royal Guard**."

AI Analysis suggests:
- ✅ Link to existing Location: "Frostlands" via "born-in"
- ✅ Create Building: "Academy of Blades" → Link via "trained-at"
- ✅ Create Organization/Rules card: "Royal Guard" → Link via "member-of"

**Example 3: Calendar Generation** (ER-0008 Related)

Timeline/Scene descriptions contain:
> "In the **third week of the Harvest Moon**, during the **Festival of Stars**..."
> "The **War of Shadows** lasted three **Long Years**, from the **Time of Fire** to the **Age of Ice**."

AI Analysis suggests:
- ✅ Create Calendar System with:
  - Month name: "Harvest Moon"
  - Festival/Event: "Festival of Stars" (recurring event)
  - Era names: "Time of Fire", "Age of Ice"
  - Year type: "Long Year" (custom year definition?)

**Requirements:**

### Settings Requirements:

1. **Enable Assistant Setting**
   - Master toggle for all AI assistant features
   - Independent of ER-0009 image generation (can enable one without the other)
   - Clear explanation of what Assistant does

2. **Analysis Configuration**
   - **Analysis Scope:**
     - Conservative: High confidence only, fewer suggestions
     - Moderate: Balanced confidence, typical use
     - Aggressive: Lower confidence, more suggestions (may have false positives)
   - **Entity Detection Toggles:**
     - Detect Locations ☑
     - Detect Artifacts ☑
     - Detect Vehicles ☑
     - Detect Buildings ☑
     - Detect Rules ☑
     - Detect Characters ☑
     - Detect Temporal Systems ☑
   - **Confidence Threshold:** 50-95% (default 70%)

3. **Behavior Settings**
   - "Auto-suggest relationships for existing cards" (on/off)
   - "Suggest creation of new cards" (on/off)
   - "Remember 'never suggest' preferences" (on/off)

### UI Requirements:

4. **"Analyze" Button Placement**
   - Near description editor in:
     - Scene cards
     - Character cards
     - Project cards (for world descriptions)
     - Timeline cards (for calendar extraction)
     - Location cards
     - All other card types
   - Button states:
     - Available (sufficient text to analyze)
     - Disabled (insufficient text, e.g., < 25 words)
     - Analyzing (in progress)
   - Tooltip: "Analyze description to find mentioned entities and suggest cards/relationships"

5. **Suggestion Review Panel**
   - Modal or sheet presentation
   - Grouped by suggestion type:
     - "New Cards to Create" section
     - "Relationships to Add" section
     - "Calendar System Detected" section (if applicable)
   - Each suggestion shows:
     - Entity name (extracted)
     - Card type (detected)
     - Confidence score (%)
     - Context (surrounding text snippet)
     - Preview of what will be created
   - Actions per suggestion:
     - ✅ Accept
     - ❌ Reject
     - 🔇 Never suggest this
     - ✏️ Edit before creating
   - Batch actions:
     - "Accept All High Confidence (>80%)"
     - "Accept All"
     - "Reject All"

6. **Suggestion Preview**
   - For new cards: Show card type, name, initial description (from context)
   - For relationships: Show source → relationship type → target
   - For calendar systems: Show detected time divisions and names

### AI Integration Requirements:

7. **Entity Recognition (NER - Named Entity Recognition)**
   - Use AI provider (Apple Intelligence, ChatGPT, Claude) for entity extraction
   - Structured output: entity name, type, confidence, context
   - Proper noun detection
   - Context-aware typing (is "Shadowblade" a person, place, or thing?)

8. **Relationship Inference**
   - Analyze sentence structure to infer relationships
   - "X drew the Y" → X owns/uses Y
   - "entered the Z" → Z is a location/building
   - "in the city of W" → W is a location
   - "the law of V" → V is a rule/custom

9. **Calendar System Extraction** (ER-0008 Integration)
   - Detect temporal vocabulary (months, seasons, years, eras)
   - Extract custom time period names
   - Identify hierarchy (days → weeks → months → years → eras)
   - Generate calendar structure definition
   - Suggest to user for review before creating Calendar card

10. **Deduplication**
    - Check if extracted entity matches existing card (fuzzy matching)
    - Avoid suggesting creation of duplicates
    - Suggest linking to existing card instead

### Data Model Requirements:

11. **Suggestion Tracking**
    - Track accepted suggestions (for learning/improvement)
    - Track rejected suggestions
    - "Never suggest" preferences (per entity or pattern)
    - Optional: Learn from user preferences over time

12. **Analysis History (Optional)**
    - When was card last analyzed
    - What suggestions were made/accepted
    - Avoid re-suggesting same entities

### Quality & Safety Requirements:

13. **Confidence Scoring**
    - Each suggestion has confidence score (0-100%)
    - Display confidence to user
    - Allow filtering by confidence threshold
    - High confidence (>85%): Likely accurate
    - Medium confidence (60-85%): Review recommended
    - Low confidence (<60%): May be false positive

14. **False Positive Handling**
    - Avoid suggesting common words as entity names
    - Context awareness (is "shadows" a place or just darkness?)
    - Proper noun vs common noun distinction
    - User feedback improves accuracy over time

15. **Privacy & Security**
    - Same privacy model as ER-0009
    - On-device processing preferred (Apple Intelligence)
    - Clear disclosure when sending text to cloud APIs
    - Option to disable cloud-based analysis
    - Data minimization (send only description text, not entire card)

**Design Approach:**

### Phase 1: Core Analysis Engine

1. **AI Provider Integration**
   - Reuse provider architecture from ER-0009
   - Add NER (Named Entity Recognition) capabilities
   - Structured output parsing

2. **Entity Extractor**
   - Analyze text for entity mentions
   - Type detection (Location, Artifact, etc.)
   - Confidence scoring
   - Context extraction

3. **Settings UI**
   - Enable Assistant toggle
   - Analysis scope configuration
   - Entity type toggles

### Phase 2: Suggestion System

4. **Suggestion Engine**
   - Generate card creation suggestions
   - Generate relationship suggestions
   - Deduplication logic
   - Confidence ranking

5. **Review UI**
   - Suggestion panel design
   - Accept/Reject/Edit flows
   - Batch operations
   - Preview functionality

### Phase 3: Card & Relationship Creation

6. **Automated Card Creation**
   - Create cards from accepted suggestions
   - Pre-populate name, type, initial description
   - Link to source card (e.g., "mentioned in Scene X")

7. **Automated Relationship Creation**
   - Create CardEdge relationships
   - Use appropriate RelationType
   - Maintain bidirectional consistency

### Phase 4: Calendar System Generation (ER-0008 Integration)

8. **Temporal Analysis**
   - Detect calendar-related vocabulary
   - Extract time period names and hierarchy
   - Generate calendar system structure

9. **Calendar Card Creation**
   - Create Rules card with calendar system data
   - Populate time divisions
   - Suggest to user for review/editing

### Phase 5: Learning & Refinement

10. **Preference Learning (Optional)**
    - Track user accept/reject patterns
    - Adjust confidence thresholds
    - Improve entity type detection
    - Reduce false positives over time

**Components Affected:**

- **Settings/SettingsView.swift** - Add "Enable Assistant" and analysis settings
- **CardEditorView.swift** - Add "Analyze" button near description editor
- **Model/Card.swift** - Optional: Track analysis metadata
- **AI/AIImageGenerator.swift** - Extend or share provider infrastructure with ER-0009
- **New: AIAssistant.swift** - Core assistant logic and orchestration
- **New: EntityExtractor.swift** - NER and entity detection
- **New: SuggestionEngine.swift** - Generate card/relationship suggestions
- **New: SuggestionReviewView.swift** - UI for reviewing suggestions
- **New: RelationshipInference.swift** - Infer relationships from context
- **New: CalendarSystemExtractor.swift** - Extract calendar systems from text (ER-0008 tie-in)
- **New: AnalysisSettings.swift** - Settings data model
- **New: SuggestionTracker.swift** - Track accepted/rejected suggestions

**Implementation Details:**

*To be filled in during implementation*

**Test Steps:**

*To be defined during implementation planning*

**Notes:**

### Open Design Questions:

1. **Analysis Triggers:**
   - Only on "Analyze" button click?
   - Optional: Auto-analyze on card save (with user confirmation)?
   - Analyze entire project (batch)?

2. **Suggestion Persistence:**
   - Store pending suggestions for later review?
   - Discard suggestions when panel closes?
   - Allow "review later" queue?

3. **Learning & Adaptation:**
   - Learn from user accept/reject patterns?
   - Adjust confidence thresholds per user?
   - Privacy implications of tracking preferences?

4. **Calendar Generation Accuracy:**
   - Minimum text required to extract calendar?
   - How to handle incomplete calendar systems?
   - User guidance for improving calendar extraction?

5. **Relationship Type Selection:**
   - Auto-select relationship types based on context?
   - Ask user to confirm/override relationship types?
   - Create custom relationship types on the fly?

6. **Batch Analysis:**
   - Analyze multiple cards at once?
   - Analyze entire project (all scenes)?
   - Progress tracking for large projects?

7. **Conflict Resolution:**
   - What if analysis suggests conflicting relationships?
   - What if extracted entity could be multiple types?
   - How to handle ambiguity?

8. **Integration with ER-0009:**
   - After creating suggested cards, auto-generate images?
   - Combined workflow (analyze → create cards → generate images)?
   - Separate or integrated UI?

### Implementation Priorities:

**Phase 1 (MVP):**
- Enable Assistant setting
- Basic entity extraction (Locations, Artifacts, Characters)
- "Analyze" button in Scene and Character editors
- Simple suggestion review UI
- Card creation from accepted suggestions

**Phase 2 (Relationships):**
- Relationship inference
- Relationship suggestions
- Deduplication (match against existing cards)
- Improved confidence scoring

**Phase 3 (Calendar Systems):**
- Temporal analysis for ER-0008
- Calendar system extraction
- Calendar card generation
- Integration with Timeline system

**Phase 4 (Advanced):**
- Batch analysis
- Learning from user preferences
- Advanced entity types (Organizations, Events, etc.)
- Multi-language support (if needed)

### Integration with Other ERs:

**ER-0008 (Timeline System):**
- Extract calendar systems from scene/timeline descriptions
- Auto-populate calendar time divisions
- Suggest calendar names and structures

**ER-0009 (AI Image Generation):**
- Share AI provider infrastructure
- After creating suggested cards, optionally generate images
- Combined workflow possible

### Why This Doesn't Cross the Copyright Line:

**The Writer Wrote the Text:**
- AI analyzes text the writer already created
- No new narrative content generated
- Writer maintains full authorship

**Extraction, Not Generation:**
- AI identifies patterns in existing text
- Suggests organizational structure
- Writer approves all changes

**Transparency & Control:**
- User explicitly triggers analysis ("Analyze" button)
- All suggestions require approval
- Easy to reject or disable

**Comparable to Other Tools:**
- Similar to search/find (identifying text patterns)
- Similar to spell-check suggestions
- Similar to autocomplete (based on existing text)

### Future Enhancements (Out of Scope for ER-0010):

- Multi-card analysis (analyze relationships between multiple scenes)
- Timeline extraction (extract event sequences from narrative)
- Contradiction detection (identify inconsistencies across scenes)
- Character trait extraction (build character profiles from descriptions)
- Plot point extraction (identify key story beats)
- World consistency checker (ensure rules/laws are consistently applied)
- Export analysis reports
- Natural language queries ("Show me all scenes mentioning the sword")

---
```

## ER-0011: Image Sharing and Linking Between Cards

**Status:** 🔵 Proposed
**Component:** Card Model, CardEditorView, Image Management
**Priority:** Medium
**Date Requested:** 2026-01-22

**Rationale:**

Writers often need the same image to appear on multiple cards. For example:
- Multiple scenes taking place in the same location
- Character cards for the same person at different life stages
- Multiple cards referencing the same artifact or building
- Location cards showing the same map at different zoom levels

Currently, each card stores its own copy of image data. To use the same image on multiple cards, users must:
1. Export the image from the first card
2. Import it into each subsequent card

This is tedious and inefficient, resulting in:
- **Storage waste**: Same image data duplicated across multiple cards
- **Workflow friction**: Extra steps to share images between cards
- **Update difficulty**: To change the image, must update each card individually
- **Sync issues**: Easy to accidentally use different versions of "the same" image

**Current Behavior:**

- Each Card stores its own `originalImageData` and `thumbnailData`
- No mechanism to reference another card's image
- No "Copy Image" or "Paste Image" functionality
- Images must be manually re-imported for each card

**Requested Behavior:**

### Option 1: Copy/Paste Image (Simple)

Add clipboard-based image sharing:

**Copy Image:**
- Context menu or button on card images: "Copy Image"
- Copies image data to system clipboard
- Works across cards in the same session

**Paste Image:**
- "Paste Image" button/menu when editing a card
- Pastes image from clipboard
- Still creates independent copies (no linking)

**Benefits:**
- Simple to implement
- Familiar UX pattern
- Works within app session

**Limitations:**
- Still duplicates image data
- No cross-session persistence
- If source image changes, copies don't update

### Option 2: Image Linking (Advanced)

Multiple cards reference the same stored image:

**Shared Image Storage:**
- New `SharedImage` model with `id`, `originalImageData`, `thumbnailData`
- Card has optional `sharedImage: SharedImage?` relationship
- Falls back to local `originalImageData` if no shared image

**Use Cases:**
- "Use image from card..." picker shows all cards with images
- Selecting a card links to that card's image
- Or: "Share this image" makes it available to other cards
- Changing the shared image updates all linked cards

**Benefits:**
- Storage efficient (one copy of image data)
- Update once, changes everywhere
- Clear visual indication when images are linked

**Limitations:**
- More complex data model changes
- Schema migration required
- Need UI to show/manage links
- What happens if source card is deleted?

### Option 3: Hybrid Approach (Recommended)

Implement both features with progressive disclosure:

**Phase 1: Copy/Paste (Quick Win)**
- Add "Copy Image" and "Paste Image" functionality
- Immediate user value with minimal changes
- No data model changes required

**Phase 2: Image Linking (Future Enhancement)**
- Add `SharedImage` model and relationships
- Offer "Link to image from..." when pasting
- User chooses: Copy (independent) vs Link (shared)
- Provides efficiency benefits for power users

**Design Decisions:**

1. **Deletion Behavior (for linked images):**
   - **Option A**: Delete shared image when last card is deleted
   - **Option B**: Keep orphaned shared images (with cleanup tool)
   - **Option C**: Convert to local image on last card

2. **Attribution Tracking:**
   - For AI-generated images with citations, should copies/links preserve attribution?
   - Recommendation: Yes, preserve AI metadata and citations

3. **Edit Behavior:**
   - Should editing a linked image affect all cards? (probably no)
   - Provide "Make Unique" option to break the link

**Proposed Implementation:**

### Phase 1: Copy/Paste (ER-0011-A)

**Files to Modify:**
- `CardEditorView.swift` - Add copy/paste buttons
- `CardSheetView.swift` - Add copy/paste to image context menu
- New: `ImageClipboardManager.swift` - Handle clipboard operations

**UI Changes:**
- "Copy Image" button/menu item on card images
- "Paste Image" button appears when clipboard has image
- Visual feedback (toast/alert) confirming copy/paste

**Keyboard Shortcuts:**
- Cmd+C when image is focused: Copy image
- Cmd+V when editing card: Paste image

### Phase 2: Image Linking (ER-0011-B) - Future

**Files to Modify:**
- `Model/Card.swift` - Add optional `sharedImage` relationship
- New: `Model/SharedImage.swift` - Shared image model
- `Model/Migrations.swift` - Add AppSchemaV7 migration
- `CardEditorView.swift` - "Link to image from card..." picker
- Visual indicator showing when image is linked

**Migration Strategy:**
- All existing cards keep local `originalImageData`
- New `sharedImage?` relationship is optional
- Backward compatible with existing cards

**Expected Benefits:**

**User Experience:**
- **Faster workflow**: Copy/paste eliminates export/import steps
- **Consistency**: Same image guaranteed to be identical across cards
- **Flexibility**: Choose between independent copies or linked images

**Performance:**
- **Storage savings**: Linked images stored once (for Option 2)
- **Sync efficiency**: Less data to sync to CloudKit (for Option 2)
- **Memory efficiency**: Single image cache for linked images

**Use Cases:**

1. **Location Scenes**: Multiple scenes in "The Dragon's Lair" all show the same map
2. **Character Development**: Same character at different story points shares core appearance
3. **Reference Images**: Architectural details shared across multiple building cards
4. **Map Hierarchy**: Parent location and child locations share overview map

**Testing Scenarios:**

1. **Copy/Paste Within Session:**
   - Copy image from Card A
   - Paste into Card B
   - Verify image appears correctly
   - Verify AI metadata preserved (if applicable)

2. **Cross-Device (future):**
   - Copy image on Mac
   - Universal clipboard to iPad
   - Paste into card on iPad

3. **Large Images:**
   - Copy/paste high-resolution image
   - Verify performance acceptable
   - Verify thumbnail regeneration works

4. **Attribution Preservation:**
   - Copy AI-generated image with citation
   - Paste into new card
   - Verify citation/attribution appears in Image Attribution panel

**Related Issues:**

- ER-0009: AI Image Generation (attribution should be preserved)
- Image storage and caching system
- CloudKit sync considerations for large images

**Priority Justification:**

**Medium Priority** because:
- **Pain point identified**: User requested this specific feature
- **Common use case**: Location scenes especially benefit
- **Quick win**: Phase 1 (copy/paste) is relatively simple
- **Not blocking**: Workarounds exist (export/import)
- **Lower than ER-8/9/10**: Timeline and AI features higher priority

**Recommendation:**

Implement **Phase 1 (Copy/Paste)** first as part of ER-0009 completion or as standalone ER-0011. This provides immediate user value with minimal complexity. Consider Phase 2 (Image Linking) as a future enhancement if users request it after experiencing copy/paste.

---

## ER-0012: Chronicles Card Type for Historical Events and Time Periods

**Status:** ✅ Verified
**Component:** Card Model (Kinds.swift), MainAppView, AI Integration
**Priority:** Medium
**Date Requested:** 2026-01-24
**Date Implemented:** 2026-01-25

**User Request:**

User asked: "What would you call a named time period, such as The Age of Ascendance, The Fall of Stormwatch, or the Shadow War or the Treaty of Argenthall? I don't think they warrant classification as Scenes because they will not form part of the narrative of the story. They are vital background information and warrant the description of important Historical Events."

User decided on the name: **Chronicles**

**Problem Statement:**

Currently, worldbuilding elements like historical events, time periods, and background lore don't have an appropriate card type:
- **Not Scenes**: These aren't part of the narrative story being written
- **Not Rules**: Too important to be relegated to generic "Rules" category
- **Not Timelines**: Timeline cards are for temporal positioning, not event descriptions
- **Historical significance**: Events like "The Shadow War" or "The Fall of Stormwatch" are crucial worldbuilding

**Proposed Solution:**

Add a new card type: **Chronicles**

**What Chronicles Are:**
- Historical events: "The Battle of Five Peaks", "The Great Rebellion"
- Time periods/eras: "The Age of Ascendance", "The Second Dynasty"
- Treaties and agreements: "The Treaty of Argenthall"
- Wars and conflicts: "The Shadow War"
- Major transitions: "The Fall of Stormwatch"
- Background lore that shapes the world but isn't directly narrated

**Implementation Summary:**

**Phase 1: Add Chronicles to Kinds Enum** ✅
- [x] Added `.chronicles = "Chronicles"` case to `Kinds.swift:24`
- [x] Added to `orderedCases` (position: after Artifacts, before Rules) - Line 35
- [x] Added singular title: "Chronicle" - Line 47
- [x] Chose SF Symbol icon: `"scroll"` / `"scroll.fill"` - Lines 69, 166
- [x] Defined light/dark color palette (warm gold/amber, h: 40/360) - Lines 105, 120

**Phase 2: UI Integration** ✅
- [x] Added Chronicles to sidebar filter in `MainAppView.swift`
- [x] Added visibility toggle to column settings (`@AppStorage`) - Line 84
- [x] Added Chronicles to switch statements (load/save column visibility) - Lines 1119, 1159
- [x] Chronicles automatically appears in "Add Card" button (inherits from `Kinds.orderedCases`)

**Phase 3: Entity Extraction Integration (ER-0010)** ✅
- [x] Added `historicalEvent = "historical_event"` entity type to `EntityType` enum - `AIProviderProtocol.swift:173`
- [x] Mapped to `.chronicles` card kind in `toCardKind()` - `AIProviderProtocol.swift:185`
- [x] Updated OpenAI prompt to extract historical events/time periods - `OpenAIProvider.swift:199-201, 206`
- [x] Added `historicalEvent` to entity type flags - `AISettings.swift:297`
- [x] Added `historicalEvent` to EntityTypesView picker - `AISettingsView.swift:352`

**Files Modified:**
- `Cumberland/Model/Kinds.swift` - Added Chronicles enum case, ordering, icon, colors
- `Cumberland/AI/AIProviderProtocol.swift` - Added historicalEvent entity type → Chronicles mapping
- `Cumberland/AI/OpenAIProvider.swift` - Updated prompt to extract historical events
- `Cumberland/AI/AISettings.swift` - Added historicalEvent to entity type flags
- `Cumberland/AI/AISettingsView.swift` - Added historicalEvent to entity type picker
- `Cumberland/MainAppView.swift` - Added Chronicles column visibility and switch cases

**Visual Design Suggestions:**

**SF Symbol:** `"scroll"` (most evocative of historical records)
- Alternative: `"book.pages"` (multiple pages = chronicles)
- Alternative: `"text.book.closed"` (formal history book)

**Color Palette:**
- **Light mode**: Warm gold/amber pastel (h: 40/360, s: 0.20, b: 0.97)
- **Dark mode**: Rich amber (h: 40/360, s: 0.58, b: 0.32)
- Rationale: Gold/amber suggests age, importance, historical records

**User Scenarios:**

1. **Fantasy Epic:**
   - Chronicles: "The First Age", "The Dragon Wars", "The Sundering"
   - Provides timeline context without being part of current narrative

2. **Sci-Fi Universe:**
   - Chronicles: "The Mars Rebellion", "The AI Awakening", "The Treaty of Europa"
   - Background history referenced in story

3. **Historical Fiction:**
   - Chronicles: "The Victorian Era", "The Industrial Revolution"
   - Real historical periods affecting characters

**Testing Checklist:**

- [ ] Create Chronicles card via "+ Add Card" button
- [ ] Chronicles appears in sidebar with correct icon/color
- [ ] Chronicles cards filterable and sortable
- [ ] Chronicles cards appear in search results
- [ ] Chronicles cards can be cited as Sources
- [ ] AI entity extraction suggests Chronicles for historical events
- [ ] CloudKit sync works for Chronicles cards

**Related:**
- ER-0010: AI Content Analysis (should extract historical events)
- ER-0008: Timeline System (Chronicles provide context for timeline events)

**Priority Justification:**

**Medium Priority** because:
- **User-requested**: Specific pain point identified
- **Common use case**: Most worldbuilding projects have historical background
- **Low complexity**: Primarily enum expansion and UI updates
- **Nice-to-have**: Workaround exists (using Rules or Scenes)
- **Synergy**: Integrates well with ER-0010 entity extraction

---

## ER-0013: Separate AI Provider Settings for Analysis and Image Generation

**Status:** ✅ Verified
**Component:** AISettings, Settings UI, AI Provider Selection
**Priority:** Medium
**Date Requested:** 2026-01-24
**Date Implemented:** 2026-01-25

**User Request:**

User said: "I think we should allow the writer to use different AI providers for Analysis and Image Generation. For example she might opt to use Apple Intelligence for analysis and Open AI for image generation. This should be selectable in preferences."

**Problem Statement:**

Currently, `AISettings` has a single `selectedProvider` setting that applies to both:
1. **Content Analysis** (entity extraction, relationship inference)
2. **Image Generation** (creating artwork for cards and maps)

Users may want different providers for different tasks:
- **Apple Intelligence for analysis**: Fast, on-device, private, no API costs
- **OpenAI for image generation**: Better quality images with DALL-E 3
- **Cost optimization**: Use free Apple Intelligence when possible, paid APIs only when needed
- **Performance**: Use fastest provider for each specific task

**Current Behavior:**

```swift
// AISettings.swift
@Observable class AISettings {
    var selectedProvider: String = "apple" // Single provider for everything
}
```

Both `analyzeText()` and `generateImage()` use the same provider.

**Proposed Solution:**

Split into two separate provider settings:

```swift
@Observable class AISettings {
    // Separate providers
    var analysisProvider: String = "apple"        // For entity extraction, analysis
    var imageGenerationProvider: String = "openai" // For DALL-E, image gen

    // Legacy property for migration (deprecated)
    @available(*, deprecated, message: "Use analysisProvider or imageGenerationProvider")
    var selectedProvider: String {
        get { analysisProvider }
        set { analysisProvider = newValue; imageGenerationProvider = newValue }
    }
}
```

**Implementation Summary:**

**Phase 1: Update AISettings Model** ✅
- [x] Added `analysisProvider: String` property to `AISettings` with migration logic - `AISettings.swift:56-71`
- [x] Added `imageGenerationProvider: String` property to `AISettings` with migration logic - `AISettings.swift:73-88`
- [x] Added automatic migration from legacy `preferredProvider` - Both properties check legacy value on first access
- [x] Deprecated `currentProvider` and added `currentAnalysisProvider` / `currentImageGenerationProvider` - Lines 165-194
- [x] Added helper method: `provider(for: AITask)` - Lines 159-164
- [x] Added `AITask` enum (`.analysis`, `.imageGeneration`) - Lines 251-255

**Phase 2: Update Settings UI** ✅
- [x] Split provider picker into two separate sections in `AISettingsView.swift:55-93`
- [x] Section 1: "Content Analysis" with provider picker and API key management - Lines 65-83
- [x] Section 2: "Image Generation" with provider picker and API key management - Lines 86-111
- [x] Added explanatory footer text for each section describing use cases
- [x] Show API key status for each provider separately (shared `apiKeyRow()` method)

**Phase 3: Update Provider Selection Logic** ✅
- [x] `CardEditorView:1102`: Use `currentAnalysisProvider` for "Analyze" button (entity extraction)
- [x] `CardEditorView:1412`: Use `currentImageGenerationProvider` for image auto-generation
- [x] Updated all usages of deprecated `currentProvider` to use task-specific properties
- [x] Fixed debug `printSettings()` to show both providers separately - `AISettings.swift:452`

**Phase 4: Availability Checks** ✅
- [x] Updated `isImageGenerationAvailable` to check `currentImageGenerationProvider` - Line 178
- [x] Updated `isContentAnalysisAvailable` to check `currentAnalysisProvider` - Line 183
- [x] Updated `isProviderAvailable` to check if either provider available - Line 195

**Files Modified:**
- `Cumberland/AI/AISettings.swift` - Added separate provider properties, migration logic, AITask enum, deprecated old properties
- `Cumberland/AI/AISettingsView.swift` - Split provider section into two separate sections with independent pickers
- `Cumberland/CardEditorView.swift` - Updated to use task-specific provider properties (analysis vs image generation)

**Build Status:** ✅ Compiles with zero errors and zero warnings

**UI Mockup:**

```
Settings → AI

┌─────────────────────────────────────┐
│ Content Analysis                    │
├─────────────────────────────────────┤
│ Provider: [Apple Intelligence ▾]    │
│                                     │
│ ℹ️ Used for entity extraction,      │
│   relationship inference, and       │
│   content analysis. Apple           │
│   Intelligence is faster and free.  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Image Generation                    │
├─────────────────────────────────────┤
│ Provider: [OpenAI (DALL-E 3) ▾]     │
│                                     │
│ ℹ️ Used for generating images and   │
│   maps. DALL-E 3 produces higher    │
│   quality results but requires API  │
│   key and has usage costs.          │
│                                     │
│ OpenAI API Key: [Configured ✓]      │
└─────────────────────────────────────┘
```

**Migration Strategy:**

1. Check if user has existing `selectedProvider` preference
2. On first launch after update:
   - Set `analysisProvider = selectedProvider`
   - Set `imageGenerationProvider = selectedProvider`
3. Clear old `selectedProvider` preference
4. User can then customize each provider independently

**Testing Checklist:**

- [ ] **Fresh Install**: Default providers set correctly
- [ ] **Existing User**: Migration preserves existing provider choice
- [ ] **Analysis**: CardEditorView "Analyze" uses `analysisProvider`
- [ ] **Image Gen**: AI Image Generation uses `imageGenerationProvider`
- [ ] **Map Gen**: Map Wizard uses `imageGenerationProvider`
- [ ] **Mixed Setup**: Apple for analysis + OpenAI for images works correctly
- [ ] **Settings UI**: Both pickers work independently
- [ ] **API Keys**: Correct API key validation for each provider

**Use Case Examples:**

**Example 1: Privacy-Conscious User**
- Analysis Provider: Apple Intelligence (on-device, private)
- Image Generation Provider: Apple Intelligence (on-device, private)
- Result: Everything stays on device, no cloud APIs

**Example 2: Quality-Focused User**
- Analysis Provider: Apple Intelligence (fast, free)
- Image Generation Provider: OpenAI (better image quality)
- Result: Fast analysis, beautiful images, optimized cost

**Example 3: Power User**
- Analysis Provider: OpenAI (GPT-4 for complex analysis)
- Image Generation Provider: OpenAI (DALL-E 3 for images)
- Result: Maximum quality, accepts API costs

**Related:**
- ER-0009: AI Image Generation
- ER-0010: AI Content Analysis
- DR-0050: Timeout issues (relates to provider performance)
- DR-0052: Entity extraction bugs (provider-specific)

**Priority Justification:**

**Medium Priority** because:
- **User-requested**: Specific feature request
- **Flexibility**: Allows users to optimize for speed, quality, or cost
- **Common pattern**: Many AI tools offer per-task provider selection
- **Not urgent**: Current single-provider system works
- **Nice enhancement**: Improves user experience and control

---

## ER-0014: Change Card Type Feature with Relationship Deletion

**Status:** ✅ Verified
**Component:** CardRelationshipView, SuggestionReviewView, AI Suggestion System
**Priority:** Medium
**Date Requested:** 2026-01-25
**Date Implemented:** 2026-01-25

**User Request:**

User identified a need to change card types in two scenarios:
1. **Before Card Creation (AI Suggestions)**: Cards suggested by AI analysis may be miscategorized (e.g., "Shadow War" suggested as Scene should be Chronicle)
2. **After Card Creation (Existing Cards)**: Cards may need reclassification as the worldbuilding evolves

User decided on implementation approach:
- **AI Suggestion Sheet**: Allow type change BEFORE creating cards (low-risk, no data loss)
- **Relationship Tab**: Allow type change AFTER creation with warning dialog (high-risk, deletes all relationships)
- **NOT in CardEditorView**: Too easy to accidentally trigger
- **NOT as menu item**: Too accessible for destructive operation

**Problem Statement:**

Currently, once a card is created with a specific type (Kind), there's no way to change it:
- **Immutable Type**: Card type is set at creation and cannot be changed
- **AI Miscategorization**: AI may suggest wrong types (e.g., historical events as Scenes instead of Chronicles)
- **User Evolving Understanding**: As worldbuilding progresses, categorization needs may change
- **All-or-Nothing**: Can't fix type without deleting and recreating card (loses all relationships anyway)

**Implemented Solution:**

**Part 1: Change Type in AI Suggestion Sheet (Low-Risk)** ✅

Allow users to override AI's suggested type BEFORE creating cards:

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift:14` - Made `cardKind` mutable (`var` instead of `let`)
- `Cumberland/AI/SuggestionReviewView.swift` - Multiple changes:
  - Lines 21-28: Changed `suggestions` to `mutableSuggestions` state
  - Lines 23-28: Added init() to accept immutable suggestions and create mutable state
  - Line 126: Changed `ForEach(suggestions.cards)` to `ForEach($mutableSuggestions.cards)`
  - Line 290: Changed `CardSuggestionRow` to accept `@Binding var suggestion`
  - Lines 311-319: Replaced static type badge with `Picker` for all card types (except .structure)

**How It Works:**
1. User analyzes card description → AI suggests entities
2. Suggestion sheet shows entities with suggested types
3. User sees "Shadow War" suggested as "Scene"
4. User taps type picker → selects "Chronicles"
5. Card is created with correct type from the start
6. **No relationships exist yet** → No data loss

**Part 2: Change Type in Relationship Tab (High-Risk)** ✅

Allow users to change type for existing cards with clear warning about relationship deletion:

**Files Modified:**
- `Cumberland/CardRelationshipView.swift`:
  - Lines 107-108: Added state variables for dialog and selected type
  - Lines 543-558: Added "Change Card Type…" button in topControls
  - Lines 345-359: Added confirmation dialog with type picker and destructive action
  - Lines 1105-1132: Implemented `changeCardType(to:)` function

**How It Works:**
1. User opens card in Relationship tab
2. User clicks "Change Card Type…" button
3. Confirmation dialog appears with:
   - **Warning**: "Changing the card type from [X] to another type will REMOVE ALL RELATIONSHIPS for [card name]. This cannot be undone."
   - **Type Picker**: Shows all card types (except .structure)
   - **Change Type Button**: Red destructive style
   - **Cancel Button**: Safe exit
4. User selects new type → clicks "Change Type"
5. System:
   - Fetches all CardEdges where card is source or target
   - Deletes all edges (relationships)
   - Changes `primary.kindRaw` to new type
   - Saves model context
6. Card type is changed, all relationships removed

**Implementation Details:**

**Relationship Deletion Logic** (`CardRelationshipView.swift:1105-1132`):
```swift
private func changeCardType(to newKind: Kinds) {
    guard newKind != primary.kind else { return }

    // Fetch all edges where this card is either source or target
    let cardID: UUID? = primary.id
    let fetchFrom = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.from?.id == cardID })
    let fetchTo = FetchDescriptor<CardEdge>(predicate: #Predicate { $0.to?.id == cardID })

    let edgesFrom = (try? modelContext.fetch(fetchFrom)) ?? []
    let edgesTo = (try? modelContext.fetch(fetchTo)) ?? []

    // Delete all relationships
    for edge in edgesFrom + edgesTo {
        modelContext.delete(edge)
    }

    // Change the card type
    primary.kindRaw = newKind.rawValue

    // Save changes
    try? modelContext.save()
}
```

**Why Relationship Deletion is Necessary:**

1. **Relationship Type Constraints**: RelationTypes have `sourceKind` and `targetKind` constraints
   - Example: "stories/is-storied-by" only valid for Scene → Project
   - If Scene becomes Character, this relationship type is invalid
2. **Data Integrity**: Invalid relationships would break the relationship system
3. **User Clarity**: Better to delete all than leave some orphaned/invalid relationships
4. **Explicit Trade-off**: User is warned and must confirm the destructive action

**User Scenarios:**

**Scenario 1: AI Misclassification (No Data Loss)**
1. User writes scene description mentioning "The Shadow War"
2. AI suggests "Shadow War" as Scene
3. User sees this in suggestion sheet, changes to Chronicles
4. Card created as Chronicles ✅
5. **No relationships deleted** (card didn't exist yet)

**Scenario 2: Late Reclassification (Destructive)**
1. User has "The Shadow War" card (type: Scenes)
2. Card has relationships to Characters, Locations, Projects
3. User realizes it should be Chronicles (historical background, not active scene)
4. User opens Relationship tab → "Change Card Type…"
5. Dialog warns: "Will REMOVE ALL RELATIONSHIPS"
6. User confirms → Type changes to Chronicles, all relationships deleted
7. User rebuilds only the relationships that still make sense

**Testing Checklist:**

**Part 1: AI Suggestion Sheet**
- [ ] Analyze card with 100+ word description
- [ ] Verify suggestion sheet shows entities with type pickers
- [ ] Change suggested type (e.g., Scene → Chronicles)
- [ ] Create card
- [ ] Verify card has correct type in sidebar
- [ ] Verify card has correct kind badge color

**Part 2: Relationship Tab**
- [ ] Create card with several relationships
- [ ] Open card in Relationship tab
- [ ] Click "Change Card Type…" button
- [ ] Verify confirmation dialog appears with warning
- [ ] Verify type picker shows all types except .structure
- [ ] Select new type → click "Change Type"
- [ ] Verify card type changes
- [ ] Verify all relationships are deleted
- [ ] Verify card appears in correct sidebar section
- [ ] Cancel dialog → verify no changes

**Edge Cases:**
- [ ] Change type to same type → no-op (guard clause)
- [ ] Card with 0 relationships → type changes, nothing deleted
- [ ] Card with 50+ relationships → all deleted (test performance)
- [ ] CloudKit sync → verify type change and edge deletions sync

**Build Status:**
✅ **BUILD SUCCEEDED** with zero errors and zero warnings

**Files Modified:**
- `Cumberland/AI/SuggestionEngine.swift` - Made cardKind mutable
- `Cumberland/AI/SuggestionReviewView.swift` - Added type picker to suggestion rows
- `Cumberland/CardRelationshipView.swift` - Added change type button, dialog, and implementation

**User Impact:** High - Provides flexibility for correcting categorization mistakes, but with appropriate warnings for destructive operations

**Priority Justification:**

**Medium Priority** because:
- **User-requested**: Specific pain point identified
- **Common use case**: AI misclassification happens frequently with new Chronicles type
- **Workaround exists**: Delete and recreate card (same data loss)
- **Quality of life**: Prevents frustration from miscategorized cards
- **Not urgent**: Users can work around it, but it's tedious

**Related:**
- ER-0012: Chronicles Card Type (new type frequently needs reclassification)
- ER-0010: AI Content Analysis (AI suggestions may be imperfect)

---

## ER-0015: Improve Empty Analysis Results Message - Show "No New Entities" and List Existing Matches

**Status:** 🔵 Proposed
**Component:** SuggestionReviewView, SuggestionEngine, Entity Extraction
**Priority:** Low
**Date Requested:** 2026-01-25

**User Request:**

User said: "When re-analyzing a description and finding no entities the popup should say no new entities found. and maybe provide an list of existing entities that were found and not duplicated."

**Problem Statement:**

Currently, when analyzing a card description, if all detected entities already exist as cards (100% deduplication), the SuggestionReviewView shows an empty state message:

```
🔍 No Suggestions Found

The AI couldn't find any entities or relationships in the text.

Try adding more descriptive details to your card.
```

This message is **misleading** because:
1. **AI DID find entities** - it just found that they all already exist
2. **Implies text is insufficient** - when actually the text is working well
3. **Doesn't acknowledge existing cards** - user doesn't know what was matched
4. **Suggests user needs to add more** - when they may have already created those cards

**Desired Behavior:**

The empty state should distinguish between two scenarios:

**Scenario 1: Truly No Entities Found**
```
🔍 No Entities Detected

The AI couldn't identify any entities or relationships in this text.

Try adding more descriptive details about:
• Characters, creatures, or people
• Locations, buildings, or places
• Artifacts, items, or objects
• Historical events or time periods
```

**Scenario 2: All Entities Already Exist (Deduplication)**
```
✅ No New Entities Found

All detected entities already exist as cards. Great work keeping your worldbuilding organized!

Entities found (already created):
• Shadowblade (Artifact)
• Temple of Shadows (Building)
• Blackrock City (Location)
• Aria (Character)

💡 Tip: You can still create relationships between these cards in the Relationship tab.
```

**Requirements:**

### Data Model Changes:

1. **SuggestionEngine Return Type Enhancement**
   - Current: Returns `Suggestions` struct with empty arrays when nothing new
   - Needed: Return additional `existingMatches: [ExistingEntityMatch]` array
   - `ExistingEntityMatch` contains:
     - `entityName: String` - Name detected in text
     - `matchedCard: Card` - Existing card that was matched
     - `confidence: Double` - Match confidence
     - `context: String?` - Text snippet where entity was mentioned

2. **Empty State Detection Logic**
   - Distinguish between:
     - **Case A**: `entities.isEmpty` (AI found nothing)
     - **Case B**: `suggestions.isEmpty && !existingMatches.isEmpty` (All duplicates)

### UI Changes:

3. **SuggestionReviewView Empty State Variants**
   - **File:** `Cumberland/AI/SuggestionReviewView.swift:164-182`
   - Replace single `emptyStateView` with:
     - `noEntitiesFoundView` - For Case A (truly empty)
     - `allExistingEntitiesView` - For Case B (all duplicates)

4. **Existing Entities List Display**
   - Show matched card name and type
   - Group by card type (Characters, Locations, etc.)
   - Optional: Show context snippet where entity was mentioned
   - Link to open matched card (tap to view)

5. **Helpful Tips**
   - For Case A: Suggest adding more descriptive text
   - For Case B: Suggest using Relationship tab to connect cards

### SuggestionEngine Changes:

6. **Track Deduplication Results**
   - **File:** `Cumberland/AI/SuggestionEngine.swift`
   - Currently: Deduplication silently filters out matches
   - Needed: Capture filtered matches and return them
   - Method: `generateCardSuggestions()` should return both new suggestions AND existing matches

7. **Existing Match Structure**
   ```swift
   struct ExistingEntityMatch: Identifiable {
       let id = UUID()
       let entityName: String
       let matchedCard: Card
       let confidence: Double
       let context: String?
   }

   struct Suggestions: Identifiable {
       var cards: [CardSuggestion]
       var relationships: [RelationshipSuggestion]
       var existingMatches: [ExistingEntityMatch] = [] // NEW

       var hasNewSuggestions: Bool {
           !cards.isEmpty || !relationships.isEmpty
       }

       var foundExistingOnly: Bool {
           !hasNewSuggestions && !existingMatches.isEmpty
       }

       var foundNothing: Bool {
           !hasNewSuggestions && existingMatches.isEmpty
       }
   }
   ```

### Implementation Details:

**Phase 1: Track Existing Matches**

1. Modify `SuggestionEngine.generateCardSuggestions()`:
   - When deduplication finds a match, add to `existingMatches` array
   - Store entity name, matched card, confidence, context
   - Return both new suggestions and existing matches

2. Update `SuggestionEngine.Suggestions` struct:
   - Add `existingMatches` property
   - Add computed properties for state detection

**Phase 2: Update Empty State UI**

3. Modify `SuggestionReviewView.emptyStateView`:
   - Check `mutableSuggestions.foundNothing` vs `mutableSuggestions.foundExistingOnly`
   - Show appropriate message for each case

4. Add `existingEntitiesSection`:
   - Grouped list of existing matches
   - Card type headers (Characters, Locations, etc.)
   - Card names with icons
   - Optional: Context snippets

**Components Affected:**

- `Cumberland/AI/SuggestionEngine.swift` - Track deduplication results, return existing matches
- `Cumberland/AI/SuggestionReviewView.swift` - Distinguish empty states, show existing matches
- `Cumberland/AI/EntityExtractor.swift` (if exists) - May need to pass through existing cards for matching

**User Scenarios:**

**Scenario 1: First Analysis (Truly Empty)**
- User writes: "The hero went to the place."
- AI finds: No specific entities (too vague)
- Empty state shows: "No Entities Detected" + tips for descriptive text
- User adds more detail: "Aria drew the Shadowblade"
- Re-analyzes: Now finds entities

**Scenario 2: Re-Analysis (All Existing)**
- User has cards: "Aria" (Character), "Shadowblade" (Artifact), "Temple of Shadows" (Building)
- User writes scene: "Aria drew the Shadowblade in the Temple of Shadows"
- AI detects all three entities
- Deduplication finds all three already exist
- Empty state shows: "No New Entities Found" + list of matched cards
- User understands: Good! Everything is already organized

**Scenario 3: Mixed Results (Some New, Some Existing)**
- User has cards: "Aria" (Character), "Temple of Shadows" (Building)
- User writes scene: "Aria drew the Shadowblade in the Temple of Shadows"
- AI detects: Aria (exists), Shadowblade (new), Temple of Shadows (exists)
- Suggestion sheet shows:
  - New Cards section: "Shadowblade" (Artifact)
  - (No empty state shown - has new suggestions)
- This scenario already works, but could be enhanced to show existing matches alongside new suggestions

**Testing Checklist:**

- [ ] Analyze card with vague text → "No Entities Detected" message
- [ ] Analyze card mentioning only existing entities → "No New Entities Found" + list
- [ ] Verify existing entities list shows correct card names and types
- [ ] Verify existing entities list groups by type
- [ ] Re-analyze same text twice → consistent results
- [ ] Analyze card with mix of new and existing → only shows new in suggestions

**Priority Justification:**

**Low Priority** because:
- **Nice-to-have**: Current behavior works, just misleading
- **User education**: Users can learn to ignore empty state on re-analysis
- **Not blocking**: Doesn't prevent any functionality
- **Polish feature**: Quality of life improvement
- **After ER-0012/0013/0014**: Higher priority features completed first

**Related:**

- ER-0010: AI Content Analysis (core entity extraction)
- ER-0012: Chronicles Card Type (new entity type for deduplication)
- Deduplication logic in SuggestionEngine

**Notes:**

This enhancement improves user trust in the AI system by:
1. **Transparency**: Shows what the AI actually found
2. **Positive reinforcement**: Acknowledges user's existing organization
3. **Actionable guidance**: Suggests next steps (relationships) instead of implying failure
4. **Reduced confusion**: Users won't think AI is broken when it finds nothing new

---

## Status Indicators

Per ER-Guidelines.md:
- 🔵 **Proposed** - Enhancement identified and documented, awaiting implementation
- 🟡 **In Progress** - Claude is actively working on this enhancement
- 🟡 **Implemented - Not Verified** - Claude completed implementation, ready for user testing
- ✅ **Implemented - Verified** - Only USER can mark after testing (move to verified batch)

---

*When user verifies an ER, move it to the appropriate ER-verified-XXXX.md file*
