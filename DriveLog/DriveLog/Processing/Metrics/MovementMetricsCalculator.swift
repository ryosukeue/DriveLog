import Foundation

nonisolated struct MovementMetrics: Sendable, Equatable {
    let distanceMeters: Double
    let durationSeconds: TimeInterval
    let estimatedAverageSpeedMetersPerSecond: Double?
}

nonisolated struct MovementMetricsCalculator: Sendable {
    private let rules: SegmentationRules
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: SegmentationRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.distanceCalculator = distanceCalculator
    }

    func calculate(locations: [LocationEventData]) -> MovementMetrics? {
        guard let first = locations.first, let last = locations.last else {
            return nil
        }
        let duration = last.timestamp.timeIntervalSince(first.timestamp)
        guard duration >= 0 else {
            return nil
        }
        let pairs = zip(locations, locations.dropFirst()).map { first, second in
            let elapsed = second.timestamp.timeIntervalSince(first.timestamp)
            let distance = distanceCalculator.meters(
                fromLatitude: first.latitude,
                longitude: first.longitude,
                toLatitude: second.latitude,
                longitude: second.longitude
            )
            return (elapsed: elapsed, distance: distance)
        }
        let distance = pairs.reduce(0) { $0 + $1.distance }
        // A movement may intentionally bridge a long Core Location gap. That gap is useful
        // for preserving the route, but treating the unobserved time as driving time makes
        // the displayed speed (and fallback classification) artificially low.
        let observedPairs = pairs.filter {
            $0.elapsed > 0 && $0.elapsed <= rules.softContinuousGap
        }
        let observedDuration = observedPairs.reduce(0) { $0 + $1.elapsed }
        let observedDistance = observedPairs.reduce(0) { $0 + $1.distance }
        let canEstimateSpeed = observedDuration >= rules.minimumSpeedDisplayDuration &&
            locations.count >= rules.minimumSpeedDisplayPointCount &&
            observedDistance >= rules.minimumSpeedDisplayDistance
        return MovementMetrics(
            distanceMeters: distance,
            durationSeconds: duration,
            estimatedAverageSpeedMetersPerSecond: canEstimateSpeed
                ? observedDistance / observedDuration
                : nil
        )
    }
}
