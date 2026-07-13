import Foundation
import SwiftData

nonisolated protocol ProcessingStateRepository: Sendable {
    func state(for localDateKey: String) async throws -> DayProcessingStateData
    func pendingDateKeys() async throws -> [String]
    func markDirty(localDateKey: String) async throws
    func markProcessing(
        localDateKey: String,
        attemptedAt: Date
    ) async throws -> DayProcessingRevision
    func markCompleted(
        localDateKey: String,
        processedRevision: Int,
        completedAt: Date
    ) async throws
    func markFailed(localDateKey: String, code: String, failedAt: Date) async throws
    func deleteState(for localDateKey: String) async throws
}

nonisolated struct SwiftDataProcessingStateRepository: ProcessingStateRepository {
    private let persistenceActor: PersistenceActor
    private let clock: any Clock

    init(modelContainer: ModelContainer, clock: any Clock = SystemClock()) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
        self.clock = clock
    }

    func state(for localDateKey: String) async throws -> DayProcessingStateData {
        do {
            return try await persistenceActor.processingState(
                for: localDateKey,
                createAt: clock.now
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_processing_state")
        }
    }

    func pendingDateKeys() async throws -> [String] {
        do {
            return try await persistenceActor.pendingProcessingDateKeys()
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_pending_dates")
        }
    }

    func markDirty(localDateKey: String) async throws {
        do {
            try await persistenceActor.markProcessingDirty(
                localDateKey: localDateKey,
                updatedAt: clock.now
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "mark_processing_dirty")
        }
    }

    func markProcessing(
        localDateKey: String,
        attemptedAt: Date
    ) async throws -> DayProcessingRevision {
        do {
            return try await persistenceActor.markProcessing(
                localDateKey: localDateKey,
                attemptedAt: attemptedAt
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "mark_processing_started")
        }
    }

    func markCompleted(
        localDateKey: String,
        processedRevision: Int,
        completedAt: Date
    ) async throws {
        do {
            try await persistenceActor.markProcessingCompleted(
                localDateKey: localDateKey,
                processedRevision: processedRevision,
                completedAt: completedAt
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "mark_processing_completed")
        }
    }

    func markFailed(localDateKey: String, code: String, failedAt: Date) async throws {
        do {
            try await persistenceActor.markProcessingFailed(
                localDateKey: localDateKey,
                code: code,
                failedAt: failedAt
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "mark_processing_failed")
        }
    }

    func deleteState(for localDateKey: String) async throws {
        do {
            try await persistenceActor.deleteProcessingState(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "delete_processing_state")
        }
    }
}
