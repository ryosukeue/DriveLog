@testable import DriveLog
import Foundation
import Testing

@Suite("Load day detail use case")
@MainActor
struct LoadDayDetailUseCaseTests {
    @Test("loads aggregate segments sorted media and map scene")
    func load() async throws {
        let fixture = Fixture()
        let result = try await fixture.useCase().execute(localDateKey: fixture.key)

        #expect(result.aggregate == fixture.aggregate)
        #expect(result.movements.map(\.segment) == [fixture.movement])
        #expect(result.stays.map(\.segment) == [fixture.stay])
        #expect(result.media.map(\.localIdentifier) == ["a", "b", "later"])
        #expect(result.media.first?.location == nil)
        #expect(result.mapScene == fixture.scene)
        #expect(!result.isReprocessing)
    }

    @Test("applies the latest movement and stay overrides")
    func overrides() async throws {
        let fixture = Fixture()
        let oldDate = Date(timeIntervalSince1970: 50)
        let newDate = Date(timeIntervalSince1970: 60)
        let classificationOverrides = [
            fixture.classificationOverride(value: .walking, updatedAt: oldDate),
            fixture.classificationOverride(value: .automotive, updatedAt: newDate)
        ]
        let stayOverrides = [
            fixture.stayOverride(action: .confirm, updatedAt: oldDate),
            fixture.stayOverride(action: .hide, updatedAt: newDate)
        ]

        let result = try await fixture.useCase(
            classificationOverrides: classificationOverrides,
            stayOverrides: stayOverrides
        ).execute(localDateKey: fixture.key)

        #expect(result.movements.first?.userClassification == .automotive)
        #expect(result.stays.first?.overrideAction == .hide)
        #expect(result.stays.first?.isVisible == false)
    }

    @Test("reports revision drift and active processing as reprocessing")
    func reprocessing() async throws {
        let fixture = Fixture()
        let revisionDrift = fixture.state(status: .completed, raw: 2, processed: 1)
        let active = fixture.state(status: .processing, raw: 1, processed: 1)

        let driftResult = try await fixture.useCase(state: revisionDrift)
            .execute(localDateKey: fixture.key)
        let activeResult = try await fixture.useCase(state: active)
            .execute(localDateKey: fixture.key)

        #expect(driftResult.isReprocessing)
        #expect(activeResult.isReprocessing)
    }

    @Test("returns invalid data when aggregate is missing")
    func missingAggregate() async {
        let fixture = Fixture()
        await #expect(throws: DriveLogError.invalidData) {
            try await fixture.useCase(hasAggregate: false).execute(localDateKey: fixture.key)
        }
    }

    @Test("preserves DriveLogError and maps unknown failures")
    func errors() async {
        let fixture = Fixture()
        await #expect(throws: DriveLogError.persistenceFailure(code: "fixture")) {
            try await fixture.useCase(error: DriveLogError.persistenceFailure(code: "fixture"))
                .execute(localDateKey: fixture.key)
        }
        await #expect(throws: DriveLogError.persistenceFailure(code: "load_day_detail")) {
            try await fixture.useCase(error: FixtureError.failed)
                .execute(localDateKey: fixture.key)
        }
    }

    @Test("maps unknown media cache failure")
    func mediaError() async {
        let fixture = Fixture()
        await #expect(throws: DriveLogError.persistenceFailure(code: "load_day_detail")) {
            try await fixture.useCase(mediaError: FixtureError.failed)
                .execute(localDateKey: fixture.key)
        }
    }
}

private struct Fixture {
    let key = "2024-01-02"
    let now = Date(timeIntervalSince1970: 100)

    var aggregate: DayAggregateData {
        DayAggregateData(
            localDateKey: key, totalDistanceMeters: 1200,
            totalMovementDurationSeconds: 600, startDate: now, endDate: now.addingTimeInterval(600),
            locationRecordCount: 10, rejectedLocationCount: 2, mediaCountCache: 0,
            automaticClassification: .automotiveLike, hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 1, totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 600, walkingDurationSeconds: 0,
            sourceRawRevision: 1, generatedAt: now
        )
    }

