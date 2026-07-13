@testable import DriveLog
import Foundation
import Testing

@Suite("Process day use case")
struct ProcessDayUseCaseTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("processes inputs and completes the captured revision")
    func processesPendingDay() async throws {
        let fixture = Fixture(date: date)
        let result = try await fixture.useCase.execute(localDateKey: "2024-01-01")

        #expect(result.aggregate.mediaCountCache == 3)
        #expect(await fixture.processor.received?.rawEvents.classificationOverrides.count == 1)
        #expect(await fixture.processor.received?.rawEvents.stayOverrides.count == 1)
        #expect(await fixture.processor.received?.rawRevision == 4)
        #expect(await fixture.derived.replacedRevision == 4)
        #expect(await fixture.state.completedRevision == 4)
        #expect(fixture.logger.records.map(\.event) == [
            .dayProcessingStarted(localDateKey: "2024-01-01"),
            .dayProcessingCompleted(localDateKey: "2024-01-01")
        ])
    }

    @Test("returns stored data without processing a completed generation")
    func skipsCompletedDay() async throws {
        let fixture = Fixture(date: date, completed: true)
        let result = try await fixture.useCase.execute(localDateKey: "2024-01-01")

        #expect(result.aggregate.localDateKey == "2024-01-01")
        #expect(await fixture.processor.received == nil)
        #expect(await fixture.state.markProcessingCount == 0)
        #expect(fixture.logger.records.isEmpty)
    }

    @Test("marks processing failures and logs a fixed code")
    func processingFailure() async throws {
        let fixture = Fixture(date: date, processorError: DriveLogError.invalidData)

        await #expect(throws: DriveLogError.invalidData) {
            try await fixture.useCase.execute(localDateKey: "2024-01-01")
        }
        #expect(await fixture.state.failedCode == "process_day")
        #expect(fixture.logger.records.last?.event == .dayProcessingFailed(
            localDateKey: "2024-01-01", code: "process_day"
        ))
    }

    @Test("does not complete when derived replacement fails")
    func replacementFailure() async throws {
        let fixture = Fixture(date: date, replacementError: DriveLogError.invalidData)

        await #expect(throws: DriveLogError.invalidData) {
            try await fixture.useCase.execute(localDateKey: "2024-01-01")
        }
        #expect(await fixture.state.completedRevision == nil)
        #expect(await fixture.state.failedCode == "process_day")
    }

    @Test("normalizes cancellation and records failure")
    func cancellation() async throws {
        let fixture = Fixture(date: date, processorError: CancellationError())

        await #expect(throws: DriveLogError.cancelled) {
            try await fixture.useCase.execute(localDateKey: "2024-01-01")
        }
        #expect(await fixture.state.failedCode == "cancelled")
    }
}

private struct Fixture {
    let state: StateRepositoryFake
    let processor: ProcessorFake
    let derived: DerivedRepositoryFake
    let logger: SpyEventLogger
    let useCase: DefaultProcessDayUseCase

    init(
        date: Date,
        completed: Bool = false,
        processorError: (any Error)? = nil,
        replacementError: (any Error)? = nil
    ) {
        state = StateRepositoryFake(date: date, completed: completed)
        processor = ProcessorFake(date: date, error: processorError)
        derived = DerivedRepositoryFake(date: date, replacementError: replacementError)
        logger = SpyEventLogger()
        useCase = DefaultProcessDayUseCase(
            stateRepository: state,
            rawRepository: RawRepositoryFake(),
            overrideRepository: OverrideRepositoryFake(date: date),
            derivedRepository: derived,
            processor: processor,
            mediaCountLoader: { _ in 3 },
            clock: FixedClock(now: date),
            logger: logger
        )
    }
}

private actor StateRepositoryFake: ProcessingStateRepository {
    private let date: Date
    private let completed: Bool
    private(set) var markProcessingCount = 0
    private(set) var completedRevision: Int?
    private(set) var failedCode: String?

    init(date: Date, completed: Bool) {
        self.date = date
        self.completed = completed
    }

    func state(for localDateKey: String) -> DayProcessingStateData {
        DayProcessingStateData(
            localDateKey: localDateKey, rawRevision: 4, processedRevision: completed ? 4 : 2,
            status: completed ? .completed : .pending, lastAttemptDate: nil,
            lastSuccessfulDate: completed ? date : nil, lastErrorCode: nil, updatedAt: date
        )
    }

    func pendingDateKeys() -> [String] {
        []
    }

    func markDirty(localDateKey _: String) {}

    func markProcessing(localDateKey _: String, attemptedAt _: Date) -> DayProcessingRevision {
        markProcessingCount += 1
        return DayProcessingRevision(rawRevision: 4, processedRevision: 2)
    }

    func markCompleted(localDateKey _: String, processedRevision: Int, completedAt _: Date) {
        completedRevision = processedRevision
    }

    func markFailed(localDateKey _: String, code: String, failedAt _: Date) {
        failedCode = code
    }

    func deleteState(for _: String) {}
}

