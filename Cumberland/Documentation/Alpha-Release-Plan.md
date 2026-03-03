# Cumberland v1.0 Alpha Release Plan

**Created:** 2026-02-27
**Target:** Limited alpha testing via TestFlight
**Platforms:** macOS 26.0+, iOS/iPadOS 26.0+, visionOS 26.0+ (basic)

---

## Release Philosophy

Cumberland v1.0 ships the **core worldbuilding toolkit** — cards, relationships, maps, timelines, story structure, Murderboard, CloudKit sync, and the theming system. All visionOS spatial features (ER-0042 through ER-0051) are deferred to v2.0. The visionOS build in v1.0 provides basic multi-window and ornament-based navigation — functional, but not yet spatially differentiated.

---

## Current State Assessment (2026-02-27)

| Metric | Status |
|--------|--------|
| Open DRs | **0** — bug backlog clean (3 deferred) |
| Verified DRs | **87** of 101 total (86.1%) |
| Unverified ERs | **1** — ER-0037 Phase 1 (Theming) awaiting verification |
| Proposed ERs (v1.0 scope) | **0** — ER-0037 Phases 2-3 are new implementation work |
| Proposed ERs (v2.0 deferred) | **10** — ER-0042 through ER-0051 (all visionOS spatial) |
| Version in project | `1.0` (Build 1) |
| Debug code | Properly `#if DEBUG` guarded |
| CloudKit | Configured — `iCloud.CumberlandCloud` |
| Schema | Stable at `AppSchemaV5` |
| Test infrastructure | Configuration issues — manual QA is the path |

---

## Release Checklist

### Part 1: Theming System (ER-0037)

#### Step 1: Verify Phase 1 (Current Implementation)

**macOS Testing:** ✅ Completed 2026-02-27
- [x] Launch app — Default theme active, everything looks identical to pre-theme appearance (zero regression)
- [x] Open Settings > Display > Theme — picker shows "Default" and "Whimsical" with color swatches
- [x] Select "Whimsical" — observe changes:
  - [x] Sidebar and main backgrounds shift to warm parchment tones
  - [x] Card names render in serif fonts
  - [x] Glass surfaces (toolbars, buttons, panels) adopt warm solid fills instead of translucent materials
  - [x] Shadows feel warmer (brown-toned instead of pure black)
  - [x] Corner radii are slightly softer (16pt vs 12pt on cards)
- [x] Navigate through features in Whimsical theme:
  - [x] Card grid — serif fonts, warm card backgrounds
  - [x] Card detail/editor — warm surfaces
  - [x] Murderboard — themed backgrounds
  - [x] Structure Board — themed lanes
  - [x] Map Wizard — themed landing page
  - [x] Relationships tab — themed glass cards and toolbar
- [x] Switch back to Default — verify clean revert to system appearance
- [x] Quit and relaunch — verify theme choice persists
- [x] Toggle light/dark mode — verify both themes adapt correctly in both modes

**iOS Testing:**
- [x] Repeat all macOS tests on iOS device or simulator
- [x] Verify sheet presentations are themed (card editor, relationship sheets)
- [x] Verify touch interactions work normally in both themes

**visionOS Testing (if available):**
- [x] Verify materials preserved — no solid colors on spatial surfaces regardless of theme
- [x] Verify ornament controls are theme-aware

**Things to watch for (file DRs if found):**
- Any text that becomes unreadable (wrong contrast in Whimsical)
- Any surface that stays in Default style when Whimsical is selected (missed integration)
- Any crash or layout break when switching themes
- Theme picker not showing both options
- Theme not persisting after force-quit

**Outcome:** Mark ER-0037 Phase 1 as verified, or file DRs for issues found

#### Step 2: Expand ThemeColors Token Set ✅ Completed 2026-03-03
- [x] Add new tokens to `ThemeTokens.swift`: `accentTertiary`, `surfaceTertiary`, `tagBackground`, `tagText`, `destructive`, `success`
- [x] Add `ThemeBackgroundImages` struct to `Theme` protocol
- [x] Update `DefaultTheme.swift` with sensible defaults for all new tokens
- [x] Update `WhimsicalTheme.swift` with enriched multi-color palette using all new tokens

