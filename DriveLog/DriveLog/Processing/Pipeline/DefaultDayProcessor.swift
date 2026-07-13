import Foundation

nonisolated struct DayProcessingResult: Sendable {
    let aggregate: DayAggregateData
    let movements: [MovementSegmentData]
    let stays: [StaySegmentData]
}

nonisolated protocol DayProcessing: Sendable {
    func process(
        localDateKey: String,
        rawEvents: RawDayEvents,
        mediaCount: Int,
        rawRevision: Int
    ) async throws -> DayProcessingResult
}

nonisolated struct DefaultDayProcessor: DayProcessing {
    private let configuration: ProcessingConfiguration
    private let clock: any Clock
    private let stableIDGenerator: any StableIDGenerating
    private let locationSanitizer: any LocationSanitizing
    private let dayBoundarySplitter: any LocalDayBoundarySplitting
    private let movementSegmenter: any MovementSegmenting
    private let movementClassifier: any MovementClassifying
    private let routeSimplifier: any RouteSimplifying
    private let routeLabelPlacer: any RouteLabelPlacing
    private let summaryBuilder: any DaySummaryBuilding
    private let overrideMatcher: any OverrideMatching

    init(
        configuration: ProcessingConfiguration = .mvp,
        clock: any Clock,
        stableIDGenerator: any StableIDGenerating = SHA256StableIDGenerator()
    ) {
        self.configuration = configuration
        self.clock = clock
        self.stableIDGenerator = stableIDGenerator
        locationSanitizer = LocationSanitizer(rules: configuration.location, clock: clock)
        dayBoundarySplitter = LocalDayBoundarySplitter()
        movementSegmenter = MovementSegmenter(
            segmentationRules: configuration.segmentation,
            stayRules: configuration.stay
        )
        movementClassifier = MovementClassifier(rules: configuration.classification)
        routeSimplifier = RouteSimplifier(rules: configuration.route)
        routeLabelPlacer = RouteLabelPlacer(rules: configuration.route)
        summaryBuilder = DaySummaryBuilder(rules: configuration.dayValidation)
        overrideMatcher = OverrideMatcher(rules: configuration.overrideMatching)
    }

    func process(
        localDateKey: String,
        rawEvents: RawDayEvents,
        mediaCount: Int,
        rawRevision: Int
    ) async throws -> DayProcessingResult {
        try Task.checkCancellation()
        let generatedAt = clock.now
        let allSanitizedLocations = locationSanitizer.sanitize(rawEvents.locations)
        let dayEvents = dayBoundarySplitter.split(rawEvents: rawEvents)[localDateKey] ?? .empty
        let sanitizedLocations = selectedLocations(
            from: allSanitizedLocations,
            localDateKey: localDateKey
        )

        try Task.checkCancellation()
        let segmentation = movementSegmenter.segment(
            locations: sanitizedLocations,
            motions: dayEvents.motions,
            visits: dayEvents.visits
        )
        let stayDetector = StayDetector(
            rules: configuration.stay,
            stableIDGenerator: stableIDGenerator,
            sourceRawRevision: rawRevision,
            generatedAt: generatedAt
        )
        let automaticStays = stayDetector.detect(
            segmentation: segmentation,
            motions: dayEvents.motions,
            visits: dayEvents.visits,
            overrides: []
        )
        let effectiveStays = applyingStayOverrides(dayEvents.stayOverrides, to: automaticStays)

        try Task.checkCancellation()
        let unlabeledMovements = segmentation.segments.map { candidate in
            movement(
                from: candidate,
                motions: dayEvents.motions,
                rawRevision: rawRevision,
                generatedAt: generatedAt
            )
        }
        let movements = addingLabels(to: unlabeledMovements, stays: effectiveStays)

        try Task.checkCancellation()
        let aggregate = summaryBuilder.build(
            localDateKey: localDateKey,
            sanitizedLocations: sanitizedLocations,
            movements: movements,
            stays: effectiveStays,
            mediaCount: mediaCount,
            sourceRawRevision: rawRevision,
            generatedAt: generatedAt
        )
        return DayProcessingResult(aggregate: aggregate, movements: movements, stays: automaticStays)
    }

    private func selectedLocations(
        from locations: SanitizedLocations,
        localDateKey: String
    ) -> SanitizedLocations {
        SanitizedLocations(
            accepted: locations.accepted.filter { $0.localDateKey == localDateKey },
            rejected: locations.rejected.filter { $0.location.localDateKey == localDateKey }
        )
    }

    private func movement(
        from candidate: MovementSegmentCandidate,
        motions: [MotionEventData],
        rawRevision: Int,
        generatedAt: Date
    ) -> MovementSegmentData {
        let classification = movementClassifier.classify(segment: candidate, motions: motions)
        let rawRoute = candidate.locations.map {
            RouteCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        return MovementSegmentData(
            stableID: stableIDGenerator.movementSegmentID(
                localDateKey: candidate.localDateKey,
                startDate: candidate.startDate,
                endDate: candidate.endDate
            ),
            localDateKey: candidate.localDateKey,
            startDate: candidate.startDate,
            endDate: candidate.endDate,
            distanceMeters: candidate.distanceMeters,
            durationSeconds: candidate.durationSeconds,
            estimatedAverageSpeedMetersPerSecond: candidate.estimatedAverageSpeedMetersPerSecond,
            automaticClassification: classification.automaticType,
            classificationConfidence: classification.confidence,
            route: routeSimplifier.simplify(rawRoute),
            labelCoordinate: nil,
            sourceRawRevision: rawRevision,
            generatedAt: generatedAt
        )
    }

    private func addingLabels(
        to movements: [MovementSegmentData],
        stays: [StaySegmentData]
    ) -> [MovementSegmentData] {
        var occupiedCoordinates = stays
            .filter(\.isVisibleByAutomaticRule)
            .map(\.representativeCoordinate)
        return movements.map { movement in
            let label = routeLabelPlacer.makeLabel(
                for: movement,
                occupiedCoordinates: occupiedCoordinates
            )
            occupiedCoordinates.append(label.coordinate)
            return copy(movement, labelCoordinate: label.coordinate)
        }
    }

    private func copy(
        _ movement: MovementSegmentData,
        labelCoordinate: RouteCoordinate
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: movement.stableID,
            localDateKey: movement.localDateKey,
            startDate: movement.startDate,
            endDate: movement.endDate,
            distanceMeters: movement.distanceMeters,
            durationSeconds: movement.durationSeconds,
            estimatedAverageSpeedMetersPerSecond: movement.estimatedAverageSpeedMetersPerSecond,
            automaticClassification: movement.automaticClassification,
            classificationConfidence: movement.classificationConfidence,
            route: movement.route,
            labelCoordinate: labelCoordinate,
            sourceRawRevision: movement.sourceRawRevision,
            generatedAt: movement.generatedAt
        )
    }

    private func applyingStayOverrides(
        _ overrides: [StayOverrideData],
        to stays: [StaySegmentData]
    ) -> [StaySegmentData] {
        stays.map { stay in
            let matching = overrides.filter {
                overrideMatcher.matchStayOverride($0, to: stays)?.stableID == stay.stableID
            }.sorted {
                $0.updatedAt == $1.updatedAt
                    ? $0.overrideKey < $1.overrideKey
                    : $0.updatedAt < $1.updatedAt
            }
            guard let action = matching.last?.action else {
                return stay
            }
            let isVisible = switch action {
            case .confirm:
                true
            case .hide:
                false
            case .automatic:
                stay.isVisibleByAutomaticRule
            }
            return copy(stay, isVisible: isVisible)
        }
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
