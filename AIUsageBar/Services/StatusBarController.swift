import SwiftUI
import Combine

private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

@MainActor
final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()

    @Published var showingSettings = false

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var hostingController: NSHostingController<ContentView>!
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    override private init() {
        super.init()
        setupStatusItem()
        setupPanel()
        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "AI Usage")
            button.imagePosition = .imageLeading
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }

        updateButtonAppearance()
    }

    private func setupPanel() {
        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let contentView = ContentView(showingSettings: Binding(
            get: { [weak self] in self?.showingSettings ?? false },
            set: { [weak self] in self?.showingSettings = $0 }
        ))
        hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 12
        hostingController.view.layer?.masksToBounds = true

        panel.contentView = hostingController.view
    }

    private func setupSubscriptions() {
        Publishers.MergeMany(
            UsageManager.shared.$claudeUsage.map { _ in () }.eraseToAnyPublisher(),
            UsageManager.shared.$codexUsage.map { _ in () }.eraseToAnyPublisher(),
            UsageManager.shared.$kimiUsage.map { _ in () }.eraseToAnyPublisher()
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] in self?.updateButtonAppearance() }
        .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateButtonAppearance()
            }
            .store(in: &cancellables)

        // React to showingSettings changes by updating the hosted view
        $showingSettings
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateHostedView()
            }
            .store(in: &cancellables)
    }

    private func updateHostedView() {
        let contentView = ContentView(showingSettings: Binding(
            get: { [weak self] in self?.showingSettings ?? false },
            set: { [weak self] in self?.showingSettings = $0 }
        ))
        hostingController.rootView = contentView
    }

    // MARK: - Actions

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showingSettings = false
            showPanel()
        }
    }

    private func showPanel() {
        positionPanel()
        panel.makeKeyAndOrderFront(nil)
        setupEventMonitor()
    }

    private func hidePanel() {
        panel.orderOut(nil)
        removeEventMonitor()
    }

    private func positionPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let panelWidth = panel.frame.width
        let panelHeight = panel.frame.height

        // Center horizontally under the button, position below the menu bar
        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight - 4

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Pattern: set menu -> click -> clear menu (so left-click still works)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        showingSettings = true
        if !panel.isVisible {
            showPanel()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Event Monitor (close panel on outside click)

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let self = self, self.panel.isVisible {
                self.hidePanel()
            }
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Button Appearance

    func updateButtonAppearance() {
        guard let button = statusItem.button else { return }

        let settings = AppSettings.shared
        let claudeUsage = settings.menuBarShowClaude ? UsageManager.shared.claudeUsage : nil
        let codexUsage = settings.menuBarShowCodex ? UsageManager.shared.codexUsage : nil
        let kimiUsage = settings.menuBarShowKimi ? UsageManager.shared.kimiUsage : nil
        let format = settings.menuBarFormat

        let statuses = [claudeUsage?.status, codexUsage?.status, kimiUsage?.status].compactMap { $0 }
        button.image = tintedIcon(for: statuses)

        let claudePct = claudeUsage.map { Int($0.displayPercentage) }
        let codexPct = codexUsage.map { Int($0.displayPercentage) }
        let kimiPct = kimiUsage.map { Int($0.displayPercentage) }

        let title: String? = {
            switch format {
            case .iconOnly:
                return nil
            case .custom:
                return settings.formatCustomTemplate(claude: claudePct, codex: codexPct, kimi: kimiPct)
            case .short, .full, .percentOnly:
                return formatBuiltIn(format: format, claude: claudePct, codex: codexPct, kimi: kimiPct)
            }
        }()

        button.title = title.map { " \($0)" } ?? ""
        button.imagePosition = title != nil ? .imageLeading : .imageOnly
    }

    private func tintedIcon(for statuses: [UsageStatus]) -> NSImage? {
        let image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "AI Usage")
        let worst: UsageStatus? = {
            if statuses.contains(.red) { return .red }
            if statuses.contains(.yellow) { return .yellow }
            if statuses.contains(.green) { return .green }
            return nil
        }()
        guard let worst, worst != .green else { return image }
        let config = NSImage.SymbolConfiguration(paletteColors: [NSColor(worst.color)])
        return image?.withSymbolConfiguration(config)
    }

    private func formatBuiltIn(format: MenuBarFormat, claude: Int?, codex: Int?, kimi: Int?) -> String? {
        let providers: [(short: String, full: String, value: Int?)] = [
            ("C", "Claude", claude),
            ("X", "Codex", codex),
            ("K", "Kimi", kimi),
        ]

        let available = providers.compactMap { p in p.value.map { (p.short, p.full, $0) } }
        guard !available.isEmpty else { return nil }

        switch format {
        case .short:
            return available.map { "\($0.0):\($0.2)%" }.joined(separator: " ")
        case .full:
            return available.map { "\($0.1):\($0.2)%" }.joined(separator: " ")
        case .percentOnly:
            return available.map { "\($0.2)%" }.joined(separator: " ")
        default:
            return nil
        }
    }
}
