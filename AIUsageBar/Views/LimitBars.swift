import SwiftUI

struct LimitBar: View {
    let label: String
    let percentage: Double
    let resetTime: String?
    let isEstimated: Bool
    let providerColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isEstimated {
                    Text("(est.)")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primary.opacity(0.1))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(providerColor)
                        .frame(width: geometry.size.width * min(percentage / 100, 1))
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 8)

            if let resetTime = resetTime {
                Text("Resets \(resetTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if percentage == 0 {
                Text("Limit reset")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }
}

struct LimitBars: View {
    let usage: UsageData

    var body: some View {
        VStack(spacing: 16) {
            LimitBar(
                label: usage.provider.primaryWindowLabel,
                percentage: usage.primaryWindow.percentage,
                resetTime: usage.primaryWindow.formattedResetTime,
                isEstimated: usage.primaryWindow.isEstimated,
                providerColor: usage.provider.color
            )

            if let secondary = usage.secondaryWindow {
                LimitBar(
                    label: usage.provider.secondaryWindowLabel,
                    percentage: secondary.percentage,
                    resetTime: secondary.formattedResetTime,
                    isEstimated: secondary.isEstimated,
                    providerColor: usage.provider.color
                )
            }
        }
    }
}
