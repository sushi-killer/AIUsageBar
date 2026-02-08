import SwiftUI

struct UsageRing: View {
    let percentage: Double
    let providerColor: Color
    let lineWidth: CGFloat

    @State private var animatedPercentage: Double = 0

    init(percentage: Double, providerColor: Color, lineWidth: CGFloat = 12) {
        self.percentage = percentage
        self.providerColor = providerColor
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.primary.opacity(0.1),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedPercentage / 100)
                .stroke(
                    providerColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: animatedPercentage)

            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(animatedPercentage))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("used")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedPercentage = percentage
            }
        }
        .onChange(of: percentage) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }
}
