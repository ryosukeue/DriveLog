import Foundation

nonisolated struct MapSceneBuilder: MapSceneBuilding {
    private let regionPaddingScale = 1.2
    private let minimumRegionDelta = 0.01
    private let distanceCalculator = GeodesicDistanceCalculator()
    private let stayRules = ProcessingConfiguration.mvp.stay

    func build(
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        media: [MediaPlacement]
    ) -> MapScene {
        let visibleStays = stays.filter(\.isVisibleByAutomaticRule)
        let polylines = movements.compactMap { movement -> MapPolyline? in
            guard !movement.route.isEmpty else { return nil }
            return MapPolyline(
                segmentStableID: movement.stableID,
                coordinates: routeCoordinates(for: movement, visibleStays: visibleStays)
            )
        }
        let labels = movements.compactMap { movement -> MapMovementLabel? in
            guard let coordinate = movement.labelCoordinate else { return nil }
            return MapMovementLabel(
                segmentStableID: movement.stableID,
                coordinate: coordinate,
                text: labelText(for: movement),
                startDate: movement.startDate,
                endDate: movement.endDate,
                durationSeconds: movement.durationSeconds,
                distanceMeters: movement.distanceMeters,
                averageSpeedMetersPerSecond: movement.estimatedAverageSpeedMetersPerSecond,
                automaticClassification: movement.automaticClassification,
                userClassification: nil
            )
        }
        let stayAnnotations = visibleStays.map { stay in
            MapStayAnnotation(
                stayStableID: stay.stableID,
                coordinate: stay.representativeCoordinate,
                text: stayDurationText(seconds: stay.durationSeconds),
                arrivalDate: stay.estimatedArrivalDate,
                departureDate: stay.estimatedDepartureDate,
                durationSeconds: stay.durationSeconds,
                confidence: stay.confidence,
                isVisibleByAutomaticRule: stay.isVisibleByAutomaticRule
            )
        }
        let mediaAnnotations = media.map {
            MapMediaAnnotation(
                localIdentifier: $0.assetIdentifier, mediaType: $0.mediaType,
                coordinate: $0.coordinate
            )
        }
        let coordinates = polylines.flatMap(\.coordinates) +
            stayAnnotations.map(\.coordinate) + mediaAnnotations.map(\.coordinate)
        return MapScene(
            polylines: polylines,
            movementLabels: labels,
            stayAnnotations: stayAnnotations,
            mediaAnnotations: mediaAnnotations,
            initialRegion: initialRegion(coordinates: coordinates)
        )
    }

    private func labelText(for movement: MovementSegmentData) -> String {
        let minutes = max(0, Int(movement.durationSeconds) / 60)
        let kilometers = max(0, movement.distanceMeters) / 1000
        return String(format: "%d分・%.1fkm", minutes, kilometers)
    }

    private func stayDurationText(seconds: Double) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return hours > 0 ? "\(hours)時間\(minutes)分" : "\(minutes)分"
    }

    private func routeCoordinates(
        for movement: MovementSegmentData,
        visibleStays: [StaySegmentData]
    ) -> [RouteCoordinate] {
        guard !movement.route.isEmpty else { return [] }
        var coordinates = movement.route
        let sameDayStays = visibleStays.filter { $0.localDateKey == movement.localDateKey }
        if let precedingStay = nearestStay(
            in: sameDayStays,
            referenceDate: movement.startDate,
            date: \.estimatedDepartureDate
        ) {
            coordinates = adding(
                precedingStay.representativeCoordinate,
                toStartOf: coordinates
            )
        }
        if let followingStay = nearestStay(
            in: sameDayStays,
            referenceDate: movement.endDate,
            date: \.estimatedArrivalDate
        ) {
            coordinates = adding(
                followingStay.representativeCoordinate,
                toEndOf: coordinates
            )
        }
        return coordinates
    }

    private func nearestStay(
        in stays: [StaySegmentData],
        referenceDate: Date,
        date: KeyPath<StaySegmentData, Date>
    ) -> StaySegmentData? {
        // Raw location and Visit coordinates can disagree by more than the
        // processing stay radius. Time adjacency is the reliable signal for
        // this display-only endpoint correction; it does not alter the
        // persisted route or movement metrics.
        stays
            .filter {
                isTemporallyAdjacent($0, to: referenceDate, boundary: date)
            }
            .min {
                let firstDifference = abs($0[keyPath: date].timeIntervalSince(referenceDate))
                let secondDifference = abs($1[keyPath: date].timeIntervalSince(referenceDate))
                if firstDifference == secondDifference {
                    return $0.stableID < $1.stableID
                }
                return firstDifference < secondDifference
            }
    }

    private func isTemporallyAdjacent(
        _ stay: StaySegmentData,
        to referenceDate: Date,
        boundary: KeyPath<StaySegmentData, Date>
    ) -> Bool {
        let boundaryDifference = abs(
            stay[keyPath: boundary].timeIntervalSince(referenceDate)
        )
        if boundaryDifference <= stayRules.automaticStayDuration {
            return true
        }
        return stay.estimatedArrivalDate <= referenceDate &&
            referenceDate <= stay.estimatedDepartureDate
    }

    private func adding(
        _ coordinate: RouteCoordinate,
        toStartOf coordinates: [RouteCoordinate]
    ) -> [RouteCoordinate] {
        guard let first = coordinates.first else { return coordinates }
        guard distance(from: coordinate, to: first) > 1 else { return coordinates }
        return [coordinate] + coordinates
    }

    private func adding(
        _ coordinate: RouteCoordinate,
        toEndOf coordinates: [RouteCoordinate]
    ) -> [RouteCoordinate] {
        guard let last = coordinates.last else { return coordinates }
        guard distance(from: last, to: coordinate) > 1 else { return coordinates }
        return coordinates + [coordinate]
    }

    private func distance(from start: RouteCoordinate, to end: RouteCoordinate) -> Double {
        distanceCalculator.meters(
            fromLatitude: start.latitude,
            longitude: start.longitude,
            toLatitude: end.latitude,
            longitude: end.longitude
        )
    }

    private func initialRegion(coordinates: [RouteCoordinate]) -> MapRegion? {
        guard let first = coordinates.first else { return nil }
        let bounds = coordinates.dropFirst().reduce(
            (minLatitude: first.latitude, maxLatitude: first.latitude,
             minLongitude: first.longitude, maxLongitude: first.longitude)
        ) { bounds, coordinate in
            (
                min(bounds.minLatitude, coordinate.latitude),
                max(bounds.maxLatitude, coordinate.latitude),
                min(bounds.minLongitude, coordinate.longitude),
                max(bounds.maxLongitude, coordinate.longitude)
            )
        }
        return MapRegion(
            center: RouteCoordinate(
                latitude: (bounds.minLatitude + bounds.maxLatitude) / 2,
                longitude: (bounds.minLongitude + bounds.maxLongitude) / 2
            ),
            latitudeDelta: max(
                (bounds.maxLatitude - bounds.minLatitude) * regionPaddingScale,
                minimumRegionDelta
            ),
            longitudeDelta: max(
                (bounds.maxLongitude - bounds.minLongitude) * regionPaddingScale,
                minimumRegionDelta
            )
        )
    }
}
