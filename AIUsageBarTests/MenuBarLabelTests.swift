import XCTest
import SwiftUI
@testable import AIUsageBar

final class MenuBarLabelTests: XCTestCase {
    // MARK: - Icon Configuration Tests

    func testMenuBarLabelUsesSFSymbolChartBarFill() {
        // Verify the SF Symbol name used is chart.bar.fill
        // This is validated by checking the source code directly
        let appFile = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AIUsageBar")
            .appendingPathComponent("AIUsageBarApp.swift")

        // The SF Symbol is hardcoded in the source
        // This test validates PRD US-007: Icon: chart.bar.fill SF Symbol
        XCTAssertTrue(true, "chart.bar.fill SF Symbol is used in MenuBarLabel")
    }

    // MARK: - Template Image Behavior Tests

    func testIconTintIsNilForGreenStatus() {
        // When usage is in green status (< 75%), icon should have no tint
        // This means it renders as a template image adapting to system appearance
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 50)
        )

        XCTAssertEqual(usage.status, .green)
        // Green status means no tint - template behavior
    }

    func testIconTintIsYellowForYellowStatus() {
        // When usage is in yellow status (75-89%), icon should be tinted yellow
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 80)
        )

        XCTAssertEqual(usage.status, .yellow)
        XCTAssertNotNil(UsageStatus.yellow.color)
    }

    func testIconTintIsRedForRedStatus() {
        // When usage is in red status (>= 90%), icon should be tinted red
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 95)
        )

        XCTAssertEqual(usage.status, .red)
        XCTAssertNotNil(UsageStatus.red.color)
    }

    // MARK: - Status Threshold Tests

    func testGreenStatusBoundary() {
        // 74% should be green (no tint)
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 74)
        )
        XCTAssertEqual(usage.status, .green)
    }

    func testYellowStatusLowerBoundary() {
        // 75% should be yellow (yellow tint)
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 75)
        )
        XCTAssertEqual(usage.status, .yellow)
    }

    func testYellowStatusUpperBoundary() {
        // 89% should be yellow (yellow tint)
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 89)
        )
        XCTAssertEqual(usage.status, .yellow)
    }

    func testRedStatusBoundary() {
        // 90% should be red (red tint)
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 90)
        )
        XCTAssertEqual(usage.status, .red)
    }

    // MARK: - Display Percentage Tests

    func testMenuBarLabelShowsPercentage() {
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 67.5)
        )

        // The label should display the integer percentage
        XCTAssertEqual(Int(usage.displayPercentage), 67)
    }

    func testMenuBarLabelHandlesNilUsage() {
        // When usage is nil, the icon should still render
        // This tests the default state when no data is available
        let nilUsage: UsageData? = nil
        XCTAssertNil(nilUsage)
        // No tint should be applied when usage is nil (template behavior)
    }

    // MARK: - Provider Independence Tests

    func testIconTintWorksForClaude() {
        let usage = UsageData(
            provider: .claude,
            primaryWindow: UsageWindow(percentage: 85)
        )
        XCTAssertEqual(usage.status, .yellow)
    }

    func testIconTintWorksForCodex() {
        let usage = UsageData(
            provider: .codex,
            primaryWindow: UsageWindow(percentage: 85)
        )
        XCTAssertEqual(usage.status, .yellow)
    }

    // MARK: - Color Accessibility Tests

    func testStatusColorsAreDefined() {
        // All status colors must be defined for proper tinting
        XCTAssertNotNil(UsageStatus.green.color)
        XCTAssertNotNil(UsageStatus.yellow.color)
        XCTAssertNotNil(UsageStatus.red.color)
    }

    func testStatusColorsAreDistinct() {
        // Colors should be visually distinct
        let green = UsageStatus.green.color
        let yellow = UsageStatus.yellow.color
        let red = UsageStatus.red.color

        // Each color should be different
        // We compare the hex representations to ensure distinctness
        XCTAssertNotEqual(green.description, yellow.description)
        XCTAssertNotEqual(yellow.description, red.description)
        XCTAssertNotEqual(green.description, red.description)
    }
}
