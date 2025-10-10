//
//  Migrations.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import SwiftData

// Current app schema (v1). Add new VersionedSchema enums as you evolve the model.
enum AppSchema: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        // Include AppSettings so it’s persisted by the main ModelContainer.
        // Added Source and Citation (Option B).
        [Card.self, RelationType.self, CardEdge.self, AppSettings.self, Source.self, Citation.self]
    }
}

// Migration plan. Starts empty; append stages when you introduce new schemas.
// For destructive reset during development, we keep this empty and rely on your hard reset command.
enum AppMigrations: SchemaMigrationPlan {
    static var stages: [MigrationStage] = []

    static var schemas: [any VersionedSchema.Type] = [
        AppSchema.self
    ]
}

