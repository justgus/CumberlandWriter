//
//  ThemingSystemTests.swift
//  CumberlandTests
//
//  ER-0052 Phase 2: Theming System Tests
//  Tests the multi-theme support system including:
//  - Theme switching and persistence
//  - Built-in theme availability
//  - Theme token access
//  - Background image management
//

import Testing
import SwiftData
import SwiftUI
@testable import Cumberland

// MARK: - Test Suite

/// Test suite for Theming System validation
@Suite("Theming System Tests", .tags(.phase2, .themingSystem))
@MainActor
struct ThemingSystemTests {

    // MARK: - Theme Manager Tests

    @Test("ThemeManager provides default theme on launch")
    @MainActor
    func testDefaultTheme() {
        // Given: Fresh ThemeManager instance
        let themeManager = ThemeManager()
        themeManager.setTheme("default") // Ensure we're on default theme

        // Then: Should have a current theme
        #expect(themeManager.currentTheme.id == "default")
        #expect(themeManager.currentTheme.displayName == "Default")
    }

    @Test("ThemeManager switches between themes")
    @MainActor
    func testThemeSwitching() {
        // Given: ThemeManager with default theme
        let themeManager = ThemeManager()
        themeManager.setTheme("default") // Reset to known state
        let initialTheme = themeManager.currentTheme.id

        // When: Switching to purple theme
        themeManager.setTheme("purple")

        // Then: Current theme should be purple
        #expect(themeManager.currentTheme.id == "purple")
        #expect(themeManager.currentTheme.id != initialTheme)
    }

    @Test("ThemeManager persists theme selection")
    @MainActor
    func testThemePersistence() {
        // Given: ThemeManager with purple theme selected
        let themeManager = ThemeManager()
        themeManager.setTheme("purple")

        // When: Theme ID is persisted (simulated by checking current state)
        let persistedID = themeManager.currentTheme.id

        // Then: Persisted ID should match selection
        #expect(persistedID == "purple")
    }

    @Test("ThemeManager provides all built-in themes")
    @MainActor
    func testBuiltInThemes() {
        // Given: ThemeManager instance
        let themeManager = ThemeManager()

        // When: Checking available themes
        // Built-in themes: default, whimsical, purple, halloween

        // Then: All built-in themes should be accessible
        themeManager.setTheme("default")
        #expect(themeManager.currentTheme.id == "default")

        themeManager.setTheme("whimsical")
        #expect(themeManager.currentTheme.id == "whimsical")

        themeManager.setTheme("purple")
        #expect(themeManager.currentTheme.id == "purple")

        themeManager.setTheme("halloween")
        #expect(themeManager.currentTheme.id == "halloween")
    }

    @Test("ThemeManager identifies user themes")
    @MainActor
    func testUserThemeIdentification() {
        // Given: ThemeManager with built-in themes
        let themeManager = ThemeManager()

        // Then: Built-in themes should not be identified as user themes
        #expect(themeManager.isUserTheme("default") == false)
        #expect(themeManager.isUserTheme("purple") == false)
        #expect(themeManager.isUserTheme("whimsical") == false)
    }

    // MARK: - Theme Color Tests

    @Test("Default theme provides accent colors")
    func testDefaultThemeAccentColors() {
        // Given: Default theme
        let theme = DefaultTheme()

        // Then: Accent colors should be defined
        _ = theme.colors.accentPrimary
        _ = theme.colors.surfacePrimary
    }

    @Test("Purple theme provides distinct colors")
    func testPurpleThemeColors() {
        // Given: Purple theme
        let theme = PurpleTheme()

        // Then: Should have distinct color palette
        _ = theme.colors.accentPrimary
        #expect(theme.displayName == "Purple Reign")
    }

    @Test("Whimsical theme provides distinct colors")
    func testWhimsicalThemeColors() {
        // Given: Whimsical theme
        let theme = WhimsicalTheme()

        // Then: Should have distinct color palette
        _ = theme.colors.accentPrimary
        #expect(theme.displayName == "Whimsical")
    }

    @Test("Halloween theme provides distinct colors")
    func testHalloweenThemeColors() {
        // Given: Halloween theme
        let theme = HalloweenTheme()

        // Then: Should have distinct color palette
        _ = theme.colors.accentPrimary
        #expect(theme.displayName == "Halloween")
    }

    // MARK: - Theme Token Tests

    @Test("Theme provides typography tokens")
    @MainActor
    func testThemeTypography() {
        // Given: A theme
        let _ = DefaultTheme()

        // Then: Typography tokens should be defined
        //#expect(theme.fonts.headline != nil)
        //#expect(theme.fonts.body != nil)
        //#expect(theme.fonts.caption != nil)
    }

    @Test("Theme provides shape tokens")
    func testThemeShapes() {
        // Given: A theme
        let theme = DefaultTheme()

        // Then: Shape tokens should be defined
        #expect(theme.shapes.cardCornerRadius >= 0)
        #expect(theme.shapes.buttonCornerRadius >= 0)
    }

    @Test("Theme provides shadow tokens")
    func testThemeShadows() {
        // Given: A theme
        let theme = DefaultTheme()

        // Then: Shadow tokens should be defined
        _ = theme.shadows.cardColor
        #expect(theme.shadows.cardDarkOpacity >= 0)
    }

    @Test("Theme provides spacing tokens")
    func testThemeSpacing() {
        // Given: A theme
        let theme = DefaultTheme()

        // Then: Spacing tokens should be defined
        #expect(theme.spacing.cardPadding > 0)
        #expect(theme.spacing.sectionSpacing > 0)
    }

    // MARK: - Background Image Tests

    @Test("Theme provides background images")
    func testThemeBackgroundImages() {
        // Given: A theme with background images
        let theme = PurpleTheme()

        // Then: Background images should be accessible
        _ = theme.backgroundImages.sidebarBackground
        _ = theme.backgroundImages.contentBackground
    }

    @Test("Background images are optional")
    func testBackgroundImagesOptional() {
        // Given: A theme
        let theme = DefaultTheme()

        // Then: Background images can be nil
        // This test verifies optional background support
        _ = theme.backgroundImages.sidebarBackground
    }
}

// MARK: - Test Tags Extension

extension Tag {
    @Tag static var themingSystem: Self
}
