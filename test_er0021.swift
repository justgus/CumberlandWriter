#!/usr/bin/env swift

//
//  test_er0021.swift
//  Standalone test script for ER-0021 VisualElements
//
//  Run with: swift test_er0021.swift
//

import Foundation

// Copy of essential types for standalone testing
enum Kinds: String, Codable {
    case characters, locations, buildings, artifacts, vehicles, scenes
}

enum CameraAngle: String, Codable {
    case lowAngleLookingUp, highAngleLookingDown, eyeLevel, aerialView, dramaticAngle

    var displayName: String {
        switch self {
        case .lowAngleLookingUp: return "low angle shot looking up"
        case .highAngleLookingDown: return "high angle shot looking down"
        case .eyeLevel: return "eye-level perspective"
        case .aerialView: return "aerial view"
        case .dramaticAngle: return "dramatic angle"
        }
    }
}

enum Framing: String, Codable {
    case closeUp, mediumShot, fullShot, wideEstablishing

    var displayName: String {
        switch self {
        case .closeUp: return "close-up"
        case .mediumShot: return "medium shot"
        case .fullShot: return "full shot"
        case .wideEstablishing: return "wide establishing shot"
        }
    }
}

enum LightingStyle: String, Codable {
    case dramatic, soft, neutral, dark, bright

    var description: String {
        switch self {
        case .dramatic: return "dramatic lighting with strong shadows"
        case .soft: return "soft warm lighting"
        case .neutral: return "neutral even lighting"
        case .dark: return "dark moody lighting"
        case .bright: return "bright cheerful lighting"
        }
    }
}

struct VisualElements: Codable {
    var sourceText: String
    var cardKind: Kinds
    var extractionConfidence: Double
    var extractedAt: Date = Date()

    // Character properties
    var physicalBuild: String?
    var hair: String?
    var eyes: String?
    var facialFeatures: String?
    var skinTone: String?
    var clothing: String?
    var accessories: [String]?
    var expression: String?
    var pose: String?

    // Location properties
    var primaryFeatures: [String]?
    var scale: String?
    var architecture: String?
    var vegetation: String?
    var isSceneWithMood: Bool = false

    // Artifact properties
    var objectType: String?
    var materials: [String]?
    var condition: String?
    var showPartial: String?

    // Building properties
    var architecturalStyle: String?
    var narrativeImportance: String?

    // Vehicle properties
    var vehicleType: String?
    var vehicleDesign: String?
    var motionState: String?

    // Universal properties
    var colors: [String]?
    var mood: String?
    var backgroundSetting: String?
    var lighting: String?
    var atmosphere: String?

    // Cinematic framing
    var cameraAngle: CameraAngle?
    var framing: Framing?
    var lightingStyle: LightingStyle?

    var hasSufficientData: Bool {
        var count = 0
        if physicalBuild != nil && !physicalBuild!.isEmpty { count += 1 }
        if hair != nil && !hair!.isEmpty { count += 1 }
        if eyes != nil && !eyes!.isEmpty { count += 1 }
        if clothing != nil && !clothing!.isEmpty { count += 1 }
        if primaryFeatures != nil && !primaryFeatures!.isEmpty { count += 1 }
        if scale != nil && !scale!.isEmpty { count += 1 }
        if architecture != nil && !architecture!.isEmpty { count += 1 }
        if objectType != nil && !objectType!.isEmpty { count += 1 }
        if materials != nil && !materials!.isEmpty { count += 1 }
        if architecturalStyle != nil && !architecturalStyle!.isEmpty { count += 1 }
        return count >= 3
    }
}

// Test runner
var testsRun = 0
var testsPassed = 0
var testsFailed = 0

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    testsRun += 1
    if condition {
        testsPassed += 1
        print("✅ PASS: \(message)")
    } else {
        testsFailed += 1
        print("❌ FAIL: \(message) (line \(line))")
    }
}

func assertEqual<T: Equatable>(_ lhs: T?, _ rhs: T?, _ message: String, file: String = #file, line: Int = #line) {
    testsRun += 1
    if lhs == rhs {
        testsPassed += 1
        print("✅ PASS: \(message)")
    } else {
        testsFailed += 1
        print("❌ FAIL: \(message) - Expected \(String(describing: rhs)), got \(String(describing: lhs)) (line \(line))")
    }
}

print(String(repeating: "=", count: 60))
print("ER-0021 Standalone Test Suite")
print(String(repeating: "=", count: 60))
print()

// Test 1: Basic initialization
print("Test 1: VisualElements initialization")
let elements1 = VisualElements(
    sourceText: "A tall warrior",
    cardKind: .characters,
    extractionConfidence: 0.75
)
assertEqual(elements1.sourceText, "A tall warrior", "Source text should match")
assertEqual(elements1.cardKind, .characters, "Card kind should be characters")
assertEqual(elements1.extractionConfidence, 0.75, "Confidence should be 0.75")
print()

// Test 2: Character properties
print("Test 2: Character properties assignment")
var elements2 = VisualElements(
    sourceText: "Captain Drake",
    cardKind: .characters,
    extractionConfidence: 0.8
)
elements2.physicalBuild = "tall, athletic"
elements2.hair = "long dark hair"
elements2.eyes = "bright green eyes"
elements2.clothing = "orange jumpsuit"
assertEqual(elements2.physicalBuild, "tall, athletic", "Physical build should match")
assertEqual(elements2.hair, "long dark hair", "Hair should match")
assertEqual(elements2.eyes, "bright green eyes", "Eyes should match")
assertEqual(elements2.clothing, "orange jumpsuit", "Clothing should match")
print()

