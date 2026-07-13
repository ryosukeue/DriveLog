nonisolated struct CalendarMonthData: Sendable, Equatable {
    let month: LocalMonth
    let days: [CalendarDayData]
}
