@testable import DriveLog
import Testing

@Suite("Start monitoring use case")
@MainActor
struct StartMonitoringUseCaseTests {
    @Test("starts storage and all providers once")
    func startsAllProviders() async throws {
        let fixture = Fixture()
        try await fixture.useCase.execute()

        #expect(await fixture.storageCoordinator.isRunning())
        #expect(fixture.location.callCounts().start == 1)
        #expect(fixture.motion.callCounts().start == 1)
        #expect(fixture.visit.callCounts().start == 1)
        #expect(fixture.logger.records == [TestLogRecord(level: .info, event: .locationMonitoringStarted)])

        try await fixture.useCase.execute()
        #expect(fixture.location.callCounts().start == 1)
        #expect(fixture.motion.callCounts().start == 1)
        #expect(fixture.visit.callCounts().start == 1)
    }

    @Test("motion denial does not stop location or visit")
    func motionFailureIsolation() async throws {
        let fixture = Fixture()
        fixture.motion.setStartError(.permissionDenied(.motion))

        try await fixture.useCase.execute()

        #expect(await fixture.location.monitoringState == .running)
        #expect(await fixture.motion.monitoringState == .stopped)
        #expect(await fixture.visit.monitoringState == .running)
    }

    @Test("visit failure does not stop location or motion")
    func visitFailureIsolation() async throws {
        let fixture = Fixture()
        fixture.visit.setStartError(.monitoringUnavailable)

        try await fixture.useCase.execute()

        #expect(await fixture.location.monitoringState == .running)
        #expect(await fixture.motion.monitoringState == .running)
        #expect(await fixture.visit.monitoringState == .stopped)
    }

    @Test("location failure stops initial storage subscription and skips auxiliaries")
    func locationFailure() async {
        let fixture = Fixture()
        fixture.location.setStartError(.permissionDenied(.location))

        await #expect(throws: DriveLogError.permissionDenied(.location)) {
            try await fixture.useCase.execute()
        }
        #expect(await !fixture.storageCoordinator.isRunning())
        #expect(fixture.motion.callCounts().start == 0)
        #expect(fixture.visit.callCounts().start == 0)
        #expect(fixture.logger.records.isEmpty)
    }

    @Test("already active providers are not started again")
    func activeProviders() async throws {
        let fixture = Fixture(
            locationState: .running, motionState: .starting, visitState: .running
        )

        try await fixture.useCase.execute()

        #expect(fixture.location.callCounts().start == 0)
        #expect(fixture.motion.callCounts().start == 0)
        #expect(fixture.visit.callCounts().start == 0)
        #expect(fixture.logger.records.isEmpty)
        #expect(await fixture.storageCoordinator.isRunning())
    }
}

@MainActor
private struct Fixture {
    let location: FakeLocationProvider
    let motion: FakeMotionProvider
    let visit: FakeVisitProvider
    let repository = InMemoryRawEventRepository()
    let logger = SpyEventLogger()
    let storageCoordinator: RawEventStorageCoordinator
    let useCase: StartMonitoringUseCase

    init(
        locationState: LocationMonitoringState = .stopped,
        motionState: MotionMonitoringState = .stopped,
        visitState: VisitMonitoringState = .stopped
    ) {
        location = FakeLocationProvider(state: locationState)
        motion = FakeMotionProvider(state: motionState)
        visit = FakeVisitProvider(state: visitState)
        storageCoordinator = RawEventStorageCoordinator(
            locationProvider: location, motionProvider: motion, visitProvider: visit,
            repository: repository, logger: logger
        )
        useCase = StartMonitoringUseCase(
            locationProvider: location, motionProvider: motion, visitProvider: visit,
            storageCoordinator: storageCoordinator, logger: logger
        )
    }
}
