import Foundation
import SwiftData

@Model
final class MotionEventModel {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var isAutomotive: Bool
    var isWalking: Bool
    var isRunning: Bool
    var isCycling: Bool
    var isStationary: Bool
    var isUnknown: Bool
    var confidenceRawValue: Int
    var createdAt: Date
    var timeZoneIdentifier: String
    var utcOffsetSeconds: Int
    var localDateKey: String

    init(
        id: UUID = UUID(), startDate: Date, endDate: Date?, isAutomotive: Bool,
        isWalking: Bool, isRunning: Bool, isCycling: Bool, isStationary: Bool,
        isUnknown: Bool, confidenceRawValue: Int, createdAt: Date,
        timeZoneIdentifier: String, utcOffsetSeconds: Int, localDateKey: String
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.isAutomotive = isAutomotive
        self.isWalking = isWalking
        self.isRunning = isRunning
        self.isCycling = isCycling
        self.isStationary = isStationary
        self.isUnknown = isUnknown
        self.confidenceRawValue = confidenceRawValue
        self.createdAt = createdAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.utcOffsetSeconds = utcOffsetSeconds
        self.localDateKey = localDateKey
    }
}
