@testable import DriveLog
import Foundation
import Testing

@Suite("Processing state repository integration")
@MainActor
struct ProcessingStateRepositoryTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("creates the initial state and transitions through success")
    func initialAndCompletedState() async throws {
        let repository = try makeRepository()
        let initial = try await repository.state(for: "2024-01-01")

        #expect(initial.rawRevision == 0)
        #expect(initial.processedRevision == 0)
        #expect(initial.status == .pending)
        #expect(initial.updatedAt == now)

        try await repository.markDirty(localDateKey: "2024-01-01")
        let revision = try await repository.markProcessing(
            localDateKey: "2024-01-01",
            attemptedAt: now.addingTimeInterval(10)
        )
        #expect(revision == DayProcessingRevision(rawRevision: 1, processedRevision: 0))

        try await repository.markCompleted(
            localDateKey: "2024-01-01",
            processedRevision: revision.rawRevision,
            completedAt: now.addingTimeInterval(20)
        )
        let completed = try await repository.state(for: "2024-01-01")
        #expect(completed.rawRevision == 1)
        #expect(completed.processedRevision == 1)
        #expect(completed.status == .completed)
        #expect(completed.lastAttemptDate == now.addingTimeInterval(10))
        #expect(completed.lastSuccessfulDate == now.addingTimeInterval(20))
        #expect(completed.lastErrorCode == nil)
    }

    @Test("records failure without advancing the processed revision")
    func failedState() async throws {
        let repository = try makeRepository()
        try await repository.markDirty(localDateKey: "2024-01-01")
        _ = try await repository.markProcessing(localDateKey: "2024-01-01", attemptedAt: now)
        try await repository.markFailed(
            localDateKey: "2024-01-01",
            code: "pipeline",
            failedAt: now.addingTimeInterval(1)
        )

        let state = try await repository.state(for: "2024-01-01")
        #expect(state.rawRevision == 1)
        #expect(state.processedRevision == 0)
        #expect(state.status == .failed)
        #expect(state.lastErrorCode == "pipeline")
        #expect(state.updatedAt == now.addingTimeInterval(1))
    }

    @Test("keeps a newer raw revision pending after an older revision completes")
    func rawChangeDuringProcessing() async throws {
        let repository = try makeRepository()
        try await repository.markDirty(localDateKey: "2024-01-01")
        let revision = try await repository.markProcessing(localDateKey: "2024-01-01", attemptedAt: now)
        try await repository.markDirty(localDateKey: "2024-01-01")
        try await repository.markCompleted(
            localDateKey: "2024-01-01",
            processedRevision: revision.rawRevision,
            completedAt: now.addingTimeInterval(1)
        )

        let state = try await repository.state(for: "2024-01-01")
        #expect(state.rawRevision == 2)
        #expect(state.processedRevision == 1)
        #expect(state.status == .pending)
        #expect(try await repository.pendingDateKeys() == ["2024-01-01"])
    }

    @Test("returns incomplete pending processing and failed dates in order")
    func pendingDateKeys() async throws {
        let repository = try makeRepository()
        _ = try await repository.state(for: "2024-01-00")
        try await repository.markDirty(localDateKey: "2024-01-03")
        try await repository.markDirty(localDateKey: "2024-01-01")
        try await repository.markDirty(localDateKey: "2024-01-02")
        _ = try await repository.markProcessing(localDateKey: "2024-01-02", attemptedAt: now)
        try await repository.markFailed(localDateKey: "2024-01-03", code: "retry", failedAt: now)

        try await repository.markDirty(localDateKey: "2024-01-04")
        let completedRevision = try await repository.markProcessing(
            localDateKey: "2024-01-04",
            attemptedAt: now
        )
        try await repository.markCompleted(
            localDateKey: "2024-01-04",
            processedRevision: completedRevision.rawRevision,
            completedAt: now
        )
        _ = try await repository.markProcessing(localDateKey: "2024-01-04", attemptedAt: now)

        #expect(try await repository.pendingDateKeys() == [
            "2024-01-03", "2024-01-02", "2024-01-01"
        ])
    }

    @Test("deletes only the requested state and tolerates a repeated delete")
    func deletion() async throws {
        let repository = try makeRepository()
        try await repository.markDirty(localDateKey: "2024-01-01")
        try await repository.markDirty(localDateKey: "2024-01-02")

        try await repository.deleteState(for: "2024-01-01")
        try await repository.deleteState(for: "2024-01-01")

        #expect(try await repository.pendingDateKeys() == ["2024-01-02"])
        let recreated = try await repository.state(for: "2024-01-01")
        #expect(recreated.rawRevision == 0)
    }

    @Test("invalidates completed days without changing an already incomplete day")
    func algorithmInvalidation() async throws {
        let repository = try makeRepository()
        try await repository.markDirty(localDateKey: "2024-01-01")
        let completedRevision = try await repository.markProcessing(
            localDateKey: "2024-01-01",
            attemptedAt: now
        )
        try await repository.markCompleted(
            localDateKey: "2024-01-01",
            processedRevision: completedRevision.rawRevision,
            completedAt: now
        )
        try await repository.markDirty(localDateKey: "2024-01-02")
        try await repository.markDirty(localDateKey: "2024-01-02")

        try await repository.invalidateProcessedDaysForAlgorithmUpdate()

        let invalidated = try await repository.state(for: "2024-01-01")
        let alreadyIncomplete = try await repository.state(for: "2024-01-02")
        #expect(invalidated.rawRevision == 1)
        #expect(invalidated.processedRevision == 0)
        #expect(invalidated.status == .pending)
        #expect(alreadyIncomplete.rawRevision == 2)
        #expect(alreadyIncomplete.processedRevision == 0)
        #expect(try await repository.pendingDateKeys() == ["2024-01-02", "2024-01-01"])
    }

    private func makeRepository() throws -> SwiftDataProcessingStateRepository {
        let container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        return SwiftDataProcessingStateRepository(
            modelContainer: container,
            clock: FixedProcessingStateClock(now: now)
        )
    }
}

private struct FixedProcessingStateClock: Clock {
    let now: Date
}
