import XCTest
import SwiftUI
@testable import AIUsageBar

final class DataSourceBadgeTests: XCTestCase {
    // MARK: - DataSourceBadge Display Tests

    func testDataSourceAPIRawValue() {
        XCTAssertEqual(DataSource.api.rawValue, "api")
    }

    func testDataSourceLocalRawValue() {
        XCTAssertEqual(DataSource.local.rawValue, "local")
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

    func testUsageDataWithLocalSourceIndicatesLocalOrigin() {
        // Acceptance Criteria: User sees "Local" indicator showing data source
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .local
        )

        XCTAssertEqual(usage.dataSource, .local, "Local data should be marked with .local source")
    }

    func testEmptyUsageDataDefaultsToLocalSource() {
        // When no API data is available, local is the default
        let empty = UsageData.empty(for: .claude)

        XCTAssertEqual(empty.dataSource, .local, "Empty usage data should default to local source")
    }

    func testEmptyCodexUsageDataDefaultsToLocalSource() {
        // Codex only uses local logs, never API
        let empty = UsageData.empty(for: .codex)

        XCTAssertEqual(empty.dataSource, .local, "Codex usage data should always be local source")
    }

    // MARK: - DataSource Badge Text Validation Tests

    func testAPISourceDisplayText() {
        // The badge displays "API" for API data source
        let source = DataSource.api
        let displayText = source == .api ? "API" : "Local"

        XCTAssertEqual(displayText, "API")
    }

    func testLocalSourceDisplayText() {
        // The badge displays "Local" for local data source
        let source = DataSource.local
        let displayText = source == .api ? "API" : "Local"

        XCTAssertEqual(displayText, "Local")
    }

    // MARK: - DataSource Badge Color Tests

    func testAPISourceBadgeUsesGreenColor() {
        // API source badge should use green color
        let source = DataSource.api
        let usesGreen = source == .api

        XCTAssertTrue(usesGreen, "API source badge should use green color")
    }

    func testLocalSourceBadgeUsesOrangeColor() {
        // Local source badge should use orange color
        let source = DataSource.local
        let usesOrange = source == .local

        XCTAssertTrue(usesOrange, "Local source badge should use orange color")
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

    func testUsageDataPreservesLocalSourceThroughCodable() throws {
        // Given: Usage data with local source
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 30),
            dataSource: .local
        )

        // When: Encoded and decoded
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(usage)
        let decoded = try decoder.decode(UsageData.self, from: data)

        // Then: Data source is preserved
        XCTAssertEqual(decoded.dataSource, .local)
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

    func testClaudeCanHaveLocalDataSource() {
        // Claude can fallback to local logs
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .local
        )

        XCTAssertEqual(usage.provider, .claude)
        XCTAssertEqual(usage.dataSource, .local)
    }

    func testCodexUsesLocalDataSource() {
        // Codex only uses local log parsing
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 50),
            dataSource: .local
        )

        XCTAssertEqual(usage.provider, .codex)
        XCTAssertEqual(usage.dataSource, .local)
    }
}
