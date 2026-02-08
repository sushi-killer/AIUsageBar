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
        UsageManager.shared.$claudeUsage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButtonAppearance() }
            .store(in: &cancellables)

        UsageManager.shared.$codexUsage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButtonAppearance() }
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
        let claudeUsage = UsageManager.shared.claudeUsage
        let codexUsage = UsageManager.shared.codexUsage
        let format = settings.menuBarFormat

        // Icon tinting based on worst status
        let statuses = [claudeUsage?.status, codexUsage?.status].compactMap { $0 }
        let worstStatus: UsageStatus? = {
            if statuses.contains(.red) { return .red }
            if statuses.contains(.yellow) { return .yellow }
            if statuses.contains(.green) { return .green }
            return nil
        }()

        let image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "AI Usage")
        if let status = worstStatus, status != .green {
            let config = NSImage.SymbolConfiguration(paletteColors: [NSColor(status.color)])
            button.image = image?.withSymbolConfiguration(config)
        } else {
            button.image = image
        }

        // Text formatting
        let claudePct = claudeUsage.map { Int($0.displayPercentage) }
        let codexPct = codexUsage.map { Int($0.displayPercentage) }

        let title: String? = {
            switch format {
            case .iconOnly:
                return nil
            case .custom:
                return settings.formatCustomTemplate(claude: claudePct, codex: codexPct)
            case .short, .full, .percentOnly:
                return formatBuiltIn(format: format, claude: claudePct, codex: codexPct)
            }
        }()

        button.title = title.map { " \($0)" } ?? ""
        button.imagePosition = title != nil ? .imageLeading : .imageOnly
    }

    private func formatBuiltIn(format: MenuBarFormat, claude: Int?, codex: Int?) -> String? {
        switch (claude, codex) {
        case let (c?, x?):
            switch format {
            case .short: return "C:\(c)% X:\(x)%"
            case .full: return "Claude:\(c)% Codex:\(x)%"
            case .percentOnly: return "\(c)% \(x)%"
            default: return nil
            }
        case let (c?, nil):
            switch format {
            case .short: return "C:\(c)%"
            case .full: return "Claude:\(c)%"
            case .percentOnly: return "\(c)%"
            default: return nil
            }
        case let (nil, x?):
            switch format {
            case .short: return "X:\(x)%"
            case .full: return "Codex:\(x)%"
            case .percentOnly: return "\(x)%"
            default: return nil
            }
        case (nil, nil):
            return nil
        }
    }
}
