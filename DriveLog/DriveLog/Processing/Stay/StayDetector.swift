import Foundation

nonisolated protocol StayDetecting: Sendable {
    func detect(
        segmentation: MovementSegmentationResult,
        motions: [MotionEventData],
        visits: [VisitEventData],
        overrides: [StayOverrideData]
    ) -> [StaySegmentData]
}

nonisolated struct StayDetector: StayDetecting {
    private let rules: StayRules
    private let stableIDGenerator: any StableIDGenerating
    private let sourceRawRevision: Int
    private let generatedAt: Date
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: StayRules,
        stableIDGenerator: any StableIDGenerating,
        sourceRawRevision: Int,
        generatedAt: Date,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.stableIDGenerator = stableIDGenerator
        self.sourceRawRevision = sourceRawRevision
        self.generatedAt = generatedAt
        self.distanceCalculator = distanceCalculator
    }

    func detect(
        segmentation: MovementSegmentationResult,
        motions: [MotionEventData],
        visits: [VisitEventData],
        overrides: [StayOverrideData]
    ) -> [StaySegmentData] {
        segmentation.gaps.compactMap { gap in
            detect(
                gap: gap,
                segmentation: segmentation,
                motions: motions,
                visits: visits,
                overrides: overrides
            )
        }
    }

    private func detect(
        gap: GapCandidate,
        segmentation: MovementSegmentationResult,
        motions: [MotionEventData],
        visits: [VisitEventData],
        overrides: [StayOverrideData]
    ) -> StaySegmentData? {
        guard gap.reason != .localDayBoundary else {
            return nil
        }
        let matchingVisits = visits.filter { visitOverlaps($0, gap: gap) }
        let visit = preferredVisit(matchingVisits)
        guard visit != nil || endpointsAreWithinStayRadius(gap) else {
            return nil
        }

        let arrival = visit?.arrivalDate ?? gap.precedingLocation.timestamp
        let departure = visit?.departureDate ?? gap.followingLocation.timestamp
        guard departure >= arrival else {
            return nil
        }
        let duration = departure.timeIntervalSince(arrival)
        let hasMotionEvidence = hasAutomotiveToWalking(motions, from: arrival, to: departure)
        let coordinate = representativeCoordinate(for: gap, visit: visit)
        let stableID = makeStableID(
            coordinate: coordinate, gap: gap, arrival: arrival, departure: departure
        )
        let automaticVisibility = isAutomaticallyVisible(
            duration: duration,
            hasVisit: visit != nil,
            hasMotionEvidence: hasMotionEvidence
        ) && !isTrafficLike(
            gap: gap,
            segmentation: segmentation,
            motions: motions,
            hasVisit: visit != nil
        )
        let visibility = appliedVisibility(
            automaticVisibility,
            stableID: stableID,
            overrides: overrides
        )

        return StaySegmentData(
            stableID: stableID,
            localDateKey: gap.precedingLocation.localDateKey,
            representativeCoordinate: coordinate,
            estimatedArrivalDate: arrival,
            estimatedDepartureDate: departure,
            durationSeconds: duration,
            confidence: confidence(hasVisit: visit != nil, hasMotionEvidence: hasMotionEvidence),
            source: source(hasVisit: visit != nil, hasMotionEvidence: hasMotionEvidence),
            isVisibleByAutomaticRule: visibility,
            sourceRawRevision: sourceRawRevision,
            generatedAt: generatedAt
        )
    }

    private func makeStableID(
        coordinate: RouteCoordinate,
        gap: GapCandidate,
        arrival: Date,
        departure: Date
    ) -> String {
        stableIDGenerator.staySegmentID(
            localDateKey: gap.precedingLocation.localDateKey,
            arrivalDate: arrival,
            departureDate: departure,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    private func endpointsAreWithinStayRadius(_ gap: GapCandidate) -> Bool {
        let distance = distanceCalculator.meters(
            fromLatitude: gap.precedingLocation.latitude,
            longitude: gap.precedingLocation.longitude,
            toLatitude: gap.followingLocation.latitude,
            longitude: gap.followingLocation.longitude
        )
        return distance <= rules.stayRadius + rules.stayRadius * 1e-12
    }

    private func visitOverlaps(_ visit: VisitEventData, gap: GapCandidate) -> Bool {
        let start = gap.precedingLocation.timestamp
        let end = gap.followingLocation.timestamp
        switch (visit.arrivalDate, visit.departureDate) {
        case let (arrival?, departure?):
            return arrival < end && departure > start
        case let (arrival?, nil):
            return arrival > start && arrival < end
        case let (nil, departure?):
            return departure > start && departure < end
        case (nil, nil):
            return false
        }
    }

    private func preferredVisit(_ visits: [VisitEventData]) -> VisitEventData? {
        visits.sorted {
            ($0.arrivalDate ?? .distantFuture) < ($1.arrivalDate ?? .distantFuture)
        }.first
    }

    private func representativeCoordinate(
        for gap: GapCandidate,
        visit: VisitEventData?
    ) -> RouteCoordinate {
        if let visit {
            return RouteCoordinate(latitude: visit.latitude, longitude: visit.longitude)
        }
        let first = gap.precedingLocation
        let second = gap.followingLocation
        let firstWeight = 1 / max(first.horizontalAccuracy, 1)
        let secondWeight = 1 / max(second.horizontalAccuracy, 1)
        let totalWeight = firstWeight + secondWeight
        return RouteCoordinate(
            latitude: (first.latitude * firstWeight + second.latitude * secondWeight) / totalWeight,
            longitude: (first.longitude * firstWeight + second.longitude * secondWeight) / totalWeight
        )
    }

    private func isAutomaticallyVisible(
        duration: TimeInterval,
        hasVisit: Bool,
        hasMotionEvidence: Bool
    ) -> Bool {
        if duration >= rules.automaticStayDuration {
            return true
        }
        return duration >= rules.minimumStayDuration && (hasVisit || hasMotionEvidence)
    }
}

private extension StayDetector {
    private func isTrafficLike(
        gap: GapCandidate,
        segmentation: MovementSegmentationResult,
        motions: [MotionEventData],
        hasVisit: Bool
    ) -> Bool {
        guard !hasVisit, hasAutomotiveStationaryAutomotive(motions, gap: gap) else {
            return false
        }
        guard let preceding = segmentation.segments.last(where: {
            $0.locations.last == gap.precedingLocation
        }),
            let following = segmentation.segments.first(where: {
                $0.locations.first == gap.followingLocation
            }),
            let precedingBearing = endingBearing(preceding),
            let followingBearing = startingBearing(following)
        else {
            return false
        }
        let tolerance = rules.trafficDirectionChangeToleranceDegrees
        return angularDifference(precedingBearing, followingBearing) <= tolerance + 1e-6
    }

    private func hasAutomotiveStationaryAutomotive(
        _ motions: [MotionEventData],
        gap: GapCandidate
    ) -> Bool {
        let start = gap.precedingLocation.timestamp
        let end = gap.followingLocation.timestamp
        let states = motions
            .filter { $0.startDate <= end && ($0.endDate ?? end) >= start }
            .sorted { $0.startDate < $1.startDate }
            .compactMap(motionState)
        guard !states.contains(.walking),
              let firstAutomotive = states.firstIndex(of: .automotive),
              let stationary = states.dropFirst(firstAutomotive + 1).firstIndex(of: .stationary)
        else {
            return false
        }
        return states.dropFirst(stationary + 1).contains(.automotive)
    }

    private func endingBearing(_ segment: MovementSegmentCandidate) -> Double? {
        guard segment.locations.count >= 2 else {
            return nil
        }
        return bearing(
            from: segment.locations[segment.locations.count - 2],
            to: segment.locations[segment.locations.count - 1]
        )
    }

    private func startingBearing(_ segment: MovementSegmentCandidate) -> Double? {
        guard segment.locations.count >= 2 else {
            return nil
        }
        return bearing(from: segment.locations[0], to: segment.locations[1])
    }

    private func bearing(from start: LocationEventData, to end: LocationEventData) -> Double {
        let startLatitude = start.latitude * .pi / 180
        let endLatitude = end.latitude * .pi / 180
        let longitudeDelta = (end.longitude - start.longitude) * .pi / 180
        let verticalComponent = sin(longitudeDelta) * cos(endLatitude)
        let horizontalComponent = cos(startLatitude) * sin(endLatitude) -
            sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta)
        let degrees = atan2(verticalComponent, horizontalComponent) * 180 / .pi
        return degrees >= 0 ? degrees : degrees + 360
    }

    private func angularDifference(_ first: Double, _ second: Double) -> Double {
        let difference = abs(first - second)
        return min(difference, 360 - difference)
    }

    private func appliedVisibility(
        _ automaticVisibility: Bool,
        stableID: String,
        overrides: [StayOverrideData]
    ) -> Bool {
        guard let action = overrides.last(where: { $0.targetStableID == stableID })?.action else {
            return automaticVisibility
        }
        switch action {
        case .confirm:
            return true
        case .hide:
            return false
        case .automatic:
            return automaticVisibility
        }
    }

    private func hasAutomotiveToWalking(
        _ motions: [MotionEventData],
        from start: Date,
        to end: Date
    ) -> Bool {
        let states = motions
            .filter { $0.startDate < end && ($0.endDate ?? end) > start }
            .sorted { $0.startDate < $1.startDate }
            .compactMap(motionState)
        guard let automotiveIndex = states.firstIndex(of: .automotive) else {
            return false
        }
        return states.dropFirst(automotiveIndex + 1).contains(.walking)
    }

    private func motionState(_ motion: MotionEventData) -> StayMotionState? {
        if motion.isAutomotive {
            return .automotive
        }
        if motion.isWalking || motion.isRunning {
            return .walking
        }
        if motion.isStationary {
            return .stationary
        }
        return nil
    }

    private func confidence(hasVisit: Bool, hasMotionEvidence: Bool) -> StayConfidence {
        if hasVisit {
            return .high
        }
        return hasMotionEvidence ? .medium : .low
    }

    private func source(hasVisit: Bool, hasMotionEvidence: Bool) -> StayDetectionSource {
        if hasVisit, hasMotionEvidence {
            return .combined
        }
        if hasVisit {
            return .visit
        }
        return hasMotionEvidence ? .motionTransition : .locationGap
    }
}

private nonisolated enum StayMotionState {
    case automotive
    case stationary
    case walking
}
