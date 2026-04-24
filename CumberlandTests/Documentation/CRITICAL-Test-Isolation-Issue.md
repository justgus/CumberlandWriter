# CRITICAL: Test Isolation Failure - Production Data Contamination

**Date**: 2026-04-24
**Severity**: CRITICAL
**Status**: ACTIVE ISSUE

---

## Executive Summary

**YOU WERE ABSOLUTELY CORRECT.** The issue is NOT SwiftData's inability to handle multiple ModelContainers. The real problem is that **95 tests are sharing the PRODUCTION CloudKit container** and simultaneously attempting to wipe all data from it.

## Evidence

### 1. Production Data Contamination
Your production CloudKit database contains test data:
- Character: "Primary"
- Character: "Knight-Commander"
- Character: "Sir Aldric the Bold, Knight-Commander of the Silver Legion..."
- Character: "Marcus Swiftwind" (ranger)
- Artifact: "Sword of Dawn"
- Character: "Queen Elara"
- Character: "Merlin" (wizard)

**This is test fixture data that should NEVER appear in production.**

### 2. Root Cause: `TestFixtures.makeFullSchemaContainer()`

**File**: `/Users/justgus/Xcode-Projects/Cumberland/CumberlandTests/TestFixtures.swift:413-439`

```swift
@MainActor
static func makeFullSchemaContainer() throws -> (ModelContainer, ModelContext) {
    containerLock.lock()
    defer { containerLock.unlock() }

    guard let container = CumberlandApp.sharedContainer else {
        fatalError("CumberlandApp.sharedContainer is nil — tests must run inside the hosted app.")
    }
    let context = ModelContext(container)
    context.autosaveEnabled = false

    // Wipe all data so each test starts with a clean store.
    // Delete in dependency order: edges first, then nodes, then top-level entities.
    try context.delete(model: CardEdge.self)
    try context.delete(model: BoardNode.self)
    try context.delete(model: Citation.self)
    try context.delete(model: StructureElement.self)
    try context.delete(model: StoryStructure.self)
    try context.delete(model: Board.self)
    try context.delete(model: ImageVersion.self)
    try context.delete(model: Source.self)
    try context.delete(model: RelationType.self)
    try context.delete(model: Card.self)
    try context.delete(model: CalendarSystem.self)
    try context.delete(model: AppSettings.self)
    try context.save()

    return (container, context)
}
```

### 3. What `CumberlandApp.sharedContainer` Actually Is

**File**: `/Users/justgus/Xcode-Projects/Cumberland/Cumberland/CumberlandApp.swift:43,211`

```swift
@MainActor static private(set) var sharedContainer: ModelContainer?

@State private var modelContainer: ModelContainer = {
    let container = makeContainer()
    sharedContainer = container  // ← Sets the static property
    return container
}()
```

This is **THE PRODUCTION APP'S CONTAINER**, which by default uses:
- **CloudKit container**: `iCloud.CumberlandCloud`
- **Local persistent store**: On-disk database

### 4. Affected Tests (95 instances)

Tests using `makeFullSchemaContainer()`:
- **All Repository tests**: CardRepositoryTests (10), EdgeRepositoryTests (10), StructureRepositoryTests (9)
- **All Service tests**: CitationManagerTests, CardOperationManagerTests, RelationshipManagerTests
- **All CloudKit tests**: SchemaV1toV2MigrationTests, SchemaV2toV3MigrationTests, SchemaV3toV5MigrationTests, ExternalStorageTests, DesyncRecoveryTests, MigrationStabilityTests
- **All Core Model tests**: BoardModelTests (8), CardModelTests (4)
- **Other tests**: StructureAssignmentManagerTests, CumberlandBoardAdapterTests, CumberlandBoardDataSourceTests, ImageGenerationWorkflowTests, ServiceIntegrationTests, MultiTimelineTests, TemporalPositioningTests, EntityExtractionTests, CalendarExtractionTests

**Total: 95 test methods across 20+ test files**

---

## How The Error Occurs

### Scenario: Parallel Test Execution

1. **Test A** calls `makeFullSchemaContainer()`
   - Acquires lock
   - Gets reference to `CumberlandApp.sharedContainer` (production)
   - Deletes ALL Card objects from production
   - Releases lock
   - **Test A still holds Card references from production container**

2. **Test B** (running in parallel) calls `makeFullSchemaContainer()`
   - Acquires lock (Test A released it)
   - Gets reference to SAME `CumberlandApp.sharedContainer`
   - Deletes ALL Card objects from production AGAIN
   - **This destroys the objects Test A is still using**
   - Calls `context.save()`

3. **Test A** tries to access `card.id`
   - **CRASH**: "This model instance was destroyed by calling ModelContext.reset and is no longer usable"

### Why The Lock Doesn't Help

The `containerLock` in `TestFixtures.swift:414` is released immediately after container creation (line 415), NOT after the test completes. This means:

```
Test A: [Lock] → Create context → Delete all data → [Unlock] → ... test runs ...
Test B:                                                    [Lock] → Create context → Delete all data → [Unlock] → ... test runs ...
                                                                                                    ↑
                                                                          Test A's objects are now destroyed!
```

---

## Historical Context (From DR Reports)

### ER-0058 (Already Identified This Problem!)

