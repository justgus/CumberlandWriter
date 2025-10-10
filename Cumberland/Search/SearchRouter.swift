// SearchRouter.swift
import Observation

@Observable
final class SearchRouter {
    var isPresented: Bool = false

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
