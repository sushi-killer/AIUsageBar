import XCTest
import SwiftUI
@testable import AIUsageBar

final class ProviderTests: XCTestCase {
    func testProviderDisplayNames() {
        XCTAssertEqual(Provider.claude.displayName, "Claude")
        XCTAssertEqual(Provider.codex.displayName, "Codex")
    }

    func testProviderColors() {
        // Claude should be terracotta
        let claudeColor = Provider.claude.color
        XCTAssertNotNil(claudeColor)

        // Codex should be green
        let codexColor = Provider.codex.color
        XCTAssertNotNil(codexColor)
    }

    func testProviderWindowLabels() {
        // Both providers should have "5-Hour" as primary
        XCTAssertEqual(Provider.claude.primaryWindowLabel, "5-Hour")
        XCTAssertEqual(Provider.codex.primaryWindowLabel, "5-Hour")

        // Secondary labels differ
        XCTAssertEqual(Provider.claude.secondaryWindowLabel, "Weekly")
        XCTAssertEqual(Provider.codex.secondaryWindowLabel, "Weekly")
    }

    func testProviderLogsPath() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path

        XCTAssertTrue(Provider.claude.logsPath.contains(".claude/projects"))
        XCTAssertTrue(Provider.claude.logsPath.hasPrefix(home))

        XCTAssertTrue(Provider.codex.logsPath.contains(".codex/sessions"))
        XCTAssertTrue(Provider.codex.logsPath.hasPrefix(home))
    }

    func testProviderCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Test encoding
        let claudeData = try encoder.encode(Provider.claude)
        let codexData = try encoder.encode(Provider.codex)

        // Test decoding
        let decodedClaude = try decoder.decode(Provider.self, from: claudeData)
        let decodedCodex = try decoder.decode(Provider.self, from: codexData)

        XCTAssertEqual(decodedClaude, Provider.claude)
        XCTAssertEqual(decodedCodex, Provider.codex)
    }

    func testProviderIdentifiable() {
        XCTAssertEqual(Provider.claude.id, "claude")
        XCTAssertEqual(Provider.codex.id, "codex")
    }

    func testProviderAllCases() {
        let allCases = Provider.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.claude))
        XCTAssertTrue(allCases.contains(.codex))
    }
}
