import Foundation

nonisolated struct StaySegmentData: Sendable, Equatable {
    let stableID: String
    let localDateKey: String
    let representativeCoordinate: RouteCoordinate
    let estimatedArrivalDate: Date
    let estimatedDepartureDate: Date
    let durationSeconds: Double
    let confidence: StayConfidence
    let source: StayDetectionSource
    let isVisibleByAutomaticRule: Bool
    let sourceRawRevision: Int
    let generatedAt: Date
}
