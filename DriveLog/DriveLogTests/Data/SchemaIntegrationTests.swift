@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("SwiftData schema integration")
@MainActor
struct SchemaIntegrationTests {
    @Test("V1 schema declares version and all designed models")
    func schemaDeclaration() {
        #expect(DriveLogSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(DriveLogSchemaV1.models.count == 10)
        #expect(DriveLogMigrationPlan.schemas.count == 1)
        #expect(DriveLogMigrationPlan.stages.isEmpty)
    }

    @Test("In-memory container saves and fetches every V1 model")
    func inMemoryContainerRoundTrip() throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        context.insert(location())
        context.insert(motion())
        context.insert(visit())
        context.insert(processingState())
        context.insert(aggregate())
        context.insert(movement())
        context.insert(stay())
        context.insert(classificationOverride())
        context.insert(stayOverride())
        context.insert(media())

        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<LocationEventModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MotionEventModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<VisitEventModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DayProcessingStateModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<DayAggregateModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MovementSegmentModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<StaySegmentModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<ClassificationOverrideModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<StayOverrideModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<MediaAssetCacheModel>()) == 1)
    }

    private var date: Date {
        Date(timeIntervalSince1970: 1_700_000_000)
    }

    private var key: String {
        "2023-11-15"
    }

    private func location() -> LocationEventModel {
        LocationEventModel(
            latitude: 35, longitude: 139, timestamp: date, horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: key, deduplicationKey: "location"
        )
    }

    private func motion() -> MotionEventModel {
        MotionEventModel(
            startDate: date, endDate: nil, isAutomotive: true, isWalking: false,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidenceRawValue: 2, createdAt: date, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: key
        )
    }

    private func visit() -> VisitEventModel {
        VisitEventModel(
            latitude: 35, longitude: 139, arrivalDate: date, departureDate: nil,
            horizontalAccuracy: 20, createdAt: date, updatedAt: date,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: key, visitMatchKey: "visit"
        )
    }

    private func processingState() -> DayProcessingStateModel {
        DayProcessingStateModel(
            localDateKey: key, rawRevision: 1, processedRevision: 1,
            statusRawValue: "completed", lastAttemptDate: date, lastSuccessfulDate: date,
            lastErrorCode: nil, updatedAt: date
        )
    }

    private func aggregate() -> DayAggregateModel {
        DayAggregateModel(
            localDateKey: key, totalDistanceMeters: 1500, totalMovementDurationSeconds: 600,
            startDate: date, endDate: date.addingTimeInterval(600), locationRecordCount: 2,
            rejectedLocationCount: 0, mediaCountCache: 1,
            automaticClassificationRawValue: "automotiveLike", hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 1, totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 600, walkingDurationSeconds: 0,
            sourceRawRevision: 1, generatedAt: date
        )
    }

    private func movement() -> MovementSegmentModel {
        MovementSegmentModel(
            stableID: "movement", localDateKey: key, startDate: date,
            endDate: date.addingTimeInterval(600), distanceMeters: 1500,
            durationSeconds: 600, estimatedAverageSpeedMetersPerSecond: 2.5,
            automaticClassificationRawValue: "automotiveLike",
            classificationConfidenceRawValue: "high", encodedRouteData: Data([1]),
            labelLatitude: nil, labelLongitude: nil, sourceRawRevision: 1, generatedAt: date
        )
    }

    private func stay() -> StaySegmentModel {
        StaySegmentModel(
            stableID: "stay", localDateKey: key, representativeLatitude: 35,
            representativeLongitude: 139, estimatedArrivalDate: date,
            estimatedDepartureDate: date.addingTimeInterval(300), durationSeconds: 300,
            confidenceRawValue: "high", sourceRawValue: "visit",
            isVisibleByAutomaticRule: true, sourceRawRevision: 1, generatedAt: date
        )
    }

    private func classificationOverride() -> ClassificationOverrideModel {
        ClassificationOverrideModel(
            overrideKey: "day|movement", targetStableID: "movement", localDateKey: key,
            originalStartDate: date, originalEndDate: date.addingTimeInterval(600),
            userClassificationRawValue: "train", createdAt: date, updatedAt: date
        )
    }

    private func stayOverride() -> StayOverrideModel {
        StayOverrideModel(
            overrideKey: "day|stay", targetStableID: "stay", localDateKey: key,
            originalArrivalDate: date, originalDepartureDate: date.addingTimeInterval(300),
            originalLatitude: 35, originalLongitude: 139, actionRawValue: "confirm",
            createdAt: date, updatedAt: date
        )
    }

    private func media() -> MediaAssetCacheModel {
        MediaAssetCacheModel(
            localIdentifier: "asset", localDateKey: key, mediaTypeRawValue: "photo",
            creationDate: date, latitude: nil, longitude: nil, durationSeconds: nil,
            isScreenshot: false, isScreenRecording: false, eligibilityRawValue: "eligible",
            lastValidatedAt: date
        )
    }
}
