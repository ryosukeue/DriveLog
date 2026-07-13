import Foundation
import SwiftData

extension PersistenceActor {
    func cachedMediaAssets(for localDateKey: String) throws -> [MediaAssetReference] {
        var descriptor = FetchDescriptor<MediaAssetCacheModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.sortBy = [
            SortDescriptor(\.creationDate),
            SortDescriptor(\.localIdentifier)
        ]
        return try modelContext.fetch(descriptor).map(OverrideMediaModelMapper.reference)
    }

    func upsertMediaAssets(
        _ assets: [MediaAssetReference],
        for localDateKey: String,
        validatedAt: Date
    ) throws {
        do {
            for asset in uniqueAssets(assets) {
                try upsertMediaAsset(asset, for: localDateKey, validatedAt: validatedAt)
            }
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func removeMediaAssets(localIdentifiers: [String]) throws {
        do {
            for localIdentifier in Set(localIdentifiers) {
                let descriptor = FetchDescriptor<MediaAssetCacheModel>(
                    predicate: #Predicate { $0.localIdentifier == localIdentifier }
                )
                try modelContext.fetch(descriptor).forEach(modelContext.delete)
            }
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func replaceMediaAssets(
        for localDateKey: String,
        assets: [MediaAssetReference],
        validatedAt: Date
    ) throws {
        do {
            let unique = uniqueAssets(assets)
            let incomingIdentifiers = Set(unique.map(\.localIdentifier))
            let existing = try modelContext.fetch(FetchDescriptor<MediaAssetCacheModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            ))
            existing
                .filter { incomingIdentifiers.contains($0.localIdentifier) == false }
                .forEach(modelContext.delete)
            for asset in unique {
                try upsertMediaAsset(asset, for: localDateKey, validatedAt: validatedAt)
            }
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func deleteMediaCache(for localDateKey: String) throws {
        do {
            let descriptor = FetchDescriptor<MediaAssetCacheModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            )
            try modelContext.fetch(descriptor).forEach(modelContext.delete)
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func upsertMediaAsset(
        _ asset: MediaAssetReference,
        for localDateKey: String,
        validatedAt: Date
    ) throws {
        let localIdentifier = asset.localIdentifier
        let descriptor = FetchDescriptor<MediaAssetCacheModel>(
            predicate: #Predicate { $0.localIdentifier == localIdentifier }
        )
        if let model = try modelContext.fetch(descriptor).first {
            model.localDateKey = localDateKey
            model.mediaTypeRawValue = RawValueMapper.rawValue(for: asset.mediaType)
            model.creationDate = asset.creationDate
            model.latitude = asset.location?.latitude
            model.longitude = asset.location?.longitude
            model.durationSeconds = asset.durationSeconds
            model.isScreenshot = asset.isScreenshot
            model.isScreenRecording = asset.isScreenRecording
            model.eligibilityRawValue = RawValueMapper.rawValue(for: .eligible)
            model.lastValidatedAt = validatedAt
        } else {
            modelContext.insert(OverrideMediaModelMapper.model(
                from: asset,
                localDateKey: localDateKey,
                eligibility: .eligible,
                lastValidatedAt: validatedAt
            ))
        }
    }

    private func uniqueAssets(_ assets: [MediaAssetReference]) -> [MediaAssetReference] {
        Array(Dictionary(assets.map { ($0.localIdentifier, $0) }, uniquingKeysWith: { _, last in
            last
        }).values)
    }
}
