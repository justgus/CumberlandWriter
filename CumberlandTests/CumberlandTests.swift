//
//  CumberlandTests.swift
//  CumberlandTests
//
//  Created by Mike Stoddard on 10/1/25.
//

import Testing
@testable import Cumberland
import Foundation

@Suite("Core behavior tests")
struct CumberlandTests {

    @Test("Card search normalization folds case/diacritics")
    func searchNormalization() async throws {
        let c = Card(name: "Café", subtitle: "Résumé", detailedText: "Ångström")
        #expect(c.normalizedSearchText.contains("cafe"))
        #expect(c.normalizedSearchText.contains("resume"))
        #expect(c.normalizedSearchText.contains("angstrom"))

        // Changing fields should recompute
        let prev = c.normalizedSearchText
        c.name = "Delta"
        #expect(c.normalizedSearchText != prev)
        #expect(c.normalizedSearchText.contains("delta"))
    }

    @Test("ImageStore writes and deletes originals")
    func imageStoreWriteDelete() async throws {
        let id = UUID()
        let data = Data("test-payload".utf8)

        // Write
        let url = try await ImageStore.shared.writeOriginalImageData(data, for: id, fileExtension: "jpg")
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(ImageStore.shared.isURLInsideStore(url))

        // Resolve back to id
        let derived = await ImageStore.shared.originalID(from: url)
        #expect(derived == id)

        // Delete
        try await ImageStore.shared.deleteOriginalImage(at: url)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test("ImageStore pruning removes orphans")
    func imageStorePrune() async throws {
        let keepID = UUID()
        let dropID = UUID()
        let data = Data("x".utf8)
        _ = try await ImageStore.shared.writeOriginalImageData(data, for: keepID, fileExtension: "png")
        let dropURL = try await ImageStore.shared.writeOriginalImageData(data, for: dropID, fileExtension: "png")

        let deleted = await ImageStore.shared.pruneOrphanOriginals(existingIDs: [keepID])
        // Should contain the dropped file
        #expect(deleted.contains(dropURL))
        #expect(!FileManager.default.fileExists(atPath: dropURL.path))
    }
}
