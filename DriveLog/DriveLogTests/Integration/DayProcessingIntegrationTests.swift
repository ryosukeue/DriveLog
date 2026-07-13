@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Day processing integration")
@MainActor
struct DayProcessingIntegrationTests {
    private let day = "2024-01-01"
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("persists a walking day from raw events")
    func walking() async throws {
        let fixture = try Fixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(day: day, points: [
            (0, 0), (600, 120), (1200, 240)
        ])
        _ = try await fixture.raw.saveMotionEvent(motion(day: day, walking: true))

        let result = try await fixture.useCase.execute(localDateKey: day)
        let saved = try await fixture.derived.movementSegments(for: day)
        let state = try await fixture.state.state(for: day)

        #expect(result.aggregate.hasValidMovement)
        #expect(saved.count == 1)
        #expect(saved.first?.automaticClassification == .walkingLike)
        #expect(state.status == .completed)
        #expect(state.rawRevision == state.processedRevision)
    }

    @Test("persists automotive movement and a detected stay")
    func automotiveAndStay() async throws {
        let automotive = try Fixture(now: baseDate.addingTimeInterval(20000))
        try await automotive.saveLocations(day: day, points: [
            (0, 0), (1500, 120), (3000, 240)
        ])
        _ = try await automotive.raw.saveMotionEvent(motion(day: day, automotive: true))
        _ = try await automotive.useCase.execute(localDateKey: day)
        #expect(
            try await automotive.derived.movementSegments(for: day).first?
                .automaticClassification == .automotiveLike
        )

        let staying = try Fixture(now: baseDate.addingTimeInterval(20000))
        try await staying.saveLocations(day: day, points: [
            (0, 0), (100, 120), (100, 7320), (200, 7440)
        ])
        _ = try await staying.useCase.execute(localDateKey: day)
        let stays = try await staying.derived.staySegments(for: day)
        #expect(stays.count == 1)
        #expect(stays.first?.durationSeconds == 7200)
    }

    @Test("keeps local dates isolated")
    func localDateBoundary() async throws {
        let fixture = try Fixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(day: day, points: [(0, 0), (1200, 240)])
        try await fixture.saveLocations(day: "2024-01-02", points: [(0, 300), (2000, 600)])

        _ = try await fixture.useCase.execute(localDateKey: day)

        #expect(try await fixture.derived.aggregate(for: day)?.locationRecordCount == 2)
        #expect(try await fixture.derived.aggregate(for: "2024-01-02") == nil)
        #expect(try await fixture.raw.rawEvents(for: "2024-01-02").locations.count == 2)
    }

    @Test("reprocesses a newer raw revision and preserves overrides")
    func revisionAndOverride() async throws {
        let fixture = try Fixture(now: baseDate.addingTimeInterval(20000))
        try await fixture.saveLocations(day: day, points: [(0, 0), (600, 120), (1200, 240)])
        _ = try await fixture.useCase.execute(localDateKey: day)
        let firstState = try await fixture.state.state(for: day)
        let storedOverride = classificationOverride(day: day)
        try await fixture.overrides.upsertClassificationOverride(storedOverride)

        _ = try await fixture.raw.saveLocationEvent(
            location(day: day, eastMeters: 1800, seconds: 360)
        )
        let dirtyState = try await fixture.state.state(for: day)
        #expect(dirtyState.status == .pending)
        #expect(dirtyState.rawRevision > dirtyState.processedRevision)

        let result = try await fixture.useCase.execute(localDateKey: day)
        let finalState = try await fixture.state.state(for: day)
        #expect(finalState.rawRevision > firstState.rawRevision)
        #expect(finalState.rawRevision == finalState.processedRevision)
        #expect(result.aggregate.sourceRawRevision == finalState.rawRevision)
        #expect(try await fixture.overrides.classificationOverrides(for: day) == [storedOverride])
    }

    @Test("does not persist derived data when processing is cancelled")
    func cancellation() async throws {
        let fixture = try Fixture(
            now: baseDate.addingTimeInterval(20000),
            processor: CancellingDayProcessor()
        )
        try await fixture.saveLocations(day: day, points: [(0, 0), (1200, 240)])

        await #expect(throws: DriveLogError.cancelled) {
            try await fixture.useCase.execute(localDateKey: day)
        }

        #expect(try await fixture.derived.aggregate(for: day) == nil)
        let state = try await fixture.state.state(for: day)
        #expect(state.status == .failed)
        #expect(state.lastErrorCode == "cancelled")
    }

    private func motion(
        day: String,
        walking: Bool = false,
        automotive: Bool = false
    ) -> MotionEventData {
        MotionEventData(
            startDate: baseDate, endDate: baseDate.addingTimeInterval(240),
            isAutomotive: automotive, isWalking: walking, isRunning: false, isCycling: false,
            isStationary: false, isUnknown: false, confidence: .high,
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400, localDateKey: day
        )
    }

    private func location(day: String, eastMeters: Double, seconds: TimeInterval) -> LocationEventData {
        LocationEventData(
            latitude: 0, longitude: eastMeters / 6_371_000 * 180 / .pi,
            timestamp: baseDate.addingTimeInterval(seconds), horizontalAccuracy: 10,
            speedMetersPerSecond: nil, createdAt: baseDate.addingTimeInterval(seconds),
            timeZoneIdentifier: "Asia/Tokyo", utcOffsetSeconds: 32400, localDateKey: day
        )
    }

    private func classificationOverride(day: String) -> ClassificationOverrideData {
        ClassificationOverrideData(
            overrideKey: "\(day)|previous", targetStableID: "previous", localDateKey: day,
            originalStartDate: baseDate, originalEndDate: baseDate.addingTimeInterval(240),
            userClassification: .walking, createdAt: baseDate, updatedAt: baseDate
        )
    }
}

