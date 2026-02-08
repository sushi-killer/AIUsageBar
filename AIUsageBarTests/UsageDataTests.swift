import XCTest
import SwiftUI
@testable import AIUsageBar

final class UsageDataTests: XCTestCase {
    // MARK: - UsageStatus Tests

    func testUsageStatusFromPercentage() {
        XCTAssertEqual(UsageStatus.from(percentage: 0), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 50), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 74), .green)
        XCTAssertEqual(UsageStatus.from(percentage: 75), .yellow)
        XCTAssertEqual(UsageStatus.from(percentage: 89), .yellow)
        XCTAssertEqual(UsageStatus.from(percentage: 90), .red)
        XCTAssertEqual(UsageStatus.from(percentage: 100), .red)
    }

    func testUsageStatusColors() {
        XCTAssertNotNil(UsageStatus.green.color)
        XCTAssertNotNil(UsageStatus.yellow.color)
        XCTAssertNotNil(UsageStatus.red.color)
    }

    // MARK: - UsageWindow Tests

    func testUsageWindowCreation() {
        let window = UsageWindow(percentage: 50, resetTime: Date(), isEstimated: false)

        XCTAssertEqual(window.percentage, 50)
        XCTAssertNotNil(window.resetTime)
        XCTAssertFalse(window.isEstimated)
    }

    func testUsageWindowFormattedResetTime() {
        // Test with reset time in future
        let futureDate = Date().addingTimeInterval(3600 * 2.75) // 2h 45m
        let window = UsageWindow(percentage: 50, resetTime: futureDate)

        let formatted = window.formattedResetTime
        XCTAssertNotNil(formatted)
        // Formatter outputs "MMM d, HH:mm" style (e.g. "Feb 6, 19:30")
        XCTAssertFalse(formatted!.isEmpty)
    }

    func testUsageWindowFormattedResetTimeNil() {
        let window = UsageWindow(percentage: 50, resetTime: nil)
        XCTAssertNil(window.formattedResetTime)
    }

    func testUsageWindowEquatable() {
        let id = UUID()
        let date = Date()

        let window1 = UsageWindow(id: id, percentage: 50, resetTime: date, isEstimated: false)
        let window2 = UsageWindow(id: id, percentage: 50, resetTime: date, isEstimated: false)

        XCTAssertEqual(window1, window2)
    }

    // MARK: - UsageData Tests

    func testUsageDataCreation() {
        let primaryWindow = UsageWindow(percentage: 45)
        let secondaryWindow = UsageWindow(percentage: 70)

        let usage = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: secondaryWindow,
            tokensUsed: 100000,
            dataSource: .api
        )

        XCTAssertEqual(usage.provider, .claude)
        XCTAssertEqual(usage.primaryWindow.percentage, 45)
        XCTAssertNotNil(usage.secondaryWindow)
        XCTAssertEqual(usage.tokensUsed, 100000)
        XCTAssertEqual(usage.dataSource, .api)
    }

    func testUsageDataStatus() {
        let greenUsage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 45)
        )
        let yellowUsage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 80)
        )
        let redUsage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 95)
        )

        XCTAssertEqual(greenUsage.status, .green)
        XCTAssertEqual(yellowUsage.status, .yellow)
        XCTAssertEqual(redUsage.status, .red)
    }

    func testUsageDataDisplayPercentage() {
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 67.5)
        )

        XCTAssertEqual(usage.displayPercentage, 67.5)
    }

    func testUsageDataEmpty() {
        let empty = UsageData.empty(for: .claude)

        XCTAssertEqual(empty.provider, .claude)
        XCTAssertEqual(empty.primaryWindow.percentage, 0)
        XCTAssertNil(empty.secondaryWindow)
        XCTAssertNil(empty.tokensUsed)
        XCTAssertEqual(empty.dataSource, .local)
    }

    func testUsageDataCodable() throws {
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 45),
            secondaryWindow: UsageWindow(percentage: 70),
            tokensUsed: 50000,
            dataSource: .local
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(usage)
        let decoded = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(decoded.provider, usage.provider)
        XCTAssertEqual(decoded.primaryWindow.percentage, usage.primaryWindow.percentage)
        XCTAssertEqual(decoded.tokensUsed, usage.tokensUsed)
        XCTAssertEqual(decoded.dataSource, usage.dataSource)
    }

    // MARK: - DataSource Tests

    func testDataSourceValues() {
        XCTAssertEqual(DataSource.api.rawValue, "api")
        XCTAssertEqual(DataSource.local.rawValue, "local")
    }

    func testDataSourceCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let apiData = try encoder.encode(DataSource.api)
        let localData = try encoder.encode(DataSource.local)

        let decodedApi = try decoder.decode(DataSource.self, from: apiData)
        let decodedLocal = try decoder.decode(DataSource.self, from: localData)

        XCTAssertEqual(decodedApi, DataSource.api)
        XCTAssertEqual(decodedLocal, DataSource.local)
    }

    // MARK: - UsageStatus Codable Tests

    func testUsageStatusCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for status in [UsageStatus.green, .yellow, .red] {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(UsageStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - UsageWindow Identifiable & Codable Tests

    func testUsageWindowIdentifiable() {
        let window1 = UsageWindow(percentage: 50)
        let window2 = UsageWindow(percentage: 50)

        // Each window should have a unique ID
        XCTAssertNotEqual(window1.id, window2.id)
    }

    func testUsageWindowCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let window = UsageWindow(
            percentage: 75.5,
            resetTime: Date(),
            isEstimated: true
        )

        let data = try encoder.encode(window)
        let decoded = try decoder.decode(UsageWindow.self, from: data)

        XCTAssertEqual(decoded.id, window.id)
        XCTAssertEqual(decoded.percentage, window.percentage)
        XCTAssertEqual(decoded.isEstimated, window.isEstimated)
        XCTAssertNotNil(decoded.resetTime)
    }

    // MARK: - UsageData Identifiable & Equatable Tests

    func testUsageDataIdentifiable() {
        let usage1 = UsageData.empty(for: .claude)
        let usage2 = UsageData.empty(for: .claude)

        // Each UsageData should have a unique ID
        XCTAssertNotEqual(usage1.id, usage2.id)
    }

    func testUsageDataEquatable() {
        let id = UUID()
        let windowId = UUID()
        let date = Date()

        let window = UsageWindow(id: windowId, percentage: 50, resetTime: date, isEstimated: false)

        let usage1 = UsageData(
            id: id,
            provider: .claude,
            primaryWindow: window,
            secondaryWindow: nil,
            tokensUsed: 1000,
            dataSource: .api,
            lastUpdated: date
        )

        let usage2 = UsageData(
            id: id,
            provider: .claude,
            primaryWindow: window,
            secondaryWindow: nil,
            tokensUsed: 1000,
            dataSource: .api,
            lastUpdated: date
        )

        XCTAssertEqual(usage1, usage2)
    }
}
