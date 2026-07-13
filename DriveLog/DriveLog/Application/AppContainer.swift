import SwiftData

final class AppContainer {
    let logger: any Logging
    let clock: any Clock
    let timeZoneProvider: any TimeZoneProviding
    let localTimeContextProvider: any LocalTimeContextProviding

    convenience init() {
        let timeZoneProvider = SystemTimeZoneProvider()
        self.init(
            logger: OSLogLogger(),
            clock: SystemClock(),
            timeZoneProvider: timeZoneProvider,
            localTimeContextProvider: DefaultLocalTimeContextProvider(
                timeZoneProvider: timeZoneProvider
            )
        )
    }

    init(
        logger: any Logging,
        clock: any Clock,
        timeZoneProvider: any TimeZoneProviding,
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        self.logger = logger
        self.clock = clock
        self.timeZoneProvider = timeZoneProvider
        self.localTimeContextProvider = localTimeContextProvider
    }

    func makeCalendarViewModel(
        modelContainer: ModelContainer,
        displayedMonth: LocalMonth
    ) -> CalendarViewModel {
        let repository = SwiftDataDerivedDataRepository(modelContainer: modelContainer)
        return CalendarViewModel(
            displayedMonth: displayedMonth,
            loadCalendarMonth: DefaultLoadCalendarMonthUseCase(repository: repository)
        )
    }

    func makeDayDetailViewModel(
        modelContainer: ModelContainer,
        localDateKey: String
    ) -> DayDetailViewModel {
        DayDetailViewModel(
            localDateKey: localDateKey,
            loadDayDetail: DefaultLoadDayDetailUseCase(
                derivedRepository: SwiftDataDerivedDataRepository(
                    modelContainer: modelContainer
                ),
                overrideRepository: SwiftDataOverrideRepository(
                    modelContainer: modelContainer
                ),
                processingStateRepository: SwiftDataProcessingStateRepository(
                    modelContainer: modelContainer,
                    clock: clock
                ),
                mediaCacheRepository: SwiftDataMediaCacheRepository(
                    modelContainer: modelContainer
                ),
                mapSceneBuilder: MapSceneBuilder()
            ),
            loadMediaThumbnail: DefaultLoadMediaThumbnailUseCase(
                photoLibrary: PhotoLibraryProvider()
            )
        )
    }

    func makeMediaPreviewViewModel(asset: MediaAssetReference) -> MediaPreviewViewModel {
        let photoLibrary = PhotoLibraryProvider()
        return MediaPreviewViewModel(
            asset: asset,
            loadPreview: DefaultLoadMediaPreviewUseCase(
                photoLibrary: photoLibrary
            ),
            shareMedia: DefaultShareMediaUseCase(
                photoLibrary: photoLibrary,
                presenter: SystemSharePresenter()
            )
        )
    }
}
