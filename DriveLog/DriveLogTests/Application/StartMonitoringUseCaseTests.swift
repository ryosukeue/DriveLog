@testable import DriveLog
import Foundation
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
        #expect(fixture.logger.records == [
            TestLogRecord(
                level: .info,
                event: .powerStateObserved(stateCode: "unplugged")
            ),
            TestLogRecord(level: .info, event: .locationMonitoringStarted),
            TestLogRecord(
                level: .info,
                event: .locationRecordingModeChanged(modeCode: "lowPower")
            )
        ])

        try await fixture.useCase.execute()
        #expect(fixture.location.callCounts().start == 1)
        #expect(fixture.motion.callCounts().start == 1)
        #expect(fixture.visit.callCounts().start == 1)
    }

    @Test("manual start switches the existing provider to high density")
    func manualHighDensityStart() async throws {
        let fixture = Fixture()
        try await fixture.useCase.execute()

        try await fixture.useCase.startHighDensityRecording()

        #expect(fixture.location.appliedModes() == [.lowPower, .automotiveHighAccuracy])
        fixture.power.send(.charging)
        fixture.motion.send(.motion(motion(stationary: true)))
        await Task.yield()
        #expect(fixture.location.appliedModes().last == .automotiveHighAccuracy)
        #expect(fixture.location.callCounts().start == 2)
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
        #expect(fixture.logger.records == [
            TestLogRecord(
                level: .info,
                event: .powerStateObserved(stateCode: "unplugged")
            )
        ])
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
        #expect(fixture.logger.records == [
            TestLogRecord(
                level: .info,
                event: .powerStateObserved(stateCode: "unplugged")
            )
        ])
        #expect(await fixture.storageCoordinator.isRunning())
    }

    @Test("charging alone does not start high accuracy tracking")
    func chargingTransitions() async throws {
        let fixture = Fixture()
        try await fixture.useCase.execute()

        fixture.power.send(.charging)
        await Task.yield()

        #expect(fixture.location.appliedModes() == [.lowPower])
    }

    @Test("automotive activity requires two location confirmations")
    func automotiveActivityTransitions() async throws {
        let fixture = Fixture(vehicleStopGracePeriod: .milliseconds(10))
        try await fixture.useCase.execute()

        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil { fixture.location.appliedModes().count == 2 }
        #expect(fixture.location.appliedModes() == [.lowPower, .automotiveCandidate])

        fixture.location.send(.location(location(speed: 4)))
        await Task.yield()
        #expect(fixture.location.appliedModes() == [.lowPower, .automotiveCandidate])
        fixture.location.send(.location(location(
            latitude: 35.001,
            timestamp: Date(timeIntervalSince1970: 1_704_067_210),
            speed: 4
        )))
        await waitUntil { fixture.location.appliedModes().count == 3 }
        #expect(fixture.location.appliedModes().last == .automotiveHighAccuracy)

        fixture.motion.send(.motion(motion(stationary: true)))
        try? await Task.sleep(for: .milliseconds(30))
        await waitUntil { fixture.location.appliedModes().count == 4 }
        #expect(fixture.location.appliedModes().last == .lowPower)
    }

    @Test("charging assists only after movement is confirmed")
    func chargingAssistsConfirmedDriving() async throws {
        let fixture = Fixture(powerState: .charging)
        try await fixture.useCase.execute()

        #expect(fixture.location.appliedModes() == [.lowPower])
        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil { fixture.location.appliedModes().count == 2 }
        fixture.location.send(.location(location(speed: 4)))
        fixture.location.send(.location(location(
            latitude: 35.001,
            timestamp: Date(timeIntervalSince1970: 1_704_067_210),
            speed: 4
        )))
        await waitUntil { fixture.location.appliedModes().count == 3 }

        #expect(fixture.location.appliedModes().last == .chargingHighAccuracy)
    }

    @Test("candidate timeout returns to low power")
    func candidateTimeout() async throws {
        let fixture = Fixture(vehicleCandidateTimeout: .milliseconds(10))
        try await fixture.useCase.execute()

        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil { fixture.location.appliedModes().count == 2 }
        try? await Task.sleep(for: .milliseconds(30))
        await waitUntil { fixture.location.appliedModes().count == 3 }

        #expect(fixture.location.appliedModes() == [.lowPower, .automotiveCandidate, .lowPower])
    }

    @Test("logs an observed candidate mode transition failure")
    func candidateTransitionFailure() async throws {
        let fixture = Fixture()
        try await fixture.useCase.execute()
        fixture.location.setStartError(.monitoringUnavailable)

        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil {
            fixture.logger.records.contains {
                $0.event == .locationRecordingModeChangeFailed(
                    modeCode: "automotiveCandidate", reasonCode: "monitoring_unavailable"
                )
            }
        }

        #expect(fixture.logger.records.last == TestLogRecord(
            level: .error,
            event: .locationRecordingModeChangeFailed(
                modeCode: "automotiveCandidate", reasonCode: "monitoring_unavailable"
            )
        ))
    }

    @Test("retries a failed candidate transition on the next activity snapshot")
    func candidateTransitionRetry() async throws {
        let fixture = Fixture()
        try await fixture.useCase.execute()
        fixture.location.setStartError(.monitoringUnavailable)

        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil { fixture.location.appliedModes().count == 2 }
        fixture.motion.send(.motion(motion(automotive: true)))
        await waitUntil { fixture.location.appliedModes().count == 3 }

        let failures = fixture.logger.records.filter {
            $0.event == .locationRecordingModeChangeFailed(
                modeCode: "automotiveCandidate", reasonCode: "monitoring_unavailable"
            )
        }
        #expect(failures.count == 1)

        fixture.location.setStartError(nil)
        fixture.motion.send(.motion(motion(automotive: true)))
        let successfulTransition = TestLogRecord(
            level: .info,
            event: .locationRecordingModeChanged(modeCode: "automotiveCandidate")
        )
        await waitUntil { fixture.logger.records.last == successfulTransition }

        #expect(fixture.location.appliedModes() == [
            .lowPower,
            .automotiveCandidate,
            .automotiveCandidate,
            .automotiveCandidate
        ])
        #expect(fixture.logger.records.last == successfulTransition)
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
    }

    private func motion(
        automotive: Bool = false,
        stationary: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: Date(timeIntervalSince1970: 1_704_067_200), endDate: nil,
            isAutomotive: automotive, isWalking: false, isRunning: false,
            isCycling: false, isStationary: stationary, isUnknown: false,
            confidence: .high, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: "2024-01-01"
        )
    }

    private func location(
        latitude: Double = 35,
        longitude: Double = 139,
        timestamp: Date = Date(timeIntervalSince1970: 1_704_067_200),
        speed: Double? = nil
    ) -> LocationEventData {
        LocationEventData(
            latitude: latitude, longitude: longitude, timestamp: timestamp,
            horizontalAccuracy: 50, speedMetersPerSecond: speed,
            createdAt: timestamp, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: "2024-01-01"
        )
    }
}