    var movement: MovementSegmentData {
        MovementSegmentData(
            stableID: "movement", localDateKey: key, startDate: now,
            endDate: now.addingTimeInterval(600), distanceMeters: 1200, durationSeconds: 600,
            estimatedAverageSpeedMetersPerSecond: 2, automaticClassification: .automotiveLike,
            classificationConfidence: .high,
            route: [RouteCoordinate(latitude: 35, longitude: 139)], labelCoordinate: nil,
            sourceRawRevision: 1, generatedAt: now
        )
    }

    var stay: StaySegmentData {
        StaySegmentData(
            stableID: "stay", localDateKey: key,
            representativeCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            estimatedArrivalDate: now, estimatedDepartureDate: now.addingTimeInterval(300),
            durationSeconds: 300, confidence: .high, source: .combined,
            isVisibleByAutomaticRule: true, sourceRawRevision: 1, generatedAt: now
        )
    }

    var scene: MapScene {
        MapScene(
            polylines: [MapPolyline(segmentStableID: "scene", coordinates: [])],
            movementLabels: [],
            stayAnnotations: [],
            mediaAnnotations: [
                MapMediaAnnotation(
                    localIdentifier: "later",
                    mediaType: .photo,
                    coordinate: RouteCoordinate(latitude: 35, longitude: 139)
                )
            ],
            initialRegion: nil
        )
    }

    var media: [MediaAssetReference] {
        [
            media(id: "later", offset: 20),
            media(id: "b", offset: 10),
            media(id: "a", offset: 10)
        ]
    }

    func state(status: ProcessingStatus = .completed, raw: Int = 1, processed: Int = 1) -> DayProcessingStateData {
        DayProcessingStateData(
            localDateKey: key, rawRevision: raw, processedRevision: processed, status: status,
            lastAttemptDate: nil, lastSuccessfulDate: nil, lastErrorCode: nil, updatedAt: now
        )
    }

    func useCase(
        hasAggregate: Bool = true,
        classificationOverrides: [ClassificationOverrideData] = [],
        stayOverrides: [StayOverrideData] = [],
        state: DayProcessingStateData? = nil,
        error: (any Error)? = nil,
        mediaError: (any Error)? = nil
    ) -> DefaultLoadDayDetailUseCase {
        DefaultLoadDayDetailUseCase(
            derivedRepository: DayDetailDerivedRepositoryFake(
                aggregate: hasAggregate ? aggregate : nil,
                movement: movement,
                stay: stay,
                error: error
            ),
            overrideRepository: DayDetailOverrideRepositoryFake(
                classifications: classificationOverrides,
                stays: stayOverrides
            ),
            processingStateRepository: DayDetailProcessingRepositoryFake(
                value: state ?? self.state()
            ),
            mediaCacheRepository: DayDetailMediaCacheRepositoryFake(
                assets: media,
                error: mediaError
            ),
            mediaPlacementCalculator: MediaPlacementCalculator(),
            mapSceneBuilder: DayDetailMapBuilderFake(scene: scene)
        )
    }

    private func media(id: String, offset: TimeInterval) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: id,
            mediaType: .photo,
            creationDate: now.addingTimeInterval(offset),
            location: id == "later" ? RouteCoordinate(latitude: 35, longitude: 139) : nil,
            durationSeconds: nil,
            isScreenshot: false,
            isScreenRecording: false
        )
    }

    func classificationOverride(
        value: UserMovementClassification,
        updatedAt: Date
    ) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "\(updatedAt.timeIntervalSince1970)", targetStableID: movement.stableID,
            localDateKey: key, originalStartDate: movement.startDate,
            originalEndDate: movement.endDate, userClassification: value,
            createdAt: updatedAt, updatedAt: updatedAt
        )
    }

    func stayOverride(action: StayOverrideAction, updatedAt: Date) -> StayOverrideData {
        StayOverrideData(
            overrideKey: "\(updatedAt.timeIntervalSince1970)", targetStableID: stay.stableID,
            localDateKey: key, originalArrivalDate: stay.estimatedArrivalDate,
            originalDepartureDate: stay.estimatedDepartureDate,
            originalCoordinate: stay.representativeCoordinate, action: action,
            createdAt: updatedAt, updatedAt: updatedAt
        )
    }
}

