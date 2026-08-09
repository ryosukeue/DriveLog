import SwiftData

struct DriveLogRootViewModels {
    let calendar: CalendarViewModel
    let monthlySummary: MonthlySummaryViewModel
    let monthlyOverview: MonthlyOverviewViewModel
    let analytics: AnalyticsViewModel
    let friends: FriendsViewModel
    let vehicles: VehiclesViewModel
    let iCloudSetup: ICloudSetupViewModel
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
            ),
            friends: makeFriendsViewModel(
                modelContainer: modelContainer,
                currentMonth: displayedMonth
            ),
            vehicles: makeVehiclesViewModel(),
            iCloudSetup: makeICloudSetupViewModel()
        )
    }

    func makeAnalyticsViewModel(
        modelContainer: ModelContainer,
        currentMonth: LocalMonth
    ) -> AnalyticsViewModel {
        AnalyticsViewModel(
            currentMonth: currentMonth,
            loadMonthlyDistanceSeries: DefaultLoadMonthlyDistanceSeriesUseCase(
                repository: SwiftDataDerivedDataRepository(modelContainer: modelContainer),
                vehicleAttribution: vehicleStore
            ),
            vehicleStore: vehicleStore,
            detector: audioRouteVehicleDetector
        )
    }

    func makeFriendsViewModel(
        modelContainer: ModelContainer,
        currentMonth: LocalMonth
    ) -> FriendsViewModel {
        FriendsViewModel(
            currentMonth: currentMonth,
            service: cloudFriendsService,
            loadMonthlyDistance: DefaultLoadMonthlyDistanceSeriesUseCase(
                repository: SwiftDataDerivedDataRepository(modelContainer: modelContainer),
                vehicleAttribution: vehicleStore
            )
        )
    }
}
