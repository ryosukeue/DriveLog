import Foundation

nonisolated protocol LoadMonthlySummaryUseCase: Sendable {
    func execute(month: LocalMonth) async throws -> MonthlySummaryData
}

nonisolated struct DefaultLoadMonthlySummaryUseCase: LoadMonthlySummaryUseCase {
    private let repository: any DerivedDataRepository
    private let cityNameProvider: any CityNameProviding
    private let movementFilter: AutomotiveMovementFilter
    private let vehicleAttribution: any VehicleAttributionProviding

    init(
        repository: any DerivedDataRepository,
        cityNameProvider: any CityNameProviding,
        movementFilter: AutomotiveMovementFilter = AutomotiveMovementFilter(),
        vehicleAttribution: any VehicleAttributionProviding = EmptyVehicleAttributionProvider()
    ) {
        self.repository = repository
        self.cityNameProvider = cityNameProvider
        self.movementFilter = movementFilter
        self.vehicleAttribution = vehicleAttribution
    }

    func execute(month: LocalMonth) async throws -> MonthlySummaryData {
        do {
            let aggregates = try await repository.aggregates(in: month)
            var totalDistance = 0.0
            var totalDuration = 0.0
            var allMovements: [MovementSegmentData] = []
            var cityCounts: [String: Int] = [:]
            let geocodeCache = CityGeocodeCache(provider: cityNameProvider)

            for aggregate in aggregates.sorted(by: { $0.localDateKey < $1.localDateKey }) {
                try Task.checkCancellation()
                let contribution = try await contribution(
                    for: aggregate,
                    geocodeCache: geocodeCache
                )
                totalDistance += contribution.distance
                totalDuration += contribution.duration
                allMovements.append(contentsOf: contribution.movements)
                for city in contribution.cities {
                    cityCounts[city, default: 0] += 1
                }
            }

            let rankings = cityCounts
                .map { CityVisitRanking(cityName: $0.key, visitCount: $0.value) }
                .sorted {
                    if $0.visitCount == $1.visitCount {
                        return $0.cityName < $1.cityName
                    }
                    return $0.visitCount > $1.visitCount
                }
                .prefix(5)
            return MonthlySummaryData(
                month: month,
                totalDistanceMeters: totalDistance,
                totalMovementDurationSeconds: totalDuration,
                cityRankings: Array(rankings),
                vehicleDistances: vehicleAttribution.distanceBreakdown(for: allMovements)
            )
        } catch let error as DriveLogError {
            throw error
        } catch is CancellationError {
            throw DriveLogError.cancelled
        } catch {
            throw DriveLogError.persistenceFailure(code: "load_monthly_summary")
        }
    }

    private func contribution(
        for aggregate: DayAggregateData,
        geocodeCache: CityGeocodeCache
    ) async throws -> MonthlySummaryContribution {
        let movements = try await repository.movementSegments(for: aggregate.localDateKey)
        let retainedMovements = movementFilter.retained(movements)
        let usesStoredAggregate = movements.isEmpty
        let distance = usesStoredAggregate ? aggregate.totalDistanceMeters :
            retainedMovements.reduce(0) { $0 + $1.distanceMeters }
        let duration = usesStoredAggregate ? aggregate.totalMovementDurationSeconds :
            retainedMovements.reduce(0) { $0 + $1.durationSeconds }
        let hasValidStoredAggregate = aggregate.hasValidMovement &&
            aggregate.automaticClassification != .walkingLike
        let hasUsableMovements = !retainedMovements.isEmpty
        guard (usesStoredAggregate && hasValidStoredAggregate) ||
            (!usesStoredAggregate && hasUsableMovements)
        else {
            return MonthlySummaryContribution(
                distance: 0,
                duration: 0,
                cities: [],
                movements: []
            )
        }
        let stays = try await repository.staySegments(for: aggregate.localDateKey)
        let cities = await collectCities(stays: stays, geocodeCache: geocodeCache)
        return MonthlySummaryContribution(
            distance: distance,
            duration: duration,
            cities: cities,
            movements: retainedMovements
        )
    }

    private func collectCities(
        stays: [StaySegmentData],
        geocodeCache: CityGeocodeCache
    ) async -> [String] {
        var cities: [String] = []
        for stay in stays where stay.isVisibleByAutomaticRule {
            if let city = await geocodeCache.cityName(for: stay.representativeCoordinate), !city.isEmpty {
                cities.append(city)
            }
        }
        return cities
    }
}

private struct MonthlySummaryContribution: Sendable {
    let distance: Double
    let duration: Double
    let cities: [String]
    let movements: [MovementSegmentData]
}

private actor CityGeocodeCache {
    private let provider: any CityNameProviding
    private var values: [String: String?] = [:]

    init(provider: any CityNameProviding) {
        self.provider = provider
    }

    func cityName(for coordinate: RouteCoordinate) async -> String? {
        let key = "\(coordinate.latitude.rounded(toPlaces: 4)),\(coordinate.longitude.rounded(toPlaces: 4))"
        if let cached = values[key] {
            return cached
        }
        let city = await provider.cityName(for: coordinate)
        values[key] = city
        return city
    }
}

private extension Double {
    nonisolated func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10, Double(places))
        return (self * factor).rounded() / factor
    }
}
