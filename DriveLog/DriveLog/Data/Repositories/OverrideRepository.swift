import Foundation
import SwiftData

nonisolated protocol OverrideRepository: Sendable {
    func classificationOverrides(for localDateKey: String) async throws
        -> [ClassificationOverrideData]
    func stayOverrides(for localDateKey: String) async throws -> [StayOverrideData]
    func upsertClassificationOverride(_ value: ClassificationOverrideData) async throws
    func upsertStayOverride(_ value: StayOverrideData) async throws
    func deleteOverrides(for localDateKey: String) async throws
}

nonisolated struct SwiftDataOverrideRepository: OverrideRepository {
    private let persistenceActor: PersistenceActor

    init(modelContainer: ModelContainer) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
    }

    func classificationOverrides(
        for localDateKey: String
    ) async throws -> [ClassificationOverrideData] {
        do {
            return try await persistenceActor.classificationOverrides(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_classification_overrides")
        }
    }

    func stayOverrides(for localDateKey: String) async throws -> [StayOverrideData] {
        do {
            return try await persistenceActor.stayOverrides(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_stay_overrides")
        }
    }

    func upsertClassificationOverride(_ value: ClassificationOverrideData) async throws {
        do {
            try await persistenceActor.upsertClassificationOverride(value)
        } catch {
            throw DriveLogError.persistenceFailure(code: "upsert_classification_override")
        }
    }

    func upsertStayOverride(_ value: StayOverrideData) async throws {
        do {
            try await persistenceActor.upsertStayOverride(value)
        } catch {
            throw DriveLogError.persistenceFailure(code: "upsert_stay_override")
        }
    }

    func deleteOverrides(for localDateKey: String) async throws {
        do {
            try await persistenceActor.deleteOverrides(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "delete_overrides")
        }
    }
}
