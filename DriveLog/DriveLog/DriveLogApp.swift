import AVFoundation
import SwiftData
import SwiftUI
import UIKit

@main
struct DriveLogApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingFlowUITestCompleted = false
    private let calendarViewModel: CalendarViewModel?
    private let appContainer: AppContainer
    private let today: Date
    private let modelContainer: ModelContainer?
    private let photoLibrary: any PhotoLibraryProviding
    private let permissionManager: any PermissionManaging
    private let runsOnboardingFlowUITest: Bool
    private let lifecycleCoordinator: AppLifecycleCoordinator?

    @MainActor
    init() {
        let container = AppContainer()
        appContainer = container
        let now = container.clock.now
        today = now
        #if DEBUG
            let uiTest = Self.makeUITestConfiguration(
                now: now,
                timeZone: container.timeZoneProvider.current
            )
            runsOnboardingFlowUITest = uiTest.runsOnboardingFlow
            permissionManager = uiTest.permissionManager
            photoLibrary = uiTest.photoLibrary
            let isSeededUITesting = uiTest.isSeeded
            let isUITesting = uiTest.isEnabled
        #else
            runsOnboardingFlowUITest = false
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
                        calendar: calendar
                    )
                }
            #endif
            self.modelContainer = modelContainer
            lifecycleCoordinator = isUITesting ? nil : container.makeAppLifecycleCoordinator(
                modelContainer: modelContainer,
                permissionManager: permissionManager
            )
            calendarViewModel = container.makeCalendarViewModel(
                modelContainer: modelContainer,
                displayedMonth: month
            )
        } catch {
            modelContainer = nil
            calendarViewModel = nil
            lifecycleCoordinator = nil
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
                } else if let calendarViewModel, let modelContainer {
                    ContentView(
                        calendarViewModel: calendarViewModel,
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
                } else {
                    ContentUnavailableView(
                        "起動できませんでした",
                        systemImage: "exclamationmark.triangle",
                        description: Text("アプリを終了して、もう一度お試しください")
                    )
                    .accessibilityIdentifier("app.startup.error")
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

    #if DEBUG
        @MainActor
        private static func makeUITestConfiguration(
            now: Date,
            timeZone: TimeZone
        ) -> UITestConfiguration {
            let arguments = ProcessInfo.processInfo.arguments
            let runsOnboardingFlow = arguments.contains("-ui-testing-onboarding-flow")
            let isMedia = arguments.contains("-ui-testing-media")
            let isSeeded = isMedia || arguments.contains("-ui-testing-day-detail")
            let isEnabled = isSeeded
                || arguments.contains("-ui-testing-calendar")
                || runsOnboardingFlow
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
                isEnabled: isEnabled
            )
        }

        @MainActor
        private static func seedUITestData(
            modelContainer: ModelContainer,
            now: Date,
            calendar: Calendar
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
            try context.save()
        }

        @MainActor
        private static func seedSummary(
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

        @MainActor
        private static func seedRoute(
            context: ModelContext,
            localDateKey: String,
            startDate: Date,
            now: Date
        ) throws {
            let route = try PropertyListRouteEncoder().encode([
                RouteCoordinate(latitude: 35.680, longitude: 139.760),
                RouteCoordinate(latitude: 35.690, longitude: 139.780),
                RouteCoordinate(latitude: 35.700, longitude: 139.800)
            ])
            context.insert(
                MovementSegmentModel(
                    stableID: "ui-movement",
                    localDateKey: localDateKey,
                    startDate: startDate,
                    endDate: now,
                    distanceMeters: 5200,
                    durationSeconds: 3600,
                    estimatedAverageSpeedMetersPerSecond: 5200 / 3600,
                    automaticClassificationRawValue: "automotiveLike",
                    classificationConfidenceRawValue: "high",
                    encodedRouteData: route,
                    labelLatitude: 35.690,
                    labelLongitude: 139.780,
                    sourceRawRevision: 1,
                    generatedAt: now
                )
            )
            context.insert(
                StaySegmentModel(
                    stableID: "ui-stay",
                    localDateKey: localDateKey,
                    representativeLatitude: 35.700,
                    representativeLongitude: 139.800,
                    estimatedArrivalDate: now.addingTimeInterval(-900),
                    estimatedDepartureDate: now.addingTimeInterval(-300),
                    durationSeconds: 600,
                    confidenceRawValue: "high",
                    sourceRawValue: "combined",
                    isVisibleByAutomaticRule: true,
                    sourceRawRevision: 1,
                    generatedAt: now
                )
            )
        }
    #endif
}

#if DEBUG
    private struct UITestConfiguration {
        let permissionManager: any PermissionManaging
        let photoLibrary: any PhotoLibraryProviding
        let runsOnboardingFlow: Bool
        let isSeeded: Bool
        let isEnabled: Bool
    }
#endif

private extension DriveLogApp {
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
            if bypassesOnboarding {
                return false
            }
        #endif
        return !hasCompletedOnboarding
    }

    static func makeModelContainer(isUITesting: Bool) throws -> ModelContainer {
        try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: isUITesting)
    }
}

