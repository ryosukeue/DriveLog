@testable import DriveLog
import Foundation
import Testing

@Suite("Automotive movement filter")
struct AutomotiveMovementFilterTests {
    @Test("retains only automotive classifications")
    func retainsAutomotiveOnly() {
        let movements = [
            movement(id: "car", classification: .automotiveLike),
            movement(id: "walk", classification: .walkingLike),
            movement(id: "other", classification: .other)
        ]

        #expect(AutomotiveMovementFilter().retained(movements).map(\.stableID) == ["car"])
    }

    @Test("rebuilds aggregate values from retained movements")
    func rebuildsAggregate() {
        let aggregate = DayAggregateData(
            localDateKey: "2026-07-18", totalDistanceMeters: 2000,
            totalMovementDurationSeconds: 1200,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 1200),
            locationRecordCount: 10, rejectedLocationCount: 0, mediaCountCache: 0,
            automaticClassification: .walkingLike, hasValidMovement: true,
            movementSegmentCount: 2, staySegmentCount: 0, totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 1200,
            sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 1300)
        )
        let movements = [
            movement(id: "car", distance: 1400, duration: 900, classification: .automotiveLike),
            movement(id: "walk", distance: 600, duration: 300, classification: .walkingLike)
        ]

        let result = AutomotiveMovementFilter().aggregate(aggregate, retaining: movements)

        #expect(result.totalDistanceMeters == 1400)
        #expect(result.totalMovementDurationSeconds == 900)
        #expect(result.movementSegmentCount == 1)
        #expect(result.automaticClassification == .automotiveLike)
        #expect(result.hasValidMovement)
    }

    @Test("a walking-only aggregate is invalid for display")
    func walkingOnlyIsInvalid() {
        let aggregate = DayAggregateData(
            localDateKey: "2026-07-18", totalDistanceMeters: 2000,
            totalMovementDurationSeconds: 1200,
            startDate: nil, endDate: nil,
            locationRecordCount: 10, rejectedLocationCount: 0, mediaCountCache: 0,
            automaticClassification: .walkingLike, hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 0, totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 1200,
            sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 1300)
        )

        let result = AutomotiveMovementFilter().aggregate(aggregate, retaining: [
            movement(id: "walk", distance: 2000, duration: 1200, classification: .walkingLike)
        ])

        #expect(result.totalDistanceMeters == 0)
        #expect(!result.hasValidMovement)
        #expect(result.automaticClassification == .other)
    }

    private func movement(
        id: String,
        distance: Double = 1200,
        duration: TimeInterval = 600,
        classification: AutomaticMovementType
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: id,
            localDateKey: "2026-07-18",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: duration),
            distanceMeters: distance,
            durationSeconds: duration,
            estimatedAverageSpeedMetersPerSecond: 10,
            automaticClassification: classification,
            classificationConfidence: .medium,
            route: [], labelCoordinate: nil,
            sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 2000)
        )
    }
}
