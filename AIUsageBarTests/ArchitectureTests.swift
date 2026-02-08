import XCTest

final class ArchitectureTests: XCTestCase {

    // MARK: - Deployment Target Tests

    func testDeploymentTargetIsMacOS13() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            XCTFail("Project file not found")
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Verify deployment target is macOS 13.0 for both Intel and Apple Silicon compatibility
        XCTAssertTrue(
            content.contains("MACOSX_DEPLOYMENT_TARGET = 13.0"),
            "Deployment target should be macOS 13.0 for broad architecture support"
        )
    }

    // MARK: - Architecture Support Tests

    func testProjectSupportsUniversalBuild() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            XCTFail("Project file not found")
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Project should use SDKROOT = macosx which supports both architectures
        XCTAssertTrue(
            content.contains("SDKROOT = macosx"),
            "Project should target macOS SDK for universal binary support"
        )
    }

    func testRuntimeArchitecture() {
        #if arch(arm64)
        // Running on Apple Silicon
        XCTAssertTrue(true, "Running on Apple Silicon (arm64)")
        #elseif arch(x86_64)
        // Running on Intel
        XCTAssertTrue(true, "Running on Intel (x86_64)")
        #else
        XCTFail("Unknown architecture - project should support arm64 or x86_64")
        #endif
    }

    // MARK: - macOS 13.0 API Compatibility Tests

    func testNoMacOS14OnlyAPIsUsed() throws {
        // Validates that no source files use macOS 14+ APIs
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let swiftFiles = try enumerateSwiftFiles(at: sourcePath)
        XCTAssertGreaterThan(swiftFiles.count, 0, "Should find Swift source files")

        for filePath in swiftFiles {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let fileName = (filePath as NSString).lastPathComponent

            // macOS 14+ onChange API (two-parameter closure)
            let twoParamOnChangePattern = "\\.onChange\\(of:[^)]+\\)\\s*\\{\\s*\\w+\\s*,\\s*\\w+\\s+in"
            let regex = try NSRegularExpression(pattern: twoParamOnChangePattern)
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)
            XCTAssertEqual(
                matches.count, 0,
                "\(fileName) should not use macOS 14+ onChange API with two parameters"
            )

            // @Observable macro (macOS 14+)
            XCTAssertFalse(
                content.contains("@Observable"),
                "\(fileName) should not use @Observable macro (macOS 14+), use ObservableObject instead"
            )

            // @Bindable property wrapper (macOS 14+)
            XCTAssertFalse(
                content.contains("@Bindable"),
                "\(fileName) should not use @Bindable (macOS 14+), use @ObservedObject instead"
            )
        }
    }

    func testNoMacOS14OnlySwiftUIModifiers() throws {
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let swiftFiles = try enumerateSwiftFiles(at: sourcePath)

        // SwiftUI modifiers introduced in macOS 14+
        let macOS14Patterns = [
            ".scrollPosition(": "scrollPosition (macOS 14+)",
            ".containerRelativeFrame(": "containerRelativeFrame (macOS 14+)",
            ".inspector(": "inspector (macOS 14+)",
            ".sensoryFeedback(": "sensoryFeedback (macOS 14+)",
            ".symbolEffect(": "symbolEffect (macOS 14+)",
            ".phaseAnimator(": "phaseAnimator (macOS 14+)",
            ".keyframeAnimator(": "keyframeAnimator (macOS 14+)",
            ".scrollTargetBehavior(": "scrollTargetBehavior (macOS 14+)",
            ".scrollTargetLayout(": "scrollTargetLayout (macOS 14+)",
            ".contentMargins(": "contentMargins (macOS 14+)",
            "import SwiftData": "SwiftData framework (macOS 14+)",
            "import TipKit": "TipKit framework (macOS 14+)",
        ]

        for filePath in swiftFiles {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let fileName = (filePath as NSString).lastPathComponent

            for (pattern, description) in macOS14Patterns {
                XCTAssertFalse(
                    content.contains(pattern),
                    "\(fileName) uses \(description) which is not available on macOS 13"
                )
            }
        }
    }

    func testNoArchitectureExclusionsInProject() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // No architecture exclusions that would prevent Intel or Apple Silicon builds
        XCTAssertFalse(
            content.contains("EXCLUDED_ARCHS"),
            "Project should not exclude any architectures for universal binary support"
        )
    }

    func testInfoPlistMinimumSystemVersion() throws {
        let plistPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Info.plist")

        let content = try String(contentsOfFile: plistPath, encoding: .utf8)

        XCTAssertTrue(
            content.contains("LSMinimumSystemVersion"),
            "Info.plist must declare LSMinimumSystemVersion"
        )
        XCTAssertTrue(
            content.contains("$(MACOSX_DEPLOYMENT_TARGET)"),
            "LSMinimumSystemVersion should reference MACOSX_DEPLOYMENT_TARGET"
        )
    }

    func testDeploymentTargetConsistentAcrossConfigs() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Count deployment target declarations - all should be 13.0
        let targetPattern = try NSRegularExpression(pattern: "MACOSX_DEPLOYMENT_TARGET = (\\d+\\.\\d+)")
        let range = NSRange(content.startIndex..., in: content)
        let matches = targetPattern.matches(in: content, options: [], range: range)

        XCTAssertGreaterThan(matches.count, 0, "Should find deployment target declarations")

        for match in matches {
            let versionRange = Range(match.range(at: 1), in: content)!
            let version = String(content[versionRange])
            XCTAssertEqual(
                version, "13.0",
                "All deployment targets should be 13.0, found \(version)"
            )
        }
    }

    func testSwiftVersionCompatibility() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Verify Swift version is 5.0 which is available on both architectures
        XCTAssertTrue(
            content.contains("SWIFT_VERSION = 5.0"),
            "Swift version should be 5.0 for cross-architecture compatibility"
        )
    }

    // MARK: - Helpers

    private func enumerateSwiftFiles(at path: String) throws -> [String] {
        let fileManager = FileManager.default
        var swiftFiles: [String] = []
        let contents = try fileManager.contentsOfDirectory(atPath: path)
        for item in contents {
            let itemPath = (path as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    swiftFiles += try enumerateSwiftFiles(at: itemPath)
                } else if item.hasSuffix(".swift") {
                    swiftFiles.append(itemPath)
                }
            }
        }
        return swiftFiles
    }

    // MARK: - Release Configuration Tests

    func testReleaseConfigurationExists() throws {
        let projectPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar.xcodeproj/project.pbxproj")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: String(projectPath)) else {
            return
        }

        let content = try String(contentsOfFile: String(projectPath), encoding: .utf8)

        // Verify both Debug and Release configurations exist
        XCTAssertTrue(content.contains("name = Debug"), "Debug configuration should exist")
        XCTAssertTrue(content.contains("name = Release"), "Release configuration should exist")

        // Release should be the default
        XCTAssertTrue(
            content.contains("defaultConfigurationName = Release"),
            "Release should be the default configuration"
        )
    }
}
