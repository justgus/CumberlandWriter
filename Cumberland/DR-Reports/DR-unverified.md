# Discrepancy Reports (DR) - Unverified Issues

- Guidelines: [Cumberland/DR-Reports/DR-Guidelines.md]

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **0 open DRs** | **1 resolved, awaiting verification**

---

## DR-0099: iOS/visionOS Targets Missing File Memberships — Build Failures

**Status:** 🟡 Resolved - Not Verified
**Severity:** High
**Platform:** iOS, visionOS
**Component:** Build System / Xcode Project Configuration
**Date Identified:** 2026-02-27
**Date Resolved:** 2026-02-27

**Description:**
Multiple Swift files were missing from the iOS and visionOS target membership exceptions in `project.pbxproj`. Because Cumberland uses `PBXFileSystemSynchronizedBuildFileExceptionSet` (where `membershipExceptions` for non-primary targets means "files explicitly included"), any new file added to the `Cumberland/` folder is automatically compiled for macOS but must be manually added to the iOS and visionOS exception lists.

**Root Cause:**
When new files were created (e.g., `Theming/*.swift`, `Services/EdgeIntegrityMonitor.swift`, `Diagnostic Views/RelationshipAuditView.swift`, `Murderboard/BacklogCardDetailSheet.swift`), they were added to the filesystem-synchronized `Cumberland/` folder and automatically picked up by the macOS target. However, they were not added to the `membershipExceptions` arrays for the iOS (`Cumberland IOS`) and visionOS (`Cumberland_visionOS`) targets.

**Files that were missing:**
- `Theming/DefaultTheme.swift`
- `Theming/Theme.swift`
- `Theming/ThemeEnvironment.swift`
- `Theming/ThemeManager.swift`
- `Theming/ThemeTokens.swift`
- `Theming/WhimsicalTheme.swift`
- `Services/EdgeIntegrityMonitor.swift`
- `Diagnostic Views/RelationshipAuditView.swift`
- `Murderboard/BacklogCardDetailSheet.swift`

**Resolution:**
User manually added all missing files to the correct build targets via Xcode's target membership inspector. Additionally, `CardRelationshipView.swift` body was refactored to extract sheet views into separate computed properties to resolve a Swift type-checker timeout on the iOS target (the body was ~190 lines with many chained `.sheet()` modifiers).

**Code Changes:**
- `Cumberland.xcodeproj/project.pbxproj` — Added missing files to iOS and visionOS `membershipExceptions` (user-performed via Xcode GUI)
- `CardRelationshipView.swift` — Extracted `mainContent`, `addCardSheet`, `existingPickerSheet()`, `createRelationTypeSheet`, `pickRelationTypeSheet`, `retypeSheet`, `editCardSheet`, `manageRelationTypesSheet`, `changeCardTypeSheet` from monolithic `body`

**Prevention:**
When creating new Swift files in the `Cumberland/` folder, always verify target membership includes all three platform targets (macOS, iOS, visionOS) in Xcode's File Inspector.

**Verification Steps:**
1. Build `Cumberland-macOS` scheme — should succeed
2. Build `Cumberland IOS` scheme — should succeed
3. Build `Cumberland_visionOS` scheme — should succeed
4. Run on iOS simulator — verify app launches and basic navigation works
5. Open a card's Relationships tab on iOS — verify sheets open correctly (validates the CardRelationshipView refactor)

---

## Recently Verified

- **DR-0098:** Complete Relationship Loss for Single Card — ✅ Verified 2026-02-22 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0096:** BoardGestureIntegration Modifies @Binding State During View Body Evaluation — ✅ Verified 2026-02-18 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0095:** Map Wizard Cannot Save Drawn Map — ✅ Verified 2026-02-16 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0094:** Image History Restore Does Not Update CardEditorView — ✅ Verified 2026-02-14 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0092:** visionOS Settings Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0093:** visionOS Developer Tools Presented as Modal Sheet Instead of Window — ✅ Verified 2026-02-12 -> [Batch 10](./DR-verified-0091-0100.md)

---

## Status Indicators

Per DR-GUIDELINES.md:
- 🔴 **Identified - Not Resolved** - Issue found and root cause analyzed, awaiting fix
- 🟡 **Resolved - Not Verified** - Claude can mark when implementation is complete
- ✅ **Resolved - Verified** - Only USER can mark after testing

---

*Last Updated: 2026-02-27*
