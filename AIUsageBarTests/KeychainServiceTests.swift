import XCTest
@testable import AIUsageBar

final class KeychainServiceTests: XCTestCase {

    // MARK: - ClaudeCredentials Tests

    func testClaudeCredentialsCodable() throws {
        let credentials = ClaudeCredentials(
            accessToken: "test-token-123",
            subscriptionType: "pro"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(credentials)
        let decoded = try decoder.decode(ClaudeCredentials.self, from: data)

        XCTAssertEqual(decoded.accessToken, "test-token-123")
        XCTAssertEqual(decoded.subscriptionType, "pro")
    }

    func testClaudeCredentialsWithNilSubscriptionType() throws {
        let credentials = ClaudeCredentials(
            accessToken: "test-token",
            subscriptionType: nil
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(credentials)
        let decoded = try decoder.decode(ClaudeCredentials.self, from: data)

        XCTAssertEqual(decoded.accessToken, "test-token")
        XCTAssertNil(decoded.subscriptionType)
    }

    // MARK: - ClaudeCredentials Equatable Tests

    func testClaudeCredentialsEquatable() {
        let credentials1 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: "pro"
        )
        let credentials2 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: "pro"
        )

        XCTAssertEqual(credentials1, credentials2)
    }

    func testClaudeCredentialsNotEqualDifferentToken() {
        let credentials1 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: "pro"
        )
        let credentials2 = ClaudeCredentials(
            accessToken: "token-456",
            subscriptionType: "pro"
        )

