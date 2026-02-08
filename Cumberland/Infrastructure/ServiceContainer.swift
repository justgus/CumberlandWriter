//
//  ServiceContainer.swift
//  Cumberland
//
//  Created by Claude Code on 2026-02-07.
//  Part of ER-0022: Code Maintainability Refactoring - Phase 4
//

import Foundation
import SwiftUI
import SwiftData

/// Centralized container for all Cumberland services and repositories.
///
/// **ER-0022 Phase 4**: Provides dependency injection infrastructure.
///
/// ## Usage
///
/// The ServiceContainer is initialized once in CumberlandApp and injected into
/// the view hierarchy via the `.serviceContainer()` modifier. Views access
/// services through the environment:
///
/// ```swift
/// struct MyView: View {
///     @Environment(\.services) private var services
///
///     var body: some View {
///         Button("Create Card") {
///             try? services.cardOperations.createCard(kind: .characters, name: "New Character")
///         }
///     }
/// }
/// ```
@Observable
@MainActor
final class ServiceContainer {

    // MARK: - Repositories (Data Access Layer)

    /// Repository for Card data access
    let cardRepository: CardRepository

    /// Repository for CardEdge data access
    let edgeRepository: EdgeRepository

    /// Repository for StoryStructure data access
    let structureRepository: StructureRepository

    /// Service for common query patterns
    let queryService: QueryService

    // MARK: - Services (Business Logic Layer)

    /// Manager for Card CRUD operations
    let cardOperations: CardOperationManager

    /// Manager for relationship (CardEdge) operations
    let relationshipManager: RelationshipManager

    /// Service for image processing (singleton - no context needed)
    var imageProcessing: ImageProcessingService {
        ImageProcessingService.shared
    }

    // MARK: - Context Access

    /// The underlying ModelContext (for advanced use cases)
    let modelContext: ModelContext

    // MARK: - Initialization

    /// Initialize the service container with a ModelContext
    /// - Parameter modelContext: The SwiftData ModelContext to use for all operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        // Initialize repositories
        self.cardRepository = CardRepository(modelContext: modelContext)
        self.edgeRepository = EdgeRepository(modelContext: modelContext)
        self.structureRepository = StructureRepository(modelContext: modelContext)
        self.queryService = QueryService(modelContext: modelContext)

        // Initialize services (they use repositories internally or the context)
        self.cardOperations = CardOperationManager(modelContext: modelContext)
        self.relationshipManager = RelationshipManager(modelContext: modelContext)
    }

    // MARK: - Convenience Factory

    /// Create a ServiceContainer from a ModelContainer
    /// - Parameter container: The ModelContainer
    /// - Returns: A configured ServiceContainer
    static func create(from container: ModelContainer) -> ServiceContainer {
        ServiceContainer(modelContext: container.mainContext)
    }
}

// MARK: - Environment Key

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer? = nil
}

extension EnvironmentValues {
    /// The service container for dependency injection
    ///
    /// Access services in views:
    /// ```swift
    /// @Environment(\.services) private var services
    /// ```
    var services: ServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// Inject the service container into the view hierarchy
    /// - Parameter container: The ServiceContainer to inject
    /// - Returns: A view with the service container in its environment
    func serviceContainer(_ container: ServiceContainer) -> some View {
        self.environment(\.services, container)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ServiceContainer {
    /// Create a ServiceContainer for previews using an in-memory store
    static func preview() -> ServiceContainer {
        let schema = Schema(AppSchemaV5.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ServiceContainer(modelContext: container.mainContext)
    }
}
#endif
