import Foundation
import Security

struct ClaudeCredentials: Codable, Equatable, Identifiable {
    let accessToken: String
    let subscriptionType: String?

    var id: String { accessToken }
}

@MainActor
final class KeychainService {
    static let shared = KeychainService()
    private let serviceName = "Claude Code-credentials"

    private var cachedCredentials: ClaudeCredentials?
    private var hasFetchedOnce = false

    private init() {}

    func getClaudeCredentials() -> ClaudeCredentials? {
        // Return cached credentials if we've already read from Keychain
        if hasFetchedOnce {
            return cachedCredentials
        }

        return fetchFromKeychain()
    }

    func invalidateCache() {
        cachedCredentials = nil
        hasFetchedOnce = false
    }

    private func fetchFromKeychain() -> ClaudeCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            cachedCredentials = nil
            hasFetchedOnce = true
            return nil
        }

        let credentials = parseCredentials(from: data)
        cachedCredentials = credentials
        hasFetchedOnce = true
        return credentials
    }

    private func parseCredentials(from data: Data) -> ClaudeCredentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try to get claudeAiOauth.accessToken
        if let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
           let accessToken = claudeAiOauth["accessToken"] as? String,
           !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            let subscriptionType = claudeAiOauth["subscriptionType"] as? String
                ?? json["subscriptionType"] as? String
            return ClaudeCredentials(accessToken: accessToken, subscriptionType: subscriptionType)
        }

        // Fallback: try direct accessToken field
        if let accessToken = json["accessToken"] as? String,
           !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            let subscriptionType = json["subscriptionType"] as? String
            return ClaudeCredentials(accessToken: accessToken, subscriptionType: subscriptionType)
        }

        return nil
    }

    var hasClaudeCredentials: Bool {
        getClaudeCredentials() != nil
    }

    // MARK: - Generic API Key Storage

    /// Cache: service name → key (read once from Keychain, then served from memory)
    private var apiKeyCache: [String: String] = [:]
    private var apiKeyFetchedOnce: Set<String> = []

    func storeAPIKey(_ key: String, forService service: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        if key.isEmpty {
            apiKeyCache.removeValue(forKey: service)
            apiKeyFetchedOnce.insert(service)
            return
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecValueData as String: Data(key.utf8)
        ]
        SecItemAdd(addQuery as CFDictionary, nil)

        // Update cache so subsequent reads skip Keychain
        apiKeyCache[service] = key
        apiKeyFetchedOnce.insert(service)
    }

    func getAPIKey(forService service: String) -> String? {
        if apiKeyFetchedOnce.contains(service) {
            return apiKeyCache[service]
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        apiKeyFetchedOnce.insert(service)
        if status == errSecSuccess, let data = result as? Data, let key = String(data: data, encoding: .utf8) {
            apiKeyCache[service] = key
            return key
        }
        return nil
    }

    func deleteAPIKey(forService service: String) {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        apiKeyCache.removeValue(forKey: service)
        apiKeyFetchedOnce.insert(service)
    }
}
