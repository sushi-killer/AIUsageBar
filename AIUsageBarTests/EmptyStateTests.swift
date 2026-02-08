import XCTest
@testable import AIUsageBar

/// Tests for PRD US-008: Empty state when no data - "Start using [Provider] to see usage"
/// Validates that the panel displays an empty state message when no usage data is available
final class EmptyStateTests: XCTestCase {

    // MARK: - Empty State Existence Tests

    func testEmptyStateExistsInContentView() throws {
        // Verify ContentView has empty state handling
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("else {") && content.contains("Empty state"),
            "ContentView must have empty state handling (PRD US-008)"
        )
    }

    func testEmptyStateHasIcon() throws {
        // Verify empty state displays an icon
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Image(systemName:") && content.contains("chart.bar"),
            "Empty state must display an icon (PRD US-008)"
        )
    }

    func testEmptyStateUsesChartIcon() throws {
        // Verify empty state uses chart.bar.xaxis icon for visual consistency
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("chart.bar.xaxis"),
            "Empty state should use chart.bar.xaxis SF Symbol icon"
        )
    }

    // MARK: - Empty State Text Tests

    func testEmptyStateHasStartUsingText() throws {
        // Verify empty state shows "Start using [Provider] to see usage"
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Start using") && content.contains("to see usage"),
            "Empty state must show 'Start using [Provider] to see usage' text (PRD US-008)"
        )
    }

    func testEmptyStateIncludesProviderName() throws {
        // Verify empty state text includes the selected provider's display name
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("selectedProvider.displayName") ||
            content.contains("\\(selectedProvider.displayName)"),
            "Empty state must include provider display name (PRD US-008)"
        )
    }

    func testEmptyStateTextIsCentered() throws {
        // Verify empty state text is centered
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".multilineTextAlignment(.center)"),
            "Empty state text should be center-aligned"
        )
    }

    // MARK: - Empty State Styling Tests

    func testEmptyStateIconUsesSecondaryColor() throws {
        // Verify empty state icon uses secondary color
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // Check for secondary foreground color on the icon
        XCTAssertTrue(
            content.contains(".foregroundStyle(.secondary)"),
            "Empty state icon should use secondary color"
        )
    }

    func testEmptyStateTextUsesSecondaryColor() throws {
        // Verify empty state text uses secondary color
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".foregroundStyle(.secondary)"),
            "Empty state text should use secondary color for subtle appearance"
        )
    }

    func testEmptyStateIconUsesLargeTitleFont() throws {
        // Verify empty state icon uses large title font
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".font(.largeTitle)"),
            "Empty state icon should use large title font for visibility"
        )
    }

    func testEmptyStateTextUsesSubheadlineFont() throws {
        // Verify empty state text uses appropriate font
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".font(.subheadline)"),
            "Empty state text should use subheadline font"
        )
    }

    // MARK: - Empty State Layout Tests

    func testEmptyStateUsesVStack() throws {
        // Verify empty state uses VStack for vertical layout
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // The empty state should be in a VStack with spacing
        XCTAssertTrue(
            content.contains("VStack(spacing:") && content.contains("Empty state"),
            "Empty state should use VStack for icon and text layout"
        )
    }

    func testEmptyStateHasVerticalPadding() throws {
        // Verify empty state has vertical padding for visual balance
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".padding(.vertical,") || content.contains("padding(.vertical)"),
            "Empty state should have vertical padding"
        )
    }

    func testEmptyStateExpandsToFillSpace() throws {
        // Verify empty state expands to fill available space
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".frame(maxWidth: .infinity") ||
            content.contains("frame(maxWidth: .infinity"),
            "Empty state should expand to fill available width"
        )
    }

    // MARK: - Conditional Display Tests

    func testEmptyStateDisplayedWhenNoUsageData() throws {
        // Verify empty state is shown when currentUsage is nil
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("if let usage = currentUsage") ||
            content.contains("if let usage = currentUsage {"),
            "Empty state must be conditional on currentUsage being nil"
        )
    }

    func testUsageDataDisplayedWhenAvailable() throws {
        // Verify usage components are shown when data is available (not empty state)
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("UsageRing("),
            "Usage components must be displayed when data is available"
        )
    }

    // MARK: - Provider Display Name Tests

    func testClaudeDisplayName() {
        // Verify Claude provider has correct display name
        let provider = Provider.claude
        XCTAssertEqual(
            provider.displayName,
            "Claude",
            "Claude provider should have 'Claude' as display name"
        )
    }

    func testCodexDisplayName() {
        // Verify Codex provider has correct display name
        let provider = Provider.codex
        XCTAssertEqual(
            provider.displayName,
            "Codex",
            "Codex provider should have 'Codex' as display name"
        )
    }

    func testEmptyStateMessageForClaude() {
        // Verify correct empty state message construction for Claude
        let provider = Provider.claude
        let expectedMessage = "Start using \(provider.displayName) to see usage"
        XCTAssertEqual(
            expectedMessage,
            "Start using Claude to see usage",
            "Empty state message for Claude must be correctly constructed"
        )
    }

    func testEmptyStateMessageForCodex() {
        // Verify correct empty state message construction for Codex
        let provider = Provider.codex
        let expectedMessage = "Start using \(provider.displayName) to see usage"
        XCTAssertEqual(
            expectedMessage,
            "Start using Codex to see usage",
            "Empty state message for Codex must be correctly constructed"
        )
    }

    // MARK: - UsageManager Integration Tests

    func testUsageManagerReturnsNilForNoData() throws {
        // Verify UsageManager has method to return usage for provider
        let managerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/UsageManager.swift")

        let content = try String(contentsOfFile: managerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("func usage(for provider:") ||
            content.contains("usage(for:"),
            "UsageManager must have method to get usage for specific provider"
        )
    }

    func testContentViewGetsUsageFromManager() throws {
        // Verify ContentView gets usage from UsageManager
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("usageManager.usage(for:") ||
            content.contains("usageManager.usage"),
            "ContentView must get usage data from UsageManager"
        )
    }
}
