//
//  OrnamentViews.swift
//  Cumberland
//
//  Created by Cumberland Development Team on 11/8/25.
//  visionOS ornament components for spatial UI
//
//  Provides visionOS ornament views attached to the main window and card
//  editor windows: sidebar navigation controls, mode switcher, and action
//  buttons rendered as floating ornaments in the spatial computing environment.
//

import SwiftUI

#if os(visionOS)

// MARK: - Primary Actions Ornament

/// Primary action buttons for card management, displayed at the bottom of the window.
/// Includes New Card, Edit Card, Refresh, and (in DEBUG) Developer Boards buttons.
/// Phase 4: Enhanced with better accessibility and focus management.
struct PrimaryActionsOrnament: View {
    let onNewCard: () -> Void
    let onEditCard: () -> Void
    let onRefresh: () -> Void
    let canEdit: Bool
    let isStructureSelected: Bool
    
    #if DEBUG
    let onDeveloperBoards: () -> Void
    #endif
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onNewCard()
            } label: {
                Label("New Card", systemImage: "plus")
            }
            .disabled(isStructureSelected)
            .glassBackgroundEffect()
            .accessibilityLabel("Create new card")
            .accessibilityHint(isStructureSelected ? "Unavailable in Structure view" : "Opens card editor")
            .keyboardShortcut("n", modifiers: [.command])
            
            Button {
                onEditCard()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .disabled(!canEdit)
            .glassBackgroundEffect()
            .accessibilityLabel("Edit selected card")
            .accessibilityHint(canEdit ? "Opens editor for the selected card" : "Select a card first")
            .keyboardShortcut("e", modifiers: [.command])
            
            Button {
                onRefresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .glassBackgroundEffect()
            .accessibilityLabel("Refresh list")
            .accessibilityHint("Reloads the current view to show latest changes")
            .keyboardShortcut("r", modifiers: [.command])
            
            #if DEBUG
            Button {
                onDeveloperBoards()
            } label: {
                Label("Developer Boards", systemImage: "wrench.and.screwdriver")
            }
            .glassBackgroundEffect()
            .help("Inspect and repair Boards and BoardNodes")
            .accessibilityLabel("Developer Boards")
            .accessibilityHint("Opens developer debugging tools")
            .keyboardShortcut("d", modifiers: [.command, .shift])
            #endif
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Primary actions")
    }
}

// MARK: - Settings Ornament

/// Settings button ornament, displayed on the leading edge of the window.
/// Collapses to icon-only when not being looked at, expands to show text on hover.
/// Opens Settings in a standalone window (windows provide their own dismiss controls).
struct SettingsOrnament: View {
    let onSettings: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button {
            onSettings()
        } label: {
            if isHovered {
                Label("Settings", systemImage: "gear")
                    .labelStyle(.titleAndIcon)
            } else {
                Label("Settings", systemImage: "gear")
                    .labelStyle(.iconOnly)
            }
        }
        .glassBackgroundEffect()
        .accessibilityLabel("Settings")
        .accessibilityHint("Opens application settings")
        .keyboardShortcut(",", modifiers: [.command])
        .onContinuousHover { phase in
            switch phase {
            case .active:
                withAnimation(.easeInOut(duration: 0.2)) { isHovered = true }
            case .ended:
                withAnimation(.easeInOut(duration: 0.2)) { isHovered = false }
            }
        }
        .padding()
    }
}

// MARK: - Developer Tools Ornament

#if DEBUG
/// Developer Tools button ornament, displayed on the leading edge below Settings.
/// Collapses to icon-only when not being looked at, expands to show text on hover.
/// Opens Developer Tools in a standalone window (windows provide their own dismiss controls).
struct DeveloperToolsOrnament: View {
    let onDeveloperTools: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button {
            onDeveloperTools()
        } label: {
            if isHovered {
                Label("Developer Tools", systemImage: "hammer.fill")
                    .labelStyle(.titleAndIcon)
            } else {
                Label("Developer Tools", systemImage: "hammer.fill")
                    .labelStyle(.iconOnly)
            }
        }
        .glassBackgroundEffect()
        .accessibilityLabel("Developer Tools")
        .accessibilityHint("Opens developer debugging tools and utilities")
        .keyboardShortcut("t", modifiers: [.command, .option])
        .onContinuousHover { phase in
            switch phase {
            case .active:
                withAnimation(.easeInOut(duration: 0.2)) { isHovered = true }
            case .ended:
                withAnimation(.easeInOut(duration: 0.2)) { isHovered = false }
            }
        }
        .padding()
    }
}
#endif

// MARK: - Detail Tab Picker Ornament

/// Tab picker for switching between card detail views (Details, Relationships, Board, etc.).
/// Displayed on the trailing edge of the detail column.
/// Phase 4: Enhanced with better accessibility and larger tap targets.
struct DetailTabPickerOrnament: View {
    let tabs: [CardDetailTab]
    @Binding var selectedTab: CardDetailTab
    
    var body: some View {
        Picker("Card View", selection: $selectedTab) {
            ForEach(tabs) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 420)
        .glassBackgroundEffect()
        .padding()
        .accessibilityLabel("Card detail view selector")
        .accessibilityHint("Choose which view to display for the selected card")
        // Phase 4: Better keyboard navigation
        .focusable(true)
    }
}

// MARK: - Preview Support

#if DEBUG
#Preview("Primary Actions Ornament") {
    PrimaryActionsOrnament(
        onNewCard: { print("New Card") },
        onEditCard: { print("Edit Card") },
        onRefresh: { print("Refresh") },
        canEdit: true,
        isStructureSelected: false,
        onDeveloperBoards: { print("Developer Boards") }
    )
    .frame(width: 400, height: 100)
}

#Preview("Settings Ornament") {
    SettingsOrnament(
        onSettings: { print("Settings") }
    )
    .frame(width: 160, height: 80)
}

#Preview("Developer Tools Ornament") {
    DeveloperToolsOrnament(
        onDeveloperTools: { print("Developer Tools") }
    )
    .frame(width: 180, height: 80)
}

#Preview("Detail Tab Picker Ornament") {
    @Previewable @State var selectedTab: CardDetailTab = .details
    
    DetailTabPickerOrnament(
        tabs: [.details, .relationships, .board],
        selectedTab: $selectedTab
    )
    .frame(width: 450, height: 100)
}
#endif // DEBUG

#endif // os(visionOS)
