import Foundation
import Observation

nonisolated enum CalendarViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error
}

@MainActor
@Observable
final class CalendarViewModel {
    private(set) var displayedMonth: LocalMonth
    private(set) var days: [CalendarDayData] = []
    private(set) var state: CalendarViewState = .idle
    private(set) var selectedLocalDateKey: String?
    private(set) var navigationLocalDateKey: String?

    private let loadCalendarMonth: any LoadCalendarMonthUseCase
    private var requestID: UUID?

    init(
        displayedMonth: LocalMonth,
        loadCalendarMonth: any LoadCalendarMonthUseCase
    ) {
        self.displayedMonth = displayedMonth
        self.loadCalendarMonth = loadCalendarMonth
    }

    func load() async {
        let requestedMonth = displayedMonth
        let id = UUID()
        requestID = id
        state = .loading
        do {
            let data = try await loadCalendarMonth.execute(month: requestedMonth)
            guard requestID == id, displayedMonth == requestedMonth else { return }
            days = data.days
            state = data.days.contains(where: \.hasValidMovement) ? .loaded : .empty
        } catch {
            guard requestID == id, displayedMonth == requestedMonth else { return }
            state = .error
        }
    }

    func showPreviousMonth() async {
        await show(monthOffset: -1)
    }

    func showNextMonth() async {
        await show(monthOffset: 1)
    }

    func select(localDateKey: String) {
        guard days.contains(where: {
            $0.localDateKey == localDateKey && $0.hasValidMovement
        }) else { return }
        selectedLocalDateKey = localDateKey
        navigationLocalDateKey = localDateKey
    }

    func consumeNavigation() {
        navigationLocalDateKey = nil
    }

    private func show(monthOffset: Int) async {
        displayedMonth = displayedMonth.adding(months: monthOffset)
        selectedLocalDateKey = nil
        navigationLocalDateKey = nil
        await load()
    }
}

private extension LocalMonth {
    nonisolated func adding(months offset: Int) -> LocalMonth {
        let zeroBasedMonth = year * 12 + month - 1 + offset
        let adjustedYear = zeroBasedMonth >= 0
            ? zeroBasedMonth / 12 : (zeroBasedMonth - 11) / 12
        let adjustedMonth = zeroBasedMonth - adjustedYear * 12 + 1
        return LocalMonth(year: adjustedYear, month: adjustedMonth)
    }
}
