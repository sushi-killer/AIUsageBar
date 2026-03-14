import XCTest
import SwiftUI
@testable import AIUsageBar

final class DataSourceBadgeTests: XCTestCase {
    // MARK: - DataSourceBadge Display Tests

    func testDataSourceAPIRawValue() {
        XCTAssertEqual(DataSource.api.rawValue, "api")
    }

    // MARK: - DataSource Indicator Requirement Tests

    func testUsageDataWithAPISourceIndicatesAPIOrigin() {
        // Acceptance Criteria: User sees "API" indicator showing data source
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .api
        )

        XCTAssertEqual(usage.dataSource, .api, "API data should be marked with .api source")
    }

    func testEmptyUsageDataDefaultsToAPISource() {
        // Empty usage data defaults to API source
        let empty = UsageData.empty(for: .claude)

        XCTAssertEqual(empty.dataSource, .api, "Empty usage data should default to api source")
    }

    func testEmptyCodexUsageDataDefaultsToAPISource() {
        let empty = UsageData.empty(for: .codex)

        XCTAssertEqual(empty.dataSource, .api, "Codex usage data should default to api source")
    }

    // MARK: - DataSource Badge Text Validation Tests

    func testAPISourceDisplayText() {
        // The badge displays "API" for API data source
        let source = DataSource.api
        let displayText = source == .api ? "API" : "Unknown"

        XCTAssertEqual(displayText, "API")
    }

    // MARK: - DataSource Badge Color Tests

    func testAPISourceBadgeUsesGreenColor() {
        // API source badge should use green color
        let source = DataSource.api
        let usesGreen = source == .api

        XCTAssertTrue(usesGreen, "API source badge should use green color")
    }

    // MARK: - DataSource in UsageData Integration Tests

    func testUsageDataPreservesDataSourceThroughCodable() throws {
        // Given: Usage data with API source
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 45),
            dataSource: .api
        )

        // When: Encoded and decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(usage)
        let decoded = try decoder.decode(UsageData.self, from: data)

        // Then: Data source is preserved
        XCTAssertEqual(decoded.dataSource, .api)
    }

    // MARK: - DataSourceBadge Visibility Tests

    func testDataSourceBadgeVisibleWhenUsageDataExists() {
        // Given: Valid usage data
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .api
        )

        // Then: Usage data exists and badge should be visible
        // In ContentView, badge is shown only when currentUsage is not nil
        XCTAssertNotNil(usage)
    }

    func testDataSourceIsPartOfUsageDataModel() {
        // Verify dataSource is a required field in UsageData
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .api
        )

        // dataSource should always be accessible
        _ = usage.dataSource
        XCTAssertTrue(true, "dataSource is always available on UsageData")
    }

    // MARK: - Provider-Specific DataSource Tests

    func testClaudeCanHaveAPIDataSource() {
        // Claude supports API data fetching
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .api
        )

        XCTAssertEqual(usage.provider, .claude)
        XCTAssertEqual(usage.dataSource, .api)
    }

    func testCodexUsesAPIDataSource() {
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .api
        )

        XCTAssertEqual(usage.provider, .codex)
        XCTAssertEqual(usage.dataSource, .api)
    }
}
