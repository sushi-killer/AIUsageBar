import XCTest
@testable import AIUsageBar

/// Tests for PRD US-010: Launch at login toggle (default: false)
/// Validates that users can enable/disable launch at login from the Settings view
final class LaunchAtLoginTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Settings Model Tests

    func testLaunchAtLoginPropertyExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("launchAtLogin"),
            "AppSettings must have a launchAtLogin property (PRD US-010)"
        )
    }

    func testLaunchAtLoginUsesAppStorage() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"launchAtLogin\")"),
            "launchAtLogin must use @AppStorage for persistence (PRD US-010)"
        )
    }

    func testLaunchAtLoginDefaultsToFalse() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var launchAtLogin: Bool = false"),
            "launchAtLogin must default to false (PRD US-010)"
        )
    }

    func testLaunchAtLoginIsBoolType() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("launchAtLogin: Bool"),
            "launchAtLogin must be a Bool type"
        )
    }

    // MARK: - SMAppService Integration Tests

    func testSettingsImportsServiceManagement() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("import ServiceManagement"),
            "Settings must import ServiceManagement for SMAppService (PRD US-010)"
        )
    }

    func testUpdateLaunchAtLoginMethodExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("func updateLaunchAtLogin()"),
            "AppSettings must have an updateLaunchAtLogin method"
        )
    }

    func testLaunchAtLoginUsesDidSet() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("launchAtLogin: Bool = false {") &&
            source.contains("didSet"),
            "launchAtLogin must use didSet to trigger SMAppService update"
        )
    }

    func testUpdateLaunchAtLoginRegistersApp() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("SMAppService.mainApp.register()"),
            "updateLaunchAtLogin must call SMAppService.mainApp.register() when enabled"
        )
    }

    func testUpdateLaunchAtLoginUnregistersApp() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("SMAppService.mainApp.unregister()"),
            "updateLaunchAtLogin must call SMAppService.mainApp.unregister() when disabled"
        )
    }

    func testUpdateLaunchAtLoginHandlesErrors() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("catch") &&
            source.contains("Failed to update launch at login"),
            "updateLaunchAtLogin must handle errors gracefully"
        )
    }

    func testLaunchAtLoginConditionallyRegisters() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("if launchAtLogin") &&
            source.contains("register()") &&
            source.contains("unregister()"),
            "updateLaunchAtLogin must register when true and unregister when false"
        )
    }

    // MARK: - SettingsView Toggle UI Tests

    func testSettingsViewHasStartupSection() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"Startup\""),
            "SettingsView must have a Startup section header (PRD US-010)"
        )
    }

    func testSettingsViewHasLaunchAtLoginToggle() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("Toggle(\"Launch at Login\""),
            "SettingsView must have a 'Launch at Login' toggle (PRD US-010)"
        )
    }

    func testLaunchAtLoginToggleBindsToSettings() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("isOn: $settings.launchAtLogin"),
            "Launch at Login toggle must bind to settings.launchAtLogin (PRD US-010)"
        )
    }

    func testLaunchAtLoginToggleUsesSwitchStyle() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("Toggle(\"Launch at Login\", isOn: $settings.launchAtLogin)") &&
            source.contains(".toggleStyle(.switch)"),
            "Launch at Login toggle must use switch style"
        )
    }

    func testStartupSectionUsesSubheadlineFont() throws {
        let source = try readSource("Views/SettingsView.swift")

        // Verify the Startup section label uses proper styling
        XCTAssertTrue(
            source.contains("\"Startup\"") &&
            source.contains(".font(.subheadline)"),
            "Startup section header must use subheadline font"
        )
    }

    func testStartupSectionUsesSecondaryColor() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"Startup\"") &&
            source.contains(".foregroundStyle(.secondary)"),
            "Startup section header must use secondary foreground color"
        )
    }

    // MARK: - Settings Persistence Tests

    func testLaunchAtLoginPersistsAcrossRestarts() throws {
        let source = try readSource("Models/Settings.swift")

        // @AppStorage ensures persistence across app restarts
        XCTAssertTrue(
            source.contains("@AppStorage(\"launchAtLogin\") var launchAtLogin"),
            "launchAtLogin must persist across app restarts via @AppStorage (PRD US-010)"
        )
    }

    func testSettingsUsesMainAppService() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("SMAppService.mainApp"),
            "Settings must use SMAppService.mainApp for launch at login (macOS 13+)"
        )
    }
}
