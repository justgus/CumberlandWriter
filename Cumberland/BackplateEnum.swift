//
//  BackplateEnum.swift
//  Cumberland
//
//  Created by Mike Stoddard on 3/31/26.
//  Completed by Claude on 4/23/26.
//
//  Defines enums and utilities for loading themed backplate images.
//  Asset Structure: Assets.xcassets/Backplates/{Theme}/{Mode}/{Subject}.imageset
//

import SwiftUI

// MARK: - Theme Types

enum ThemeType: String, CaseIterable {
    case defaultTheme = "Default"
    case purpleTheme = "Purple"
    case halloweenTheme = "Halloween"
    case whimsicalTheme = "Whimsical"

    var displayName: String {
        switch self {
        case .defaultTheme: return "Default"
        case .purpleTheme: return "Purple"
        case .halloweenTheme: return "Halloween"
        case .whimsicalTheme: return "Whimsical"
        }
    }
} //end ThemeType

// MARK: - Mode Types

enum ModeType: String, CaseIterable {
    case lightMode = "Light"
    case darkMode = "Dark"

    var displayName: String { rawValue }
}

// MARK: - Subject Types (Backplate Items)

enum SubjectType: String, CaseIterable {
    case castle = "Castle"
    case cat = "Cat"
    case codex = "Codex"
    case couple = "Couple"
    case key = "Key"
    case lines = "Lines"
    case pen = "Pen"
    case sextant = "Sextant"
    case ship = "Ship"
    case sword = "Sword"
    case tree = "Tree"
    case watch = "Watch"

    var displayName: String { rawValue }
}

// MARK: - Backplate Enum Utility

struct BackplateEnum {

    // MARK: - Image Name Generation

    /// Generates the asset catalog image name for a backplate
    /// - Parameters:
    ///   - theme: The theme type (Default, Purple, Halloween, Whimsical)
    ///   - mode: Light or Dark mode
    ///   - subject: The backplate subject/item
    /// - Returns: Asset catalog image name with namespace path
    /// - Note: Theme and Mode folders have "provides-namespace": true
    func getImageName(theme: ThemeType, mode: ModeType, subject: SubjectType) -> String {
        return "\(theme.rawValue)/\(mode.rawValue)/\(subject.rawValue)"
    }

    // MARK: - Image Loading

    /// Loads a backplate image from the asset catalog
    /// - Parameters:
    ///   - theme: The theme type
    ///   - mode: Light or Dark mode
    ///   - subject: The backplate subject/item
    /// - Returns: SwiftUI Image if found, nil otherwise
    func getImage(theme: ThemeType, mode: ModeType, subject: SubjectType) -> Image? {
        let imageName = getImageName(theme: theme, mode: mode, subject: subject)

        #if DEBUG
        print("imageName = \(imageName)")
        #endif
        
        #if os(macOS)
        if NSImage(named: imageName) != nil {
            return Image(imageName)
        }
        #elseif os(iOS) || os(visionOS)
        if UIImage(named: imageName) != nil {
            return Image(imageName)
        }
        #endif

        return nil
    }

    /// Loads a backplate image using ColorScheme instead of ModeType
    /// - Parameters:
    ///   - theme: The theme type
    ///   - colorScheme: SwiftUI ColorScheme (.light or .dark)
    ///   - subject: The backplate subject/item
    /// - Returns: SwiftUI Image if found, nil otherwise
    func getImage(theme: ThemeType, colorScheme: ColorScheme, subject: SubjectType) -> Image? {
        let mode: ModeType = colorScheme == .dark ? .darkMode : .lightMode
        #if DEBUG
        let img = getImage(theme: theme, mode: mode, subject: subject)
        
        print("theme: \(theme), mode: \(mode), subject: \(subject) -> img: \(String(describing: img))")
        return img
        #else
        return getImage(theme: theme, mode: mode, subject: subject)
        #endif
    }

    // MARK: - Kind Mapping

    /// Maps Card kinds to appropriate backplate subjects for empty states
    /// - Parameter kind: The Card kind
    /// - Returns: Appropriate SubjectType for that kind
    func subjectForKind(_ kind: Kinds) -> SubjectType {
        switch kind {
        case .projects:   return .pen
        case .worlds:     return .tree
        case .characters: return .cat
        case .chapters:   return .pen
        case .scenes:     return .pen
        case .timelines:  return .watch
        case .calendars:  return .watch
        case .maps:       return .ship
        case .locations:  return .castle
        case .buildings:  return .castle
        case .vehicles:   return .ship
        case .artifacts:  return .sword
        case .chronicles: return .codex
        case .rules:      return .codex
        case .sources:    return .codex
        case .structure:  return .codex
        }
    }

    // MARK: - Theme Integration

    /// Converts ThemeManager theme name to ThemeType
    /// - Parameter themeName: Theme name from ThemeManager
    /// - Returns: Corresponding ThemeType
    func themeTypeFromThemeManager(_ themeName: String) -> ThemeType {
        switch themeName.lowercased() {
        case "halloween":
            return .halloweenTheme
        case "purple":
            return .purpleTheme
        case "whimsical":
            return .whimsicalTheme
        default:
            return .defaultTheme
        }
    }

} //end BackplateEnum
