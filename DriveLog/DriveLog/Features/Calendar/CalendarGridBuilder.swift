import Foundation

nonisolated struct CalendarGridLayout: Sendable, Equatable {
    let monthTitle: String
    let weekdaySymbols: [String]
    let daySlots: [Int?]
    let todayDay: Int?

    var weekRowCount: Int {
        max(1, Int(ceil(Double(daySlots.count) / 7)))
    }
}

nonisolated struct CalendarGridBuilder: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func makeLayout(month: LocalMonth, today: Date) throws -> CalendarGridLayout {
        guard (1 ... 12).contains(month.month),
              let firstDate = calendar.date(from: DateComponents(
                  year: month.year, month: month.month, day: 1
              )), let dayRange = calendar.range(of: .day, in: .month, for: firstDate)
        else {
            throw DriveLogError.invalidData
        }
        let firstWeekday = calendar.component(.weekday, from: firstDate)
        let leadingEmptyCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        let symbols = rotatedWeekdaySymbols()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        let title = formatter.string(from: firstDate)
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let todayDay = todayComponents.year == month.year && todayComponents.month == month.month
            ? todayComponents.day : nil
        return CalendarGridLayout(
            monthTitle: title,
            weekdaySymbols: symbols,
            daySlots: Array(repeating: nil, count: leadingEmptyCount)
                + dayRange.map(Optional.some),
            todayDay: todayDay
        )
    }

    private func rotatedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let startIndex = max(0, min(6, calendar.firstWeekday - 1))
        return Array(symbols[startIndex...] + symbols[..<startIndex])
    }
}
