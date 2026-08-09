import Foundation

nonisolated protocol LoadMonthlyDistanceSeriesUseCase: Sendable {
    func execute(month: LocalMonth) async throws -> MonthlyDistanceSeriesData
}

nonisolated struct DefaultLoadMonthlyDistanceSeriesUseCase: LoadMonthlyDistanceSeriesUseCase {
    private let repository: any DerivedDataRepository
    private let movementFilter: AutomotiveMovementFilter
    private let vehicleAttribution: any VehicleAttributionProviding

    init(
        repository: any DerivedDataRepository,
        movementFilter: AutomotiveMovementFilter = AutomotiveMovementFilter(),
        vehicleAttribution: any VehicleAttributionProviding = EmptyVehicleAttributionProvider()
    ) {
        self.repository = repository
        self.movementFilter = movementFilter
        self.vehicleAttribution = vehicleAttribution
    }

    func execute(month: LocalMonth) async throws -> MonthlyDistanceSeriesData {
        do {
            let dayCount = try numberOfDays(in: month)
            let aggregates = try await repository.aggregates(in: month)
            var distancesByDate: [String: Double] = [:]
            var vehicleDistancesByDate: [String: Double] = [:]
            let selectedVehicle = vehicleAttribution.registeredVehicles().first

            for aggregate in aggregates {
                try Task.checkCancellation()
                let movements = try await repository.movementSegments(
                    for: aggregate.localDateKey
                )
                distancesByDate[aggregate.localDateKey] = distance(
                    aggregate: aggregate,
                    movements: movements
                )
                vehicleDistancesByDate[aggregate.localDateKey] = selectedVehicle.map { vehicle in
                    movementFilter.retained(movements).reduce(0) { result, movement in
                        let share = vehicleAttribution.distanceShares(
                            forStartDate: movement.startDate,
                            endDate: movement.endDate
                        ).first { $0.vehicleID == vehicle.id }?.fraction ?? 0
                        return result + max(0, movement.distanceMeters) * share
                    }
                } ?? 0
            }

            let days = (1 ... dayCount).map { day in
                let key = String(format: "%04d-%02d-%02d", month.year, month.month, day)
                return DailyDistanceData(
                    localDateKey: key,
                    day: day,
                    distanceMeters: distancesByDate[key, default: 0],
                    selectedVehicleDistanceMeters: vehicleDistancesByDate[key, default: 0],
                    selectedVehicleName: selectedVehicle?.name,
                    selectedVehicleColorHex: selectedVehicle?.colorHex
                )
            }
            return MonthlyDistanceSeriesData(month: month, days: days)
        } catch let error as DriveLogError {
            throw error
        } catch is CancellationError {
            throw DriveLogError.cancelled
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_monthly_distance_series")
        }
    }

    private func distance(
        aggregate: DayAggregateData,
        movements: [MovementSegmentData]
    ) -> Double {
        if movements.isEmpty {
            guard aggregate.hasValidMovement,
                  aggregate.automaticClassification != .walkingLike
            else { return 0 }
            return max(0, aggregate.totalDistanceMeters)
        }
        return movementFilter.retained(movements).reduce(0) {
            $0 + max(0, $1.distanceMeters)
        }
    }

    private func numberOfDays(in month: LocalMonth) throws -> Int {
        guard (1 ... 12).contains(month.month) else {
            throw DriveLogError.invalidData
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let firstDay = calendar.date(from: DateComponents(
            year: month.year,
            month: month.month,
            day: 1
        )), let range = calendar.range(of: .day, in: .month, for: firstDay)
        else { throw DriveLogError.invalidData }
        return range.count
    }
}
