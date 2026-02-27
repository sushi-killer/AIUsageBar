import Foundation
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "ClaudeProvider")

struct ClaudeAPIResponse: Codable {
    let fiveHour: UsageWindowResponse?
    let sevenDay: UsageWindowResponse?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

struct UsageWindowResponse: Codable {
    let utilization: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ClaudeLogEntry: Codable {
    let message: MessageContent?
    let timestamp: String?

    struct MessageContent: Codable {
        let usage: TokenUsage?
    }

    struct TokenUsage: Codable {
        let inputTokens: Int?
        let outputTokens: Int?
        let cacheCreationInputTokens: Int?
        let cacheReadInputTokens: Int?

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
            case cacheCreationInputTokens = "cache_creation_input_tokens"
            case cacheReadInputTokens = "cache_read_input_tokens"
        }

        var totalTokens: Int {
            (inputTokens ?? 0) + (outputTokens ?? 0) +
            (cacheCreationInputTokens ?? 0) + (cacheReadInputTokens ?? 0)
        }
    }
}

struct ClaudeProfileResponse: Codable {
    let organization: ClaudeOrganization?
}

struct ClaudeOrganization: Codable {
    let organizationType: String?
    let rateLimitTier: String?

    enum CodingKeys: String, CodingKey {
        case organizationType = "organization_type"
        case rateLimitTier = "rate_limit_tier"
    }
}

actor ClaudeProvider {
    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let profileURL = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    private let keychainService = KeychainService.shared

    /// Session-level guard: once we've retried after a 401, don't retry again
    /// until a successful response proves the credentials are valid.
    private var hasRetriedAfterAuthError = false

    /// Cached plan label so we don't hit the profile API every refresh
    private var cachedPlanLabel: String?
    private var planLabelCachedAt: Date?
    private static let planLabelTTL: TimeInterval = 3600

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func getPlanLabel() async -> String? {
        if let cached = cachedPlanLabel,
           let cachedAt = planLabelCachedAt,
           Date().timeIntervalSince(cachedAt) < Self.planLabelTTL {
            return cached
        }

        guard let credentials = await keychainService.getClaudeCredentials() else { return nil }

        var request = URLRequest(url: profileURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let profile = try JSONDecoder().decode(ClaudeProfileResponse.self, from: data)

            if let tier = profile.organization?.rateLimitTier {
                let label = parseTierLabel(tier)
                cachedPlanLabel = label
                planLabelCachedAt = Date()
                return label
            }
        } catch {
            logger.error("Claude profile error: \(error)")
        }
        return nil
    }

    private func parseTierLabel(_ tier: String) -> String {
        let lower = tier.lowercased()
        if lower.contains("max_20x") || lower.contains("max20x") { return "Max 20x" }
        if lower.contains("max_5x") || lower.contains("max5x") { return "Max 5x" }
        if lower.contains("max") { return "Max" }
        if lower.contains("pro") { return "Pro" }
        return tier.split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }

    func fetchUsage() async -> UsageData? {
        // Try API first
        if let apiData = await fetchFromAPI() {
            return apiData
        }

        // Fallback to local logs
        return await fetchFromLogs()
    }

    private func fetchFromAPI() async -> UsageData? {
        return await performAPIRequest(isRetry: false)
    }

    private func performAPIRequest(isRetry: Bool) async -> UsageData? {
        guard let credentials = await keychainService.getClaudeCredentials() else {
            return nil
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }

            if httpResponse.statusCode == 401 {
                logger.warning("Claude API returned 401 (isRetry=\(isRetry))")
                if !isRetry && !hasRetriedAfterAuthError {
                    hasRetriedAfterAuthError = true
                    await keychainService.invalidateCache()
                    return await performAPIRequest(isRetry: true)
                }
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                logger.warning("Claude API returned status \(httpResponse.statusCode)")
                return nil
            }

            hasRetriedAfterAuthError = false

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.debug("Claude API raw response: \(jsonString)")
            }

            let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
            return convertAPIResponse(apiResponse)
        } catch {
            logger.error("Claude API error: \(error)")
            return nil
        }
    }

    private func parseISO8601(_ string: String) -> Date? {
        if let date = Self.iso8601WithFractional.date(from: string) { return date }
        return Self.iso8601Standard.date(from: string)
    }

    func convertAPIResponse(_ response: ClaudeAPIResponse) -> UsageData? {
        guard let fiveHour = response.fiveHour else {
            logger.info("API response missing five_hour window, falling back to logs")
            return nil
        }

        let fiveHourReset = fiveHour.resetsAt.flatMap { parseISO8601($0) }

        let primaryWindow = UsageWindow(
            percentage: fiveHour.utilization,
            resetTime: fiveHourReset,
            isEstimated: false
        )

        let secondaryWindow: UsageWindow? = response.sevenDay.map { sevenDay in
            let sevenDayReset = sevenDay.resetsAt.flatMap { parseISO8601($0) }
            return UsageWindow(
                percentage: sevenDay.utilization,
                resetTime: sevenDayReset,
                isEstimated: false
            )
        }

        return UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: secondaryWindow,
            tokensUsed: nil,
            dataSource: .api
        )
    }

    private func fetchFromLogs() async -> UsageData? {
        let logsPath = Provider.claude.logsPath
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: logsPath) else {
            return nil
        }

        var totalTokens = 0
        let fiveHoursAgo = Date().addingTimeInterval(-5 * 3600)

        do {
            let projectDirs = try fileManager.contentsOfDirectory(atPath: logsPath)

            for projectDir in projectDirs {
                let projectPath = (logsPath as NSString).appendingPathComponent(projectDir)
                var isDirectory: ObjCBool = false

                guard fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                let files = try fileManager.contentsOfDirectory(atPath: projectPath)
                let jsonlFiles = files.filter { $0.hasSuffix(".jsonl") }

                for file in jsonlFiles {
                    let filePath = (projectPath as NSString).appendingPathComponent(file)
                    totalTokens += await parseLogFile(at: filePath, since: fiveHoursAgo)
                }
            }
        } catch {
            logger.error("Error reading Claude logs: \(error)")
            return nil
        }

        guard totalTokens > 0 else {
            return nil
        }

        // Estimate percentage based on a typical limit (rough estimation)
        let estimatedLimit = 1_000_000 // Typical 5-hour token limit
        let percentage = min(Double(totalTokens) / Double(estimatedLimit) * 100, 100)

        let primaryWindow = UsageWindow(
            percentage: percentage,
            resetTime: Date().addingTimeInterval(5 * 3600),
            isEstimated: true
        )

        return UsageData(
            provider: .claude,
            primaryWindow: primaryWindow,
            secondaryWindow: nil,
            tokensUsed: nil,
            dataSource: .local
        )
    }

    private func parseLogFile(at path: String, since: Date) async -> Int {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return 0
        }

        var totalTokens = 0
        let lines = content.components(separatedBy: .newlines)
        let decoder = JSONDecoder()

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8) else {
                continue
            }

            do {
                let entry = try decoder.decode(ClaudeLogEntry.self, from: lineData)

                // Skip entries without timestamp — can't determine if they're in the window
                guard let timestampStr = entry.timestamp else {
                    continue
                }

                if let timestamp = Self.iso8601Standard.date(from: timestampStr)
                    ?? Self.iso8601WithFractional.date(from: timestampStr),
                   timestamp < since {
                    continue
                }

                if let usage = entry.message?.usage {
                    totalTokens += usage.totalTokens
                }
            } catch {
                continue
            }
        }

        return totalTokens
    }
}
