import Foundation

nonisolated struct ChargingLocationEmissionFilter: Sendable {
    private let minimumInterval: TimeInterval
    private var lastEmissionDate: Date?

    init(minimumInterval: TimeInterval = 60) {
        self.minimumInterval = minimumInterval
    }

    mutating func reset() {
        lastEmissionDate = nil
    }

    mutating func shouldEmit(
        _ timestamp: Date,
        minimumInterval: TimeInterval? = nil
    ) -> Bool {
        guard let lastEmissionDate else {
            lastEmissionDate = timestamp
            return true
        }
        let interval = minimumInterval ?? self.minimumInterval
        guard timestamp.timeIntervalSince(lastEmissionDate) >= interval else {
            return false
        }
        self.lastEmissionDate = timestamp
        return true
    }
}
