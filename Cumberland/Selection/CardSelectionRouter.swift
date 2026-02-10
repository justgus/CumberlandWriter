//
//  CardSelectionRouter.swift
//  Cumberland
//
//  Observable router that tracks the currently selected Card for detail
//  presentation. Provides select(_:) and clear() methods. Injected into
//  the SwiftUI environment so any view can programmatically navigate to a
//  specific card.
//

import Observation

@Observable
final class CardSelectionRouter {
    var selectedCard: Card?

    func select(_ card: Card) {
        selectedCard = card
    }

    func clear() {
        selectedCard = nil
    }
}
