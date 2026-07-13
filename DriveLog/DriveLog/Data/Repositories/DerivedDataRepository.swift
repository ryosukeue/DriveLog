import Foundation
import SwiftData

nonisolated protocol DerivedDataRepository: Sendable {
    func aggregate(for localDateKey: String) async throws -> DayAggregateData?
    func aggregates(in month: LocalMonth) async throws -> [DayAggregateData]
    func movementSegments(for localDateKey: String) async throws -> [MovementSegmentData]
    func staySegments(for localDateKey: String) async throws -> [StaySegmentData]
    func replaceDerivedData(
        for localDateKey: String,
        result: DayProcessingResult,
        processedRevision: Int
    ) async throws
    func deleteDerivedData(for localDateKey: String) async throws
}

nonisolated struct SwiftDataDerivedDataRepository: Sendable {
    private let persistenceActor: PersistenceActor
    private let routeEncoding: any RouteEncoding

    init(
        modelContainer: ModelContainer,
        routeEncoding: any RouteEncoding = PropertyListRouteEncoder()
    ) {
        persistenceActor = PersistenceActor(modelContainer: modelContainer)
        self.routeEncoding = routeEncoding
    }

    func aggregate(for localDateKey: String) async throws -> DayAggregateData? {
        do {
            return try await persistenceActor.aggregate(for: localDateKey, routeEncoding: routeEncoding)
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_day_aggregate")
        }
    }

    func aggregates(in month: LocalMonth) async throws -> [DayAggregateData] {
        guard let range = month.keyRange else {
            throw DriveLogError.invalidData
        }
        do {
            return try await persistenceActor.aggregates(
                from: range.start,
                before: range.end,
                routeEncoding: routeEncoding
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_month_aggregates")
        }
    }

    func movementSegments(for localDateKey: String) async throws -> [MovementSegmentData] {
        do {
            return try await persistenceActor.movementSegments(
                for: localDateKey,
                routeEncoding: routeEncoding
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_movement_segments")
        }
    }

    func staySegments(for localDateKey: String) async throws -> [StaySegmentData] {
        do {
            return try await persistenceActor.staySegments(
                for: localDateKey,
                routeEncoding: routeEncoding
            )
        } catch {
            throw DriveLogError.persistenceFailure(code: "fetch_stay_segments")
        }
    }
}

private extension LocalMonth {
    nonisolated var keyRange: (start: String, end: String)? {
        guard (1 ... 12).contains(month) else { return nil }
        let nextYear = month == 12 ? year + 1 : year
        let nextMonth = month == 12 ? 1 : month + 1
        return (
            String(format: "%04d-%02d-01", year, month),
            String(format: "%04d-%02d-01", nextYear, nextMonth)
        )
    }
}