#### Step 3: Implement Background Image Support ✅ Completed 2026-03-03
- [x] Implement `SurfaceFill.textured` case fully (currently stub)
- [x] Create `ThemeBackgroundView` modifier for optional tiled/stretched image overlay
- [x] Wire into sidebar background (`MainAppView.swift`)
- [x] Wire into content/card list area (`MainAppView.swift`)
- [x] Wire into Murderboard canvas (`MurderBoardView.swift`)
- [x] Wire into Structure Board (`StructureBoardView.swift`)
- [x] Wire into Map Wizard landing (`MapWizardView.swift`)
- [x] Wire into empty state views
- [x] Wire into detail placeholder / "no selection" state
- [x] Verify visionOS suppresses background images (uses materials instead)

#### Step 4: Build Additional Themes ✅ Completed 2026-03-03
- [x] Create `PurpleTheme.swift` — deep plums, lavenders, violet accents, silver text
- [x] Create `HalloweenTheme.swift` — black, bone-white, pumpkin orange, blood red
- [ ] Create background image assets for Whimsical (parchment, cork textures) — deferred to Phase 3
- [ ] Create background image assets for Purple (optional: damask, velvet) — deferred to Phase 3
- [ ] Create background image assets for Halloween (optional: spiderweb, haunted) — deferred to Phase 3
- [ ] Add all theme assets to Assets.xcassets under `ThemeAssets/` group — deferred to Phase 3
- [x] Register new themes in `ThemeManager.init()`
- [x] Verify all themes in light and dark mode on macOS and iOS

#### Step 5: User-Defined Theme Support ✅ Completed 2026-03-03
- [x] Define `.cumberlandtheme` JSON schema
- [x] Implement `UserTheme` Codable struct conforming to `Theme` protocol
- [x] Implement `ThemeFileManager` for import/export/persistence
- [x] Register `UTType.cumberlandTheme` in Info.plist (all three platforms)
- [x] Add Import/Export buttons to Settings > Display > Theme
- [x] Implement validation with user-friendly error alerts
- [x] Implement fallback to DefaultTheme for missing/invalid fields
- [x] Verify import, export, delete, and persistence across app launches
- [x] Verify shared `.cumberlandtheme` files open correctly on another device

---

### Part 2: Placeholder & Stub Cleanup

#### Step 6: Audit Visible Stubs
- [ ] AI Generate map method: hide behind a "Coming Soon" indicator, or remove from the method picker entirely for v1.0
- [ ] Search for any other visible placeholder text, "TODO" strings, or "Coming Soon" labels in the UI
- [ ] Verify no debug-only features are accessible in Release builds
- [ ] Verify `#if DEBUG` guards are correctly excluding developer tools

---

### Part 3: Platform Scoping

#### Step 7: visionOS v1.0 Scope Confirmation
- [ ] Basic visionOS features verified: multi-window, ornaments, navigation
- [ ] All 10 spatial ERs (ER-0042 through ER-0051) confirmed deferred to v2.0
- [ ] visionOS theme falls back to materials gracefully (already handled by `platformResolved`)
- [ ] No broken or half-implemented visionOS features visible to users
- [ ] Decision: include visionOS build in alpha, or defer visionOS TestFlight to v1.1/v2.0?

---

### Part 4: Build Configuration & App Store Setup

#### Step 8: Entitlements & Signing
- [ ] Change APS environment from `development` to `production` in `Cumberland.entitlements`
- [ ] Verify CloudKit container is configured for production environment
- [ ] Verify app group identifiers are correct (`group.com.caposoft.Cumberland`)
- [ ] Verify keychain sharing configuration
- [ ] Verify code signing for all three platform targets (macOS, iOS, visionOS)
- [ ] Verify provisioning profiles are valid and not expired

#### Step 9: App Store Connect Setup
- [ ] Create App Store Connect record for Cumberland
- [ ] Register bundle identifier (`com.caposoft.Cumberland` or equivalent)
- [ ] Configure TestFlight for alpha distribution
- [ ] Set up internal testing group (immediate access, no review)
- [ ] Set up external testing group if needed (requires Beta App Review)

