import Foundation

nonisolated struct MotionEventData: Sendable, Equatable {
    let startDate: Date
    let endDate: Date?
    let isAutomotive: Bool
    let isWalking: Bool
    let isRunning: Bool
    let isCycling: Bool
    let isStationary: Bool
    let isUnknown: Bool
    let confidence: MotionConfidence
    let timeZoneIdentifier: String
    let utcOffsetSeconds: Int
    let localDateKey: String
}
