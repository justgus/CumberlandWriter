# Test Infrastructure Setup Instructions

Follow these steps to complete the test infrastructure setup for ER-0008, ER-0009, and ER-0010.

## Part 1: Add New Test Files to Xcode Project

The test files have been created in the filesystem, but Xcode doesn't know about them yet.

### Steps:

1. **Open Cumberland.xcodeproj in Xcode**

2. **Select the CumberlandTests group in the Project Navigator**

3. **Add the reorganized folders:**
   - Right-click on `CumberlandTests` → "Add Files to Cumberland..."
   - Navigate to `/Users/justgus/Xcode-Projects/Cumberland/CumberlandTests/`
   - Select these folders:
     - `Existing/`
     - `ER-0008-Timeline/`
     - `ER-0009-ImageGeneration/`
     - `ER-0010-ContentAnalysis/`
     - `Integration/`
   - **Important:** Check "Create folder references" (NOT "Create groups")
   - Click "Add"

4. **Verify the structure:**
   - Expand `CumberlandTests` in the Project Navigator
   - You should see all 5 folders with the test files inside
   - The folders should have blue icons (folder references)

5. **Remove old file references (if present):**
   - If you see duplicate entries for `CitationTests.swift`, `StoryStructureTests.swift`, etc. at the root level
   - Select them and press Delete → "Remove Reference" (NOT "Move to Trash")

---

## Part 2: Create visionOS Test Targets

Currently missing: `CumberlandVisionOSTests` and `CumberlandVisionOSUITests`

### Create CumberlandVisionOSTests (Unit Tests)

1. **Create new target:**
   - In Xcode, click the project file in the Navigator
   - Click the "+" button at the bottom of the targets list
   - Select "visionOS" → "Unit Testing Bundle"
   - Click "Next"

2. **Configure target:**
   - **Product Name:** `CumberlandVisionOSTests`
   - **Team:** (Your team)
   - **Organization Identifier:** (Your org ID)
   - **Target to be Tested:** `Cumberland_visionOS`
   - Click "Finish"

3. **Add test files:**
   - Select the `CumberlandVisionOSTests` folder in the Navigator
   - Right-click → "Add Files to Cumberland..."
   - Navigate to `CumberlandTests/` folders
   - Select files from:
     - `Existing/`
     - `ER-0008-Timeline/`
     - `ER-0009-ImageGeneration/`
     - `ER-0010-ContentAnalysis/`
     - `Integration/`
   - **Check:** Add to targets → `CumberlandVisionOSTests`
   - Click "Add"

### Create CumberlandVisionOSUITests (UI Tests)

1. **Create new target:**
   - Click the "+" button at the bottom of the targets list
   - Select "visionOS" → "UI Testing Bundle"
   - Click "Next"

2. **Configure target:**
   - **Product Name:** `CumberlandVisionOSUITests`
   - **Target to be Tested:** `Cumberland_visionOS`
   - Click "Finish"

3. **Configure for testing:**
   - UI tests will be added later as UI features are implemented
   - For now, the target structure is ready

---

## Part 3: Configure CI/CD

### Option A: GitHub Actions (Recommended)

1. **Create workflow file:**
   ```bash
   mkdir -p .github/workflows
   ```

2. **Create `.github/workflows/tests.yml`:**
   ```yaml
   name: Run Tests

   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main, develop ]

   jobs:
     test-macos:
       runs-on: macos-14
       steps:
         - uses: actions/checkout@v4
         - name: Select Xcode version
           run: sudo xcode-select -s /Applications/Xcode_15.2.app
         - name: Run macOS tests
           run: xcodebuild test -scheme Cumberland-macOS -destination 'platform=macOS'

     test-ios:
       runs-on: macos-14
       steps:
         - uses: actions/checkout@v4
         - name: Select Xcode version
           run: sudo xcode-select -s /Applications/Xcode_15.2.app
         - name: Run iOS tests
           run: xcodebuild test -scheme "Cumberland IOS" -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

     test-visionos:
       runs-on: macos-14
       steps:
         - uses: actions/checkout@v4
         - name: Select Xcode version
           run: sudo xcode-select -s /Applications/Xcode_15.2.app
         - name: Run visionOS tests
           run: xcodebuild test -scheme Cumberland_visionOS -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
   ```

