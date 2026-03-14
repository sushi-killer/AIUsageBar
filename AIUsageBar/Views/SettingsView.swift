import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var usageManager = UsageManager.shared
    @Binding var showingSettings: Bool

    @State private var hasClaudeCredentials = false
    @State private var hasCodexLogs = false
    @State private var hasKimiKey = false
    @State private var kimiAPIKeyField = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    showingSettings = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Appearance
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Picker("Theme", selection: Binding(
                        get: { settings.appTheme },
                        set: { settings.appTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            } label: {
                Text("Appearance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Providers
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Toggle("Claude", isOn: $settings.providerEnabledClaude)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(settings.enabledProviders.count == 1 && settings.providerEnabledClaude)
                        Toggle("Codex", isOn: $settings.providerEnabledCodex)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(settings.enabledProviders.count == 1 && settings.providerEnabledCodex)
                        Toggle("Kimi", isOn: $settings.providerEnabledKimi)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(settings.enabledProviders.count == 1 && settings.providerEnabledKimi)
                    }
                    .onChange(of: settings.providerEnabledClaude) { val in
                        settings.menuBarShowClaude = val
                        settings.ensureSelectedProviderEnabled()
                    }
                    .onChange(of: settings.providerEnabledCodex) { val in
                        settings.menuBarShowCodex = val
                        settings.ensureSelectedProviderEnabled()
                    }
                    .onChange(of: settings.providerEnabledKimi) { val in
                        settings.menuBarShowKimi = val
                        settings.ensureSelectedProviderEnabled()
                    }
                }
            } label: {
                Text("Providers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Menu Bar Format
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Toggle("Claude", isOn: $settings.menuBarShowClaude)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(!settings.providerEnabledClaude)
                        Toggle("Codex", isOn: $settings.menuBarShowCodex)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(!settings.providerEnabledCodex)
                        Toggle("Kimi", isOn: $settings.menuBarShowKimi)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .disabled(!settings.providerEnabledKimi)
}

                    Picker("Format", selection: Binding(
                        get: { settings.menuBarFormat },
                        set: { settings.menuBarFormat = $0 }
                    )) {
                        ForEach(MenuBarFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)

                    if settings.menuBarFormat == .custom {
                        TextField("Template", text: $settings.customMenuBarFormat)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospaced())

                        Text("Placeholders: {c} {x} {k} {claude} {codex} {kimi}")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(settings.formatCustomTemplate(claude: 45, codex: 30, kimi: 20))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text(settings.menuBarFormat.preview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            } label: {
                Text("Menu Bar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Provider Status
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(hasClaudeCredentials ? .green : .red)
                            Text("Claude")
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(hasCodexLogs ? .green : .red)
                            Text("Codex")
                                .font(.caption)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(hasKimiKey ? .green : .red)
                            Text("Kimi")
                                .font(.caption)
                        }

                        Spacer()
                    }

                    SecureField("Kimi API Key (sk-kimi-...)", text: $kimiAPIKeyField)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .onChange(of: kimiAPIKeyField) { _ in
                            settings.kimiAPIKey = kimiAPIKeyField
                            hasKimiKey = !kimiAPIKeyField.isEmpty
                        }
                }
            } label: {
                Text("Provider Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Notifications
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)
                        .toggleStyle(.switch)

                    if settings.notificationsEnabled {
                        if !notificationService.isAuthorized {
                            HStack(spacing: 6) {
                                Text("Disabled in System Settings")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Open Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .font(.caption)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alert Thresholds")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ThresholdPickerRow(
                                label: "Low",
                                isEnabled: $settings.threshold50Enabled,
                                value: $settings.threshold50Value
                            )

                            ThresholdPickerRow(
                                label: "Medium",
                                isEnabled: $settings.threshold75Enabled,
                                value: $settings.threshold75Value
                            )

                            ThresholdPickerRow(
                                label: "High",
                                isEnabled: $settings.threshold90Enabled,
                                value: $settings.threshold90Value
                            )
                        }
                    }
                }
            } label: {
                Text("Notifications")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Startup
            GroupBox {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
            } label: {
                Text("Startup")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Footer
            HStack {
                Text("v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let update = usageManager.availableUpdate {
                    Button("v\(update.version) available") {
                        NSWorkspace.shared.open(update.url)
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(.top, 2)
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            hasClaudeCredentials = KeychainService.shared.hasClaudeCredentials
            hasCodexLogs = Provider.codex.logsPath.map { FileManager.default.fileExists(atPath: $0) } ?? false
            kimiAPIKeyField = settings.kimiAPIKey
            hasKimiKey = !kimiAPIKeyField.isEmpty
            Task {
                await notificationService.checkAuthorization()
            }
        }
    }
}

struct ThresholdPickerRow: View {
    let label: String
    @Binding var isEnabled: Bool
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 8) {
            Toggle(isOn: $isEnabled) {
                Text(label)
                    .font(.caption)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Spacer()

            Picker("", selection: $value) {
                ForEach(AppSettings.thresholdOptions, id: \.self) { option in
                    Text("\(option)%").tag(option)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: 70)
            .disabled(!isEnabled)
        }
    }
}
