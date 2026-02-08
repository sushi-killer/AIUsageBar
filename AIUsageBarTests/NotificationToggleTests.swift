import XCTest
@testable import AIUsageBar

/// Tests for PRD US-010: Notifications enabled toggle (default: true)
/// Validates that users can enable/disable notifications from the Settings view
final class NotificationToggleTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Settings Model Tests

    func testNotificationsEnabledPropertyExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("notificationsEnabled"),
            "AppSettings must have a notificationsEnabled property (PRD US-010)"
        )
    }

    func testNotificationsEnabledUsesAppStorage() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"notificationsEnabled\")"),
            "notificationsEnabled must use @AppStorage for persistence (PRD US-010)"
        )
    }

    func testNotificationsEnabledDefaultsToTrue() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var notificationsEnabled: Bool = true"),
            "notificationsEnabled must default to true (PRD US-010)"
        )
    }

    func testNotificationsEnabledIsBoolType() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("notificationsEnabled: Bool"),
            "notificationsEnabled must be a Bool type"
        )
    }

    // MARK: - SettingsView Toggle UI Tests

    func testSettingsViewHasNotificationsSection() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"Notifications\""),
            "SettingsView must have a Notifications section header (PRD US-010)"
        )
    }

    func testSettingsViewHasEnableNotificationsToggle() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("Toggle(\"Enable Notifications\""),
            "SettingsView must have an 'Enable Notifications' toggle (PRD US-010)"
        )
    }

    func testNotificationsToggleBindsToSettings() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("isOn: $settings.notificationsEnabled"),
            "Notifications toggle must bind to settings.notificationsEnabled (PRD US-010)"
        )
    }

    func testNotificationsToggleUsesSwitchStyle() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("Toggle(\"Enable Notifications\", isOn: $settings.notificationsEnabled)") &&
            source.contains(".toggleStyle(.switch)"),
            "Notifications toggle must use switch style"
        )
    }

    // MARK: - Conditional Sub-settings Tests

    func testThresholdSettingsConditionalOnNotificationsEnabled() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("if settings.notificationsEnabled"),
            "Threshold settings must only show when notifications are enabled (PRD US-010)"
        )
    }

    func testAlertThresholdsLabelExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"Alert Thresholds\""),
            "SettingsView must show 'Alert Thresholds' label when notifications enabled"
        )
    }

    func testThreshold50PickerRowExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("$settings.threshold50Enabled") &&
            source.contains("$settings.threshold50Value"),
            "SettingsView must have a threshold picker for the low (50%) threshold (PRD US-010)"
        )
    }

    func testThreshold75PickerRowExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("$settings.threshold75Enabled") &&
            source.contains("$settings.threshold75Value"),
            "SettingsView must have a threshold picker for the medium (75%) threshold (PRD US-010)"
        )
    }

    func testThreshold90PickerRowExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("$settings.threshold90Enabled") &&
            source.contains("$settings.threshold90Value"),
            "SettingsView must have a threshold picker for the high (90%) threshold (PRD US-010)"
        )
    }

    func testThresholdPickersUseSmallControlSize() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains(".controlSize(.small)"),
            "Threshold pickers must use small control size for compact layout"
        )
    }

    func testThresholdPickersAreIndented() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains(".padding(.leading, 16)"),
            "Threshold pickers must be indented under the main toggle"
        )
    }

    // MARK: - NotificationService Integration Tests

    func testNotificationServiceChecksNotificationsEnabled() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("AppSettings.shared.notificationsEnabled"),
            "NotificationService must check notificationsEnabled before sending (PRD US-010)"
        )
    }

    func testNotificationServiceGuardsOnEnabled() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("guard AppSettings.shared.notificationsEnabled"),
            "NotificationService must guard on notificationsEnabled to skip when disabled"
        )
    }

    func testNotificationServiceRequiresAuthorization() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("guard AppSettings.shared.notificationsEnabled, isAuthorized"),
            "NotificationService must require both enabled setting and system authorization"
        )
    }

    // MARK: - Permission Request Tests

    func testRequestPermissionButtonExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"Request Permission\""),
            "SettingsView must have a Request Permission button when not authorized"
        )
    }

    func testRequestPermissionConditionalOnAuthorization() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("!notificationService.isAuthorized"),
            "Request Permission button must only show when not authorized"
        )
    }

    func testRequestPermissionCallsService() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("notificationService.requestAuthorization()"),
            "Request Permission button must call notificationService.requestAuthorization()"
        )
    }

    // MARK: - Settings Model Threshold Tests

    func testEnabledThresholdsComputedProperty() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var enabledThresholds: [Int]"),
            "AppSettings must have an enabledThresholds computed property"
        )
    }

    func testThreshold50DefaultsToTrue() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold50Enabled: Bool = true"),
            "threshold50Enabled must default to true"
        )
    }

    func testThreshold75DefaultsToTrue() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold75Enabled: Bool = true"),
            "threshold75Enabled must default to true"
        )
    }

    func testThreshold90DefaultsToTrue() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold90Enabled: Bool = true"),
            "threshold90Enabled must default to true"
        )
    }

    // MARK: - SettingsView Observes NotificationService Tests

    func testSettingsViewObservesNotificationService() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("@ObservedObject") && source.contains("notificationService"),
            "SettingsView must observe NotificationService for authorization state"
        )
    }

    func testSettingsViewObservesAppSettings() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("@ObservedObject") && source.contains("AppSettings.shared"),
            "SettingsView must observe AppSettings for toggle bindings"
        )
    }
}
