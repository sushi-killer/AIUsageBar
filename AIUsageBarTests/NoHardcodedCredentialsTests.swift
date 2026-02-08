import XCTest

final class NoHardcodedCredentialsTests: XCTestCase {

    // MARK: - Test Data

    private let credentialPatterns: [(pattern: String, description: String)] = [
        // API Keys
        ("sk-[a-zA-Z0-9]{20,}", "OpenAI/Anthropic style API key"),
        ("AKIA[0-9A-Z]{16}", "AWS Access Key ID"),
        ("AIza[0-9A-Za-z\\-_]{35}", "Google API Key"),

        // Tokens and secrets - only match actual token values, not variable names or JSON keys
        ("Bearer\\s+[A-Za-z0-9\\-_\\.]{20,}", "Bearer token with actual value"),

        // OAuth/JWT patterns - only match quoted string values
        ("\"ey[A-Za-z0-9\\-_]+\\.[A-Za-z0-9\\-_]+\\.[A-Za-z0-9\\-_]+\"", "JWT token as string value"),

        // Database connection strings with embedded credentials
        ("://[^:]+:[^@]+@[a-zA-Z0-9]", "Connection string with embedded credentials"),

        // Private keys
        ("-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----", "Private key header"),
    ]

    private let excludedPaths: [String] = [
        "Tests",
        ".xcodeproj",
        ".git",
        "build",
        "DerivedData"
    ]

    // MARK: - Source Code Credential Tests

    func testNoHardcodedCredentialsInSourceFiles() throws {
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let violations = try scanDirectory(at: sourcePath, fileExtension: ".swift")

        XCTAssertTrue(
            violations.isEmpty,
            "Found potential hardcoded credentials:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testNoHardcodedCredentialsInInfoPlist() throws {
        let basePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]

        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(atPath: basePath)

        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".plist"),
                  !excludedPaths.contains(where: { file.contains($0) }) else {
                continue
            }

            let filePath = basePath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            for (pattern, description) in credentialPatterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(content.startIndex..., in: content)
                let matches = regex.matches(in: content, options: [], range: range)

                XCTAssertEqual(
                    matches.count, 0,
                    "File \(file) may contain hardcoded credentials: \(description)"
                )
            }
        }
    }

    // MARK: - Service File Specific Tests

    func testKeychainServiceDoesNotContainHardcodedTokens() throws {
        let keychainServicePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/KeychainService.swift")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: keychainServicePath) else {
            return
        }

        let content = try String(contentsOfFile: keychainServicePath, encoding: .utf8)

        // Verify no hardcoded access tokens
        XCTAssertFalse(
            content.contains(#"accessToken: ""#) && content.contains(#"sk-"#),
            "KeychainService should not contain hardcoded access tokens"
        )

        // Verify credentials come from Keychain, not hardcoded
        XCTAssertTrue(
            content.contains("SecItemCopyMatching"),
            "KeychainService should use SecItemCopyMatching to retrieve credentials"
        )
    }

    func testClaudeProviderUsesKeychainForAuth() throws {
        let claudeProviderPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/ClaudeProvider.swift")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: claudeProviderPath) else {
            return
        }

        let content = try String(contentsOfFile: claudeProviderPath, encoding: .utf8)

        // Verify provider uses KeychainService for credentials
        XCTAssertTrue(
            content.contains("keychainService") || content.contains("KeychainService"),
            "ClaudeProvider should use KeychainService for credential retrieval"
        )

        // Verify Bearer token is constructed dynamically
        XCTAssertTrue(
            content.contains("Bearer \\(") || content.contains("Bearer \\(credentials"),
            "ClaudeProvider should construct Bearer token from dynamic credentials"
        )

        // Verify no hardcoded Bearer tokens
        let hardcodedBearerPattern = "Bearer [a-zA-Z0-9\\-_]{20,}"
        let regex = try NSRegularExpression(pattern: hardcodedBearerPattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, options: [], range: range)

        XCTAssertEqual(
            matches.count, 0,
            "ClaudeProvider should not contain hardcoded Bearer tokens"
        )
    }

    func testNoAPIKeysInProviderFiles() throws {
        let servicesPath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/Services/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: servicesPath) else {
            return
        }

        let serviceFiles = try fileManager.contentsOfDirectory(atPath: servicesPath)
            .filter { $0.hasSuffix(".swift") && $0.contains("Provider") }

        for serviceFile in serviceFiles {
            let filePath = servicesPath + serviceFile
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for Anthropic API key pattern
            let anthropicKeyPattern = "sk-ant-[a-zA-Z0-9\\-_]{20,}"
            let regex = try NSRegularExpression(pattern: anthropicKeyPattern)
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            XCTAssertEqual(
                matches.count, 0,
                "\(serviceFile) should not contain hardcoded Anthropic API keys"
            )
        }
    }

    // MARK: - Environment Variable Tests

    func testNoHardcodedEnvironmentValues() throws {
        let sourcePath = #filePath
            .components(separatedBy: "AIUsageBarTests")[0]
            .appending("AIUsageBar/")

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: sourcePath) else {
            return
        }

        let enumerator = fileManager.enumerator(atPath: sourcePath)

        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".swift"),
                  !excludedPaths.contains(where: { file.contains($0) }) else {
                continue
            }

            let filePath = sourcePath + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for patterns like API_KEY = "actual_value"
            let envPattern = "(API_KEY|SECRET|PASSWORD|TOKEN)\\s*=\\s*\"[^\"]{10,}\""
            let regex = try NSRegularExpression(pattern: envPattern, options: .caseInsensitive)
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            XCTAssertEqual(
                matches.count, 0,
                "File \(file) may contain hardcoded environment values"
            )
        }
    }

    // MARK: - Helper Methods

    private func scanDirectory(at path: String, fileExtension: String) throws -> [String] {
        var violations: [String] = []
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: path) else {
            return violations
        }

        let enumerator = fileManager.enumerator(atPath: path)

        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(fileExtension),
                  !excludedPaths.contains(where: { file.contains($0) }) else {
                continue
            }

            let filePath = path + file
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            for (pattern, description) in credentialPatterns {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(content.startIndex..., in: content)
                let matches = regex.matches(in: content, options: [], range: range)

                for match in matches {
                    if let swiftRange = Range(match.range, in: content) {
                        let matchedText = String(content[swiftRange])
                        violations.append("[\(file)] \(description): \(matchedText)")
                    }
                }
            }
        }

        return violations
    }
}
