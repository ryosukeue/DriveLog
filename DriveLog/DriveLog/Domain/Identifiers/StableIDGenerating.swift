import Foundation

protocol StableIDGenerating: Sendable {
    func movementSegmentID(
        localDateKey: String,
        startDate: Date,
        endDate: Date
    ) -> String

    func staySegmentID(
        localDateKey: String,
        arrivalDate: Date,
        departureDate: Date,
        latitude: Double,
        longitude: Double
    ) -> String
}
