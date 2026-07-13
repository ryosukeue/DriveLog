@testable import DriveLog
import Foundation
import SwiftData
import Testing

@Suite("Derived data replacement integration")
@MainActor
struct DerivedDataReplacementTests {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("replaces all three derived types without orphans")
    func replacement() async throws {
        let fixture = try Fixture()
        try await fixture.repository.replaceDerivedData(
            for: "2024-01-01", result: result(id: "old", revision: 1), processedRevision: 1
        )
        try await fixture.repository.replaceDerivedData(
            for: "2024-01-01", result: result(id: "new", revision: 2), processedRevision: 2
        )

        #expect(try await fixture.repository.aggregate(for: "2024-01-01")?.sourceRawRevision == 2)
        #expect(try await fixture.repository.movementSegments(for: "2024-01-01").map(\.stableID) == ["new"])
        #expect(try await fixture.repository.staySegments(for: "2024-01-01").map(\.stableID) == ["stay-new"])
    }

    @Test("keeps old data when route encoding fails before deletion")
    func encodingFailure() async throws {
        let fixture = try Fixture()
        try await fixture.repository.replaceDerivedData(
            for: "2024-01-01", result: result(id: "old", revision: 1), processedRevision: 1
        )
        let failing = SwiftDataDerivedDataRepository(
            modelContainer: fixture.container, routeEncoding: FailingRouteEncoder()
        )

        await #expect(throws: DriveLogError.persistenceFailure(code: "replace_derived_data")) {
            try await failing.replaceDerivedData(
                for: "2024-01-01", result: result(id: "new", revision: 2), processedRevision: 2
            )
        }
        #expect(try await fixture.repository.movementSegments(for: "2024-01-01").map(\.stableID) == ["old"])
    }

    @Test("rejects inconsistent revision and deletes only one day")
    func validationAndDeletion() async throws {
        let fixture = try Fixture()
        try await fixture.repository.replaceDerivedData(
            for: "2024-01-01", result: result(id: "one", revision: 1), processedRevision: 1
        )
        try await fixture.repository.replaceDerivedData(
            for: "2024-01-02", result: result(id: "two", day: "2024-01-02", revision: 1),
            processedRevision: 1
        )
        await #expect(throws: DriveLogError.persistenceFailure(code: "replace_derived_data")) {
            try await fixture.repository.replaceDerivedData(
                for: "2024-01-01", result: result(id: "bad", revision: 2), processedRevision: 1
            )
        }
        try await fixture.repository.deleteDerivedData(for: "2024-01-01")
        try await fixture.repository.deleteDerivedData(for: "2024-01-01")

        #expect(try await fixture.repository.aggregate(for: "2024-01-01") == nil)
        #expect(try await fixture.repository.aggregate(for: "2024-01-02") != nil)
    }

    private func result(
        id: String,
        day: String = "2024-01-01",
        revision: Int
    ) -> DayProcessingResult {
        let aggregate = DayAggregateData(
            localDateKey: day, totalDistanceMeters: 100, totalMovementDurationSeconds: 60,
            startDate: date, endDate: date.addingTimeInterval(60), locationRecordCount: 2,
            rejectedLocationCount: 0, mediaCountCache: 0, automaticClassification: .other,
            hasValidMovement: false, movementSegmentCount: 1, staySegmentCount: 1,
            totalStayDurationSeconds: 60, automotiveDurationSeconds: 0, walkingDurationSeconds: 0,
            sourceRawRevision: revision, generatedAt: date
        )
        let movement = MovementSegmentData(
            stableID: id, localDateKey: day, startDate: date, endDate: date.addingTimeInterval(60),
            distanceMeters: 100, durationSeconds: 60, estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: .other, classificationConfidence: .low,
            route: [RouteCoordinate(latitude: 35, longitude: 139)], labelCoordinate: nil,
            sourceRawRevision: revision, generatedAt: date
        )
        let stay = StaySegmentData(
            stableID: "stay-\(id)", localDateKey: day,
            representativeCoordinate: RouteCoordinate(latitude: 35, longitude: 139),
            estimatedArrivalDate: date, estimatedDepartureDate: date.addingTimeInterval(60),
            durationSeconds: 60, confidence: .low, source: .locationGap,
            isVisibleByAutomaticRule: true, sourceRawRevision: revision, generatedAt: date
        )
        return DayProcessingResult(aggregate: aggregate, movements: [movement], stays: [stay])
    }
}

@MainActor
private struct Fixture {
    let container: ModelContainer
    let repository: SwiftDataDerivedDataRepository

    init() throws {
        container = try DriveLogModelContainerFactory.make(isStoredInMemoryOnly: true)
        repository = SwiftDataDerivedDataRepository(modelContainer: container)
    }
}

private struct FailingRouteEncoder: RouteEncoding {
    func encode(_: [RouteCoordinate]) throws -> Data {
        throw DriveLogError.invalidData
    }

    func decode(_: Data) throws -> [RouteCoordinate] {
        throw DriveLogError.invalidData
    }
}
