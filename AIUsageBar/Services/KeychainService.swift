import Foundation
import Security

struct ClaudeCredentials: Codable, Equatable, Identifiable {
    let accessToken: String
    let subscriptionType: String?
    let refreshToken: String?
    /// Token expiry as epoch milliseconds (matches Keychain JSON format)
    let expiresAt: Int64?

    init(accessToken: String, subscriptionType: String?, refreshToken: String? = nil, expiresAt: Int64? = nil) {
        self.accessToken = accessToken
        self.subscriptionType = subscriptionType
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    var id: String { accessToken }

    /// Whether the access token has expired (with 30s grace to avoid edge-case failures)
    var isExpired: Bool {
        guard let expiresAt else { return false }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        return nowMs >= expiresAt - 30_000
    }

    /// Whether the token will expire within the given interval
    func expiresWithin(_ seconds: TimeInterval) -> Bool {
        guard let expiresAt else { return false }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let thresholdMs = Int64(seconds * 1000)
        return expiresAt - nowMs < thresholdMs
    }
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

    /// Update cached credentials after a successful token refresh (no Keychain write)
    func updateCachedCredentials(_ credentials: ClaudeCredentials) {
        cachedCredentials = credentials
        hasFetchedOnce = true
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
            if status == errSecAuthFailed || status == errSecUserCanceled {
                // User denied Keychain access — cache the denial to avoid repeated prompts
                hasFetchedOnce = true
            } else {
                // Item not found or other transient error — retry on next tick
                // (e.g., user logs into Claude Code after app launch)
                hasFetchedOnce = false
            }
            return nil
        }

        let credentials = parseCredentials(from: data)
        if credentials != nil {
            cachedCredentials = credentials
            hasFetchedOnce = true
        }
        return credentials
    }

    private func parseCredentials(from data: Data) -> ClaudeCredentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Claude Code wraps credentials under "claudeAiOauth"; fall back to top-level
        let oauthJson = json["claudeAiOauth"] as? [String: Any]
        // Try oauthJson first, then fall back to top-level json
        let sourceJson = oauthJson ?? json

        // Accept both camelCase and snake_case (Claude Code uses both)
        var accessToken = sourceJson["accessToken"] as? String
            ?? sourceJson["access_token"] as? String

        // If claudeAiOauth had empty/missing token, try direct top-level fallback
        if let token = accessToken, token.trimmingCharacters(in: .whitespaces).isEmpty {
            accessToken = nil
        }
        if accessToken == nil, oauthJson != nil {
            accessToken = json["accessToken"] as? String ?? json["access_token"] as? String
            if let token = accessToken, token.trimmingCharacters(in: .whitespaces).isEmpty {
                accessToken = nil
            }
        }

        guard let validToken = accessToken else { return nil }

        let subscriptionType = sourceJson["subscriptionType"] as? String
            ?? json["subscriptionType"] as? String
        let refreshToken = sourceJson["refreshToken"] as? String
            ?? sourceJson["refresh_token"] as? String
        let expiresAt = sourceJson["expiresAt"] as? Int64
            ?? sourceJson["expires_at"] as? Int64

        return ClaudeCredentials(
            accessToken: validToken,
            subscriptionType: subscriptionType,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
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
