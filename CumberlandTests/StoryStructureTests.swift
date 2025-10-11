//
//  StoryStructureTests.swift
//  Cumberland
//
//  Created by Assistant on 10/10/25.
//

import Testing
import SwiftData
import Foundation
@testable import Cumberland

@Suite("Story Structure Tests")
struct StoryStructureTests {
    
    @Test("Creating a new story structure")
    func createStoryStructure() async throws {
        let structure = StoryStructure(name: "Three-Act Structure")
        
        #expect(structure.name == "Three-Act Structure")
        #expect((structure.elements ?? []).isEmpty)
        #expect(structure.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }
    
    @Test("Adding elements to structure")
    func addElementsToStructure() async throws {
        let structure = StoryStructure(name: "Test Structure")
        
        let element1 = StructureElement(name: "Act 1", orderIndex: 0)
        let element2 = StructureElement(name: "Act 2", orderIndex: 1)
        
        if structure.elements == nil { structure.elements = [] }
        structure.elements?.append(element1)
        structure.elements?.append(element2)
        
        #expect((structure.elements ?? []).count == 2)
        #expect(structure.elements?[0].name == "Act 1")
        #expect(structure.elements?[1].name == "Act 2")
    }
    
    @Test("Structure element color generation")
    func structureElementColorGeneration() async throws {
        let element1 = StructureElement(name: "Element 1", orderIndex: 0)
        let element2 = StructureElement(name: "Element 2", orderIndex: 1)
        
        // Colors should be different based on order index
        #expect(element1.displayColor != element2.displayColor)
    }
    
    @Test("Creating structure from template")
    func createFromTemplate() async throws {
        let template = StoryStructure.predefinedTemplates.first!
        let structure = StoryStructure.createFromTemplate(template)
        
        #expect(structure.name == template.name)
        #expect((structure.elements ?? []).count == template.elements.count)
        
        for (index, elementName) in template.elements.enumerated() {
            #expect(structure.elements?[index].name == elementName)
            #expect(structure.elements?[index].orderIndex == index)
        }
    }
}