@MainActor
private struct Fixture {
    let location: FakeLocationProvider
    let motion: FakeMotionProvider
    let visit: FakeVisitProvider
    let repository = InMemoryRawEventRepository()
    let logger = SpyEventLogger()
    let power: FakePowerStateProvider
    let storageCoordinator: RawEventStorageCoordinator
    let useCase: StartMonitoringUseCase

    init(
        locationState: LocationMonitoringState = .stopped,
        motionState: MotionMonitoringState = .stopped,
        visitState: VisitMonitoringState = .stopped,
        powerState: PowerState = .unplugged,
        vehicleStopGracePeriod: Duration = .seconds(180),
        vehicleCandidateTimeout: Duration = .seconds(90)
    ) {
        location = FakeLocationProvider(state: locationState)
        motion = FakeMotionProvider(state: motionState)
        visit = FakeVisitProvider(state: visitState)
        power = FakePowerStateProvider(current: powerState)
        storageCoordinator = RawEventStorageCoordinator(
            locationProvider: location, motionProvider: motion, visitProvider: visit,
            repository: repository, logger: logger
        )
        useCase = StartMonitoringUseCase(
            locationProvider: location, motionProvider: motion, visitProvider: visit,
            storageCoordinator: storageCoordinator, powerStateProvider: power, logger: logger,
            vehicleStopGracePeriod: vehicleStopGracePeriod,
            vehicleCandidateTimeout: vehicleCandidateTimeout
        )
    }
}
