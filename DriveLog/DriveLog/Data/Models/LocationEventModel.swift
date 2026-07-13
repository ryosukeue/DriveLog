import Foundation
import SwiftData

@Model
final class LocationEventModel {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var horizontalAccuracy: Double
    var speedMetersPerSecond: Double?
    var createdAt: Date
    var timeZoneIdentifier: String
    var utcOffsetSeconds: Int
    var localDateKey: String
    var deduplicationKey: String

    init(
        id: UUID = UUID(), latitude: Double, longitude: Double, timestamp: Date,
        horizontalAccuracy: Double, speedMetersPerSecond: Double?, createdAt: Date,
        timeZoneIdentifier: String, utcOffsetSeconds: Int, localDateKey: String,
        deduplicationKey: String
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.horizontalAccuracy = horizontalAccuracy
        self.speedMetersPerSecond = speedMetersPerSecond
        self.createdAt = createdAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.utcOffsetSeconds = utcOffsetSeconds
        self.localDateKey = localDateKey
        self.deduplicationKey = deduplicationKey
    }
}
