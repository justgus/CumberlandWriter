# CumberlandTests Organization

This test target has been reorganized to support development of ER-0008, ER-0009, and ER-0010.

## Folder Structure

```
CumberlandTests/
├── Existing/                          # Original tests (pre-ER implementation)
│   ├── CitationTests.swift
│   ├── StoryStructureTests.swift
│   ├── SpecHeaderGuardTests.swift
│   └── WipeStoreTests.swift
│
├── ER-0008-Timeline/                  # Timeline System tests
│   ├── CalendarSystemTests.swift     ✓ Created
│   ├── TemporalPositioningTests.swift (TODO)
│   ├── TimelineChartTests.swift       (TODO)
│   └── MultiTimelineGraphTests.swift  (TODO)
│
├── ER-0009-ImageGeneration/           # AI Image Generation tests
│   ├── AIProviderTests.swift          ✓ Created
│   ├── ImageGenerationTests.swift     (TODO)
│   ├── AttributionTests.swift         (TODO)
│   └── MetadataTests.swift            (TODO)
│
├── ER-0010-ContentAnalysis/           # AI Content Analysis tests
│   ├── EntityExtractionTests.swift    ✓ Created
│   ├── RelationshipInferenceTests.swift (TODO)
│   ├── SuggestionEngineTests.swift    (TODO)
│   └── CalendarExtractionTests.swift  (TODO)
│
└── Integration/                       # Cross-ER integration tests
    ├── CrossERWorkflowTests.swift     ✓ Created
    ├── AIInfrastructureTests.swift    (TODO)
    └── MigrationTests.swift           (TODO)
```

## Test Framework

This project uses **Swift Testing** (not XCTest). Key features:

### Attributes
- `@Suite("Name")` - Group related tests
- `@Test("Description")` - Individual test function
- `@MainActor` - Run test on main actor (required for SwiftData)

### Expectations
- `#expect(condition)` - Assert condition is true
- `#expect(throws: Error.self)` - Assert throws specific error
- `try await` - Async test support

### Example
```swift
@Suite("My Feature Tests")
struct MyFeatureTests {
    @Test("Create and save entity")
    @MainActor
    func createEntity() async throws {
        let (_, context) = try makeInMemoryContainer()
        let card = Card(kind: .characters, name: "Test")
        context.insert(card)
        try context.save()
        #expect(card.name == "Test")
    }
}
```

## Testing Strategy

### Hybrid Approach
- **Incremental Testing:** Tests added during each development phase
- **Comprehensive Testing:** Full integration tests in Phase 10

### Test Coverage Targets
- **Logic:** >80% coverage
- **Models:** >90% coverage
- **UI:** >60% coverage

### Test Types
1. **Unit Tests:** Test individual components in isolation
2. **Integration Tests:** Test feature workflows
3. **Cross-ER Tests:** Test interactions between ERs
4. **Migration Tests:** Test schema migrations

## In-Memory Testing Pattern

All tests use in-memory SwiftData containers for isolation:

```swift
@MainActor
func makeInMemoryContainer() throws -> (ModelContainer, ModelContext) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
        for: Card.self, CalendarSystem.self,
        configurations: config
    )
    let context = ModelContext(container)
    return (container, context)
}
```

## Running Tests

### Command Line
```bash
# Run all tests
xcodebuild test -scheme Cumberland-macOS

# Run specific test suite
xcodebuild test -scheme Cumberland-macOS -only-testing:CumberlandTests/CalendarSystemTests
```

### Xcode
1. Open Test Navigator (⌘6)
2. Click the play button next to any test or suite
3. View results in the Test Navigator

## CI/CD Integration

Tests run automatically on:
- Every commit (via GitHub Actions or Xcode Cloud)
- Pull request creation
- Nightly builds (comprehensive test suite)

## Next Steps

1. **Add files to Xcode project** (see SETUP-INSTRUCTIONS.md)
2. **Create visionOS test targets** (see SETUP-INSTRUCTIONS.md)
3. **Implement TODOs** in template test files as features are developed
4. **Run baseline tests** to ensure existing functionality works

---

*Last Updated: 2026-01-20 (Phase 0)*
