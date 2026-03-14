import SwiftUI
import ServiceManagement
import os

private let logger = Logger(subsystem: "com.aiusagebar.app", category: "Settings")

/// Configuration constants for update timing requirements
/// Per PRD US-004: "User sees usage percentage update within 5 seconds of API response"
/// Per PRD US-006: "User sees usage update within 2 seconds of new log entry"
enum UpdateTiming {
    /// Maximum allowed delay between API response and UI update (in seconds)
    /// This is the PRD requirement for user-visible update latency
    static let maxUIUpdateDelay: TimeInterval = 5.0

    /// Maximum allowed delay between file change and UI update (in seconds)
    /// Per PRD US-006: "User sees usage update within 2 seconds of new log entry"
    /// Achieved through: FSEvents latency (0.5s) + app debounce (0.5s) + processing (~0.5s)
    static let maxFileWatcherUpdateDelay: TimeInterval = 2.0

    /// The FSEvents latency used for OS-level event coalescing
    static let fsEventsLatency: TimeInterval = 0.5

    /// The app-level debounce interval for file watcher callbacks
    static let fileWatcherDebounce: TimeInterval = 0.5

    /// The synchronous nature of SwiftUI @Published property updates
    /// means actual delay should be near-zero in practice
    static let expectedSynchronousDelay: TimeInterval = 0.1
}

/// Configuration constants for CPU idle period optimizations
/// These settings ensure minimal CPU usage when the app is not actively being used
enum IdleOptimization {
    /// Timer tolerance as a fraction of the timer interval.
    /// Allows macOS to coalesce timer wakeups for power efficiency.
    /// A 10% tolerance on a 60-second interval = 6-second coalescing window.
    static let timerToleranceFraction: Double = 0.1

    /// Minimum timer tolerance in seconds to ensure meaningful coalescing
    static let minimumTimerTolerance: TimeInterval = 1.0

    /// Maximum timer tolerance in seconds to ensure timely updates
    static let maximumTimerTolerance: TimeInterval = 30.0
}

enum AppTheme: String, CaseIterable {
    case standard = "standard"
    case mini = "mini"

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .mini: return "Mini"
        }
    }
}

