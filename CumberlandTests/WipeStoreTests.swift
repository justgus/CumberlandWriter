import Testing
import SwiftData
@testable import Cumberland

final class WipeStoreTests {

    // Run this test to delete all on-disk data for the app's current store.
    @MainActor
    func testWipeAllData() throws {
        // Build the same container the app uses (on-disk, not in-memory)
        let schema = Schema(AppSchema.models)
        let container = try ModelContainer(for: schema, migrationPlan: AppMigrations.self)

        let context = ModelContext(container)
        context.autosaveEnabled = false

        // Fetch all Cards
        let allCards = try context.fetch(FetchDescriptor<Card>())

        // Cleanup external resources and delete
        for card in allCards {
            card.cleanupBeforeDeletion()
            context.delete(card)
        }

        try context.save()
    }
}
