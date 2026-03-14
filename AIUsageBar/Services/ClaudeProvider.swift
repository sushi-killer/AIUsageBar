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

/// Response from the Anthropic OAuth token refresh endpoint
private struct TokenRefreshResponse: Codable {
    let accessToken: String
    let tokenType: String?
    let expiresIn: Int?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

actor ClaudeProvider: UsageProvider {
    private static let oauthBetaVersion = "oauth-2025-04-20"
    private static let userAgentValue = "claude-code/2.0.32"
    private static let oauthClientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private static let tokenRefreshURL = URL(string: "https://console.anthropic.com/v1/oauth/token")!
    /// Proactively refresh when token expires within this interval
    private static let proactiveRefreshThreshold: TimeInterval = 15 * 60 // 15 minutes

    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let profileURL = URL(string: "https://api.anthropic.com/api/oauth/profile")!
    private let keychainService = KeychainService.shared

    /// Cached plan label so we don't hit the profile API every refresh
    private var planLabelCache = PlanLabelCache()

    /// Deduplicates concurrent refresh attempts (getPlanLabel + fetchUsage can overlap)
    private var activeRefreshTask: Task<ClaudeCredentials?, Never>?
    /// Tracks 401-triggered refresh attempts to prevent loops (proactive refresh does NOT set this)
    private var lastReactiveRefreshAttempt: Date?

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

        guard var credentials = await keychainService.getClaudeCredentials() else { return nil }

        // Ensure token is fresh for profile request too
        if credentials.expiresWithin(Self.proactiveRefreshThreshold),
           let refreshed = await refreshAccessToken(credentials) {
            credentials = refreshed
        }

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
        guard var credentials = await keychainService.getClaudeCredentials() else {
            return nil
        }

        // Proactive refresh: if token expires within 15 min, refresh before API call
        if credentials.expiresWithin(Self.proactiveRefreshThreshold),
           let refreshed = await refreshAccessToken(credentials) {
            credentials = refreshed
        }

        return await performAPIRequest(credentials: credentials)
    }

    private func performAPIRequest(credentials: ClaudeCredentials) async -> UsageData? {
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
                logger.warning("Claude API returned 401, attempting token refresh")
                // Guard: only one reactive refresh per 60s (proactive refresh has its own path)
                let now = Date()
                let recentlyRefreshed = lastReactiveRefreshAttempt.map { now.timeIntervalSince($0) < 60 } ?? false
                if !recentlyRefreshed {
                    lastReactiveRefreshAttempt = now
                    if let refreshed = await refreshAccessToken(credentials) {
                        return await performAPIRequest(credentials: refreshed)
                    }
                }
                // Refresh failed or recently tried — invalidate cache so next timer tick
                // re-reads Keychain (in case user entered new creds via the app)
                logger.info("Token refresh exhausted, invalidating cache for next cycle")
                await keychainService.invalidateCache()
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                logger.warning("Claude API returned status \(httpResponse.statusCode)")
                return nil
            }

            let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
            return convertAPIResponse(apiResponse)
        } catch {
            logger.error("Claude API error: \(error)")
            return nil
        }
    }

    // MARK: - OAuth Token Refresh

    /// Refresh the access token using the refresh token endpoint.
    /// Deduplicated: concurrent callers (fetchUsage + getPlanLabel) share a single refresh.
    private func refreshAccessToken(_ credentials: ClaudeCredentials) async -> ClaudeCredentials? {
        // If a refresh is already in-flight, join it instead of firing a second one
        if let existing = activeRefreshTask {
            return await existing.value
        }

        guard let refreshToken = credentials.refreshToken, !refreshToken.isEmpty else {
            logger.info("No refresh token available, cannot self-refresh")
            return nil
        }

        let task = Task<ClaudeCredentials?, Never> { [keychainService] in
            var request = URLRequest(url: Self.tokenRefreshURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 15
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // Form-urlencoded requires encoding &, =, + etc — use strict allowed set
            var formAllowed = CharacterSet.alphanumerics
            formAllowed.insert(charactersIn: "-._~")
            let encodedToken = refreshToken.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? refreshToken
            let body = "grant_type=refresh_token&refresh_token=\(encodedToken)&client_id=\(Self.oauthClientId)"
            request.httpBody = body.data(using: .utf8)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    logger.warning("Token refresh failed with status \(statusCode)")
                    return nil
                }

                let tokenResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)

                let newExpiresAt: Int64? = tokenResponse.expiresIn.map {
                    Int64(Date().timeIntervalSince1970 * 1000) + Int64($0) * 1000
                }

                let updated = ClaudeCredentials(
                    accessToken: tokenResponse.accessToken,
                    subscriptionType: credentials.subscriptionType,
                    refreshToken: tokenResponse.refreshToken ?? credentials.refreshToken,
                    expiresAt: newExpiresAt ?? credentials.expiresAt
                )

                await keychainService.updateCachedCredentials(updated)
                logger.info("Token refreshed successfully, expires in \(tokenResponse.expiresIn ?? -1)s")
                return updated
            } catch {
                logger.error("Token refresh error: \(error)")
                return nil
            }
        }

        activeRefreshTask = task
        let result = await task.value
        activeRefreshTask = nil
        return result
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
