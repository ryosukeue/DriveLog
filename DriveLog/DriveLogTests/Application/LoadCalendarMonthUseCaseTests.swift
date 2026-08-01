@testable import DriveLog
import Foundation
import Testing

@Suite("Load calendar month use case")
struct LoadCalendarMonthUseCaseTests {
    private let month = LocalMonth(year: 2024, month: 1)

    @Test("returns sorted valid and invalid calendar days")
    func days() async throws {
        let repository = CalendarDerivedRepositoryFake(aggregates: [
            aggregate(day: "2024-01-20", distance: 500, isValid: false),
            aggregate(day: "2024-01-02", distance: 1500, isValid: true)
        ])

        let result = try await DefaultLoadCalendarMonthUseCase(repository: repository)
            .execute(month: month)

        #expect(result.month == month)
        #expect(result.days == [
            CalendarDayData(
                localDateKey: "2024-01-02", day: 2,
                totalDistanceMeters: 1500, hasValidMovement: true
            ),
            CalendarDayData(
                localDateKey: "2024-01-20", day: 20,
                totalDistanceMeters: nil, hasValidMovement: false
            )
        ])
    }

    @Test("returns an empty month")
    func empty() async throws {
        let useCase = DefaultLoadCalendarMonthUseCase(
            repository: CalendarDerivedRepositoryFake(aggregates: [])
        )

        let result = try await useCase.execute(month: month)

        #expect(result == CalendarMonthData(month: month, days: []))
    }

    @Test("does not use a non-automotive aggregate fallback")
    func excludesNonAutomotiveFallback() async throws {
        let useCase = DefaultLoadCalendarMonthUseCase(
            repository: CalendarDerivedRepositoryFake(aggregates: [
                aggregate(
                    day: "2024-01-03",
                    distance: 2500,
                    isValid: true,
                    classification: .walkingLike
                )
            ])
        )

        let result = try await useCase.execute(month: month)

        #expect(result.days == [
            CalendarDayData(
                localDateKey: "2024-01-03",
                day: 3,
                totalDistanceMeters: nil,
                hasValidMovement: false
            )
        ])
    }

    @Test("uses an other aggregate fallback")
    func includesOtherFallback() async throws {
        let useCase = DefaultLoadCalendarMonthUseCase(
            repository: CalendarDerivedRepositoryFake(aggregates: [
                aggregate(
                    day: "2024-01-04",
                    distance: 2500,
                    isValid: true,
                    classification: .other
                )
            ])
        )

        let result = try await useCase.execute(month: month)

        #expect(result.days == [
            CalendarDayData(
                localDateKey: "2024-01-04",
                day: 4,
                totalDistanceMeters: 2500,
                hasValidMovement: true
            )
        ])
    }

    @Test("rejects an invalid local date key")
    func invalidDateKey() async {
        let useCase = DefaultLoadCalendarMonthUseCase(
            repository: CalendarDerivedRepositoryFake(aggregates: [
                aggregate(day: "invalid", distance: 1500, isValid: true)
            ])
        )

        await #expect(throws: DriveLogError.invalidData) {
            try await useCase.execute(month: month)
        }
    }

    @Test("preserves repository DriveLogError")
    func repositoryError() async {
        let useCase = DefaultLoadCalendarMonthUseCase(
            repository: CalendarDerivedRepositoryFake(
                aggregates: [], error: DriveLogError.persistenceFailure(code: "fixture")
            )
        )

        await #expect(throws: DriveLogError.persistenceFailure(code: "fixture")) {
            try await useCase.execute(month: month)
        }
    }
}

private struct CalendarDerivedRepositoryFake: DerivedDataRepository {
    let storedAggregates: [DayAggregateData]
    let error: DriveLogError?

    init(aggregates: [DayAggregateData], error: DriveLogError? = nil) {
        storedAggregates = aggregates
        self.error = error
    }

    func aggregates(in _: LocalMonth) throws -> [DayAggregateData] {
        if let error {
            throw error
        }
        return storedAggregates
    }

    func aggregate(for _: String) -> DayAggregateData? {
        nil
    }

    func movementSegments(for _: String) -> [MovementSegmentData] {
        []
    }

    func staySegments(for _: String) -> [StaySegmentData] {
        []
    }

    func replaceDerivedData(for _: String, result _: DayProcessingResult, processedRevision _: Int) {}
    func deleteDerivedData(for _: String) {}
}

private nonisolated func aggregate(
    day: String,
    distance: Double,
    isValid: Bool,
    classification: AutomaticMovementType = .automotiveLike
) -> DayAggregateData {
    DayAggregateData(
        localDateKey: day, totalDistanceMeters: distance, totalMovementDurationSeconds: 60,
        startDate: nil, endDate: nil, locationRecordCount: 2, rejectedLocationCount: 0,
        mediaCountCache: 0, automaticClassification: classification, hasValidMovement: isValid,
        movementSegmentCount: 1, staySegmentCount: 0, totalStayDurationSeconds: 0,
        automotiveDurationSeconds: 0, walkingDurationSeconds: 60, sourceRawRevision: 1,
        generatedAt: Date(timeIntervalSince1970: 0)
    )
}
