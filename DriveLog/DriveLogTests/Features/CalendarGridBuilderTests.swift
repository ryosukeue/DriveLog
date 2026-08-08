@testable import DriveLog
import Foundation
import Testing

@Suite("Calendar grid builder")
struct CalendarGridBuilderTests {
    @Test("builds leap February with a Sunday-first calendar")
    func leapYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        calendar.firstWeekday = 1
        let layout = try CalendarGridBuilder(calendar: calendar).makeLayout(
            month: LocalMonth(year: 2024, month: 2),
            today: #require(calendar.date(from: DateComponents(
                year: 2024, month: 2, day: 15
            )))
        )

        #expect(layout.daySlots.compactMap { $0 }.count == 29)
        #expect(layout.daySlots.prefix(4).allSatisfy { $0 == nil })
        #expect(layout.weekdaySymbols.first == "S")
        #expect(layout.todayDay == 15)
    }

    @Test("rotates symbols and slots for a Monday-first calendar")
    func mondayFirst() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_GB")
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        calendar.firstWeekday = 2
        let layout = try CalendarGridBuilder(calendar: calendar).makeLayout(
            month: LocalMonth(year: 2024, month: 9),
            today: Date(timeIntervalSince1970: 0)
        )

        #expect(layout.weekdaySymbols.first == "M")
        #expect(layout.daySlots.prefix(6).allSatisfy { $0 == nil })
        #expect(layout.daySlots[6] == 1)
        #expect(layout.todayDay == nil)
    }

    @Test("rejects an invalid month")
    func invalidMonth() {
        let builder = CalendarGridBuilder(calendar: Calendar(identifier: .gregorian))

        #expect(throws: DriveLogError.invalidData) {
            try builder.makeLayout(
                month: LocalMonth(year: 2024, month: 13),
                today: Date(timeIntervalSince1970: 0)
            )
        }
    }

    @Test("August 2026 exposes all six calendar rows")
    func sixWeekAugust() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Tokyo"))
        calendar.firstWeekday = 1

        let layout = try CalendarGridBuilder(calendar: calendar).makeLayout(
            month: LocalMonth(year: 2026, month: 8),
            today: Date(timeIntervalSince1970: 0)
        )

        #expect(layout.weekRowCount == 6)
        #expect(layout.daySlots.compactMap { $0 }.last == 31)
    }
}
