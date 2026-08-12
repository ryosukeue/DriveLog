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
        let distance = zip(locations, locations.dropFirst()).reduce(0) { result, pair in
            result + distanceCalculator.meters(
                fromLatitude: pair.0.latitude,
                longitude: pair.0.longitude,
                toLatitude: pair.1.latitude,
                longitude: pair.1.longitude
            )
        }
        let canEstimateSpeed = duration >= rules.minimumSpeedDisplayDuration &&
            locations.count >= rules.minimumSpeedDisplayPointCount &&
            distance >= rules.minimumSpeedDisplayDistance &&
            duration > 0
        return MovementMetrics(
            distanceMeters: distance,
            durationSeconds: duration,
            estimatedAverageSpeedMetersPerSecond: canEstimateSpeed ? distance / duration : nil
        )
    }
}
