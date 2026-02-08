import XCTest
@testable import AIUsageBar

/// Tests for PRD requirement US-004:
/// "User sees usage percentage update within 5 seconds of API response"
final class UpdateTimingTests: XCTestCase {

    // MARK: - UpdateTiming Configuration Tests

    func testMaxUIUpdateDelayIsConfigured() {
        // Verify the maximum UI update delay constant is defined
        XCTAssertEqual(UpdateTiming.maxUIUpdateDelay, 5.0,
                      "Maximum UI update delay should be 5 seconds per PRD requirement")
    }

    func testMaxUIUpdateDelayIsReasonable() {
        // The max delay should be positive and not too large
        XCTAssertGreaterThan(UpdateTiming.maxUIUpdateDelay, 0,
                            "Max UI update delay must be positive")
        XCTAssertLessThanOrEqual(UpdateTiming.maxUIUpdateDelay, 10.0,
                                 "Max UI update delay should not exceed 10 seconds for good UX")
    }

    func testExpectedSynchronousDelayIsMinimal() {
        // SwiftUI updates should be near-instantaneous
        XCTAssertLessThan(UpdateTiming.expectedSynchronousDelay, 1.0,
                         "Expected synchronous delay should be under 1 second")
        XCTAssertLessThan(UpdateTiming.expectedSynchronousDelay, UpdateTiming.maxUIUpdateDelay,
                         "Expected delay should be less than maximum allowed delay")
    }

    // MARK: - UsageData Timestamp Tests

    func testUsageDataHasLastUpdatedTimestamp() {
        // UsageData should track when it was last updated for freshness verification
        let primaryWindow = UsageWindow(percentage: 50.0)
        let beforeCreation = Date()

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api
        )

        let afterCreation = Date()

