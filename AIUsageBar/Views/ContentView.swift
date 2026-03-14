import SwiftUI

struct ContentView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var usageManager = UsageManager.shared
    @Binding var showingSettings: Bool

    private var selectedProvider: Provider {
        settings.selectedProvider
    }

    private var currentUsage: UsageData? {
        usageManager.usage(for: selectedProvider)
    }

    var body: some View {
        if showingSettings {
            SettingsView(showingSettings: $showingSettings)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            // Header showing active provider name (PRD US-008)
            ProviderHeader(provider: selectedProvider)

            // Provider Tabs (hide when only one provider enabled)
            if settings.enabledProviders.count > 1 {
                ProviderTabs(selectedProvider: Binding(
                    get: { settings.selectedProvider },
                    set: { settings.selectedProvider = $0 }
                ))
            }

            // Fixed-height content area to prevent layout jumps between tabs
            VStack(spacing: 16) {
                if let usage = currentUsage {
                    if settings.appTheme == .standard {
                        UsageRing(
                            percentage: usage.displayPercentage,
                            providerColor: usage.provider.color
                        )
                        .frame(width: 120, height: 120)
                        .padding(.vertical, 8)

                        ResetTimer(resetTime: usage.primaryWindow.resetTime)
                    }

                    LimitBars(usage: usage)
                } else {
                    Spacer()

                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("Start using \(selectedProvider.displayName) to see usage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: settings.appTheme == .standard ? 280 : 120, alignment: .top)

            Divider()

            // Footer
            HStack {
                Button {
                    Task {
                        await usageManager.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(usageManager.isLoading)

                if usageManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                }

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            guard !usageManager.hasRecentData else { return }
            await usageManager.refresh()
        }
    }

}