@MainActor
private struct Fixture {
    let raw: SwiftDataRawEventRepository
    let state: SwiftDataProcessingStateRepository
    let overrides: SwiftDataOverrideRepository
    let derived: SwiftDataDerivedDataRepository
    let useCase: DefaultProcessDayUseCase
    private let now: Date

    init(now: Date, processor: (any DayProcessing)? = nil) throws {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        let clock = IntegrationClock(now: now)
        raw = SwiftDataRawEventRepository(modelContainer: container, clock: clock)
        state = SwiftDataProcessingStateRepository(modelContainer: container, clock: clock)
        overrides = SwiftDataOverrideRepository(modelContainer: container)
        derived = SwiftDataDerivedDataRepository(modelContainer: container)
        self.now = now
        useCase = DefaultProcessDayUseCase(
            stateRepository: state,
            rawRepository: raw,
            overrideRepository: overrides,
            derivedRepository: derived,
            processor: processor ?? DefaultDayProcessor(clock: clock),
            clock: clock,
            logger: IntegrationLogger()
        )
    }

    func saveLocations(
        day: String,
        points: [(eastMeters: Double, seconds: TimeInterval)]
    ) async throws {
        for point in points {
            let timestamp = now.addingTimeInterval(point.seconds - 20000)
            let event = LocationEventData(
                latitude: 0, longitude: point.eastMeters / 6_371_000 * 180 / .pi,
                timestamp: timestamp, horizontalAccuracy: 10, speedMetersPerSecond: nil,
                createdAt: timestamp, timeZoneIdentifier: "Asia/Tokyo",
                utcOffsetSeconds: 32400, localDateKey: day
            )
            _ = try await raw.saveLocationEvent(event)
        }
    }
}

private nonisolated struct IntegrationClock: Clock {
    let now: Date
}

private nonisolated struct IntegrationLogger: Logging {
    func debug(_: LogEvent) {}
    func info(_: LogEvent) {}
    func error(_: LogEvent) {}
}

private nonisolated struct CancellingDayProcessor: DayProcessing {
    func process(
        localDateKey _: String,
        rawEvents _: RawDayEvents,
        mediaCount _: Int,
        rawRevision _: Int
    ) async throws -> DayProcessingResult {
        throw CancellationError()
    }
}
