import Foundation

nonisolated struct MovementSegmentData: Sendable, Equatable {
    let stableID: String
    let localDateKey: String
    let startDate: Date
    let endDate: Date
    let distanceMeters: Double
    let durationSeconds: Double
    let estimatedAverageSpeedMetersPerSecond: Double?
    let automaticClassification: AutomaticMovementType
    let classificationConfidence: ClassificationConfidence
    let route: [RouteCoordinate]
    let labelCoordinate: RouteCoordinate?
    let sourceRawRevision: Int
    let generatedAt: Date
}
