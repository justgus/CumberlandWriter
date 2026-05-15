# Enhancement Requests (ER) - Batch 23: ER-0023

This file contains verified enhancement request ER-0023.

**Batch Status:** ✅ Verified (1/1)

---

## ER-0023: Extract Image Processing to Swift Package

**Status:** ✅ Implemented - Verified
**Component:** Image Processing, Swift Package
**Priority:** Medium
**Date Requested:** 2026-02-03
**Date Implemented:** 2026-02-13
**Date Verified:** 2026-02-14
**Dependencies:** ER-0022 Phase 1 (ImageProcessingService must exist first)

**Summary:**

Extracted all image processing utilities (thumbnail generation, format conversion, image loading) into a local Swift Package at `Packages/ImageProcessing/`, wired into all 3 app targets, consolidated duplicate code, and migrated tests.

**Resolution:**

Created `Packages/ImageProcessing/` Swift Package with 7 source files and 3 test files. Package uses swift-tools-version 6.2 with platforms macOS 26, iOS 26, visionOS 26. All types marked `Sendable` for Swift 6 strict concurrency. Tests use Swift Testing framework (`@Test`, `#expect`).

Key improvements over old `Cumberland/Services/ImageProcessingService.swift`:
- Replaced deprecated `lockFocus()`/`unlockFocus()` with `NSImage(size:flipped:drawingHandler:)` on macOS
- Removed reflection-based `pngData()`/`jpegData()` probing (unnecessary on macOS 26+)
- Split monolithic service into focused sub-components (`ThumbnailGenerator`, `ImageConverter`, `ImageLoader`)
- All sub-components are `struct` for value semantics + automatic `Sendable`
- `MemberImportVisibility` upcoming feature enabled (matching RealityKitContent pattern)

**Files Created (10 files):**
- `Packages/ImageProcessing/Package.swift`
- `Packages/ImageProcessing/Sources/ImageProcessing/ImageProcessingService.swift` (public facade)
- `Packages/ImageProcessing/Sources/ImageProcessing/ThumbnailGenerator.swift`
- `Packages/ImageProcessing/Sources/ImageProcessing/ImageConverter.swift`
- `Packages/ImageProcessing/Sources/ImageProcessing/ImageLoader.swift`
- `Packages/ImageProcessing/Sources/ImageProcessing/PlatformImage.swift`
- `Packages/ImageProcessing/Sources/ImageProcessing/ImageProcessingError.swift`
- `Packages/ImageProcessing/Tests/ImageProcessingTests/ThumbnailGeneratorTests.swift` (5 tests)
- `Packages/ImageProcessing/Tests/ImageProcessingTests/ImageConverterTests.swift` (8 tests)
- `Packages/ImageProcessing/Tests/ImageProcessingTests/ImageLoaderTests.swift` (4 tests)

**Files Deleted (1 file):**
- `Cumberland/Services/ImageProcessingService.swift` (old monolithic service)

**Files Modified (9 files):**
- `Cumberland.xcodeproj/project.pbxproj` -- added ImageProcessing as local package dependency for all 3 app targets
- `Cumberland/Infrastructure/ServiceContainer.swift` -- added `import ImageProcessing`
- `Cumberland/ViewModels/CardEditorViewModel.swift` -- added `import ImageProcessing`
- `Cumberland/CardSheet/CardSheetDropHandler.swift` -- added `import ImageProcessing`
- `Cumberland/Images/FullSizeImageViewer.swift` -- added `import ImageProcessing`
- `Cumberland/AI/ImageGeneration/BatchGenerationQueue.swift` -- added `import ImageProcessing`, removed private `generateThumbnail` wrapper
- `Cumberland/AI/ImageGeneration/ImageVersionManager.swift` -- added `import ImageProcessing`, removed private `generateThumbnail` wrapper
- `Cumberland/CardEditor/CardEditorDropHandler.swift` -- added `import ImageProcessing`, replaced inline NSBitmapImageRep conversion with `ImageProcessingService.shared.convertToPNG`/`convertToJPEG`
- `Cumberland/Images/ImageClipboardManager.swift` -- added `import ImageProcessing`, deleted private `convertToPNG` method, simplified TIFF paste path

**Test Results:**
- Package tests: 17/17 passing (Swift Testing framework)
- Build: macOS BUILD SUCCEEDED, iOS BUILD SUCCEEDED, visionOS BUILD SUCCEEDED

**Detailed Build Plan:** See `ER-0023-BuildPlan.md`

---

*Last Updated: 2026-02-14*
