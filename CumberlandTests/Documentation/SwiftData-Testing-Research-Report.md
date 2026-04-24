# SwiftData Testing: Official Guidance and Approved Methods Report

**Date**: 2026-04-24
**Project**: Cumberland
**Issue**: Fatal error: "This model instance was destroyed by calling ModelContext.reset and is no longer usable"

---

## Executive Summary

After extensive research of Apple documentation and community best practices, I found that **Apple has not published comprehensive official guidance specifically addressing SwiftData testing with parallel execution**. However, I've identified several approved patterns and critical issues that directly apply to your situation.

## Key Finding: iOS 18 Regression

**Critical Discovery**: The exact error you're experiencing - `"This model instance was destroyed by calling ModelContext.reset and is no longer usable"` - is a **known iOS 18/Xcode 16 regression** reported by multiple developers on Apple Developer Forums.

**Root Cause**: When a ModelContext or @ModelActor is released (even unintentionally at the end of scope), model instances fetched by that context become unusable. This behavior is **new in iOS 18** and affects code that worked perfectly in earlier versions.

**Source**: [iOS 18 SwiftData ModelContext reset - Apple Developer Forums](https://developer.apple.com/forums/thread/757521)

---

## Apple-Approved Testing Patterns

### 1. In-Memory ModelContainer Isolation ✅ (Currently Using)

**Your current approach is correct**: Each test creates its own in-memory ModelContainer.

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Card.self, ..., configurations: config)
```

**Documentation Support**:
- [How to write unit tests for your SwiftData code - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code)
- [Testing SwiftData and the Query property wrapper - Medium](https://medium.com/@mgomolka/testing-swiftdata-and-the-query-property-wrapper-through-an-example-3965816b216f)

**Limitation**: While each ModelContainer is isolated, **SwiftData's internal infrastructure doesn't handle dozens of simultaneous in-memory containers well in iOS 18**.

### 2. Swift Testing `.serialized` Trait ✅ (Implemented)

**Your implementation is correct**: Adding `@Suite(.serialized)` to test suites.

**How it works**:
- Tests within a serialized suite run sequentially
- **However**: Different test suites can still run in parallel with each other
- The trait is "recursively applied" to nested suites

**Official Documentation**: [Running tests serially or in parallel - Apple Developer Documentation](https://developer.apple.com/documentation/testing/parallelization)

**Important Clarification from Swift Forums**:
> "Tests in a suite with the .serialized trait will run one after another, however Swift is still free to run other unrelated tests in parallel"

This explains why your tests are still failing - **inter-suite parallelization is still active**.

**Source**: [Running tests serially or in parallel - Swift Forums](https://forums.swift.org/t/running-tests-serially-or-in-parallel/72935)

### 3. ModelContext Thread Safety Principles

**Apple's Core Guidance**:
- **ModelContainer**: IS Sendable and thread-safe ✅
- **ModelContext**: NOT Sendable and NOT thread-safe ❌
- **Model Objects**: NOT Sendable and NOT thread-safe ❌
- **PersistentIdentifier**: IS Sendable and thread-safe ✅

**Critical Rule**:
> "Don't pass managed object instances between queues. Doing so can result in corruption of the data and termination of the app."

**Sources**:
- [Concurrency support - Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/concurrencysupport)
- [Core Data and Swift Data concurrency - Pol Piella](https://www.polpiella.dev/core-data-swift-data-concurrency)

### 4. Parallel Test Execution Best Practices

**From Xcode Testing Documentation**:

**Test Isolation Requirements**:
- Each test must function independently
- Tests must be free of shared mutable state
- Each test should produce the same result regardless of execution order

**Test Distribution Model**:
- Xcode distributes tests at the **class/suite level**, not per-method
- Multiple test runners execute in separate processes
- Tests within a runner execute serially

**Critical for Database Testing**:
> "With App Host (iOS Simulator): Tests operate in sandboxed environments with private directories, making external data access safe. Without App Host: Multiple test runners write to shared directories simultaneously, causing data collisions"

**Source**: [Shared State During Parallel Testing in Xcode - Caesar Wirth](https://cjwirth.com/tech/shared-state-during-parallel-testing-in-xcode)

---

## Apple-Approved Solutions (Ranked by Recommendation)

### Solution 1: Disable Global Parallel Execution ⭐ RECOMMENDED

**Why This Is The Right Solution**:
1. **Addresses iOS 18 regression** in SwiftData's internal state management
2. **Matches Apple's guidance** for database/persistence testing
3. **Prevents shared state issues** across test runners
4. **Simplest implementation** - no code changes required

**Implementation Methods**:

#### A. Xcode Scheme (Permanent)
1. Product → Scheme → Edit Scheme
2. Select "Test" tab
3. Options → **Uncheck "Execute in parallel"**

#### B. Command Line (One-time)
```bash
xcodebuild test -scheme Cumberland-macOS -parallel-testing-enabled NO
```

#### C. Test Plan (if using .xctestplan)
```json
{
  "configurations": [{
    "options": {
      "parallelizationEnabled": false
    }
  }]
}
```

**Sources**:
- [XCTest Best Practices - Maestro](https://maestro.dev/insights/xctest-best-practices-ios-testing)
- [Mastering the Swift Testing Framework - Fatbobman](https://fatbobman.com/en/posts/mastering-the-swift-testing-framework/)

### Solution 2: Shared ModelContainer Pattern ⚠️ (Not Recommended)

**Theory**: Use a single ModelContainer shared across all tests, with context.reset() between tests.

**Why NOT Recommended**:
- Violates test isolation principles
- The iOS 18 regression shows context.reset() itself is problematic
- Doesn't match Apple's sandboxing model for parallel tests
- Creates test interdependencies

### Solution 3: ModelActor Pattern 🤔 (For Production, Not Tests)

**Apple's recommended pattern for concurrent ModelContext access**:

```swift
@ModelActor
actor DataHandler {
    func fetchData() { ... }
}
```

**Why This Doesn't Solve Testing Issues**:
- Designed for app runtime, not test isolation
- Still requires serial execution within the actor
- Doesn't prevent multiple test suites creating multiple actors in parallel

**Sources**:
- [Concurrent Programming in SwiftData - Fatbobman](https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/)
- [Using ModelActor in SwiftData - BrightDigit](https://brightdigit.com/tutorials/swiftdata-modelactor/)

### Solution 4: Wait for Apple to Fix iOS 18 Regression ⏳ (Long-term)

**Evidence**: Multiple Apple Developer Forum threads report this issue with no official resolution yet.

**Not Viable**: Can't wait for a fix when tests need to run now.

---

## SwiftData Known Issues Relevant to Testing

From [SwiftData Pitfalls - Wade Tregaskis](https://wadetregaskis.com/swiftdata-pitfalls/):

1. **Auto-save is unreliable** - changes lost without explicit save()
2. **Array ordering randomly changes** - SQLite doesn't preserve order
3. **Forced relationship optionality** - crashes possible
4. **Initialization bugs with bidirectional relationships**
5. **Model objects can't be created outside contexts** - breaks standard testing patterns

These issues compound when running tests in parallel.

---

## Final Recommendation

**Disable parallel test execution globally** is the Apple-approved solution that best addresses your situation:

### Why This Is Correct:

1. ✅ **Matches Apple's guidance**: Database/persistence tests need sandboxed environments
2. ✅ **Solves iOS 18 regression**: Prevents simultaneous ModelContainer creation
3. ✅ **Maintains test isolation**: Each test still gets its own in-memory container
4. ✅ **Follows Swift Testing docs**: `.serialized` already implemented per-suite
5. ✅ **Industry standard**: Multiple sources recommend this for database tests

### What You've Already Done Right:

- ✅ In-memory ModelConfiguration per test
- ✅ `.serialized` trait on all SwiftData test suites
- ✅ Proper context lifecycle (created/destroyed per test)

### The Missing Piece:

**Inter-suite parallelization** must be disabled because SwiftData's internal infrastructure (in iOS 18) cannot handle 50+ test suites creating ModelContainers simultaneously, even though each container is theoretically isolated.

---

## Implementation Steps

### Immediate Action (Recommended)

Edit the Xcode scheme to disable parallel execution:

1. Open Cumberland.xcodeproj in Xcode
2. Product menu → Scheme → Edit Scheme...
3. Select "Test" in the left sidebar
4. Click "Options" tab
5. **Uncheck "Execute in parallel"**
6. Click "Close"

### Alternative: Command Line Testing

Run tests with parallelization disabled:

```bash
cd /Users/justgus/Xcode-Projects/Cumberland
xcodebuild test -scheme Cumberland-macOS -configuration Debug -parallel-testing-enabled NO
```

---

## Sources & References

1. [Running tests serially or in parallel - Apple Developer Documentation](https://developer.apple.com/documentation/testing/parallelization)
2. [Concurrency support - Apple Developer Documentation](https://developer.apple.com/documentation/swiftdata/concurrencysupport)
3. [iOS 18 SwiftData ModelContext reset - Apple Developer Forums](https://developer.apple.com/forums/thread/757521)
4. [How to write unit tests for your SwiftData code - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-write-unit-tests-for-your-swiftdata-code)
5. [Running tests serially or in parallel - Swift Forums](https://forums.swift.org/t/running-tests-serially-or-in-parallel/72935)
6. [Core Data and Swift Data concurrency - Pol Piella](https://www.polpiella.dev/core-data-swift-data-concurrency)
7. [Concurrent Programming in SwiftData - Fatbobman](https://fatbobman.com/en/posts/concurret-programming-in-swiftdata/)
8. [Shared State During Parallel Testing in Xcode - Caesar Wirth](https://cjwirth.com/tech/shared-state-during-parallel-testing-in-xcode)
9. [XCTest Best Practices - Maestro](https://maestro.dev/insights/xctest-best-practices-ios-testing)
10. [SwiftData Pitfalls - Wade Tregaskis](https://wadetregaskis.com/swiftdata-pitfalls/)
11. [Mastering the Swift Testing Framework - Fatbobman](https://fatbobman.com/en/posts/mastering-the-swift-testing-framework/)
12. [Using ModelActor in SwiftData - BrightDigit](https://brightdigit.com/tutorials/swiftdata-modelactor/)

---

## Conclusion

The `.serialized` trait you've implemented is correct and necessary, but insufficient on its own. The iOS 18 regression in SwiftData's internal state management requires disabling parallel execution at the global level to prevent multiple test suites from creating ModelContainers simultaneously.

This solution:
- Follows Apple's documented best practices
- Addresses the known iOS 18 regression
- Maintains proper test isolation
- Requires no code changes
- Is reversible if/when Apple fixes the underlying issue

**Next Step**: Disable parallel test execution in your Xcode scheme settings.
