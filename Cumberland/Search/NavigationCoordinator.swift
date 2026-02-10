//
//  NavigationCoordinator.swift
//  Cumberland
//
//  Observable coordinator that allows search results and other contextual
//  flows to force-present a specific card in CardSheetView regardless of
//  the current sidebar selection. Shared via SwiftUI environment throughout
//  MainAppView.
//

import SwiftUI

@Observable
final class NavigationCoordinator {
    // When true, any Card selection should be shown as CardSheetView
    // regardless of context (e.g., search results).
    var forceCardSheetView: Bool = false

    // Optional: keep track of a specifically forced card if you need it elsewhere.
    // Not strictly required for routing in MainAppView, but useful for intents.
    var forcedCardID: UUID?

    func showCardSheet(for card: Card) {
        forcedCardID = card.id
        forceCardSheetView = true
    }

    func clearForce() {
        forcedCardID = nil
        forceCardSheetView = false
    }

    // Stub retained for compatibility with any callers you may add later.
    func navigateToSearchResult(_ result: SearchResult) {
        // Implement navigation as needed in your app.
        print("Navigate to card: \(result.card.name)")
    }
}

