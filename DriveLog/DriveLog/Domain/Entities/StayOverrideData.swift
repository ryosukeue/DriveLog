import Foundation

nonisolated struct StayOverrideData: Sendable, Equatable {
    let overrideKey: String
    let targetStableID: String
    let localDateKey: String
    let originalArrivalDate: Date
    let originalDepartureDate: Date
    let originalCoordinate: RouteCoordinate
    let action: StayOverrideAction
    let createdAt: Date
    let updatedAt: Date
}
