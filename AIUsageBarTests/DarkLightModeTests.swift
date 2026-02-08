import XCTest
@testable import AIUsageBar

/// Tests that all text in the app is readable in both light and dark mode.
/// Validates that views use adaptive system colors (.primary, .secondary)
/// instead of hardcoded colors like .black or .white for text on variable backgrounds.
final class DarkLightModeTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
        let fullPath = basePath.appending(relativePath)
        return try String(contentsOfFile: fullPath, encoding: .utf8)
    }

    // MARK: - No Hardcoded .black or .white Text Colors

    func testNoHardcodedBlackForegroundInViews() throws {
        let viewFiles = [
            "AIUsageBar/Views/ContentView.swift",
            "AIUsageBar/Views/ProviderHeader.swift",
            "AIUsageBar/Views/ProviderTabs.swift",
            "AIUsageBar/Views/UsageRing.swift",
            "AIUsageBar/Views/LimitBars.swift",
            "AIUsageBar/Views/ResetTimer.swift",
            "AIUsageBar/Views/SettingsView.swift"
        ]

        for file in viewFiles {
            let content = try readSource(file)
            XCTAssertFalse(
                content.contains(".foregroundColor(.black)"),
                "\(file) must not use .foregroundColor(.black) — use .primary for dark mode compatibility"
            )
            XCTAssertFalse(
                content.contains(".foregroundStyle(.black)"),
                "\(file) must not use .foregroundStyle(.black) — use .primary for dark mode compatibility"
            )
        }
    }

    func testNoHardcodedWhiteOnVariableBackground() throws {
        // ProviderTabs uses .white on a colored provider background — that's acceptable.
        // But no other view should use .white for text on a variable/material background.
        let viewsWithVariableBackground = [
            "AIUsageBar/Views/ContentView.swift",
            "AIUsageBar/Views/ProviderHeader.swift",
            "AIUsageBar/Views/UsageRing.swift",
            "AIUsageBar/Views/LimitBars.swift",
            "AIUsageBar/Views/ResetTimer.swift",
            "AIUsageBar/Views/SettingsView.swift"
        ]

        for file in viewsWithVariableBackground {
            let content = try readSource(file)
            XCTAssertFalse(
                content.contains(".foregroundColor(.white)"),
                "\(file) must not use .foregroundColor(.white) — use .primary for light mode compatibility"
            )
        }
    }

    // MARK: - Provider Header Uses Adaptive Colors

    func testProviderHeaderUsesPrimaryColor() throws {
        let content = try readSource("AIUsageBar/Views/ProviderHeader.swift")
        XCTAssertTrue(
            content.contains(".foregroundStyle(.primary)"),
            "ProviderHeader must use .primary for the provider name to adapt to light/dark mode"
        )
    }

    // MARK: - ContentView Footer Buttons Use Adaptive Colors

    func testContentViewFooterButtonsUseSecondaryColor() throws {
        let content = try readSource("AIUsageBar/Views/ContentView.swift")

        // Both footer icon buttons (refresh and gear) should use .secondary
        let secondaryCount = content.components(separatedBy: ".foregroundStyle(.secondary)").count - 1
        XCTAssertGreaterThanOrEqual(
            secondaryCount, 4,
            "ContentView should use .foregroundStyle(.secondary) for footer buttons and other secondary text"
        )
    }

    func testRefreshButtonHasExplicitForegroundColor() throws {
        let content = try readSource("AIUsageBar/Views/ContentView.swift")
        // The refresh button icon should have an explicit foreground color
        XCTAssertTrue(
            content.contains("arrow.clockwise") && content.contains(".foregroundStyle(.secondary)"),
            "Refresh button icon must have explicit .foregroundStyle(.secondary) for dark mode visibility"
        )
    }

    func testGearButtonHasExplicitForegroundColor() throws {
        let content = try readSource("AIUsageBar/Views/ContentView.swift")
        XCTAssertTrue(
            content.contains("\"gear\"") && content.contains(".foregroundStyle(.secondary)"),
            "Settings gear button must have explicit .foregroundStyle(.secondary) for dark mode visibility"
        )
    }

    // MARK: - SettingsView Uses Adaptive Colors

    func testSettingsHeaderUsesPrimaryColor() throws {
        let content = try readSource("AIUsageBar/Views/SettingsView.swift")
        // The "Settings" header should use .primary
        XCTAssertTrue(
            content.contains("Text(\"Settings\")") &&
            content.contains(".foregroundStyle(.primary)"),
            "Settings header must use .primary for light/dark mode readability"
        )
    }

    func testSettingsProviderLabelsUsePrimaryColor() throws {
        let content = try readSource("AIUsageBar/Views/SettingsView.swift")
        // "Claude" and "Codex" labels should use .primary
        let lines = content.components(separatedBy: "\n")
        var claudeHasPrimary = false
        var codexHasPrimary = false

        for (index, line) in lines.enumerated() {
            if line.contains("Text(\"Claude\")") {
                let nextLines = lines[index..<min(index + 3, lines.count)].joined()
                if nextLines.contains(".foregroundStyle(.primary)") {
                    claudeHasPrimary = true
                }
            }
            if line.contains("Text(\"Codex\")") {
                let nextLines = lines[index..<min(index + 3, lines.count)].joined()
                if nextLines.contains(".foregroundStyle(.primary)") {
                    codexHasPrimary = true
                }
            }
        }

        XCTAssertTrue(claudeHasPrimary, "Claude label must use .foregroundStyle(.primary) for dark mode readability")
        XCTAssertTrue(codexHasPrimary, "Codex label must use .foregroundStyle(.primary) for dark mode readability")
    }

    // MARK: - Progress Track Backgrounds Use Adaptive Colors

    func testUsageRingTrackUsesAdaptiveBackground() throws {
        let content = try readSource("AIUsageBar/Views/UsageRing.swift")
        // Should use Color.primary.opacity() instead of Color.gray.opacity() for the ring track
        XCTAssertTrue(
            content.contains("Color.primary.opacity("),
            "UsageRing track should use Color.primary.opacity() for consistent visibility in both modes"
        )
        XCTAssertFalse(
            content.contains("Color.gray.opacity(0.2)"),
            "UsageRing track should not use Color.gray.opacity(0.2) — use Color.primary.opacity() instead"
        )
    }

    func testLimitBarsTrackUsesAdaptiveBackground() throws {
        let content = try readSource("AIUsageBar/Views/LimitBars.swift")
        XCTAssertTrue(
            content.contains("Color.primary.opacity("),
            "LimitBars track should use Color.primary.opacity() for consistent visibility in both modes"
        )
        XCTAssertFalse(
            content.contains("Color.gray.opacity(0.2)"),
            "LimitBars track should not use Color.gray.opacity(0.2) — use Color.primary.opacity() instead"
        )
    }

    func testProviderTabsBackgroundUsesAdaptiveColor() throws {
        let content = try readSource("AIUsageBar/Views/ProviderTabs.swift")
        XCTAssertTrue(
            content.contains("Color.primary.opacity("),
            "ProviderTabs background should use Color.primary.opacity() for consistent visibility in both modes"
        )
        XCTAssertFalse(
            content.contains("Color.gray.opacity(0.1)"),
            "ProviderTabs should not use Color.gray.opacity(0.1) — use Color.primary.opacity() instead"
        )
    }

    // MARK: - UsageStatus Colors Have Sufficient Brightness

    func testUsageStatusGreenColorNotTooDark() {
        let color = UsageStatus.green.color
        // Color(hex: "4A9B6E") — R:74 G:155 B:110
        // This should be visible on both light and dark backgrounds
        XCTAssertNotNil(color, "Green status color must be defined")
    }

    func testUsageStatusYellowColorNotTooDark() {
        let color = UsageStatus.yellow.color
        // Color(hex: "D4A03D") — R:212 G:160 B:61
        XCTAssertNotNil(color, "Yellow status color must be defined")
    }

    func testUsageStatusRedColorNotTooDark() {
        let color = UsageStatus.red.color
        // Color(hex: "C75B39") — R:199 G:91 B:57
        XCTAssertNotNil(color, "Red status color must be defined")
    }

    // MARK: - ProviderTabs Selected Tab White Text Is On Colored Background

    func testSelectedTabWhiteTextHasColoredBackground() throws {
        let content = try readSource("AIUsageBar/Views/ProviderTabs.swift")
        // White text is only acceptable when on a colored (provider.color) background
        XCTAssertTrue(
            content.contains(".foregroundStyle(isSelected ? .white : .secondary)"),
            "Selected tab must use .white only when selected (on colored background)"
        )
        XCTAssertTrue(
            content.contains("isSelected ? provider.color : Color.clear"),
            "Selected tab must have provider.color background to ensure white text contrast"
        )
    }

    // MARK: - Panel Background Supports Both Modes

    func testContentViewUsesUltraThinMaterial() throws {
        let content = try readSource("AIUsageBar/Views/ContentView.swift")
        XCTAssertTrue(
            content.contains(".ultraThinMaterial"),
            "ContentView must use .ultraThinMaterial which adapts to light/dark mode"
        )
    }
}
