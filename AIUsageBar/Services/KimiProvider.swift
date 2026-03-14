import Foundation
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "KimiProvider")

// MARK: - API Response Models

struct KimiUsageResponse: Codable {
    let user: KimiUser?
    let usage: KimiQuota?
    let limits: [KimiLimitWindow]?
}

struct KimiUser: Codable {
    let membership: KimiMembership?
}

struct KimiMembership: Codable {
    let level: String?
}

struct KimiQuota: Codable {
    let limit: String?
    let remaining: String?
    let resetTime: String?
}

struct KimiLimitWindow: Codable {
    let window: KimiWindow?
    let detail: KimiQuota?
}

struct KimiWindow: Codable {
    let duration: Int?
    let timeUnit: String?
}

// MARK: - Provider

actor KimiProvider: UsageProvider {
    private static let usagesURL = URL(string: "https://api.kimi.com/coding/v1/usages")!

    private static let iso8601WithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601Standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Cached plan label with TTL to avoid stale membership data
    private var planLabelCache = PlanLabelCache()

    func fetchUsage() async -> UsageData? {
        guard let apiKey = await readAPIKey(), !apiKey.isEmpty else {
            return nil
        }

        var request = URLRequest(url: Self.usagesURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { return nil }

            if httpResponse.statusCode == 429 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "retry-after")
                logger.info("Kimi API rate limited (429), retry-after: \(retryAfter ?? "none")")
                return nil
            }

            if httpResponse.statusCode == 401 {
                logger.warning("Kimi API returned 401 — API key may be invalid")
                return nil
            }

            guard httpResponse.statusCode == 200 else {
                logger.warning("Kimi usages API returned \(httpResponse.statusCode)")
                return nil
            }

            let usageResponse = try JSONDecoder().decode(KimiUsageResponse.self, from: data)
            return convertResponse(usageResponse)
        } catch {
            logger.error("Kimi API error: \(error)")
            return nil
        }
    }

    func getPlanLabel() async -> String? {
        return planLabelCache.cached ?? planLabelCache.stale
    }

    // MARK: - Private

    private func readAPIKey() async -> String? {
        await MainActor.run { KeychainService.shared.getAPIKey(forService: AppSettings.kimiKeychainService) }
    }

    private func convertResponse(_ response: KimiUsageResponse) -> UsageData? {
        // Parse membership level
        if let level = response.user?.membership?.level {
            planLabelCache.store(parseMembershipLevel(level))
        }

        // Primary window: first entry in limits[] (5-hour window)
        var primaryWindow = UsageWindow(percentage: 0, isEstimated: true)
        if let firstLimit = response.limits?.first,
           let detail = firstLimit.detail {
            primaryWindow = makeWindow(from: detail)
        }

        // Secondary window: overall quota from response.usage (Kimi API returns this as the weekly/overall quota)
        var secondaryWindow: UsageWindow?
        if let overall = response.usage {
            secondaryWindow = makeWindow(from: overall)
        }

        return UsageData(
            provider: .kimi,
            primaryWindow: primaryWindow,
            secondaryWindow: secondaryWindow,
            tokensUsed: nil,
            dataSource: .api
        )
    }

    private func makeWindow(from quota: KimiQuota) -> UsageWindow {
        let limit = Double(quota.limit ?? "0") ?? 0
        let remaining = Double(quota.remaining ?? "0") ?? 0

        var percentage: Double = 0
        if limit > 0 {
            let used = limit - remaining
            percentage = min(max(used / limit * 100, 0), 100)
        }

        var resetTime: Date?
        if let resetStr = quota.resetTime {
            resetTime = Self.iso8601WithFractional.date(from: resetStr)
                ?? Self.iso8601Standard.date(from: resetStr)
        }

        return UsageWindow(
            percentage: percentage,
            resetTime: resetTime,
            isEstimated: false
        )
    }

    private func parseMembershipLevel(_ level: String) -> String {
        let lower = level.lowercased()
        // Kimi uses musical tempo names for subscription tiers
        if lower.contains("vivace") { return "Vivace" }
        if lower.contains("allegretto") { return "Allegretto" }
        if lower.contains("allegro") { return "Allegro" }
        if lower.contains("moderato") { return "Moderato" }
        if lower.contains("andante") { return "Andante" }
        if lower.contains("adagio") { return "Adagio" }
        // API internal names → marketing names
        if lower.contains("premium") { return "Vivace" }
        if lower.contains("advanced") { return "Allegro" }
        if lower.contains("intermediate") { return "Allegretto" }
        if lower.contains("basic") { return "Moderato" }
        if lower.contains("free") { return "Free" }
        // Fallback: strip common prefixes and capitalize
        let cleaned = level
            .replacingOccurrences(of: "LEVEL_", with: "")
            .replacingOccurrences(of: "MEMBERSHIP_", with: "")
        return cleaned.capitalized
    }
}
