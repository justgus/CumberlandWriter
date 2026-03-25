// InvestigationWrapperTests.swift
// MurderBoardTests

import Testing
import SwiftUI
import SwiftData
import Foundation
@testable import MurderBoard

@Suite("Investigation Wrapper Tests", .serialized)
struct InvestigationWrapperTests {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: InvestigationBoard.self, InvestigationNode.self, InvestigationEdge.self,
            configurations: config
        )
        return container.mainContext
    }

    // MARK: - InvestigationNodeWrapper

    @Test("InvestigationNodeWrapper.init maps all properties")
    @MainActor
    func nodeWrapperMapsAllProperties() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Suspect", subtitle: "Main suspect", category: .person, posX: 100, posY: 200)
        node.zIndex = 5.0
        node.pinned = true
        ctx.insert(node)
        try ctx.save()

        let wrapper = InvestigationNodeWrapper(from: node, primaryNodeID: nil)

        #expect(wrapper.nodeID == node.id)
        #expect(wrapper.posX == 100)
        #expect(wrapper.posY == 200)
        #expect(wrapper.zIndex == 5.0)
        #expect(wrapper.isPinned == true)
        #expect(wrapper.displayName == "Suspect")
        #expect(wrapper.subtitle == "Main suspect")
        #expect(wrapper.categorySystemImage == NodeCategory.person.systemImage)
        #expect(wrapper.category == .person)
    }

    @Test("isPrimary true when matches primaryNodeID")
    @MainActor
    func wrapperIsPrimaryTrue() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Detective", category: .person)
        ctx.insert(node)
        try ctx.save()

        let wrapper = InvestigationNodeWrapper(from: node, primaryNodeID: node.id)
        #expect(wrapper.isPrimary == true)
    }

    @Test("isPrimary false otherwise")
    @MainActor
    func wrapperIsPrimaryFalse() async throws {
        let ctx = try makeContext()
        let node = InvestigationNode(name: "Bystander", category: .person)
        ctx.insert(node)
        try ctx.save()

        let wrapper = InvestigationNodeWrapper(from: node, primaryNodeID: UUID())
        #expect(wrapper.isPrimary == false)
    }

    @Test("accentColor returns category defaultColor")
    @MainActor
    func wrapperAccentColorUsesCategory() async throws {
        let ctx = try makeContext()

        for category in NodeCategory.allCases {
            let node = InvestigationNode(name: "Test", category: category)
            ctx.insert(node)

            let wrapper = InvestigationNodeWrapper(from: node, primaryNodeID: nil)
            let color = wrapper.accentColor(for: .light)
            #expect(color == category.defaultColor)
        }
    }

    // MARK: - InvestigationEdgeWrapper

    @Test("InvestigationEdgeWrapper.init maps edge properties")
    @MainActor
    func edgeWrapperMapsProperties() async throws {
        let ctx = try makeContext()
        let sourceID = UUID()
        let targetID = UUID()
        let edge = InvestigationEdge(sourceNodeID: sourceID, targetNodeID: targetID, label: "witnessed")
        ctx.insert(edge)
        try ctx.save()

        let wrapper = InvestigationEdgeWrapper(from: edge)

        #expect(wrapper.edgeID == edge.id)
        #expect(wrapper.sourceNodeID == sourceID)
        #expect(wrapper.targetNodeID == targetID)
        #expect(wrapper.createdAt == edge.createdAt)
    }

    @Test("typeCode comes from edge label")
    @MainActor
    func edgeWrapperTypeCodeFromLabel() async throws {
        let ctx = try makeContext()
        let edge = InvestigationEdge(sourceNodeID: UUID(), targetNodeID: UUID(), label: "suspects")
        ctx.insert(edge)
        try ctx.save()

        let wrapper = InvestigationEdgeWrapper(from: edge)
        #expect(wrapper.typeCode == "suspects")
    }
}
