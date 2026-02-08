import Foundation
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "UpdateChecker")

actor UpdateChecker {
    struct Release {
        let version: String
        let url: URL
    }

    private var cachedRelease: Release?
    private var lastCheckDate: Date?
    private static let checkInterval: TimeInterval = 6 * 60 * 60 // 6 hours

    func checkForUpdate() async -> Release? {
        // Throttle: skip if checked recently
        if let lastCheck = lastCheckDate,
           Date().timeIntervalSince(lastCheck) < Self.checkInterval {
            return cachedRelease
        }

        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return cachedRelease
        }

        do {
            let url = URL(string: "https://api.github.com/repos/sushi-killer/AIUsageBar/releases/latest")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                lastCheckDate = Date()
                return cachedRelease
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String,
                  let releaseURL = URL(string: htmlURL) else {
                lastCheckDate = Date()
                return cachedRelease
            }

            let remoteVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            lastCheckDate = Date()

            if isNewer(remote: remoteVersion, current: currentVersion) {
                let release = Release(version: remoteVersion, url: releaseURL)
                cachedRelease = release
                return release
            } else {
                cachedRelease = nil
                return nil
            }
        } catch {
            logger.debug("Update check failed: \(error.localizedDescription)")
            lastCheckDate = Date()
            return cachedRelease
        }
    }

    private func isNewer(remote: String, current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        let count = max(remoteParts.count, currentParts.count)
        for i in 0..<count {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
}
