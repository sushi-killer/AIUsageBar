import XCTest
@testable import AIUsageBar

/// Tests for PRD US-011: Notification System
/// Validates UNUserNotificationCenter usage, first-launch permission request,
/// threshold notifications, deduplication, and notification tap handling
final class NotificationSystemTests: XCTestCase {

    // MARK: - Helper

    private func readSource(_ relativePath: String) throws -> String {
        let basePath = #filePath
            .components(separatedBy: "/AIUsageBarTests/")
            .first!
        let filePath = basePath + "/AIUsageBar/" + relativePath
        return try String(contentsOfFile: filePath, encoding: .utf8)
    }

    // MARK: - UNUserNotificationCenter Usage (PRD US-011)

    func testImportsUserNotifications() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("import UserNotifications"),
            "NotificationService must import UserNotifications framework (PRD US-011)"
        )
    }

    func testUsesUNUserNotificationCenter() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNUserNotificationCenter.current()"),
            "NotificationService must use UNUserNotificationCenter (PRD US-011)"
        )
    }

    func testUsesUNMutableNotificationContent() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNMutableNotificationContent()"),
            "NotificationService must create UNMutableNotificationContent for notifications"
        )
    }

    func testUsesUNNotificationRequest() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNNotificationRequest("),
            "NotificationService must create UNNotificationRequest for delivery"
        )
    }

    // MARK: - Request Permission on First Launch (PRD US-011)

    func testHasRequestPermissionOnFirstLaunchMethod() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("requestPermissionOnFirstLaunch"),
            "NotificationService must have a requestPermissionOnFirstLaunch method (PRD US-011)"
        )
    }

    func testFirstLaunchUsesUserDefaultsKey() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("hasRequestedNotificationPermission"),
            "NotificationService must track first-launch request via UserDefaults key"
        )
    }

    func testFirstLaunchGuardsOnHasRequested() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("guard !hasRequested else { return }"),
            "requestPermissionOnFirstLaunch must skip if already requested"
        )
    }

    func testFirstLaunchSetsUserDefaultsFlag() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UserDefaults.standard.set(true, forKey: Self.hasRequestedPermissionKey)"),
            "requestPermissionOnFirstLaunch must set the flag before requesting"
        )
    }

    func testFirstLaunchCallsRequestAuthorization() throws {
        let source = try readSource("Services/NotificationService.swift")

        // Verify requestPermissionOnFirstLaunch calls requestAuthorization
        let methodRange = source.range(of: "requestPermissionOnFirstLaunch")!
        let afterMethod = String(source[methodRange.lowerBound...])
        let methodEnd = afterMethod.range(of: "^\n    }", options: .regularExpression)!
        let methodBody = String(afterMethod[..<methodEnd.upperBound])

        XCTAssertTrue(
            methodBody.contains("await requestAuthorization()"),
            "requestPermissionOnFirstLaunch must call requestAuthorization()"
        )
    }

    func testInitCallsFirstLaunchPermission() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("await requestPermissionOnFirstLaunch()"),
            "NotificationService init must call requestPermissionOnFirstLaunch (PRD US-011)"
        )
    }

    // MARK: - Notification at Thresholds (PRD US-011)

    func testCheckAndSendNotificationMethodExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func checkAndSendNotification(for usage: UsageData, thresholds: [Int])"),
            "NotificationService must have checkAndSendNotification method"
        )
    }

    func testNotificationChecksPercentageAgainstThresholds() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("percentage >= threshold"),
            "checkAndSendNotification must compare percentage against thresholds"
        )
    }

    func testNotificationIteratesOverSortedThresholds() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("thresholds.sorted()"),
            "checkAndSendNotification must iterate over sorted thresholds"
        )
    }

    // MARK: - Notification Content (PRD US-011)

    func testNotificationTitleIncludesProviderName() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("content.title = \"\\(provider.displayName) Usage Alert\""),
            "Notification title must be '[Provider] Usage Alert' (PRD US-011)"
        )
    }

    func testNotificationBodyIncludesPercentage() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("content.body = \"You've used \\(percentage)% of your 5-hour limit\""),
            "Notification body must be 'You've used X% of your 5-hour limit' (PRD US-011)"
        )
    }

    func testNotificationHasDefaultSound() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("content.sound = .default"),
            "Notification must use default sound"
        )
    }

    func testNotificationUsesUsageAlertCategory() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("content.categoryIdentifier = \"USAGE_ALERT\""),
            "Notification must use USAGE_ALERT category identifier"
        )
    }

    // MARK: - Deduplication (PRD US-011)

    func testTracksSentThresholdsPerProvider() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("sentThresholds: [Provider: Set<Int>]"),
            "NotificationService must track sent thresholds per provider for deduplication"
        )
    }

    func testSkipsAlreadySentThreshold() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("!sent.contains(threshold)"),
            "checkAndSendNotification must skip thresholds already sent (PRD US-011)"
        )
    }

    func testInsertsThresholdAfterSending() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("sent.insert(threshold)"),
            "checkAndSendNotification must record sent thresholds to prevent repeats"
        )
    }

    func testResetThresholdsForProviderExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func resetThresholds(for provider: Provider)"),
            "NotificationService must have resetThresholds(for:) to reset after usage resets"
        )
    }

    func testResetAllThresholdsExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func resetAllThresholds()"),
            "NotificationService must have resetAllThresholds()"
        )
    }

    // MARK: - Notification Tap Handling (PRD US-011)

    func testConformsToUNUserNotificationCenterDelegate() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNUserNotificationCenterDelegate"),
            "NotificationService must conform to UNUserNotificationCenterDelegate (PRD US-011)"
        )
    }

    func testSetsItselfAsDelegate() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNUserNotificationCenter.current().delegate = self"),
            "NotificationService must set itself as UNUserNotificationCenter delegate"
        )
    }

    func testImplementsWillPresentDelegate() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("willPresent notification"),
            "NotificationService must implement willPresent delegate for foreground notifications"
        )
    }

    func testWillPresentShowsBannerAndSound() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("[.banner, .sound]"),
            "willPresent delegate must show banner and play sound in foreground"
        )
    }

    func testImplementsDidReceiveDelegate() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("didReceive response"),
            "NotificationService must implement didReceive delegate for notification tap handling"
        )
    }

    func testDidReceiveActivatesApp() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("NSApp.activate"),
            "didReceive delegate must activate the app when notification is tapped (PRD US-011)"
        )
    }

    // MARK: - Notification Categories Setup

    func testSetupNotificationCategoriesExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func setupNotificationCategories()"),
            "NotificationService must have setupNotificationCategories()"
        )
    }

    func testSetupRegistersUsageAlertCategory() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("UNNotificationCategory(") &&
            source.contains("identifier: \"USAGE_ALERT\""),
            "setupNotificationCategories must register USAGE_ALERT category"
        )
    }

    // MARK: - App Integration

    func testAppCallsSetupNotificationCategories() throws {
        let source = try readSource("AIUsageBarApp.swift")

        XCTAssertTrue(
            source.contains("NotificationService.shared.setupNotificationCategories()"),
            "App must call setupNotificationCategories on initialization"
        )
    }

    func testUsageManagerTriggersNotifications() throws {
        let source = try readSource("Services/UsageManager.swift")

        XCTAssertTrue(
            source.contains("NotificationService.shared.checkAndSendNotification"),
            "UsageManager must trigger notification checks on data refresh"
        )
    }

    func testUsageManagerPassesEnabledThresholds() throws {
        let source = try readSource("Services/UsageManager.swift")

        XCTAssertTrue(
            source.contains("AppSettings.shared.enabledThresholds"),
            "UsageManager must pass enabledThresholds from AppSettings to notification service"
        )
    }

    // MARK: - Authorization

    func testRequestAuthorizationMethodExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func requestAuthorization() async"),
            "NotificationService must have async requestAuthorization method"
        )
    }

    func testRequestsAlertSoundBadgeOptions() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("options: [.alert, .sound, .badge]"),
            "requestAuthorization must request alert, sound, and badge options"
        )
    }

    func testCheckAuthorizationMethodExists() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("func checkAuthorization() async"),
            "NotificationService must have async checkAuthorization method"
        )
    }

    func testIsAuthorizedPublishedProperty() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("@Published private(set) var isAuthorized: Bool"),
            "NotificationService must have @Published isAuthorized property"
        )
    }

    // MARK: - NSObject Inheritance

    func testInheritsFromNSObject() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("NotificationService: NSObject"),
            "NotificationService must inherit from NSObject for delegate conformance"
        )
    }

    // MARK: - Notification Identifier Uniqueness

    func testNotificationIdentifierIncludesProviderAndThreshold() throws {
        let source = try readSource("Services/NotificationService.swift")

        XCTAssertTrue(
            source.contains("identifier: \"\\(provider.rawValue)-\\(threshold)\""),
            "Notification identifier must include provider and threshold for uniqueness"
        )
    }
}
