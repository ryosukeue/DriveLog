@testable import DriveLog
import Foundation
import Testing

@Suite("Day processing coordinator")
struct DayProcessingCoordinatorTests {
    @Test("forwards a visible day and its priority")
    func processIfNeeded() async {
        let gate = CoordinatorGateSpy()
        let coordinator = DefaultDayProcessingCoordinator(
            stateRepository: CoordinatorStateFake(keys: []),
            processDayUseCase: CoordinatorUseCaseFake(),
            gate: gate
        )

        await coordinator.processIfNeeded(localDateKey: "2024-01-02", priority: .userVisible)

        let requests = await gate.requests
        #expect(requests.count == 1)
        #expect(requests.first?.localDateKey == "2024-01-02")
        #expect(requests.first?.priority == .userVisible)
    }

    @Test("processes only the pending limit in repository order")
    func pendingLimit() async {
        let gate = CoordinatorGateSpy()
        let coordinator = DefaultDayProcessingCoordinator(
            stateRepository: CoordinatorStateFake(keys: ["2024-01-01", "2024-01-02", "2024-01-03"]),
            processDayUseCase: CoordinatorUseCaseFake(),
            gate: gate
        )

        await coordinator.processPendingDays(limit: 2)

        let requests = await gate.requests
        #expect(requests.map(\.localDateKey) == ["2024-01-01", "2024-01-02"])
        #expect(requests.allSatisfy { $0.priority == .background })
    }

    @Test("ignores nonpositive limits")
    func nonpositiveLimit() async {
        let state = CoordinatorStateFake(keys: ["2024-01-01"])
        let gate = CoordinatorGateSpy()
        let coordinator = DefaultDayProcessingCoordinator(
            stateRepository: state, processDayUseCase: CoordinatorUseCaseFake(), gate: gate
        )

        await coordinator.processPendingDays(limit: 0)
        await coordinator.processPendingDays(limit: -1)

        #expect(await state.pendingFetchCount == 0)
        #expect(await gate.requests.isEmpty)
    }

    @Test("continues after an individual processing failure")
    func continuesAfterFailure() async {
        let gate = CoordinatorGateSpy(failingDay: "2024-01-01")
        let coordinator = DefaultDayProcessingCoordinator(
            stateRepository: CoordinatorStateFake(keys: ["2024-01-01", "2024-01-02"]),
            processDayUseCase: CoordinatorUseCaseFake(),
            gate: gate
        )

        await coordinator.processPendingDays(limit: 2)

        #expect(await gate.requests.map(\.localDateKey) == ["2024-01-01", "2024-01-02"])
    }

    @Test("forwards cancellation and stops the current batch")
    func cancellation() async {
        let gate = CoordinatorGateSpy(suspendsFirstRequest: true)
        let coordinator = DefaultDayProcessingCoordinator(
            stateRepository: CoordinatorStateFake(keys: ["2024-01-01", "2024-01-02"]),
            processDayUseCase: CoordinatorUseCaseFake(),
            gate: gate
        )
        let batch = Task { await coordinator.processPendingDays(limit: 2) }
        await gate.waitUntilFirstRequest()

        await coordinator.cancelCurrentProcessing()
        await gate.resumeFirstRequest()
        await batch.value

        #expect(await gate.cancelCount == 1)
        #expect(await gate.requests.map(\.localDateKey) == ["2024-01-01"])
    }
}

private actor CoordinatorGateSpy: DayProcessingGating {
    struct Request: Sendable {
        let localDateKey: String
        let priority: ProcessingPriority
    }

    private(set) var requests: [Request] = []
    private(set) var cancelCount = 0
    private let failingDay: String?
    private let suspendsFirstRequest: Bool
    private var firstRequestContinuation: CheckedContinuation<Void, Never>?
    private var firstRequestWaiters: [CheckedContinuation<Void, Never>] = []

    init(failingDay: String? = nil, suspendsFirstRequest: Bool = false) {
        self.failingDay = failingDay
        self.suspendsFirstRequest = suspendsFirstRequest
    }

    func execute(
        localDateKey: String,
        priority: ProcessingPriority,
        operation: @escaping @Sendable () async throws -> DayProcessingResult
    ) async throws -> DayProcessingResult {
        requests.append(Request(localDateKey: localDateKey, priority: priority))
        if requests.count == 1 {
            let waiters = firstRequestWaiters
            firstRequestWaiters.removeAll()
            waiters.forEach { $0.resume() }
            if suspendsFirstRequest {
                await withCheckedContinuation { firstRequestContinuation = $0 }
            }
        }
        if localDateKey == failingDay {
            throw CoordinatorTestError.expected
        }
        return try await operation()
    }

    func cancelAll() {
        cancelCount += 1
    }

    func waitUntilFirstRequest() async {
        guard requests.isEmpty else { return }
        await withCheckedContinuation { firstRequestWaiters.append($0) }
    }

    func resumeFirstRequest() {
        firstRequestContinuation?.resume()
        firstRequestContinuation = nil
    }
}

private actor CoordinatorStateFake: ProcessingStateRepository {
    private let keys: [String]
    private(set) var pendingFetchCount = 0

    init(keys: [String]) {
        self.keys = keys
    }

    func pendingDateKeys() -> [String] {
        pendingFetchCount += 1
        return keys
    }

    func state(for localDateKey: String) -> DayProcessingStateData {
        DayProcessingStateData(
            localDateKey: localDateKey, rawRevision: 1, processedRevision: 0, status: .pending,
            lastAttemptDate: nil, lastSuccessfulDate: nil, lastErrorCode: nil,
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func markDirty(localDateKey _: String) {}
    func markProcessing(localDateKey _: String, attemptedAt _: Date) -> DayProcessingRevision {
        DayProcessingRevision(rawRevision: 1, processedRevision: 0)
    }

    func markCompleted(localDateKey _: String, processedRevision _: Int, completedAt _: Date) {}
    func markFailed(localDateKey _: String, code _: String, failedAt _: Date) {}
    func deleteState(for _: String) {}
}

private struct CoordinatorUseCaseFake: ProcessDayUseCase {
    func execute(localDateKey: String) -> DayProcessingResult {
        coordinatorResult(day: localDateKey)
    }
}

private enum CoordinatorTestError: Error {
    case expected
}

private nonisolated func coordinatorResult(day: String) -> DayProcessingResult {
    DayProcessingResult(
        aggregate: DayAggregateData(
            localDateKey: day, totalDistanceMeters: 0, totalMovementDurationSeconds: 0,
            startDate: nil, endDate: nil, locationRecordCount: 0, rejectedLocationCount: 0,
            mediaCountCache: 0, automaticClassification: .other, hasValidMovement: false,
            movementSegmentCount: 0, staySegmentCount: 0, totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 0, sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        ),
        movements: [],
        stays: []
    )
}
