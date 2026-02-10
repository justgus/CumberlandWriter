//
//  ProjectSelectionRouter.swift
//  Cumberland
//
//  Observable router that tracks the currently selected Project card used
//  as the context for StructureBoardView and MurderBoardView. Provides
//  select(_:) and clear() methods; injected into the SwiftUI environment.
//

import Observation

@Observable
final class ProjectSelectionRouter {
    var selectedProject: Card?

    func select(_ project: Card) {
        selectedProject = project
    }

    func clear() {
        selectedProject = nil
    }
}