#### Step 10: App Store Metadata
- [ ] App name: "Cumberland"
- [ ] Subtitle (30 characters max): decide on tagline
- [ ] App description (4000 characters max)
- [ ] Category: Productivity (primary), Entertainment or Reference (secondary)
- [ ] App icon verified across all platforms and sizes
- [ ] Screenshots: macOS (at least 1 size)
- [ ] Screenshots: iOS/iPadOS (at least 2 sizes)
- [ ] Screenshots: visionOS (optional for alpha)
- [ ] Privacy policy URL (required for App Store — can be a simple page)
- [ ] Age rating questionnaire completed
- [ ] Support URL configured

---

### Part 5: Quality Assurance

#### Step 11: Manual QA — Core Features

**macOS Full Walkthrough:**
- [ ] Launch app, create a new project with cards of various Kinds
- [ ] Test card creation, editing, deletion for each Kind
- [ ] Test image import (file picker, photos, drag & drop)
- [ ] Test relationship creation and editing (CardEdge + RelationType)
- [ ] Test Murderboard: add nodes, create edges, drag, select, delete
- [ ] Test Structure Board: assign cards to structure elements, drag between lanes
- [ ] Test Map Wizard: Import method, Draw method, Maps capture method
- [ ] Test Drawing Canvas: layers, brushes, save, resume
- [ ] Test Timeline: assign temporal positions, navigate
- [ ] Test Citations: add sources, create citations, verify attribution
- [ ] Test Settings: all preferences work and persist
- [ ] Test Theme switching: Default, Whimsical, Purple, Halloween, back to Default
- [ ] Test window management: multiple windows, window restoration
- [ ] Test keyboard shortcuts

**iOS/iPadOS Full Walkthrough:**
- [ ] Same feature checklist as macOS, adapted for touch/Pencil
- [ ] Test Apple Pencil support in Drawing Canvas
- [ ] Test sheet-based editing (CardSheetView)
- [ ] Test navigation flow: sidebar, card list, card detail
- [ ] Test multitasking (Split View, Slide Over)
- [ ] Test orientation changes (portrait, landscape)

**visionOS Basic Walkthrough:**
- [ ] Launch app, verify main window appears
- [ ] Verify ornament-based controls work
- [ ] Test basic card creation and editing
- [ ] Verify multi-window support (open card in new window)
- [ ] Verify theme materials render correctly

#### Step 12: Manual QA — Data & Sync

- [ ] CloudKit sync: create card on macOS, verify appears on iOS (and vice versa)
- [ ] CloudKit sync: edit card on one device, verify update propagates
- [ ] CloudKit sync: delete card on one device, verify removal propagates
- [ ] CloudKit sync: image data syncs correctly (external storage / CKAsset)
- [ ] CloudKit sync: relationships sync correctly
- [ ] Offline mode: create/edit cards while offline, verify sync when reconnected
- [ ] Data migration: fresh install (no existing data) — app launches cleanly
- [ ] Data migration: existing data — schema migrations apply cleanly

#### Step 13: Manual QA — Edge Cases

- [ ] Large project: 100+ cards — verify performance (scrolling, search, filtering)
- [ ] Empty project: no cards — verify empty states are friendly and functional
- [ ] Long text: very long card names, subtitles, detailed text — verify layout doesn't break
- [ ] Large images: high-resolution photos as card images — verify memory and performance
- [ ] Rapid theme switching: switch themes repeatedly — verify no state corruption
- [ ] Background/foreground: suspend and resume the app — verify state preserved
- [ ] Low storage: verify app handles insufficient storage gracefully (CloudKit assets)

---

### Part 6: Alpha Distribution

#### Step 14: Alpha Logistics

- [ ] Decide alpha group size and composition (5? 10? 20 testers?)
- [ ] Identify alpha testers (friends, writing community, beta testing community)
- [ ] Prepare alpha tester communication: expectations, known limitations, feedback channel
- [ ] Set up feedback mechanism:
  - TestFlight built-in feedback (screenshot + text)
  - Consider "Send Feedback" button in Settings > About (opens email compose or form)
  - Consider a dedicated feedback channel (Discord, email alias, GitHub Issues)
