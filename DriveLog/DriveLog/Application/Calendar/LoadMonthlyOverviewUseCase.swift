import Foundation

nonisolated protocol LoadMonthlyOverviewUseCase: Sendable {
    func execute(month: LocalMonth) async throws -> MonthlyOverviewData
}

nonisolated struct DefaultLoadMonthlyOverviewUseCase: LoadMonthlyOverviewUseCase {
    private let repository: any DerivedDataRepository
    private let mediaCacheRepository: any MediaCacheRepository
    private let mediaPlacementCalculator: any MediaPlacementCalculating
    private let mapSceneBuilder: any MapSceneBuilding
    private let movementFilter: AutomotiveMovementFilter
    private let refreshMediaCache: (any RefreshMediaCacheUseCase)?

    init(
        repository: any DerivedDataRepository,
        mediaCacheRepository: any MediaCacheRepository,
        mediaPlacementCalculator: any MediaPlacementCalculating,
        mapSceneBuilder: any MapSceneBuilding,
        movementFilter: AutomotiveMovementFilter = AutomotiveMovementFilter(),
        refreshMediaCache: (any RefreshMediaCacheUseCase)? = nil
    ) {
        self.repository = repository
        self.mediaCacheRepository = mediaCacheRepository
        self.mediaPlacementCalculator = mediaPlacementCalculator
        self.mapSceneBuilder = mapSceneBuilder
        self.movementFilter = movementFilter
        self.refreshMediaCache = refreshMediaCache
    }

    func execute(month: LocalMonth) async throws -> MonthlyOverviewData {
        do {
            let aggregates = try await repository.aggregates(in: month)
            var movements: [MovementSegmentData] = []
            var stays: [StaySegmentData] = []
            var mediaByIdentifier: [String: MediaAssetReference] = [:]

            for aggregate in aggregates.sorted(by: { $0.localDateKey < $1.localDateKey }) {
                try Task.checkCancellation()
                let dayMovements = try await repository.movementSegments(
                    for: aggregate.localDateKey
                )
                movements.append(contentsOf: movementFilter.retained(dayMovements))
                try await stays.append(contentsOf: repository.staySegments(for: aggregate.localDateKey))
                let dayMedia = try await currentMedia(for: aggregate.localDateKey)
                for asset in dayMedia where asset.location != nil {
                    mediaByIdentifier[asset.localIdentifier] = asset
                }
            }

            let media = mediaByIdentifier.values.sorted(by: mediaOrder)
            let placements = mediaPlacementCalculator.place(
                assets: media,
                movements: movements
            )
            let mapScene = mapSceneBuilder.build(
                movements: movements,
                stays: stays,
                media: placements
            )
            return MonthlyOverviewData(
                month: month,
                mapScene: mapScene,
                movements: movements,
                stays: stays,
                media: media
            )
        } catch let error as DriveLogError {
            throw error
        } catch is CancellationError {
            throw DriveLogError.cancelled
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_monthly_overview")
        }
    }

    private func currentMedia(for localDateKey: String) async throws -> [MediaAssetReference] {
        guard let refreshMediaCache else {
            return try await mediaCacheRepository.cachedAssets(for: localDateKey)
        }
        do {
            return try await refreshMediaCache.execute(localDateKey: localDateKey)
        } catch {
            try Task.checkCancellation()
            return try await mediaCacheRepository.cachedAssets(for: localDateKey)
        }
    }

    private func mediaOrder(
        _ first: MediaAssetReference,
        _ second: MediaAssetReference
    ) -> Bool {
        guard first.creationDate == second.creationDate else {
            return (first.creationDate ?? .distantFuture) <
                (second.creationDate ?? .distantFuture)
        }
        return first.localIdentifier < second.localIdentifier
    }
}
