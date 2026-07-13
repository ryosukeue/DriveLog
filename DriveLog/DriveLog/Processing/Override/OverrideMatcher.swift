import Foundation

nonisolated protocol OverrideMatching: Sendable {
    func matchClassificationOverride(
        _ override: ClassificationOverrideData,
        to segments: [MovementSegmentData]
    ) -> MovementSegmentData?

    func matchStayOverride(
        _ override: StayOverrideData,
        to stays: [StaySegmentData]
    ) -> StaySegmentData?
}

nonisolated struct OverrideMatcher: OverrideMatching {
    private let rules: OverrideMatchingRules
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: OverrideMatchingRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.distanceCalculator = distanceCalculator
    }

    func matchClassificationOverride(
        _ override: ClassificationOverrideData,
        to segments: [MovementSegmentData]
    ) -> MovementSegmentData? {
        let exactMatches = segments.filter { $0.stableID == override.targetStableID }
        if !exactMatches.isEmpty {
            return unique(exactMatches)
        }
        return unique(segments.filter { segment in
            segment.localDateKey == override.localDateKey &&
                absoluteDifference(segment.startDate, override.originalStartDate) <=
                rules.movementOverrideStartTolerance &&
                absoluteDifference(segment.endDate, override.originalEndDate) <=
                rules.movementOverrideEndTolerance &&
                overlapRatio(
                    firstStart: segment.startDate,
                    firstEnd: segment.endDate,
                    secondStart: override.originalStartDate,
                    secondEnd: override.originalEndDate
                ) >= rules.movementOverrideMinimumOverlap
        })
    }

    func matchStayOverride(
        _ override: StayOverrideData,
        to stays: [StaySegmentData]
    ) -> StaySegmentData? {
        let exactMatches = stays.filter { $0.stableID == override.targetStableID }
        if !exactMatches.isEmpty {
            return unique(exactMatches)
        }
        return unique(stays.filter { stay in
            stay.localDateKey == override.localDateKey &&
                absoluteDifference(stay.estimatedArrivalDate, override.originalArrivalDate) <=
                rules.stayOverrideArrivalTolerance &&
                absoluteDifference(stay.estimatedDepartureDate, override.originalDepartureDate) <=
                rules.stayOverrideDepartureTolerance &&
                distance(from: stay.representativeCoordinate, to: override.originalCoordinate) <=
                rules.stayOverrideCoordinateTolerance + 0.000_001
        })
    }

    private func unique<Element>(_ matches: [Element]) -> Element? {
        matches.count == 1 ? matches[0] : nil
    }

    private func absoluteDifference(_ first: Date, _ second: Date) -> TimeInterval {
        abs(first.timeIntervalSince(second))
    }

    private func overlapRatio(
        firstStart: Date,
        firstEnd: Date,
        secondStart: Date,
        secondEnd: Date
    ) -> Double {
        let firstDuration = firstEnd.timeIntervalSince(firstStart)
        let secondDuration = secondEnd.timeIntervalSince(secondStart)
        let shorterDuration = min(firstDuration, secondDuration)
        guard shorterDuration > 0 else {
            return 0
        }
        let overlap = min(firstEnd, secondEnd).timeIntervalSince(max(firstStart, secondStart))
        return max(0, overlap) / shorterDuration
    }

    private func distance(from first: RouteCoordinate, to second: RouteCoordinate) -> Double {
        distanceCalculator.meters(
            fromLatitude: first.latitude,
            longitude: first.longitude,
            toLatitude: second.latitude,
            longitude: second.longitude
        )
    }
}
