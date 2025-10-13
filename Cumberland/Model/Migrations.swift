//
//  Migrations.swift
//  Cumberland
//
//  Created by Mike Stoddard on 10/1/25.
//

import SwiftData
import Foundation

// MARK: - Versioned Schemas

// V1: original schema (no originalImageData on Card)
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AppSettings.self, Card.self, RelationType.self, CardEdge.self, Source.self, Citation.self, StoryStructure.self, StructureElement.self]
    }
}

// V2: adds Card.originalImageData (optional, external storage)
enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AppSettings.self, Card.self, RelationType.self, CardEdge.self, Source.self, Citation.self, StoryStructure.self, StructureElement.self]
    }
}

// MARK: - Migration Plan

enum AppMigrations: SchemaMigrationPlan {
    // One stage from V1 to V2 with a data backfill for originals from local files.
    static var stages: [MigrationStage] = [
        MigrationStage.custom(
            fromVersion: AppSchemaV1.self,
            toVersion: AppSchemaV2.self,
            willMigrate: { _ in
                // Nothing needed pre-migration
            },
            didMigrate: { context in
                // Backfill Card.originalImageData for cards that have a local original file but no synced data yet.
                // We scan the ImageStore for files named "<UUID>.<ext>" and match them to Cards by id.
                let urls = ImageStore.shared.listAllOriginalImageURLs()
                guard urls.isEmpty == false else { return }

                // Build a map of id -> URL for quick lookup
                var byID: [UUID: URL] = [:]
                byID.reserveCapacity(urls.count)
                for u in urls {
                    if let id = ImageStore.shared.originalID(from: u) {
                        byID[id] = u
                    }
                }
                guard !byID.isEmpty else { return }

                // Fetch all Cards once and process
                var fetch = FetchDescriptor<Card>()
                fetch.fetchLimit = 0
                let cards: [Card] = (try? context.fetch(fetch)) ?? []
                var updated = 0

                for card in cards {
                    // Only backfill if missing synced data and a local file exists
                    guard card.originalImageData == nil, let url = byID[card.id] else { continue }
                    if let data = try? Data(contentsOf: url), !data.isEmpty {
                        card.originalImageData = data
                        // If thumbnail is missing, generate a small PNG from the original
                        if card.thumbnailData == nil, let cg = Card.makeCGImage(from: data) {
                            card.thumbnailData = Card.makePNGThumbnailData(from: cg, maxPixel: 256)
                        }
                        updated += 1
                    }
                }

                if updated > 0 {
                    try? context.save()
                }
            }
        )
    ]

    static var schemas: [any VersionedSchema.Type] = [
        AppSchemaV1.self,
        AppSchemaV2.self
    ]
}
