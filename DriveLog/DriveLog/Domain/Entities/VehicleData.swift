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
        lastOilChangeOdometerKilometers: Double = 0
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
            ) ?? 0
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

nonisolated struct AudioRouteDevice: Identifiable, Sendable, Equatable {
    let uid: String
    let name: String
    let portType: String

    var id: String {
        uid
    }
}

nonisolated protocol VehicleAttributionProviding: Sendable {
    func registeredVehicles() -> [VehicleProfile]
    func vehicle(forStartDate startDate: Date, endDate: Date) -> VehicleProfile?
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
    func distanceBreakdown(
        for movements: [MovementSegmentData]
    ) -> [VehicleDistanceSummary] {
        let vehiclesByID = Dictionary(
            registeredVehicles().map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let distanceByVehicle = movements.reduce(into: [UUID: Double]()) { result, movement in
            guard let vehicle = vehicle(
                forStartDate: movement.startDate,
                endDate: movement.endDate
            ) else { return }
            result[vehicle.id, default: 0] += max(0, movement.distanceMeters)
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
