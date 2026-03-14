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

actor ClaudeProvider: UsageProvider {
    private static let oauthBetaVersion = "oauth-2025-04-20"
    private static let userAgentValue = "claude-code/2.0.32"

    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let profileURL = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    private let keychainService = KeychainService.shared

    /// Session-level guard: once we've retried after a 401, don't retry again
    /// until a successful response proves the credentials are valid.
    private var hasRetriedAfterAuthError = false

    /// Cached plan label so we don't hit the profile API every refresh
    private var planLabelCache = PlanLabelCache()

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
        if let cached = planLabelCache.cached { return cached }

        guard let credentials = await keychainService.getClaudeCredentials() else { return nil }

        var request = URLRequest(url: profileURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.oauthBetaVersion, forHTTPHeaderField: "anthropic-beta")
        request.setValue(Self.userAgentValue, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let profile = try JSONDecoder().decode(ClaudeProfileResponse.self, from: data)

            if let tier = profile.organization?.rateLimitTier {
                let label = parseTierLabel(tier)
                planLabelCache.store(label)
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
        return await performAPIRequest(isRetry: false)
    }

    private func performAPIRequest(isRetry: Bool) async -> UsageData? {
        guard let credentials = await keychainService.getClaudeCredentials() else {
            return nil
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.oauthBetaVersion, forHTTPHeaderField: "anthropic-beta")
        request.setValue(Self.userAgentValue, forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }

            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                logger.info("Claude API rate limited (429), retry-after: \(retryAfter ?? "none")")
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
            logger.info("API response missing five_hour window")
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

}
