import Foundation
import SwiftData

@Model
final class VisitEventModel {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var arrivalDate: Date?
    var departureDate: Date?
    var horizontalAccuracy: Double
    var createdAt: Date
    var updatedAt: Date
    var timeZoneIdentifier: String
    var utcOffsetSeconds: Int
    var localDateKey: String
    var visitMatchKey: String

    init(
        id: UUID = UUID(), latitude: Double, longitude: Double, arrivalDate: Date?,
        departureDate: Date?, horizontalAccuracy: Double, createdAt: Date, updatedAt: Date,
        timeZoneIdentifier: String, utcOffsetSeconds: Int, localDateKey: String,
        visitMatchKey: String
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.horizontalAccuracy = horizontalAccuracy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.utcOffsetSeconds = utcOffsetSeconds
        self.localDateKey = localDateKey
        self.visitMatchKey = visitMatchKey
    }
}
