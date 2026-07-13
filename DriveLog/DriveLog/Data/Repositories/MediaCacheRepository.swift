import Foundation
import SwiftData

nonisolated protocol MediaCacheRepository: Sendable {
    func cachedAssets(for localDateKey: String) async throws -> [MediaAssetReference]
    func upsertAssets(
        _ assets: [MediaAssetReference],
        for localDateKey: String,
        validatedAt: Date
    ) async throws
    func removeAssets(localIdentifiers: [String]) async throws
    func replaceAssets(
        for localDateKey: String,
        assets: [MediaAssetReference],
        validatedAt: Date
    ) async throws
    func deleteCache(for localDateKey: String) async throws
}

nonisolated struct SwiftDataMediaCacheRepository: MediaCacheRepository {
    private let persistenceActor: PersistenceActor

    init(modelContainer: ModelContainer) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
    }

    func cachedAssets(for localDateKey: String) async throws -> [MediaAssetReference] {
        do {
            return try await persistenceActor.cachedMediaAssets(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_media_cache")
        }
    }

    func upsertAssets(
        _ assets: [MediaAssetReference],
        for localDateKey: String,
        validatedAt: Date
    ) async throws {
        do {
            try await persistenceActor.upsertMediaAssets(
                assets,
                for: localDateKey,
                validatedAt: validatedAt
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "upsert_media_cache")
        }
    }

    func removeAssets(localIdentifiers: [String]) async throws {
        do {
            try await persistenceActor.removeMediaAssets(localIdentifiers: localIdentifiers)
        } catch {
            throw DriveLogError.persistenceFailure(code: "remove_media_cache")
        }
    }

    func replaceAssets(
        for localDateKey: String,
        assets: [MediaAssetReference],
        validatedAt: Date
    ) async throws {
        do {
            try await persistenceActor.replaceMediaAssets(
                for: localDateKey,
                assets: assets,
                validatedAt: validatedAt
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "replace_media_cache")
        }
    }

    func deleteCache(for localDateKey: String) async throws {
        do {
            try await persistenceActor.deleteMediaCache(for: localDateKey)
        } catch {
            throw DriveLogError.persistenceFailure(code: "delete_media_cache")
        }
    }
}
