# Discrepancy Reports (DR) - Unverified Issues

- Guidelines: [Cumberland/DR-Reports/DR-Guidelines.md]

This document tracks recent discrepancy reports that are open or awaiting user verification.

**Status:** Currently **1 open DRs** | **0 resolved, awaiting verification**

---

## DR-0115: SearchEngineTests — 4 Tests Fail in Suite but Pass Individually (Concurrency/Context Isolation)

**Status:** 🔴 Identified - Not Resolved
**Component:** Testing / SwiftData
**Severity:** Medium
**Date Identified:** 2026-04-09
**Related ER:** ER-0052 (Phase 1.4 - Search Engine Tests)

**Affected Tests:**
- `searchNormalizesWhitespace()`
- `searchNormalizesPunctuation()`
- `searchRanksByFieldPriority()`
- `searchCombinesWithMultipleFilters()`

**Current Behavior:**

These 4 tests in `CumberlandTests/Search/SearchEngineTests.swift` consistently FAIL when run as part of the full test suite but PASS when run individually in isolation.

**Test Symptoms:**
- All 4 tests return 0 search results when expecting 1+ results
- Cards are created successfully via `CardOperationManager`
- Search engine executes without errors
- Normalized search text appears to be empty or not matching

**Root Cause Analysis:**

SwiftData context timing/isolation issue in Swift Testing framework. Despite the test suite being marked with `.serialized`, there appears to be a concurrency or context snapshot problem where:

1. Cards created via `CardOperationManager.createCard()` are inserted and saved to context
2. The `SwiftDataSearchEngine` queries the same context reference
3. But the search returns no results, suggesting the saved cards aren't visible to the search query

**Previously Attempted Fixes:**
- ✅ Added `.serialized` to `@Suite` annotation (already present)
- ✅ Removed redundant `context.insert()` calls after `CardOperationManager.createCard()`
- ✅ Added explicit `try context.save()` after card creation
- ✅ Enhanced Card normalization logic (whitespace + punctuation)
- ✅ Enhanced SearchEngine query normalization (whitespace + punctuation)
- ❌ Issue persists

**Key Implementation Details:**

Each test follows this pattern:
```swift
@Test("Test name")
@MainActor
func testName() async throws {
    let (_, context) = try TestFixtures.makeFullSchemaContainer()
    let engine = SwiftDataSearchEngine(context: context)

    let card = try createCard(kind: .characters, name: "Test Name", ...)
    try context.save()  // Already saved by CardOperationManager, but explicit save added

    let results = await engine.search("test", maxResults: 10)
    #expect(results.count == 1)  // FAILS: returns 0 in suite, 1 when isolated
}
```

Helper method:
```swift
private func createCard(..., context: ModelContext) throws -> Card {
    let mgr = CardOperationManager(modelContext: context)
    return try mgr.createCard(kind: kind, name: name, ...)  // Inserts + saves internally
}
```

**Historical Context:**

User reports: "I distinctly remember you fumbling around with the concurrency fixes yesterday (or earlier) and having the same trouble you are having now and eventually Having to go through a number of hoops before you finally fixed it."

**The fix from that previous session was NOT documented.** This DR is being created to ensure the solution isn't lost this time.

**Files Affected:**
- `CumberlandTests/Search/SearchEngineTests.swift:416-565` (4 failing tests)
- `Cumberland/Search/SearchEngine.swift` (enhanced normalization)
- `Cumberland/Model/Card.swift` (enhanced normalizedSearchText computation)

**Next Steps:**

1. Check for git branches that may contain the previous fix
2. Investigate SwiftData context isolation patterns in passing vs failing tests
3. Consider alternative test infrastructure (separate contexts, explicit transactions, etc.)
4. Document the working solution in ER-0052 once found

**Workaround:**

Tests pass when run individually:
```bash
xcodebuild test -scheme Cumberland-macOS -only-testing:CumberlandTests/SearchEngineTests/searchNormalizesWhitespace
```

---

## Recently Verified

- **DR-0114:** CalendarExtractionTests Disabled via `#if false` — Re-enable with Container Fix — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0113:** EntityExtractionTests Disabled via `#if false` — Re-enable with API Fixes — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0112:** ImageGenerationWorkflowTests Disabled via `#if false` — Re-enable with Type and Container Fixes — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0111:** VisualElementExtractorTests — Optional Comparison Bug and Compound Word Match — ✅ Verified 2026-03-30 -> [Batch 12](./DR-verified-0111-0120.md)
- **DR-0110:** KeychainHelperTests — Keychain Operations Fail in Hosted Test Environment — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0109:** CardModelTests — normalizedSearchText Not Updated After Property Mutation — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0108:** AISettingsTests — Not Meeting Expectations — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0107:** AIImageGeneratorTests — Test Expects Success From Placeholder Implementation — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0106:** AIProviderTests — analyzeText Test String Below 25-Word Minimum — ✅ Verified 2026-03-30 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0105:** Test Infrastructure — Migrate Factories to Service Managers — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0104:** BoardManager Service — Centralize Board/BoardNode CRUD — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0103:** RelationTypeManager Service — Centralize RelationType CRUD — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0102:** TestFixtures Crash on context.insert() — ✅ Verified 2026-03-29 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0101:** Theme Color Swatches Not Visible in Settings Picker — ✅ Verified 2026-02-27 -> [Batch 11](./DR-verified-0101-0110.md)
- **DR-0099:** iOS/visionOS Targets Missing File Memberships — Build Failures — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
- **DR-0100:** Auxiliary Windows Restore on App Launch Instead of Main UI — ✅ Verified 2026-02-27 -> [Batch 10](./DR-verified-0091-0100.md)
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

*Last Updated: 2026-03-30*
