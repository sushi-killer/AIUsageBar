import Foundation
import Combine

@MainActor
final class UsageManager: ObservableObject {
    static let shared = UsageManager()

    @Published private(set) var claudeUsage: UsageData?
    @Published private(set) var codexUsage: UsageData?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var availableUpdate: UpdateChecker.Release?

    private let claudeProvider = ClaudeProvider()
    private let codexProvider = CodexProvider()
    private let updateChecker = UpdateChecker()
    private var lastNotifiedVersion: String?
    private var fileWatcher: FileWatcher?
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?

    private init() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        setupFileWatcher()
        setupRefreshTimer()
    }

    func usage(for provider: Provider) -> UsageData? {
        switch provider {
        case .claude: return claudeUsage
        case .codex: return codexUsage
        }
    }

    func refresh() async {
        // Deduplicate: if a refresh is already running, wait for it instead
        if let existing = refreshTask, !existing.isCancelled {
            await existing.value
            return
        }

        let task = Task { @MainActor in
            isLoading = true
            lastError = nil

            async let claudeTask = claudeProvider.fetchUsage()
            async let codexTask = codexProvider.fetchUsage()

            let (claude, codex) = await (claudeTask, codexTask)

            claudeUsage = claude
            codexUsage = codex

            // Check notifications
            if let claude = claude {
                await NotificationService.shared.checkAndSendNotification(
                    for: claude,
                    thresholds: AppSettings.shared.enabledThresholds
                )
            }

            if let codex = codex {
                await NotificationService.shared.checkAndSendNotification(
                    for: codex,
                    thresholds: AppSettings.shared.enabledThresholds
                )
            }

            // Check for app updates (throttled internally to once per 6 hours)
            if let update = await updateChecker.checkForUpdate() {
                availableUpdate = update
                if update.version != lastNotifiedVersion {
                    NotificationService.shared.sendUpdateNotification(version: update.version)
                    lastNotifiedVersion = update.version
                }
            } else {
                availableUpdate = nil
            }

            isLoading = false
        }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    func refresh(provider: Provider) async {
        switch provider {
        case .claude:
            claudeUsage = await claudeProvider.fetchUsage()
            if let usage = claudeUsage {
                await NotificationService.shared.checkAndSendNotification(
                    for: usage,
                    thresholds: AppSettings.shared.enabledThresholds
                )
            }
        case .codex:
            codexUsage = await codexProvider.fetchUsage()
            if let usage = codexUsage {
                await NotificationService.shared.checkAndSendNotification(
                    for: usage,
                    thresholds: AppSettings.shared.enabledThresholds
                )
            }
        }
    }

    private func setupFileWatcher() {
        fileWatcher = FileWatcher { [weak self] provider in
            Task { @MainActor in
                await self?.refresh(provider: provider)
            }
        }
        fileWatcher?.start()
    }

    private func setupRefreshTimer() {
        refreshTimer?.invalidate()
        let interval = AppSettings.shared.refreshInterval
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
        // Allow system to coalesce timer fires for power efficiency during idle periods.
        // Tolerance is clamped between min/max bounds for reasonable behavior.
        let calculatedTolerance = interval * IdleOptimization.timerToleranceFraction
        timer.tolerance = min(
            max(calculatedTolerance, IdleOptimization.minimumTimerTolerance),
            IdleOptimization.maximumTimerTolerance
        )
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func updateRefreshInterval() {
        setupRefreshTimer()
    }

    func getClaudePlanLabel() async -> String? {
        await claudeProvider.getPlanLabel()
    }

    func getCodexPlanLabel() async -> String? {
        await codexProvider.getPlanLabel()
    }
}
