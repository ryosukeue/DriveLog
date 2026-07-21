import Foundation

nonisolated struct VehicleMovementEvidenceEvaluator: Sendable {
    let maximumHorizontalAccuracy: Double
    let minimumSpeedMetersPerSecond: Double
    let minimumDisplacementMeters: Double
    let maximumEvidenceInterval: TimeInterval

    init(
        maximumHorizontalAccuracy: Double = 150,
        minimumSpeedMetersPerSecond: Double = 3,
        minimumDisplacementMeters: Double = 100,
        maximumEvidenceInterval: TimeInterval = 90
    ) {
        self.maximumHorizontalAccuracy = maximumHorizontalAccuracy
        self.minimumSpeedMetersPerSecond = minimumSpeedMetersPerSecond
        self.minimumDisplacementMeters = minimumDisplacementMeters
        self.maximumEvidenceInterval = maximumEvidenceInterval
    }

    func confirmsMovement(
        _ location: LocationEventData,
        after previous: LocationEventData?
    ) -> Bool {
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= maximumHorizontalAccuracy
        else {
            return false
        }

        if let previous {
            guard location.timestamp > previous.timestamp,
                  location.timestamp.timeIntervalSince(previous.timestamp) <= maximumEvidenceInterval,
                  previous.horizontalAccuracy >= 0,
                  previous.horizontalAccuracy <= maximumHorizontalAccuracy
            else {
                return false
            }
        }

        let hasSpeedEvidence = location.speedMetersPerSecond.map {
            $0 >= minimumSpeedMetersPerSecond
        } ?? false
        if hasSpeedEvidence {
            return true
        }

        guard let previous,
              Self.distanceMeters(from: previous, to: location) >= minimumDisplacementMeters
        else {
            return false
        }
        return true
    }

    private static func distanceMeters(
        from first: LocationEventData,
        to second: LocationEventData
    ) -> Double {
        let earthRadius = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let deltaLatitude = (second.latitude - first.latitude) * .pi / 180
        let deltaLongitude = (second.longitude - first.longitude) * .pi / 180
        let haversine = sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
            cos(latitude1) * cos(latitude2) *
            sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
    }
}