#if DEBUG
    private final class UITestPhotoLibraryProvider: PhotoLibraryProviding, @unchecked Sendable {
        let libraryChanges = AsyncStream<PhotoLibraryChange> { $0.finish() }
        private let assets: [MediaAssetReference]
        private let thumbnailImage: UIImage

        init(now: Date, timeZone: TimeZone) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            let start = calendar.startOfDay(for: now)
            assets = [
                MediaAssetReference(
                    localIdentifier: "ui-photo",
                    mediaType: .photo,
                    creationDate: start.addingTimeInterval(3600),
                    location: RouteCoordinate(latitude: 35.690, longitude: 139.780),
                    durationSeconds: nil,
                    isScreenshot: false,
                    isScreenRecording: false
                ),
                MediaAssetReference(
                    localIdentifier: "ui-video",
                    mediaType: .video,
                    creationDate: start.addingTimeInterval(7200),
                    location: RouteCoordinate(latitude: 35.690_05, longitude: 139.780_05),
                    durationSeconds: 10,
                    isScreenshot: false,
                    isScreenRecording: false
                ),
                MediaAssetReference(
                    localIdentifier: "ui-unavailable",
                    mediaType: .photo,
                    creationDate: start.addingTimeInterval(10800),
                    location: nil,
                    durationSeconds: nil,
                    isScreenshot: false,
                    isScreenRecording: false
                )
            ]
            thumbnailImage = UIImage(systemName: "car.fill") ?? UIImage()
        }

        func authorizationState() async -> PhotoPermissionState {
            .authorized
        }

        func fetchAssets(in interval: DateInterval) async throws -> [MediaAssetReference] {
            assets.filter { asset in
                guard let creationDate = asset.creationDate else { return false }
                return interval.contains(creationDate)
            }
        }

        func requestThumbnail(localIdentifier: String, targetSize _: CGSize) async throws -> UIImage {
            guard localIdentifier != "ui-unavailable" else {
                throw DriveLogError.mediaUnavailable
            }
            return thumbnailImage
        }

        func requestPhotoPreview(localIdentifier: String) async throws -> UIImage {
            guard localIdentifier == "ui-photo" else { throw DriveLogError.mediaUnavailable }
            return thumbnailImage
        }

        func requestVideoAsset(localIdentifier: String) async throws -> AVAsset {
            guard localIdentifier == "ui-video" else { throw DriveLogError.mediaUnavailable }
            return AVURLAsset(url: URL(fileURLWithPath: "/tmp/drivelog-ui-video.mov"))
        }

        func requestShareableResource(localIdentifier: String) async throws -> ShareableMediaResource {
            guard let asset = assets.first(where: { $0.localIdentifier == localIdentifier }) else {
                throw DriveLogError.mediaUnavailable
            }
            let mediaType = asset.mediaType
            return ShareableMediaResource(
                fileURL: URL(fileURLWithPath: "/tmp/drivelog-ui-share"),
                mediaType: mediaType
            )
        }
    }
#endif
