@testable import DriveLog
import Foundation
import Testing

@Suite("Automotive movement filter")
struct AutomotiveMovementFilterTests {
    @Test("retains automotive and other classifications")
    func retainsNonWalkingMovements() {
        let movements = [
            movement(id: "car", classification: .automotiveLike),
            movement(id: "walk", classification: .walkingLike),
            movement(id: "other", classification: .other)
        ]

        #expect(AutomotiveMovementFilter().retained(movements).map(\.stableID) == ["car", "other"])
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
            movement(id: "walk", distance: 600, duration: 300, classification: .walkingLike),
            movement(id: "other", distance: 300, duration: 200, classification: .other)
        ]

        let result = AutomotiveMovementFilter().aggregate(aggregate, retaining: movements)

        #expect(result.totalDistanceMeters == 1700)
        #expect(result.totalMovementDurationSeconds == 1100)
        #expect(result.movementSegmentCount == 2)
        #expect(result.automaticClassification == .automotiveLike)
        #expect(result.automotiveDurationSeconds == 900)
        #expect(result.walkingDurationSeconds == 0)
        #expect(result.hasValidMovement)
    }

    @Test("an other-only aggregate remains eligible for display")
    func otherOnlyIsDisplayed() {
        let aggregate = DayAggregateData(
            localDateKey: "2026-07-18", totalDistanceMeters: 1500,
            totalMovementDurationSeconds: 600,
            startDate: nil, endDate: nil,
            locationRecordCount: 10, rejectedLocationCount: 0, mediaCountCache: 0,
            automaticClassification: .other, hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 0, totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 0,
            sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 1300)
        )

        let result = AutomotiveMovementFilter().aggregate(aggregate, retaining: [
            movement(id: "other", distance: 1500, duration: 600, classification: .other)
        ])

        #expect(result.totalDistanceMeters == 1500)
        #expect(result.hasValidMovement)
        #expect(result.automaticClassification == .other)
        #expect(result.automotiveDurationSeconds == 0)
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
