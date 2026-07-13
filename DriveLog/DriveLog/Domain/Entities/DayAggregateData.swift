import Foundation

nonisolated struct DayAggregateData: Sendable, Equatable {
    let localDateKey: String
    let totalDistanceMeters: Double
    let totalMovementDurationSeconds: Double
    let startDate: Date?
    let endDate: Date?
    let locationRecordCount: Int
    let rejectedLocationCount: Int
    let mediaCountCache: Int
    let automaticClassification: AutomaticMovementType
    let hasValidMovement: Bool
    let movementSegmentCount: Int
    let staySegmentCount: Int
    let totalStayDurationSeconds: Double
    let automotiveDurationSeconds: Double
    let walkingDurationSeconds: Double
    let sourceRawRevision: Int
    let generatedAt: Date
}
