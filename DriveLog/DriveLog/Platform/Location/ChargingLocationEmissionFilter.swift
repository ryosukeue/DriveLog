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

    mutating func shouldEmit(_ timestamp: Date) -> Bool {
        guard let lastEmissionDate else {
            lastEmissionDate = timestamp
            return true
        }
        guard timestamp.timeIntervalSince(lastEmissionDate) >= minimumInterval else {
            return false
        }
        self.lastEmissionDate = timestamp
        return true
    }
}
