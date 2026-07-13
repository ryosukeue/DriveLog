import Foundation

nonisolated protocol DaySummaryBuilding: Sendable {
    // swiftlint:disable:next function_parameter_count
    func build(
        localDateKey: String,
        sanitizedLocations: SanitizedLocations,
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        mediaCount: Int,
        sourceRawRevision: Int,
        generatedAt: Date
    ) -> DayAggregateData
}

nonisolated struct DaySummaryBuilder: DaySummaryBuilding {
    private let rules: DayValidationRules

    init(rules: DayValidationRules) {
        self.rules = rules
    }

    // swiftlint:disable:next function_parameter_count
    func build(
        localDateKey: String,
        sanitizedLocations: SanitizedLocations,
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        mediaCount: Int,
        sourceRawRevision: Int,
        generatedAt: Date
    ) -> DayAggregateData {
        let totalDistance = movements.reduce(0) { $0 + $1.distanceMeters }
        let totalMovementDuration = movements.reduce(0) { $0 + $1.durationSeconds }
        let automotiveDuration = duration(of: .automotiveLike, in: movements)
        let walkingDuration = duration(of: .walkingLike, in: movements)
        let visibleStays = stays.filter(\.isVisibleByAutomaticRule)
        return DayAggregateData(
            localDateKey: localDateKey,
            totalDistanceMeters: totalDistance,
            totalMovementDurationSeconds: totalMovementDuration,
            startDate: movements.map(\.startDate).min(),
            endDate: movements.map(\.endDate).max(),
            locationRecordCount: sanitizedLocations.accepted.count,
            rejectedLocationCount: sanitizedLocations.rejected.count,
            mediaCountCache: mediaCount,
            automaticClassification: representativeClassification(movements),
            hasValidMovement: totalDistance >= rules.minimumValidDayDistance &&
                movements.count >= rules.minimumValidMovementSegments &&
                sanitizedLocations.accepted.count >= rules.minimumValidLocationPointCount,
            movementSegmentCount: movements.count,
            staySegmentCount: visibleStays.count,
            totalStayDurationSeconds: visibleStays.reduce(0) { $0 + $1.durationSeconds },
            automotiveDurationSeconds: automotiveDuration,
            walkingDurationSeconds: walkingDuration,
            sourceRawRevision: sourceRawRevision,
            generatedAt: generatedAt
        )
    }

    private func duration(
        of classification: AutomaticMovementType,
        in movements: [MovementSegmentData]
    ) -> TimeInterval {
        movements
            .filter { $0.automaticClassification == classification }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    private func representativeClassification(
        _ movements: [MovementSegmentData]
    ) -> AutomaticMovementType {
        let durations: [(AutomaticMovementType, TimeInterval)] = [
            (.automotiveLike, duration(of: .automotiveLike, in: movements)),
            (.walkingLike, duration(of: .walkingLike, in: movements)),
            (.other, duration(of: .other, in: movements))
        ]
        guard let maximum = durations.map(\.1).max(), maximum > 0 else {
            return .other
        }
        let leaders = durations.filter { $0.1 == maximum }
        return leaders.count == 1 ? leaders[0].0 : .other
    }
}
