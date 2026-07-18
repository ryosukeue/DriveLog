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
    let displayedMonth: LocalMonth
    private(set) var selectedMonth: LocalMonth
    private(set) var months: [CalendarMonthData] = []
    private(set) var state: CalendarViewState = .idle
    private(set) var selectedLocalDateKey: String?
    private(set) var navigationLocalDateKey: String?

    var days: [CalendarDayData] {
        months.first { $0.month == displayedMonth }?.days ?? []
    }

    var validLocalDateKeys: [String] {
        months
            .flatMap(\.days)
            .filter(\.hasValidMovement)
            .map(\.localDateKey)
            .sorted()
    }

    private let loadCalendarMonth: any LoadCalendarMonthUseCase
    private var loadedByMonth: [LocalMonth: CalendarMonthData] = [:]
    private var isExtending = false
    private let initialRadius = 2
    private let extensionCount = 3

    init(
        displayedMonth: LocalMonth,
        loadCalendarMonth: any LoadCalendarMonthUseCase
    ) {
        self.displayedMonth = displayedMonth
        selectedMonth = displayedMonth
        self.loadCalendarMonth = loadCalendarMonth
    }

    func select(month: LocalMonth) {
        guard months.contains(where: { $0.month == month }) else { return }
        selectedMonth = month
        selectedLocalDateKey = nil
        navigationLocalDateKey = nil
    }

    func load() async {
        state = .loading
        do {
            loadedByMonth[displayedMonth] = nil
            try await load(months: (-initialRadius ... initialRadius).map {
                displayedMonth.adding(months: $0)
            })
            updateState()
        } catch {
            state = .error
        }
    }

    func loadMorePastIfNeeded(visibleMonth: LocalMonth) async {
        guard visibleMonth == months.first?.month, !isExtending else { return }
        let values = (1 ... extensionCount).map { visibleMonth.adding(months: -$0) }.reversed()
        await extend(with: Array(values))
    }

    func loadMoreFutureIfNeeded(visibleMonth: LocalMonth) async {
        guard visibleMonth == months.last?.month, !isExtending else { return }
        await extend(with: (1 ... extensionCount).map { visibleMonth.adding(months: $0) })
    }

    func select(localDateKey: String) {
        guard months.flatMap(\.days).contains(where: {
            $0.localDateKey == localDateKey && $0.hasValidMovement
        }) else { return }
        selectedLocalDateKey = localDateKey
        navigationLocalDateKey = localDateKey
    }

    func consumeNavigation() {
        navigationLocalDateKey = nil
    }

    private func extend(with values: [LocalMonth]) async {
        isExtending = true
        defer { isExtending = false }
        try? await load(months: values)
        updateState()
    }

    private func load(months values: [LocalMonth]) async throws {
        for month in values where loadedByMonth[month] == nil {
            loadedByMonth[month] = try await loadCalendarMonth.execute(month: month)
        }
        months = loadedByMonth.values.sorted { $0.month < $1.month }
    }

    private func updateState() {
        state = months.flatMap(\.days).contains(where: \.hasValidMovement) ? .loaded : .empty
    }
}

extension LocalMonth: Comparable {
    static func < (lhs: LocalMonth, rhs: LocalMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    nonisolated func adding(months offset: Int) -> LocalMonth {
        let zeroBasedMonth = year * 12 + month - 1 + offset
        let adjustedYear = zeroBasedMonth >= 0
            ? zeroBasedMonth / 12 : (zeroBasedMonth - 11) / 12
        let adjustedMonth = zeroBasedMonth - adjustedYear * 12 + 1
        return LocalMonth(year: adjustedYear, month: adjustedMonth)
    }
}