3. **Commit and push:**
   ```bash
   git add .github/workflows/tests.yml
   git commit -m "Add CI/CD test workflow"
   git push
   ```

### Option B: Xcode Cloud

1. **Open Xcode Cloud settings:**
   - In Xcode: Product → Xcode Cloud → Create Workflow

2. **Configure workflow:**
   - **Trigger:** On every commit to main/develop
   - **Actions:** Run tests
   - **Platforms:** macOS, iOS, iPadOS, visionOS
   - **Schedule:** Nightly comprehensive tests

3. **Save and enable**

---

## Part 4: Create Test Data Fixtures

Test fixtures provide sample data for testing.

### Steps:

1. **Create TestFixtures.swift:**
   - Location: `CumberlandTests/TestFixtures.swift`
   - Contains sample calendars, cards, descriptions

2. **Example structure:**
   ```swift
   enum TestFixtures {
       static let gregorianCalendar: CalendarSystem { /* ... */ }
       static let fantasyCalendar: CalendarSystem { /* ... */ }
       static let sampleSceneDescription: String { /* ... */ }
       static let sampleCharacterCard: Card { /* ... */ }
   }
   ```

3. **Add to project:**
   - Add `TestFixtures.swift` to all test targets

---

## Part 5: Verify Setup

### Run Baseline Tests

1. **In Xcode:**
   - Press ⌘U (or Product → Test)
   - All existing tests should pass

2. **Expected results:**
   - `CitationTests`: ✓ Pass
   - `StoryStructureTests`: ✓ Pass
   - Template tests: ⚠️ Skip (TODOs not implemented yet)

### Run from Command Line

```bash
# macOS tests
xcodebuild test -scheme Cumberland-macOS

# iOS tests
xcodebuild test -scheme "Cumberland IOS" -sdk iphonesimulator

# visionOS tests
xcodebuild test -scheme Cumberland_visionOS -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

### Check Test Coverage

1. **Enable coverage:**
   - Edit scheme (⌘<)
   - Select "Test" action
   - Check "Gather coverage for all targets"

2. **View coverage:**
   - After running tests, open Report Navigator (⌘9)
   - Select test run → Coverage tab
   - Verify baseline coverage metrics

---

## Part 6: Next Steps

Once setup is complete:

1. ✅ Test infrastructure configured
2. ✅ Folder structure organized
3. ✅ Template test files created
4. ✅ CI/CD pipeline ready
5. ⏭️ **Begin Phase 1:** AI Provider Infrastructure implementation

---

## Troubleshooting

### "No such module 'Cumberland'" in tests
- **Solution:** Ensure test targets have "Cumberland" app target in "Target Dependencies" (Build Phases)

### Tests not appearing in Test Navigator
- **Solution:** Clean build folder (⌘⇧K) and rebuild (⌘B)

### visionOS simulator not found
- **Solution:** Download visionOS simulator (Xcode → Settings → Platforms → visionOS)

### CI/CD tests failing with "scheme not found"
- **Solution:** In Xcode, Edit Scheme → Check "Shared" checkbox to commit scheme file

---

**Questions?** See:
- [Implementation Plan](../DR-Reports/IMPLEMENTATION-PLAN-ER-0008-0009-0010.md)
- [Test Plan](../DR-Reports/TEST-PLAN-ER-0008-0009-0010.md)
- [Architecture Decisions](../DR-Reports/ADR-ER-0008-0009-0010.md)

---

*Last Updated: 2026-01-20 (Phase 0)*
