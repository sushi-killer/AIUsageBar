import XCTest
@testable import AIUsageBar

/// Tests for PRD US-008: Header showing active provider name
/// Validates that the panel displays a header with the active provider name
final class ProviderHeaderTests: XCTestCase {

    // MARK: - ProviderHeader Component Tests

    func testProviderHeaderFileExists() throws {
        // Verify ProviderHeader.swift exists
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let fileManager = FileManager.default
        XCTAssertTrue(
            fileManager.fileExists(atPath: headerPath),
            "ProviderHeader.swift must exist for header component (PRD US-008)"
        )
    }

    func testProviderHeaderIsSwiftUIView() throws {
        // Verify ProviderHeader conforms to View protocol
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let content = try String(contentsOfFile: headerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("struct ProviderHeader: View"),
            "ProviderHeader must be a SwiftUI View"
        )
    }

    func testProviderHeaderAcceptsProvider() throws {
        // Verify ProviderHeader takes a provider parameter
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let content = try String(contentsOfFile: headerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("let provider: Provider"),
            "ProviderHeader must accept a Provider parameter to display the active provider"
        )
    }

    func testProviderHeaderDisplaysProviderName() throws {
        // Verify ProviderHeader displays the provider's display name
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let content = try String(contentsOfFile: headerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("provider.displayName"),
            "ProviderHeader must display the provider's display name (PRD US-008)"
        )
    }

    func testProviderHeaderUsesHeadlineFont() throws {
        // Verify ProviderHeader uses headline font for prominence
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let content = try String(contentsOfFile: headerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains(".font(.headline)"),
            "ProviderHeader should use headline font for visual prominence"
        )
    }

    // MARK: - ContentView Integration Tests

    func testContentViewUsesProviderHeader() throws {
        // Verify ContentView uses the ProviderHeader component
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("ProviderHeader("),
            "ContentView must use ProviderHeader component for the panel header (PRD US-008)"
        )
    }

    func testContentViewPassesSelectedProviderToHeader() throws {
        // Verify ContentView passes the selected provider to the header
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("provider: selectedProvider"),
            "ContentView must pass the selected provider to ProviderHeader"
        )
    }

    // MARK: - PRD Comment Documentation Tests

    func testProviderHeaderHasPRDReference() throws {
        // Verify ProviderHeader has PRD US-008 reference
        let headerPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ProviderHeader.swift")

        let content = try String(contentsOfFile: headerPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("PRD US-008"),
            "ProviderHeader should reference PRD US-008 for traceability"
        )
    }

    func testContentViewHeaderCommentReferencesPRD() throws {
        // Verify ContentView header section references PRD US-008
        let contentViewPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/ContentView.swift")

        let content = try String(contentsOfFile: contentViewPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("PRD US-008") || content.contains("Header showing active provider name"),
            "ContentView should document the header requirement (PRD US-008)"
        )
    }

    // MARK: - Provider Display Name Tests

    func testClaudeProviderHasDisplayName() {
        // Verify Claude provider has a proper display name
        XCTAssertEqual(Provider.claude.displayName, "Claude")
    }

    func testCodexProviderHasDisplayName() {
        // Verify Codex provider has a proper display name
        XCTAssertEqual(Provider.codex.displayName, "Codex")
    }
}
