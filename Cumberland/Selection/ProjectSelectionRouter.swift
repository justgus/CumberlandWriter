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
