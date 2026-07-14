@testable import DriveLog
import os
import Testing

@Suite("App lifecycle coordinator")
@MainActor
struct AppLifecycleCoordinatorTests {
    @Test("launch refreshes permissions and starts monitoring")
    func launch() async {
        let fixture = Fixture()

        await fixture.coordinator.handleLaunch()

        #expect(fixture.permissionManager.refreshCount == 1)
        #expect(await fixture.location.callCounts().start == 1)
        #expect(await fixture.motion.callCounts().start == 1)
        #expect(await fixture.visit.callCounts().start == 1)
        #expect(fixture.dayProcessing.pendingLimits == [1])
        #expect(fixture.backgroundTasks.registrationCount == 1)
        #expect(fixture.backgroundTasks.requirements.isEmpty)
    }

    @Test("foreground refreshes permissions and rechecks active monitoring")
    func foreground() async {
        let fixture = Fixture()
        await fixture.coordinator.handleLaunch()

        await fixture.coordinator.handleForeground()

        #expect(fixture.permissionManager.refreshCount == 2)
        #expect(await fixture.location.callCounts().start == 1)
        #expect(await fixture.motion.callCounts().start == 1)
        #expect(await fixture.visit.callCounts().start == 1)
        #expect(fixture.dayProcessing.pendingLimits == [1, 1])
        #expect(fixture.backgroundTasks.registrationCount == 1)
    }

    @Test("foreground retries monitoring after a launch failure")
    func retry() async {
        let fixture = Fixture()
        await fixture.location.setStartError(.permissionDenied(.location))

        await fixture.coordinator.handleLaunch()
        #expect(await fixture.location.callCounts().start == 1)
        #expect(await fixture.motion.callCounts().start == 0)
        #expect(await fixture.visit.callCounts().start == 0)
        #expect(fixture.dayProcessing.pendingLimits == [1])

        await fixture.location.setStartError(nil)
        await fixture.coordinator.handleForeground()

        #expect(fixture.permissionManager.refreshCount == 2)
        #expect(await fixture.location.callCounts().start == 2)
        #expect(await fixture.motion.callCounts().start == 1)
        #expect(await fixture.visit.callCounts().start == 1)
        #expect(fixture.dayProcessing.pendingLimits == [1, 1])
    }

    @Test("background keeps all monitoring active")
    func background() async {
        let fixture = Fixture()
        await fixture.coordinator.handleLaunch()

        await fixture.coordinator.handleBackground()

        #expect(await fixture.location.callCounts().stop == 0)
        #expect(await fixture.motion.callCounts().stop == 0)
        #expect(await fixture.visit.callCounts().stop == 0)
        #expect(await fixture.storageCoordinator.isRunning())
        #expect(fixture.dayProcessing.pendingLimits == [1])
        #expect(fixture.dayProcessing.cancelCount == 0)
        #expect(fixture.backgroundTasks.requirements == [false])
    }

    @Test("scheduler failures keep foreground fallback and monitoring active")
    func schedulerFailures() async {
        let fixture = Fixture(backgroundTaskError: .backgroundTaskUnavailable)

        await fixture.coordinator.handleLaunch()
        await fixture.coordinator.handleBackground()

        #expect(fixture.permissionManager.refreshCount == 1)
        #expect(await fixture.location.callCounts().start == 1)
        #expect(fixture.dayProcessing.pendingLimits == [1])
        #expect(fixture.backgroundTasks.registrationCount == 1)
        #expect(fixture.backgroundTasks.requirements == [false])
    }
}

@MainActor
private struct Fixture {
    let permissionManager = FakePermissionManager(
        state: PermissionState(
            location: .notDetermined,
            motion: .notDetermined,
            photos: .notDetermined
        )
    )
    let location = FakeLocationProvider()
    let motion = FakeMotionProvider()
    let visit = FakeVisitProvider()
    let dayProcessing = LifecycleProcessingCoordinatorFake()
    let backgroundTasks: LifecycleBackgroundTaskSchedulerFake
    let storageCoordinator: RawEventStorageCoordinator
    let coordinator: AppLifecycleCoordinator

    init(backgroundTaskError: DriveLogError? = nil) {
        backgroundTasks = LifecycleBackgroundTaskSchedulerFake(error: backgroundTaskError)
        let logger = SpyEventLogger()
        let storageCoordinator = RawEventStorageCoordinator(
            locationProvider: location,
            motionProvider: motion,
            visitProvider: visit,
            repository: InMemoryRawEventRepository(),
            logger: logger
        )
        self.storageCoordinator = storageCoordinator
        coordinator = AppLifecycleCoordinator(
            permissionManager: permissionManager,
            startMonitoringUseCase: StartMonitoringUseCase(
                locationProvider: location,
                motionProvider: motion,
                visitProvider: visit,
                storageCoordinator: storageCoordinator,
                logger: logger
            ),
            dayProcessingCoordinator: dayProcessing,
            backgroundTaskScheduler: backgroundTasks
        )
    }
}

private final class LifecycleBackgroundTaskSchedulerFake: BackgroundTaskScheduling, @unchecked Sendable {
    private struct State {
        var registrationCount = 0
        var requirements: [Bool] = []
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())
    private let error: DriveLogError?

    var registrationCount: Int {
        storage.withLock(\.registrationCount)
    }

    var requirements: [Bool] {
        storage.withLock(\.requirements)
    }

    init(error: DriveLogError?) {
        self.error = error
    }

    func registerProcessingTask() throws {
        storage.withLock { $0.registrationCount += 1 }
        if let error {
            throw error
        }
    }

    func scheduleProcessingTask(requiresExternalPower: Bool) throws {
        storage.withLock { $0.requirements.append(requiresExternalPower) }
        if let error {
            throw error
        }
    }

    func cancelPendingProcessingTask() {}
}

private final class LifecycleProcessingCoordinatorFake: DayProcessingCoordinating {
    private struct State {
        var pendingLimits: [Int] = []
        var cancelCount = 0
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())

    var pendingLimits: [Int] {
        storage.withLock { $0.pendingLimits }
    }

    var cancelCount: Int {
        storage.withLock { $0.cancelCount }
    }

    func processIfNeeded(localDateKey _: String, priority _: ProcessingPriority) async {}

    func processPendingDays(limit: Int) async {
        storage.withLock { $0.pendingLimits.append(limit) }
    }

    func cancelCurrentProcessing() async {
        storage.withLock { $0.cancelCount += 1 }
    }
}
