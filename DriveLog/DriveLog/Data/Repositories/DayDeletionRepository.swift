import SwiftData

nonisolated protocol DayDeletionRepository: Sendable {
    func deleteDay(localDateKey: String) async throws
}

nonisolated struct SwiftDataDayDeletionRepository: DayDeletionRepository {
    private let persistenceActor: PersistenceActor

    init(modelContainer: ModelContainer) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
    }

    func deleteDay(localDateKey: String) async throws {
        do {
            try await persistenceActor.deleteDay(localDateKey: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "delete_day")
        }
    }
}
