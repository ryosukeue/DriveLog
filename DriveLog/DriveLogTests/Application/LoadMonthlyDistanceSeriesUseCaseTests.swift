@testable import DriveLog
import Foundation
import Testing

@Suite("Load monthly distance series use case")
struct LoadMonthlyDistanceSeriesUseCaseTests {
    @Test("fills every calendar day and excludes walking segments")
    func dailySeries() async throws {
        let first = "2026-02-01"
        let second = "2026-02-02"
        let repository = DistanceSeriesRepositoryFake(
            aggregates: [aggregate(day: first), aggregate(day: second)],
            movements: [
                first: [
                    movement(id: "car", day: first, distance: 4000, type: .automotiveLike),
                    movement(id: "walk", day: first, distance: 800, type: .walkingLike)
                ],
                second: []
            ]
        )
        let useCase = DefaultLoadMonthlyDistanceSeriesUseCase(repository: repository)

        let result = try await useCase.execute(month: LocalMonth(year: 2026, month: 2))

        #expect(result.days.count == 28)
        #expect(result.days[0].distanceMeters == 4000)
        #expect(result.days[1].distanceMeters == 5000)
        #expect(result.days[2].distanceMeters == 0)
        #expect(result.totalDistanceMeters == 9000)
        #expect(result.activeDayCount == 2)
    }

    @Test("does not use a walking-only stored aggregate")
    func walkingAggregate() async throws {
        let day = "2026-07-03"
        let repository = DistanceSeriesRepositoryFake(
            aggregates: [aggregate(day: day, type: .walkingLike)],
            movements: [:]
        )

        let result = try await DefaultLoadMonthlyDistanceSeriesUseCase(
            repository: repository
        ).execute(month: LocalMonth(year: 2026, month: 7))

        #expect(result.days[2].distanceMeters == 0)
        #expect(result.activeDayCount == 0)
    }

    private func aggregate(
        day: String,
        type: AutomaticMovementType = .automotiveLike
    ) -> DayAggregateData {
        DayAggregateData(
            localDateKey: day,
            totalDistanceMeters: 5000,
            totalMovementDurationSeconds: 600,
            startDate: nil,
            endDate: nil,
            locationRecordCount: 20,
            rejectedLocationCount: 0,
            mediaCountCache: 0,
            automaticClassification: type,
            hasValidMovement: true,
            movementSegmentCount: 1,
            staySegmentCount: 0,
            totalStayDurationSeconds: 0,
            automotiveDurationSeconds: 600,
            walkingDurationSeconds: 0,
            sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func movement(
        id: String,
        day: String,
        distance: Double,
        type: AutomaticMovementType
    ) -> MovementSegmentData {
        MovementSegmentData(
            stableID: id,
            localDateKey: day,
            startDate: Date(timeIntervalSince1970: 0),
            endDate: Date(timeIntervalSince1970: 600),
            distanceMeters: distance,
            durationSeconds: 600,
            estimatedAverageSpeedMetersPerSecond: nil,
            automaticClassification: type,
            classificationConfidence: .medium,
            route: [],
            labelCoordinate: nil,
            sourceRawRevision: 1,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }
}

private struct DistanceSeriesRepositoryFake: DerivedDataRepository {
    let storedAggregates: [DayAggregateData]
    let storedMovements: [String: [MovementSegmentData]]

    init(
        aggregates: [DayAggregateData],
        movements: [String: [MovementSegmentData]]
    ) {
        storedAggregates = aggregates
        storedMovements = movements
    }

    func aggregate(for _: String) -> DayAggregateData? {
        nil
    }

    func aggregates(in _: LocalMonth) -> [DayAggregateData] {
        storedAggregates
    }

    func movementSegments(for key: String) -> [MovementSegmentData] {
        storedMovements[key, default: []]
    }

    func staySegments(for _: String) -> [StaySegmentData] {
        []
    }

    func replaceDerivedData(
        for _: String,
        result _: DayProcessingResult,
        processedRevision _: Int
    ) {}

    func deleteDerivedData(
        for _: String
    ) {}
}
