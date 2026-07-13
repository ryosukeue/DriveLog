import Foundation
import SwiftData

@Model
final class DayAggregateModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var localDateKey: String
    var totalDistanceMeters: Double
    var totalMovementDurationSeconds: Double
    var startDate: Date?
    var endDate: Date?
    var locationRecordCount: Int
    var rejectedLocationCount: Int
    var mediaCountCache: Int
    var automaticClassificationRawValue: String
    var hasValidMovement: Bool
    var movementSegmentCount: Int
    var staySegmentCount: Int
    var totalStayDurationSeconds: Double
    var automotiveDurationSeconds: Double
    var walkingDurationSeconds: Double
    var sourceRawRevision: Int
    var generatedAt: Date

    init(
        id: UUID = UUID(), localDateKey: String, totalDistanceMeters: Double,
        totalMovementDurationSeconds: Double, startDate: Date?, endDate: Date?,
        locationRecordCount: Int, rejectedLocationCount: Int, mediaCountCache: Int,
        automaticClassificationRawValue: String, hasValidMovement: Bool,
        movementSegmentCount: Int, staySegmentCount: Int, totalStayDurationSeconds: Double,
        automotiveDurationSeconds: Double, walkingDurationSeconds: Double,
        sourceRawRevision: Int, generatedAt: Date
    ) {
        self.id = id
        self.localDateKey = localDateKey
        self.totalDistanceMeters = totalDistanceMeters
        self.totalMovementDurationSeconds = totalMovementDurationSeconds
        self.startDate = startDate
        self.endDate = endDate
        self.locationRecordCount = locationRecordCount
        self.rejectedLocationCount = rejectedLocationCount
        self.mediaCountCache = mediaCountCache
        self.automaticClassificationRawValue = automaticClassificationRawValue
        self.hasValidMovement = hasValidMovement
        self.movementSegmentCount = movementSegmentCount
        self.staySegmentCount = staySegmentCount
        self.totalStayDurationSeconds = totalStayDurationSeconds
        self.automotiveDurationSeconds = automotiveDurationSeconds
        self.walkingDurationSeconds = walkingDurationSeconds
        self.sourceRawRevision = sourceRawRevision
        self.generatedAt = generatedAt
    }
}
