import SwiftData

struct DriveLogRootViewModels {
    let calendar: CalendarViewModel
    let monthlySummary: MonthlySummaryViewModel
    let monthlyOverview: MonthlyOverviewViewModel
    let analytics: AnalyticsViewModel
}

extension AppContainer {
    func makeRootViewModels(
        modelContainer: ModelContainer,
        displayedMonth: LocalMonth,
        photoLibrary: any PhotoLibraryProviding
    ) -> DriveLogRootViewModels {
        DriveLogRootViewModels(
            calendar: makeCalendarViewModel(
                modelContainer: modelContainer,
                displayedMonth: displayedMonth
            ),
            monthlySummary: makeMonthlySummaryViewModel(modelContainer: modelContainer),
            monthlyOverview: makeMonthlyOverviewViewModel(
                modelContainer: modelContainer,
                photoLibrary: photoLibrary
            ),
            analytics: makeAnalyticsViewModel(
                modelContainer: modelContainer,
                currentMonth: displayedMonth
            )
        )
    }

    func makeAnalyticsViewModel(
        modelContainer: ModelContainer,
        currentMonth: LocalMonth
    ) -> AnalyticsViewModel {
        AnalyticsViewModel(
            currentMonth: currentMonth,
            loadMonthlyDistanceSeries: DefaultLoadMonthlyDistanceSeriesUseCase(
                repository: SwiftDataDerivedDataRepository(modelContainer: modelContainer)
            )
        )
    }
}
