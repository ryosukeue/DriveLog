import Foundation

nonisolated struct MapScene: Sendable, Equatable {
    let polylines: [MapPolyline]
    let movementLabels: [MapMovementLabel]
    let stayAnnotations: [MapStayAnnotation]
    let mediaAnnotations: [MapMediaAnnotation]
    let initialRegion: MapRegion?

    static let empty = MapScene(
        polylines: [],
        movementLabels: [],
        stayAnnotations: [],
        mediaAnnotations: [],
        initialRegion: nil
    )
}

nonisolated struct MapPolyline: Sendable, Equatable {
    let segmentStableID: String
    let coordinates: [RouteCoordinate]
}

nonisolated struct MapMovementLabel: Sendable, Equatable {
    let segmentStableID: String
    let coordinate: RouteCoordinate
    let text: String
    let startDate: Date
    let endDate: Date
    let durationSeconds: Double
    let distanceMeters: Double
    let averageSpeedMetersPerSecond: Double?
    let automaticClassification: AutomaticMovementType
    let userClassification: UserMovementClassification?
}

nonisolated struct MapStayAnnotation: Sendable, Equatable {
    let stayStableID: String
    let coordinate: RouteCoordinate
    let text: String
    let arrivalDate: Date
    let departureDate: Date
    let durationSeconds: Double
    let confidence: StayConfidence
    let isVisibleByAutomaticRule: Bool
}

nonisolated struct MapMediaAnnotation: Sendable, Equatable {
    let localIdentifier: String
    let coordinate: RouteCoordinate
}

nonisolated struct MapRegion: Sendable, Equatable {
    let center: RouteCoordinate
    let latitudeDelta: Double
    let longitudeDelta: Double
}

nonisolated protocol MapSceneBuilding: Sendable {
    func build(
        movements: [MovementSegmentData],
        stays: [StaySegmentData],
        media: [MediaPlacement]
    ) -> MapScene
}
