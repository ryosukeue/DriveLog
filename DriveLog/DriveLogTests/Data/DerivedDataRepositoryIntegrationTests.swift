@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Derived data repository retrieval")
@MainActor
struct DerivedDataRepositoryTests {
    @Test("fetches one aggregate and a sorted month across unrelated dates")
    func aggregateAndMonth() async throws {
        let fixture = try Fixture()
        try fixture.insertAggregates(keys: ["2024-02-01", "2024-01-31", "2024-01-02", "2024-01-01"])

        #expect(try await fixture.repository.aggregate(for: "2024-01-02")?.localDateKey == "2024-01-02")
        #expect(try await fixture.repository.aggregate(for: "2024-03-01") == nil)
        let january = try await fixture.repository.aggregates(in: LocalMonth(year: 2024, month: 1))
        #expect(january.map(\.localDateKey) == ["2024-01-01", "2024-01-02", "2024-01-31"])
    }

    @Test("fetches movement and stay data in chronological order with route decoding")
    func segments() async throws {
        let fixture = try Fixture()
        try fixture.insertSegments()

        let movements = try await fixture.repository.movementSegments(for: "2024-01-01")
        let stays = try await fixture.repository.staySegments(for: "2024-01-01")
        #expect(movements.map(\.stableID) == ["early", "late"])
        #expect(movements[0].route == [RouteCoordinate(latitude: 35, longitude: 139)])
        #expect(stays.map(\.stableID) == ["stay-early", "stay-late"])
        #expect(try await fixture.repository.movementSegments(for: "other").isEmpty)
    }

    @Test("rejects an invalid month")
    func invalidMonth() async throws {
        let fixture = try Fixture()
        await #expect(throws: DriveLogError.invalidData) {
            try await fixture.repository.aggregates(in: LocalMonth(year: 2024, month: 13))
        }
    }
}

@MainActor
private struct Fixture {
    let container: ModelContainer
    let repository: SwiftDataDerivedDataRepository
    private let encoder = PropertyListRouteEncoder()
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    init() throws {
        container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        repository = SwiftDataDerivedDataRepository(modelContainer: container)
    }

    func insertAggregates(keys: [String]) throws {
        let context = ModelContext(container)
        for key in keys {
            context.insert(DayAggregateModel(
                localDateKey: key, totalDistanceMeters: 1000,
                totalMovementDurationSeconds: 600, startDate: date, endDate: date,
                locationRecordCount: 2, rejectedLocationCount: 0, mediaCountCache: 1,
                automaticClassificationRawValue: "other", hasValidMovement: true,
                movementSegmentCount: 1, staySegmentCount: 0,
                totalStayDurationSeconds: 0, automotiveDurationSeconds: 0,
                walkingDurationSeconds: 0, sourceRawRevision: 1, generatedAt: date
            ))
        }
        try context.save()
    }

    func insertSegments() throws {
        let context = ModelContext(container)
        let route = try encoder.encode([RouteCoordinate(latitude: 35, longitude: 139)])
        for (id, offset) in [("late", 100.0), ("early", 0.0)] {
            context.insert(MovementSegmentModel(
                stableID: id, localDateKey: "2024-01-01",
                startDate: date.addingTimeInterval(offset), endDate: date.addingTimeInterval(offset + 60),
                distanceMeters: 100, durationSeconds: 60,
                estimatedAverageSpeedMetersPerSecond: nil,
                automaticClassificationRawValue: "other", classificationConfidenceRawValue: "low",
                encodedRouteData: route, labelLatitude: nil, labelLongitude: nil,
                sourceRawRevision: 1, generatedAt: date
            ))
        }
        for (id, offset) in [("stay-late", 100.0), ("stay-early", 0.0)] {
            context.insert(StaySegmentModel(
                stableID: id, localDateKey: "2024-01-01",
                representativeLatitude: 35, representativeLongitude: 139,
                estimatedArrivalDate: date.addingTimeInterval(offset),
                estimatedDepartureDate: date.addingTimeInterval(offset + 60),
                durationSeconds: 60, confidenceRawValue: "low", sourceRawValue: "locationGap",
                isVisibleByAutomaticRule: true, sourceRawRevision: 1, generatedAt: date
            ))
        }
        try context.save()
    }
}
