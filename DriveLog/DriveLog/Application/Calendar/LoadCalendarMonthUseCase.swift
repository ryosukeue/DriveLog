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
            let days = try aggregates
                .sorted { $0.localDateKey < $1.localDateKey }
                .map(calendarDay)
            return CalendarMonthData(month: month, days: days)
        } catch let error as DriveLogError {
            throw error
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_calendar_month")
        }
    }

    private func calendarDay(from aggregate: DayAggregateData) throws -> CalendarDayData {
        guard let component = aggregate.localDateKey.split(separator: "-").last,
              let day = Int(component),
              (1 ... 31).contains(day)
        else {
            throw DriveLogError.invalidData
        }
        return CalendarDayData(
            localDateKey: aggregate.localDateKey,
            day: day,
            totalDistanceMeters: aggregate.hasValidMovement
                ? aggregate.totalDistanceMeters : nil,
            hasValidMovement: aggregate.hasValidMovement
        )
    }
}
