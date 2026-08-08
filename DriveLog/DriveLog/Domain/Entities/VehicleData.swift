import Foundation

nonisolated struct VehicleProfile: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let audioRouteUID: String
    let audioRouteName: String
    let colorHex: String
    let createdAt: Date
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
