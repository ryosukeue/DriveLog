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
        var valid: [LocationEventData] = []
        var rejected: [RejectedLocation] = []

        for location in sorted(locations) {
            if let reason = rejectionReason(for: location, now: now) {
                rejected.append(RejectedLocation(location: location, reason: reason))
            } else {
                valid.append(location)
            }
        }

        let deduplicated = removeDuplicates(from: valid)
        rejected.append(contentsOf: deduplicated.rejected)
        let accuracyFiltered = removePoorAccuracy(from: deduplicated.accepted)
        rejected.append(contentsOf: accuracyFiltered.rejected)
        return SanitizedLocations(accepted: accuracyFiltered.accepted, rejected: sorted(rejected))
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

    private func sorted(_ rejected: [RejectedLocation]) -> [RejectedLocation] {
        rejected.enumerated().sorted { lhs, rhs in
            let left = lhs.element.location
            let right = rhs.element.location
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

    private func removeDuplicates(from locations: [LocationEventData]) -> SanitizedLocations {
        var accepted: [LocationEventData] = []
        var rejected: [RejectedLocation] = []

        for location in locations {
            let duplicateIndices = accepted.indices.filter {
                isDuplicate(location, of: accepted[$0])
            }
            guard !duplicateIndices.isEmpty else {
                accepted.append(location)
                continue
            }

            let bestExistingIndex = duplicateIndices.reduce(duplicateIndices[0]) { best, candidate in
                isPreferred(accepted[candidate], over: accepted[best]) ? candidate : best
            }
            if isPreferred(location, over: accepted[bestExistingIndex]) {
                for index in duplicateIndices.reversed() {
                    rejected.append(RejectedLocation(location: accepted.remove(at: index), reason: .duplicate))
                }
                accepted.append(location)
            } else {
                rejected.append(RejectedLocation(location: location, reason: .duplicate))
            }
        }

        return SanitizedLocations(accepted: sorted(accepted), rejected: rejected)
    }

    private func removePoorAccuracy(from locations: [LocationEventData]) -> SanitizedLocations {
        var accepted: [LocationEventData] = []
        var rejected: [RejectedLocation] = []

        for location in locations {
            if location.horizontalAccuracy > rules.maximumHorizontalAccuracy {
                rejected.append(RejectedLocation(location: location, reason: .poorAccuracy))
            } else {
                accepted.append(location)
            }
        }

        return SanitizedLocations(accepted: accepted, rejected: rejected)
    }

    private func isDuplicate(_ location: LocationEventData, of candidate: LocationEventData) -> Bool {
        let timeInterval = abs(location.timestamp.timeIntervalSince(candidate.timestamp))
        return timeInterval <= rules.duplicateTimeInterval &&
            surfaceDistance(from: location, to: candidate) <= rules.duplicateDistance
    }

    private func isPreferred(_ location: LocationEventData, over candidate: LocationEventData) -> Bool {
        if location.horizontalAccuracy != candidate.horizontalAccuracy {
            return location.horizontalAccuracy < candidate.horizontalAccuracy
        }
        if location.timestamp != candidate.timestamp {
            return location.timestamp > candidate.timestamp
        }
        return location.createdAt < candidate.createdAt
    }

    private func surfaceDistance(from start: LocationEventData, to end: LocationEventData) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let latitudeDelta = radians(end.latitude - start.latitude)
        let longitudeDelta = radians(end.longitude - start.longitude)
        let startLatitude = radians(start.latitude)
        let endLatitude = radians(end.latitude)
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2) +
            cos(startLatitude) * cos(endLatitude) *
            sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return 2 * earthRadiusMeters * atan2(sqrt(haversine), sqrt(max(0, 1 - haversine)))
    }

    private func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