private actor ProcessorFake: DayProcessing {
    struct Input: Sendable {
        let rawEvents: RawDayEvents
        let rawRevision: Int
    }

    private let date: Date
    private let error: (any Error)?
    private(set) var received: Input?

    init(date: Date, error: (any Error)?) {
        self.date = date
        self.error = error
    }

    func process(
        localDateKey: String,
        rawEvents: RawDayEvents,
        mediaCount: Int,
        rawRevision: Int
    ) throws -> DayProcessingResult {
        received = Input(rawEvents: rawEvents, rawRevision: rawRevision)
        if let error {
            throw error
        }
        return DayProcessingResult(
            aggregate: makeAggregate(
                day: localDateKey, date: date, revision: rawRevision, mediaCount: mediaCount
            ),
            movements: [],
            stays: []
        )
    }
}

private actor DerivedRepositoryFake: DerivedDataRepository {
    private let date: Date
    private let replacementError: (any Error)?
    private(set) var replacedRevision: Int?

    init(date: Date, replacementError: (any Error)?) {
        self.date = date
        self.replacementError = replacementError
    }

    func aggregate(for localDateKey: String) -> DayAggregateData? {
        makeAggregate(day: localDateKey, date: date, revision: 4, mediaCount: 0)
    }

    func aggregates(in _: LocalMonth) -> [DayAggregateData] {
        []
    }

    func movementSegments(for _: String) -> [MovementSegmentData] {
        []
    }

    func staySegments(for _: String) -> [StaySegmentData] {
        []
    }

    func replaceDerivedData(
        for _: String,
        result _: DayProcessingResult,
        processedRevision: Int
    ) throws {
        if let replacementError {
            throw replacementError
        }
        replacedRevision = processedRevision
    }

    func deleteDerivedData(for _: String) {}
}

private struct RawRepositoryFake: RawEventRepository {
    func saveLocationEvent(_: LocationEventData) -> RawEventSaveResult {
        .inserted
    }

    func saveMotionEvent(_: MotionEventData) -> RawEventSaveResult {
        .inserted
    }

    func saveOrUpdateVisitEvent(_: VisitEventData) -> RawEventSaveResult {
        .inserted
    }

    func rawEvents(for _: String) -> RawDayEvents {
        .empty
    }

    func deleteRawEvents(for _: String) {}
}

private struct OverrideRepositoryFake: OverrideRepository {
    let date: Date

    func classificationOverrides(for localDateKey: String) -> [ClassificationOverrideData] {
        [ClassificationOverrideData(
            overrideKey: "\(localDateKey)|movement", targetStableID: "movement",
            localDateKey: localDateKey, originalStartDate: date,
            originalEndDate: date.addingTimeInterval(60), userClassification: .walking,
            createdAt: date, updatedAt: date
        )]
    }

    func stayOverrides(for localDateKey: String) -> [StayOverrideData] {
        [StayOverrideData(
            overrideKey: "\(localDateKey)|stay", targetStableID: "stay",
            localDateKey: localDateKey, originalArrivalDate: date,
            originalDepartureDate: date.addingTimeInterval(60),
            originalCoordinate: RouteCoordinate(latitude: 35, longitude: 139), action: .confirm,
            createdAt: date, updatedAt: date
        )]
    }

    func upsertClassificationOverride(_: ClassificationOverrideData) {}
    func upsertStayOverride(_: StayOverrideData) {}
    func deleteOverrides(for _: String) {}
}

private struct FixedClock: Clock {
    let now: Date
}

private func makeAggregate(
    day: String,
    date: Date,
    revision: Int,
    mediaCount: Int
) -> DayAggregateData {
    DayAggregateData(
        localDateKey: day, totalDistanceMeters: 0, totalMovementDurationSeconds: 0,
        startDate: nil, endDate: nil, locationRecordCount: 0, rejectedLocationCount: 0,
        mediaCountCache: mediaCount, automaticClassification: .other, hasValidMovement: false,
        movementSegmentCount: 0, staySegmentCount: 0, totalStayDurationSeconds: 0,
        automotiveDurationSeconds: 0, walkingDurationSeconds: 0,
        sourceRawRevision: revision, generatedAt: date
    )
}
