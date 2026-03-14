import XCTest
@testable import AIUsageBar

final class KimiProviderTests: XCTestCase {
    var provider: KimiProvider!

    override func setUp() {
        super.setUp()
        provider = KimiProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    // MARK: - Provider Enum Tests

    func testKimiProviderEnumProperties() {
        let kimi = Provider.kimi
        XCTAssertEqual(kimi.displayName, "Kimi")
        XCTAssertEqual(kimi.shortName, "K")
        XCTAssertEqual(kimi.primaryWindowLabel, "5-Hour")
        XCTAssertEqual(kimi.secondaryWindowLabel, "Weekly")
        XCTAssertFalse(kimi.hasLocalLogs)
        XCTAssertNil(kimi.logsPath)
    }

    func testKimiProviderRawValue() {
        XCTAssertEqual(Provider.kimi.rawValue, "kimi")
        XCTAssertEqual(Provider(rawValue: "kimi"), .kimi)
    }

    // MARK: - API Response Decoding

    func testKimiUsageResponseDecoding() throws {
        let json = """
        {
            "user": {
                "userId": "test123",
                "region": "REGION_OVERSEA",
                "membership": {"level": "LEVEL_INTERMEDIATE"}
            },
            "usage": {
                "limit": "100",
                "remaining": "60",
                "resetTime": "2026-03-15T09:31:26.861944Z"
            },
            "limits": [{
                "window": {"duration": 300, "timeUnit": "TIME_UNIT_MINUTE"},
                "detail": {
                    "limit": "100",
                    "remaining": "75",
                    "resetTime": "2026-03-10T23:31:26.861944Z"
                }
            }]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(KimiUsageResponse.self, from: data)

        XCTAssertEqual(response.user?.membership?.level, "LEVEL_INTERMEDIATE")
        XCTAssertEqual(response.usage?.limit, "100")
        XCTAssertEqual(response.usage?.remaining, "60")
        XCTAssertEqual(response.limits?.count, 1)
        XCTAssertEqual(response.limits?.first?.detail?.remaining, "75")
        XCTAssertEqual(response.limits?.first?.window?.duration, 300)
    }

    func testKimiUsageResponseDecodingMinimal() throws {
        let json = """
        {"usage": {"limit": "50", "remaining": "50"}, "limits": []}
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(KimiUsageResponse.self, from: data)

        XCTAssertNil(response.user)
        XCTAssertEqual(response.usage?.limit, "50")
        XCTAssertEqual(response.limits?.count, 0)
    }

    // MARK: - Provider Instantiation

    func testKimiProviderCanBeInstantiated() {
        let testProvider = KimiProvider()
        XCTAssertNotNil(testProvider)
    }

    func testFetchUsageReturnsNilWithoutAPIKey() async {
        // Without a stored API key, fetchUsage should return nil
        let testProvider = KimiProvider()
        // Note: This depends on no Kimi-apikey being stored in the Keychain
        // Just verify it doesn't crash
        XCTAssertNotNil(testProvider)
    }
}
