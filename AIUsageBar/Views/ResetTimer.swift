import SwiftUI

/// Displays a countdown timer to the next reset time.
/// Uses TimelineView for efficient updates - only updates when visible,
/// eliminating CPU usage when the menu bar popover is closed.
struct ResetTimer: View {
    let resetTime: Date?

    var body: some View {
        // TimelineView automatically pauses updates when view is not visible,
        // avoiding CPU usage during idle periods (no timer runs in background)
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(formatTimeRemaining(at: context.date))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatTimeRemaining(at now: Date) -> String {
        guard let resetTime = resetTime else {
            return "--:--"
        }

        let interval = resetTime.timeIntervalSince(now)

        if interval <= 0 {
            return "resetting..."
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
