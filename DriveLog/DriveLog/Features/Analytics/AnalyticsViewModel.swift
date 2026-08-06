import Observation

nonisolated enum AnalyticsViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case error
}

@MainActor
@Observable
final class AnalyticsViewModel {
    private(set) var state: AnalyticsViewState = .idle
    private(set) var selectedMonth: LocalMonth
    private(set) var series: MonthlyDistanceSeriesData?
    let currentMonth: LocalMonth

    var canMoveToNextMonth: Bool {
        selectedMonth < currentMonth
    }

    private let loadMonthlyDistanceSeries: any LoadMonthlyDistanceSeriesUseCase
    private var requestID = 0

    init(
        currentMonth: LocalMonth,
        loadMonthlyDistanceSeries: any LoadMonthlyDistanceSeriesUseCase
    ) {
        self.currentMonth = currentMonth
        selectedMonth = currentMonth
        self.loadMonthlyDistanceSeries = loadMonthlyDistanceSeries
    }

    func load() async {
        await load(month: selectedMonth)
    }

    func moveToPreviousMonth() async {
        await load(month: selectedMonth.adding(months: -1))
    }

    func moveToNextMonth() async {
        guard canMoveToNextMonth else { return }
        await load(month: selectedMonth.adding(months: 1))
    }

    func select(month: LocalMonth) async {
        guard month <= currentMonth else { return }
        await load(month: month)
    }

    private func load(month: LocalMonth) async {
        selectedMonth = month
        requestID += 1
        let currentRequestID = requestID
        state = .loading
        do {
            let result = try await loadMonthlyDistanceSeries.execute(month: month)
            guard currentRequestID == requestID else { return }
            series = result
            state = .loaded
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
        } catch {
            guard currentRequestID == requestID else { return }
            series = nil
            state = .error
        }
    }
}