        // lastUpdated should be set to creation time
        XCTAssertGreaterThanOrEqual(usageData.lastUpdated, beforeCreation,
                                    "lastUpdated should be >= creation start time")
        XCTAssertLessThanOrEqual(usageData.lastUpdated, afterCreation,
                                 "lastUpdated should be <= creation end time")
    }

    func testUsageDataLastUpdatedCanBeCustomized() {
        // UsageData should allow custom lastUpdated for testing and special cases
        let customDate = Date(timeIntervalSince1970: 1700000000)
        let primaryWindow = UsageWindow(percentage: 50.0)

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api,
            lastUpdated: customDate
        )

        XCTAssertEqual(usageData.lastUpdated, customDate,
                      "lastUpdated should match provided custom date")
    }

    func testUsageDataDefaultLastUpdatedIsNow() {
        // Default lastUpdated should be the current time
        let now = Date()
        let primaryWindow = UsageWindow(percentage: 50.0)

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api
        )

        // Allow 1 second tolerance for test execution
        let timeDifference = abs(usageData.lastUpdated.timeIntervalSince(now))
        XCTAssertLessThan(timeDifference, 1.0,
                         "Default lastUpdated should be within 1 second of current time")
    }

    // MARK: - Update Architecture Tests

    func testAPIDataSourceIsMarkedCorrectly() {
        // Data from API should be marked as such for UI display
        let primaryWindow = UsageWindow(percentage: 45.0)

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api
        )

        XCTAssertEqual(usageData.dataSource, .api,
                      "API data should have .api data source")
    }

    func testLocalDataSourceIsMarkedCorrectly() {
        // Data from local logs should be marked as such
        let primaryWindow = UsageWindow(percentage: 45.0, isEstimated: true)

        let usageData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            tokensUsed: 450000,
            dataSource: .local
        )

        XCTAssertEqual(usageData.dataSource, .local,
                      "Local data should have .local data source")
    }

    // MARK: - Data Freshness Tests

    func testCanDetermineFreshnessFromLastUpdated() {
        // The lastUpdated timestamp allows determining if data is fresh
        let staleDate = Date().addingTimeInterval(-UpdateTiming.maxUIUpdateDelay - 1)
        let freshDate = Date()

        let primaryWindow = UsageWindow(percentage: 50.0)

        let staleData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api,
            lastUpdated: staleDate
        )

        let freshData = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api,
            lastUpdated: freshDate
        )

        // Calculate staleness
        let staleAge = Date().timeIntervalSince(staleData.lastUpdated)
        let freshAge = Date().timeIntervalSince(freshData.lastUpdated)

        XCTAssertGreaterThan(staleAge, UpdateTiming.maxUIUpdateDelay,
                            "Stale data should be older than max update delay")
        XCTAssertLessThan(freshAge, UpdateTiming.maxUIUpdateDelay,
                         "Fresh data should be newer than max update delay")
    }

    func testTimestampPersistsThroughEncoding() throws {
        // lastUpdated should survive encode/decode cycle
        let customDate = Date(timeIntervalSince1970: 1700000000)
        let primaryWindow = UsageWindow(percentage: 50.0)

        let original = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            dataSource: .api,
            lastUpdated: customDate
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UsageData.self, from: data)

        XCTAssertEqual(decoded.lastUpdated, original.lastUpdated,
                      "lastUpdated should survive JSON encoding/decoding")
    }

    // MARK: - SwiftUI Reactive Architecture Tests

    func testUsageWindowIsEquatableForSwiftUIUpdates() {
        // SwiftUI relies on Equatable to determine if views need updating
        let window1 = UsageWindow(percentage: 50.0)
        let window2 = UsageWindow(percentage: 50.0)
        let window3 = UsageWindow(percentage: 75.0)

        // Windows with same values but different IDs should not be equal
        // This ensures UI always updates when new data arrives
        XCTAssertNotEqual(window1, window2,
                         "Windows with different IDs should not be equal")
        XCTAssertNotEqual(window1, window3,
                         "Windows with different percentages should not be equal")
    }

    func testUsageDataIsEquatableForSwiftUIUpdates() {
        // SwiftUI uses Equatable to optimize rendering
        let primaryWindow1 = UsageWindow(percentage: 50.0)
        let primaryWindow2 = UsageWindow(percentage: 50.0)

        let data1 = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow1,
            dataSource: .api
        )

        let data2 = UsageData(
            provider: .claude,
            primaryWindow: primaryWindow2,
            dataSource: .api
        )

        // Different instances should not be equal (different IDs)
        // This ensures UI always updates when new data is assigned
        XCTAssertNotEqual(data1, data2,
                         "Different UsageData instances should not be equal")
    }

    func testNewUsageDataCreatedOnEachAPIResponse() async throws {
        // Each API response should create a new UsageData instance
        // This ensures @Published triggers UI updates

        let json = """
        {
            "five_hour": {
                "utilization": 0.45,
                "resets_at": "2024-01-15T15:00:00.000Z"
            },
            "seven_day": {
                "utilization": 0.72,
                "resets_at": "2024-01-20T00:00:00.000Z"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

        let provider = ClaudeProvider()
        let usageData1 = await provider.convertAPIResponse(apiResponse)
        let usageData2 = await provider.convertAPIResponse(apiResponse)

        // Each conversion should create a new instance with a new ID
        XCTAssertNotEqual(usageData1.id, usageData2.id,
                         "Each API response conversion should create a new UsageData instance")
    }

    // MARK: - Update Timing Contract Tests

    func testUpdateTimingRequirementDocumented() {
        // The 5-second requirement should be documented in code
        // This test ensures the constant exists and is accessible

        let maxDelay = UpdateTiming.maxUIUpdateDelay

        // Document the requirement in the test itself
        // PRD US-004: "User sees usage percentage update within 5 seconds of API response"
        XCTAssertEqual(maxDelay, 5.0,
                      """
                      PRD Requirement US-004:
                      User sees usage percentage update within 5 seconds of API response.

                      This is achieved through:
                      1. UsageManager updates @Published properties synchronously after API fetch
                      2. SwiftUI automatically re-renders when @Published properties change
                      3. The update delay is bounded by network latency, not app code

                      The 5-second requirement is a maximum acceptable delay, not a polling interval.
                      """)
    }

    // MARK: - File Watcher Timing Tests (PRD US-006)

    func testMaxFileWatcherUpdateDelayIsConfigured() {
        // PRD US-006: "User sees usage update within 2 seconds of new log entry"
        XCTAssertEqual(UpdateTiming.maxFileWatcherUpdateDelay, 2.0,
                      "Maximum file watcher update delay should be 2 seconds per PRD US-006")
    }

    func testFileWatcherDelayIsLessThanAPIDelay() {
        // File-based updates should be faster than API-based updates
        XCTAssertLessThan(UpdateTiming.maxFileWatcherUpdateDelay, UpdateTiming.maxUIUpdateDelay,
                         "File watcher delay should be faster than API update delay")
    }

    func testFSEventsLatencyIsConfigured() {
        // FSEvents latency controls OS-level event coalescing
        XCTAssertEqual(UpdateTiming.fsEventsLatency, 0.5,
                      "FSEvents latency should be 0.5 seconds")
    }

    func testFileWatcherDebounceIsConfigured() {
        // App-level debounce prevents excessive refresh calls
        XCTAssertEqual(UpdateTiming.fileWatcherDebounce, 0.5,
                      "File watcher debounce should be 0.5 seconds")
    }

    func testTotalFileWatcherDelayMeetsRequirement() {
        // Total debounce delay = FSEvents latency + app debounce
        // Must leave room for processing time within 2-second requirement
        let totalDebounce = UpdateTiming.fsEventsLatency + UpdateTiming.fileWatcherDebounce
        let processingBuffer: TimeInterval = 0.5

        XCTAssertLessThanOrEqual(
            totalDebounce + processingBuffer,
            UpdateTiming.maxFileWatcherUpdateDelay,
            """
            PRD Requirement US-006:
            User sees usage update within 2 seconds of new log entry.

            Breakdown:
            - FSEvents latency: \(UpdateTiming.fsEventsLatency)s (OS-level coalescing)
            - App debounce: \(UpdateTiming.fileWatcherDebounce)s (prevents rapid refreshes)
            - Processing buffer: \(processingBuffer)s (file read + UI update)
            - Total: \(totalDebounce + processingBuffer)s (must be <= \(UpdateTiming.maxFileWatcherUpdateDelay)s)
            """
        )
    }

    func testFileWatcherTimingConstantsArePositive() {
        // All timing constants should be positive
        XCTAssertGreaterThan(UpdateTiming.maxFileWatcherUpdateDelay, 0)
        XCTAssertGreaterThan(UpdateTiming.fsEventsLatency, 0)
        XCTAssertGreaterThan(UpdateTiming.fileWatcherDebounce, 0)
    }

    func testFileWatcherTimingConstantsAreReasonable() {
        // Timing constants should not be too small (causes excessive CPU)
        // or too large (causes poor UX)
        XCTAssertGreaterThanOrEqual(UpdateTiming.fsEventsLatency, 0.1,
            "FSEvents latency should be at least 0.1s to avoid excessive callbacks")
        XCTAssertGreaterThanOrEqual(UpdateTiming.fileWatcherDebounce, 0.1,
            "Debounce should be at least 0.1s to avoid excessive refreshes")
        XCTAssertLessThanOrEqual(UpdateTiming.maxFileWatcherUpdateDelay, 5.0,
            "Max delay should not exceed 5 seconds for acceptable UX")
    }
}
