import Foundation

nonisolated struct DailyDistanceData: Identifiable, Sendable, Equatable {
    let localDateKey: String
    let day: Int
    let distanceMeters: Double

    var id: String {
        localDateKey
    }
}

nonisolated struct MonthlyDistanceSeriesData: Sendable, Equatable {
    let month: LocalMonth
    let days: [DailyDistanceData]

    var totalDistanceMeters: Double {
        days.reduce(0) { $0 + $1.distanceMeters }
    }

    var activeDayCount: Int {
        days.count { $0.distanceMeters > 0 }
    }
}
