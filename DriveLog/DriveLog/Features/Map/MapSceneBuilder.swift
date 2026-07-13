import Foundation

nonisolated struct MapSceneBuilder: MapSceneBuilding {
    private let regionPaddingScale = 1.2
    private let minimumRegionDelta = 0.01

    func build(
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        media: [MediaPlacement]
    ) -> MapScene {
        let polylines = movements.compactMap { movement -> MapPolyline? in
            guard !movement.route.isEmpty else { return nil }
            return MapPolyline(
                segmentStableID: movement.stableID,
                coordinates: movement.route
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
        let stayAnnotations = stays.compactMap { stay -> MapStayAnnotation? in
            guard stay.isVisibleByAutomaticRule else { return nil }
            return MapStayAnnotation(
                stayStableID: stay.stableID,
                coordinate: stay.representativeCoordinate,
                text: stayDurationText(seconds: stay.durationSeconds)
            )
        }
        let mediaAnnotations = media.map {
            MapMediaAnnotation(
                localIdentifier: $0.assetIdentifier,
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
