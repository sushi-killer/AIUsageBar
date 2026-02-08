import XCTest
@testable import AIUsageBar

/// Tests for PRD US-007: Click opens panel below icon
/// Validates that the menu bar uses window style for panel display
final class MenuBarPanelTests: XCTestCase {

    // MARK: - MenuBarExtra Configuration Tests

    func testMenuBarExtraUsesWindowStyle() throws {
        // The app must use .menuBarExtraStyle(.window) to show panel below icon
        // This is verified by checking the source code
        let appPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBarApp.swift")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: appPath) else {
            XCTFail("AIUsageBarApp.swift not found")
            return
        }

        let content = try String(contentsOfFile: appPath, encoding: .utf8)

        // Verify MenuBarExtra uses .window style for panel display
        XCTAssertTrue(
            content.contains(".menuBarExtraStyle(.window)"),
            "MenuBarExtra must use .window style to display panel below icon (PRD US-007)"
        )
    }

    func testMenuBarExtraHasContentView() throws {
        // Verify the panel shows ContentView when clicked
        let appPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBarApp.swift")

        let content = try String(contentsOfFile: appPath, encoding: .utf8)

        // MenuBarExtra should have ContentView as its content
        XCTAssertTrue(
            content.contains("MenuBarExtra {"),
            "MenuBarExtra should be defined with content closure"
        )
        XCTAssertTrue(
            content.contains("ContentView()"),
            "MenuBarExtra should display ContentView when panel opens"
        )
    }

    func testMenuBarExtraHasLabel() throws {
        // Verify the menu bar has a label for the icon
        let appPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBarApp.swift")

        let content = try String(contentsOfFile: appPath, encoding: .utf8)

        // MenuBarExtra should have a label
        XCTAssertTrue(
            content.contains("} label: {"),
            "MenuBarExtra should have a label closure for the icon"
        )
        XCTAssertTrue(
            content.contains("MenuBarLabel("),
            "MenuBarExtra should use MenuBarLabel for the icon"
        )
    }

    // MARK: - Window Style Behavior Tests

    func testWindowStyleNotMenuStyle() throws {
        // Verify the app does NOT use .menu style (which would show a dropdown menu)
        let appPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBarApp.swift")

        let content = try String(contentsOfFile: appPath, encoding: .utf8)

        // Should not use .menu style
        XCTAssertFalse(
            content.contains(".menuBarExtraStyle(.menu)"),
            "MenuBarExtra should use .window style, not .menu style"
        )
    }

    // MARK: - API Compatibility Tests

    func testMenuBarExtraAPIMacOS13Compatible() throws {
        // MenuBarExtra API was introduced in macOS 13.0
        // This test verifies we're using the correct API
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .dropLast()
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Deployment target must be at least macOS 13.0 for MenuBarExtra
        XCTAssertTrue(
            content.contains("MACOSX_DEPLOYMENT_TARGET = 13.0"),
            "Deployment target must be macOS 13.0+ for MenuBarExtra API"
        )
    }

    // MARK: - Panel Structure Tests

    func testContentViewExistsForPanel() throws {
        // Verify ContentView.swift exists and provides the panel content
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let fileManager = FileManager.default
        XCTAssertTrue(
            fileManager.fileExists(atPath: contentViewPath),
            "ContentView.swift must exist to provide panel content"
        )
    }

    func testContentViewIsSwiftUIView() throws {
        // Verify ContentView conforms to View protocol
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("struct ContentView: View"),
            "ContentView must be a SwiftUI View"
        )
    }

    // MARK: - Panel Dimension Tests

    func testPanelWidthIs320Pixels() throws {
        // PRD US-007: Panel width: 320px
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // Verify ContentView has frame width of 320
        XCTAssertTrue(
            content.contains(".frame(width: 320)"),
            "Panel must have width of 320px (PRD US-007)"
        )
    }

    // MARK: - Panel Visual Style Tests

    func testPanelUsesUltraThinMaterialBackground() throws {
        // PRD US-007: Panel uses .ultraThinMaterial background (frosted glass)
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // Verify ContentView uses ultraThinMaterial for frosted glass effect
        XCTAssertTrue(
            content.contains(".background(.ultraThinMaterial)"),
            "Panel must use .ultraThinMaterial background for frosted glass effect (PRD US-007)"
        )
    }

    func testPanelHas12pxRoundedCorners() throws {
        // PRD US-007: Panel has 12px rounded corners
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        // Verify ContentView uses 12px rounded corners via clipShape
        XCTAssertTrue(
            content.contains(".clipShape(RoundedRectangle(cornerRadius: 12))"),
            "Panel must have 12px rounded corners (PRD US-007)"
        )
    }

    // MARK: - Panel Dismiss Behavior Tests

    func testClickOutsidePanelClosesIt() throws {
        // PRD US-007: Click outside panel closes it
        // This behavior is provided automatically by MenuBarExtra with .window style
        // When using .menuBarExtraStyle(.window), clicking outside the panel dismisses it
        // This is standard macOS behavior for MenuBarExtra windows
        let appPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBarApp.swift")

        let content = try String(contentsOfFile: appPath, encoding: .utf8)

        // The .window style provides automatic click-outside-to-close behavior
        // This is a built-in feature of SwiftUI's MenuBarExtra when using window style
        XCTAssertTrue(
            content.contains(".menuBarExtraStyle(.window)"),
            "MenuBarExtra must use .window style which provides click-outside-to-close behavior (PRD US-007)"
        )

        // Additionally verify we're NOT using .menu style (which doesn't have this behavior)
        XCTAssertFalse(
            content.contains(".menuBarExtraStyle(.menu)"),
            "MenuBarExtra should not use .menu style - .window style provides click-outside-to-close"
        )
    }
}
