import Testing
import SwiftData
@testable import Cumberland

final class WipeStoreTests {

    // Run this test to delete all on-disk data for the app's current store.
    @MainActor
    func testWipeAllData() throws {
        // Build the same container the app uses (on-disk, not in-memory)
        let container = try ModelContainer(
            for: Card.self, Board.self, BoardNode.self, Citation.self, RelationType.self, Source.self, StoryStructure.self, StructureElement.self, CalendarSystem.self, SuggestionFeedback.self,
            migrationPlan: AppMigrations.self
        )

        let context = ModelContext(container)
        context.autosaveEnabled = false

        // Fetch all Cards
        let allCards = try context.fetch(FetchDescriptor<Card>())

        // Cleanup external resources and delete
        for card in allCards {
            card.cleanupBeforeDeletion(in: context)
            context.delete(card)
        }

        try context.save()
    }
}
