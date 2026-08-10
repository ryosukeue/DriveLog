import Foundation

nonisolated struct MovementSegmenter: MovementSegmenting {
    private let segmentationRules: SegmentationRules
    private let stayRules: StayRules
    private let distanceCalculator: GeodesicDistanceCalculator
    private let metricsCalculator: MovementMetricsCalculator
    private let stationaryDriftDetector: StationaryDriftDetector

    init(
        segmentationRules: SegmentationRules,
        stayRules: StayRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.segmentationRules = segmentationRules
        self.stayRules = stayRules
        self.distanceCalculator = distanceCalculator
        metricsCalculator = MovementMetricsCalculator(
            rules: segmentationRules,
            distanceCalculator: distanceCalculator
        )
        stationaryDriftDetector = StationaryDriftDetector(
            rules: segmentationRules.stationaryDrift,
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

        let partition = partitionLocations(
            first: first,
            remaining: locations.accepted.dropFirst(),
            motions: motions,
            visits: visits
        )
        let candidates = partition.chunks.compactMap(makeCandidate)
        let evaluations = candidates.map { candidate in
            let meetsMinimumRequirements = isValid(candidate)
            let isStationaryDrift = meetsMinimumRequirements &&
                stationaryDriftDetector.isStationaryDrift(candidate, motions: motions)
            return CandidateEvaluation(
                candidate: candidate,
                isAccepted: meetsMinimumRequirements && !isStationaryDrift,
                isStationaryDrift: isStationaryDrift
            )
        }
        return MovementSegmentationResult(
            segments: evaluations.filter(\.isAccepted).map(\.candidate),
            gaps: partition.gaps,
            discardedSegments: evaluations.filter { !$0.isAccepted }.map(\.candidate),
            stationaryDriftDiscardedCount: evaluations.count(where: \.isStationaryDrift)
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
        if interval >= segmentationRules.absoluteMaximumContinuousGap {
            return .continuousGap
        }
        let overlappingVisits = visits.filter {
            visitOverlaps($0, from: start.timestamp, to: end.timestamp)
        }
        let hasVisit = !overlappingVisits.isEmpty
        let hasConfirmedStayVisit = overlappingVisits.contains(where: isConfirmedStayVisit)
        let hasStayEvidence = hasConfirmedStayVisit || endpointsAreWithinStayRadius(
            from: start,
            to: end
        )
        if interval >= stayRules.automaticStayDuration, hasStayEvidence {
            return .stationaryStay
        }
        if hasVisit {
            return .visit
        }
        let hasSupportedMotionTransition = interval >= stayRules.minimumStayDuration &&
            hasTravelModeTransition(motions, from: start.timestamp, to: end.timestamp)
        if hasSupportedMotionTransition {
            return .motionTransition
        }
        if interval >= segmentationRules.softContinuousGap,
           !hasMovementContinuity(
               from: start,
               to: end,
               interval: interval,
               motions: motions
           )
        {
            return .continuousGap
        }
        return nil
    }

    private func hasMovementContinuity(
        from start: LocationEventData,
        to end: LocationEventData,
        interval: TimeInterval,
        motions: [MotionEventData]
    ) -> Bool {
        guard interval > 0 else { return false }
        let distance = distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
        let averageSpeed = distance / interval
        guard averageSpeed <= segmentationRules.maximumBridgeAverageSpeed else {
            return false
        }
        if hasTravelMotionEvidence(motions, from: start.timestamp, to: end.timestamp) {
            return true
        }
        return distance >= segmentationRules.minimumBridgeDistance &&
            averageSpeed >= segmentationRules.minimumBridgeAverageSpeed
    }

    private func hasTravelMotionEvidence(
        _ motions: [MotionEventData],
        from start: Date,
        to end: Date
    ) -> Bool {
        motions.contains { motion in
            guard motion.isAutomotive || motion.isWalking ||
                    motion.isRunning || motion.isCycling
            else { return false }
            return motion.startDate < end && (motion.endDate ?? end) > start
        }
    }

    private func endpointsAreWithinStayRadius(
        from start: LocationEventData,
        to end: LocationEventData
    ) -> Bool {
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        ) <= stayRules.stayRadius + stayRules.stayRadius * 1e-12
    }

    private func visitOverlaps(_ visit: VisitEventData, from start: Date, to end: Date) -> Bool {
        switch (visit.arrivalDate, visit.departureDate) {
        case let (arrival?, departure?): arrival < end && departure > start
        case let (arrival?, nil): arrival > start && arrival < end
        case let (nil, departure?): departure > start && departure < end
        case (nil, nil): false
        }
    }

    private func isConfirmedStayVisit(_ visit: VisitEventData) -> Bool {
        guard let arrival = visit.arrivalDate,
              let departure = visit.departureDate
        else { return false }
        return departure.timeIntervalSince(arrival) >= stayRules.automaticStayDuration
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

private nonisolated struct CandidateEvaluation {
    let candidate: MovementSegmentCandidate
    let isAccepted: Bool
    let isStationaryDrift: Bool
}

private extension MovementSegmenter {
    func partitionLocations(
        first: LocationEventData,
        remaining: ArraySlice<LocationEventData>,
        motions: [MotionEventData],
        visits: [VisitEventData]
    ) -> MovementSegmentationPartition {
        var result = MovementSegmentationPartition(first: first)
        var previousLocation = first
        var previousVisit = confirmedVisit(containing: first.timestamp, visits: visits)
        for location in remaining {
            let currentVisit = confirmedVisit(containing: location.timestamp, visits: visits)
            let transitionsVisit = previousVisit != currentVisit &&
                (previousVisit != nil || currentVisit != nil)
            if let reason = fundamentalBoundaryReason(from: previousLocation, to: location) {
                result.appendHardBoundary(from: previousLocation, to: location, reason: reason)
            } else if transitionsVisit {
                partitionAtConfirmedVisit(
                    from: previousLocation,
                    to: location,
                    previousVisit: previousVisit,
                    currentVisit: currentVisit,
                    result: &result
                )
            } else if currentVisit == nil {
                appendUsingStandardRules(
                    from: previousLocation,
                    to: location,
                    motions: motions,
                    visits: visits,
                    result: &result
                )
            }
            previousLocation = location
            previousVisit = currentVisit
        }
        return result
    }

    func fundamentalBoundaryReason(
        from start: LocationEventData,
        to end: LocationEventData
    ) -> SegmentationBoundaryReason? {
        if start.localDateKey != end.localDateKey {
            return .localDayBoundary
        }
        let interval = end.timestamp.timeIntervalSince(start.timestamp)
        return interval >= segmentationRules.absoluteMaximumContinuousGap
            ? .continuousGap
            : nil
    }

    func appendUsingStandardRules(
        from start: LocationEventData,
        to end: LocationEventData,
        motions: [MotionEventData],
        visits: [VisitEventData],
        result: inout MovementSegmentationPartition
    ) {
        guard let reason = boundaryReason(
            from: start,
            to: end,
            motions: motions,
            visits: visits
        ) else {
            result.append(end)
            return
        }
        result.gaps.append(GapCandidate(
            precedingLocation: start,
            followingLocation: end,
            reason: reason
        ))
        switch reason {
        case .continuousGap, .localDayBoundary, .stationaryStay:
            result.chunks.append([end])
        case .visit, .motionTransition:
            result.append(end)
        }
    }

    func partitionAtConfirmedVisit(
        from start: LocationEventData,
        to end: LocationEventData,
        previousVisit: ConfirmedVisitInterval?,
        currentVisit: ConfirmedVisitInterval?,
        result: inout MovementSegmentationPartition
    ) {
        switch (previousVisit, currentVisit) {
        case (nil, let visit?):
            result.append(end)
            result.appendStayGap(from: start, to: end, visit: visit)
        case (let visit?, nil):
            result.chunks.append([end])
            result.appendStayGap(from: start, to: end, visit: visit)
        case let (previous?, _?):
            result.chunks.append([end])
            result.appendStayGap(from: start, to: end, visit: previous)
        case (nil, nil):
            result.append(end)
        }
    }

    func confirmedVisit(
        containing date: Date,
        visits: [VisitEventData]
    ) -> ConfirmedVisitInterval? {
        visits.compactMap { visit -> ConfirmedVisitInterval? in
            guard let arrival = visit.arrivalDate,
                  let departure = visit.departureDate,
                  departure.timeIntervalSince(arrival) >= stayRules.automaticStayDuration,
                  arrival <= date,
                  date <= departure
            else { return nil }
            return ConfirmedVisitInterval(arrival: arrival, departure: departure)
        }.min { $0.arrival < $1.arrival }
    }
}

private nonisolated struct MovementSegmentationPartition {
    var chunks: [[LocationEventData]]
    var gaps: [GapCandidate] = []
    var recordedVisits: [ConfirmedVisitInterval] = []

    init(first: LocationEventData) {
        chunks = [[first]]
    }

    mutating func append(_ location: LocationEventData) {
        chunks[chunks.count - 1].append(location)
    }

    mutating func appendHardBoundary(
        from start: LocationEventData,
        to end: LocationEventData,
        reason: SegmentationBoundaryReason
    ) {
        gaps.append(GapCandidate(
            precedingLocation: start,
            followingLocation: end,
            reason: reason
        ))
        chunks.append([end])
    }

    mutating func appendStayGap(
        from start: LocationEventData,
        to end: LocationEventData,
        visit: ConfirmedVisitInterval
    ) {
        guard !recordedVisits.contains(visit) else { return }
        gaps.append(GapCandidate(
            precedingLocation: start,
            followingLocation: end,
            reason: .stationaryStay
        ))
        recordedVisits.append(visit)
    }
}

private nonisolated enum TravelMode {
    case automotive
    case walking
}

private nonisolated struct ConfirmedVisitInterval: Equatable {
    let arrival: Date
    let departure: Date
}