private enum FixtureError: Error {
    case failed
}

private struct DayDetailDerivedRepositoryFake: DerivedDataRepository {
    let storedAggregate: DayAggregateData?
    let movement: MovementSegmentData
    let stay: StaySegmentData
    let error: (any Error)?

    init(
        aggregate: DayAggregateData?,
        movement: MovementSegmentData,
        stay: StaySegmentData,
        error: (any Error)?
    ) {
        storedAggregate = aggregate
        self.movement = movement
        self.stay = stay
        self.error = error
    }

    func aggregate(for _: String) throws -> DayAggregateData? {
        if let error {
            throw error
        }
        return storedAggregate
    }

    func aggregates(in _: LocalMonth) -> [DayAggregateData] {
        []
    }

    func movementSegments(for _: String) -> [MovementSegmentData] {
        [movement]
    }

    func staySegments(for _: String) -> [StaySegmentData] {
        [stay]
    }

    func replaceDerivedData(for _: String, result _: DayProcessingResult, processedRevision _: Int) {}
    func deleteDerivedData(for _: String) {}
}

private struct DayDetailOverrideRepositoryFake: OverrideRepository {
    let classifications: [ClassificationOverrideData]
    let stays: [StayOverrideData]

    func classificationOverrides(for _: String) -> [ClassificationOverrideData] {
        classifications
    }

    func stayOverrides(for _: String) -> [StayOverrideData] {
        stays
    }

    func upsertClassificationOverride(_: ClassificationOverrideData) {}
    func upsertStayOverride(_: StayOverrideData) {}
    func deleteOverrides(for _: String) {}
}

private struct DayDetailProcessingRepositoryFake: ProcessingStateRepository {
    let value: DayProcessingStateData

    func state(for _: String) -> DayProcessingStateData {
        value
    }

    func pendingDateKeys() -> [String] {
        []
    }

    func markDirty(localDateKey _: String) {}
    func markProcessing(localDateKey _: String, attemptedAt _: Date) -> DayProcessingRevision {
        DayProcessingRevision(rawRevision: 0, processedRevision: 0)
    }

    func markCompleted(localDateKey _: String, processedRevision _: Int, completedAt _: Date) {}
    func markFailed(localDateKey _: String, code _: String, failedAt _: Date) {}
    func deleteState(for _: String) {}
}

private struct DayDetailMediaCacheRepositoryFake: MediaCacheRepository {
    let assets: [MediaAssetReference]
    let error: (any Error)?

    func cachedAssets(for _: String) throws -> [MediaAssetReference] {
        if let error {
            throw error
        }
        return assets
    }

    func upsertAssets(_: [MediaAssetReference], for _: String, validatedAt _: Date) {}
    func removeAssets(localIdentifiers _: [String]) {}
    func replaceAssets(for _: String, assets _: [MediaAssetReference], validatedAt _: Date) {}
    func deleteCache(for _: String) {}
}

private struct DayDetailMapBuilderFake: MapSceneBuilding {
    let scene: MapScene

    func build(
        movements _: [MovementSegmentData],
        stays _: [StaySegmentData],
        media: [MediaPlacement]
    ) -> MapScene {
        MapScene(
            polylines: scene.polylines,
            movementLabels: scene.movementLabels,
            stayAnnotations: scene.stayAnnotations,
            mediaAnnotations: media.map {
                MapMediaAnnotation(
                    localIdentifier: $0.assetIdentifier,
                    mediaType: $0.mediaType,
                    coordinate: $0.coordinate
                )
            },
            initialRegion: scene.initialRegion
        )
    }
}
