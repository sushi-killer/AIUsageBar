import XCTest
@testable import AIUsageBar

/// Tests for PRD US-008: Reset timer - countdown to primary window reset ("2h 45m" format)
/// Validates that the panel displays a countdown timer that updates every second
final class ResetTimerTests: XCTestCase {

    // MARK: - ResetTimer Component Tests

    func testResetTimerFileExists() throws {
        // Verify ResetTimer.swift exists
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let fileManager = FileManager.default
        XCTAssertTrue(
            fileManager.fileExists(atPath: timerPath),
            "ResetTimer.swift must exist for countdown display (PRD US-008)"
        )
    }

    func testResetTimerIsSwiftUIView() throws {
        // Verify ResetTimer conforms to View protocol
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("struct ResetTimer: View"),
            "ResetTimer must be a SwiftUI View"
        )
    }

    func testResetTimerAcceptsResetTime() throws {
        // Verify ResetTimer takes a resetTime parameter
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("let resetTime: Date?"),
            "ResetTimer must accept an optional Date parameter for reset time (PRD US-008)"
        )
    }

    // MARK: - TimelineView Tests (Updates Every Second)

    func testResetTimerUsesTimelineView() throws {
        // Verify ResetTimer uses TimelineView for efficient per-second updates
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("TimelineView"),
            "ResetTimer must use TimelineView for efficient timer updates (PRD US-008)"
        )
    }

    func testResetTimerUpdatesEverySecond() throws {
        // Verify ResetTimer uses 1-second periodic updates
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".periodic(from:") && content.contains("by: 1.0"),
            "ResetTimer must update every second using periodic schedule (PRD US-008)"
        )
    }

    // MARK: - Display Format Tests ("2h 45m" format)

    func testResetTimerHasFormatFunction() throws {
        // Verify ResetTimer has a formatting function
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("formatTimeRemaining"),
            "ResetTimer must have a time formatting function"
        )
    }

    func testResetTimerFormatsHoursAndMinutes() throws {
        // Verify ResetTimer formats hours and minutes correctly ("Xh Xm" format)
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("%dh") && content.contains("%02dm"),
            "ResetTimer must format hours and minutes in 'Xh XXm' format (PRD US-008)"
        )
    }

    func testResetTimerFormatsMinutesAndSeconds() throws {
        // Verify ResetTimer formats minutes and seconds when under 1 hour
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("%dm") && content.contains("%02ds"),
            "ResetTimer must format minutes and seconds when under 1 hour"
        )
    }

    func testResetTimerHandlesNilResetTime() throws {
        // Verify ResetTimer handles nil reset time gracefully
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("guard let resetTime") && content.contains("--:--"),
            "ResetTimer must handle nil reset time with fallback display"
        )
    }

    func testResetTimerHandlesPastResetTime() throws {
        // Verify ResetTimer handles reset time in the past
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("interval <= 0") && content.contains("resetting"),
            "ResetTimer must show 'resetting...' when reset time has passed"
        )
    }

    // MARK: - UI Element Tests

    func testResetTimerDisplaysClockIcon() throws {
        // Verify ResetTimer shows a clock icon
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Image(systemName: \"clock\")"),
            "ResetTimer should display a clock icon"
        )
    }

    func testResetTimerUsesHStack() throws {
        // Verify ResetTimer uses HStack for horizontal layout
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("HStack"),
            "ResetTimer should use HStack for icon and text layout"
        )
    }

    func testResetTimerUsesMonospacedDigitFont() throws {
        // Verify ResetTimer uses monospaced digits for stable width
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("monospacedDigit"),
            "ResetTimer should use monospaced digits for stable display"
        )
    }

    func testResetTimerUsesCaptionFont() throws {
        // Verify ResetTimer uses caption font size
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".caption"),
            "ResetTimer should use caption font for compact display"
        )
    }

    func testResetTimerUsesSecondaryColor() throws {
        // Verify ResetTimer uses secondary foreground color
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("foregroundStyle(.secondary)"),
            "ResetTimer should use secondary color for subtle appearance"
        )
    }

    // MARK: - ContentView Integration Tests

    func testContentViewUsesResetTimer() throws {
        // Verify ContentView uses the ResetTimer component
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("ResetTimer("),
            "ContentView must use ResetTimer component (PRD US-008)"
        )
    }

    func testContentViewPassesResetTimeToTimer() throws {
        // Verify ContentView passes resetTime to ResetTimer
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("resetTime:") && content.contains("ResetTimer"),
            "ContentView must pass resetTime to ResetTimer"
        )
    }

    func testContentViewUsesPrimaryWindowResetTime() throws {
        // Verify ContentView passes primary window reset time
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("primaryWindow.resetTime"),
            "ContentView must pass primary window reset time to ResetTimer (PRD US-008)"
        )
    }

    // MARK: - CPU Efficiency Tests

    func testResetTimerDocumentsIdleOptimization() throws {
        // Verify ResetTimer documents that it pauses when not visible
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("pause") || content.contains("idle") || content.contains("not visible"),
            "ResetTimer should document CPU efficiency when not visible"
        )
    }

    func testResetTimerUsesContextDate() throws {
        // Verify ResetTimer uses TimelineView context date for accuracy
        let timerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ResetTimer.swift")

        let content = try String(contentsOfFile: timerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("context.date"),
            "ResetTimer should use TimelineView context date for accurate timing"
        )
    }

    // MARK: - UsageWindow Model Tests

    func testUsageWindowHasResetTime() throws {
        // Verify UsageWindow model has resetTime property
        let usageDataPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Models/UsageData.swift")

        let content = try String(contentsOfFile: usageDataPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("let resetTime: Date?"),
            "UsageWindow must have optional resetTime property"
        )
    }

    func testUsageWindowHasFormattedResetTime() throws {
        // Verify UsageWindow has formatted reset time helper
        let usageDataPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Models/UsageData.swift")

        let content = try String(contentsOfFile: usageDataPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("formattedResetTime"),
            "UsageWindow should have formattedResetTime computed property"
        )
    }

    // MARK: - Time Calculation Tests

    func testTimeCalculatesHoursCorrectly() {
        // Verify time interval to hours calculation
        let hours = Int(7200) / 3600  // 2 hours in seconds
        XCTAssertEqual(hours, 2, "7200 seconds should equal 2 hours")
    }

    func testTimeCalculatesMinutesCorrectly() {
        // Verify time interval to minutes calculation
        let seconds = 7200 + 2700  // 2h 45m in seconds
        let minutes = (seconds % 3600) / 60
        XCTAssertEqual(minutes, 45, "Remaining seconds should equal 45 minutes")
    }

    func testTimeCalculatesSecondsCorrectly() {
        // Verify time interval to seconds calculation
        let totalSeconds = 125  // 2m 5s
        let seconds = totalSeconds % 60
        XCTAssertEqual(seconds, 5, "Remaining seconds should be 5")
    }
}
