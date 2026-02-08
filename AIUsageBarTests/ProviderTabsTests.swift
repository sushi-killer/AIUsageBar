import XCTest
@testable import AIUsageBar

/// Tests for ProviderTabs component (PRD US-008)
/// Validates horizontal tab layout with Claude | Codex providers
final class ProviderTabsTests: XCTestCase {

    // MARK: - Component Structure Tests

    func testProviderTabsFileExists() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: filePath),
            "ProviderTabs.swift should exist in Views directory"
        )
    }

    func testProviderTabsUsesHStackForHorizontalLayout() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify HStack is used for horizontal layout
        XCTAssertTrue(
            source.contains("HStack"),
            "ProviderTabs should use HStack for horizontal tab layout"
        )
    }

    func testProviderTabsIteratesOverAllProviders() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify ForEach iterates over all providers
        XCTAssertTrue(
            source.contains("ForEach(Provider.allCases)"),
            "ProviderTabs should iterate over Provider.allCases"
        )
    }

    func testProviderTabsAcceptsSelectedProviderBinding() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify binding for selected provider
        XCTAssertTrue(
            source.contains("@Binding var selectedProvider: Provider"),
            "ProviderTabs should have a @Binding for selectedProvider"
        )
    }

    // MARK: - Tab Styling Tests

    func testActiveTabShowsProviderColor() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify active tab uses provider color
        XCTAssertTrue(
            source.contains("isSelected ? provider.color"),
            "Active tab should display provider color when selected"
        )
    }

    func testInactiveTabShowsClearOrGrayBackground() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify inactive tab uses clear/gray background
        XCTAssertTrue(
            source.contains("Color.clear") || source.contains("Color.gray"),
            "Inactive tab should have clear or gray background"
        )
    }

    func testActiveTabTextIsWhite() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify active tab text is white
        XCTAssertTrue(
            source.contains(".white"),
            "Active tab text should be white for contrast against provider color"
        )
    }

    func testInactiveTabTextIsSecondary() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify inactive tab text is secondary color
        XCTAssertTrue(
            source.contains(".secondary"),
            "Inactive tab text should use secondary color"
        )
    }

    // MARK: - Provider Display Tests

    func testProviderTabUsesDisplayName() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify display name is used
        XCTAssertTrue(
            source.contains("provider.displayName"),
            "Tab should display provider.displayName"
        )
    }

    func testClaudeProviderDisplayName() {
        // Verify Claude display name matches expected "Claude"
        XCTAssertEqual(
            Provider.claude.displayName,
            "Claude",
            "Claude provider should display as 'Claude'"
        )
    }

    func testCodexProviderDisplayName() {
        // Verify Codex display name matches expected "Codex"
        XCTAssertEqual(
            Provider.codex.displayName,
            "Codex",
            "Codex provider should display as 'Codex'"
        )
    }

    // MARK: - ContentView Integration Tests

    func testContentViewIncludesProviderTabs() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ContentView.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify ContentView uses ProviderTabs
        XCTAssertTrue(
            source.contains("ProviderTabs("),
            "ContentView should include ProviderTabs component"
        )
    }

    func testContentViewPassesSelectedProviderBinding() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ContentView.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify ContentView passes selectedProvider binding
        XCTAssertTrue(
            source.contains("selectedProvider:"),
            "ContentView should pass selectedProvider binding to ProviderTabs"
        )
    }

    // MARK: - Animation Tests

    func testTabSelectionHasAnimation() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify animation is applied on selection
        XCTAssertTrue(
            source.contains("withAnimation"),
            "Tab selection should have animation"
        )
    }

    // MARK: - Rounded Corner Tests

    func testProviderTabsHasRoundedCorners() throws {
        let filePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first! + "/AIUsageBar/Views/ProviderTabs.swift"

        let source = try String(contentsOfFile: filePath, encoding: .utf8)

        // Verify rounded corners are applied
        XCTAssertTrue(
            source.contains("RoundedRectangle") || source.contains("cornerRadius"),
            "ProviderTabs should have rounded corners"
        )
    }
}
