import Foundation
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "CodexProvider")

// MARK: - API Response Models

struct CodexUsageResponse: Codable {
    let planType: String?
    let rateLimit: CodexRateLimit

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
    }
}

struct CodexRateLimit: Codable {
    let primaryWindow: CodexWindow?
    let secondaryWindow: CodexWindow?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexWindow: Codable {
    let usedPercent: Double
    let limitWindowSeconds: Int?
    let resetAt: Int?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAt = "reset_at"
    }
}

// MARK: - Provider

actor CodexProvider: UsageProvider {
    private let apiURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    /// Cached plan label with TTL
    private var planLabelCache = PlanLabelCache()

    func fetchUsage() async -> UsageData? {
        return await fetchFromAPI()
    }

    // MARK: - Plan Label

    func getPlanLabel() async -> String? {
        if let cached = planLabelCache.cached { return cached }

        guard let label = extractPlanTypeFromJWT() else { return nil }
        planLabelCache.store(label)
        return label
    }

    private func extractPlanTypeFromJWT() -> String? {
        let authPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json").path

        guard let data = FileManager.default.contents(atPath: authPath) else {
            logger.debug("JWT parse failed: auth file not found at \(authPath)")
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.warning("JWT parse failed: could not deserialize auth.json")
            return nil
        }
        guard let tokens = json["tokens"] as? [String: Any] else {
            logger.warning("JWT parse failed: missing 'tokens' key in auth.json")
            return nil
        }
        guard let idToken = tokens["id_token"] as? String else {
            logger.warning("JWT parse failed: missing 'id_token' in tokens")
            return nil
        }

        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else {
            logger.warning("JWT parse failed: token has \(parts.count) parts, expected >= 2")
            return nil
        }

        var base64 = String(parts[1])
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64) else {
            logger.warning("JWT parse failed: base64 decoding of payload segment failed")
            return nil
        }
        guard let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            logger.warning("JWT parse failed: could not deserialize JWT payload as JSON")
            return nil
        }

        if let authInfo = payload["https://api.openai.com/auth"] as? [String: Any],
           let planType = authInfo["chatgpt_plan_type"] as? String {
            return planType.capitalized
        }

        logger.debug("JWT parse: no 'chatgpt_plan_type' found in JWT auth claim")
        return nil
    }

    // MARK: - API

    private func fetchFromAPI() async -> UsageData? {
        guard let auth = readAuth() else { return nil }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(auth.accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.setValue("AIUsageBar/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { return nil }

            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                logger.info("Codex API rate limited (429), retry-after: \(retryAfter ?? "none")")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                return nil
            }

            let apiResponse = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
            return buildFromAPI(apiResponse)
        } catch {
            logger.error("Codex API error: \(error)")
            return nil
        }
    }

    private func readAuth() -> (accessToken: String, accountId: String)? {
        let authPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json").path

        guard let data = FileManager.default.contents(atPath: authPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String else {
            return nil
        }

        let accountId = tokens["account_id"] as? String ?? ""
        return (accessToken, accountId)
    }

    private func buildFromAPI(_ response: CodexUsageResponse) -> UsageData {
        var primaryWindow = UsageWindow(percentage: 0, isEstimated: true)
        var secondaryWindow: UsageWindow?

        if let pw = response.rateLimit.primaryWindow {
            primaryWindow = UsageWindow(
                percentage: pw.usedPercent,
                resetTime: pw.resetAt.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                isEstimated: false
            )
        }

        if let sw = response.rateLimit.secondaryWindow {
            secondaryWindow = UsageWindow(
                percentage: sw.usedPercent,
                resetTime: sw.resetAt.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                isEstimated: false
            )
        }

        return UsageData(
            provider: .codex,
            primaryWindow: primaryWindow,
            secondaryWindow: secondaryWindow,
            tokensUsed: nil,
            dataSource: .api
        )
    }

}
