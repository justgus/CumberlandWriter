// StructureAssignmentManagerTests.swift
// CumberlandTests

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("StructureAssignmentManager Tests", .serialized)
struct StructureAssignmentManagerTests {

    @MainActor
    private func makeManager() throws -> (StructureAssignmentManager, ModelContext) {
        let (_, ctx) = try TestFixtures.makeFullSchemaContainer()
        let mgr = StructureAssignmentManager(modelContext: ctx)
        return (mgr, ctx)
    }

    @Test("assignCard adds card without duplicates")
    @MainActor
    func assignNoDuplicates() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleScene(context: ctx)
        let structure = StoryStructure(name: "Test")
        let element = StructureElement(name: "Act 1", orderIndex: 0)
        element.storyStructure = structure
        ctx.insert(structure); ctx.insert(element)
        try ctx.save()

        mgr.assignCard(card, to: element)
        mgr.assignCard(card, to: element) // duplicate

        #expect((element.assignedCards ?? []).count == 1)
    }

    @Test("unassignCard removes card from element")
    @MainActor
    func unassignRemoves() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleScene(context: ctx)
        let structure = StoryStructure(name: "Test")
        let element = StructureElement(name: "Act 1", orderIndex: 0)
        element.storyStructure = structure
        ctx.insert(structure); ctx.insert(element)
        try ctx.save()

        mgr.assignCard(card, to: element)
        #expect((element.assignedCards ?? []).count == 1)

        mgr.unassignCard(card, from: element)
        #expect((element.assignedCards ?? []).isEmpty)
    }

    @Test("setAssignments replaces current with desired set")
    @MainActor
    func setAssignmentsReplaces() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleScene(context: ctx)
        let structure = StoryStructure(name: "Test")
        let elA = StructureElement(name: "A", orderIndex: 0)
        let elB = StructureElement(name: "B", orderIndex: 1)
        let elC = StructureElement(name: "C", orderIndex: 2)
        for el in [elA, elB, elC] { el.storyStructure = structure }
        ctx.insert(structure); ctx.insert(elA); ctx.insert(elB); ctx.insert(elC)
        try ctx.save()

        // Start: assigned to A and B
        mgr.assignCard(card, to: elA)
        mgr.assignCard(card, to: elB)

        // Replace with B and C
        mgr.setAssignments(for: card, to: [elB, elC])

        // A should no longer contain card
        #expect(!(elA.assignedCards ?? []).contains(where: { $0.id == card.id }))
        // B should still contain card
        #expect((elB.assignedCards ?? []).contains(where: { $0.id == card.id }))
        // C should now contain card
        #expect((elC.assignedCards ?? []).contains(where: { $0.id == card.id }))
    }

    @Test("getStructureElements returns all elements for a card")
    @MainActor
    func getElementsReturnsAll() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleScene(context: ctx)
        let structure = StoryStructure(name: "Test")
        let elA = StructureElement(name: "A", orderIndex: 0)
        let elB = StructureElement(name: "B", orderIndex: 1)
        for el in [elA, elB] { el.storyStructure = structure }
        ctx.insert(structure); ctx.insert(elA); ctx.insert(elB)
        try ctx.save()

        mgr.assignCard(card, to: elA)
        mgr.assignCard(card, to: elB)

        let elements = mgr.getStructureElements(for: card)
        #expect(elements.count == 2)
    }

    @Test("assignCard to nil element is no-op")
    @MainActor
    func assignToNilIsNoop() async throws {
        let (mgr, ctx) = try makeManager()
        let card = TestFixtures.createSampleScene(context: ctx)
        try ctx.save()

        // Should not crash
        mgr.assignCard(card, to: nil)
    }
}
