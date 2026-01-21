import Foundation
import Security

/// Helper for securely storing and retrieving API keys in the Keychain
/// Used for third-party AI provider authentication (OpenAI, etc.)
///
/// Note: Apple Intelligence doesn't require API keys (uses device authentication)
class KeychainHelper {

    // MARK: - Singleton

    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Service Identifier

    /// Service identifier for Cumberland app in Keychain
    private let service = "com.cumberland.ai.apikeys"

    // MARK: - Save API Key

    /// Save an API key to the Keychain
    /// - Parameters:
    ///   - key: The API key to store
    ///   - provider: Provider name (e.g., "openai", "anthropic")
    /// - Throws: KeychainError if save fails
    func saveAPIKey(_ key: String, for provider: String) throws {
        guard !key.isEmpty else {
            throw KeychainError.invalidInput
        }

        let account = accountName(for: provider)
        let data = key.data(using: .utf8)!

        // Check if key already exists
        if (try? retrieveAPIKey(for: provider)) != nil {
            // Update existing key
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            guard status == errSecSuccess else {
                throw KeychainError.updateFailed(status: status)
            }
        } else {
            // Add new key
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
            ]

            let status = SecItemAdd(query as CFDictionary, nil)

            guard status == errSecSuccess else {
                throw KeychainError.saveFailed(status: status)
            }
        }

        #if DEBUG
        print("✓ [KeychainHelper] Saved API key for provider: \(provider)")
        #endif
    }

    // MARK: - Retrieve API Key

    /// Retrieve an API key from the Keychain
    /// - Parameter provider: Provider name (e.g., "openai", "anthropic")
    /// - Returns: The API key, or nil if not found
    /// - Throws: KeychainError if retrieval fails (other than not found)
    func retrieveAPIKey(for provider: String) throws -> String? {
        let account = accountName(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainError.retrievalFailed(status: status)
        }

        guard let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return key
    }

    // MARK: - Delete API Key

    /// Delete an API key from the Keychain
    /// - Parameter provider: Provider name
    /// - Throws: KeychainError if deletion fails
    func deleteAPIKey(for provider: String) throws {
        let account = accountName(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status: status)
        }

        #if DEBUG
        print("✓ [KeychainHelper] Deleted API key for provider: \(provider)")
        #endif
    }

    // MARK: - Check Existence

    /// Check if an API key exists for a provider
    /// - Parameter provider: Provider name
    /// - Returns: True if key exists, false otherwise
    func hasAPIKey(for provider: String) -> Bool {
        (try? retrieveAPIKey(for: provider)) != nil
    }

    // MARK: - List Providers

    /// List all providers that have stored API keys
    /// - Returns: Array of provider names
    func listProvidersWithKeys() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item in
            guard let account = item[kSecAttrAccount as String] as? String else {
                return nil
            }
            return providerName(from: account)
        }
    }

    // MARK: - Delete All

    /// Delete all API keys (use with caution!)
    /// - Throws: KeychainError if deletion fails
    func deleteAllAPIKeys() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status: status)
        }

        #if DEBUG
        print("⚠️ [KeychainHelper] Deleted all API keys")
        #endif
    }

    // MARK: - Private Helpers

    /// Convert provider name to Keychain account name
    private func accountName(for provider: String) -> String {
        "apikey_\(provider.lowercased())"
    }

    /// Convert Keychain account name back to provider name
    private func providerName(from account: String) -> String? {
        guard account.hasPrefix("apikey_") else {
            return nil
        }
        return String(account.dropFirst("apikey_".count))
    }
}

// MARK: - Keychain Errors

enum KeychainError: LocalizedError {
    case invalidInput
    case saveFailed(status: OSStatus)
    case updateFailed(status: OSStatus)
    case retrievalFailed(status: OSStatus)
    case deletionFailed(status: OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input: API key cannot be empty"

        case .saveFailed(let status):
            return "Failed to save API key to Keychain (status: \(status))"

        case .updateFailed(let status):
            return "Failed to update API key in Keychain (status: \(status))"

        case .retrievalFailed(let status):
            return "Failed to retrieve API key from Keychain (status: \(status))"

        case .deletionFailed(let status):
            return "Failed to delete API key from Keychain (status: \(status))"

        case .invalidData:
            return "Invalid data retrieved from Keychain"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Please provide a valid API key"

        case .saveFailed, .updateFailed, .deletionFailed:
            return "Check Keychain access permissions and try again"

        case .retrievalFailed:
            return "The API key may have been deleted or corrupted"

        case .invalidData:
            return "Try deleting and re-adding the API key"
        }
    }
}

// MARK: - Convenience Extensions

extension KeychainHelper {
    /// Common provider identifiers
    enum Provider {
        static let openAI = "openai"
        static let anthropic = "anthropic"
        static let google = "google"
        static let cohere = "cohere"

        /// All known providers
        static let all = [openAI, anthropic, google, cohere]
    }
}

// MARK: - Testing Helpers

#if DEBUG
extension KeychainHelper {
    /// Clear all keys for testing (Debug only)
    func clearAllForTesting() {
        try? deleteAllAPIKeys()
    }

    /// Add test key (Debug only)
    func addTestKey(for provider: String, value: String = "test-key-12345") {
        try? saveAPIKey(value, for: provider)
    }
}
#endif
