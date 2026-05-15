# ER-0038: Localization Infrastructure

**Status:** ✅ Verified
**Component:** Infrastructure / Internationalization
**Priority:** Medium
**Date Requested:** 2026-02-22
**Date Implemented:** 2026-02-22
**Date Verified:** 2026-02-23

**Rationale:**
Cumberland currently ships English-only. Localization infrastructure is needed to support international users. Apple's modern String Catalog system makes this feasible with minimal disruption, but the codebase needs an audit to ensure all user-facing strings are properly externalized.

**Current Behavior:**
All user-facing strings are hardcoded in English throughout SwiftUI views, view models, and utility functions. No `.xcstrings` String Catalog exists. Some strings are user-generated content (card names, relationship types, detailed text) which should NOT be translated.

**Desired Behavior:**
All UI chrome strings (labels, buttons, headers, alerts, empty states, tooltips) are externalized into a String Catalog. The app can be localized to additional languages by providing translations without code changes. User-generated content remains untranslated.

**Implementation Summary:**
- **Phase 1:** String Catalog (`.xcstrings`) created in Xcode with all 3 target memberships
- **Phase 2:** 12 enums (~80 string literals) converted to `String(localized:)` — `rawValue` preserved for persistence
  - `Kinds.title`, `Kinds.singularTitle`, `SettingsSection.title`, `CardDetailTab.title`, `CardDetailTab.helpText`, `WizardStep.title`, `InteriorUnits.displayName`, `PaletteTab.displayName`, `ColorSchemePreference.displayName`, `CitationKind.displayName`, `SizeCategory.displayName`, `BacklogSortOption.label`, `MapStyleType.displayName`, `MapCreationMethod.description`, `AnalysisScope.displayName`, `AnalysisScope.description`
- **Phase 3:** 28 RelationType seed labels (56 strings) localized via `String(localized: String.LocalizationValue(variable))` at construction time in `CumberlandApp.swift`
- **Phase 4:** Programmatic strings — `MainAppView` empty state messages and `SettingsView.emptyMessage` wrapped in `String(localized:)` with interpolation
- **Phase 5:** `Text(verbatim:)` added to 18 user-content display sites across 12 files to prevent spurious localization lookups
- **Phase 6:** Build verified successful across all targets

**Files Modified:**
- `Localizable.xcstrings` (NEW)
- `Model/Kinds.swift`, `SettingsView.swift`, `CardDetailTab.swift`, `MapWizardView.swift`
- `DrawCanvas/ToolPaletteState.swift`, `Model/AppSettings.swift`, `Model/CitationKind.swift`
- `Model/Card.swift`, `Murderboard/MurderBoardView.swift`, `AI/Models/AISettings.swift`
- `CumberlandApp.swift`, `MainAppView.swift`
- `CardView.swift`, `SidebarPanel.swift`, `CardSheetHeaderView.swift`, `BacklogCardDetailSheet.swift`
- `CardRelationshipSheets.swift`, `CardDiagnosticsView.swift`, `AggregateTextView.swift`
- `SourcesView.swift`, `StoryStructureView.swift`, `LayersTabView.swift`, `InspectorTabView.swift`

**Notes:**
- Ships English-only — no translations included; additional languages are separate ERs
- 56 RelationType seed strings require manual catalog entry (not auto-extracted from variable-based `String.LocalizationValue`)
- Enum `rawValue` properties untouched — only display computed properties changed
- User-generated content (card names, relationship labels, detailed text) explicitly excluded via `Text(verbatim:)`
