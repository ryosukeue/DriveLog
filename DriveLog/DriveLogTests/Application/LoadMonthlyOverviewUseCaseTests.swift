@testable import DriveLog
import Foundation
import Testing

@Suite("Load monthly overview use case")
struct LoadMonthlyOverviewUseCaseTests {
    @Test("retains non-walking movement and only located media")
    func overview() async throws {
        let day = "2026-07-01"
        let month = LocalMonth(year: 2026, month: 7)
        let start = Date(timeIntervalSince1970: 0)
        let route = [
            RouteCoordinate(latitude: 35, longitude: 139),
            RouteCoordinate(latitude: 35.001, longitude: 139)
        ]
        let repository = MonthlyOverviewRepositoryFake(
            aggregates: [aggregate(day: day)],
            movements: [
                day: [
                    movement(id: "car", classification: .automotiveLike, route: route),
                    movement(id: "walk", classification: .walkingLike, route: route),
                    movement(id: "other", classification: .other, route: route)
                ]
            ],
            stays: [day: [stay(id: "stay")]]
        )
        let media = MonthlyMediaCacheFake(assets: [
            MediaAssetReference(
                localIdentifier: "photo", mediaType: .photo, creationDate: start,
                location: route[0], durationSeconds: nil,
                isScreenshot: false, isScreenRecording: false
            ),
            MediaAssetReference(
                localIdentifier: "no-location", mediaType: .video, creationDate: start,
                location: nil, durationSeconds: 4,
                isScreenshot: false, isScreenRecording: false
            )
        ])
        let useCase = DefaultLoadMonthlyOverviewUseCase(
            repository: repository,
            mediaCacheRepository: media,
            mediaPlacementCalculator: MediaPlacementCalculator(),
            mapSceneBuilder: MapSceneBuilder()
        )

        let result = try await useCase.execute(month: month)

        #expect(result.movements.map(\.stableID) == ["car", "other"])
        #expect(result.media.map(\.localIdentifier) == ["photo"])
        #expect(result.mapScene.polylines.count == 2)
        #expect(result.mapScene.mediaAnnotations.map(\.localIdentifier) == ["photo"])
    }

    @Test("uses the refreshed photo library result instead of deleted cached media")
    func refreshesMedia() async throws {
        let day = "2026-07-01"
        let coordinate = RouteCoordinate(latitude: 35, longitude: 139)
        let repository = MonthlyOverviewRepositoryFake(
            aggregates: [aggregate(day: day)], movements: [:], stays: [:]
        )
        let cached = MonthlyMediaCacheFake(assets: [media(id: "deleted", at: coordinate)])
        let refreshed = MonthlyMediaRefreshFake(assets: [media(id: "current", at: coordinate)])
        let useCase = DefaultLoadMonthlyOverviewUseCase(
            repository: repository,
            mediaCacheRepository: cached,
            mediaPlacementCalculator: MediaPlacementCalculator(),
            mapSceneBuilder: MapSceneBuilder(),
            refreshMediaCache: refreshed
        )

        let result = try await useCase.execute(month: LocalMonth(year: 2026, month: 7))

        #expect(result.media.map(\.localIdentifier) == ["current"])
    }

    @Test("falls back to cached media when refreshing Photos fails")
    func refreshFallback() async throws {
        let day = "2026-07-01"
        let coordinate = RouteCoordinate(latitude: 35, longitude: 139)
        let repository = MonthlyOverviewRepositoryFake(
            aggregates: [aggregate(day: day)], movements: [:], stays: [:]
        )
        let cached = MonthlyMediaCacheFake(assets: [media(id: "cached", at: coordinate)])
        let useCase = DefaultLoadMonthlyOverviewUseCase(
            repository: repository,
            mediaCacheRepository: cached,
            mediaPlacementCalculator: MediaPlacementCalculator(),
            mapSceneBuilder: MapSceneBuilder(),
            refreshMediaCache: MonthlyMediaRefreshFake(
                assets: [], error: .mediaUnavailable
            )
        )

        let result = try await useCase.execute(month: LocalMonth(year: 2026, month: 7))

        #expect(result.media.map(\.localIdentifier) == ["cached"])
    }

