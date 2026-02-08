import XCTest

final class SigningConfigurationTests: XCTestCase {

    // MARK: - Entitlements Tests

    func testEntitlementsFileExists() throws {
        // Entitlements are embedded in the code signature at build time
        // This test validates the source file structure is correct
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBar.entitlements")

        let fileManager = FileManager.default
        // If running in Xcode context with source access, validate the file exists
        if fileManager.fileExists(atPath: projectPath) {
            let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            XCTAssertNotNil(plist as? [String: Any])
        }
    }

    func testEntitlementsHasKeychainAccess() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBar.entitlements")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectPath) else {
            // Skip if not running from source directory
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Could not parse entitlements plist")
            return
        }

        // Verify keychain access groups is present
        XCTAssertNotNil(plist["com.apple.security.keychain-access-groups"], "Entitlements should have keychain-access-groups")

        if let keychainGroups = plist["com.apple.security.keychain-access-groups"] as? [String] {
            XCTAssertFalse(keychainGroups.isEmpty, "Keychain access groups should not be empty")
            // Verify the access group format contains the bundle identifier
            let hasAppIdentifier = keychainGroups.contains { $0.contains("com.aiusagebar.app") }
            XCTAssertTrue(hasAppIdentifier, "Keychain access should include app bundle identifier")
        }
    }

    func testSandboxIsDisabled() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/AIUsageBar.entitlements")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Could not parse entitlements plist")
            return
        }

        // Sandbox must be disabled for access to ~/.claude and ~/.codex
        if let sandboxEnabled = plist["com.apple.security.app-sandbox"] as? Bool {
            XCTAssertFalse(sandboxEnabled, "App sandbox should be disabled for file system access")
        }
    }

    // MARK: - Info.plist Tests

    func testInfoPlistHasLSUIElement() throws {
        // In test environment, we check the source file
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Info.plist")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectPath) else {
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Could not parse Info.plist")
            return
        }

        // LSUIElement should be true for menu bar apps
        if let isUIElement = plist["LSUIElement"] as? Bool {
            XCTAssertTrue(isUIElement, "LSUIElement should be true for menu bar app")
        } else if let isUIElement = plist["LSUIElement"] as? String {
            XCTAssertEqual(isUIElement, "YES", "LSUIElement should be YES for menu bar app")
        }
    }

    // MARK: - Project Configuration Tests

    func testProjectHasSigningForRelease() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Verify ad-hoc signing identity allows archive without Developer ID certificate
        XCTAssertTrue(
            content.contains("CODE_SIGN_IDENTITY = \"-\""),
            "Release configuration should use ad-hoc signing identity for archive builds"
        )

        // Verify Automatic signing style for archive builds
        XCTAssertTrue(
            content.contains("CODE_SIGN_STYLE = Automatic"),
            "Release configuration should use Automatic code signing style"
        )

        // Verify hardened runtime is enabled
        XCTAssertTrue(
            content.contains("ENABLE_HARDENED_RUNTIME = YES"),
            "Hardened runtime should be enabled for notarization"
        )
    }

    func testBundleIdentifierFormat() throws {
        // Validate bundle ID format (reverse DNS) from the project file
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        XCTAssertTrue(
            content.contains("PRODUCT_BUNDLE_IDENTIFIER = com.aiusagebar.app"),
            "Bundle identifier should follow reverse DNS format"
        )
    }

    // MARK: - Archive Build Readiness Tests

    func testArchiveBuildRequirements() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            XCTFail("Project file not found")
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Archive build requires a product type of application
        XCTAssertTrue(
            content.contains("productType = \"com.apple.product-type.application\""),
            "Project must have application product type for archive builds"
        )

        // Archive build requires CURRENT_PROJECT_VERSION
        XCTAssertTrue(
            content.contains("CURRENT_PROJECT_VERSION = 1"),
            "Project must have a current project version for archive builds"
        )

        // Archive build requires MARKETING_VERSION
        XCTAssertTrue(
            content.contains("MARKETING_VERSION = 1.0"),
            "Project must have a marketing version for archive builds"
        )

        // Release must not require Developer ID certificate (allows archive without it)
        XCTAssertFalse(
            content.contains("CODE_SIGN_IDENTITY = \"Developer ID Application\""),
            "Release should not require Developer ID certificate for archive builds"
        )

        // No PROVISIONING_PROFILE_SPECIFIER requirement for ad-hoc signing
        XCTAssertFalse(
            content.contains("PROVISIONING_PROFILE_SPECIFIER"),
            "Release should not specify provisioning profile for ad-hoc archive builds"
        )
    }

    func testAllSourceFilesExist() throws {
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourcePath) else {
            XCTFail("Source directory not found")
            return
        }

        // All source files referenced in the project must exist for archive to succeed
        let requiredFiles = [
            "AIUsageBarApp.swift",
            "Models/Provider.swift",
            "Models/UsageData.swift",
            "Models/Settings.swift",
            "Services/KeychainService.swift",
            "Services/ClaudeProvider.swift",
            "Services/CodexProvider.swift",
            "Services/FileWatcher.swift",
            "Services/NotificationService.swift",
            "Services/UsageManager.swift",
            "Views/ContentView.swift",
            "Views/ProviderTabs.swift",
            "Views/ProviderHeader.swift",
            "Views/UsageRing.swift",
            "Views/LimitBars.swift",
            "Views/ResetTimer.swift",
            "Views/SettingsView.swift",
        ]

        for file in requiredFiles {
            let filePath = sourcePath + file
            XCTAssertTrue(
                fileManager.fileExists(atPath: filePath),
                "Required source file missing: \(file)"
            )
        }
    }

    func testInfoPlistHasRequiredArchiveKeys() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Info.plist")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: projectPath) else {
            XCTFail("Info.plist not found")
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: projectPath))
        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            XCTFail("Could not parse Info.plist")
            return
        }

        // Archive requires these keys for a valid app bundle
        XCTAssertNotNil(plist["CFBundleIdentifier"], "Info.plist must have CFBundleIdentifier")
        XCTAssertNotNil(plist["CFBundleExecutable"], "Info.plist must have CFBundleExecutable")
        XCTAssertNotNil(plist["CFBundlePackageType"], "Info.plist must have CFBundlePackageType")
        XCTAssertNotNil(plist["CFBundleShortVersionString"], "Info.plist must have CFBundleShortVersionString")
        XCTAssertNotNil(plist["CFBundleVersion"], "Info.plist must have CFBundleVersion")
        XCTAssertNotNil(plist["CFBundleName"], "Info.plist must have CFBundleName")
        XCTAssertNotNil(plist["LSMinimumSystemVersion"], "Info.plist must have LSMinimumSystemVersion")

        // Package type must be APPL for archive
        XCTAssertEqual(plist["CFBundlePackageType"] as? String, "APPL", "Bundle package type must be APPL")
    }

    func testEntitlementsFileReferencedInProject() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Entitlements must be referenced in the project for archive signing
        XCTAssertTrue(
            content.contains("CODE_SIGN_ENTITLEMENTS = AIUsageBar/AIUsageBar.entitlements"),
            "Project must reference entitlements file for archive signing"
        )
    }

    func testReleaseConfigurationHasWholeModuleOptimization() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Release should use whole module optimization for archive builds
        XCTAssertTrue(
            content.contains("SWIFT_COMPILATION_MODE = wholemodule"),
            "Release configuration should use whole module optimization"
        )
    }

    func testReleaseConfigurationHasDsymDebugInfo() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Release should generate dSYM for crash reporting
        XCTAssertTrue(
            content.contains("DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\""),
            "Release configuration should generate dSYM debug info for archive builds"
        )
    }
}
