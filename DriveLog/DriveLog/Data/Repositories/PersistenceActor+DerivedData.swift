import Foundation
import SwiftData

extension PersistenceActor {
    func replaceDerivedData(
        for localDateKey: String,
        result: DayProcessingResult,
        processedRevision: Int,
        routeEncoding: any RouteEncoding
    ) throws {
        guard result.aggregate.localDateKey == localDateKey,
              result.aggregate.sourceRawRevision == processedRevision,
              result.movements.allSatisfy({
                  $0.localDateKey == localDateKey && $0.sourceRawRevision == processedRevision
              }),
              result.stays.allSatisfy({
                  $0.localDateKey == localDateKey && $0.sourceRawRevision == processedRevision
              })
        else {
            throw DriveLogError.invalidData
        }

        let mapper = DerivedDataModelMapper(routeEncoding: routeEncoding)
        let aggregate = mapper.model(from: result.aggregate)
        let movements = try result.movements.map { try mapper.model(from: $0) }
        let stays = result.stays.map { mapper.model(from: $0) }

        do {
            try deleteDerivedModels(for: localDateKey)
            modelContext.insert(aggregate)
            movements.forEach(modelContext.insert)
            stays.forEach(modelContext.insert)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func deleteDerivedData(for localDateKey: String) throws {
        do {
            try deleteDerivedModels(for: localDateKey)
            try saveIfNeeded()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func aggregate(
        for localDateKey: String,
        routeEncoding: any RouteEncoding
    ) throws -> DayAggregateData? {
        var descriptor = FetchDescriptor<DayAggregateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map {
            DerivedDataModelMapper(routeEncoding: routeEncoding).data(from: $0)
        }
    }

    func aggregates(
        from startKey: String,
        before endKey: String,
        routeEncoding: any RouteEncoding
    ) throws -> [DayAggregateData] {
        let descriptor = FetchDescriptor<DayAggregateModel>(
            predicate: #Predicate { $0.localDateKey >= startKey && $0.localDateKey < endKey },
            sortBy: [SortDescriptor(\DayAggregateModel.localDateKey)]
        )
        let mapper = DerivedDataModelMapper(routeEncoding: routeEncoding)
        return try modelContext.fetch(descriptor).map(mapper.data)
    }

    func movementSegments(
        for localDateKey: String,
        routeEncoding: any RouteEncoding
    ) throws -> [MovementSegmentData] {
        let descriptor = FetchDescriptor<MovementSegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey },
            sortBy: [SortDescriptor(\MovementSegmentModel.startDate)]
        )
        let mapper = DerivedDataModelMapper(routeEncoding: routeEncoding)
        return try modelContext.fetch(descriptor).map(mapper.data)
    }

    func staySegments(
        for localDateKey: String,
        routeEncoding: any RouteEncoding
    ) throws -> [StaySegmentData] {
        let descriptor = FetchDescriptor<StaySegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey },
            sortBy: [SortDescriptor(\StaySegmentModel.estimatedArrivalDate)]
        )
        let mapper = DerivedDataModelMapper(routeEncoding: routeEncoding)
        return try modelContext.fetch(descriptor).map(mapper.data)
    }

    private func deleteDerivedModels(for localDateKey: String) throws {
        let aggregates = try modelContext.fetch(FetchDescriptor<DayAggregateModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let movements = try modelContext.fetch(FetchDescriptor<MovementSegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        let stays = try modelContext.fetch(FetchDescriptor<StaySegmentModel>(
            predicate: #Predicate { $0.localDateKey == localDateKey }
        ))
        aggregates.forEach(modelContext.delete)
        movements.forEach(modelContext.delete)
        stays.forEach(modelContext.delete)
    }
}
