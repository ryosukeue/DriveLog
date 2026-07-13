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
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: LocationRules,
        clock: any Clock,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.clock = clock
        self.distanceCalculator = distanceCalculator
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
        let jumpFiltered = removeImplausibleJumps(from: accuracyFiltered.accepted)
        rejected.append(contentsOf: jumpFiltered.rejected)
        return SanitizedLocations(accepted: jumpFiltered.accepted, rejected: sorted(rejected))
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

    private func removeImplausibleJumps(from locations: [LocationEventData]) -> SanitizedLocations {
        var accepted = locations
        var rejected: [RejectedLocation] = []

        while let jumpIndex = firstImplausibleJumpIndex(in: accepted) {
            let removalIndex = implausiblePointIndex(in: accepted, jumpIndex: jumpIndex)
            let reason: RejectedLocationReason = hasValidTimeSequence(
                accepted[jumpIndex], accepted[jumpIndex + 1]
            ) ? .implausibleJump : .invalidSequence
            rejected.append(
                RejectedLocation(location: accepted.remove(at: removalIndex), reason: reason)
            )
        }

        return SanitizedLocations(accepted: accepted, rejected: rejected)
    }

    private func firstImplausibleJumpIndex(in locations: [LocationEventData]) -> Int? {
        guard locations.count >= 2 else {
            return nil
        }
        return (0 ..< locations.count - 1).first {
            estimatedSpeed(from: locations[$0], to: locations[$0 + 1]) > rules.maximumPlausibleSpeed
        }
    }

    private func implausiblePointIndex(
        in locations: [LocationEventData],
        jumpIndex: Int
    ) -> Int {
        let leftIndex = jumpIndex
        let rightIndex = jumpIndex + 1

        let hasPlausibleSuccessor = rightIndex + 1 < locations.count &&
            isPlausible(from: locations[leftIndex], to: locations[rightIndex + 1])
        if hasPlausibleSuccessor {
            return rightIndex
        }
        let hasPlausiblePredecessor = leftIndex > 0 &&
            isPlausible(from: locations[leftIndex - 1], to: locations[rightIndex])
        if hasPlausiblePredecessor {
            return leftIndex
        }
        if locations[leftIndex].horizontalAccuracy > locations[rightIndex].horizontalAccuracy {
            return leftIndex
        }
        return rightIndex
    }

    private func isPlausible(from start: LocationEventData, to end: LocationEventData) -> Bool {
        estimatedSpeed(from: start, to: end) <= rules.maximumPlausibleSpeed
    }

    private func estimatedSpeed(from start: LocationEventData, to end: LocationEventData) -> Double {
        let timeInterval = end.timestamp.timeIntervalSince(start.timestamp)
        guard timeInterval > 0 else {
            return .infinity
        }
        return surfaceDistance(from: start, to: end) / timeInterval
    }

    private func hasValidTimeSequence(_ start: LocationEventData, _ end: LocationEventData) -> Bool {
        end.timestamp > start.timestamp
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
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
    }
}
