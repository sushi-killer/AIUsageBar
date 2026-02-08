import SwiftUI

/// Header component showing the active provider name
/// PRD US-008: Header showing active provider name
struct ProviderHeader: View {
    let provider: Provider
    @State private var planLabel: String?

    var body: some View {
        HStack {
            Text(provider.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            if let tier = planLabel {
                Text(tier)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(.tint)
                    .clipShape(Capsule())
                    .transition(.opacity)
            }

            Spacer()
        }
        .task(id: provider) {
            let settings = AppSettings.shared
            let cached = provider == .claude ? settings.cachedClaudePlanLabel : settings.cachedCodexPlanLabel

            if !cached.isEmpty {
                planLabel = cached
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { planLabel = nil }
            }

            let fresh = await loadPlanLabel()
            if fresh != planLabel {
                withAnimation(.easeInOut(duration: 0.2)) { planLabel = fresh }
            }

            if let fresh {
                if provider == .claude { settings.cachedClaudePlanLabel = fresh }
                else { settings.cachedCodexPlanLabel = fresh }
            }
        }
    }

    private func loadPlanLabel() async -> String? {
        switch provider {
        case .claude:
            return await UsageManager.shared.getClaudePlanLabel()
        case .codex:
            return await UsageManager.shared.getCodexPlanLabel()
        }
    }
}

#if DEBUG
struct ProviderHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProviderHeader(provider: .claude)
            ProviderHeader(provider: .codex)
            ProviderHeader(provider: .claude)
        }
        .padding()
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}
#endif
