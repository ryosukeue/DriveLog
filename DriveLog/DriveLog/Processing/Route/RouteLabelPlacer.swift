import Foundation

nonisolated struct RouteLabel: Sendable, Equatable {
    let movementSegmentID: String
    let coordinate: RouteCoordinate
    let text: String
}

nonisolated protocol RouteLabelPlacing: Sendable {
    func makeLabel(
        for segment: MovementSegmentData,
        occupiedCoordinates: [RouteCoordinate]
    ) -> RouteLabel
}

nonisolated struct RouteLabelPlacer: RouteLabelPlacing {
    private let rules: RouteRules
    private let distanceCalculator: GeodesicDistanceCalculator

    init(
        rules: RouteRules,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.distanceCalculator = distanceCalculator
    }

    func makeLabel(
        for segment: MovementSegmentData,
        occupiedCoordinates: [RouteCoordinate]
    ) -> RouteLabel {
        let primaryCoordinate = coordinate(
            along: segment.route,
            at: rules.routeLabelPrimaryPosition,
            fallback: segment.labelCoordinate
        )
        let positions = [rules.routeLabelPrimaryPosition] + rules.routeLabelFallbackPositions
        let selectedCoordinate = positions.lazy
            .map { coordinate(along: segment.route, at: $0, fallback: segment.labelCoordinate) }
            .first { !occupiedCoordinates.contains($0) } ?? primaryCoordinate
        return RouteLabel(
            movementSegmentID: segment.stableID,
            coordinate: selectedCoordinate,
            text: "\(formattedDuration(segment.durationSeconds))・\(formattedDistance(segment.distanceMeters))"
        )
    }

    private func coordinate(
        along route: [RouteCoordinate],
        at fraction: Double,
        fallback: RouteCoordinate?
    ) -> RouteCoordinate {
        guard let first = route.first else {
            return fallback ?? RouteCoordinate(latitude: 0, longitude: 0)
        }
        guard route.count > 1 else {
            return first
        }

        let distances = zip(route, route.dropFirst()).map { distance(from: $0.0, to: $0.1) }
        let totalDistance = distances.reduce(0, +)
        guard totalDistance > 0 else {
            return first
        }
        let targetDistance = totalDistance * max(0, min(1, fraction))
        var traversedDistance = 0.0
        for (index, segmentDistance) in distances.enumerated() {
            let nextDistance = traversedDistance + segmentDistance
            if targetDistance <= nextDistance || index == distances.count - 1 {
                let segmentFraction = segmentDistance > 0
                    ? (targetDistance - traversedDistance) / segmentDistance
                    : 0
                return interpolated(from: route[index], to: route[index + 1], fraction: segmentFraction)
            }
            traversedDistance = nextDistance
        }
        return route.last ?? first
    }

    private func distance(from start: RouteCoordinate, to end: RouteCoordinate) -> Double {
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
    }

    private func interpolated(
        from start: RouteCoordinate,
        to end: RouteCoordinate,
        fraction: Double
    ) -> RouteCoordinate {
        let longitudeDelta = normalizedLongitudeDelta(end.longitude - start.longitude)
        var longitude = start.longitude + longitudeDelta * fraction
        if longitude > 180 {
            longitude -= 360
        } else if longitude < -180 {
            longitude += 360
        }
        return RouteCoordinate(
            latitude: start.latitude + (end.latitude - start.latitude) * fraction,
            longitude: longitude
        )
    }

    private func normalizedLongitudeDelta(_ degrees: Double) -> Double {
        var result = degrees.truncatingRemainder(dividingBy: 360)
        if result > 180 {
            result -= 360
        } else if result < -180 {
            result += 360
        }
        return result
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(max(0, meters).rounded()))m"
        }
        return String(format: "%.1fkm", locale: Locale(identifier: "ja_JP"), max(0, meters) / 1000)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds / 60))
        guard totalMinutes >= 60 else {
            return "\(totalMinutes)分"
        }
        return "\(totalMinutes / 60)時間\(totalMinutes % 60)分"
    }
}