enum MenuBarFormat: String, CaseIterable {
    case short = "short"
    case full = "full"
    case percentOnly = "pct"
    case iconOnly = "icon"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .short: return "Short"
        case .full: return "Full"
        case .percentOnly: return "Percent Only"
        case .iconOnly: return "Icon Only"
        case .custom: return "Custom"
        }
    }

    var preview: String {
        switch self {
        case .short: return "C:45% X:30% K:20%"
        case .full: return "Claude:45% Codex:30% Kimi:20%"
        case .percentOnly: return "45% 30% 20%"
        case .iconOnly: return "(icon only)"
        case .custom: return "(custom template)"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("appTheme") var appThemeRaw: String = AppTheme.standard.rawValue

    var appTheme: AppTheme {
        get { AppTheme(rawValue: appThemeRaw) ?? .standard }
        set { appThemeRaw = newValue.rawValue }
    }

    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet {
            updateLaunchAtLogin()
        }
    }
    @AppStorage("threshold50Enabled") var threshold50Enabled: Bool = true
    @AppStorage("threshold75Enabled") var threshold75Enabled: Bool = true
    @AppStorage("threshold90Enabled") var threshold90Enabled: Bool = true
    static let defaultWarningThreshold = 50
    static let defaultHighThreshold = 75
    static let defaultCriticalThreshold = 90

    @AppStorage("threshold50Value") var threshold50Value: Int = AppSettings.defaultWarningThreshold
    @AppStorage("threshold75Value") var threshold75Value: Int = AppSettings.defaultHighThreshold
    @AppStorage("threshold90Value") var threshold90Value: Int = AppSettings.defaultCriticalThreshold
    @AppStorage("selectedProvider") var selectedProviderRaw: String = Provider.claude.rawValue
    @AppStorage("refreshInterval") var refreshInterval: Double = 120.0

    /// Hard floor: no provider may be polled more often than this.
    /// Anthropic's usage endpoint triggers a permanent 429 loop at 30-60s intervals.
    static let minimumRefreshInterval: TimeInterval = 120.0
    @AppStorage("cachedClaudePlanLabel") var cachedClaudePlanLabel: String = ""
    @AppStorage("cachedCodexPlanLabel") var cachedCodexPlanLabel: String = ""
    @AppStorage("cachedKimiPlanLabel") var cachedKimiPlanLabel: String = ""
    @AppStorage("providerEnabledClaude") var providerEnabledClaude: Bool = true
    @AppStorage("providerEnabledCodex") var providerEnabledCodex: Bool = true
    @AppStorage("providerEnabledKimi") var providerEnabledKimi: Bool = true
    @AppStorage("menuBarShowClaude") var menuBarShowClaude: Bool = true
    @AppStorage("menuBarShowCodex") var menuBarShowCodex: Bool = true
    @AppStorage("menuBarShowKimi") var menuBarShowKimi: Bool = true
    @AppStorage("menuBarFormat") var menuBarFormatRaw: String = MenuBarFormat.short.rawValue
    @AppStorage("customMenuBarFormat") var customMenuBarFormat: String = "C:{c}% X:{x}% K:{k}%"

    static let kimiKeychainService = "Kimi-apikey"

    var kimiAPIKey: String {
        get { KeychainService.shared.getAPIKey(forService: Self.kimiKeychainService) ?? "" }
        set {
            KeychainService.shared.storeAPIKey(newValue, forService: Self.kimiKeychainService)
            objectWillChange.send()
        }
    }

    var menuBarFormat: MenuBarFormat {
        get { MenuBarFormat(rawValue: menuBarFormatRaw) ?? .short }
        set { menuBarFormatRaw = newValue.rawValue }
    }

    func formatCustomTemplate(claude: Int?, codex: Int?, kimi: Int? = nil) -> String {
        var result = customMenuBarFormat
        result = result.replacingOccurrences(of: "{c}", with: claude.map { "\($0)" } ?? "-")
        result = result.replacingOccurrences(of: "{x}", with: codex.map { "\($0)" } ?? "-")
        result = result.replacingOccurrences(of: "{k}", with: kimi.map { "\($0)" } ?? "-")
        result = result.replacingOccurrences(of: "{claude}", with: "Claude")
        result = result.replacingOccurrences(of: "{codex}", with: "Codex")
        result = result.replacingOccurrences(of: "{kimi}", with: "Kimi")
        // Clean up multiple consecutive spaces
        result = result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
        return result.trimmingCharacters(in: .whitespaces)
    }

    func isProviderEnabled(_ provider: Provider) -> Bool {
        switch provider {
        case .claude: return providerEnabledClaude
        case .codex: return providerEnabledCodex
        case .kimi: return providerEnabledKimi
        }
    }

    var enabledProviders: [Provider] {
        Provider.allCases.filter { isProviderEnabled($0) }
    }

    func isMenuBarVisible(_ provider: Provider) -> Bool {
        guard isProviderEnabled(provider) else { return false }
        switch provider {
        case .claude: return menuBarShowClaude
        case .codex: return menuBarShowCodex
        case .kimi: return menuBarShowKimi
        }
    }

    /// If the currently selected provider was disabled, switch to the first enabled one
    func ensureSelectedProviderEnabled() {
        if !isProviderEnabled(selectedProvider), let first = enabledProviders.first {
            selectedProvider = first
        }
    }

    var selectedProvider: Provider {
        get { Provider(rawValue: selectedProviderRaw) ?? .claude }
        set { selectedProviderRaw = newValue.rawValue }
    }

    var enabledThresholds: [Int] {
        var thresholds: [Int] = []
        if threshold50Enabled { thresholds.append(threshold50Value) }
        if threshold75Enabled { thresholds.append(threshold75Value) }
        if threshold90Enabled { thresholds.append(threshold90Value) }
        return thresholds
    }

    /// Available percentage options for threshold pickers
    static let thresholdOptions: [Int] = Array(stride(from: 10, through: 100, by: 5))

    func cachedPlanLabel(for provider: Provider) -> String {
        switch provider {
        case .claude: return cachedClaudePlanLabel
        case .codex: return cachedCodexPlanLabel
        case .kimi: return cachedKimiPlanLabel
        }
    }

    func setCachedPlanLabel(_ label: String, for provider: Provider) {
        switch provider {
        case .claude: cachedClaudePlanLabel = label
        case .codex: cachedCodexPlanLabel = label
        case .kimi: cachedKimiPlanLabel = label
        }
    }

    private init() {}

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Failed to update launch at login: \(error)")
        }
    }
}
