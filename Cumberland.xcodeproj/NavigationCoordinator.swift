// NavigationCoordinator.swift  
import Foundation
import SwiftUI
import SwiftData

// MARK: - Navigation Coordinator

@Observable
final class NavigationCoordinator {
    // Current navigation state
    var selectedKind: Kinds?
    var selectedCard: Card?
    var forceCardSheetView: Bool = false
    
    // Search integration
    private var searchRouter: SearchRouter?
    
    init() {}
    
    func setSearchRouter(_ router: SearchRouter) {
        self.searchRouter = router
    }
    
    // Navigate to a specific card from search results
    func navigateToSearchResult(_ result: SearchResult) {
        selectedKind = result.card.kind
        selectedCard = result.card
        forceCardSheetView = true
        
        // Close search overlay
        searchRouter?.close()
    }
    
    // Navigate to a kind's default view
    func navigateToKind(_ kind: Kinds) {
        selectedKind = kind
        selectedCard = nil
        forceCardSheetView = false
    }
    
    // Navigate to a specific card with default detail view for that kind
    func navigateToCard(_ card: Card, forceCardSheet: Bool = false) {
        selectedKind = card.kind
        selectedCard = card
        forceCardSheetView = forceCardSheet
    }
    
    // Reset navigation state
    func reset() {
        selectedKind = nil
        selectedCard = nil
        forceCardSheetView = false
    }
}

// MARK: - Navigation Environment Key

private struct NavigationCoordinatorKey: EnvironmentKey {
    static let defaultValue: NavigationCoordinator? = nil
}

extension EnvironmentValues {
    var navigationCoordinator: NavigationCoordinator? {
        get { self[NavigationCoordinatorKey.self] }
        set { self[NavigationCoordinatorKey.self] = newValue }
    }
}