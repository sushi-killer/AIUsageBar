import Foundation
import Combine

@MainActor
final class UsageManager: ObservableObject {
    static let shared = UsageManager()

    @Published private(set) var claudeUsage: UsageData?
    @Published private(set) var codexUsage: UsageData?
    @Published private(set) var kimiUsage: UsageData?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var availableUpdate: UpdateChecker.Release?

    private let claudeProvider = ClaudeProvider()
    private let codexProvider = CodexProvider()
    private let kimiProvider = KimiProvider()
    private let updateChecker = UpdateChecker()
    private var lastNotifiedVersion: String?
    private var fileWatcher: FileWatcher?
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?

    private var lastRefreshTime: [Provider: Date] = [:]

    private init() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        setupFileWatcher()
        setupRefreshTimer()
    }

    func usage(for provider: Provider) -> UsageData? {
        switch provider {
        case .claude: return claudeUsage
        case .codex: return codexUsage
        case .kimi: return kimiUsage
        }
    }

    var hasRecentData: Bool {
        let settings = AppSettings.shared
        let interval = settings.refreshInterval
        let now = Date()
        let usages = settings.enabledProviders.compactMap { usage(for: $0) }
        guard !usages.isEmpty else { return false }
        return usages.contains { now.timeIntervalSince($0.lastUpdated) < interval }
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
            defer { isLoading = false; refreshTask = nil }

            let settings = AppSettings.shared
            async let claudeTask: UsageData? = settings.isProviderEnabled(.claude) ? claudeProvider.fetchUsage() : nil
            async let codexTask: UsageData? = settings.isProviderEnabled(.codex) ? codexProvider.fetchUsage() : nil
            async let kimiTask: UsageData? = settings.isProviderEnabled(.kimi) ? kimiProvider.fetchUsage() : nil

            let (claude, codex, kimi) = await (claudeTask, codexTask, kimiTask)

            for (provider, data) in [(Provider.claude, claude), (.codex, codex), (.kimi, kimi)] {
                if settings.isProviderEnabled(provider) {
                    if let data { self.setUsage(data, for: provider) }
                    self.lastRefreshTime[provider] = Date()
                } else {
                    self.setUsage(nil, for: provider)
                    self.lastRefreshTime.removeValue(forKey: provider)
                }
            }

            // Check notifications in background (don't block spinner)
            let thresholds = AppSettings.shared.enabledThresholds
            Task { @MainActor in
                for usage in [claude, codex, kimi].compactMap({ $0 }) {
                    await NotificationService.shared.checkAndSendNotification(
                        for: usage,
                        thresholds: thresholds
                    )
                }
            }

            // Check for app updates in the background
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let update = await self.updateChecker.checkForUpdate() {
                    self.availableUpdate = update
                    if update.version != self.lastNotifiedVersion {
                        NotificationService.shared.sendUpdateNotification(version: update.version)
                        self.lastNotifiedVersion = update.version
                    }
                } else {
                    self.availableUpdate = nil
                }
            }
        }
        refreshTask = task
        await task.value
    }

    func refresh(provider: Provider) async {
        // Per-provider throttle: respect minimum refresh interval
        let now = Date()
        if let last = lastRefreshTime[provider],
           now.timeIntervalSince(last) < AppSettings.minimumRefreshInterval { return }
        lastRefreshTime[provider] = now

        let usage = await fetchUsage(for: provider)
        if let usage { setUsage(usage, for: provider) }
        if let usage {
            await NotificationService.shared.checkAndSendNotification(
                for: usage,
                thresholds: AppSettings.shared.enabledThresholds
            )
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
        let interval = max(AppSettings.shared.refreshInterval, AppSettings.minimumRefreshInterval)
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

    func getPlanLabel(for provider: Provider) async -> String? {
        switch provider {
        case .claude: return await claudeProvider.getPlanLabel()
        case .codex: return await codexProvider.getPlanLabel()
        case .kimi: return await kimiProvider.getPlanLabel()
        }
    }

    private func setUsage(_ data: UsageData?, for provider: Provider) {
        switch provider {
        case .claude: claudeUsage = data
        case .codex: codexUsage = data
        case .kimi: kimiUsage = data
        }
    }

    private func fetchUsage(for provider: Provider) async -> UsageData? {
        switch provider {
        case .claude: return await claudeProvider.fetchUsage()
        case .codex: return await codexProvider.fetchUsage()
        case .kimi: return await kimiProvider.fetchUsage()
        }
    }
}