    private func aggregate(day: String) -> DayAggregateData {
        DayAggregateData(
            localDateKey: day, totalDistanceMeters: 1000,
            totalMovementDurationSeconds: 600, startDate: nil, endDate: nil,
            locationRecordCount: 2, rejectedLocationCount: 0, mediaCountCache: 2,
            automaticClassification: .automotiveLike, hasValidMovement: true,
            movementSegmentCount: 1, staySegmentCount: 1, totalStayDurationSeconds: 300,
            automotiveDurationSeconds: 600, walkingDurationSeconds: 0,
            sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func movement(
        id: String,
        classification: AutomaticMovementType,
        route: [RouteCoordinate]
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: id, localDateKey: "2026-07-01",
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 600), distanceMeters: 1000,
            durationSeconds: 600, estimatedAverageSpeedMetersPerSecond: 10,
            automaticClassification: classification, classificationConfidence: .medium,
            route: route, labelCoordinate: route.first, sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func stay(id: String) -> StaySegmentData {
        StaySegmentData(
            stableID: id, localDateKey: "2026-07-01",
            representativeCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            estimatedArrivalDate: Date(timeIntervalSince1970: 0),
            estimatedDepartureDate: Date(timeIntervalSince1970: 300),
            durationSeconds: 300, confidence: .medium, source: .combined,
            isVisibleByAutomaticRule: true, sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func media(id: String, at location: RouteCoordinate?) -> MediaAssetReference {
        MediaAssetReference(
            localIdentifier: id,
            mediaType: .photo,
            creationDate: Date(timeIntervalSince1970: 0),
            location: location,
            durationSeconds: nil,
            isScreenshot: false,
            isScreenRecording: false
        )
    }
}

private struct MonthlyMediaRefreshFake: RefreshMediaCacheUseCase {
    let assets: [MediaAssetReference]
    let error: DriveLogError?

    init(assets: [MediaAssetReference], error: DriveLogError? = nil) {
        self.assets = assets
        self.error = error
    }

    func execute(localDateKey _: String) throws -> [MediaAssetReference] {
        if let error {
            throw error
        }
        return assets
    }
}

private struct MonthlyOverviewRepositoryFake: DerivedDataRepository {
    let storedAggregates: [DayAggregateData]
    let storedMovements: [String: [MovementSegmentData]]
    let storedStays: [String: [StaySegmentData]]

    init(
        aggregates: [DayAggregateData],
        movements: [String: [MovementSegmentData]],
        stays: [String: [StaySegmentData]]
    ) {
        storedAggregates = aggregates
        storedMovements = movements
        storedStays = stays
    }

    func aggregate(for _: String) -> DayAggregateData? {
        nil
    }

    func aggregates(in _: LocalMonth) -> [DayAggregateData] {
        storedAggregates
    }

    func movementSegments(for localDateKey: String) -> [MovementSegmentData] {
        storedMovements[localDateKey, default: []]
    }

    func staySegments(for localDateKey: String) -> [StaySegmentData] {
        storedStays[localDateKey, default: []]
    }

    func replaceDerivedData(for _: String, result _: DayProcessingResult, processedRevision _: Int) {}
    func deleteDerivedData(for _: String) {}
}

private struct MonthlyMediaCacheFake: MediaCacheRepository {
    let assets: [MediaAssetReference]

    func cachedAssets(for _: String) -> [MediaAssetReference] {
        assets
    }

    func upsertAssets(
        _: [MediaAssetReference], for _: String, validatedAt _: Date
    ) {}
    func removeAssets(localIdentifiers _: [String]) {}
    func replaceAssets(
        for _: String, assets _: [MediaAssetReference], validatedAt _: Date
    ) {}
    func deleteCache(for _: String) {}
}
