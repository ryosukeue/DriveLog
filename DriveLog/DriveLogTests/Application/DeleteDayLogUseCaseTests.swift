@testable import DriveLog
import os
import Testing

@Suite("Delete day log use case")
struct DeleteDayLogUseCaseTests {
    @Test("calls the repository once and logs completion")
    func success() async throws {
        let repository = DayDeletionRepositorySpy()
        let logger = SpyEventLogger()
        let useCase = DefaultDeleteDayLogUseCase(repository: repository, logger: logger)

        try await useCase.execute(localDateKey: "2024-01-01")

        #expect(repository.keys == ["2024-01-01"])
        #expect(logger.records == [TestLogRecord(
            level: .info,
            event: .dayDeletionCompleted(localDateKey: "2024-01-01")
        )])
    }

    @Test("preserves a repository DriveLogError and logs only failure")
    func repositoryFailure() async {
        let expected = DriveLogError.persistenceFailure(code: "store")
        let repository = DayDeletionRepositorySpy(error: expected)
        let logger = SpyEventLogger()
        let useCase = DefaultDeleteDayLogUseCase(repository: repository, logger: logger)

        await #expect(throws: expected) {
            try await useCase.execute(localDateKey: "2024-01-01")
        }

        #expect(repository.keys == ["2024-01-01"])
        #expect(logger.records == [TestLogRecord(
            level: .error,
            event: .dayDeletionFailed(localDateKey: "2024-01-01", code: "store")
        )])
    }

    @Test("normalizes an unknown repository error")
    func unknownFailure() async {
        let repository = DayDeletionRepositorySpy(error: DeleteTestError())
        let logger = SpyEventLogger()
        let useCase = DefaultDeleteDayLogUseCase(repository: repository, logger: logger)
        let expected = DriveLogError.persistenceFailure(code: "delete_day")

        await #expect(throws: expected) {
            try await useCase.execute(localDateKey: "2024-01-01")
        }

        #expect(logger.records == [TestLogRecord(
            level: .error,
            event: .dayDeletionFailed(localDateKey: "2024-01-01", code: "delete_day")
        )])
    }

    @Test("rejects an empty date before deletion or logging")
    func invalidInput() async {
        let repository = DayDeletionRepositorySpy()
        let logger = SpyEventLogger()
        let useCase = DefaultDeleteDayLogUseCase(repository: repository, logger: logger)

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(localDateKey: "")
        }

        #expect(repository.keys.isEmpty)
        #expect(logger.records.isEmpty)
    }
}

private struct DeleteTestError: Error {}

private final class DayDeletionRepositorySpy: DayDeletionRepository, @unchecked Sendable {
    private struct State {
        var keys: [String] = []
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())
    private let error: (any Error)?

    var keys: [String] {
        storage.withLock(\.keys)
    }

    init(error: (any Error)? = nil) {
        self.error = error
    }

    func deleteDay(localDateKey: String) throws {
        storage.withLock { $0.keys.append(localDateKey) }
        if let error {
            throw error
        }
    }
}
