import Foundation

nonisolated protocol LocationSanitizing: Sendable {
    func sanitize(_ locations: [LocationEventData]) -> SanitizedLocations
}

nonisolated struct SanitizedLocations: Sendable, Equatable {
    let accepted: [LocationEventData]
    let rejected: [RejectedLocation]
}

nonisolated struct RejectedLocation: Sendable, Equatable {
    let location: LocationEventData
    let reason: RejectedLocationReason
}

nonisolated enum RejectedLocationReason: String, Sendable, Equatable {
    case invalidCoordinate
    case invalidAccuracy
    case futureTimestamp
    case duplicate
    case poorAccuracy
    case implausibleJump
    case invalidSequence
}

nonisolated struct LocationSanitizer: LocationSanitizing {
    private let rules: LocationRules
    private let clock: any Clock

    init(rules: LocationRules, clock: any Clock) {
        self.rules = rules
        self.clock = clock
    }

    func sanitize(_ locations: [LocationEventData]) -> SanitizedLocations {
        let now = clock.now
        var accepted: [LocationEventData] = []
        var rejected: [RejectedLocation] = []

        for location in sorted(locations) {
            if let reason = rejectionReason(for: location, now: now) {
                rejected.append(RejectedLocation(location: location, reason: reason))
            } else {
                accepted.append(location)
            }
        }

        return SanitizedLocations(accepted: accepted, rejected: rejected)
    }

    private func sorted(_ locations: [LocationEventData]) -> [LocationEventData] {
        locations.enumerated().sorted { lhs, rhs in
            let left = lhs.element
            let right = rhs.element
            let leftTimestamp = timestampSortValue(left.timestamp)
            let rightTimestamp = timestampSortValue(right.timestamp)
            if leftTimestamp != rightTimestamp {
                return leftTimestamp < rightTimestamp
            }
            if left.horizontalAccuracy != right.horizontalAccuracy {
                return accuracySortValue(left.horizontalAccuracy) < accuracySortValue(right.horizontalAccuracy)
            }
            if left.createdAt != right.createdAt {
                return left.createdAt < right.createdAt
            }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func accuracySortValue(_ accuracy: Double) -> Double {
        accuracy.isFinite ? accuracy : .infinity
    }

    private func timestampSortValue(_ date: Date) -> TimeInterval {
        let value = date.timeIntervalSinceReferenceDate
        return value.isFinite ? value : .infinity
    }

    private func rejectionReason(
        for location: LocationEventData,
        now: Date
    ) -> RejectedLocationReason? {
        guard location.latitude.isFinite,
              location.longitude.isFinite,
              (-90 ... 90).contains(location.latitude),
              (-180 ... 180).contains(location.longitude)
        else {
            return .invalidCoordinate
        }
        guard location.horizontalAccuracy.isFinite, location.horizontalAccuracy >= 0 else {
            return .invalidAccuracy
        }
        let timestamp = location.timestamp.timeIntervalSinceReferenceDate
        guard timestamp.isFinite,
              location.timestamp.timeIntervalSince(now) < rules.futureTimestampTolerance
        else {
            return .futureTimestamp
        }
        return nil
    }
}
