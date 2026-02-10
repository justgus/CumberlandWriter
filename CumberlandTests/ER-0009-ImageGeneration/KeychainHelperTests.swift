//
//  KeychainHelperTests.swift
//  CumberlandTests
//
//  Swift Testing suite for ER-0009: AI Image Generation (Phase 1).
//  Tests KeychainHelper secure API key storage: save, retrieve, update,
//  and delete operations; empty-string handling; and multi-key isolation.
//

import Testing
@testable import Cumberland

/// Tests for KeychainHelper secure API key storage
/// Part of ER-0009: AI Image Generation (Phase 1)
@Suite("KeychainHelper Tests")
struct KeychainHelperTests {

    // MARK: - Setup/Teardown

    init() {
        // Clear keychain before tests
        try? KeychainHelper.shared.deleteAllAPIKeys()
    }

    // MARK: - Save and Retrieve Tests

    @Test("Save and retrieve API key")
    func saveAndRetrieveAPIKey() throws {
        let helper = KeychainHelper.shared
        let provider = "openai"
        let apiKey = "sk-test-12345"

        // Save
        try helper.saveAPIKey(apiKey, for: provider)

        // Retrieve
        let retrieved = try helper.retrieveAPIKey(for: provider)
        #expect(retrieved == apiKey)

        // Cleanup
        try helper.deleteAPIKey(for: provider)
    }

    @Test("Retrieve non-existent API key returns nil")
    func retrieveNonExistentKey() throws {
        let helper = KeychainHelper.shared
        let retrieved = try helper.retrieveAPIKey(for: "nonexistent")
        #expect(retrieved == nil)
    }

    @Test("Save empty API key throws error")
    func saveEmptyKeyThrows() throws {
        let helper = KeychainHelper.shared

        #expect(throws: KeychainError.self) {
            try helper.saveAPIKey("", for: "openai")
        }
    }

    // MARK: - Update Tests

    @Test("Update existing API key")
    func updateExistingKey() throws {
        let helper = KeychainHelper.shared
        let provider = "openai"
        let oldKey = "sk-old-12345"
        let newKey = "sk-new-67890"

        // Save initial key
        try helper.saveAPIKey(oldKey, for: provider)

        // Update
        try helper.saveAPIKey(newKey, for: provider)

        // Verify updated
        let retrieved = try helper.retrieveAPIKey(for: provider)
        #expect(retrieved == newKey)
        #expect(retrieved != oldKey)

        // Cleanup
        try helper.deleteAPIKey(for: provider)
    }

    // MARK: - Delete Tests

    @Test("Delete API key")
    func deleteAPIKey() throws {
        let helper = KeychainHelper.shared
        let provider = "openai"
        let apiKey = "sk-test-12345"

        // Save
        try helper.saveAPIKey(apiKey, for: provider)

        // Verify exists
        #expect(helper.hasAPIKey(for: provider) == true)

        // Delete
        try helper.deleteAPIKey(for: provider)

        // Verify deleted
        #expect(helper.hasAPIKey(for: provider) == false)
        let retrieved = try helper.retrieveAPIKey(for: provider)
        #expect(retrieved == nil)
    }

    @Test("Delete non-existent key does not throw")
    func deleteNonExistentKey() throws {
        let helper = KeychainHelper.shared

        // Should not throw
        try helper.deleteAPIKey(for: "nonexistent")
    }

    // MARK: - Multiple Provider Tests

    @Test("Store keys for multiple providers")
    func multipleProviders() throws {
        let helper = KeychainHelper.shared
        let providers = [
            "openai": "sk-openai-12345",
            "anthropic": "sk-anthropic-67890",
            "google": "sk-google-abcdef"
        ]

        // Save all
        for (provider, key) in providers {
            try helper.saveAPIKey(key, for: provider)
        }

        // Verify all
        for (provider, expectedKey) in providers {
            let retrieved = try helper.retrieveAPIKey(for: provider)
            #expect(retrieved == expectedKey)
        }

        // Cleanup
        for provider in providers.keys {
            try helper.deleteAPIKey(for: provider)
        }
    }

    @Test("List providers with keys")
    func listProviders() throws {
        let helper = KeychainHelper.shared
        let providers = ["openai", "anthropic", "google"]

        // Save keys for all providers
        for provider in providers {
            try helper.saveAPIKey("test-key", for: provider)
        }

        // List
        let listed = helper.listProvidersWithKeys()

        // Verify all present
        for provider in providers {
            #expect(listed.contains(provider))
        }

        // Cleanup
        for provider in providers {
            try helper.deleteAPIKey(for: provider)
        }
    }

    // MARK: - Has API Key Tests

    @Test("Check if API key exists")
    func hasAPIKey() throws {
        let helper = KeychainHelper.shared
        let provider = "openai"

        // Should not exist initially
        #expect(helper.hasAPIKey(for: provider) == false)

        // Save key
        try helper.saveAPIKey("test-key", for: provider)

        // Should exist now
        #expect(helper.hasAPIKey(for: provider) == true)

        // Delete
        try helper.deleteAPIKey(for: provider)

        // Should not exist anymore
        #expect(helper.hasAPIKey(for: provider) == false)
    }

    // MARK: - Delete All Tests

    @Test("Delete all API keys")
    func deleteAllAPIKeys() throws {
        let helper = KeychainHelper.shared
        let providers = ["openai", "anthropic", "google"]

        // Save keys
        for provider in providers {
            try helper.saveAPIKey("test-key", for: provider)
        }

        // Verify all exist
        for provider in providers {
            #expect(helper.hasAPIKey(for: provider) == true)
        }

        // Delete all
        try helper.deleteAllAPIKeys()

        // Verify all deleted
        for provider in providers {
            #expect(helper.hasAPIKey(for: provider) == false)
        }
    }

    // MARK: - Case Sensitivity Tests

    @Test("Provider names are case-insensitive")
    func caseInsensitiveProviderNames() throws {
        let helper = KeychainHelper.shared
        let key = "test-key-12345"

        // Save with uppercase
        try helper.saveAPIKey(key, for: "OpenAI")

        // Retrieve with lowercase
        let retrieved1 = try helper.retrieveAPIKey(for: "openai")
        #expect(retrieved1 == key)

        // Retrieve with mixed case
        let retrieved2 = try helper.retrieveAPIKey(for: "OpenAI")
        #expect(retrieved2 == key)

        // Cleanup
        try helper.deleteAPIKey(for: "openai")
    }

    // MARK: - Special Characters Tests

    @Test("Handle API keys with special characters")
    func specialCharactersInAPIKey() throws {
        let helper = KeychainHelper.shared
        let provider = "openai"
        let complexKey = "sk-test_12345-ABCDEF/ghijkl+==!"

        // Save
        try helper.saveAPIKey(complexKey, for: provider)

        // Retrieve
        let retrieved = try helper.retrieveAPIKey(for: provider)
        #expect(retrieved == complexKey)

        // Cleanup
        try helper.deleteAPIKey(for: provider)
    }
}