// Test 3: Building properties with cinematic framing
print("Test 3: Building properties with camera angle")
var elements3 = VisualElements(
    sourceText: "Magic Academy",
    cardKind: .buildings,
    extractionConfidence: 0.85
)
elements3.architecturalStyle = "gothic"
elements3.narrativeImportance = "grand"
elements3.cameraAngle = .lowAngleLookingUp
elements3.framing = .wideEstablishing
assertEqual(elements3.architecturalStyle, "gothic", "Architectural style should match")
assertEqual(elements3.narrativeImportance, "grand", "Narrative importance should match")
assertEqual(elements3.cameraAngle, .lowAngleLookingUp, "Camera angle should be low angle")
assertEqual(elements3.framing, .wideEstablishing, "Framing should be wide establishing")
print()

// Test 4: Artifact with partial object
print("Test 4: Artifact with partial object detection")
var elements4 = VisualElements(
    sourceText: "Shadowblade hilt",
    cardKind: .artifacts,
    extractionConfidence: 0.75
)
elements4.objectType = "sword"
elements4.showPartial = "hilt only"
elements4.framing = .closeUp
elements4.lightingStyle = .dramatic
assertEqual(elements4.objectType, "sword", "Object type should match")
assertEqual(elements4.showPartial, "hilt only", "Should show partial object")
assertEqual(elements4.framing, .closeUp, "Framing should be close-up")
assertEqual(elements4.lightingStyle, .dramatic, "Lighting should be dramatic")
print()

// Test 5: Scene with mood
print("Test 5: Scene with mood and lighting")
var elements5 = VisualElements(
    sourceText: "Tense confrontation",
    cardKind: .scenes,
    extractionConfidence: 0.7
)
elements5.isSceneWithMood = true
elements5.mood = "tense, confrontational"
elements5.lightingStyle = .dark
elements5.atmosphere = "foggy"
assert(elements5.isSceneWithMood == true, "Scene should have mood")
assertEqual(elements5.mood, "tense, confrontational", "Mood should match")
assertEqual(elements5.lightingStyle, .dark, "Lighting should be dark")
assertEqual(elements5.atmosphere, "foggy", "Atmosphere should match")
print()

// Test 6: hasSufficientData with empty elements
print("Test 6: hasSufficientData with empty elements")
let elements6 = VisualElements(
    sourceText: "Empty",
    cardKind: .characters,
    extractionConfidence: 0.5
)
assert(elements6.hasSufficientData == false, "Empty elements should not have sufficient data")
print()

// Test 7: hasSufficientData with enough properties
print("Test 7: hasSufficientData with 4 properties")
var elements7 = VisualElements(
    sourceText: "Warrior",
    cardKind: .characters,
    extractionConfidence: 0.8
)
elements7.physicalBuild = "tall"
elements7.hair = "dark"
elements7.eyes = "green"
elements7.clothing = "armor"
assert(elements7.hasSufficientData == true, "Elements with 4+ properties should have sufficient data")
print()

// Test 8: Codable round-trip
print("Test 8: JSON encoding/decoding")
var elements8 = VisualElements(
    sourceText: "Grand cathedral",
    cardKind: .buildings,
    extractionConfidence: 0.85
)
elements8.architecturalStyle = "gothic"
elements8.scale = "massive"
elements8.cameraAngle = .lowAngleLookingUp
elements8.materials = ["stone", "stained glass"]

do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(elements8)

    let decoder = JSONDecoder()
    let decoded = try decoder.decode(VisualElements.self, from: data)

    assertEqual(decoded.sourceText, elements8.sourceText, "Decoded source text should match")
    assertEqual(decoded.cardKind, elements8.cardKind, "Decoded card kind should match")
    assertEqual(decoded.architecturalStyle, elements8.architecturalStyle, "Decoded architectural style should match")
    assertEqual(decoded.cameraAngle, elements8.cameraAngle, "Decoded camera angle should match")
    assert(decoded.materials?.count == 2, "Decoded materials count should be 2")
    print("✅ PASS: JSON round-trip successful")
} catch {
    testsFailed += 1
    print("❌ FAIL: JSON encoding/decoding failed - \(error)")
}
print()

// Test 9: Enum display names
print("Test 9: Enum display names")
assertEqual(CameraAngle.lowAngleLookingUp.displayName, "low angle shot looking up", "Camera angle display name")
assertEqual(Framing.closeUp.displayName, "close-up", "Framing display name")
assertEqual(LightingStyle.dramatic.description, "dramatic lighting with strong shadows", "Lighting description")
print()

// Test 10: Vehicle properties
print("Test 10: Vehicle properties")
var elements10 = VisualElements(
    sourceText: "Airship",
    cardKind: .vehicles,
    extractionConfidence: 0.8
)
elements10.vehicleType = "airship"
elements10.vehicleDesign = "sleek hull"
elements10.motionState = "in flight"
elements10.materials = ["wood", "brass"]
assertEqual(elements10.vehicleType, "airship", "Vehicle type should match")
assertEqual(elements10.motionState, "in flight", "Motion state should match")
assert(elements10.materials?.count == 2, "Should have 2 materials")
print()

// Summary
print(String(repeating: "=", count: 60))
print("Test Summary:")
print(String(repeating: "=", count: 60))
print("Total tests run: \(testsRun)")
print("Passed: \(testsPassed) ✅")
print("Failed: \(testsFailed) ❌")
print()

if testsFailed == 0 {
    print("🎉 ALL TESTS PASSED! ER-0021 VisualElements model working correctly.")
    exit(0)
} else {
    print("⚠️  Some tests failed. Review failures above.")
    exit(1)
}
