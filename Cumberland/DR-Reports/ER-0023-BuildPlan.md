# ER-0023: Extract Image Processing to Swift Package - Build Plan

**Status:** 🔵 Proposed
**Component:** Image Processing, Swift Package
**Priority:** Medium
**Date Requested:** 2026-02-03
**Dependencies:** ER-0022 (Phase 1 - ImageProcessingService must exist first)

---

## Overview

Extract all image processing utilities (thumbnail generation, format conversion, image loading) into a reusable Swift Package that can be used by Cumberland, Storyscapes, and future applications.

**Key Benefit:** Eliminate duplicate code and create a single source of truth for image operations across all your applications.

**Note:** Cumberland.xcodeproj is located at ./Cumberland.xcodeproj
    Storyscapes.xcodeproj is located at ../Storyscapes/Storyscapes.xcodeproj


---

## Current State Analysis

### Duplicate Code Identified

**Thumbnail Generation (2 exact copies):**
1. `Cumberland/AI/BatchGenerationQueue.swift:516-550`
2. `Cumberland/AI/ImageVersionManager.swift:196+`

**Image Conversion Functions:**
- `nsImageToPngData()` in `CardSheetView.swift:2178`
- `nsImageToJpegData()` in `CardSheetView.swift:2190`
- Similar conversions in `BatchGenerationQueue.swift` and `ImageVersionManager.swift`

**Image Loading:**
- Multiple `loadImage()` implementations across Card.swift extensions
- Platform-specific CGImage loading scattered throughout codebase

**Total Duplicate/Scattered Code:** ~200 lines across 5+ files

---

## Package Architecture

### Package Structure

```
ImageProcessing/
├── Package.swift
├── Sources/
│   └── ImageProcessing/
│       ├── ImageProcessingService.swift       # Main service (singleton)
│       ├── ThumbnailGenerator.swift           # Thumbnail operations
│       ├── ImageConverter.swift               # Format conversion
│       ├── ImageLoader.swift                  # Loading from Data/URL
│       ├── PlatformImage.swift                # Platform abstraction
│       └── ImageProcessingError.swift         # Error types
└── Tests/
    └── ImageProcessingTests/
        ├── ThumbnailGeneratorTests.swift
        ├── ImageConverterTests.swift
        └── ImageLoaderTests.swift
```

### Public API Design

```swift
// ImageProcessingService.swift
@available(macOS 26.0, iOS 26.0, *)
public final class ImageProcessingService {
    public static let shared = ImageProcessingService()

    private let thumbnailGenerator: ThumbnailGenerator
    private let imageConverter: ImageConverter
    private let imageLoader: ImageLoader

    private init() {
        self.thumbnailGenerator = ThumbnailGenerator()
        self.imageConverter = ImageConverter()
        self.imageLoader = ImageLoader()
    }

    // MARK: - Thumbnail Generation

    /// Generate a thumbnail from image data
    /// - Parameters:
    ///   - imageData: Source image data (PNG, JPEG, etc.)
    ///   - size: Target thumbnail size (default: 200x200)
    /// - Returns: Thumbnail as PNG data, or nil if generation failed
    public func generateThumbnail(
        from imageData: Data,
        size: CGSize = CGSize(width: 200, height: 200)
    ) -> Data? {
        thumbnailGenerator.generate(from: imageData, size: size)
    }

    // MARK: - Format Conversion

    /// Convert image data to PNG format
    public func convertToPNG(_ imageData: Data) -> Data? {
        imageConverter.convertToPNG(imageData)
    }

    /// Convert image data to JPEG format
    /// - Parameter compressionQuality: JPEG quality (0.0 - 1.0, default: 0.9)
    public func convertToJPEG(
        _ imageData: Data,
        compressionQuality: CGFloat = 0.9
    ) -> Data? {
        imageConverter.convertToJPEG(imageData, quality: compressionQuality)
    }

    // MARK: - Image Loading

    /// Load CGImage from data
    public func loadImage(from data: Data) async -> CGImage? {
        await imageLoader.loadCGImage(from: data)
    }

    /// Load CGImage from file URL
    public func loadImage(from url: URL) async -> CGImage? {
        await imageLoader.loadCGImage(from: url)
    }

    /// Load platform-specific image from data
    #if os(macOS)
    public func loadNSImage(from data: Data) -> NSImage? {
        imageLoader.loadNSImage(from: data)
    }
    #elseif os(iOS) || os(visionOS)
    public func loadUIImage(from data: Data) -> UIImage? {
        imageLoader.loadUIImage(from: data)
    }
    #endif
}
```

