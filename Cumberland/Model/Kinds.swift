//
//  Kinds.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/2/25.
//
//  Defines the Kinds enum that categorises every Card (characters, scenes,
//  locations, maps, chapters, projects, timelines, calendars, sources, worlds).
//  Conforms to Codable for SwiftData storage via kindRaw String. Provides
//  displayName, plural form, SF Symbol, accent color, and sidebar sort order.
//

import Foundation
import SwiftUI

// Public model-level enum for categorizing Cards.
// Conforms to Codable so it can be stored by SwiftData.
enum Kinds: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case projects = "Projects"
    case worlds = "Worlds"
    case characters = "Characters"
    case chapters = "Chapters"
    case scenes = "Scenes"
    case timelines = "Timelines"
    case calendars = "Calendars"
    case maps = "Maps"
    case locations = "Locations"
    case buildings = "Buildings"
    case vehicles = "Vehicles"
    case artifacts = "Artifacts"
    case chronicles = "Chronicles" // Historical events, eras, and time periods
    case rules = "Rules"
    case sources = "Sources" // New: visible in sidebar
    case structure = "Structure" // New: story spine management

    var id: String { rawValue }

    // Ordered list exactly as requested, with Maps before Locations
    static let orderedCases: [Kinds] = [
        .projects, .worlds, .characters, .chapters, .scenes, .timelines, .calendars,
        .maps, .locations, .buildings, .vehicles, .artifacts, .chronicles, .rules, .sources, .structure
    ]

    var title: String { rawValue }

    // Singular display name for button labels and other contexts.
    var singularTitle: String {
        switch self {
        case .projects:   return "Project"
        case .worlds:     return "World"
        case .characters: return "Character"
        case .chapters:   return "Chapter"
        case .scenes:     return "Scene"
        case .timelines:  return "Timeline"
        case .calendars:  return "Calendar"
        case .maps:       return "Map"
        case .locations:  return "Location"
        case .buildings:  return "Building"
        case .vehicles:   return "Vehicle"
        case .artifacts:  return "Artifact"
        case .chronicles: return "Chronicle"
        case .rules:      return "Rule"
        case .sources:    return "Source"
        case .structure:  return "Structure"
        }
    }

    var systemImage: String {
        switch self {
        case .projects: return "folder"
        case .worlds: return "globe.europe.africa"
        case .characters: return "person.2"
        case .chapters: return "text.book.closed"
        case .scenes: return "film"
        case .timelines: return "calendar"
        case .calendars: return "calendar.badge.clock"
        case .maps: return "map"
        case .locations: return "mappin.and.ellipse"
        case .buildings: return "building.2"
        case .vehicles: return "car"
        case .artifacts: return "shippingbox"
        case .chronicles: return "scroll" // Historical records icon
        case .rules: return "list.bullet.rectangle"
        case .sources: return "book" // Bibliography-like icon
        case .structure: return "list.number" // Story structure icon
        }
    }

    // Public API: use these in your views
    func backgroundColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkColor : lightColor
    }

    func accentColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? darkAccentColor : lightAccentColor
    }

    // MARK: - Palette (light = pastel, dark = richer)
    // Hues are chosen to be distinct and readable. Tweak saturation/brightness to taste.

    var lightColor: Color {
        switch self {
        case .projects:   return Self.pastel(h: 210/360, s: 0.20, b: 0.96)
        case .worlds:     return Self.pastel(h: 160/360, s: 0.20, b: 0.96)
        case .characters: return Self.pastel(h: 280/360, s: 0.18, b: 0.96)
        case .chapters:   return Self.pastel(h:  50/360, s: 0.20, b: 0.97)
        case .scenes:     return Self.pastel(h: 340/360, s: 0.18, b: 0.97)
        case .timelines:  return Self.pastel(h:  30/360, s: 0.22, b: 0.97)
        case .calendars:  return Self.pastel(h: 245/360, s: 0.20, b: 0.96)
        case .maps:       return Self.pastel(h: 190/360, s: 0.18, b: 0.96)
        case .locations:  return Self.pastel(h: 110/360, s: 0.20, b: 0.96)
        case .buildings:  return Self.pastel(h:  10/360, s: 0.16, b: 0.96)
        case .vehicles:   return Self.pastel(h: 225/360, s: 0.20, b: 0.96)
        case .artifacts:  return Self.pastel(h: 300/360, s: 0.18, b: 0.96)
        case .chronicles: return Self.pastel(h:  40/360, s: 0.20, b: 0.97) // warm gold/amber
        case .rules:      return Self.pastel(h:  85/360, s: 0.16, b: 0.96)
        case .sources:    return Self.pastel(h: 260/360, s: 0.16, b: 0.97) // soft purple-blue
        case .structure:  return Self.pastel(h: 200/360, s: 0.18, b: 0.97) // soft cyan
        }
    }

    var darkColor: Color {
        switch self {
        case .projects:   return Self.rich(h: 210/360, s: 0.55, b: 0.28)
        case .worlds:     return Self.rich(h: 160/360, s: 0.55, b: 0.28)
        case .characters: return Self.rich(h: 280/360, s: 0.57, b: 0.30)
        case .chapters:   return Self.rich(h:  50/360, s: 0.60, b: 0.32)
        case .scenes:     return Self.rich(h: 340/360, s: 0.55, b: 0.30)
        case .timelines:  return Self.rich(h:  30/360, s: 0.60, b: 0.32)
        case .calendars:  return Self.rich(h: 245/360, s: 0.58, b: 0.30)
        case .maps:       return Self.rich(h: 190/360, s: 0.55, b: 0.28)
        case .locations:  return Self.rich(h: 110/360, s: 0.55, b: 0.28)
        case .buildings:  return Self.rich(h:  10/360, s: 0.55, b: 0.30)
        case .vehicles:   return Self.rich(h: 225/360, s: 0.57, b: 0.30)
        case .artifacts:  return Self.rich(h: 300/360, s: 0.60, b: 0.30)
        case .chronicles: return Self.rich(h:  40/360, s: 0.58, b: 0.32) // rich amber
        case .rules:      return Self.rich(h:  85/360, s: 0.57, b: 0.28)
        case .sources:    return Self.rich(h: 260/360, s: 0.58, b: 0.32)
        case .structure:  return Self.rich(h: 200/360, s: 0.58, b: 0.30)
        }
    }

    var lightAccentColor: Color { lightColor.opacity(0.9) }
    var darkAccentColor: Color { darkColor.opacity(0.96) }

    // MARK: - SF Symbols palette

    var symbolName: String {
        switch self {
        case .projects:   return "folder"
        case .worlds:     return "globe.europe.africa"
        case .characters: return "person.2"
        case .chapters:   return "text.book.closed"
        case .scenes:     return "film"
        case .timelines:  return "calendar"
        case .calendars:  return "calendar.badge.clock"
        case .maps:       return "map"
        case .locations:  return "mappin.and.ellipse"
        case .buildings:  return "building.2"
        case .vehicles:   return "car"
        case .artifacts:  return "shippingbox"
        case .chronicles: return "scroll"
        case .rules:      return "list.bullet.rectangle"
        case .sources:    return "book"
        case .structure:  return "list.number"
        }
    }

    var filledSymbolName: String {
        switch self {
        case .projects:   return "folder.fill"
        case .worlds:     return "globe.europe.africa"
        case .characters: return "person.2.fill"
        case .chapters:   return "text.book.closed.fill"
        case .scenes:     return "film.fill"
        case .timelines:  return "calendar"
        case .calendars:  return "calendar.badge.clock"
        case .maps:       return "map.fill"
        case .locations:  return "mappin.and.ellipse"
        case .buildings:  return "building.2.fill"
        case .vehicles:   return "car.fill"
        case .artifacts:  return "shippingbox.fill"
        case .chronicles: return "scroll.fill"
        case .rules:      return "list.bullet.rectangle.fill"
        case .sources:    return "book.fill"
        case .structure:  return "list.number"
        }
    }

    func symbolImage(filled: Bool = false) -> Image {
        Image(systemName: filled ? filledSymbolName : symbolName)
    }

    // MARK: - Helpers

    private static func pastel(h: CGFloat, s: CGFloat, b: CGFloat) -> Color {
        Color(hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: 1.0)
    }

    private static func rich(h: CGFloat, s: CGFloat, b: CGFloat) -> Color {
        Color(hue: Double(h), saturation: Double(s), brightness: Double(b), opacity: 1.0)
    }
} //end enum Kind

