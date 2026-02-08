import XCTest
@testable import AIUsageBar

/// Tests for single-tap provider switching (PRD US-008)
/// Validates that users can switch between providers with a single tap
final class ProviderSwitchingTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Tab Button Tap Tests

    func testProviderTabUsesButtonForTapInteraction() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains("Button(action:"),
            "ProviderTab should use a Button for single-tap interaction"
        )
    }

    func testProviderTabHasPlainButtonStyle() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains(".buttonStyle(.plain)"),
            "ProviderTab button should use plain style for clean tap area"
        )
    }

    func testProviderTabHasFullWidthTapArea() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains(".contentShape(Rectangle())"),
            "ProviderTab should have contentShape(Rectangle()) for full-area tap target"
        )
    }

    func testProviderTabExpandsToFillWidth() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains(".frame(maxWidth: .infinity)"),
            "ProviderTab should expand to fill available width"
        )
    }

    // MARK: - Selection Update Tests

    func testTapUpdatesSelectedProviderBinding() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains("selectedProvider = provider"),
            "Tapping a tab should update the selectedProvider binding"
        )
    }

    func testTapAnimatesSelectionChange() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains("withAnimation(.easeInOut(duration: 0.2))"),
            "Provider switch should animate with easeInOut transition"
        )
    }

    // MARK: - Settings Persistence Tests

    func testContentViewBindsToAppSettings() throws {
        let source = try readSource("Views/ContentView.swift")

        XCTAssertTrue(
            source.contains("settings.selectedProvider"),
            "ContentView should bind provider selection to AppSettings"
        )
    }

    func testAppSettingsStoresSelectedProvider() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"selectedProvider\")"),
            "AppSettings should persist selected provider via @AppStorage"
        )
    }

    func testProviderSelectionPersistsAcrossViews() throws {
        let source = try readSource("Views/ContentView.swift")

        // Verify the binding reads and writes to settings
        XCTAssertTrue(
            source.contains("get: { settings.selectedProvider }") &&
            source.contains("set: { settings.selectedProvider = $0 }"),
            "ContentView should create a two-way binding to settings.selectedProvider"
        )
    }

    // MARK: - UI Reactivity Tests

    func testContentViewUpdatesUsageOnProviderSwitch() throws {
        let source = try readSource("Views/ContentView.swift")

        XCTAssertTrue(
            source.contains("usageManager.usage(for: selectedProvider)"),
            "ContentView should fetch usage data for the currently selected provider"
        )
    }

    func testSelectedProviderDrivesCurrentUsage() throws {
        let source = try readSource("Views/ContentView.swift")

        // Verify currentUsage is a computed property dependent on selectedProvider
        XCTAssertTrue(
            source.contains("private var currentUsage: UsageData?") &&
            source.contains("usageManager.usage(for: selectedProvider)"),
            "currentUsage should be computed from the selected provider"
        )
    }

    // MARK: - Provider Model Tests

    func testAllProvidersAreAvailableForSwitching() {
        let providers = Provider.allCases
        XCTAssertEqual(
            providers.count, 2,
            "There should be exactly 2 providers available for switching"
        )
    }

    func testEachProviderHasUniqueDisplayName() {
        let names = Provider.allCases.map { $0.displayName }
        let uniqueNames = Set(names)
        XCTAssertEqual(
            names.count, uniqueNames.count,
            "Each provider should have a unique display name for tab identification"
        )
    }

    func testEachProviderHasUniqueColor() {
        let colors = Provider.allCases.map { $0.color.description }
        let uniqueColors = Set(colors)
        XCTAssertEqual(
            colors.count, uniqueColors.count,
            "Each provider should have a unique color for visual differentiation"
        )
    }

    // MARK: - Visual Feedback Tests

    func testSelectedTabShowsVisualDistinction() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        // Selected tab has different background than unselected
        XCTAssertTrue(
            source.contains("isSelected ? provider.color : Color.clear"),
            "Selected tab should show provider color while unselected shows clear"
        )
    }

    func testSelectedTabHasBoldText() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains("isSelected ? .semibold : .regular"),
            "Selected tab should use semibold font weight for emphasis"
        )
    }

    func testSelectedTabHasContrastingTextColor() throws {
        let source = try readSource("Views/ProviderTabs.swift")

        XCTAssertTrue(
            source.contains("isSelected ? .white : .secondary"),
            "Selected tab should show white text, unselected should show secondary"
        )
    }
}
