import Foundation
import SwiftData

@Model
final class MovementSegmentModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var stableID: String
    var localDateKey: String
    var startDate: Date
    var endDate: Date
    var distanceMeters: Double
    var durationSeconds: Double
    var estimatedAverageSpeedMetersPerSecond: Double?
    var automaticClassificationRawValue: String
    var classificationConfidenceRawValue: String
    var encodedRouteData: Data
    var labelLatitude: Double?
    var labelLongitude: Double?
    var sourceRawRevision: Int
    var generatedAt: Date

    init(
        id: UUID = UUID(), stableID: String, localDateKey: String, startDate: Date,
        endDate: Date, distanceMeters: Double, durationSeconds: Double,
        estimatedAverageSpeedMetersPerSecond: Double?, automaticClassificationRawValue: String,
        classificationConfidenceRawValue: String, encodedRouteData: Data,
        labelLatitude: Double?, labelLongitude: Double?, sourceRawRevision: Int,
        generatedAt: Date
    ) {
        self.id = id
        self.stableID = stableID
        self.localDateKey = localDateKey
        self.startDate = startDate
        self.endDate = endDate
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.estimatedAverageSpeedMetersPerSecond = estimatedAverageSpeedMetersPerSecond
        self.automaticClassificationRawValue = automaticClassificationRawValue
        self.classificationConfidenceRawValue = classificationConfidenceRawValue
        self.encodedRouteData = encodedRouteData
        self.labelLatitude = labelLatitude
        self.labelLongitude = labelLongitude
        self.sourceRawRevision = sourceRawRevision
        self.generatedAt = generatedAt
    }
}
