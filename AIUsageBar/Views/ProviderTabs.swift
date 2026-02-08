import SwiftUI

struct ProviderTabs: View {
    @Binding var selectedProvider: Provider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Provider.allCases) { provider in
                ProviderTab(
                    provider: provider,
                    isSelected: selectedProvider == provider
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedProvider = provider
                    }
                }
            }
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ProviderTab: View {
    let provider: Provider
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(provider.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    isSelected ? provider.color : Color.clear
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
