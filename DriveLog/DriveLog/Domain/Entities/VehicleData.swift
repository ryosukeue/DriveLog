import Foundation

nonisolated struct VehicleProfile: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let audioRouteUID: String
    let audioRouteName: String
    let colorHex: String
    let createdAt: Date
    let odometerKilometers: Double
    let oilChangeIntervalKilometers: Double
    let lastOilChangeOdometerKilometers: Double
    let usesHighAccuracyTracking: Bool

    var oilChangeDueOdometerKilometers: Double {
        lastOilChangeOdometerKilometers + oilChangeIntervalKilometers
    }

    var oilChangeRemainingKilometers: Double {
        oilChangeDueOdometerKilometers - odometerKilometers
    }

    init(
        id: UUID,
        name: String,
        audioRouteUID: String,
        audioRouteName: String,
        colorHex: String,
        createdAt: Date,
        odometerKilometers: Double = 0,
        oilChangeIntervalKilometers: Double = 5_000,
        lastOilChangeOdometerKilometers: Double = 0,
        usesHighAccuracyTracking: Bool = true
    ) {
        self.id = id
        self.name = name
        self.audioRouteUID = audioRouteUID
        self.audioRouteName = audioRouteName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.odometerKilometers = max(0, odometerKilometers)
        self.oilChangeIntervalKilometers = max(1, oilChangeIntervalKilometers)
        self.lastOilChangeOdometerKilometers = max(0, lastOilChangeOdometerKilometers)
        self.usesHighAccuracyTracking = usesHighAccuracyTracking
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case audioRouteUID
        case audioRouteName
        case colorHex
        case createdAt
        case odometerKilometers
        case oilChangeIntervalKilometers
        case lastOilChangeOdometerKilometers
        case usesHighAccuracyTracking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            audioRouteUID: try container.decode(String.self, forKey: .audioRouteUID),
            audioRouteName: try container.decode(String.self, forKey: .audioRouteName),
            colorHex: try container.decode(String.self, forKey: .colorHex),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            odometerKilometers: try container.decodeIfPresent(
                Double.self,
                forKey: .odometerKilometers
            ) ?? 0,
            oilChangeIntervalKilometers: try container.decodeIfPresent(
                Double.self,
                forKey: .oilChangeIntervalKilometers
            ) ?? 5_000,
            lastOilChangeOdometerKilometers: try container.decodeIfPresent(
                Double.self,
                forKey: .lastOilChangeOdometerKilometers
            ) ?? 0,
            usesHighAccuracyTracking: try container.decodeIfPresent(
                Bool.self,
                forKey: .usesHighAccuracyTracking
            ) ?? true
        )
    }
}

nonisolated enum VehicleOilChangeNotification: Sendable, Equatable {
    case upcoming(vehicleID: UUID, vehicleName: String, remainingKilometers: Int)
    case overdue(vehicleID: UUID, vehicleName: String)
}

nonisolated protocol VehicleProcessedDistanceRecording: Sendable {
    func replaceProcessedDistances(
        for localDateKey: String,
        movements: [MovementSegmentData]
    ) -> [VehicleOilChangeNotification]
}

nonisolated protocol VehicleOilChangeNotifying: Sendable {
    func requestAuthorization() async
    func send(_ notification: VehicleOilChangeNotification) async
}

nonisolated struct EmptyVehicleOilChangeNotifier: VehicleOilChangeNotifying {
    func requestAuthorization() async {}
    func send(_: VehicleOilChangeNotification) async {}
}

nonisolated struct VehicleDistanceSummary: Identifiable, Sendable, Equatable {
    let vehicle: VehicleProfile
    let distanceMeters: Double

    var id: UUID {
        vehicle.id
    }
}

nonisolated struct VehicleDistanceShare: Sendable, Equatable {
    let vehicleID: UUID
    let fraction: Double
}

nonisolated struct AudioRouteDevice: Identifiable, Sendable, Equatable {
    let uid: String
    let name: String
    let portType: String

    var id: String {
        uid
    }
}

nonisolated struct VehicleFuelRecord: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let vehicleID: UUID
    let date: Date
    let liters: Double
    let isFullTank: Bool
    let trackedDistanceKilometers: Double
}

