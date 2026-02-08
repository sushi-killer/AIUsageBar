import XCTest
@testable import AIUsageBar

/// Tests for PRD US-010: Threshold sliders or pickers: 50%, 75%, 90%
/// Validates that users can configure threshold values via picker controls in Settings
final class ThresholdPickerTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Settings Model: Threshold Value Properties

    func testThreshold50ValuePropertyExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("threshold50Value"),
            "AppSettings must have a threshold50Value property for configurable threshold"
        )
    }

    func testThreshold75ValuePropertyExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("threshold75Value"),
            "AppSettings must have a threshold75Value property for configurable threshold"
        )
    }

    func testThreshold90ValuePropertyExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("threshold90Value"),
            "AppSettings must have a threshold90Value property for configurable threshold"
        )
    }

    func testThreshold50ValueUsesAppStorage() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"threshold50Value\")"),
            "threshold50Value must use @AppStorage for persistence"
        )
    }

    func testThreshold75ValueUsesAppStorage() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"threshold75Value\")"),
            "threshold75Value must use @AppStorage for persistence"
        )
    }

    func testThreshold90ValueUsesAppStorage() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("@AppStorage(\"threshold90Value\")"),
            "threshold90Value must use @AppStorage for persistence"
        )
    }

    func testThreshold50ValueDefaultsTo50() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold50Value: Int = 50"),
            "threshold50Value must default to 50"
        )
    }

    func testThreshold75ValueDefaultsTo75() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold75Value: Int = 75"),
            "threshold75Value must default to 75"
        )
    }

    func testThreshold90ValueDefaultsTo90() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("var threshold90Value: Int = 90"),
            "threshold90Value must default to 90"
        )
    }

    func testThresholdValuesAreIntType() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("threshold50Value: Int") &&
            source.contains("threshold75Value: Int") &&
            source.contains("threshold90Value: Int"),
            "All threshold values must be Int type"
        )
    }

    // MARK: - Settings Model: enabledThresholds Uses Values

    func testEnabledThresholdsUsesConfigurableValues() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("thresholds.append(threshold50Value)") &&
            source.contains("thresholds.append(threshold75Value)") &&
            source.contains("thresholds.append(threshold90Value)"),
            "enabledThresholds must use configurable threshold values, not hardcoded 50/75/90"
        )
    }

    // MARK: - Settings Model: Threshold Options

    func testThresholdOptionsExists() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("thresholdOptions"),
            "AppSettings must have a thresholdOptions static property for picker options"
        )
    }

    func testThresholdOptionsIsStaticArray() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("static let thresholdOptions: [Int]"),
            "thresholdOptions must be a static let of [Int]"
        )
    }

    func testThresholdOptionsStartsAt10() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("from: 10"),
            "thresholdOptions must start from 10%"
        )
    }

    func testThresholdOptionsEndsAt100() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("through: 100"),
            "thresholdOptions must go through 100%"
        )
    }

    func testThresholdOptionsStepBy5() throws {
        let source = try readSource("Models/Settings.swift")

        XCTAssertTrue(
            source.contains("by: 5"),
            "thresholdOptions must step by 5% increments"
        )
    }

    // MARK: - SettingsView: ThresholdPickerRow Usage

    func testSettingsViewUsesThresholdPickerRow() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("ThresholdPickerRow("),
            "SettingsView must use ThresholdPickerRow components for threshold configuration"
        )
    }

    func testLowThresholdPickerRow() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("label: \"Low\"") &&
            source.contains("isEnabled: $settings.threshold50Enabled") &&
            source.contains("value: $settings.threshold50Value"),
            "SettingsView must have a Low threshold picker row bound to threshold50"
        )
    }

    func testMediumThresholdPickerRow() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("label: \"Medium\"") &&
            source.contains("isEnabled: $settings.threshold75Enabled") &&
            source.contains("value: $settings.threshold75Value"),
            "SettingsView must have a Medium threshold picker row bound to threshold75"
        )
    }

    func testHighThresholdPickerRow() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("label: \"High\"") &&
            source.contains("isEnabled: $settings.threshold90Enabled") &&
            source.contains("value: $settings.threshold90Value"),
            "SettingsView must have a High threshold picker row bound to threshold90"
        )
    }

    // MARK: - ThresholdPickerRow Component

    func testThresholdPickerRowStructExists() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("struct ThresholdPickerRow: View"),
            "ThresholdPickerRow must be a SwiftUI View struct"
        )
    }

    func testThresholdPickerRowHasLabelProperty() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("let label: String"),
            "ThresholdPickerRow must have a label property"
        )
    }

    func testThresholdPickerRowHasIsEnabledBinding() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("@Binding var isEnabled: Bool"),
            "ThresholdPickerRow must have an isEnabled binding"
        )
    }

    func testThresholdPickerRowHasValueBinding() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("@Binding var value: Int"),
            "ThresholdPickerRow must have a value binding"
        )
    }

    func testThresholdPickerRowHasToggle() throws {
        let source = try readSource("Views/SettingsView.swift")

        // Check within ThresholdPickerRow context
        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains("Toggle(isOn: $isEnabled)"),
            "ThresholdPickerRow must have a Toggle bound to isEnabled"
        )
    }

    func testThresholdPickerRowHasPicker() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains("Picker(\"\", selection: $value)"),
            "ThresholdPickerRow must have a Picker bound to value"
        )
    }

    func testThresholdPickerRowUsesMenuStyle() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains(".pickerStyle(.menu)"),
            "ThresholdPickerRow Picker must use menu style"
        )
    }

    func testThresholdPickerRowDisabledWhenNotEnabled() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains(".disabled(!isEnabled)"),
            "ThresholdPickerRow Picker must be disabled when threshold is not enabled"
        )
    }

    func testThresholdPickerRowUsesThresholdOptions() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains("AppSettings.thresholdOptions"),
            "ThresholdPickerRow must use AppSettings.thresholdOptions for picker options"
        )
    }

    func testThresholdPickerRowDisplaysPercentage() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains("\\(option)%"),
            "ThresholdPickerRow must display percentage values with % suffix"
        )
    }

    func testThresholdPickerRowToggleUsesSwitchStyle() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains(".toggleStyle(.switch)"),
            "ThresholdPickerRow toggle must use switch style"
        )
    }

    func testThresholdPickerRowUsesSmallControlSize() throws {
        let source = try readSource("Views/SettingsView.swift")

        let pickerRowRange = source.range(of: "struct ThresholdPickerRow")!
        let pickerRowSource = String(source[pickerRowRange.lowerBound...])

        XCTAssertTrue(
            pickerRowSource.contains(".controlSize(.small)"),
            "ThresholdPickerRow must use small control size"
        )
    }
}
