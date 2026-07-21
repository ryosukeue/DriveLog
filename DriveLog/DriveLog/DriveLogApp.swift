import SwiftData
import SwiftUI

@main
struct DriveLogApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingFlowUITestCompleted = false
    @State private var hasOpenedRecords = false
    private let calendarViewModel: CalendarViewModel?
    private let monthlySummaryViewModel: MonthlySummaryViewModel?
    private let monthlyOverviewViewModel: MonthlyOverviewViewModel?
    private let appContainer: AppContainer
    private let today: Date
    private let modelContainer: ModelContainer?
    private let photoLibrary: any PhotoLibraryProviding
    private let permissionManager: any PermissionManaging
    private let recordingStarter: (any RecordingStarting)?
    private let runsOnboardingFlowUITest: Bool
    private let isUITesting: Bool
    private let lifecycleCoordinator: AppLifecycleCoordinator?

    @MainActor
    // swiftlint:disable:next function_body_length
    init() {
        let container = AppContainer()
        appContainer = container
        let now = Self.referenceDate(for: container)
        today = now
        #if DEBUG
            let uiTest = Self.makeUITestConfiguration(now: now, timeZone: container.timeZoneProvider.current)
            runsOnboardingFlowUITest = uiTest.runsOnboardingFlow
            permissionManager = uiTest.permissionManager
            photoLibrary = uiTest.photoLibrary
            let isSeededUITesting = uiTest.isSeeded
            let isUITesting = uiTest.isEnabled
            self.isUITesting = isUITesting
        #else
            runsOnboardingFlowUITest = false
            isUITesting = false
            permissionManager = PermissionCoordinator()
            let isUITesting = false
            photoLibrary = PhotoLibraryProvider()
        #endif
        do {
            let modelContainer = try Self.makeModelContainer(isUITesting: isUITesting)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = container.timeZoneProvider.current
            let components = calendar.dateComponents([.year, .month], from: now)
            let month = LocalMonth(year: components.year ?? 1970, month: components.month ?? 1)
            #if DEBUG
                if isSeededUITesting {
                    try Self.seedUITestData(
                        modelContainer: modelContainer,
                        now: now,
                        calendar: calendar,
                        usesDenseMapFixture: uiTest.usesDenseMapFixture
                    )
                }
            #endif
            self.modelContainer = modelContainer
            if isUITesting {
                lifecycleCoordinator = nil
                recordingStarter = uiTest.recordingStarter
            } else {
                lifecycleCoordinator = container.makeAppLifecycleCoordinator(
                    modelContainer: modelContainer,
                    permissionManager: permissionManager
                )
                recordingStarter = container.recordingStarter
            }
            calendarViewModel = container.makeCalendarViewModel(modelContainer: modelContainer, displayedMonth: month)
            monthlySummaryViewModel = container.makeMonthlySummaryViewModel(modelContainer: modelContainer)
            monthlyOverviewViewModel = container.makeMonthlyOverviewViewModel(modelContainer: modelContainer)
        } catch {
            modelContainer = nil
            calendarViewModel = nil
            monthlySummaryViewModel = nil
            monthlyOverviewViewModel = nil
            lifecycleCoordinator = nil
            recordingStarter = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if shouldShowOnboarding {
                    OnboardingView(
                        viewModel: OnboardingViewModel(permissionManager: permissionManager),
                        onCompleted: {
                            hasCompletedOnboarding = true
                            onboardingFlowUITestCompleted = true
                        }
                    )
                } else if shouldShowRecordingStart, let recordingStarter {
                    RecordingStartView(
                        viewModel: RecordingStartViewModel(
                            startRecording: recordingStarter
                        ),
                        onBrowseRecords: {
                            hasOpenedRecords = true
                        }
                    )
                } else {
                    switch (calendarViewModel, monthlySummaryViewModel, monthlyOverviewViewModel, modelContainer) {
                    case let (
                        .some(calendarViewModel),
                        .some(monthlySummaryViewModel),
                        .some(monthlyOverviewViewModel),
                        .some(modelContainer)
                    ):
                        ContentView(
                            calendarViewModel: calendarViewModel,
                            monthlySummaryViewModel: monthlySummaryViewModel,
                            monthlyOverviewViewModel: monthlyOverviewViewModel,
                            today: today,
                            makeDayDetailViewModel: { localDateKey in
                                appContainer.makeDayDetailViewModel(
                                    modelContainer: modelContainer,
                                    localDateKey: localDateKey,
                                    photoLibrary: photoLibrary
                                )
                            },
                            loadMediaThumbnail: appContainer.makeLoadMediaThumbnailUseCase(
                                photoLibrary: photoLibrary
                            ),
                            updateStayOverride: appContainer.makeUpdateStayOverrideUseCase(
                                modelContainer: modelContainer
                            ),
                            hapticFeedback: appContainer.hapticFeedback,
                            makeMediaPreviewViewModel: { asset in
                                appContainer.makeMediaPreviewViewModel(
                                    asset: asset,
                                    photoLibrary: photoLibrary
                                )
                            }
                        )
                    default:
                        ContentUnavailableView(
                            "起動できませんでした",
                            systemImage: "exclamationmark.triangle",
                            description: Text("アプリを終了して、もう一度お試しください")
                        )
                        .accessibilityIdentifier("app.startup.error")
                    }
                }
            }
            .task {
                await lifecycleCoordinator?.handleLaunch()
            }
            .onChange(of: scenePhase) { _, phase in
                Task { @MainActor in
                    switch phase {
                    case .active:
                        await lifecycleCoordinator?.handleForeground()
                    case .background:
                        await lifecycleCoordinator?.handleBackground()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
    }
}

#if DEBUG
    private extension DriveLogApp {
        @MainActor
        static func makeUITestConfiguration(
            now: Date,
            timeZone: TimeZone
        ) -> UITestConfiguration {
            let arguments = ProcessInfo.processInfo.arguments
            let runsOnboardingFlow = arguments.contains("-ui-testing-onboarding-flow")
            let usesDenseMapFixture = arguments.contains("-ui-testing-july-17-map")
            let runsRecordingStartFlow = arguments.contains("-ui-testing-recording-start")
            let isMedia = arguments.contains("-ui-testing-media") || usesDenseMapFixture
            let isSeeded = isMedia
                || arguments.contains("-ui-testing-day-detail")
                || usesDenseMapFixture
            let isEnabled = isSeeded
                || arguments.contains("-ui-testing-calendar")
                || runsOnboardingFlow
                || runsRecordingStartFlow
            let permissionManager: any PermissionManaging = runsOnboardingFlow
                ? UITestPermissionManager() : PermissionCoordinator()
            let photoLibrary: any PhotoLibraryProviding = isMedia
                ? UITestPhotoLibraryProvider(now: now, timeZone: timeZone)
                : PhotoLibraryProvider()
            return UITestConfiguration(
                permissionManager: permissionManager,
                photoLibrary: photoLibrary,
                runsOnboardingFlow: runsOnboardingFlow,
                isSeeded: isSeeded,
                isEnabled: isEnabled,
                usesDenseMapFixture: usesDenseMapFixture,
                recordingStarter: runsRecordingStartFlow || runsOnboardingFlow
                    ? UITestRecordingStarter() : nil
            )
        }

        @MainActor
        static func seedUITestData(
            modelContainer: ModelContainer,
            now: Date,
            calendar: Calendar,
            usesDenseMapFixture: Bool
        ) throws {
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            guard let year = components.year,
                  let month = components.month,
                  let day = components.day
            else { throw DriveLogError.invalidData }
            let localDateKey = String(format: "%04d-%02d-%02d", year, month, day)
            let startDate = now.addingTimeInterval(-3600)
            let context = ModelContext(modelContainer)
            seedSummary(context: context, localDateKey: localDateKey, startDate: startDate, now: now)
            try seedRoute(context: context, localDateKey: localDateKey, startDate: startDate, now: now)
            if usesDenseMapFixture {
                try seedDenseMapExtras(
                    context: context,
                    localDateKey: localDateKey,
                    startDate: startDate,
                    now: now
                )
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: now) else {
                throw DriveLogError.invalidData
            }
            let nextComponents = calendar.dateComponents([.year, .month, .day], from: nextDate)
            guard let nextYear = nextComponents.year,
                  let nextMonth = nextComponents.month,
                  let nextDay = nextComponents.day
            else { throw DriveLogError.invalidData }
            let nextLocalDateKey = String(
                format: "%04d-%02d-%02d",
                nextYear,
                nextMonth,
                nextDay
            )
            seedSummary(
                context: context,
                localDateKey: nextLocalDateKey,
                startDate: nextDate.addingTimeInterval(-1800),
                now: nextDate
            )
            try context.save()
        }

        @MainActor
        static func seedSummary(
            context: ModelContext,
            localDateKey: String,
            startDate: Date,
            now: Date
        ) {
            context.insert(DayAggregateModel(
                localDateKey: localDateKey, totalDistanceMeters: 5200,
                totalMovementDurationSeconds: 3600, startDate: startDate, endDate: now,
                locationRecordCount: 120, rejectedLocationCount: 3, mediaCountCache: 0,
                automaticClassificationRawValue: "automotiveLike", hasValidMovement: true,
                movementSegmentCount: 2, staySegmentCount: 1, totalStayDurationSeconds: 600,
                automotiveDurationSeconds: 3000, walkingDurationSeconds: 600,
                sourceRawRevision: 1, generatedAt: now
            ))
            context.insert(DayProcessingStateModel(
                localDateKey: localDateKey, rawRevision: 1, processedRevision: 1,
                statusRawValue: "completed", lastAttemptDate: now, lastSuccessfulDate: now,
                lastErrorCode: nil, updatedAt: now
            ))
        }
    }
#endif

#if DEBUG
    private struct UITestConfiguration {
        let permissionManager: any PermissionManaging
        let photoLibrary: any PhotoLibraryProviding
        let runsOnboardingFlow: Bool
        let isSeeded: Bool
        let isEnabled: Bool
        let usesDenseMapFixture: Bool
        let recordingStarter: (any RecordingStarting)?
    }

    private struct UITestRecordingStarter: RecordingStarting {
        func startHighDensityRecording() async throws {}
    }
#endif

private extension DriveLogApp {
    @MainActor
    static func referenceDate(for container: AppContainer) -> Date {
        let current = container.clock.now
        #if DEBUG
            return uiTestReferenceDate(
                defaultValue: current,
                timeZone: container.timeZoneProvider.current
            )
        #else
            return current
        #endif
    }

    var shouldShowOnboarding: Bool {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-ui-testing-onboarding") {
                return true
            }
            if runsOnboardingFlowUITest {
                return !onboardingFlowUITestCompleted
            }
            let bypassesOnboarding = arguments.contains("-ui-testing-day-detail")
                || arguments.contains("-ui-testing-media")
                || arguments.contains("-ui-testing-calendar")
                || arguments.contains("-ui-testing-july-17-map")
            if bypassesOnboarding {
                return false
            }
        #endif
        return !hasCompletedOnboarding
    }

    var shouldShowRecordingStart: Bool {
        #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-ui-testing-recording-start") || runsOnboardingFlowUITest {
                return !shouldShowOnboarding && !hasOpenedRecords
            }
        #endif
        return !isUITesting && !hasOpenedRecords
    }

    static func makeModelContainer(isUITesting: Bool) throws -> ModelContainer {
        try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: isUITesting)
    }
}
