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
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 30

    private init() {}

    func getClaudeCredentials() -> ClaudeCredentials? {
        // Return cached credentials if still fresh
        if let cached = cachedCredentials,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTTL {
            return cached
        }

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
            cacheTimestamp = Date()
            return nil
        }

        let credentials = parseCredentials(from: data)
        cachedCredentials = credentials
        cacheTimestamp = Date()
        return credentials
    }

    func invalidateCache() {
        cachedCredentials = nil
        cacheTimestamp = nil
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
}