- [ ] Crash reporting: TestFlight provides crash logs automatically; consider supplementary analytics

#### Step 15: TestFlight Submission

- [ ] Increment build number for each upload (1, 2, 3...)
- [ ] Archive macOS build and upload to App Store Connect
- [ ] Archive iOS build and upload to App Store Connect
- [ ] Archive visionOS build and upload (if including in alpha)
- [ ] Wait for App Store processing (usually 15-30 minutes)
- [ ] Write alpha release notes:
  - What to test
  - Known limitations (visionOS spatial features deferred, AI generation placeholder, test infrastructure issues)
  - How to report bugs and feedback
  - What's coming in future builds
- [ ] Add testers to TestFlight group
- [ ] Send invitation communication to testers

#### Step 16: Alpha Tester Release Notes Template

```
Cumberland v1.0 Alpha Build [N]

Welcome to the Cumberland alpha! This build includes the core worldbuilding
toolkit for macOS and iOS/iPadOS. visionOS is included with basic functionality.

WHAT TO TEST:
- Card creation, editing, and deletion (all 14 card types)
- Relationships and the Murderboard
- Map creation (Import, Draw, Maps Capture)
- Story Structure Board
- Timeline
- Theme switching (Settings > Display > Theme)
- CloudKit sync between devices
- Custom theme import/export (.cumberlandtheme files)

KNOWN LIMITATIONS:
- AI Map Generation: placeholder only, not yet functional
- visionOS: basic multi-window support only; spatial features coming in v2.0
- Test automation: manual testing only for this build

HOW TO REPORT ISSUES:
- Use TestFlight's built-in feedback (shake device or screenshot)
- [Additional feedback channel details]

Thank you for testing Cumberland!
```

---

### Part 7: Post-Alpha

#### Step 17: Alpha Feedback Loop

- [ ] Monitor TestFlight crash reports daily during first week
- [ ] Triage tester feedback: file DRs for bugs, ERs for feature requests
- [ ] Prioritize critical/high severity issues for immediate fix builds
- [ ] Plan subsequent alpha builds (v1.0 Build 2, Build 3...) addressing feedback
- [ ] Track alpha stability metrics: crash-free sessions, active testers, feedback volume

#### Step 18: Path to v1.0 GM (Gold Master)

- [ ] All critical DRs from alpha resolved
- [ ] All high-priority DRs from alpha resolved (or documented as known issues)
- [ ] Final QA pass on GM candidate build
- [ ] App Store submission for review
- [ ] Prepare marketing materials (website, social, press kit)
- [ ] Plan v1.0 launch communication

#### Step 19: v2.0 Planning (Post-Launch)

- [ ] Begin visionOS spatial features (ER-0042 through ER-0051)
- [ ] Incorporate alpha/v1.0 tester feedback into v2.0 roadmap
- [ ] AI Map Generation implementation
- [ ] Localization deployment (ER-0038 infrastructure verified)
- [ ] Advanced Drawing Canvas features (layers, shapes, text)
- [ ] Image history and AI generation tracking (future schema migration)

---

## Version Strategy

| Version | Scope | Distribution |
|---------|-------|-------------|
| **v1.0 Alpha** | Core features + theming | TestFlight, limited testers |
| **v1.0 Beta** | Alpha fixes + polish | TestFlight, expanded testers |
| **v1.0 GM** | Final release candidate | App Store submission |
| **v1.0** | Public release | App Store |
| **v1.x** | Bug fixes, minor features from feedback | App Store updates |
| **v2.0** | visionOS spatial workspace, AI generation | App Store |

---

## Cross-References

- **ER-0037:** Theming System — Multi-Color Themes, Background Images & User-Defined Themes
- **ER-0042 through ER-0051:** visionOS Spatial Features (deferred to v2.0)
- **DR-Reports/DR-Documentation.md:** Bug tracking index
- **DR-Reports/ER-Documentation.md:** Enhancement tracking index
- **DR-Reports/ER-Guidelines.md:** ER documentation standards
- **DR-Reports/DR-GUIDELINES.md:** DR documentation standards

---

*Last Updated: 2026-02-27*
