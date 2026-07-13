@testable import DriveLog
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
    }

    @Test("foreground retries monitoring after a launch failure")
    func retry() async {
        let fixture = Fixture()
        await fixture.location.setStartError(.permissionDenied(.location))

        await fixture.coordinator.handleLaunch()
        #expect(await fixture.location.callCounts().start == 1)
        #expect(await fixture.motion.callCounts().start == 0)
        #expect(await fixture.visit.callCounts().start == 0)

        await fixture.location.setStartError(nil)
        await fixture.coordinator.handleForeground()

        #expect(fixture.permissionManager.refreshCount == 2)
        #expect(await fixture.location.callCounts().start == 2)
        #expect(await fixture.motion.callCounts().start == 1)
        #expect(await fixture.visit.callCounts().start == 1)
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
    let storageCoordinator: RawEventStorageCoordinator
    let coordinator: AppLifecycleCoordinator

    init() {
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
            )
        )
    }
}
