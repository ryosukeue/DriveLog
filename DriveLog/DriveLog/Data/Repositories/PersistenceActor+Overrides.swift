import Foundation
import SwiftData

extension PersistenceActor {
    func classificationOverrides(
        for localDateKey: String
    ) throws -> [ClassificationOverrideData] {
        var descriptor = FetchDescriptor<ClassificationOverrideModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.sortBy = [SortDescriptor(\.overrideKey)]
        return try modelContext.fetch(descriptor).map(OverrideMediaModelMapper.data)
    }

    func stayOverrides(for localDateKey: String) throws -> [StayOverrideData] {
        var descriptor = FetchDescriptor<StayOverrideModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.sortBy = [SortDescriptor(\.overrideKey)]
        return try modelContext.fetch(descriptor).map(OverrideMediaModelMapper.data)
    }

    func upsertClassificationOverride(_ value: ClassificationOverrideData) throws {
        try validateOverrideKey(
            value.overrideKey, localDateKey: value.localDateKey,
            targetStableID: value.targetStableID
        )
        do {
            let key = value.overrideKey
            let descriptor = FetchDescriptor<ClassificationOverrideModel>(
                predicate: #Predicate { $0.overrideKey == key }
            )
            if let model = try modelContext.fetch(descriptor).first {
                model.targetStableID = value.targetStableID
                model.localDateKey = value.localDateKey
                model.originalStartDate = value.originalStartDate
                model.originalEndDate = value.originalEndDate
                model.userClassificationRawValue = RawValueMapper.rawValue(
                    for: value.userClassification
                )
                model.updatedAt = value.updatedAt
            } else {
                modelContext.insert(OverrideMediaModelMapper.model(from: value))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func upsertStayOverride(_ value: StayOverrideData) throws {
        try validateOverrideKey(
            value.overrideKey, localDateKey: value.localDateKey,
            targetStableID: value.targetStableID
        )
        do {
            let key = value.overrideKey
            let descriptor = FetchDescriptor<StayOverrideModel>(
                predicate: #Predicate { $0.overrideKey == key }
            )
            if let model = try modelContext.fetch(descriptor).first {
                model.targetStableID = value.targetStableID
                model.localDateKey = value.localDateKey
                model.originalArrivalDate = value.originalArrivalDate
                model.originalDepartureDate = value.originalDepartureDate
                model.originalLatitude = value.originalCoordinate.latitude
                model.originalLongitude = value.originalCoordinate.longitude
                model.actionRawValue = RawValueMapper.rawValue(for: value.action)
                model.updatedAt = value.updatedAt
            } else {
                modelContext.insert(OverrideMediaModelMapper.model(from: value))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func deleteOverrides(for localDateKey: String) throws {
        do {
            let classifications = try modelContext.fetch(
                FetchDescriptor<ClassificationOverrideModel>(
                    predicate: #Predicate { $0.localDateKey == localDateKey }
                )
            )
            let stays = try modelContext.fetch(FetchDescriptor<StayOverrideModel>(
                predicate: #Predicate { $0.localDateKey == localDateKey }
            ))
            classifications.forEach(modelContext.delete)
            stays.forEach(modelContext.delete)
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func validateOverrideKey(
        _ overrideKey: String,
        localDateKey: String,
        targetStableID: String
    ) throws {
        guard overrideKey == "\(localDateKey)|\(targetStableID)" else {
            throw DriveLogError.invalidData
        }
    }
}