### Platform Abstraction

```swift
// PlatformImage.swift
#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#elseif os(iOS) || os(visionOS)
import UIKit
public typealias PlatformImage = UIImage
#endif

extension PlatformImage {
    /// Convert to PNG data
    public func pngData() -> Data? {
        #if os(macOS)
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .png, properties: [:])
        #elseif os(iOS) || os(visionOS)
        return self.pngData()
        #endif
    }

    /// Convert to JPEG data
    public func jpegData(compressionQuality: CGFloat) -> Data? {
        #if os(macOS)
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
        #elseif os(iOS) || os(visionOS)
        return self.jpegData(compressionQuality: compressionQuality)
        #endif
    }
}
```

---

## Implementation Plan

### Phase 1: Create Swift Package (Week 1)

**Step 1.1: Create Package**
```bash
cd /path/to/packages
swift package init --name ImageProcessing --type library
```

**Step 1.2: Configure Package.swift**
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ImageProcessing",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ImageProcessing",
            targets: ["ImageProcessing"]
        ),
    ],
    targets: [
        .target(
            name: "ImageProcessing",
            dependencies: []
        ),
        .testTarget(
            name: "ImageProcessingTests",
            dependencies: ["ImageProcessing"]
        ),
    ]
)
```

**Step 1.3: Implement Core Classes**
1. Create `ImageProcessingService.swift` (main API)
2. Create `ThumbnailGenerator.swift` (migrate from BatchGenerationQueue/ImageVersionManager)
3. Create `ImageConverter.swift` (migrate from CardSheetView)
4. Create `ImageLoader.swift` (migrate from Card.swift extensions)
5. Create `PlatformImage.swift` (platform abstraction)
6. Create `ImageProcessingError.swift` (error types)

**Files to Create:**
- `Sources/ImageProcessing/ImageProcessingService.swift` (~100 lines)
- `Sources/ImageProcessing/ThumbnailGenerator.swift` (~120 lines)
- `Sources/ImageProcessing/ImageConverter.swift` (~80 lines)
- `Sources/ImageProcessing/ImageLoader.swift` (~100 lines)
- `Sources/ImageProcessing/PlatformImage.swift` (~60 lines)
- `Sources/ImageProcessing/ImageProcessingError.swift` (~30 lines)

**Total New Code:** ~490 lines

### Phase 2: Write Unit Tests (Week 1)

**Step 2.1: Test Thumbnail Generation**
```swift
// ThumbnailGeneratorTests.swift
@testable import ImageProcessing
import XCTest

final class ThumbnailGeneratorTests: XCTestCase {
    func testGenerateThumbnailFromPNG() async throws {
        let testImage = createTestImageData(format: .png, size: CGSize(width: 1000, height: 1000))

        let thumbnail = ImageProcessingService.shared.generateThumbnail(
            from: testImage,
            size: CGSize(width: 200, height: 200)
        )

        XCTAssertNotNil(thumbnail)

        // Verify thumbnail dimensions
        if let thumbnailCGImage = await ImageProcessingService.shared.loadImage(from: thumbnail!) {
            XCTAssertEqual(thumbnailCGImage.width, 200)
            XCTAssertEqual(thumbnailCGImage.height, 200)
        }
    }

    func testGenerateThumbnailFromJPEG() async throws {
        // Similar test for JPEG
    }

