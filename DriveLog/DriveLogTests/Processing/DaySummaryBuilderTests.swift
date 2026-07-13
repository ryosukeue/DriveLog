@testable import DriveLog
import Foundation
import Testing

@Suite("Day summary builder")
struct DaySummaryBuilderTests {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let builder = DaySummaryBuilder(rules: ProcessingConfiguration.mvp.dayValidation)

    @Test("aggregates movement stay location media and metadata fields")
    func aggregateFields() {
        let sanitized = SanitizedLocations(
            accepted: [location(seconds: 0), location(seconds: 1)],
            rejected: [RejectedLocation(location: location(seconds: 2), reason: .poorAccuracy)]
        )
        let movements = [
            movement(id: "walk", start: 100, duration: 600, distance: 600, classification: .walkingLike),
            movement(id: "car", start: 0, duration: 1200, distance: 1400, classification: .automotiveLike)
        ]
        let stays = [
            stay(id: "visible", duration: 300, visible: true),
            stay(id: "hidden", duration: 900, visible: false)
        ]
        let generatedAt = baseDate.addingTimeInterval(5000)

        let result = builder.build(
            localDateKey: "2024-01-01",
            sanitizedLocations: sanitized,
            movements: movements,
            stays: stays,
            mediaCount: 7,
            sourceRawRevision: 9,
            generatedAt: generatedAt
        )

        #expect(result.localDateKey == "2024-01-01")
        #expect(result.totalDistanceMeters == 2000)
        #expect(result.totalMovementDurationSeconds == 1800)
        #expect(result.startDate == baseDate)
        #expect(result.endDate == baseDate.addingTimeInterval(1200))
        #expect(result.locationRecordCount == 2)
        #expect(result.rejectedLocationCount == 1)
        #expect(result.mediaCountCache == 7)
        #expect(result.movementSegmentCount == 2)
        #expect(result.staySegmentCount == 1)
        #expect(result.totalStayDurationSeconds == 300)
        #expect(result.automotiveDurationSeconds == 1200)
        #expect(result.walkingDurationSeconds == 600)
        #expect(result.automaticClassification == .automotiveLike)
        #expect(result.hasValidMovement)
        #expect(result.sourceRawRevision == 9)
        #expect(result.generatedAt == generatedAt)
    }

    @Test("uses other for tied or missing representative classification")
    func representativeClassificationTies() {
        let tied = [
            movement(id: "car", start: 0, duration: 600, distance: 500, classification: .automotiveLike),
            movement(id: "walk", start: 600, duration: 600, distance: 500, classification: .walkingLike)
        ]

        #expect(build(movements: tied).automaticClassification == .other)
        #expect(build(movements: []).automaticClassification == .other)
    }

    @Test("includes the valid day distance segment and point boundaries")
    func validDayBoundaries() {
        let validMovement = movement(
            id: "valid", start: 0, duration: 600, distance: 1000, classification: .other
        )

        #expect(build(movements: [validMovement], acceptedCount: 2).hasValidMovement)
        #expect(!build(movements: [movement(
            id: "short", start: 0, duration: 600, distance: 999.999, classification: .other
        )], acceptedCount: 2).hasValidMovement)
        #expect(!build(movements: [], acceptedCount: 2).hasValidMovement)
        #expect(!build(movements: [validMovement], acceptedCount: 1).hasValidMovement)
    }

    @Test("builds an empty aggregate when every location is rejected")
    func emptyAndAllRejected() {
        let rejected = [
            RejectedLocation(location: location(seconds: 0), reason: .implausibleJump),
            RejectedLocation(location: location(seconds: 1), reason: .implausibleJump)
        ]
        let result = builder.build(
            localDateKey: "2024-01-01",
            sanitizedLocations: SanitizedLocations(accepted: [], rejected: rejected),
            movements: [],
            stays: [],
            mediaCount: 0,
            sourceRawRevision: 3,
            generatedAt: baseDate
        )

        #expect(result.totalDistanceMeters == 0)
        #expect(result.totalMovementDurationSeconds == 0)
        #expect(result.startDate == nil)
        #expect(result.endDate == nil)
        #expect(result.locationRecordCount == 0)
        #expect(result.rejectedLocationCount == 2)
        #expect(!result.hasValidMovement)
    }

    private func build(
        movements: [MovementSegmentData],
        acceptedCount: Int = 2
    ) -> DayAggregateData {
        builder.build(
            localDateKey: "2024-01-01",
            sanitizedLocations: SanitizedLocations(
                accepted: (0 ..< acceptedCount).map { location(seconds: TimeInterval($0)) },
                rejected: []
            ),
            movements: movements,
            stays: [],
            mediaCount: 0,
            sourceRawRevision: 1,
            generatedAt: baseDate
        )
    }

    private func movement(
        id: String,
        start: TimeInterval,
        duration: TimeInterval,
        distance: Double,
        classification: AutomaticMovementType
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: id,
            localDateKey: "2024-01-01",
            startDate: baseDate.addingTimeInterval(start),
            endDate: baseDate.addingTimeInterval(start + duration),
            distanceMeters: distance,
            durationSeconds: duration,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: classification,
            classificationConfidence: .medium,
            route: [],
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: baseDate
        )
    }

    private func stay(id: String, duration: TimeInterval, visible: Bool) -> StaySegmentData {
        StaySegmentData(
            stableID: id,
            localDateKey: "2024-01-01",
            representativeCoordinate: RouteCoordinate(latitude: 0, longitude: 0),
            estimatedArrivalDate: baseDate,
            estimatedDepartureDate: baseDate.addingTimeInterval(duration),
            durationSeconds: duration,
            confidence: .medium,
            source: .combined,
            isVisibleByAutomaticRule: visible,
            sourceRawRevision: 1,
            generatedAt: baseDate
        )
    }

    private func location(seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 35,
            longitude: 139,
            timestamp: baseDate.addingTimeInterval(seconds),
            horizontalAccuracy: 10,
            speedMetersPerSecond: nil,
            createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400,
            localDateKey: "2024-01-01"
        )
    }
}
