import XCTest
@testable import AIUsageBar

/// Tests for PRD US-010: Quit button in Settings view
/// Validates that the Settings view has a Quit button that terminates the app
final class QuitButtonTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - Quit Button Existence Tests

    func testQuitButtonExistsInSettingsView() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("Button(\"Quit\")"),
            "SettingsView must have a Quit button (PRD US-010)"
        )
    }

    func testQuitButtonCallsTerminate() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("NSApplication.shared.terminate(nil)"),
            "Quit button must call NSApplication.shared.terminate(nil) to quit the app (PRD US-010)"
        )
    }

    // MARK: - Quit Button Styling Tests

    func testQuitButtonUsesPlainStyle() throws {
        let source = try readSource("Views/SettingsView.swift")

        // Find the Quit button section and verify it uses plain button style
        let quitRange = source.range(of: "Button(\"Quit\")")
        XCTAssertNotNil(quitRange, "Quit button must exist")

        let afterQuit = String(source[quitRange!.upperBound...])
        XCTAssertTrue(
            afterQuit.hasPrefix(" {\n") || afterQuit.contains(".buttonStyle(.plain)"),
            "Quit button should use plain button style"
        )

        XCTAssertTrue(
            source.contains(".buttonStyle(.plain)"),
            "Quit button must use plain button style"
        )
    }

    func testQuitButtonUsesRedColor() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains(".foregroundStyle(.red)"),
            "Quit button must use red foreground color to indicate destructive action (PRD US-010)"
        )
    }

    // MARK: - Quit Button Placement Tests

    func testQuitButtonIsInFooter() throws {
        let source = try readSource("Views/SettingsView.swift")

        // Quit button should appear after Spacer() in the footer section
        guard let spacerRange = source.range(of: "Spacer()", options: .backwards) else {
            XCTFail("SettingsView must have a Spacer before the Quit button")
            return
        }
        guard let quitRange = source.range(of: "Button(\"Quit\")") else {
            XCTFail("SettingsView must have a Quit button")
            return
        }

        XCTAssertTrue(
            spacerRange.lowerBound < quitRange.lowerBound,
            "Quit button must appear after Spacer() in the footer HStack"
        )
    }

    func testQuitButtonIsAfterVersionLabel() throws {
        let source = try readSource("Views/SettingsView.swift")

        guard let versionRange = source.range(of: "v1.0.0") else {
            XCTFail("SettingsView must have a version label")
            return
        }
        guard let quitRange = source.range(of: "Button(\"Quit\")") else {
            XCTFail("SettingsView must have a Quit button")
            return
        }

        XCTAssertTrue(
            versionRange.lowerBound < quitRange.lowerBound,
            "Quit button must appear after version label in the footer"
        )
    }

    func testFooterHasVersionAndQuit() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("\"v1.0.0\"") && source.contains("Button(\"Quit\")"),
            "Footer must contain both version label and Quit button"
        )
    }

    // MARK: - Quit Button Behavior Tests

    func testQuitButtonTerminateUsesNilSender() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("terminate(nil)"),
            "terminate must be called with nil sender for clean shutdown"
        )
    }

    func testQuitButtonUsesNSApplication() throws {
        let source = try readSource("Views/SettingsView.swift")

        XCTAssertTrue(
            source.contains("NSApplication.shared"),
            "Quit button must use NSApplication.shared to access the app instance"
        )
    }
}
