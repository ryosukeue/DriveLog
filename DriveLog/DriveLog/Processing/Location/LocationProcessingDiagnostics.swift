import Foundation

nonisolated struct LocationProcessingDiagnostics: Sendable, Equatable {
    let receivedCount: Int
    let acceptedCount: Int
    let rejectionCounts: [RejectedLocationReason: Int]
    let accuracyCounts: AccuracyCounts
    let intervalCounts: IntervalCounts
    let continuousGapCount: Int
    let localDayBoundaryCount: Int
    let movementCount: Int
    let discardedMovementCount: Int
    let stationaryDriftDiscardedMovementCount: Int
    let routeInputPointCount: Int
    let routePersistedPointCount: Int

    nonisolated struct AccuracyCounts: Sendable, Equatable {
        var upToTwentyFiveMeters: Int
        var twentyFiveToOneHundredMeters: Int
        var oneHundredToFiveHundredMeters: Int
        var overFiveHundredMeters: Int
        var invalid: Int
    }

    nonisolated struct IntervalCounts: Sendable, Equatable {
        var upToNinetySeconds: Int
        var ninetySecondsToFifteenMinutes: Int
        var fifteenToNinetyMinutes: Int
        var ninetyMinutesOrMore: Int
        var invalid: Int
    }

    init(
        received: [LocationEventData],
        sanitized: SanitizedLocations,
        segmentation: MovementSegmentationResult,
        routePersistedPointCount: Int
    ) {
        receivedCount = received.count
        acceptedCount = sanitized.accepted.count
        rejectionCounts = Dictionary(grouping: sanitized.rejected, by: \.reason)
            .mapValues(\.count)
        accuracyCounts = Self.accuracyCounts(received)
        intervalCounts = Self.intervalCounts(received)
        continuousGapCount = segmentation.gaps.count { $0.reason == .continuousGap }
        localDayBoundaryCount = segmentation.gaps.count { $0.reason == .localDayBoundary }
        movementCount = segmentation.segments.count
        discardedMovementCount = segmentation.discardedSegments.count
        stationaryDriftDiscardedMovementCount = segmentation.stationaryDriftDiscardedCount
        routeInputPointCount = segmentation.segments.reduce(0) { $0 + $1.locations.count }
        self.routePersistedPointCount = routePersistedPointCount
    }

    private static func accuracyCounts(_ locations: [LocationEventData]) -> AccuracyCounts {
        var result = AccuracyCounts(
            upToTwentyFiveMeters: 0,
            twentyFiveToOneHundredMeters: 0,
            oneHundredToFiveHundredMeters: 0,
            overFiveHundredMeters: 0,
            invalid: 0
        )
        for accuracy in locations.map(\.horizontalAccuracy) {
            if !accuracy.isFinite || accuracy < 0 {
                result.invalid += 1
            } else if accuracy <= 25 {
                result.upToTwentyFiveMeters += 1
            } else if accuracy <= 100 {
                result.twentyFiveToOneHundredMeters += 1
            } else if accuracy <= 500 {
                result.oneHundredToFiveHundredMeters += 1
            } else {
                result.overFiveHundredMeters += 1
            }
        }
        return result
    }

    private static func intervalCounts(_ locations: [LocationEventData]) -> IntervalCounts {
        var result = IntervalCounts(
            upToNinetySeconds: 0,
            ninetySecondsToFifteenMinutes: 0,
            fifteenToNinetyMinutes: 0,
            ninetyMinutesOrMore: 0,
            invalid: 0
        )
        let sorted = locations.sorted { $0.timestamp < $1.timestamp }
        for pair in zip(sorted, sorted.dropFirst()) {
            let interval = pair.1.timestamp.timeIntervalSince(pair.0.timestamp)
            if !interval.isFinite || interval <= 0 {
                result.invalid += 1
            } else if interval <= 90 {
                result.upToNinetySeconds += 1
            } else if interval < 15 * 60 {
                result.ninetySecondsToFifteenMinutes += 1
            } else if interval < 90 * 60 {
                result.fifteenToNinetyMinutes += 1
            } else {
                result.ninetyMinutesOrMore += 1
            }
        }
        return result
    }
}
