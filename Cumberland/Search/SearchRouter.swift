// SearchRouter.swift
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
