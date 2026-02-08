import XCTest
@testable import AIUsageBar

/// Tests for PRD US-009: Limit Bars Component
/// Validates two horizontal progress bars showing primary and secondary usage windows
final class LimitBarsTests: XCTestCase {

    // MARK: - File Existence Tests

    func testLimitBarsFileExists() throws {
        let path = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/LimitBars.swift")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: path),
            "LimitBars.swift must exist (PRD US-009)"
        )
    }

    // MARK: - LimitBars Struct Tests

    func testLimitBarsIsSwiftUIView() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("struct LimitBars: View"),
            "LimitBars must be a SwiftUI View"
        )
    }

    func testLimitBarsAcceptsUsageData() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let usage: UsageData"),
            "LimitBars must accept a UsageData parameter"
        )
    }

    // MARK: - LimitBar Struct Tests

    func testLimitBarIsSwiftUIView() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("struct LimitBar: View"),
            "LimitBar must be a SwiftUI View for individual progress bars"
        )
    }

    func testLimitBarAcceptsLabel() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let label: String"),
            "LimitBar must accept a label parameter (PRD US-009)"
        )
    }

    func testLimitBarAcceptsPercentage() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let percentage: Double"),
            "LimitBar must accept a percentage parameter (PRD US-009)"
        )
    }

    func testLimitBarAcceptsResetTime() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let resetTime: String?"),
            "LimitBar must accept an optional reset time parameter (PRD US-009)"
        )
    }

    func testLimitBarAcceptsProviderColor() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let providerColor: Color"),
            "LimitBar must accept a providerColor for bar fill color"
        )
    }

    func testLimitBarAcceptsIsEstimated() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("let isEstimated: Bool"),
            "LimitBar must accept an isEstimated flag"
        )
    }

    // MARK: - Two Horizontal Progress Bars Tests

    func testLimitBarsRendersPrimaryBar() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("usage.provider.primaryWindowLabel"),
            "LimitBars must render primary bar with provider's primary window label (PRD US-009)"
        )
    }

    func testLimitBarsRendersSecondaryBar() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("usage.provider.secondaryWindowLabel"),
            "LimitBars must render secondary bar with provider's secondary window label (PRD US-009)"
        )
    }

    func testLimitBarsHandlesOptionalSecondaryWindow() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("if let secondary = usage.secondaryWindow"),
            "LimitBars must conditionally render secondary bar when available"
        )
    }

    func testLimitBarsUsesVStackLayout() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("VStack(spacing:"),
            "LimitBars must use VStack with spacing between bars (PRD US-009)"
        )
    }

    // MARK: - Primary Bar Label Tests

    func testPrimaryBarLabelIsFiveHour() {
        let provider = Provider.claude
        XCTAssertEqual(
            provider.primaryWindowLabel, "5-Hour",
            "Primary bar must show '5-Hour' label (PRD US-009)"
        )
    }

    func testCodexPrimaryBarLabelIsFiveHour() {
        let provider = Provider.codex
        XCTAssertEqual(
            provider.primaryWindowLabel, "5-Hour",
            "Codex primary bar must also show '5-Hour' label"
        )
    }

    // MARK: - Secondary Bar Label Tests

    func testClaudeSecondaryBarLabelIsWeekly() {
        let provider = Provider.claude
        XCTAssertEqual(
            provider.secondaryWindowLabel, "Weekly",
            "Claude secondary bar must show 'Weekly' label (PRD US-009)"
        )
    }

    func testCodexSecondaryBarLabelIsWeekly() {
        let provider = Provider.codex
        XCTAssertEqual(
            provider.secondaryWindowLabel, "Weekly",
            "Codex secondary bar must show 'Weekly' label"
        )
    }

    // MARK: - Bar Fill Color Tests

    func testBarUsesProviderColor() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".fill(providerColor)"),
            "Bar fill color must use provider color"
        )
    }

    func testBarHasBackgroundFill() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("Color.primary.opacity(0.1)"),
            "Bar must have a subtle background fill"
        )
    }

    // MARK: - Horizontal Progress Bar Visual Tests

    func testBarUsesRoundedRectangle() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("RoundedRectangle(cornerRadius:"),
            "Bar must use RoundedRectangle shape (PRD US-009)"
        )
    }

    func testBarHasFixedHeight() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".frame(height:"),
            "Bar must have a fixed height for consistent styling"
        )
    }

    func testBarUsesGeometryReader() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("GeometryReader"),
            "Bar must use GeometryReader for proportional fill width"
        )
    }

    func testBarFillWidthIsProportional() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("geometry.size.width") && content.contains("percentage / 100"),
            "Bar fill width must be proportional to percentage"
        )
    }

    func testBarFillIsClamped() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("min(percentage / 100, 1)"),
            "Bar fill must be clamped to max 100%"
        )
    }

    // MARK: - Percentage Text Tests

    func testPercentageTextIsRightAligned() throws {
        let content = try loadLimitBarsSource()

        // Percentage is right-aligned via HStack with Spacer before it
        XCTAssertTrue(
            content.contains("Spacer()") && content.contains("Int(percentage))%"),
            "Percentage text must be right-aligned (PRD US-009)"
        )
    }

    func testPercentageUsesMonospacedDigits() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".monospacedDigit()"),
            "Percentage text must use monospaced digits for alignment"
        )
    }

    // MARK: - Reset Time Tests

    func testResetTimeDisplayed() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("Resets"),
            "Bar must display reset time text (PRD US-009)"
        )
    }

    func testResetTimeIsOptional() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("if let resetTime"),
            "Reset time must be conditionally displayed when available"
        )
    }

    func testResetTimeRelativeFormat() {
        // Verify reset time uses relative format like "in 2h 45m"
        let futureDate = Date().addingTimeInterval(2 * 3600 + 45 * 60)
        let window = UsageWindow(percentage: 50, resetTime: futureDate)

        let formatted = window.formattedResetTime
        XCTAssertNotNil(formatted, "Reset time must be formatted")
        XCTAssertTrue(
            formatted!.starts(with: "in "),
            "Reset time must use relative format starting with 'in' (PRD US-009)"
        )
    }

    func testResetTimeHoursAndMinutes() {
        let futureDate = Date().addingTimeInterval(2 * 3600 + 30 * 60)
        let window = UsageWindow(percentage: 50, resetTime: futureDate)

        let formatted = window.formattedResetTime!
        XCTAssertTrue(
            formatted.contains("h") && formatted.contains("m"),
            "Reset time must show hours and minutes format"
        )
    }

    func testResetTimeMinutesOnly() {
        let futureDate = Date().addingTimeInterval(30 * 60)
        let window = UsageWindow(percentage: 50, resetTime: futureDate)

        let formatted = window.formattedResetTime!
        XCTAssertTrue(
            formatted.contains("m") && !formatted.contains("h"),
            "Reset time under 1 hour should show minutes only"
        )
    }

    func testResetTimePastShowsNow() {
        let pastDate = Date().addingTimeInterval(-60)
        let window = UsageWindow(percentage: 50, resetTime: pastDate)

        XCTAssertEqual(
            window.formattedResetTime, "now",
            "Past reset time should display 'now'"
        )
    }

    func testResetTimeNilWhenNoDate() {
        let window = UsageWindow(percentage: 50, resetTime: nil)

        XCTAssertNil(
            window.formattedResetTime,
            "Reset time should be nil when no date provided"
        )
    }

    // MARK: - Animation Tests

    func testBarHasAnimation() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".animation("),
            "Bar must animate on percentage change"
        )
    }

    func testBarUsesEaseInOutAnimation() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".easeInOut"),
            "Bar must use easeInOut animation for smooth transitions"
        )
    }

    // MARK: - Estimated Data Badge Tests

    func testEstimatedBadgeDisplayed() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("(est.)"),
            "Bar must show '(est.)' badge when data is estimated"
        )
    }

    func testEstimatedBadgeIsConditional() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains("if isEstimated"),
            "Estimated badge must only show when isEstimated is true"
        )
    }

    // MARK: - ContentView Integration Tests

    func testContentViewUsesLimitBars() throws {
        let contentPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("LimitBars("),
            "ContentView must use the LimitBars component (PRD US-009)"
        )
    }

    func testContentViewPassesUsageToLimitBars() throws {
        let contentPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("LimitBars(usage:"),
            "ContentView must pass usage data to LimitBars"
        )
    }

    // MARK: - Data Model Integration Tests

    func testUsageDataWithBothWindows() {
        let primary = UsageWindow(percentage: 45, resetTime: Date().addingTimeInterval(3600))
        let secondary = UsageWindow(percentage: 60, resetTime: Date().addingTimeInterval(86400))
        let usage = UsageData(
            provider: .claude,
            primaryWindow: primary,
            secondaryWindow: secondary
        )

        XCTAssertEqual(usage.primaryWindow.percentage, 45)
        XCTAssertNotNil(usage.secondaryWindow)
        XCTAssertEqual(usage.secondaryWindow?.percentage, 60)
    }

    func testUsageDataWithPrimaryOnly() {
        let primary = UsageWindow(percentage: 30)
        let usage = UsageData(
            provider: .codex,
            primaryWindow: primary,
            secondaryWindow: nil
        )

        XCTAssertEqual(usage.primaryWindow.percentage, 30)
        XCTAssertNil(usage.secondaryWindow, "Secondary window should be nil when not available")
    }

    func testWindowEstimatedFlag() {
        let estimated = UsageWindow(percentage: 40, isEstimated: true)
        let accurate = UsageWindow(percentage: 40, isEstimated: false)

        XCTAssertTrue(estimated.isEstimated)
        XCTAssertFalse(accurate.isEstimated)
    }

    // MARK: - Styling Consistency Tests

    func testBarLabelUsesSubheadlineFont() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".font(.subheadline)"),
            "Bar label should use subheadline font"
        )
    }

    func testBarResetTimeUsesCaptionFont() throws {
        let content = try loadLimitBarsSource()

        XCTAssertTrue(
            content.contains(".font(.caption)"),
            "Reset time should use caption font"
        )
    }

    func testBarsHaveConsistentSpacing() throws {
        let content = try loadLimitBarsSource()

        // LimitBars uses VStack(spacing: 16) for consistent spacing between bars
        XCTAssertTrue(
            content.contains("VStack(spacing: 16)"),
            "Bars must have consistent 16px spacing (PRD US-009)"
        )
    }

    // MARK: - Helper

    private func loadLimitBarsSource() throws -> String {
        let path = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/LimitBars.swift")
        return try String(contentsOfFile: path, encoding: .utf8)
    }
}
