nonisolated protocol LoadDayDetailUseCase: Sendable {
    func execute(localDateKey: String) async throws -> DayDetailData
}

nonisolated struct DefaultLoadDayDetailUseCase: LoadDayDetailUseCase {
    private let derivedRepository: any DerivedDataRepository
    private let overrideRepository: any OverrideRepository
    private let processingStateRepository: any ProcessingStateRepository
    private let mapSceneBuilder: any MapSceneBuilding
    private let overrideMatcher: any OverrideMatching

    init(
        derivedRepository: any DerivedDataRepository,
        overrideRepository: any OverrideRepository,
        processingStateRepository: any ProcessingStateRepository,
        mapSceneBuilder: any MapSceneBuilding,
        overrideMatcher: any OverrideMatching = OverrideMatcher(
            rules: ProcessingConfiguration.mvp.overrideMatching
        )
    ) {
        self.derivedRepository = derivedRepository
        self.overrideRepository = overrideRepository
        self.processingStateRepository = processingStateRepository
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

        guard let aggregate = try await aggregateValue else {
            throw DriveLogError.invalidData
        }
        let movements = try await movementValues
        let stays = try await stayValues
        let classificationOverrides = try await classificationValues
        let stayOverrides = try await stayOverrideValues
        let state = try await stateValue
        let displayMovements = movements.map { movement in
            MovementDisplayData(
                segment: movement,
                userClassification: latestClassification(
                    for: movement,
                    movements: movements,
                    overrides: classificationOverrides
                )
            )
        }
        let displayStays = stays.map { stay in
            StayDisplayData(
                segment: stay,
                overrideAction: latestStayAction(
                    for: stay,
                    stays: stays,
                    overrides: stayOverrides
                )
            )
        }
        let visibleStays = displayStays.map { display in
            copy(display.segment, isVisible: display.isVisible)
        }
        return DayDetailData(
            aggregate: aggregate,
            movements: displayMovements,
            stays: displayStays,
            media: [],
            mapScene: makeMapScene(movements: movements, stays: visibleStays),
            isReprocessing: state.status == .processing ||
                state.rawRevision > state.processedRevision
        )
    }

    private func makeMapScene(
        movements: [MovementSegmentData],
        stays: [StaySegmentData]
    ) -> MapScene {
        mapSceneBuilder.build(movements: movements, stays: stays, media: [])
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
}
