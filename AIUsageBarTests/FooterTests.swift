import XCTest
@testable import AIUsageBar

/// Tests for PRD US-008: Footer with Settings button
/// Validates that the panel has a footer section with a Settings button
final class FooterTests: XCTestCase {

    // MARK: - Footer Existence Tests

    func testFooterExistsInContentView() throws {
        // Verify ContentView has a footer section
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("// Footer"),
            "ContentView must have a footer section (PRD US-008)"
        )
    }

    func testFooterHasDivider() throws {
        // Verify footer is separated from content by a Divider
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Divider()"),
            "Footer must have a divider separating it from content (PRD US-008)"
        )
    }

    // MARK: - Settings Button Tests

    func testSettingsButtonExists() throws {
        // Verify Settings button exists in footer
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("showingSettings = true"),
            "Footer must have a Settings button that shows settings (PRD US-008)"
        )
    }

    func testSettingsButtonUsesGearIcon() throws {
        // Verify Settings button uses gear icon
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("\"gear\""),
            "Settings button must use gear SF Symbol icon (PRD US-008)"
        )
    }

    func testSettingsButtonHasPlainStyle() throws {
        // Verify Settings button uses plain button style
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".buttonStyle(.plain)"),
            "Settings button should use plain button style"
        )
    }

    // MARK: - Settings Sheet Tests

    func testShowingSettingsStateExists() throws {
        // Verify showingSettings state variable exists
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("@State private var showingSettings"),
            "ContentView must have showingSettings state variable"
        )
    }

    func testSettingsSheetIsPresented() throws {
        // Verify Settings sheet is presented when button is tapped
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".sheet(isPresented: $showingSettings)"),
            "Settings must be shown as a sheet (PRD US-008)"
        )
    }

    func testSettingsViewIsShown() throws {
        // Verify SettingsView is displayed in the sheet
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("SettingsView()"),
            "Settings sheet must display SettingsView"
        )
    }

    // MARK: - Footer Layout Tests

    func testFooterUsesHStack() throws {
        // Verify footer uses HStack for horizontal layout
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // Footer should use HStack
        XCTAssertTrue(
            content.contains("// Footer") && content.contains("HStack"),
            "Footer should use HStack for horizontal layout"
        )
    }

    func testFooterHasSpacer() throws {
        // Verify footer has Spacer() to push Settings button to the right
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("Spacer()"),
            "Footer should have Spacer() to align elements"
        )
    }

    // MARK: - Refresh Button Tests

    func testRefreshButtonExists() throws {
        // Verify refresh button exists in footer
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("\"arrow.clockwise\""),
            "Footer should have a refresh button with arrow.clockwise icon"
        )
    }

    func testRefreshButtonCallsRefresh() throws {
        // Verify refresh button triggers usageManager.refresh()
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("usageManager.refresh()"),
            "Refresh button must call usageManager.refresh()"
        )
    }

    func testRefreshButtonDisabledWhenLoading() throws {
        // Verify refresh button is disabled during loading
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".disabled(usageManager.isLoading)"),
            "Refresh button should be disabled when loading"
        )
    }

    // MARK: - Loading Indicator Tests

    func testLoadingIndicatorExists() throws {
        // Verify loading indicator exists in footer
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("ProgressView()"),
            "Footer should have a loading indicator"
        )
    }

    func testLoadingIndicatorConditional() throws {
        // Verify loading indicator is shown only when loading
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("if usageManager.isLoading"),
            "Loading indicator should only show when usageManager.isLoading is true"
        )
    }

    // MARK: - Button Font Tests

    func testSettingsButtonUsesCaptionFont() throws {
        // Verify Settings button uses caption font
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".font(.caption)"),
            "Footer buttons should use caption font for consistent sizing"
        )
    }

    // MARK: - SettingsView Existence Tests

    func testSettingsViewExists() throws {
        // Verify SettingsView file exists
        let settingsViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/SettingsView.swift")

        XCTAssertNoThrow(
            try String(contentsOfFile: settingsViewPath, encoding: .utf8),
            "SettingsView.swift must exist (PRD US-008)"
        )
    }

    func testSettingsViewIsSwiftUIView() throws {
        // Verify SettingsView is a SwiftUI View
        let settingsViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/SettingsView.swift")

        let content = try String(contentsOfFile: settingsViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("struct SettingsView:") && content.contains("View"),
            "SettingsView must be a SwiftUI View"
        )
    }
}