    func testThumbnailAspectRatioPreserved() async throws {
        // Test that aspect ratio is maintained
    }
}
```

**Step 2.2: Test Format Conversion**
**Step 2.3: Test Image Loading**

**Files to Create:**
- `Tests/ImageProcessingTests/ThumbnailGeneratorTests.swift` (~150 lines)
- `Tests/ImageProcessingTests/ImageConverterTests.swift` (~100 lines)
- `Tests/ImageProcessingTests/ImageLoaderTests.swift` (~100 lines)
- `Tests/ImageProcessingTests/TestHelpers.swift` (~50 lines)

### Phase 3: Integrate Package into Cumberland (Week 2)

**Step 3.1: Add Package Dependency**

Option A: Local Package (Development)
```swift
// Cumberland/Cumberland.xcodeproj
// File > Add Package Dependencies > Add Local...
// Select ImageProcessing package folder
```

Option B: Git Repository (Production)
```swift
dependencies: [
    .package(url: "https://github.com/yourorg/ImageProcessing.git", from: "1.0.0")
]
```

**Step 3.2: Import Package**
```swift
// In any Cumberland file
import ImageProcessing
```

**Step 3.3: Migrate BatchGenerationQueue**

**Before:**
```swift
// BatchGenerationQueue.swift:516-550
private func generateThumbnail(from imageData: Data) -> Data? {
    #if os(macOS)
    guard let nsImage = NSImage(data: imageData) else { return nil }
    // ... 35 lines of thumbnail generation code ...
    #elseif os(iOS) || os(visionOS)
    guard let uiImage = UIImage(data: imageData) else { return nil }
    // ... similar code ...
    #endif
}
```

**After:**
```swift
// BatchGenerationQueue.swift
import ImageProcessing

// Delete lines 516-550 entirely

// Replace all calls to generateThumbnail():
let thumbnailData = ImageProcessingService.shared.generateThumbnail(from: imageData)
```

**Estimated Reduction:** -35 lines in BatchGenerationQueue.swift

**Step 3.4: Migrate ImageVersionManager**

**Before:**
```swift
// ImageVersionManager.swift:196+
private func generateThumbnail(from data: Data) -> Data? {
    // ... duplicate thumbnail generation code ...
}
```

**After:**
```swift
import ImageProcessing

// Delete duplicate method

// Replace all calls:
let thumbnailData = ImageProcessingService.shared.generateThumbnail(from: originalData)
```

**Estimated Reduction:** -35 lines in ImageVersionManager.swift

**Step 3.5: Migrate CardSheetView**

**Before:**
```swift
// CardSheetView.swift:2178, 2190
private func nsImageToPngData(_ image: NSImage) -> Data? {
    // ... conversion code ...
}

private func nsImageToJpegData(_ image: NSImage, compressionQuality: CGFloat = 0.9) -> Data? {
    // ... conversion code ...
}
```

**After:**
```swift
import ImageProcessing

// Delete both methods

// Replace calls with:
if let pngData = ImageProcessingService.shared.convertToPNG(originalData) {
    // use pngData
}
```

**Estimated Reduction:** -25 lines in CardSheetView.swift

**Step 3.6: Migrate Card.swift Extensions**

**Before:**
```swift
// Card.swift - multiple image loading methods
func loadThumbnailCGImage() -> CGImage? {
    // ... loading code ...
}

func loadFullCGImage() -> CGImage? {
    // ... loading code ...
}

func cgImageFromThumbnailData() -> CGImage? {
    // ... loading code ...
}
```

**After:**
```swift
import ImageProcessing

func loadThumbnailCGImage() async -> CGImage? {
    guard let thumbnailData = thumbnailData else { return nil }
    return await ImageProcessingService.shared.loadImage(from: thumbnailData)
}

func loadFullCGImage() async -> CGImage? {
    guard let imageURL = imageFileURL else { return nil }
    return await ImageProcessingService.shared.loadImage(from: imageURL)
}

// cgImageFromThumbnailData() can be deleted - use loadThumbnailCGImage()
```

**Estimated Reduction:** -50 lines in Card.swift

### Phase 4: Integrate into Storyscapes (Week 2)

**Step 4.1: Add Same Package Dependency to Storyscapes**
```swift
// Storyscapes.xcodeproj
// File > Add Package Dependencies
// Add ImageProcessing package (local or git)
```

**Step 4.2: Use in Storyscapes Map Export**
```swift
// Storyscapes map export functionality
import ImageProcessing