**File**: `/Users/justgus/Xcode-Projects/Cumberland/Cumberland/DR-Reports/ER-verified-0058.md:132-138`

> **Before ER-0058:**
> - All tests used `CumberlandApp.sharedContainer` (production container)
> - `TestFixtures.makeFullSchemaContainer()` wiped data with `containerLock` protection
> - Lock released after container creation, NOT after test completion
> - **Result: 30+ tests failing due to data being wiped mid-test by other tests**

**ER-0058 was supposed to fix this**, but looking at the current code, `makeFullSchemaContainer()` STILL uses `CumberlandApp.sharedContainer`!

### DR-0101-0110 (Documented The Approach)

> 1. Exposed host app's `ModelContainer` to tests (`CumberlandApp.swift`) via `@MainActor static private(set) var sharedContainer`
> 2. Rewrote `makeFullSchemaContainer()` to reuse host container with fresh `ModelContext` per call

**This was the design decision that caused the problem.**

---

## Why This Is CRITICAL

### 1. Data Loss Risk
Tests are **deleting production data**. If a test runs while you're actively using the app:
- All your characters, scenes, locations get deleted
- CloudKit may sync these deletes to other devices
- **PERMANENT DATA LOSS**

### 2. CloudKit Quota Concerns
Every test that calls `makeFullSchemaContainer()`:
- Deletes potentially thousands of records from CloudKit
- CloudKit charges for operations and storage
- Running 95 tests × multiple times = massive CloudKit API usage

### 3. Test Unreliability
Tests are not isolated:
- Test results depend on execution order
- Parallel execution causes random failures
- Cannot trust test results

### 4. Production Database Pollution
Your production database already has test data (Sir Aldric, etc.), proving tests are writing to production.

---

## The Correct Solution

### Option 1: In-Memory Containers (RECOMMENDED)

**Replace** `TestFixtures.makeFullSchemaContainer()` with `TestFixtures.makeIsolatedContainer()` (which already exists!):

```swift
// TestFixtures.swift:338-342
static func makeIsolatedContainer() throws -> (ModelContainer, ModelContext) {
    let schema = Schema(AppSchemaV5.models)
    let container = try DataBackend.makeContainer(mode: .inMemory, schema: schema)
    let context = ModelContext(container)
    context.autosaveEnabled = false
    return (container, context)
}
```

This creates:
- ✅ In-memory storage (no persistence)
- ✅ Isolated per test
- ✅ No CloudKit connection
- ✅ Fast
- ✅ Safe

### Option 2: Deprecate `makeFullSchemaContainer()` Entirely

Mark it as deprecated and force all tests to use `makeIsolatedContainer()`:

```swift
@available(*, deprecated, message: "Use makeIsolatedContainer() instead - this method writes to production!")
static func makeFullSchemaContainer() throws -> (ModelContainer, ModelContext) {
    fatalError("DEPRECATED: This method writes to production database. Use makeIsolatedContainer() instead.")
}
```

### Option 3: Fix The Lock Scope (NOT RECOMMENDED)

Extend the lock lifetime to cover the entire test, but this:
- Still uses production storage
- Serializes all tests (slow)
- Doesn't prevent data pollution
- Is architecturally wrong

---

## Immediate Action Required

### 1. Stop Running Tests (URGENT)
Until this is fixed, **DO NOT run tests** - they are corrupting your production database.

### 2. Clean Production Database
Your CloudKit production database has test data. You'll need to:
- Manually delete test characters (Sir Aldric, Marcus Swiftwind, etc.)
- Or reset the production database entirely

### 3. Migrate Tests
Replace all 95 instances of `makeFullSchemaContainer()` with `makeIsolatedContainer()`:

```bash
# Find all usages
cd /Users/justgus/Xcode-Projects/Cumberland/CumberlandTests
grep -r "makeFullSchemaContainer" . --include="*.swift"

# Replace (after verification)
find . -name "*.swift" -exec sed -i '' 's/makeFullSchemaContainer/makeIsolatedContainer/g' {} \;
```

### 4. Add Safeguard
Add a compile-time error to `makeFullSchemaContainer()`:

```swift
static func makeFullSchemaContainer() throws -> (ModelContainer, ModelContext) {
    #error("DEPRECATED: Use makeIsolatedContainer() - this method writes to PRODUCTION!")
    // ... existing code ...
}
```

---

## Verification

After migration, verify:

1. ✅ No test uses `makeFullSchemaContainer()`
2. ✅ All tests use `makeIsolatedContainer()` or create their own in-memory containers
3. ✅ Run tests and verify no production data appears
4. ✅ Check CloudKit dashboard - no new test data
5. ✅ Tests pass without ModelContext.reset errors

---

## Conclusion

**You were 100% correct** to challenge my assumption. The issue is NOT SwiftData's limitation with multiple containers. The issue is:

1. **95 tests share the production CloudKit container**
2. **Each test deletes ALL data from production**
3. **Parallel execution causes tests to destroy each other's data mid-test**
4. **Production database is contaminated with test data**

The solution is simple: **Use isolated in-memory containers** (`makeIsolatedContainer()`), which already exists in the codebase but isn't being used.

**Priority**: CRITICAL - Fix immediately before any more test runs corrupt production data.
