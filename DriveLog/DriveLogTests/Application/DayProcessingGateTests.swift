@testable import DriveLog
import Foundation
import Testing

@Suite("Day processing gate")
struct DayProcessingGateTests {
    @Test("coalesces concurrent requests for the same day")
    func coalescesSameDay() async throws {
        let gate = DayProcessingGate()
        let probe = ProcessingProbe()
        let first = Task {
            try await gate.execute(localDateKey: "2024-01-01", priority: .background) {
                await probe.run(day: "2024-01-01")
            }
        }
        await probe.waitUntilInvocationCount(1)
        let second = Task {
            try await gate.execute(localDateKey: "2024-01-01", priority: .userVisible) {
                await probe.run(day: "2024-01-01")
            }
        }
        await probe.release()

        let firstResult = try await first.value
        let secondResult = try await second.value
        #expect(firstResult.aggregate.localDateKey == "2024-01-01")
        #expect(secondResult.aggregate.localDateKey == "2024-01-01")
        #expect(await probe.invocationCount(for: "2024-01-01") == 1)
    }

    @Test("runs different days independently")
    func differentDays() async throws {
        let gate = DayProcessingGate()
        let probe = ProcessingProbe()
        let first = Task {
            try await gate.execute(localDateKey: "2024-01-01", priority: .normal) {
                await probe.run(day: "2024-01-01")
            }
        }
        let second = Task {
            try await gate.execute(localDateKey: "2024-01-02", priority: .normal) {
                await probe.run(day: "2024-01-02")
            }
        }
        await probe.waitUntilInvocationCount(2)
        await probe.release()

        _ = try await (first.value, second.value)
        #expect(await probe.invocationCount(for: "2024-01-01") == 1)
        #expect(await probe.invocationCount(for: "2024-01-02") == 1)
    }

    @Test("allows retry after success and failure")
    func retry() async throws {
        let gate = DayProcessingGate()
        let successCount = InvocationCounter()
        for _ in 0 ..< 2 {
            _ = try await gate.execute(localDateKey: "2024-01-01", priority: .normal) {
                await successCount.increment()
                return makeResult(day: "2024-01-01")
            }
        }
        #expect(await successCount.value == 2)

        await #expect(throws: GateTestError.expected) {
            try await gate.execute(localDateKey: "2024-01-02", priority: .normal) {
                throw GateTestError.expected
            }
        }
        let recovered = try await gate.execute(
            localDateKey: "2024-01-02", priority: .normal
        ) {
            makeResult(day: "2024-01-02")
        }
        #expect(recovered.aggregate.localDateKey == "2024-01-02")
    }

    @Test("maps ordered processing priorities")
    func priorityMapping() {
        #expect(ProcessingPriority.background.rawValue < ProcessingPriority.normal.rawValue)
        #expect(ProcessingPriority.normal.rawValue < ProcessingPriority.userVisible.rawValue)
        #expect(ProcessingPriority.background.taskPriority == .background)
        #expect(ProcessingPriority.normal.taskPriority == .medium)
        #expect(ProcessingPriority.userVisible.taskPriority == .userInitiated)
    }
}

private actor ProcessingProbe {
    private var counts: [String: Int] = [:]
    private var totalCount = 0
    private var isReleased = false
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []
    private var countWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func run(day: String) async -> DayProcessingResult {
        counts[day, default: 0] += 1
        totalCount += 1
        resumeSatisfiedCountWaiters()
        if !isReleased {
            await withCheckedContinuation { continuation in
                releaseWaiters.append(continuation)
            }
        }
        return makeResult(day: day)
    }

    func waitUntilInvocationCount(_ count: Int) async {
        guard totalCount < count else { return }
        await withCheckedContinuation { continuation in
            countWaiters.append((count, continuation))
        }
    }

    func release() {
        isReleased = true
        let waiters = releaseWaiters
        releaseWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    func invocationCount(for day: String) -> Int {
        counts[day, default: 0]
    }

    private func resumeSatisfiedCountWaiters() {
        let satisfied = countWaiters.filter { $0.count <= totalCount }
        countWaiters.removeAll { $0.count <= totalCount }
        satisfied.forEach { $0.continuation.resume() }
    }
}

private actor InvocationCounter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}

private enum GateTestError: Error {
    case expected
}

private func makeResult(day: String) -> DayProcessingResult {
    DayProcessingResult(
        aggregate: DayAggregateData(
            localDateKey: day, totalDistanceMeters: 0, totalMovementDurationSeconds: 0,
            startDate: nil, endDate: nil, locationRecordCount: 0, rejectedLocationCount: 0,
            mediaCountCache: 0, automaticClassification: .other, hasValidMovement: false,
            movementSegmentCount: 0, staySegmentCount: 0, totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 0, walkingDurationSeconds: 0, sourceRawRevision: 0,
            generatedAt: Date(timeIntervalSince1970: 0)
        ),
        movements: [],
        stays: []
    )
}
