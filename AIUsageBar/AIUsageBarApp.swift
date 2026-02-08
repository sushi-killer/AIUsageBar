import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningTests else { return }

        // Initialize the status bar controller (singleton)
        _ = StatusBarController.shared

        Task {
            await NotificationService.shared.requestPermissionOnFirstLaunch()
            NotificationService.shared.setupNotificationCategories()
        }
    }
}

@main
struct AIUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    @StateObject private var usageManager = UsageManager.shared

    var body: some Scene {
        Settings {
            if !Self.isRunningTests {
                EmptyView()
            }
        }
    }
}
