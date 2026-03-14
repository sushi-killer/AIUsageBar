import Foundation

struct PlanLabelCache {
    private var label: String?
    private var cachedAt: Date?
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 3600) { self.ttl = ttl }

    var cached: String? {
        guard let label, let cachedAt,
              Date().timeIntervalSince(cachedAt) < ttl else { return nil }
        return label
    }

    /// Returns stored label regardless of TTL (stale-while-revalidate)
    var stale: String? { label }

    mutating func store(_ value: String) {
        label = value
        cachedAt = Date()
    }
}
