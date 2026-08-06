@testable import DriveLog
import Testing

@MainActor
@Suite("Analytics view model")
struct AnalyticsViewModelTests {
    @Test("loads the current month and navigates without entering the future")
    func navigation() async {
        let current = LocalMonth(year: 2026, month: 8)
        let viewModel = AnalyticsViewModel(
            currentMonth: current,
            loadMonthlyDistanceSeries: DistanceSeriesUseCaseFake()
        )

        await viewModel.load()
        #expect(viewModel.state == .loaded)
        #expect(viewModel.series?.month == current)
        #expect(viewModel.canMoveToNextMonth == false)

        await viewModel.moveToPreviousMonth()
        #expect(viewModel.selectedMonth == LocalMonth(year: 2026, month: 7))
        #expect(viewModel.canMoveToNextMonth)

        await viewModel.moveToNextMonth()
        await viewModel.moveToNextMonth()
        #expect(viewModel.selectedMonth == current)
    }

    @Test("represents a loading failure")
    func failure() async {
        let viewModel = AnalyticsViewModel(
            currentMonth: LocalMonth(year: 2026, month: 8),
            loadMonthlyDistanceSeries: DistanceSeriesUseCaseFake(error: .invalidData)
        )

        await viewModel.load()

        #expect(viewModel.state == .error)
        #expect(viewModel.series == nil)
    }
}

private struct DistanceSeriesUseCaseFake: LoadMonthlyDistanceSeriesUseCase {
    let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(month: LocalMonth) throws -> MonthlyDistanceSeriesData {
        if let error {
            throw error
        }
        return MonthlyDistanceSeriesData(month: month, days: [])
    }
}
