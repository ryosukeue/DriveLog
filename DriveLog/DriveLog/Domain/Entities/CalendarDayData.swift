struct CalendarDayData: Sendable, Equatable {
    let localDateKey: String
    let day: Int
    let totalDistanceMeters: Double?
    let hasValidMovement: Bool
}
