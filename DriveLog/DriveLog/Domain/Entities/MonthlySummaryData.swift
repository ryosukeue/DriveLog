import Foundation

nonisolated struct MonthlySummaryData: Sendable, Equatable {
    let month: LocalMonth
    let totalDistanceMeters: Double
    let totalMovementDurationSeconds: Double
    let cityRankings: [CityVisitRanking]
}

nonisolated struct CityVisitRanking: Sendable, Equatable, Identifiable {
    let cityName: String
    let visitCount: Int

    var id: String {
        cityName
    }
}
