@testable import DriveLog
import Foundation
import Testing

@Suite("Raw event storage coordinator")
@MainActor
struct RawEventStorageCoordinatorTests {
    @Test("stores three provider event types and logs accepted saves")
    func savesAllEventTypes() async {
        let fixture = Fixture()
        var savedIterator = fixture.repository.savedEvents.makeAsyncIterator()
        var logIterator = fixture.logger.updates.makeAsyncIterator()
        await fixture.coordinator.start()

        await fixture.location.send(.location(location()))
        await fixture.motion.send(.motion(motion()))
        await fixture.visit.send(.visit(visit()))

        var saved: [SavedRawEventKind] = []
        var logs: [TestLogRecord] = []
        for _ in 0 ..< 3 {
            if let event = await savedIterator.next() {
                saved.append(event)
            }
            if let record = await logIterator.next() {
                logs.append(record)
            }
        }
        #expect(saved.contains(.location))
        #expect(saved.contains(.motion))
        #expect(saved.contains(.visit))
        #expect(logs.contains(TestLogRecord(level: .info, event: .locationEventSaved(localDateKey: Self.key))))
        #expect(logs.contains(TestLogRecord(level: .info, event: .motionEventSaved(localDateKey: Self.key))))
        #expect(logs.contains(TestLogRecord(level: .info, event: .visitEventSaved(localDateKey: Self.key))))
    }

    @Test("isolates a location save failure and continues with later and other events")
    func isolatesFailure() async {
        let repository = RecordingRawEventRepository(locationFailuresRemaining: 1)
        let fixture = Fixture(repository: repository)
        var savedIterator = repository.savedEvents.makeAsyncIterator()
        var logIterator = fixture.logger.updates.makeAsyncIterator()
        await fixture.coordinator.start()

        await fixture.location.send(.location(location(timestamp: Date(timeIntervalSince1970: 100))))
        await fixture.location.send(.location(location(timestamp: Date(timeIntervalSince1970: 200))))
        await fixture.motion.send(.motion(motion()))

        var saved: [SavedRawEventKind] = []
        for _ in 0 ..< 2 {
            if let event = await savedIterator.next() {
                saved.append(event)
            }
        }
        #expect(saved.contains(.location))
        #expect(saved.contains(.motion))

        var logs: [TestLogRecord] = []
        for _ in 0 ..< 3 {
            if let record = await logIterator.next() {
                logs.append(record)
            }
        }
        let failure = TestLogRecord(
            level: .error, event: .locationEventRejected(reasonCode: "persistence_failure")
        )
        #expect(logs.contains(failure))
        #expect(logs.contains(TestLogRecord(level: .info, event: .locationEventSaved(localDateKey: Self.key))))
        #expect(logs.contains(TestLogRecord(level: .info, event: .motionEventSaved(localDateKey: Self.key))))
    }

    @Test("logs duplicate and provider error with fixed privacy-safe reason codes")
    func rejectedLocationLogging() async {
        let repository = RecordingRawEventRepository(locationResult: .duplicateIgnored)
        let fixture = Fixture(repository: repository)
        var iterator = fixture.logger.updates.makeAsyncIterator()
        await fixture.coordinator.start()

        await fixture.location.send(.location(location()))
        await fixture.location.send(.error(.monitoringUnavailable))

        let duplicate = TestLogRecord(
            level: .debug, event: .locationEventRejected(reasonCode: "duplicate")
        )
        let providerError = TestLogRecord(
            level: .error, event: .locationEventRejected(reasonCode: "provider_error")
        )
        #expect(await iterator.next() == duplicate)
        #expect(await iterator.next() == providerError)
        #expect(await fixture.coordinator.isRunning())
        await fixture.coordinator.stop()
        #expect(await !fixture.coordinator.isRunning())
        #expect(await fixture.location.callCounts().stop == 0)
    }

    private static let key = "2026-01-01"

    private func location(timestamp: Date = Date(timeIntervalSince1970: 100)) -> LocationEventData {
        LocationEventData(
            latitude: 35, longitude: 139, timestamp: timestamp,
            horizontalAccuracy: 25, speedMetersPerSecond: 2, createdAt: timestamp,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400,
            localDateKey: Self.key
        )
    }

    private func motion() -> MotionEventData {
        MotionEventData(
            startDate: Date(timeIntervalSince1970: 100), endDate: nil,
            isAutomotive: false, isWalking: true, isRunning: false,
            isCycling: false, isStationary: false, isUnknown: false,
            confidence: .medium, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: Self.key
        )
    }

    private func visit() -> VisitEventData {
        VisitEventData(
            latitude: 35, longitude: 139,
            arrivalDate: Date(timeIntervalSince1970: 100), departureDate: nil,
            horizontalAccuracy: 25, timeZoneIdentifier: "Asia/Tokyo",
            utcOffsetSeconds: 32400, localDateKey: Self.key
        )
    }
}

@MainActor
private struct Fixture {
    let location = FakeLocationProvider()
    let motion = FakeMotionProvider()
    let visit = FakeVisitProvider()
    let repository: RecordingRawEventRepository
    let logger = SpyEventLogger()
    let coordinator: RawEventStorageCoordinator

    init(repository: RecordingRawEventRepository = RecordingRawEventRepository()) {
        self.repository = repository
        coordinator = RawEventStorageCoordinator(
            locationProvider: location, motionProvider: motion, visitProvider: visit,
            repository: repository, logger: logger
        )
    }
}

private enum SavedRawEventKind: Sendable, Equatable {
    case location
    case motion
    case visit
}

private actor RecordingRawEventRepository: RawEventRepository {
    nonisolated let savedEvents: AsyncStream<SavedRawEventKind>
    private let continuation: AsyncStream<SavedRawEventKind>.Continuation
    private let locationResult: RawEventSaveResult
    private var locationFailuresRemaining: Int

    init(
        locationResult: RawEventSaveResult = .inserted,
        locationFailuresRemaining: Int = 0
    ) {
        let stream = AsyncStream.makeStream(of: SavedRawEventKind.self)
        savedEvents = stream.stream
        continuation = stream.continuation
        self.locationResult = locationResult
        self.locationFailuresRemaining = locationFailuresRemaining
    }

    func saveLocationEvent(_: LocationEventData) throws -> RawEventSaveResult {
        if locationFailuresRemaining > 0 {
            locationFailuresRemaining -= 1
            throw DriveLogError.persistenceFailure(code: "test_location")
        }
        continuation.yield(.location)
        return locationResult
    }

    func saveMotionEvent(_: MotionEventData) -> RawEventSaveResult {
        continuation.yield(.motion)
        return .inserted
    }

    func saveOrUpdateVisitEvent(_: VisitEventData) -> RawEventSaveResult {
        continuation.yield(.visit)
        return .updated
    }

    func rawEvents(for _: String) -> RawDayEvents {
        RawDayEvents(
            locations: [], motions: [], visits: [],
            classificationOverrides: [], stayOverrides: []
        )
    }

    func deleteRawEvents(for _: String) {}
}
