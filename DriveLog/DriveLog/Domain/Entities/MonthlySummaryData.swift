import Foundation

nonisolated struct MonthlySummaryData: Sendable, Equatable {
    let month: LocalMonth
    let totalDistanceMeters: Double
    let totalMovementDurationSeconds: Double
    let cityRankings: [CityVisitRanking]
    let vehicleDistances: [VehicleDistanceSummary]

    init(
        month: LocalMonth,
        totalDistanceMeters: Double,
        totalMovementDurationSeconds: Double,
        cityRankings: [CityVisitRanking],
        vehicleDistances: [VehicleDistanceSummary] = []
    ) {
        self.month = month
        self.totalDistanceMeters = totalDistanceMeters
        self.totalMovementDurationSeconds = totalMovementDurationSeconds
        self.cityRankings = cityRankings
        self.vehicleDistances = vehicleDistances
    }
}

nonisolated struct CityVisitRanking: Sendable, Equatable, Identifiable {
    let cityName: String
    let visitCount: Int

    var id: String {
        cityName
    }
}
