import Foundation

nonisolated protocol LoadDayDetailUseCase: Sendable {
    func execute(localDateKey: String) async throws -> DayDetailData
}

nonisolated struct DefaultLoadDayDetailUseCase: LoadDayDetailUseCase {
    private let derivedRepository: any DerivedDataRepository
    private let overrideRepository: any OverrideRepository
    private let processingStateRepository: any ProcessingStateRepository
    private let mediaCacheRepository: any MediaCacheRepository
    private let mediaPlacementCalculator: any MediaPlacementCalculating
    private let mapSceneBuilder: any MapSceneBuilding
    private let overrideMatcher: any OverrideMatching

    init(
        derivedRepository: any DerivedDataRepository,
        overrideRepository: any OverrideRepository,
        processingStateRepository: any ProcessingStateRepository,
        mediaCacheRepository: any MediaCacheRepository,
        mediaPlacementCalculator: any MediaPlacementCalculating,
        mapSceneBuilder: any MapSceneBuilding,
        overrideMatcher: any OverrideMatching = OverrideMatcher(
            rules: ProcessingConfiguration.mvp.overrideMatching
        )
    ) {
        self.derivedRepository = derivedRepository
        self.overrideRepository = overrideRepository
        self.processingStateRepository = processingStateRepository
        self.mediaCacheRepository = mediaCacheRepository
        self.mediaPlacementCalculator = mediaPlacementCalculator
        self.mapSceneBuilder = mapSceneBuilder
        self.overrideMatcher = overrideMatcher
    }

    func execute(localDateKey: String) async throws -> DayDetailData {
        do {
            return try await load(localDateKey: localDateKey)
        } catch let error as DriveLogError {
            throw error
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_day_detail")
        }
    }

    private func load(localDateKey: String) async throws -> DayDetailData {
        async let aggregateValue = derivedRepository.aggregate(for: localDateKey)
        async let movementValues = derivedRepository.movementSegments(for: localDateKey)
        async let stayValues = derivedRepository.staySegments(for: localDateKey)
        async let classificationValues = overrideRepository.classificationOverrides(
            for: localDateKey
        )
        async let stayOverrideValues = overrideRepository.stayOverrides(for: localDateKey)
        async let stateValue = processingStateRepository.state(for: localDateKey)
        async let mediaValue = mediaCacheRepository.cachedAssets(for: localDateKey)

        guard let aggregate = try await aggregateValue else {
            throw DriveLogError.invalidData
        }
        let movements = try await movementValues
        let stays = try await stayValues
        let classificationOverrides = try await classificationValues
        let stayOverrides = try await stayOverrideValues
        let state = try await stateValue
        let media = try await mediaValue.sorted(by: mediaOrder)
        let display = makeDisplayValues(
            aggregate: aggregate,
            movements: movements,
            stays: stays,
            overrides: DisplayOverrides(
                classification: classificationOverrides,
                stay: stayOverrides
            ),
            media: media
        )
        return DayDetailData(
            aggregate: display.aggregate, movements: display.movements, stays: display.stays,
            media: media, mapScene: display.mapScene,
            isReprocessing: state.status == .processing ||
                state.rawRevision > state.processedRevision
        )
    }

    private func makeDisplayValues(
        aggregate: DayAggregateData,
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        overrides: DisplayOverrides,
        media: [MediaAssetReference]
    ) -> DisplayValues {
        let automotiveMovements = AutomotiveMovementFilter().retained(movements)
        let displayAggregate = AutomotiveMovementFilter().aggregate(
            aggregate,
            retaining: movements
        )
        let displayMovements = automotiveMovements.map { movement in
            MovementDisplayData(
                segment: movement,
                userClassification: latestClassification(
                    for: movement,
                    movements: automotiveMovements,
                    overrides: overrides.classification
                )
            )
        }
        let displayStays = stays.map { stay in
            StayDisplayData(
                segment: stay,
                overrideAction: latestStayAction(
                    for: stay,
                    stays: stays,
                    overrides: overrides.stay
                )
            )
        }
        let builtScene = makeMapScene(
            movements: automotiveMovements, stays: displayStays.map(visibleStay), media: media
        )
        let mapScene = OverrideDisplayDataApplier().apply(
            to: builtScene, movements: displayMovements, stays: displayStays
        )
        return DisplayValues(
            aggregate: displayAggregate,
            movements: displayMovements,
            stays: displayStays,
            mapScene: mapScene
        )
    }

    private func mediaOrder(_ first: MediaAssetReference, _ second: MediaAssetReference) -> Bool {
        guard first.creationDate == second.creationDate else {
            return (first.creationDate ?? .distantFuture) < (second.creationDate ?? .distantFuture)
        }
        return first.localIdentifier < second.localIdentifier
    }

    private func visibleStay(_ display: StayDisplayData) -> StaySegmentData {
        copy(display.segment, isVisible: display.isVisible)
    }

    private func makeMapScene(
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        media: [MediaAssetReference]
    ) -> MapScene {
        mapSceneBuilder.build(
            movements: movements,
            stays: stays,
            media: mediaPlacementCalculator.place(assets: media, movements: movements)
        )
    }

    private func latestClassification(
        for movement: MovementSegmentData,
        movements: [MovementSegmentData],
        overrides: [ClassificationOverrideData]
    ) -> UserMovementClassification? {
        overrides.filter {
            overrideMatcher.matchClassificationOverride($0, to: movements)?.stableID ==
                movement.stableID
        }.sorted(by: overrideOrder).last?.userClassification
    }

    private func latestStayAction(
        for stay: StaySegmentData,
        stays: [StaySegmentData],
        overrides: [StayOverrideData]
    ) -> StayOverrideAction? {
        overrides.filter {
            overrideMatcher.matchStayOverride($0, to: stays)?.stableID == stay.stableID
        }.sorted(by: overrideOrder).last?.action
    }

    private func overrideOrder(
        _ first: ClassificationOverrideData,
        _ second: ClassificationOverrideData
    ) -> Bool {
        first.updatedAt == second.updatedAt
            ? first.overrideKey < second.overrideKey
            : first.updatedAt < second.updatedAt
    }

    private func overrideOrder(_ first: StayOverrideData, _ second: StayOverrideData) -> Bool {
        first.updatedAt == second.updatedAt
            ? first.overrideKey < second.overrideKey
            : first.updatedAt < second.updatedAt
    }

    private func copy(_ stay: StaySegmentData, isVisible: Bool) -> StaySegmentData {
        StaySegmentData(
            stableID: stay.stableID,
            localDateKey: stay.localDateKey,
            representativeCoordinate: stay.representativeCoordinate,
            estimatedArrivalDate: stay.estimatedArrivalDate,
            estimatedDepartureDate: stay.estimatedDepartureDate,
            durationSeconds: stay.durationSeconds,
            confidence: stay.confidence,
            source: stay.source,
            isVisibleByAutomaticRule: isVisible,
            sourceRawRevision: stay.sourceRawRevision,
            generatedAt: stay.generatedAt
        )
    }

    private struct DisplayValues {
        let aggregate: DayAggregateData
        let movements: [MovementDisplayData]
        let stays: [StayDisplayData]
        let mapScene: MapScene
    }

    private struct DisplayOverrides {
        let classification: [ClassificationOverrideData]
        let stay: [StayOverrideData]
    }
}
