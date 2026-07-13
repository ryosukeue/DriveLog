@testable import DriveLog
import Foundation
import Testing

@Suite("SwiftData V1 models")
struct SwiftDataV1ModelTests {
    @Test("Raw event models preserve V1 fields")
    func rawEventModelsPreserveFields() {
        let location = locationModel()
        let motion = motionModel()
        let visit = visitModel()

        #expect(location.deduplicationKey == "location-key")
        #expect(location.speedMetersPerSecond == nil)
        #expect(motion.isAutomotive && motion.isWalking)
        #expect(motion.endDate == nil)
        #expect(visit.visitMatchKey == "visit-key")
        #expect(visit.departureDate == nil)
    }

    @Test("Processing and aggregate models preserve V1 fields")
    func processingModelsPreserveFields() {
        let state = processingStateModel()
        let aggregate = aggregateModel()

        #expect(state.rawRevision == 4)
        #expect(state.lastErrorCode == nil)
        #expect(aggregate.automaticClassificationRawValue == "walkingLike")
        #expect(aggregate.sourceRawRevision == 4)
    }

    @Test("Derived and override models preserve V1 fields")
    func derivedModelsPreserveFields() {
        let movement = movementModel()
        let stay = stayModel()
        let classificationOverride = classificationOverrideModel()
        let stayOverride = stayOverrideModel()

        #expect(movement.encodedRouteData == Data([1, 2, 3]))
        #expect(movement.labelLongitude == nil)
        #expect(stay.sourceRawValue == "combined")
        #expect(classificationOverride.userClassificationRawValue == "train")
        #expect(stayOverride.actionRawValue == "confirm")
    }

    @Test("Media cache preserves optional metadata without media body")
    func mediaCachePreservesFields() {
        let media = MediaAssetCacheModel(
            localIdentifier: "asset-id", localDateKey: localDateKey,
            mediaTypeRawValue: "photo", creationDate: nil, latitude: nil, longitude: nil,
            durationSeconds: nil, isScreenshot: false, isScreenRecording: false,
            eligibilityRawValue: "eligible", lastValidatedAt: date
        )

        #expect(media.localIdentifier == "asset-id")
        #expect(media.creationDate == nil)
        #expect(media.latitude == nil)
        #expect(media.eligibilityRawValue == "eligible")
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private var localDateKey: String {
        "2023-11-15"
    }

    private func locationModel() -> LocationEventModel {
        LocationEventModel(
            latitude: 35, longitude: 139, timestamp: date, horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey,
            deduplicationKey: "location-key"
        )
    }

    private func motionModel() -> MotionEventModel {
        MotionEventModel(
            startDate: date, endDate: nil, isAutomotive: true, isWalking: true,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidenceRawValue: 1, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: localDateKey
        )
    }

    private func visitModel() -> VisitEventModel {
        VisitEventModel(
            latitude: 35, longitude: 139, arrivalDate: date, departureDate: nil,
            horizontalAccuracy: 20, createdAt: date, updatedAt: date,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: localDateKey, visitMatchKey: "visit-key"
        )
    }

    private func processingStateModel() -> DayProcessingStateModel {
        DayProcessingStateModel(
            localDateKey: localDateKey, rawRevision: 4, processedRevision: 3,
            statusRawValue: "pending", lastAttemptDate: date, lastSuccessfulDate: nil,
            lastErrorCode: nil, updatedAt: date
        )
    }

    private func aggregateModel() -> DayAggregateModel {
        DayAggregateModel(
            localDateKey: localDateKey, totalDistanceMeters: 1500,
            totalMovementDurationSeconds: 600, startDate: date,
            endDate: date.addingTimeInterval(600), locationRecordCount: 10,
            rejectedLocationCount: 1, mediaCountCache: 2,
            automaticClassificationRawValue: "walkingLike", hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 1, totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 600,
            sourceRawRevision: 4, generatedAt: date
        )
    }

    private func movementModel() -> MovementSegmentModel {
        MovementSegmentModel(
            stableID: "movement-id", localDateKey: localDateKey, startDate: date,
            endDate: date.addingTimeInterval(600), distanceMeters: 1500,
            durationSeconds: 600, estimatedAverageSpeedMetersPerSecond: 2.5,
            automaticClassificationRawValue: "walkingLike",
            classificationConfidenceRawValue: "high", encodedRouteData: Data([1, 2, 3]),
            labelLatitude: 35, labelLongitude: nil, sourceRawRevision: 4, generatedAt: date
        )
    }

    private func stayModel() -> StaySegmentModel {
        StaySegmentModel(
            stableID: "stay-id", localDateKey: localDateKey, representativeLatitude: 35,
            representativeLongitude: 139, estimatedArrivalDate: date,
            estimatedDepartureDate: date.addingTimeInterval(600), durationSeconds: 600,
            confidenceRawValue: "high", sourceRawValue: "combined",
            isVisibleByAutomaticRule: true, sourceRawRevision: 4, generatedAt: date
        )
    }

    private func classificationOverrideModel() -> ClassificationOverrideModel {
        ClassificationOverrideModel(
            overrideKey: "day|movement", targetStableID: "movement-id",
            localDateKey: localDateKey, originalStartDate: date,
            originalEndDate: date.addingTimeInterval(600), userClassificationRawValue: "train",
            createdAt: date, updatedAt: date
        )
    }

    private func stayOverrideModel() -> StayOverrideModel {
        StayOverrideModel(
            overrideKey: "day|stay", targetStableID: "stay-id", localDateKey: localDateKey,
            originalArrivalDate: date, originalDepartureDate: date.addingTimeInterval(600),
            originalLatitude: 35, originalLongitude: 139, actionRawValue: "confirm",
            createdAt: date, updatedAt: date
        )
    }
}
