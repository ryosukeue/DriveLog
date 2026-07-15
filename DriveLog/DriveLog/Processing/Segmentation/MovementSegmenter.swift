import Foundation

nonisolated protocol MovementSegmenting: Sendable {
    func segment(
        locations: SanitizedLocations,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> MovementSegmentationResult
}

nonisolated struct MovementSegmentationResult: Sendable, Equatable {
    let segments: [MovementSegmentCandidate]
    let gaps: [GapCandidate]
    let discardedSegments: [MovementSegmentCandidate]
}

nonisolated struct MovementSegmentCandidate: Sendable, Equatable {
    let localDateKey: String
    let startDate: Date
    let endDate: Date
    let locations: [LocationEventData]
    let distanceMeters: Double
    let estimatedAverageSpeedMetersPerSecond: Double?

    init(
        localDateKey: String,
        startDate: Date,
        endDate: Date,
        locations: [LocationEventData],
        distanceMeters: Double,
        estimatedAverageSpeedMetersPerSecond: Double? = nil
    ) {
        self.localDateKey = localDateKey
        self.startDate = startDate
        self.endDate = endDate
        self.locations = locations
        self.distanceMeters = distanceMeters
        self.estimatedAverageSpeedMetersPerSecond = estimatedAverageSpeedMetersPerSecond
    }

    var durationSeconds: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
}

nonisolated struct GapCandidate: Sendable, Equatable {
    let precedingLocation: LocationEventData
    let followingLocation: LocationEventData
    let reason: SegmentationBoundaryReason

    var durationSeconds: TimeInterval {
        followingLocation.timestamp.timeIntervalSince(precedingLocation.timestamp)
    }
}

nonisolated enum SegmentationBoundaryReason: Sendable, Equatable {
    case continuousGap
    case localDayBoundary
    case visit
    case motionTransition
}

nonisolated struct MovementSegmenter: MovementSegmenting {
    private let segmentationRules: SegmentationRules
    private let stayRules: StayRules
    private let metricsCalculator: MovementMetricsCalculator

    init(
        segmentationRules: SegmentationRules,
        stayRules: StayRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.segmentationRules = segmentationRules
        self.stayRules = stayRules
        metricsCalculator = MovementMetricsCalculator(
            rules: segmentationRules,
            distanceCalculator: distanceCalculator
        )
    }

    func segment(
        locations: SanitizedLocations,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> MovementSegmentationResult {
        guard let first = locations.accepted.first else {
            return MovementSegmentationResult(segments: [], gaps: [], discardedSegments: [])
        }

        var chunks = [[first]]
        var gaps: [GapCandidate] = []
        for location in locations.accepted.dropFirst() {
            guard let preceding = chunks.last?.last else {
                continue
            }
            if let reason = boundaryReason(
                from: preceding,
                to: location,
                motions: motions,
                visits: visits
            ) {
                gaps.append(
                    GapCandidate(
                        precedingLocation: preceding,
                        followingLocation: location,
                        reason: reason
                    )
                )
                switch reason {
                case .continuousGap, .localDayBoundary:
                    chunks.append([location])
                case .visit, .motionTransition:
                    chunks[chunks.count - 1].append(location)
                }
            } else {
                chunks[chunks.count - 1].append(location)
            }
        }

        let candidates = chunks.compactMap(makeCandidate)
        return MovementSegmentationResult(
            segments: candidates.filter(isValid),
            gaps: gaps,
            discardedSegments: candidates.filter { !isValid($0) }
        )
    }

    private func boundaryReason(
        from start: LocationEventData,
        to end: LocationEventData,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> SegmentationBoundaryReason? {
        if start.localDateKey != end.localDateKey {
            return .localDayBoundary
        }
        let interval = end.timestamp.timeIntervalSince(start.timestamp)
        if interval >= segmentationRules.maximumContinuousGap {
            return .continuousGap
        }
        if visits.contains(where: { visitOverlaps($0, from: start.timestamp, to: end.timestamp) }) {
            return .visit
        }
        let hasSupportedMotionTransition = interval >= stayRules.minimumStayDuration &&
            hasTravelModeTransition(motions, from: start.timestamp, to: end.timestamp)
        if hasSupportedMotionTransition {
            return .motionTransition
        }
        return nil
    }

    private func visitOverlaps(_ visit: VisitEventData, from start: Date, to end: Date) -> Bool {
        switch (visit.arrivalDate, visit.departureDate) {
        case let (arrival?, departure?): arrival < end && departure > start
        case let (arrival?, nil): arrival > start && arrival < end
        case let (nil, departure?): departure > start && departure < end
        case (nil, nil): false
        }
    }

    private func hasTravelModeTransition(
        _ motions: [MotionEventData],
        from start: Date,
        to end: Date
    ) -> Bool {
        let modes = motions
            .filter { $0.startDate < end && ($0.endDate ?? end) > start }
            .sorted { $0.startDate < $1.startDate }
            .compactMap(travelMode)
        return zip(modes, modes.dropFirst()).contains { $0 != $1 }
    }

    private func travelMode(_ motion: MotionEventData) -> TravelMode? {
        if motion.isAutomotive, !motion.isWalking {
            return .automotive
        }
        if motion.isWalking, !motion.isAutomotive {
            return .walking
        }
        return nil
    }

    private func makeCandidate(_ locations: [LocationEventData]) -> MovementSegmentCandidate? {
        guard let first = locations.first,
              let last = locations.last,
              let metrics = metricsCalculator.calculate(locations: locations)
        else {
            return nil
        }
        return MovementSegmentCandidate(
            localDateKey: first.localDateKey,
            startDate: first.timestamp,
            endDate: last.timestamp,
            locations: locations,
            distanceMeters: metrics.distanceMeters,
            estimatedAverageSpeedMetersPerSecond: metrics.estimatedAverageSpeedMetersPerSecond
        )
    }

    private func isValid(_ candidate: MovementSegmentCandidate) -> Bool {
        candidate.locations.count >= segmentationRules.minimumSegmentPointCount &&
            candidate.distanceMeters >= segmentationRules.minimumSegmentDistance
    }
}

private nonisolated enum TravelMode {
    case automotive
    case walking
}
