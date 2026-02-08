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

// MARK: - Log Entry Models (fallback)

struct CodexLogEntry: Codable {
    let payload: Payload?
    let timestamp: String?

    struct Payload: Codable {
        let type: String?
        let rateLimits: RateLimits?

        enum CodingKeys: String, CodingKey {
            case type
            case rateLimits = "rate_limits"
        }
    }

    struct RateLimits: Codable {
        let primary: RateLimitWindow?
        let secondary: RateLimitWindow?
    }

    struct RateLimitWindow: Codable {
        let usedPercent: Double?
        let resetsAt: Int?

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case resetsAt = "resets_at"
        }
    }
}

// MARK: - Provider

actor CodexProvider {
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    private let apiURL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    /// Cached plan label with TTL
    private var cachedPlanLabel: String?
    private var planLabelCachedAt: Date?
    private static let planLabelTTL: TimeInterval = 3600

    func fetchUsage() async -> UsageData? {
        // Try API first
        if let apiData = await fetchFromAPI() {
            return apiData
        }

        // Fallback to local logs
        return await fetchFromLogs()
    }

    // MARK: - Plan Label

    func getPlanLabel() -> String? {
        if let cached = cachedPlanLabel,
           let cachedAt = planLabelCachedAt,
           Date().timeIntervalSince(cachedAt) < Self.planLabelTTL {
            return cached
        }

        guard let label = extractPlanTypeFromJWT() else { return nil }
        cachedPlanLabel = label
        planLabelCachedAt = Date()
        return label
    }

    private func extractPlanTypeFromJWT() -> String? {
        let authPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json").path

        guard let data = FileManager.default.contents(atPath: authPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = json["tokens"] as? [String: Any],
              let idToken = tokens["id_token"] as? String else {
            return nil
        }

        let parts = idToken.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        var base64 = String(parts[1])
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            return nil
        }

        if let authInfo = payload["https://api.openai.com/auth"] as? [String: Any],
           let planType = authInfo["chatgpt_plan_type"] as? String {
            return planType.capitalized
        }

        return nil
    }

    // MARK: - API

    private func fetchFromAPI() async -> UsageData? {
        guard let auth = readAuth() else { return nil }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(auth.accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        request.setValue("AIUsageBar/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
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

    // MARK: - Fallback: Local Logs

    private func fetchFromLogs() async -> UsageData? {
        let logsPath = Provider.codex.logsPath
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: logsPath) else { return nil }

        for daysAgo in 0..<7 {
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) else { continue }
            let dayPath = (logsPath as NSString).appendingPathComponent(Self.dayFormatter.string(from: date))
            if let usage = await fetchFromPath(dayPath) {
                return usage
            }
        }

        return nil
    }

    private func fetchFromPath(_ path: String) async -> UsageData? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else { return nil }

        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            let rolloutFiles = files.filter { $0.hasPrefix("rollout-") && $0.hasSuffix(".jsonl") }
                .sorted().reversed()

            for file in rolloutFiles {
                let filePath = (path as NSString).appendingPathComponent(file)
                if let usage = await parseLogFile(at: filePath) {
                    return usage
                }
            }
        } catch {
            logger.error("Error reading Codex logs: \(error)")
        }

        return nil
    }

    private func parseLogFile(at path: String) async -> UsageData? {
        guard let data = FileManager.default.contents(atPath: path),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = content.components(separatedBy: .newlines).reversed()
        let decoder = JSONDecoder()

        for line in lines {
            guard !line.isEmpty, let lineData = line.data(using: .utf8) else { continue }

            do {
                let entry = try decoder.decode(CodexLogEntry.self, from: lineData)
                guard entry.payload?.type == "token_count",
                      let rateLimits = entry.payload?.rateLimits else { continue }

                return buildFromLogs(rateLimits)
            } catch {
                continue
            }
        }

        return nil
    }

    private func buildFromLogs(_ rateLimits: CodexLogEntry.RateLimits) -> UsageData {
        let now = Date()

        func makeWindow(_ w: CodexLogEntry.RateLimitWindow) -> UsageWindow {
            let resetDate = w.resetsAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            let isExpired = resetDate.map { $0 <= now } ?? false
            return UsageWindow(
                percentage: isExpired ? 0 : (w.usedPercent ?? 0),
                resetTime: isExpired ? nil : resetDate,
                isEstimated: false
            )
        }

        let primary = rateLimits.primary.map { makeWindow($0) }
            ?? UsageWindow(percentage: 0, isEstimated: true)
        let secondary = rateLimits.secondary.map { makeWindow($0) }

        return UsageData(
            provider: .codex,
            primaryWindow: primary,
            secondaryWindow: secondary,
            tokensUsed: nil,
            dataSource: .local
        )
    }
}
