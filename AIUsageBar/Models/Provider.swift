import SwiftUI

enum Provider: String, CaseIterable, Identifiable, Codable {
    case claude
    case codex

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        }
    }

    var color: Color {
        switch self {
        case .claude: return Color(hex: "C75B39") // Terracotta
        case .codex: return Color(hex: "10B981")  // Green
        }
    }

    var primaryWindowLabel: String {
        return "5-Hour"
    }

    var secondaryWindowLabel: String {
        switch self {
        case .claude: return "Weekly"
        case .codex: return "Weekly"
        }
    }

    var logsPath: String {
        switch self {
        case .claude:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/projects").path
        case .codex:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".codex/sessions").path
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
