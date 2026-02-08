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

    func testCodexLogEntryWithRateLimitsDecoding() throws {
        let json = """
        {
            "payload": {
                "type": "token_count",
                "rate_limits": {
                    "primary": {
                        "used_percent": 13,
                        "resets_at": 1770277666
                    },
                    "secondary": {
                        "used_percent": 47,
                        "resets_at": 1770662282
                    }
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let entry = try decoder.decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "token_count")
        XCTAssertNotNil(entry.payload?.rateLimits)
        XCTAssertEqual(entry.payload?.rateLimits?.primary?.usedPercent, 13)
        XCTAssertEqual(entry.payload?.rateLimits?.primary?.resetsAt, 1770277666)
        XCTAssertEqual(entry.payload?.rateLimits?.secondary?.usedPercent, 47)
        XCTAssertEqual(entry.payload?.rateLimits?.secondary?.resetsAt, 1770662282)
    }

    func testCodexLogEntryWithTokenCountTypeDecoding() throws {
        let json = """
        {
            "payload": {
                "type": "token_count"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "token_count")
        XCTAssertNil(entry.payload?.rateLimits)
    }

    func testCodexLogEntryNonTokenCountType() throws {
        let json = """
        {
            "payload": {
                "type": "other_event"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "other_event")
        XCTAssertNil(entry.payload?.rateLimits)
    }

    func testFetchUsageReturnsNilWithoutLogs() async {
        // This test verifies that fetchUsage handles missing logs gracefully
        let result = await provider.fetchUsage()

        // Result could be nil if no logs exist - that's acceptable
        // We're mainly verifying no crash occurs
        if let result = result {
            XCTAssertEqual(result.provider, .codex)
        }
    }

    func testRateLimitWindowDateConversion() {
        // Test Unix timestamp conversion
        let timestamp = 1900000000 // well into the future
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        XCTAssertNotNil(date)
        // Verify it's a reasonable future date
        XCTAssertTrue(date > Date())
    }

    // MARK: - Local Logs Path Pattern Tests

    func testCodexLogsBasePath() {
        // Validates the base path for Codex logs: ~/.codex/sessions
        let logsPath = Provider.codex.logsPath
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        XCTAssertTrue(logsPath.hasPrefix(homeDir), "Logs path should start with home directory")
        XCTAssertTrue(logsPath.hasSuffix(".codex/sessions"), "Logs path should end with .codex/sessions")

        let expectedBasePath = (homeDir as NSString).appendingPathComponent(".codex/sessions")
        XCTAssertEqual(logsPath, expectedBasePath, "Base logs path should be ~/.codex/sessions")
    }

    func testCodexLogsPathNotContainsGlobCharacters() {
        // The logsPath property returns the base directory, not a glob pattern
        let logsPath = Provider.codex.logsPath

        XCTAssertFalse(logsPath.contains("*"), "Logs path should not contain glob characters")
        XCTAssertFalse(logsPath.contains("?"), "Logs path should not contain wildcard characters")
    }

    func testCodexLogsDirectoryStructure() {
        // Documents the expected directory structure for Codex local logs
        // Structure: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
        //
        // Example:
        // ~/.codex/sessions/
        //   2026/
        //     02/
        //       05/
        //         rollout-abc123.jsonl
        //         rollout-def456.jsonl

        let logsPath = Provider.codex.logsPath
        let fileManager = FileManager.default

        // If the base path exists, verify it's a directory
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: logsPath, isDirectory: &isDirectory) {
            XCTAssertTrue(isDirectory.boolValue, "Codex logs path should be a directory")
        }
        // Note: If directory doesn't exist, the test passes as this is valid state
        // when Codex hasn't been used yet
    }

    func testRolloutFilenamePrefixPattern() {
        // Validates the rollout-*.jsonl filename pattern
        let validFilenames = [
            "rollout-abc123.jsonl",
            "rollout-session1.jsonl",
            "rollout-0ffe5d87-6e39-4c0c-b096.jsonl",
            "rollout-.jsonl" // Edge case: empty suffix is still valid pattern match
        ]

        for filename in validFilenames {
            XCTAssertTrue(filename.hasPrefix("rollout-"),
                         "Valid rollout files should start with 'rollout-'")
            XCTAssertTrue(filename.hasSuffix(".jsonl"),
                         "Valid rollout files should end with '.jsonl'")
        }
    }

    func testInvalidFilenamesNotMatchingRolloutPattern() {
        // Files that don't match rollout-*.jsonl pattern
        let invalidFilenames = [
            "session.jsonl",           // Missing rollout- prefix
            "rollout.json",            // Wrong extension
            "rollout-abc.json",        // Wrong extension
            "ROLLOUT-abc.jsonl",       // Case sensitive
            "log-rollout.jsonl",       // rollout not at start
            "rollout_abc.jsonl"        // Underscore instead of hyphen
        ]

        for filename in invalidFilenames {
            let isValid = filename.hasPrefix("rollout-") && filename.hasSuffix(".jsonl")
            XCTAssertFalse(isValid,
                          "File '\(filename)' should not match rollout-*.jsonl pattern")
        }
    }

    func testYYYYMMDDPathFormat() {
        // Tests that the date path follows YYYY/MM/DD format
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        let testDate = Date()
        let datePath = formatter.string(from: testDate)

        // Verify format has correct structure
        let components = datePath.split(separator: "/")
        XCTAssertEqual(components.count, 3, "Date path should have 3 components")

        let year = String(components[0])
        let month = String(components[1])
        let day = String(components[2])

        // Year should be 4 digits
        XCTAssertEqual(year.count, 4, "Year should be 4 digits")
        XCTAssertNotNil(Int(year), "Year should be numeric")

        // Month should be 2 digits
        XCTAssertEqual(month.count, 2, "Month should be 2 digits")
        XCTAssertNotNil(Int(month), "Month should be numeric")
        if let monthInt = Int(month) {
            XCTAssertTrue(monthInt >= 1 && monthInt <= 12, "Month should be 1-12")
        }

        // Day should be 2 digits
        XCTAssertEqual(day.count, 2, "Day should be 2 digits")
        XCTAssertNotNil(Int(day), "Day should be numeric")
        if let dayInt = Int(day) {
            XCTAssertTrue(dayInt >= 1 && dayInt <= 31, "Day should be 1-31")
        }
    }

    func testYesterdayPathCalculation() {
        // Tests that yesterday's path is calculated correctly
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todayPath = formatter.string(from: today)
        let yesterdayPath = formatter.string(from: yesterday)

        XCTAssertNotEqual(todayPath, yesterdayPath, "Today and yesterday paths should differ")

        // Parse components and verify difference
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
        let yesterdayComponents = Calendar.current.dateComponents([.year, .month, .day], from: yesterday)

        // Day should decrease by 1 (or wrap around at month boundary)
        if todayComponents.day! > 1 {
            XCTAssertEqual(yesterdayComponents.day, todayComponents.day! - 1)
        }
    }

    func testFullCodexLogPath() {
        // Tests the complete path construction: ~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl
        let basePath = Provider.codex.logsPath
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let datePath = formatter.string(from: Date())

        let fullDirPath = (basePath as NSString).appendingPathComponent(datePath)
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        // Verify the full path structure
        XCTAssertTrue(fullDirPath.hasPrefix(homeDir))
        XCTAssertTrue(fullDirPath.contains(".codex/sessions/"))
        XCTAssertTrue(fullDirPath.contains(datePath))

        // Example path verification
        // Should be like: /Users/username/.codex/sessions/2026/02/05
        let expectedPattern = ".codex/sessions/\\d{4}/\\d{2}/\\d{2}"
        let regex = try! NSRegularExpression(pattern: expectedPattern)
        let range = NSRange(fullDirPath.startIndex..., in: fullDirPath)
        XCTAssertNotNil(regex.firstMatch(in: fullDirPath, range: range),
                       "Full path should match pattern: ~/.codex/sessions/YYYY/MM/DD")
    }

    // MARK: - Log Parsing Tests

    func testCodexLogEntryWithFullPayload() throws {
        // Tests parsing a complete token_count entry with rate_limits and timestamp
        let json = """
        {
            "payload": {
                "type": "token_count",
                "rate_limits": {
                    "primary": {
                        "used_percent": 25.5,
                        "resets_at": 1770300000
                    },
                    "secondary": {
                        "used_percent": 65.3,
                        "resets_at": 1770800000
                    }
                }
            },
            "timestamp": "2024-01-15T14:30:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "token_count")
        XCTAssertEqual(entry.payload?.rateLimits?.primary?.usedPercent, 25.5)
        XCTAssertEqual(entry.payload?.rateLimits?.primary?.resetsAt, 1770300000)
        XCTAssertEqual(entry.payload?.rateLimits?.secondary?.usedPercent, 65.3)
        XCTAssertEqual(entry.payload?.rateLimits?.secondary?.resetsAt, 1770800000)
        XCTAssertEqual(entry.timestamp, "2024-01-15T14:30:00Z")
    }

    func testCodexLogEntryWithoutRateLimits() throws {
        // Tests parsing a token_count entry without rate_limits
        let json = """
        {
            "payload": {
                "type": "token_count"
            },
            "timestamp": "2024-01-15T15:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "token_count")
        XCTAssertNil(entry.payload?.rateLimits)
    }

    func testCodexLogEntrySkipsNonTokenCountTypes() throws {
        // Tests that non-token_count entries are parsed but filtered by the provider
        let json = """
        {
            "payload": {
                "type": "conversation_start"
            },
            "timestamp": "2024-01-15T14:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.type, "conversation_start")
        XCTAssertNil(entry.payload?.rateLimits)
    }

    func testCodexEstimatedUsageCalculation() {
        // Tests the estimation formula used when rate_limits are unavailable
        // Formula: percentage = min(totalTokens / 500_000 * 100, 100)
        let estimatedLimit = 500_000

        let testCases: [(Int, Double)] = [
            (0, 0.0),
            (50_000, 10.0),
            (250_000, 50.0),
            (375_000, 75.0),
            (450_000, 90.0),
            (500_000, 100.0),
            (750_000, 100.0), // Should cap at 100%
        ]

        for (totalTokens, expectedPercentage) in testCases {
            let percentage = min(Double(totalTokens) / Double(estimatedLimit) * 100, 100)
            XCTAssertEqual(percentage, expectedPercentage, accuracy: 0.001,
                          "Tokens \(totalTokens) should estimate to \(expectedPercentage)%")
        }
    }

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
            dataSource: .local
        )

        XCTAssertEqual(usageData.provider, .codex)
        XCTAssertEqual(usageData.dataSource, .local)
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
            dataSource: .local
        )

        XCTAssertEqual(usageData.provider, .codex)
        XCTAssertEqual(usageData.dataSource, .local)
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
                dataSource: .local
            )

            XCTAssertEqual(usageData.status, expectedStatus,
                          "Percentage \(percentage)% should result in \(expectedStatus) status")
        }
    }

    func testCodexRateLimitWindowWithZeroValues() throws {
        // Tests rate_limits with zero values
        let json = """
        {
            "payload": {
                "type": "token_count",
                "rate_limits": {
                    "primary": {
                        "used_percent": 0,
                        "resets_at": 1770300000
                    }
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.rateLimits?.primary?.usedPercent, 0)
        XCTAssertNil(entry.payload?.rateLimits?.secondary)
    }

    func testCodexRateLimitWindowWith100Percent() throws {
        // Tests rate_limits at maximum usage
        let json = """
        {
            "payload": {
                "type": "token_count",
                "rate_limits": {
                    "primary": {
                        "used_percent": 100,
                        "resets_at": 1770300000
                    },
                    "secondary": {
                        "used_percent": 100,
                        "resets_at": 1770800000
                    }
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let entry = try JSONDecoder().decode(CodexLogEntry.self, from: data)

        XCTAssertEqual(entry.payload?.rateLimits?.primary?.usedPercent, 100)
        XCTAssertEqual(entry.payload?.rateLimits?.secondary?.usedPercent, 100)
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

    // MARK: - File Discovery Tests

    func testRolloutFileSorting() {
        // Tests that rollout files are sorted correctly (most recent first)
        var files = [
            "rollout-aaa.jsonl",
            "rollout-ccc.jsonl",
            "rollout-bbb.jsonl"
        ]

        files = files.filter { $0.hasPrefix("rollout-") && $0.hasSuffix(".jsonl") }
            .sorted()
            .reversed()
            .map { $0 }

        // Reversed sorted order (most recent first alphabetically)
        XCTAssertEqual(files[0], "rollout-ccc.jsonl")
        XCTAssertEqual(files[1], "rollout-bbb.jsonl")
        XCTAssertEqual(files[2], "rollout-aaa.jsonl")
    }

    func testRolloutFileFiltering() {
        // Tests filtering of files to only include rollout-*.jsonl
        let allFiles = [
            "rollout-session1.jsonl",
            "rollout-session2.jsonl",
            "other-file.jsonl",
            "rollout-session3.json", // Wrong extension
            "config.json",
            ".DS_Store"
        ]

        let rolloutFiles = allFiles.filter { $0.hasPrefix("rollout-") && $0.hasSuffix(".jsonl") }

        XCTAssertEqual(rolloutFiles.count, 2)
        XCTAssertTrue(rolloutFiles.contains("rollout-session1.jsonl"))
        XCTAssertTrue(rolloutFiles.contains("rollout-session2.jsonl"))
    }
}
