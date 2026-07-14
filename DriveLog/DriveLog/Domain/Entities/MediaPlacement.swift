nonisolated struct MediaPlacement: Sendable, Equatable {
    let assetIdentifier: String
    let coordinate: RouteCoordinate
    let relatedMovementStableID: String?
}
