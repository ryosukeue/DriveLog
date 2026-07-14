import Foundation
import SwiftData

extension PersistenceActor {
    func deleteDay(localDateKey: String) throws {
        try deleteDayRawModels(localDateKey: localDateKey)
        try deleteDayDerivedModels(localDateKey: localDateKey)
        try deleteDayUserModels(localDateKey: localDateKey)
        try deleteDaySupportModels(localDateKey: localDateKey)
        try modelContext.save()
    }

    private func deleteDayRawModels(localDateKey: String) throws {
        let locations = try modelContext.fetch(FetchDescriptor<LocationEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let motions = try modelContext.fetch(FetchDescriptor<MotionEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let visits = try modelContext.fetch(FetchDescriptor<VisitEventModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        locations.forEach { modelContext.delete($0) }
        motions.forEach { modelContext.delete($0) }
        visits.forEach { modelContext.delete($0) }
    }

    private func deleteDayDerivedModels(localDateKey: String) throws {
        let aggregates = try modelContext.fetch(FetchDescriptor<DayAggregateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let movements = try modelContext.fetch(FetchDescriptor<MovementSegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let stays = try modelContext.fetch(FetchDescriptor<StaySegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        aggregates.forEach { modelContext.delete($0) }
        movements.forEach { modelContext.delete($0) }
        stays.forEach { modelContext.delete($0) }
    }

    private func deleteDayUserModels(localDateKey: String) throws {
        let classifications = try modelContext.fetch(FetchDescriptor<ClassificationOverrideModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let stays = try modelContext.fetch(FetchDescriptor<StayOverrideModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        classifications.forEach { modelContext.delete($0) }
        stays.forEach { modelContext.delete($0) }
    }

    private func deleteDaySupportModels(localDateKey: String) throws {
        let states = try modelContext.fetch(FetchDescriptor<DayProcessingStateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let media = try modelContext.fetch(FetchDescriptor<MediaAssetCacheModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        states.forEach { modelContext.delete($0) }
        media.forEach { modelContext.delete($0) }
    }
}
