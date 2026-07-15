import Foundation

nonisolated protocol MediaPlacementCalculating: Sendable {
    func place(
        assets: [MediaAssetReference],
        movements: [MovementSegmentData]
    ) -> [MediaPlacement]
}

nonisolated struct MediaPlacementCalculator: MediaPlacementCalculating {
    private struct Candidate {
        let movement: MovementSegmentData
        let distance: Double
    }

    private let rules: MediaRules
    private let distanceCalculator: GeodesicDistanceCalculator
    private let equalDistanceTolerance = 0.001
    private let earthRadiusMeters = 6_371_000.0

    init(
        rules: MediaRules = ProcessingConfiguration.mvp.media,
        distanceCalculator: GeodesicDistanceCalculator = GeodesicDistanceCalculator()
    ) {
        self.rules = rules
        self.distanceCalculator = distanceCalculator
    }

    func place(
        assets: [MediaAssetReference],
        movements: [MovementSegmentData]
    ) -> [MediaPlacement] {
        assets.compactMap { asset in
            guard let coordinate = asset.location else { return nil }
            return MediaPlacement(
                assetIdentifier: asset.localIdentifier,
                mediaType: asset.mediaType,
                coordinate: coordinate,
                relatedMovementStableID: relatedMovementID(
                    asset: asset,
                    coordinate: coordinate,
                    movements: movements
                )
            )
        }
    }

    private func relatedMovementID(
        asset: MediaAssetReference,
        coordinate: RouteCoordinate,
        movements: [MovementSegmentData]
    ) -> String? {
        let maximumDistance = max(0, rules.maximumRouteMediaDistance)
        let candidates = movements.compactMap { movement -> Candidate? in
            guard let distance = routeDistance(from: coordinate, to: movement.route),
                  distance <= maximumDistance
            else { return nil }
            return Candidate(movement: movement, distance: distance)
        }
        return candidates.reduce(nil as Candidate?) { selected, candidate in
            guard let selected else { return candidate }
            return isPreferred(candidate, over: selected, creationDate: asset.creationDate)
                ? candidate
                : selected
        }?.movement.stableID
    }

    private func isPreferred(
        _ candidate: Candidate,
        over selected: Candidate,
        creationDate: Date?
    ) -> Bool {
        let distanceDifference = candidate.distance - selected.distance
        if abs(distanceDifference) > equalDistanceTolerance {
            return distanceDifference < 0
        }
        let candidateTimeDistance = timeDistance(
            creationDate,
            start: candidate.movement.startDate,
            end: candidate.movement.endDate
        )
        let selectedTimeDistance = timeDistance(
            creationDate,
            start: selected.movement.startDate,
            end: selected.movement.endDate
        )
        if candidateTimeDistance != selectedTimeDistance {
            return candidateTimeDistance < selectedTimeDistance
        }
        return candidate.movement.stableID < selected.movement.stableID
    }

    private func timeDistance(_ date: Date?, start: Date, end: Date) -> TimeInterval {
        guard let date else { return .infinity }
        let lower = min(start, end)
        let upper = max(start, end)
        if lower ... upper ~= date {
            return 0
        }
        return min(abs(date.timeIntervalSince(lower)), abs(date.timeIntervalSince(upper)))
    }

    private func routeDistance(
        from coordinate: RouteCoordinate,
        to route: [RouteCoordinate]
    ) -> Double? {
        guard let first = route.first else { return nil }
        guard route.count > 1 else {
            return geodesicDistance(from: coordinate, to: first)
        }
        return zip(route, route.dropFirst()).map { start, end in
            segmentDistance(from: coordinate, start: start, end: end)
        }.min()
    }

    private func segmentDistance(
        from coordinate: RouteCoordinate,
        start: RouteCoordinate,
        end: RouteCoordinate
    ) -> Double {
        let startPoint = localPoint(start, origin: coordinate)
        let endPoint = localPoint(end, origin: coordinate)
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        let lengthSquared = deltaX * deltaX + deltaY * deltaY
        guard lengthSquared > 0 else {
            return geodesicDistance(from: coordinate, to: start)
        }
        let projection = max(
            0,
            min(1, -(startPoint.x * deltaX + startPoint.y * deltaY) / lengthSquared)
        )
        return hypot(
            startPoint.x + projection * deltaX,
            startPoint.y + projection * deltaY
        )
    }

    private func localPoint(
        _ coordinate: RouteCoordinate,
        origin: RouteCoordinate
    ) -> (x: Double, y: Double) {
        let originLatitude = radians(origin.latitude)
        return (
            radians(coordinate.longitude - origin.longitude) * cos(originLatitude) *
                earthRadiusMeters,
            radians(coordinate.latitude - origin.latitude) * earthRadiusMeters
        )
    }

    private func geodesicDistance(
        from start: RouteCoordinate,
        to end: RouteCoordinate
    ) -> Double {
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
    }

    private func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}
