import SwiftUI

enum UsageStatus: String, Codable {
    case green
    case yellow
    case red

    var color: Color {
        switch self {
        case .green: return Color(hex: "4A9B6E")
        case .yellow: return Color(hex: "D4A03D")
        case .red: return Color(hex: "C75B39")
        }
    }

    static func from(percentage: Double) -> UsageStatus {
        if percentage >= 90 {
            return .red
        } else if percentage >= 75 {
            return .yellow
        } else {
            return .green
        }
    }
}

enum DataSource: String, Codable {
    case api
    case local
}

struct UsageWindow: Identifiable, Codable, Equatable {
    let id: UUID
    let percentage: Double
    let resetTime: Date?
    let isEstimated: Bool

    init(id: UUID = UUID(), percentage: Double, resetTime: Date? = nil, isEstimated: Bool = false) {
        self.id = id
        self.percentage = percentage
        self.resetTime = resetTime
        self.isEstimated = isEstimated
    }

    private static let resetTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter
    }()

    var formattedResetTime: String? {
        guard let resetTime = resetTime else { return nil }

        if resetTime.timeIntervalSince(Date()) <= 0 {
            return "now"
        }

        return Self.resetTimeFormatter.string(from: resetTime)
    }
}

struct UsageData: Identifiable, Codable, Equatable {
    let id: UUID
    let provider: Provider
    let primaryWindow: UsageWindow
    let secondaryWindow: UsageWindow?
    let tokensUsed: Int?
    let dataSource: DataSource
    let lastUpdated: Date

    init(
        id: UUID = UUID(),
        provider: Provider,
        primaryWindow: UsageWindow,
        secondaryWindow: UsageWindow? = nil,
        tokensUsed: Int? = nil,
        dataSource: DataSource = .local,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.provider = provider
        self.primaryWindow = primaryWindow
        self.secondaryWindow = secondaryWindow
        self.tokensUsed = tokensUsed
        self.dataSource = dataSource
        self.lastUpdated = lastUpdated
    }

    var status: UsageStatus {
        UsageStatus.from(percentage: primaryWindow.percentage)
    }

    var displayPercentage: Double {
        primaryWindow.percentage
    }

    static func empty(for provider: Provider) -> UsageData {
        UsageData(
            provider: provider,
            primaryWindow: UsageWindow(percentage: 0),
            secondaryWindow: nil,
            tokensUsed: nil,
            dataSource: .local
        )
    }
}
