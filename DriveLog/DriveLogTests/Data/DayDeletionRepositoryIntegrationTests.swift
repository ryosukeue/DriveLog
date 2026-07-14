@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Day deletion repository integration")
@MainActor
struct DayDeletionRepositoryIntegrationTests {
    private let targetDay = "2024-01-01"
    private let otherDay = "2024-01-02"
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("deletes every V1 model for only the requested day")
    func deletesRequestedDayOnly() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        insertAllModels(day: targetDay, into: context)
        insertAllModels(day: otherDay, into: context)
        try context.save()

        try await SwiftDataDayDeletionRepository(modelContainer: container)
            .deleteDay(localDateKey: targetDay)

        let verification = ModelContext(container)
        #expect(try modelCounts(day: targetDay, context: verification) == emptyCounts)
        #expect(try modelCounts(day: otherDay, context: verification) == fullCounts)
    }

    @Test("deletes orphaned derived user state and media models")
    func deletesOrphans() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        insertOrphanModels(day: targetDay, into: context)
        try context.save()

        try await SwiftDataDayDeletionRepository(modelContainer: container)
            .deleteDay(localDateKey: targetDay)

        #expect(try modelCounts(day: targetDay, context: ModelContext(container)) == emptyCounts)
    }

    @Test("deleting an empty day is idempotent")
    func emptyDay() async throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        insertAllModels(day: otherDay, into: context)
        try context.save()
        let repository = SwiftDataDayDeletionRepository(modelContainer: container)

        try await repository.deleteDay(localDateKey: targetDay)
        try await repository.deleteDay(localDateKey: targetDay)

        #expect(try modelCounts(day: otherDay, context: ModelContext(container)) == fullCounts)
    }

    private var emptyCounts: [Int] {
        Array(repeating: 0, count: 10)
    }

    private var fullCounts: [Int] {
        Array(repeating: 1, count: 10)
    }

    private func modelCounts(day: String, context: ModelContext) throws -> [Int] {
        try [
            context.fetch(FetchDescriptor<LocationEventModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<MotionEventModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<VisitEventModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<DayAggregateModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<MovementSegmentModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<StaySegmentModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<ClassificationOverrideModel>()).count {
                $0.localDateKey == day
            },
            context.fetch(FetchDescriptor<StayOverrideModel>()).count { $0.localDateKey == day },
            context.fetch(FetchDescriptor<DayProcessingStateModel>()).count {
                $0.localDateKey == day
            },
            context.fetch(FetchDescriptor<MediaAssetCacheModel>()).count {
                $0.localDateKey == day
            }
        ]
    }

    private func insertAllModels(day: String, into context: ModelContext) {
        context.insert(location(day: day))
        context.insert(motion(day: day))
        context.insert(visit(day: day))
        insertOrphanModels(day: day, into: context)
        context.insert(aggregate(day: day))
    }

    private func insertOrphanModels(day: String, into context: ModelContext) {
        context.insert(movement(day: day))
        context.insert(stay(day: day))
        context.insert(classificationOverride(day: day))
        context.insert(stayOverride(day: day))
        context.insert(processingState(day: day))
        context.insert(media(day: day))
    }

    private func location(day: String) -> LocationEventModel {
        LocationEventModel(
            latitude: 0, longitude: 0, timestamp: date, horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: date, timeZoneIdentifier: "UTC",
            utcOffsetSeconds: 0, localDateKey: day, deduplicationKey: "location-\(day)"
        )
    }

    private func motion(day: String) -> MotionEventModel {
        MotionEventModel(
            startDate: date, endDate: nil, isAutomotive: false, isWalking: true,
            isRunning: false, isCycling: false, isStationary: false, isUnknown: false,
            confidenceRawValue: 2, createdAt: date, timeZoneIdentifier: "UTC",
            utcOffsetSeconds: 0, localDateKey: day
        )
    }

    private func visit(day: String) -> VisitEventModel {
        VisitEventModel(
            latitude: 0, longitude: 0, arrivalDate: date, departureDate: nil,
            horizontalAccuracy: 10, createdAt: date, updatedAt: date,
            timeZoneIdentifier: "UTC", utcOffsetSeconds: 0, localDateKey: day,
            visitMatchKey: "visit-\(day)"
        )
    }

    private func aggregate(day: String) -> DayAggregateModel {
        DayAggregateModel(
            localDateKey: day, totalDistanceMeters: 1000,
            totalMovementDurationSeconds: 600, startDate: date,
            endDate: date.addingTimeInterval(600), locationRecordCount: 2,
            rejectedLocationCount: 0, mediaCountCache: 1,
            automaticClassificationRawValue: "walkingLike", hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 1, totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 600,
            sourceRawRevision: 1, generatedAt: date
        )
    }

    private func movement(day: String) -> MovementSegmentModel {
        MovementSegmentModel(
            stableID: "movement-\(day)", localDateKey: day, startDate: date,
            endDate: date.addingTimeInterval(600), distanceMeters: 1000,
            durationSeconds: 600, estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassificationRawValue: "walkingLike",
            classificationConfidenceRawValue: "high", encodedRouteData: Data(),
            labelLatitude: nil, labelLongitude: nil, sourceRawRevision: 1,
            generatedAt: date
        )
    }

    private func stay(day: String) -> StaySegmentModel {
        StaySegmentModel(
            stableID: "stay-\(day)", localDateKey: day, representativeLatitude: 0,
            representativeLongitude: 0, estimatedArrivalDate: date,
            estimatedDepartureDate: date.addingTimeInterval(300), durationSeconds: 300,
            confidenceRawValue: "high", sourceRawValue: "visit",
            isVisibleByAutomaticRule: true, sourceRawRevision: 1, generatedAt: date
        )
    }

    private func classificationOverride(day: String) -> ClassificationOverrideModel {
        ClassificationOverrideModel(
            overrideKey: "\(day)|movement", targetStableID: "movement-\(day)",
            localDateKey: day, originalStartDate: date,
            originalEndDate: date.addingTimeInterval(600), userClassificationRawValue: "train",
            createdAt: date, updatedAt: date
        )
    }

    private func stayOverride(day: String) -> StayOverrideModel {
        StayOverrideModel(
            overrideKey: "\(day)|stay", targetStableID: "stay-\(day)", localDateKey: day,
            originalArrivalDate: date, originalDepartureDate: date.addingTimeInterval(300),
            originalLatitude: 0, originalLongitude: 0, actionRawValue: "hide",
            createdAt: date, updatedAt: date
        )
    }

    private func processingState(day: String) -> DayProcessingStateModel {
        DayProcessingStateModel(
            localDateKey: day, rawRevision: 1, processedRevision: 1,
            statusRawValue: "completed", lastAttemptDate: date, lastSuccessfulDate: date,
            lastErrorCode: nil, updatedAt: date
        )
    }

    private func media(day: String) -> MediaAssetCacheModel {
        MediaAssetCacheModel(
            localIdentifier: "asset-\(day)", localDateKey: day, mediaTypeRawValue: "photo",
            creationDate: date, latitude: nil, longitude: nil, durationSeconds: nil,
            isScreenshot: false, isScreenRecording: false, eligibilityRawValue: "eligible",
            lastValidatedAt: date
        )
    }
}
