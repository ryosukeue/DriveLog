import Foundation

nonisolated struct VisitEventData: Sendable, Equatable {
    let latitude: Double
    let longitude: Double
    let arrivalDate: Date?
    let departureDate: Date?
    let horizontalAccuracy: Double
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
