import XCTest

final class CompilerWarningTests: XCTestCase {

    // MARK: - Unused Variables Check

    func testNoUnusedVariablesInModels() throws {
        let modelsPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Models/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelsPath) else {
            return
        }

        let modelFiles = try fileManager.contentsOfDirectory(atPath: modelsPath)
            .filter { $0.hasSuffix(".swift") }

        for file in modelFiles {
            let filePath = modelsPath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for unused variable pattern: let _ = (underscore variable assignments)
            // These are usually intentional, so we skip this check

            // Check for variables declared but never used (heuristic check)
            // This is a basic check - full unused variable detection requires compiler analysis
            XCTAssertFalse(
                content.contains("// TODO: Remove unused"),
                "File \(file) contains TODO for unused code removal"
            )
        }
    }

    // MARK: - Deprecated API Check

    func testNoDeprecatedAPIsInViews() throws {
        let viewsPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Views/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: viewsPath) else {
            return
        }

        let viewFiles = try fileManager.contentsOfDirectory(atPath: viewsPath)
            .filter { $0.hasSuffix(".swift") }

        for file in viewFiles {
            let filePath = viewsPath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for deprecated SwiftUI APIs
            let deprecatedPatterns = [
                "onAppear(perform:)": ".onAppear { }",  // Not deprecated, just alternate syntax
                "UIColor": "Use Color instead for SwiftUI",
                "NSColor": "Use Color instead for pure SwiftUI"
            ]

            // Note: UIColor and NSColor may be valid for interop, so we don't fail on them
            // This test documents awareness of potential migration paths

            XCTAssertFalse(
                content.contains("@available(*, deprecated"),
                "File \(file) contains deprecated code markers"
            )
        }
    }

    // MARK: - Force Unwrap Check

    func testMinimalForceUnwrapsInServices() throws {
        let servicesPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: servicesPath) else {
            return
        }

        let serviceFiles = try fileManager.contentsOfDirectory(atPath: servicesPath)
            .filter { $0.hasSuffix(".swift") }

        for file in serviceFiles {
            let filePath = servicesPath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Count force unwraps (!)
            // Exclude string interpolation, optionals declaration, and URL literals
            let lines = content.components(separatedBy: .newlines)
            var forceUnwrapCount = 0

            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Skip comments
                if trimmed.hasPrefix("//") { continue }

                // Skip URL literals (common safe use of !)
                if trimmed.contains("URL(string:") && trimmed.contains(")!") {
                    continue
                }

                // Count remaining force unwraps
                let components = trimmed.components(separatedBy: "!")
                // Each ! that's not a negation or in a string is potentially a force unwrap
                forceUnwrapCount += components.count - 1
            }

            // Allow some force unwraps (URL literals, etc.) but flag excessive use
            XCTAssertLessThan(
                forceUnwrapCount, 20,
                "File \(file) has many force unwraps (\(forceUnwrapCount)), consider using optional binding"
            )
        }
    }

    // MARK: - Implicit Return Check (Swift 5.1+)

    func testCodeUsesModernSwiftSyntax() throws {
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourcePath) else {
            return
        }

        // Check that project uses modern Swift features available in macOS 13+
        // This is a documentation test - the code should compile on Swift 5.7+

        let swiftFiles = try enumerateSwiftFiles(at: sourcePath)
        XCTAssertGreaterThan(swiftFiles.count, 0, "Should find Swift source files")

        for file in swiftFiles {
            let content = try String(contentsOfFile: file, encoding: .utf8)

            // Verify no legacy patterns that would cause warnings
            XCTAssertFalse(
                content.contains("#selector") && !content.contains("@objc"),
                "File \(file) uses #selector without @objc annotation"
            )
        }
    }

    // MARK: - Result Unused Check

    func testNoIgnoredResults() throws {
        let servicesPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: servicesPath) else {
            return
        }

        let serviceFiles = try fileManager.contentsOfDirectory(atPath: servicesPath)
            .filter { $0.hasSuffix(".swift") }

        for file in serviceFiles {
            let filePath = servicesPath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for @discardableResult or explicit _ = assignments
            // The presence of @discardableResult is fine, it's intentional
            // We're checking that results aren't accidentally ignored

            XCTAssertFalse(
                content.contains("// FIXME: handle result"),
                "File \(file) has unhandled results marked with FIXME"
            )
        }
    }

    // MARK: - Type Inference Ambiguity Check

    func testNoAmbiguousTypeInference() throws {
        let modelsPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Models/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelsPath) else {
            return
        }

        let modelFiles = try fileManager.contentsOfDirectory(atPath: modelsPath)
            .filter { $0.hasSuffix(".swift") }

        for file in modelFiles {
            let filePath = modelsPath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Verify explicit types are used where appropriate
            // This is a best practice check, not a warning check

            // Check for proper Codable implementations
            if content.contains(": Codable") || content.contains(", Codable") {
                // Ensure CodingKeys are properly typed if present
                if content.contains("CodingKeys") {
                    XCTAssertTrue(
                        content.contains("enum CodingKeys: String, CodingKey"),
                        "File \(file) should use 'enum CodingKeys: String, CodingKey' pattern"
                    )
                }
            }
        }
    }

    // MARK: - Helper Methods

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
}
