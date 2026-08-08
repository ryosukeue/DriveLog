nonisolated struct OverrideDisplayDataApplier: Sendable {
    func apply(
        to scene: MapScene,
        movements: [MovementDisplayData],
        stays: [StayDisplayData]
    ) -> MapScene {
        let movementsByID = Dictionary(
            movements.map { ($0.segment.stableID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let staysByID = Dictionary(
            stays.map { ($0.segment.stableID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        return MapScene(
            polylines: scene.polylines.map { polyline in
                guard let display = movementsByID[polyline.segmentStableID] else {
                    return polyline
                }
                return MapPolyline(
                    segmentStableID: polyline.segmentStableID,
                    coordinates: polyline.coordinates,
                    colorHex: display.vehicle?.colorHex
                )
            },
            movementLabels: scene.movementLabels.map { label in
                guard let display = movementsByID[label.segmentStableID] else { return label }
                return label.copy(userClassification: display.userClassification)
            },
            stayAnnotations: scene.stayAnnotations.compactMap { annotation in
                guard let display = staysByID[annotation.stayStableID] else { return annotation }
                guard display.isVisible else { return nil }
                return annotation.copy(
                    isVisibleByAutomaticRule: display.segment.isVisibleByAutomaticRule
                )
            },
            mediaAnnotations: scene.mediaAnnotations,
            initialRegion: scene.initialRegion
        )
    }
}

nonisolated extension MapScene {
    func applyingVehicleColors(_ colorsByStableID: [String: String]) -> MapScene {
        MapScene(
            polylines: polylines.map { polyline in
                MapPolyline(
                    segmentStableID: polyline.segmentStableID,
                    coordinates: polyline.coordinates,
                    colorHex: colorsByStableID[polyline.segmentStableID]
                )
            },
            movementLabels: movementLabels,
            stayAnnotations: stayAnnotations,
            mediaAnnotations: mediaAnnotations,
            initialRegion: initialRegion
        )
    }
}

private extension MapMovementLabel {
    nonisolated func copy(
        userClassification: UserMovementClassification?
    ) -> MapMovementLabel {
        MapMovementLabel(
            segmentStableID: segmentStableID,
            coordinate: coordinate,
            text: text,
            startDate: startDate,
            endDate: endDate,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            averageSpeedMetersPerSecond: averageSpeedMetersPerSecond,
            automaticClassification: automaticClassification,
            userClassification: userClassification
        )
    }
}

private extension MapStayAnnotation {
    nonisolated func copy(isVisibleByAutomaticRule: Bool) -> MapStayAnnotation {
        MapStayAnnotation(
            stayStableID: stayStableID,
            coordinate: coordinate,
            text: text,
            arrivalDate: arrivalDate,
            departureDate: departureDate,
            durationSeconds: durationSeconds,
            confidence: confidence,
            isVisibleByAutomaticRule: isVisibleByAutomaticRule
        )
    }
}