func exportMapAsPNG() {
    let mapImageData = renderMapToData()

    // Generate thumbnail for preview
    if let thumbnail = ImageProcessingService.shared.generateThumbnail(from: mapImageData) {
        saveMapThumbnail(thumbnail)
    }

    // Convert to PNG if needed
    if let pngData = ImageProcessingService.shared.convertToPNG(mapImageData) {
        saveMap(pngData)
    }
}
```

**Benefit:** Storyscapes immediately gains all image processing capabilities without duplicating code

---

## Migration Checklist

### Phase 1: Package Creation
- [ ] Create ImageProcessing Swift Package
- [ ] Configure Package.swift with correct platforms
- [ ] Implement ImageProcessingService
- [ ] Implement ThumbnailGenerator
- [ ] Implement ImageConverter
- [ ] Implement ImageLoader
- [ ] Implement PlatformImage abstraction
- [ ] Implement ImageProcessingError

### Phase 2: Testing
- [ ] Write ThumbnailGeneratorTests
- [ ] Write ImageConverterTests
- [ ] Write ImageLoaderTests
- [ ] All tests passing on macOS
- [ ] All tests passing on iOS simulator
- [ ] All tests passing on visionOS simulator (if applicable)

### Phase 3: Cumberland Integration
- [ ] Add package dependency to Cumberland
- [ ] Import ImageProcessing in affected files
- [ ] Migrate BatchGenerationQueue (remove lines 516-550)
- [ ] Migrate ImageVersionManager (remove generateThumbnail)
- [ ] Migrate CardSheetView (remove nsImageToPngData, nsImageToJpegData)
- [ ] Migrate Card.swift extensions (simplify image loading methods)
- [ ] Update all call sites to use ImageProcessingService
- [ ] Build Cumberland successfully
- [ ] Test image generation (verify thumbnails work)
- [ ] Test image history (verify thumbnails work)
- [ ] Test image export (verify format conversion works)

### Phase 4: Storyscapes Integration
- [ ] Add package dependency to Storyscapes
- [ ] Use ImageProcessingService in map export
- [ ] Test map thumbnail generation
- [ ] Test map format conversion

---

## Testing Strategy

### Unit Tests (Package Level)

**Test Coverage Goals:**
- Thumbnail generation: 90%+
- Format conversion: 90%+
- Image loading: 90%+

**Key Test Scenarios:**
1. Generate thumbnail from PNG (various sizes)
2. Generate thumbnail from JPEG (various sizes)
3. Generate thumbnail preserving aspect ratio
4. Convert PNG to JPEG
5. Convert JPEG to PNG
6. Load image from Data
7. Load image from file URL
8. Handle corrupt image data gracefully
9. Handle missing files gracefully
10. Platform-specific conversions (NSImage ↔ UIImage)

### Integration Tests (Cumberland Level)

**Test Scenarios:**
1. **AI Image Generation:**
   - Generate character image
   - Verify thumbnail created correctly
   - Verify thumbnail displayed in UI

2. **Image History:**
   - Generate multiple versions
   - Verify all thumbnails displayed
   - Verify thumbnail quality

3. **Image Export:**
   - Export image as PNG
   - Export image as JPEG
   - Verify format conversion successful

4. **Card Images:**
   - Add image to card
   - Verify thumbnail generated
   - Verify full image loads correctly
   - Delete card, verify image cleanup

### Performance Tests

**Benchmarks:**
- Thumbnail generation time: <100ms for 2000x2000 source
- Format conversion time: <50ms
- Image loading time: <20ms from memory, <100ms from disk

---

## Documentation Requirements

### Package Documentation

**Files to Create:**
- `README.md` - Package overview, installation, usage examples
- `CHANGELOG.md` - Version history
- `LICENSE` - MIT or appropriate license

**README.md Structure:**
```markdown
# ImageProcessing

A Swift package for image processing operations across macOS, iOS, and visionOS.

## Features

- Thumbnail generation with aspect ratio preservation
- Image format conversion (PNG, JPEG)
- Async image loading from Data or URLs
- Platform-agnostic API with platform-specific implementations

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/ImageProcessing.git", from: "1.0.0")
]
```

## Usage

### Generate Thumbnail

```swift
import ImageProcessing

