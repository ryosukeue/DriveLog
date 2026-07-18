@testable import DriveLog
import Foundation
import Testing

@Suite("Load monthly summary use case")
struct LoadMonthlySummaryUseCaseTests {
    @Test("sums automotive movement and ranks stay cities")
    func summary() async throws {
        let month = LocalMonth(year: 2026, month: 7)
        let repository = MonthlySummaryRepositoryFake(
            aggregates: [
                aggregate(day: "2026-07-01"),
                aggregate(day: "2026-07-02")
            ],
            movements: [
                "2026-07-01": [
                    movement(id: "car-1", distance: 1000, duration: 600),
                    movement(id: "walk-1", distance: 2000, duration: 1200, classification: .walkingLike)
                ],
                "2026-07-02": [movement(id: "car-2", distance: 2000, duration: 600)]
            ],
            stays: [
                "2026-07-01": [stay(id: "stay-1", longitude: 139.0)],
                "2026-07-02": [
                    stay(id: "stay-2", longitude: 139.0),
                    stay(id: "stay-3", longitude: 135.0)
                ]
            ]
        )
        let useCase = DefaultLoadMonthlySummaryUseCase(
            repository: repository,
            cityNameProvider: FakeCityNameProvider()
        )

        let result = try await useCase.execute(month: month)

        #expect(result.totalDistanceMeters == 3000)
        #expect(result.totalMovementDurationSeconds == 1200)
        #expect(result.cityRankings == [
            CityVisitRanking(cityName: "東京", visitCount: 2),
            CityVisitRanking(cityName: "大阪", visitCount: 1)
        ])
    }

    @Test("city lookup failure does not discard movement totals")
    func cityLookupFailure() async throws {
        let month = LocalMonth(year: 2026, month: 7)
        let repository = MonthlySummaryRepositoryFake(
            aggregates: [aggregate(day: "2026-07-01")],
            movements: ["2026-07-01": [movement(id: "car", distance: 1200, duration: 600)]],
            stays: ["2026-07-01": [stay(id: "stay", longitude: 140.0)]]
        )

        let result = try await DefaultLoadMonthlySummaryUseCase(
            repository: repository,
            cityNameProvider: NilCityNameProvider()
        ).execute(month: month)

        #expect(result.totalDistanceMeters == 1200)
        #expect(result.totalMovementDurationSeconds == 600)
        #expect(result.cityRankings.isEmpty)
    }
}

private struct FakeCityNameProvider: CityNameProviding {
    func cityName(for coordinate: RouteCoordinate) async -> String? {
        coordinate.longitude < 137 ? "大阪" : "東京"
    }
}

private struct NilCityNameProvider: CityNameProviding {
    func cityName(for _: RouteCoordinate) async -> String? {
        nil
    }
}

private struct MonthlySummaryRepositoryFake: DerivedDataRepository {
    let storedAggregates: [DayAggregateData]
    let storedMovements: [String: [MovementSegmentData]]
    let storedStays: [String: [StaySegmentData]]

    init(
        aggregates: [DayAggregateData],
        movements: [String: [MovementSegmentData]],
        stays: [String: [StaySegmentData]]
    ) {
        storedAggregates = aggregates
        storedMovements = movements
        storedStays = stays
    }

    func aggregates(in _: LocalMonth) -> [DayAggregateData] {
        storedAggregates
    }

    func aggregate(for _: String) -> DayAggregateData? {
        nil
    }

    func movementSegments(for localDateKey: String) -> [MovementSegmentData] {
        storedMovements[localDateKey, default: []]
    }

    func staySegments(for localDateKey: String) -> [StaySegmentData] {
        storedStays[localDateKey, default: []]
    }

    func replaceDerivedData(for _: String, result _: DayProcessingResult, processedRevision _: Int) {}
    func deleteDerivedData(for _: String) {}
}

private func aggregate(day: String) -> DayAggregateData {
    DayAggregateData(
        localDateKey: day, totalDistanceMeters: 3000,
        totalMovementDurationSeconds: 1800, startDate: nil, endDate: nil,
        locationRecordCount: 10, rejectedLocationCount: 0, mediaCountCache: 0,
        automaticClassification: .automotiveLike, hasValidMovement: true,
        movementSegmentCount: 2, staySegmentCount: 1, totalStayDurationSeconds: 300,
        automotiveDurationSeconds: 600, walkingDurationSeconds: 1200,
        sourceRawRevision: 1, generatedAt: Date(timeIntervalSince1970: 0)
    )
}

private func movement(
    id: String,
    distance: Double,
    duration: TimeInterval,
    classification: AutomaticMovementType = .automotiveLike
) -> MovementSegmentData {
    MovementSegmentData(
        stableID: id, localDateKey: "2026-07-01",
        startDate: Date(timeIntervalSince1970: 0),
        endDate: Date(timeIntervalSince1970: duration),
        distanceMeters: distance, durationSeconds: duration,
        estimatedAverageSpeedMetersPerSecond: 10,
        automaticClassification: classification, classificationConfidence: .medium,
        route: [], labelCoordinate: nil, sourceRawRevision: 1,
        generatedAt: Date(timeIntervalSince1970: 0)
    )
}

private func stay(id: String, longitude: Double) -> StaySegmentData {
    StaySegmentData(
        stableID: id, localDateKey: "2026-07-01",
        representativeCoordinate: RouteCoordinate(latitude: 35, longitude: longitude),
        estimatedArrivalDate: Date(timeIntervalSince1970: 0),
        estimatedDepartureDate: Date(timeIntervalSince1970: 300),
        durationSeconds: 300, confidence: .medium, source: .combined,
        isVisibleByAutomaticRule: true, sourceRawRevision: 1,
        generatedAt: Date(timeIntervalSince1970: 0)
    )
}
