import Foundation

struct LocationEventData: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let speedMetersPerSecond: Double?
    let createdAt: Date
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
