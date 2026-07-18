import Foundation

nonisolated struct StationaryDriftDetector: Sendable {
    private let rules: StationaryDriftRules
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: StationaryDriftRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.distanceCalculator = distanceCalculator
    }

    func isStationaryDrift(
        _ candidate: MovementSegmentCandidate,
        motions: [MotionEventData]
    ) -> Bool {
        let duration = candidate.durationSeconds
        guard duration >= rules.minimumDuration,
              duration > 0,
              candidate.distanceMeters > 0,
              candidate.distanceMeters / duration <= rules.maximumAverageSpeed,
              progressRatio(candidate) <= rules.maximumProgressRatio
        else {
            return false
        }

        let evidence = motionEvidence(
            from: candidate.startDate,
            to: candidate.endDate,
            motions: motions
        )
        guard evidence.totalDuration >= rules.minimumMotionEvidenceDuration else {
            return false
        }
        return evidence.stationaryDuration / evidence.totalDuration >=
            rules.minimumStationaryMotionRatio
    }

    private func progressRatio(_ candidate: MovementSegmentCandidate) -> Double {
        guard let first = candidate.locations.first else { return .infinity }
        let maximumDisplacement = candidate.locations.dropFirst().reduce(0.0) { result, location in
            max(
                result,
                distanceCalculator.meters(
                    fromLatitude: first.latitude,
                    longitude: first.longitude,
                    toLatitude: location.latitude,
                    longitude: location.longitude
                )
            )
        }
        return maximumDisplacement / candidate.distanceMeters
    }

    private func motionEvidence(
        from startDate: Date,
        to endDate: Date,
        motions: [MotionEventData]
    ) -> MotionEvidence {
        let snapshots = groupedSnapshots(motions)
        var evidence = MotionEvidence()
        for (index, snapshot) in snapshots.enumerated() {
            let nextStartDate = snapshots.indices.contains(index + 1) ?
                snapshots[index + 1].startDate : endDate
            let effectiveEndDate = min(
                endDate,
                snapshot.explicitEndDate.map { min($0, nextStartDate) } ?? nextStartDate
            )
            let effectiveStartDate = max(startDate, snapshot.startDate)
            guard effectiveEndDate > effectiveStartDate else { continue }

            let duration = effectiveEndDate.timeIntervalSince(effectiveStartDate)
            if snapshot.hasTravelEvidence {
                evidence.travelDuration += duration
            } else if snapshot.hasStationaryEvidence {
                evidence.stationaryDuration += duration
            }
        }
        return evidence
    }

    private func groupedSnapshots(_ motions: [MotionEventData]) -> [MotionSnapshot] {
        Dictionary(grouping: motions, by: \.startDate)
            .map { startDate, groupedMotions in
                let explicitEndDates = groupedMotions.compactMap(\.endDate)
                return MotionSnapshot(
                    startDate: startDate,
                    explicitEndDate: groupedMotions.contains { $0.endDate == nil } ?
                        nil : explicitEndDates.max(),
                    hasTravelEvidence: groupedMotions.contains(where: hasTravelEvidence),
                    hasStationaryEvidence: groupedMotions.contains(where: \.isStationary)
                )
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func hasTravelEvidence(_ motion: MotionEventData) -> Bool {
        motion.isAutomotive || motion.isWalking || motion.isRunning || motion.isCycling
    }
}

private nonisolated struct MotionSnapshot: Sendable {
    let startDate: Date
    let explicitEndDate: Date?
    let hasTravelEvidence: Bool
    let hasStationaryEvidence: Bool
}

private nonisolated struct MotionEvidence: Sendable {
    var stationaryDuration = 0.0
    var travelDuration = 0.0

    var totalDuration: TimeInterval {
        stationaryDuration + travelDuration
    }
}
