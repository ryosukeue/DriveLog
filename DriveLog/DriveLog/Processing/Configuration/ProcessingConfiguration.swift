import Foundation

nonisolated struct ProcessingConfiguration: Sendable, Equatable {
    let location: LocationRules
    let segmentation: SegmentationRules
    let stay: StayRules
    let classification: ClassificationRules
    let dayValidation: DayValidationRules
    let overrideMatching: OverrideMatchingRules
    let media: MediaRules
    let route: RouteRules

    static let mvp = ProcessingConfiguration(
        location: LocationRules(
            futureTimestampTolerance: 24 * 60 * 60,
            duplicateTimeInterval: 30,
            duplicateDistance: 10,
            maximumHorizontalAccuracy: 500,
            maximumPlausibleSpeed: 250 / 3.6
        ),
        segmentation: SegmentationRules(
            maximumContinuousGap: 15 * 60,
            minimumSegmentDistance: 100,
            minimumSegmentPointCount: 2,
            minimumSpeedDisplayDuration: 2 * 60,
            minimumSpeedDisplayDistance: 100,
            minimumSpeedDisplayPointCount: 2,
            stationaryDrift: StationaryDriftRules(
                minimumDuration: 5 * 60,
                maximumAverageSpeed: 0.5,
                maximumProgressRatio: 0.4,
                minimumMotionEvidenceDuration: 3 * 60,
                minimumStationaryMotionRatio: 0.6
            )
        ),
        stay: StayRules(
            minimumStayDuration: 3 * 60,
            automaticStayDuration: 5 * 60,
            stayRadius: 150,
            trafficDirectionChangeToleranceDegrees: 45
        ),
        classification: ClassificationRules(
            lowConfidenceWeight: 0.5,
            mediumConfidenceWeight: 0.75,
            highConfidenceWeight: 1,
            automotiveMotionRatio: 0.5,
            automotiveFallbackSpeed: 15 / 3.6,
            automotiveFallbackDistance: 500,
            walkingMotionRatio: 0.4,
            walkingFallbackMaximumSpeed: 8 / 3.6,
            walkingFallbackMaximumDistance: 3000,
            highConfidenceMinimumRatio: 0.7,
            mediumConfidenceMinimumRatio: 0.4
        ),
        dayValidation: DayValidationRules(
            minimumValidDayDistance: 1000,
            minimumValidMovementSegments: 1,
            minimumValidLocationPointCount: 2
        ),
        overrideMatching: OverrideMatchingRules(
            movementOverrideStartTolerance: 15 * 60,
            movementOverrideEndTolerance: 15 * 60,
            movementOverrideMinimumOverlap: 0.5,
            stayOverrideArrivalTolerance: 15 * 60,
            stayOverrideDepartureTolerance: 15 * 60,
            stayOverrideCoordinateTolerance: 300
        ),
        media: MediaRules(maximumRouteMediaDistance: 500),
        route: RouteRules(
            simplificationTolerance: 30,
            minimumPointCountForSimplification: 10,
            routeLabelPrimaryPosition: 0.5,
            routeLabelFallbackPositions: [0.4, 0.45, 0.55, 0.6]
        )
    )
}

nonisolated struct LocationRules: Sendable, Equatable {
    let futureTimestampTolerance: TimeInterval
    let duplicateTimeInterval: TimeInterval
    let duplicateDistance: Double
    let maximumHorizontalAccuracy: Double
    let maximumPlausibleSpeed: Double
}

nonisolated struct SegmentationRules: Sendable, Equatable {
    let maximumContinuousGap: TimeInterval
    let minimumSegmentDistance: Double
    let minimumSegmentPointCount: Int
    let minimumSpeedDisplayDuration: TimeInterval
    let minimumSpeedDisplayDistance: Double
    let minimumSpeedDisplayPointCount: Int
    let stationaryDrift: StationaryDriftRules
}

nonisolated struct StationaryDriftRules: Sendable, Equatable {
    let minimumDuration: TimeInterval
    let maximumAverageSpeed: Double
    let maximumProgressRatio: Double
    let minimumMotionEvidenceDuration: TimeInterval
    let minimumStationaryMotionRatio: Double
}

nonisolated struct StayRules: Sendable, Equatable {
    let minimumStayDuration: TimeInterval
    let automaticStayDuration: TimeInterval
    let stayRadius: Double
    let trafficDirectionChangeToleranceDegrees: Double
}

nonisolated struct ClassificationRules: Sendable, Equatable {
    let lowConfidenceWeight: Double
    let mediumConfidenceWeight: Double
    let highConfidenceWeight: Double
    let automotiveMotionRatio: Double
    let automotiveFallbackSpeed: Double
    let automotiveFallbackDistance: Double
    let walkingMotionRatio: Double
    let walkingFallbackMaximumSpeed: Double
    let walkingFallbackMaximumDistance: Double
    let highConfidenceMinimumRatio: Double
    let mediumConfidenceMinimumRatio: Double
}

nonisolated struct DayValidationRules: Sendable, Equatable {
    let minimumValidDayDistance: Double
    let minimumValidMovementSegments: Int
    let minimumValidLocationPointCount: Int
}

nonisolated struct OverrideMatchingRules: Sendable, Equatable {
    let movementOverrideStartTolerance: TimeInterval
    let movementOverrideEndTolerance: TimeInterval
    let movementOverrideMinimumOverlap: Double
    let stayOverrideArrivalTolerance: TimeInterval
    let stayOverrideDepartureTolerance: TimeInterval
    let stayOverrideCoordinateTolerance: Double
}

nonisolated struct MediaRules: Sendable, Equatable {
    let maximumRouteMediaDistance: Double
}

nonisolated struct RouteRules: Sendable, Equatable {
    let simplificationTolerance: Double
    let minimumPointCountForSimplification: Int
    let routeLabelPrimaryPosition: Double
    let routeLabelFallbackPositions: [Double]
}
