// CardSelectionRouter.swift
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
