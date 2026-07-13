import Foundation
import SwiftData

extension PersistenceActor {
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
}