nonisolated struct FuelEconomyInterval: Identifiable, Sendable, Equatable {
    let id: UUID
    let vehicleID: UUID
    let startDate: Date
    let endDate: Date
    let distanceKilometers: Double
    let fuelLiters: Double

    var kilometersPerLiter: Double {
        distanceKilometers / fuelLiters
    }
}

nonisolated enum FuelEconomyCalculator {
    static func intervals(from records: [VehicleFuelRecord]) -> [FuelEconomyInterval] {
        let sorted = records.sorted { first, second in
            if first.date == second.date {
                return first.id.uuidString < second.id.uuidString
            }
            return first.date < second.date
        }
        var previousFullTank: VehicleFuelRecord?
        var accumulatedLiters = 0.0
        var result: [FuelEconomyInterval] = []

        for record in sorted {
            guard record.liters > 0, record.liters.isFinite else { continue }
            guard let intervalStart = previousFullTank else {
                if record.isFullTank {
                    previousFullTank = record
                    accumulatedLiters = 0
                }
                continue
            }

            accumulatedLiters += record.liters
            guard record.isFullTank else { continue }
            let distance = record.trackedDistanceKilometers
                - intervalStart.trackedDistanceKilometers
            if distance > 0, distance.isFinite, accumulatedLiters > 0 {
                result.append(FuelEconomyInterval(
                    id: record.id,
                    vehicleID: record.vehicleID,
                    startDate: intervalStart.date,
                    endDate: record.date,
                    distanceKilometers: distance,
                    fuelLiters: accumulatedLiters
                ))
            }
            previousFullTank = record
            accumulatedLiters = 0
        }
        return result
    }

    static func overallKilometersPerLiter(
        from intervals: [FuelEconomyInterval]
    ) -> Double? {
        let totalDistance = intervals.reduce(0) { $0 + $1.distanceKilometers }
        let totalFuel = intervals.reduce(0) { $0 + $1.fuelLiters }
        guard totalDistance > 0, totalFuel > 0 else { return nil }
        return totalDistance / totalFuel
    }
}

nonisolated protocol VehicleAttributionProviding: Sendable {
    func registeredVehicles() -> [VehicleProfile]
    func vehicle(forStartDate startDate: Date, endDate: Date) -> VehicleProfile?
    func distanceShares(forStartDate startDate: Date, endDate: Date) -> [VehicleDistanceShare]
}

nonisolated struct EmptyVehicleAttributionProvider: VehicleAttributionProviding {
    func registeredVehicles() -> [VehicleProfile] {
        []
    }

    func vehicle(forStartDate _: Date, endDate _: Date) -> VehicleProfile? {
        nil
    }
}

nonisolated extension VehicleAttributionProviding {
    func distanceShares(forStartDate startDate: Date, endDate: Date) -> [VehicleDistanceShare] {
        guard let vehicle = vehicle(forStartDate: startDate, endDate: endDate) else { return [] }
        return [VehicleDistanceShare(vehicleID: vehicle.id, fraction: 1)]
    }

    func distanceBreakdown(
        for movements: [MovementSegmentData]
    ) -> [VehicleDistanceSummary] {
        let vehiclesByID = Dictionary(
            registeredVehicles().map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let distanceByVehicle = movements.reduce(into: [UUID: Double]()) { result, movement in
            let shares = distanceShares(
                forStartDate: movement.startDate,
                endDate: movement.endDate
            )
            for share in shares {
                result[share.vehicleID, default: 0] += max(0, movement.distanceMeters)
                    * min(max(share.fraction, 0), 1)
            }
        }
        return distanceByVehicle.compactMap { id, distance in
            guard let vehicle = vehiclesByID[id], distance > 0 else { return nil }
            return VehicleDistanceSummary(vehicle: vehicle, distanceMeters: distance)
        }.sorted { first, second in
            if first.distanceMeters == second.distanceMeters {
                return first.vehicle.createdAt < second.vehicle.createdAt
            }
            return first.distanceMeters > second.distanceMeters
        }
    }
}
