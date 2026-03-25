// InvestigationNodeTests.swift
// MurderBoardTests

import Testing
import SwiftUI
import SwiftData
import Foundation
@testable import MurderBoard

@Suite("InvestigationNode Tests", .serialized)
struct InvestigationNodeTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: InvestigationBoard.self, InvestigationNode.self, InvestigationEdge.self,
            configurations: config
        )
        return container.mainContext
    }

    @Test("create node with default category (.person)")
    @MainActor
    func createNodeDefaultCategory() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "John Doe")
        ctx.insert(node)
        try ctx.save()

        #expect(node.category == .person)
        #expect(node.categoryRaw == "person")
        #expect(node.name == "John Doe")
    }

    @Test("category computed decodes from categoryRaw")
    @MainActor
    func categoryDecodesFromRaw() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Test")
        node.categoryRaw = "weapon"
        ctx.insert(node)

        #expect(node.category == .weapon)
    }

    @Test("category setter updates categoryRaw")
    @MainActor
    func categorySetterUpdatesRaw() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Test")
        ctx.insert(node)

        node.category = .document
        #expect(node.categoryRaw == "document")

        node.category = .vehicle
        #expect(node.categoryRaw == "vehicle")
    }

    @Test("all NodeCategory cases have non-empty systemImage")
    func allCategoriesHaveSystemImage() {
        for category in NodeCategory.allCases {
            #expect(!category.systemImage.isEmpty, "Category \(category) has empty systemImage")
        }
    }

    @Test("all NodeCategory cases have non-empty displayName")
    func allCategoriesHaveDisplayName() {
        for category in NodeCategory.allCases {
            #expect(!category.displayName.isEmpty, "Category \(category) has empty displayName")
        }
    }

    @Test("all NodeCategory cases have a defaultColor")
    func allCategoriesHaveDefaultColor() {
        // Verify all 8 categories return a color (no crashes)
        let colors = NodeCategory.allCases.map { $0.defaultColor }
        #expect(colors.count == 8)
    }

    @Test("transferData creates correct transfer representation")
    @MainActor
    func transferDataCorrect() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Evidence", category: .clue)
        ctx.insert(node)
        try ctx.save()

        let transfer = node.transferData()
        #expect(transfer.id == node.id)
        #expect(transfer.name == "Evidence")
        #expect(transfer.categoryRaw == "clue")
    }
}
