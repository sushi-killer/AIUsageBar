import Foundation

protocol UsageProvider: Actor {
    func fetchUsage() async -> UsageData?
    func getPlanLabel() async -> String?
}