let imageData: Data = // ... your image data
let thumbnail = ImageProcessingService.shared.generateThumbnail(
    from: imageData,
    size: CGSize(width: 200, height: 200)
)
```

### Convert Format

```swift
let pngData = ImageProcessingService.shared.convertToPNG(jpegData)
let jpegData = ImageProcessingService.shared.convertToJPEG(pngData, compressionQuality: 0.8)
```

### Load Image

```swift
let cgImage = await ImageProcessingService.shared.loadImage(from: imageData)
let cgImageFromFile = await ImageProcessingService.shared.loadImage(from: fileURL)
```

## Requirements

- macOS 14.0+
- iOS 17.0+
- visionOS 1.0+
- Swift 6.0+

## License

MIT License
```

### Code Documentation

**DocC Comments for All Public APIs:**
```swift
/// Service for image processing operations
///
/// `ImageProcessingService` provides a unified API for common image operations
/// including thumbnail generation, format conversion, and image loading across
/// macOS, iOS, and visionOS platforms.
///
/// ## Topics
///
/// ### Getting the Service
/// - ``shared``
///
/// ### Thumbnail Generation
/// - ``generateThumbnail(from:size:)``
///
/// ### Format Conversion
/// - ``convertToPNG(_:)``
/// - ``convertToJPEG(_:compressionQuality:)``
///
/// ### Image Loading
/// - ``loadImage(from:)-swift.method``
/// - ``loadImage(from:)-swift.type.method``
public final class ImageProcessingService {
    // ...
}
```

---

## Success Criteria

### Completion Criteria

- [ ] Package builds successfully on all platforms
- [ ] All unit tests passing (90%+ coverage)
- [ ] Cumberland integrated and functioning
- [ ] Storyscapes integrated and functioning
- [ ] Code duplication eliminated:
  - BatchGenerationQueue: -35 lines
  - ImageVersionManager: -35 lines
  - CardSheetView: -25 lines
  - Card.swift: -50 lines
  - **Total reduction: ~145 lines**
- [ ] Documentation complete (README, inline docs)
- [ ] No performance regressions

### Quality Metrics

- Build time: No significant increase
- Test coverage: 90%+ in package
- Performance: Within 10% of baseline
- Code reuse: Package used in both Cumberland and Storyscapes

---

## Risks and Mitigations

### Risk 1: Platform-Specific Behavior Differences

**Risk:** Image processing may behave differently on macOS vs iOS/visionOS

**Mitigation:**
- Comprehensive unit tests on all platforms
- Platform-specific test cases
- Manual testing on physical devices

### Risk 2: Performance Regressions

**Risk:** Abstraction layer may introduce overhead

**Mitigation:**
- Benchmark before and after migration
- Profile hot paths
- Optimize critical operations if needed

### Risk 3: Breaking Existing Functionality

**Risk:** Migration may break image generation/history features

**Mitigation:**
- Incremental migration (one file at a time)
- Extensive testing after each migration
- Keep old code temporarily (can roll back)

---

## Timeline Estimate

**Total Duration:** 2 weeks

- **Week 1:**
  - Days 1-2: Create package structure and core implementation
  - Days 3-4: Write unit tests
  - Day 5: Package testing and refinement

- **Week 2:**
  - Days 1-2: Cumberland integration (migrate files)
  - Day 3: Cumberland testing
  - Day 4: Storyscapes integration
  - Day 5: Final testing, documentation, cleanup

---

## Dependencies

**Required:**
- ER-0022 Phase 1 must be completed first (ImageProcessingService stub must exist)

**Optional:**
- Can proceed independently of other phases of ER-0022

---

## Future Enhancements

### Potential Additions

1. **Advanced Thumbnail Options:**
   - Maintain aspect ratio vs crop to fit
   - Smart cropping (detect faces/important regions)
   - Apply effects (blur, brightness adjustments)

2. **Additional Format Support:**
   - WebP conversion
   - HEIF/HEIC support
   - SVG rasterization

3. **Performance Optimizations:**
   - Thumbnail caching layer
   - Async batch processing
   - GPU-accelerated operations

4. **Metadata Preservation:**
   - Preserve EXIF data during conversion
   - Add metadata to generated images

---

*Last Updated: 2026-02-03*
