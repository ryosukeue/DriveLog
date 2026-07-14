import Foundation

nonisolated struct MediaAssetReference: Sendable, Equatable {
    let localIdentifier: String
    let mediaType: MediaType
    let creationDate: Date?
    let location: RouteCoordinate?
    let durationSeconds: Double?
    let isScreenshot: Bool
    let isScreenRecording: Bool
}
