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

    @Test("represents an empty month and an error without discarding days")
    func emptyAndError() async {
        let month = LocalMonth(year: 2024, month: 1)
        let useCase = CalendarLoadSequenceFake(results: [
            .success(CalendarMonthData(
                month: month,
                days: [CalendarDayData(
                    localDateKey: "2024-01-01", day: 1,
                    totalDistanceMeters: nil, hasValidMovement: false
                )]
            )),
            .failure(CalendarTestError.expected)
        ])
        let viewModel = CalendarViewModel(displayedMonth: month, loadCalendarMonth: useCase)

        await viewModel.load()
        #expect(viewModel.state == .empty)
        #expect(viewModel.days.count == 1)
        await viewModel.load()

        #expect(viewModel.state == .error)
        #expect(viewModel.days.count == 1)
    }

    @Test("moves across year boundaries and clears selection")
    func monthMovement() async {
        let december = LocalMonth(year: 2024, month: 12)
        let january = LocalMonth(year: 2025, month: 1)
        let useCase = CalendarLoadFake(results: [
            (december, .success(CalendarMonthData(
                month: december,
                days: [CalendarDayData(
                    localDateKey: "2024-12-01", day: 1,
                    totalDistanceMeters: 2000, hasValidMovement: true
                )]
            ))),
            (january, .success(CalendarMonthData(month: january, days: [])))
        ])
        let viewModel = CalendarViewModel(displayedMonth: december, loadCalendarMonth: useCase)
        await viewModel.load()
        viewModel.select(localDateKey: "2024-12-01")

        await viewModel.showNextMonth()
        #expect(viewModel.displayedMonth == january)
        #expect(viewModel.selectedLocalDateKey == nil)
        #expect(viewModel.state == .empty)
        await viewModel.showPreviousMonth()
        #expect(viewModel.displayedMonth == december)
    }

    @Test("ignores an older response after moving to a new month")
    func staleResponse() async {
        let useCase = ControlledCalendarLoadFake()
        let viewModel = CalendarViewModel(
            displayedMonth: LocalMonth(year: 2024, month: 1),
            loadCalendarMonth: useCase
        )
        let oldLoad = Task { await viewModel.load() }
        await useCase.waitForRequests(1)
        let newLoad = Task { await viewModel.showNextMonth() }
        await useCase.waitForRequests(2)
        await useCase.complete(
            month: LocalMonth(year: 2024, month: 2),
            days: [CalendarDayData(
                localDateKey: "2024-02-02", day: 2,
                totalDistanceMeters: 2000, hasValidMovement: true
            )]
        )
        await newLoad.value
        await useCase.complete(
            month: LocalMonth(year: 2024, month: 1),
            days: [CalendarDayData(
                localDateKey: "2024-01-01", day: 1,
                totalDistanceMeters: 1000, hasValidMovement: true
            )]
        )
        await oldLoad.value

        #expect(viewModel.displayedMonth == LocalMonth(year: 2024, month: 2))
        #expect(viewModel.days.map(\.localDateKey) == ["2024-02-02"])
    }
}

private struct CalendarLoadFake: LoadCalendarMonthUseCase {
    let results: [(LocalMonth, Result<CalendarMonthData, CalendarTestError>)]

    func execute(month: LocalMonth) throws -> CalendarMonthData {
        guard let result = results.first(where: { $0.0 == month })?.1 else {
            throw CalendarTestError.expected
        }
        return try result.get()
    }
}

private actor CalendarLoadSequenceFake: LoadCalendarMonthUseCase {
    private var results: [Result<CalendarMonthData, CalendarTestError>]

    init(results: [Result<CalendarMonthData, CalendarTestError>]) {
        self.results = results
    }

    func execute(month _: LocalMonth) throws -> CalendarMonthData {
        guard !results.isEmpty else { throw CalendarTestError.expected }
        return try results.removeFirst().get()
    }
}

private actor ControlledCalendarLoadFake: LoadCalendarMonthUseCase {
    private var continuations: [(
        LocalMonth,
        CheckedContinuation<CalendarMonthData, any Error>
    )] = []
    private var requestCount = 0
    private var requestWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func execute(month: LocalMonth) async throws -> CalendarMonthData {
        requestCount += 1
        resumeRequestWaiters()
        return try await withCheckedThrowingContinuation { continuations.append((month, $0)) }
    }

    func waitForRequests(_ count: Int) async {
        guard requestCount < count else { return }
        await withCheckedContinuation { requestWaiters.append((count, $0)) }
    }

    func complete(month: LocalMonth, days: [CalendarDayData]) {
        guard let index = continuations.firstIndex(where: { $0.0 == month }) else { return }
        let continuation = continuations.remove(at: index).1
        continuation.resume(returning: CalendarMonthData(month: month, days: days))
    }

    private func resumeRequestWaiters() {
        let ready = requestWaiters.filter { $0.0 <= requestCount }
        requestWaiters.removeAll { $0.0 <= requestCount }
        ready.forEach { $0.1.resume() }
    }
}

private enum CalendarTestError: Error, Sendable {
    case expected
}
