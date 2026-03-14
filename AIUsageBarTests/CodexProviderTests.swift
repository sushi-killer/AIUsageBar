import XCTest
@testable import AIUsageBar

final class CodexProviderTests: XCTestCase {
    var provider: CodexProvider!

    override func setUp() {
        super.setUp()
        provider = CodexProvider()
    }

    override func tearDown() {
        provider = nil
        super.tearDown()
    }

    func testRateLimitWindowDateConversion() {
        // Test Unix timestamp conversion
        let timestamp = 1900000000 // well into the future
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        XCTAssertNotNil(date)
        // Verify it's a reasonable future date
        XCTAssertTrue(date > Date())
    }

    // MARK: - UsageData Construction Tests

    func testCodexUsageDataFromRateLimits() {
        // Tests building UsageData from rate_limits
        let primaryWindow = UsageWindow(
            percentage: 25.0,
            resetTime: Date(timeIntervalSince1970: 1770300000),
            isEstimated: false
        )
        let secondaryWindow = UsageWindow(
            percentage: 65.0,
            resetTime: Date(timeIntervalSince1970: 1770800000),
            isEstimated: false
        )

        let usageData = UsageData(
            provider: .codex,
            primaryWindow: primaryWindow,
            secondaryWindow: secondaryWindow,
            tokensUsed: 5000,
            dataSource: .api
        )

        XCTAssertEqual(usageData.provider, .codex)
        XCTAssertEqual(usageData.dataSource, .api)
        XCTAssertEqual(usageData.primaryWindow.percentage, 25.0)
        XCTAssertFalse(usageData.primaryWindow.isEstimated)
        XCTAssertNotNil(usageData.secondaryWindow)
        XCTAssertEqual(usageData.secondaryWindow?.percentage, 65.0)
    }

    func testCodexUsageDataFromEstimation() {
        // Tests building UsageData from token estimation (no rate_limits)
        let primaryWindow = UsageWindow(
            percentage: 40.0,
            resetTime: nil,
            isEstimated: true
        )

        let usageData = UsageData(
            provider: .codex,
            primaryWindow: primaryWindow,
            secondaryWindow: nil,
            tokensUsed: 200_000,
            dataSource: .api
        )

        XCTAssertEqual(usageData.provider, .codex)
        XCTAssertEqual(usageData.dataSource, .api)
        XCTAssertEqual(usageData.primaryWindow.percentage, 40.0)
        XCTAssertTrue(usageData.primaryWindow.isEstimated)
        XCTAssertNil(usageData.secondaryWindow)
        XCTAssertEqual(usageData.tokensUsed, 200_000)
    }

    func testCodexStatusThresholds() {
        // Tests that Codex usage status follows the same thresholds as other providers
        let testCases: [(Double, UsageStatus)] = [
            (0.0, .green),
            (50.0, .green),
            (74.9, .green),
            (75.0, .yellow),
            (85.0, .yellow),
            (89.9, .yellow),
            (90.0, .red),
            (95.0, .red),
            (100.0, .red),
        ]

        for (percentage, expectedStatus) in testCases {
            let primaryWindow = UsageWindow(
                percentage: percentage,
                resetTime: nil,
                isEstimated: false
            )
            let usageData = UsageData(
                provider: .codex,
                primaryWindow: primaryWindow,
                dataSource: .api
            )

            XCTAssertEqual(usageData.status, expectedStatus,
                          "Percentage \(percentage)% should result in \(expectedStatus) status")
        }
    }

    func testCodexPrimaryWindowLabel() {
        // Verifies Codex uses the correct window labels
        XCTAssertEqual(Provider.codex.primaryWindowLabel, "5-Hour")
        XCTAssertEqual(Provider.codex.secondaryWindowLabel, "Weekly")
    }

    func testCodexProviderColor() {
        // Verifies Codex brand color is configured
        let color = Provider.codex.color
        XCTAssertNotNil(color)
        // Green color hex: #10B981
    }

    func testCodexDisplayName() {
        XCTAssertEqual(Provider.codex.displayName, "Codex")
    }
}
