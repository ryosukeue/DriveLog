nonisolated protocol LoadCalendarMonthUseCase: Sendable {
    func execute(month: LocalMonth) async throws -> CalendarMonthData
}

nonisolated struct DefaultLoadCalendarMonthUseCase: LoadCalendarMonthUseCase {
    private let repository: any DerivedDataRepository

    init(repository: any DerivedDataRepository) {
        self.repository = repository
    }

    func execute(month: LocalMonth) async throws -> CalendarMonthData {
        do {
            let aggregates = try await repository.aggregates(in: month)
            let days = try await aggregates
                .sorted { $0.localDateKey < $1.localDateKey }
                .asyncMap(calendarDay)
            return CalendarMonthData(month: month, days: days)
        } catch let error as DriveLogError {
            throw error
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_calendar_month")
        }
    }

    private func calendarDay(from aggregate: DayAggregateData) async throws -> CalendarDayData {
        guard let component = aggregate.localDateKey.split(separator: "-").last,
              let day = Int(component),
              (1 ... 31).contains(day)
        else {
            throw DriveLogError.invalidData
        }
        let movements = try await repository.movementSegments(for: aggregate.localDateKey)
        let filteredMovements = AutomotiveMovementFilter().retained(movements)
        let usesStoredAggregate = movements.isEmpty
        let distance = usesStoredAggregate
            ? aggregate.totalDistanceMeters
            : filteredMovements.reduce(0) { $0 + $1.distanceMeters }
        let hasValidMovement = !usesStoredAggregate
            ? distance >= ProcessingConfiguration.mvp.dayValidation.minimumValidDayDistance &&
            filteredMovements.count >=
            ProcessingConfiguration.mvp.dayValidation.minimumValidMovementSegments &&
            aggregate.locationRecordCount >=
            ProcessingConfiguration.mvp.dayValidation.minimumValidLocationPointCount
            : aggregate.hasValidMovement && aggregate.automaticClassification == .automotiveLike
        return CalendarDayData(
            localDateKey: aggregate.localDateKey,
            day: day,
            totalDistanceMeters: hasValidMovement ? distance : nil,
            hasValidMovement: hasValidMovement
        )
    }
}

private extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async throws -> [T] {
        var values: [T] = []
        values.reserveCapacity(underestimatedCount)
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}
