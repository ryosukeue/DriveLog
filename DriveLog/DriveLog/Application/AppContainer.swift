import SwiftData

final class AppContainer {
    let logger: any Logging
    let clock: any Clock
    let timeZoneProvider: any TimeZoneProviding
    let localTimeContextProvider: any LocalTimeContextProviding
    let hapticFeedback: any HapticFeedbackProviding

    convenience init() {
        let timeZoneProvider = SystemTimeZoneProvider()
        self.init(
            logger: OSLogLogger(),
            clock: SystemClock(),
            timeZoneProvider: timeZoneProvider,
            localTimeContextProvider: DefaultLocalTimeContextProvider(
                timeZoneProvider: timeZoneProvider
            ),
            hapticFeedback: SystemHapticFeedbackProvider()
        )
    }

    init(
        logger: any Logging,
        clock: any Clock,
        timeZoneProvider: any TimeZoneProviding,
        localTimeContextProvider: any LocalTimeContextProviding,
        hapticFeedback: any HapticFeedbackProviding
    ) {
        self.logger = logger
        self.clock = clock
        self.timeZoneProvider = timeZoneProvider
        self.localTimeContextProvider = localTimeContextProvider
        self.hapticFeedback = hapticFeedback
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
        localDateKey: String,
        photoLibrary: any PhotoLibraryProviding = PhotoLibraryProvider()
    ) -> DayDetailViewModel {
        let mediaCacheRepository = SwiftDataMediaCacheRepository(
            modelContainer: modelContainer
        )
        return DayDetailViewModel(
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
                mediaCacheRepository: mediaCacheRepository,
                mediaPlacementCalculator: MediaPlacementCalculator(),
                mapSceneBuilder: MapSceneBuilder()
            ),
            loadMediaThumbnail: DefaultLoadMediaThumbnailUseCase(photoLibrary: photoLibrary),
            refreshMediaCache: DefaultRefreshMediaCacheUseCase(
                photoLibrary: photoLibrary,
                eligibilityEvaluator: DefaultMediaEligibilityEvaluator(),
                mediaCacheRepository: mediaCacheRepository,
                clock: clock,
                timeZoneProvider: timeZoneProvider,
                logger: logger
            ),
            observePhotoLibraryChanges: DefaultObservePhotoLibraryChangesUseCase(
                photoLibrary: photoLibrary
            ),
            deleteDayLog: DefaultDeleteDayLogUseCase(
                repository: SwiftDataDayDeletionRepository(modelContainer: modelContainer),
                logger: logger
            ),
            hapticFeedback: hapticFeedback
        )
    }

    func makeLoadMediaThumbnailUseCase(
        photoLibrary: any PhotoLibraryProviding = PhotoLibraryProvider()
    ) -> any LoadMediaThumbnailUseCase {
        DefaultLoadMediaThumbnailUseCase(photoLibrary: photoLibrary)
    }

    func makeUpdateClassificationUseCase(
        modelContainer: ModelContainer
    ) -> any UpdateClassificationUseCase {
        DefaultUpdateClassificationUseCase(
            overrideRepository: SwiftDataOverrideRepository(modelContainer: modelContainer),
            clock: clock
        )
    }

    func makeUpdateStayOverrideUseCase(
        modelContainer: ModelContainer
    ) -> any UpdateStayOverrideUseCase {
        DefaultUpdateStayOverrideUseCase(
            overrideRepository: SwiftDataOverrideRepository(modelContainer: modelContainer),
            clock: clock
        )
    }

    func makeMediaPreviewViewModel(
        asset: MediaAssetReference,
        photoLibrary: any PhotoLibraryProviding = PhotoLibraryProvider()
    ) -> MediaPreviewViewModel {
        MediaPreviewViewModel(
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

    // swiftlint:disable:next function_body_length
    func makeAppLifecycleCoordinator(
        modelContainer: ModelContainer,
        permissionManager: any PermissionManaging
    ) -> AppLifecycleCoordinator {
        let rawRepository = SwiftDataRawEventRepository(
            modelContainer: modelContainer,
            clock: clock
        )
        let stateRepository = SwiftDataProcessingStateRepository(
            modelContainer: modelContainer,
            clock: clock
        )
        let overrideRepository = SwiftDataOverrideRepository(modelContainer: modelContainer)
        let derivedRepository = SwiftDataDerivedDataRepository(modelContainer: modelContainer)
        let mediaCacheRepository = SwiftDataMediaCacheRepository(modelContainer: modelContainer)
        let providers = makeMonitoringProviders()
        let powerStateProvider = SystemPowerStateProvider()
        let storageCoordinator = RawEventStorageCoordinator(
            locationProvider: providers.location,
            motionProvider: providers.motion,
            visitProvider: providers.visit,
            repository: rawRepository,
            logger: logger
        )
        let startMonitoring = StartMonitoringUseCase(
            locationProvider: providers.location,
            motionProvider: providers.motion,
            visitProvider: providers.visit,
            storageCoordinator: storageCoordinator,
            powerStateProvider: powerStateProvider,
            logger: logger
        )
        let processDay = makeProcessDayUseCase(
            stateRepository: stateRepository,
            rawRepository: rawRepository,
            overrideRepository: overrideRepository,
            derivedRepository: derivedRepository,
            mediaCacheRepository: mediaCacheRepository
        )
        let dayProcessing = DefaultDayProcessingCoordinator(
            stateRepository: stateRepository,
            processDayUseCase: processDay
        )
        let backgroundCoordinator = BackgroundTaskCoordinator(
            dayProcessingCoordinator: dayProcessing
        )
        let backgroundScheduler = SystemBackgroundTaskScheduler { task in
            backgroundCoordinator.handle(task: task)
        }
        return AppLifecycleCoordinator(
            permissionManager: permissionManager,
            startMonitoringUseCase: startMonitoring,
            dayProcessingCoordinator: dayProcessing,
            backgroundTaskScheduler: backgroundScheduler
        )
    }

    private func makeMonitoringProviders() -> MonitoringProviders {
        MonitoringProviders(
            location: CoreLocationProvider(
                clock: clock,
                localTimeContextProvider: localTimeContextProvider
            ),
            motion: CoreMotionProvider(localTimeContextProvider: localTimeContextProvider),
            visit: CoreLocationVisitProvider(
                clock: clock,
                localTimeContextProvider: localTimeContextProvider
            )
        )
    }

    private func makeProcessDayUseCase(
        stateRepository: SwiftDataProcessingStateRepository,
        rawRepository: SwiftDataRawEventRepository,
        overrideRepository: SwiftDataOverrideRepository,
        derivedRepository: SwiftDataDerivedDataRepository,
        mediaCacheRepository: SwiftDataMediaCacheRepository
    ) -> DefaultProcessDayUseCase {
        DefaultProcessDayUseCase(
            stateRepository: stateRepository,
            rawRepository: rawRepository,
            overrideRepository: overrideRepository,
            derivedRepository: derivedRepository,
            processor: DefaultDayProcessor(clock: clock),
            mediaCountLoader: { localDateKey in
                try await mediaCacheRepository.cachedAssets(for: localDateKey).count
            },
            clock: clock,
            logger: logger
        )
    }
}

private struct MonitoringProviders {
    let location: CoreLocationProvider
    let motion: CoreMotionProvider
    let visit: CoreLocationVisitProvider
}
