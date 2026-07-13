import Foundation
import SwiftData

@Model
final class StayOverrideModel {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var overrideKey: String
    var targetStableID: String
    var localDateKey: String
    var originalArrivalDate: Date
    var originalDepartureDate: Date
    var originalLatitude: Double
    var originalLongitude: Double
    var actionRawValue: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(), overrideKey: String, targetStableID: String,
        localDateKey: String, originalArrivalDate: Date, originalDepartureDate: Date,
        originalLatitude: Double, originalLongitude: Double, actionRawValue: String,
        createdAt: Date, updatedAt: Date
    ) {
        self.id = id
        self.overrideKey = overrideKey
        self.targetStableID = targetStableID
        self.localDateKey = localDateKey
        self.originalArrivalDate = originalArrivalDate
        self.originalDepartureDate = originalDepartureDate
        self.originalLatitude = originalLatitude
        self.originalLongitude = originalLongitude
        self.actionRawValue = actionRawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
