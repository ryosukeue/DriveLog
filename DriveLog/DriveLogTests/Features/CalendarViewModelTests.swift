@testable import DriveLog
import Testing

@Suite("Calendar view model")
@MainActor
struct CalendarViewModelTests {
    @Test("loads valid days and selects only a movement day")
    func loadedAndSelection() async {
        let month = LocalMonth(year: 2024, month: 1)
        let useCase = CalendarLoadFake(results: [(month, .success(CalendarMonthData(
            month: month,
            days: [
                CalendarDayData(
                    localDateKey: "2024-01-01", day: 1,
                    totalDistanceMeters: nil, hasValidMovement: false
                ),
                CalendarDayData(
                    localDateKey: "2024-01-02", day: 2,
                    totalDistanceMeters: 1500, hasValidMovement: true
                )
            ]
        )))])
        let viewModel = CalendarViewModel(displayedMonth: month, loadCalendarMonth: useCase)

        await viewModel.load()
        viewModel.select(localDateKey: "2024-01-01")
        #expect(viewModel.selectedLocalDateKey == nil)
        viewModel.select(localDateKey: "2024-01-02")

        #expect(viewModel.state == .loaded)
        #expect(viewModel.selectedLocalDateKey == "2024-01-02")
        #expect(viewModel.navigationLocalDateKey == "2024-01-02")
        viewModel.consumeNavigation()
        #expect(viewModel.navigationLocalDateKey == nil)
    }

    @Test("represents an empty month and an error")
    func emptyAndError() async {
        let month = LocalMonth(year: 2024, month: 1)
        let emptyViewModel = CalendarViewModel(
            displayedMonth: month,
            loadCalendarMonth: CalendarLoadFake(results: [(month, .success(CalendarMonthData(
                month: month,
                days: [CalendarDayData(
                    localDateKey: "2024-01-01", day: 1,
                    totalDistanceMeters: nil, hasValidMovement: false
                )]
            )))])
        )

        await emptyViewModel.load()
        #expect(emptyViewModel.state == .empty)
        #expect(emptyViewModel.days.count == 1)

        let errorViewModel = CalendarViewModel(
            displayedMonth: month,
            loadCalendarMonth: CalendarLoadFailureFake()
        )
        await errorViewModel.load()

        #expect(errorViewModel.state == .error)
    }

    @Test("extends past and future across year boundaries")
    func extensions() async {
        let december = LocalMonth(year: 2024, month: 12)
        let useCase = CalendarLoadFake(results: [
            (december, .success(CalendarMonthData(month: december, days: [])))
        ])
        let viewModel = CalendarViewModel(displayedMonth: december, loadCalendarMonth: useCase)
        await viewModel.load()

        if let first = viewModel.months.first?.month {
            await viewModel.loadMorePastIfNeeded(visibleMonth: first)
        }
        if let last = viewModel.months.last?.month {
            await viewModel.loadMoreFutureIfNeeded(visibleMonth: last)
        }

        #expect(viewModel.months.first?.month == LocalMonth(year: 2024, month: 7))
        #expect(viewModel.months.last?.month == LocalMonth(year: 2025, month: 5))
    }
}

private struct CalendarLoadFake: LoadCalendarMonthUseCase {
    let results: [(LocalMonth, Result<CalendarMonthData, CalendarTestError>)]

    func execute(month: LocalMonth) throws -> CalendarMonthData {
        guard let result = results.first(where: { $0.0 == month })?.1 else {
            return CalendarMonthData(month: month, days: [])
        }
        return try result.get()
    }
}

private struct CalendarLoadFailureFake: LoadCalendarMonthUseCase {
    func execute(month _: LocalMonth) throws -> CalendarMonthData {
        throw CalendarTestError.expected
    }
}

private enum CalendarTestError: Error, Sendable {
    case expected
}
