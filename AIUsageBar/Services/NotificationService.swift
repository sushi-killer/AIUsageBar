import Foundation
import AppKit
import UserNotifications
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "NotificationService")

@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized: Bool = false
    private var sentThresholds: [Provider: Set<Int>] = [:]

    private static let hasRequestedPermissionKey = "hasRequestedNotificationPermission"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            logger.error("Notification authorization error: \(error)")
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    /// Request notification permission automatically on first launch
    func requestPermissionOnFirstLaunch() async {
        let hasRequested = UserDefaults.standard.bool(forKey: Self.hasRequestedPermissionKey)
        guard !hasRequested else {
            await checkAuthorization()
            return
        }

        UserDefaults.standard.set(true, forKey: Self.hasRequestedPermissionKey)
        await requestAuthorization()
    }

    func checkAndSendNotification(for usage: UsageData, thresholds: [Int]) async {
        guard AppSettings.shared.notificationsEnabled else { return }
        if !isAuthorized {
            await checkAuthorization()
        }
        guard isAuthorized else { return }

        let percentage = Int(usage.displayPercentage)
        var sent = sentThresholds[usage.provider] ?? Set()

        // Reset thresholds when usage drops below the minimum configured threshold
        let minThreshold = thresholds.min() ?? 0
        if percentage < minThreshold && !sent.isEmpty {
            sent.removeAll()
            sentThresholds[usage.provider] = sent
            return
        }

        for threshold in thresholds.sorted() {
            if percentage >= threshold && !sent.contains(threshold) {
                sendNotification(provider: usage.provider, percentage: percentage, threshold: threshold)
                sent.insert(threshold)
            }
        }

        sentThresholds[usage.provider] = sent
    }

    func resetThresholds(for provider: Provider) {
        sentThresholds[provider] = Set()
    }

    func resetAllThresholds() {
        sentThresholds.removeAll()
    }

    private func sendNotification(provider: Provider, percentage: Int, threshold: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(provider.displayName) Usage Alert"
        content.body = "You've used \(percentage)% of your \(provider.displayName) rate limit"
        content.sound = .default
        content.categoryIdentifier = "USAGE_ALERT"

        let request = UNNotificationRequest(
            identifier: "\(provider.rawValue)-\(threshold)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Failed to send notification: \(error)")
            }
        }
    }

    func sendUpdateNotification(version: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Update Available"
        content.body = "AI Usage Bar v\(version) is now available"
        content.sound = .default
        content.categoryIdentifier = "UPDATE_AVAILABLE"

        let request = UNNotificationRequest(
            identifier: "update-\(version)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Failed to send update notification: \(error)")
            }
        }
    }

    func setupNotificationCategories() {
        let usageCategory = UNNotificationCategory(
            identifier: "USAGE_ALERT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let updateCategory = UNNotificationCategory(
            identifier: "UPDATE_AVAILABLE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([usageCategory, updateCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Show notifications even when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap to bring app to foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
        }
        completionHandler()
    }
}
