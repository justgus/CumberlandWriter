//
//  SearchRouter.swift
//  Cumberland
//
//  Observable router that controls whether the SearchOverlay is presented.
//  Holds a reference to the current SearchEngine instance and exposes
//  show()/hide() methods. Injected into the SwiftUI environment so toolbar
//  buttons and keyboard shortcuts can trigger search from anywhere.
//

import Observation
import SwiftData

@Observable
final class SearchRouter {
    var isPresented: Bool = false
    var searchEngine: SearchEngine?
    
    init() {}
    
    func setSearchEngine(_ engine: SearchEngine) {
        self.searchEngine = engine
    }

    func open() {
        isPresented = true
    }

    func close() {
        isPresented = false
    }

    func toggle() {
        isPresented.toggle()
    }
}
