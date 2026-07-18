import Foundation

nonisolated struct AutomotiveMovementFilter: Sendable {
    private let dayValidationRules: DayValidationRules

    init(dayValidationRules: DayValidationRules = ProcessingConfiguration.mvp.dayValidation) {
        self.dayValidationRules = dayValidationRules
    }

    func retained(_ movements: [MovementSegmentData]) -> [MovementSegmentData] {
        movements.filter { $0.automaticClassification == .automotiveLike }
    }

    func aggregate(
        _ aggregate: DayAggregateData,
        retaining movements: [MovementSegmentData]
    ) -> DayAggregateData {
        let retainedMovements = retained(movements)
        let distance = retainedMovements.reduce(0) { $0 + $1.distanceMeters }
        let duration = retainedMovements.reduce(0) { $0 + $1.durationSeconds }
        let startDate = retainedMovements.map(\.startDate).min()
        let endDate = retainedMovements.map(\.endDate).max()
        let isValid = distance >= dayValidationRules.minimumValidDayDistance &&
            retainedMovements.count >= dayValidationRules.minimumValidMovementSegments &&
            aggregate.locationRecordCount >= dayValidationRules.minimumValidLocationPointCount
        return DayAggregateData(
            localDateKey: aggregate.localDateKey,
            totalDistanceMeters: distance,
            totalMovementDurationSeconds: duration,
            startDate: startDate,
            endDate: endDate,
            locationRecordCount: aggregate.locationRecordCount,
            rejectedLocationCount: aggregate.rejectedLocationCount,
            mediaCountCache: aggregate.mediaCountCache,
            automaticClassification: retainedMovements.isEmpty ? .other : .automotiveLike,
            hasValidMovement: isValid,
            movementSegmentCount: retainedMovements.count,
            staySegmentCount: aggregate.staySegmentCount,
            totalStayDurationSeconds: aggregate.totalStayDurationSeconds,
            automotiveDurationSeconds: duration,
            walkingDurationSeconds: aggregate.walkingDurationSeconds,
            sourceRawRevision: aggregate.sourceRawRevision,
            generatedAt: aggregate.generatedAt
        )
    }
}
