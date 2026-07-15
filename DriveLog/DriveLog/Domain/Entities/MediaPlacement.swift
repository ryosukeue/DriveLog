nonisolated struct MediaPlacement: Sendable, Equatable {
    let assetIdentifier: String
    let mediaType: MediaType
    let coordinate: RouteCoordinate
    let relatedMovementStableID: String?
}
