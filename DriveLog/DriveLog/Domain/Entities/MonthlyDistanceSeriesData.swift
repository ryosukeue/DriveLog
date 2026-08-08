import Foundation

nonisolated struct DailyDistanceData: Identifiable, Sendable, Equatable {
    let localDateKey: String
    let day: Int
    let distanceMeters: Double
    let selectedVehicleDistanceMeters: Double
    let selectedVehicleName: String?
    let selectedVehicleColorHex: String?

    init(
        localDateKey: String,
        day: Int,
        distanceMeters: Double,
        selectedVehicleDistanceMeters: Double = 0,
        selectedVehicleName: String? = nil,
        selectedVehicleColorHex: String? = nil
    ) {
        self.localDateKey = localDateKey
        self.day = day
        self.distanceMeters = distanceMeters
        self.selectedVehicleDistanceMeters = min(
            max(0, selectedVehicleDistanceMeters),
            max(0, distanceMeters)
        )
        self.selectedVehicleName = selectedVehicleName
        self.selectedVehicleColorHex = selectedVehicleColorHex
    }

    var otherVehicleDistanceMeters: Double {
        max(0, distanceMeters - selectedVehicleDistanceMeters)
    }

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

    var selectedVehicle: (name: String, colorHex: String)? {
        days.compactMap { day -> (name: String, colorHex: String)? in
            guard let name = day.selectedVehicleName,
                  let colorHex = day.selectedVehicleColorHex
            else { return nil }
            return (name, colorHex)
        }.first
    }
}
