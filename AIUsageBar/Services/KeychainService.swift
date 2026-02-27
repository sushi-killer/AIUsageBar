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
}
