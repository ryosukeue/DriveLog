import Foundation
import SwiftData

@Model
final class StaySegmentModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var stableID: String
    var localDateKey: String
    var representativeLatitude: Double
    var representativeLongitude: Double
    var estimatedArrivalDate: Date
    var estimatedDepartureDate: Date
    var durationSeconds: Double
    var confidenceRawValue: String
    var sourceRawValue: String
    var isVisibleByAutomaticRule: Bool
    var sourceRawRevision: Int
    var generatedAt: Date

    init(
        id: UUID = UUID(), stableID: String, localDateKey: String,
        representativeLatitude: Double, representativeLongitude: Double,
        estimatedArrivalDate: Date, estimatedDepartureDate: Date, durationSeconds: Double,
        confidenceRawValue: String, sourceRawValue: String, isVisibleByAutomaticRule: Bool,
        sourceRawRevision: Int, generatedAt: Date
    ) {
        self.id = id
        self.stableID = stableID
        self.localDateKey = localDateKey
        self.representativeLatitude = representativeLatitude
        self.representativeLongitude = representativeLongitude
        self.estimatedArrivalDate = estimatedArrivalDate
        self.estimatedDepartureDate = estimatedDepartureDate
        self.durationSeconds = durationSeconds
        self.confidenceRawValue = confidenceRawValue
        self.sourceRawValue = sourceRawValue
        self.isVisibleByAutomaticRule = isVisibleByAutomaticRule
        self.sourceRawRevision = sourceRawRevision
        self.generatedAt = generatedAt
    }
}