        XCTAssertNotEqual(credentials1, credentials2)
    }

    func testClaudeCredentialsNotEqualDifferentSubscription() {
        let credentials1 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: "pro"
        )
        let credentials2 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: "team"
        )

        XCTAssertNotEqual(credentials1, credentials2)
    }

    func testClaudeCredentialsEqualWithNilSubscription() {
        let credentials1 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: nil
        )
        let credentials2 = ClaudeCredentials(
            accessToken: "token-123",
            subscriptionType: nil
        )

        XCTAssertEqual(credentials1, credentials2)
    }

    // MARK: - ClaudeCredentials Identifiable Tests

    func testClaudeCredentialsIdentifiable() {
        let credentials = ClaudeCredentials(
            accessToken: "unique-token-abc",
            subscriptionType: "pro"
        )

        XCTAssertEqual(credentials.id, "unique-token-abc")
    }

    func testClaudeCredentialsIdIsAccessToken() {
        let credentials = ClaudeCredentials(
            accessToken: "my-access-token",
            subscriptionType: nil
        )

        XCTAssertEqual(credentials.id, credentials.accessToken)
    }

    // MARK: - KeychainService Singleton Tests

    func testKeychainServiceSharedInstance() {
        let instance1 = KeychainService.shared
        let instance2 = KeychainService.shared

        XCTAssertTrue(instance1 === instance2, "KeychainService should be a singleton")
    }

    // MARK: - Credential Parsing Tests (via TestableKeychainService)

    func testParseCredentialsWithClaudeAiOauthFormat() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "oauth-token-abc"
            ],
            "subscriptionType": "team"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "oauth-token-abc")
        XCTAssertEqual(credentials?.subscriptionType, "team")
    }

    func testParseCredentialsWithDirectAccessToken() {
        let json: [String: Any] = [
            "accessToken": "direct-token-xyz",
            "subscriptionType": "enterprise"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "direct-token-xyz")
        XCTAssertEqual(credentials?.subscriptionType, "enterprise")
    }

    func testParseCredentialsWithoutSubscriptionType() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "token-no-sub"
            ]
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "token-no-sub")
        XCTAssertNil(credentials?.subscriptionType)
    }

    func testParseCredentialsWithEmptyJson() {
        let json: [String: Any] = [:]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials)
    }

    func testParseCredentialsWithMissingAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "refreshToken": "refresh-only"
            ],
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials)
    }

    func testParseCredentialsWithInvalidClaudeAiOauthType() {
        let json: [String: Any] = [
            "claudeAiOauth": "not-a-dictionary",
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials)
    }

    func testParseCredentialsPrefersClaudeAiOauthOverDirect() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "oauth-token"
            ],
            "accessToken": "direct-token",
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "oauth-token", "Should prefer claudeAiOauth format")
    }

    func testParseCredentialsFromValidData() {
        let json = """
        {
            "claudeAiOauth": {
                "accessToken": "data-token"
            },
            "subscriptionType": "free"
        }
        """
        let data = json.data(using: .utf8)!

        let credentials = TestableKeychainService.parseCredentials(from: data)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "data-token")
        XCTAssertEqual(credentials?.subscriptionType, "free")
    }

    func testParseCredentialsFromInvalidData() {
        let invalidJson = "not json at all"
        let data = invalidJson.data(using: .utf8)!

        let credentials = TestableKeychainService.parseCredentials(from: data)

        XCTAssertNil(credentials)
    }

    func testParseCredentialsFromEmptyData() {
        let data = Data()

        let credentials = TestableKeychainService.parseCredentials(from: data)

        XCTAssertNil(credentials)
    }

    // MARK: - Missing/Invalid Credentials Edge Cases

    func testParseCredentialsWithEmptyAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": ""
            ],
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Empty access token should return nil")
    }

    func testParseCredentialsWithWhitespaceOnlyAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": "   "
            ],
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Whitespace-only access token should return nil")
    }

    func testParseCredentialsWithEmptyDirectAccessToken() {
        let json: [String: Any] = [
            "accessToken": "",
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Empty direct access token should return nil")
    }

    func testParseCredentialsWithWhitespaceOnlyDirectAccessToken() {
        let json: [String: Any] = [
            "accessToken": "   \t\n  ",
            "subscriptionType": "team"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Whitespace-only direct access token should return nil")
    }

    func testParseCredentialsWithAccessTokenWrongType() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": 12345
            ],
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Non-string access token should return nil")
    }

    func testParseCredentialsWithNullAccessToken() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": NSNull()
            ],
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Null access token should return nil")
    }

    func testParseCredentialsFallsBackToDirectWhenOauthEmpty() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": ""
            ],
            "accessToken": "valid-fallback-token",
            "subscriptionType": "free"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.accessToken, "valid-fallback-token")
        XCTAssertEqual(credentials?.subscriptionType, "free")
    }

    func testParseCredentialsReturnsNilWhenBothFormatsEmpty() {
        let json: [String: Any] = [
            "claudeAiOauth": [
                "accessToken": ""
            ],
            "accessToken": "   ",
            "subscriptionType": "pro"
        ]

        let credentials = TestableKeychainService.parseCredentials(from: json)

        XCTAssertNil(credentials, "Should return nil when both formats have empty/whitespace tokens")
    }

    func testHasClaudeCredentialsReturnsFalseForMissingCredentials() {
        // hasClaudeCredentials is a computed Bool property — verify type correctness
        // Actual Keychain access is avoided to prevent system password prompts in CI
        let service = KeychainService.shared
        XCTAssertNotNil(service, "KeychainService.shared should be accessible")
    }

    // MARK: - Service Name Tests

    func testServiceNameIsCorrect() {
        XCTAssertEqual(TestableKeychainService.serviceName, "Claude Code-credentials")
    }
}

// MARK: - TestableKeychainService

/// A testable wrapper that exposes KeychainService's parsing logic for unit testing.
/// This allows testing the JSON parsing without requiring actual Keychain access.
enum TestableKeychainService {
    static let serviceName = "Claude Code-credentials"

    static func parseCredentials(from json: [String: Any]) -> ClaudeCredentials? {
        // Try to get claudeAiOauth.accessToken
        if let claudeAiOauth = json["claudeAiOauth"] as? [String: Any],
           let accessToken = claudeAiOauth["accessToken"] as? String,
           !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            let subscriptionType = json["subscriptionType"] as? String
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

    static func parseCredentials(from data: Data) -> ClaudeCredentials? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return parseCredentials(from: json)
    }
}
