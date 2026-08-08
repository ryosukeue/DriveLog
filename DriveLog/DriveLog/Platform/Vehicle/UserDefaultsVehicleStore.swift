import Foundation
import os

final class UserDefaultsVehicleStore: VehicleAttributionProviding,
    VehicleProcessedDistanceRecording,
    @unchecked Sendable
{
    private struct DetectionInterval: Codable, Sendable, Equatable {
        let vehicleID: UUID
        let startDate: Date
        var endDate: Date?
    }

    private struct StoredState: Codable, Sendable {
        var vehicles: [VehicleProfile] = []
        var intervals: [DetectionInterval] = []
        var dayDistanceCredits: [VehicleDayDistanceCredit] = []
        var oilNotificationStates: [UUID: OilNotificationState] = [:]

        private enum CodingKeys: String, CodingKey {
            case vehicles
            case intervals
            case dayDistanceCredits
            case oilNotificationStates
        }

        init() {}

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            vehicles = try container.decodeIfPresent(
                [VehicleProfile].self,
                forKey: .vehicles
            ) ?? []
            intervals = try container.decodeIfPresent(
                [DetectionInterval].self,
                forKey: .intervals
            ) ?? []
            dayDistanceCredits = try container.decodeIfPresent(
                [VehicleDayDistanceCredit].self,
                forKey: .dayDistanceCredits
            ) ?? []
            oilNotificationStates = try container.decodeIfPresent(
                [UUID: OilNotificationState].self,
                forKey: .oilNotificationStates
            ) ?? [:]
        }
    }

    private struct VehicleDayDistanceCredit: Codable, Sendable {
        let localDateKey: String
        var distanceKilometersByVehicleID: [UUID: Double]
    }

    private struct OilNotificationState: Codable, Sendable {
        var upcomingDueOdometerKilometers: Double?
        var overdueDueOdometerKilometers: Double?
    }

    enum StoreError: Error, Equatable {
        case vehicleLimitReached
        case duplicateAudioRoute
        case vehicleNotFound
        case invalidMaintenanceValues
    }

    private static let storageKey = "vehicle.store.v1"
    private static let maximumIntervals = 4_000
    private static let palette = [
        "#007AFF", "#34C759", "#AF52DE", "#FF9500", "#00C7BE", "#5856D6"
    ]

    private let defaults: UserDefaults
    private let lock: OSAllocatedUnfairLock<StoredState>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let state = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode(StoredState.self, from: $0) }
            ?? StoredState()
        lock = OSAllocatedUnfairLock(initialState: state)
    }

    func registeredVehicles() -> [VehicleProfile] {
        lock.withLock { $0.vehicles.sorted { $0.createdAt < $1.createdAt } }
    }

    @discardableResult
    func addVehicle(
        name: String,
        audioRouteUID: String,
        audioRouteName: String,
        odometerKilometers: Double = 0,
        oilChangeIntervalKilometers: Double = 5_000,
        lastOilChangeOdometerKilometers: Double = 0,
        userVisibleLimit: Int? = nil,
        now: Date = Date()
    ) throws -> VehicleProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.hasValidMaintenanceValues(
            odometerKilometers: odometerKilometers,
            oilChangeIntervalKilometers: oilChangeIntervalKilometers,
            lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers
        ) else {
            throw StoreError.invalidMaintenanceValues
        }
        return try mutate { state in
            if let userVisibleLimit, state.vehicles.count >= userVisibleLimit {
                throw StoreError.vehicleLimitReached
            }
            guard !state.vehicles.contains(where: { $0.audioRouteUID == audioRouteUID }) else {
                throw StoreError.duplicateAudioRoute
            }
            let vehicle = VehicleProfile(
                id: UUID(),
                name: trimmedName.isEmpty ? audioRouteName : trimmedName,
                audioRouteUID: audioRouteUID,
                audioRouteName: audioRouteName,
                colorHex: Self.palette[state.vehicles.count % Self.palette.count],
                createdAt: now,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers
            )
            state.vehicles.append(vehicle)
            return vehicle
        }
    }

    @discardableResult
    func updateVehicle(
        id: UUID,
        name: String,
        odometerKilometers: Double,
        oilChangeIntervalKilometers: Double,
        lastOilChangeOdometerKilometers: Double
    ) throws -> VehicleProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.hasValidMaintenanceValues(
            odometerKilometers: odometerKilometers,
            oilChangeIntervalKilometers: oilChangeIntervalKilometers,
            lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers
        ) else {
            throw StoreError.invalidMaintenanceValues
        }
        return try mutate { state in
            guard let index = state.vehicles.firstIndex(where: { $0.id == id }) else {
                throw StoreError.vehicleNotFound
            }
            let existing = state.vehicles[index]
            let updated = VehicleProfile(
                id: existing.id,
                name: trimmedName.isEmpty ? existing.audioRouteName : trimmedName,
                audioRouteUID: existing.audioRouteUID,
                audioRouteName: existing.audioRouteName,
                colorHex: existing.colorHex,
                createdAt: existing.createdAt,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers
            )
            state.vehicles[index] = updated
            state.oilNotificationStates[id] = nil
            return updated
        }
    }

    func removeVehicle(id: UUID, now: Date = Date()) {
        _ = try? mutate { state in
            state.vehicles.removeAll { $0.id == id }
            state.oilNotificationStates[id] = nil
            for index in state.dayDistanceCredits.indices {
                state.dayDistanceCredits[index].distanceKilometersByVehicleID[id] = nil
            }
            for index in state.intervals.indices
                where state.intervals[index].vehicleID == id && state.intervals[index].endDate == nil
            {
                state.intervals[index].endDate = now
            }
        }
    }

    func updateDetectedAudioRoute(uid: String?, at date: Date = Date()) {
        _ = try? mutate { state in
            let detectedVehicleID = state.vehicles.first { $0.audioRouteUID == uid }?.id
            let activeIndex = state.intervals.lastIndex { $0.endDate == nil }
            let activeVehicleID = activeIndex.map { state.intervals[$0].vehicleID }
            guard detectedVehicleID != activeVehicleID else { return }
            if let activeIndex {
                state.intervals[activeIndex].endDate = date
            }
            if let detectedVehicleID {
                state.intervals.append(DetectionInterval(
                    vehicleID: detectedVehicleID,
                    startDate: date,
                    endDate: nil
                ))
            }
            if state.intervals.count > Self.maximumIntervals {
                state.intervals.removeFirst(state.intervals.count - Self.maximumIntervals)
            }
        }
    }

    func vehicle(forStartDate startDate: Date, endDate: Date) -> VehicleProfile? {
        guard endDate >= startDate else { return nil }
        return lock.withLock { state in
            guard let vehicleID = Self.vehicleID(
                forStartDate: startDate,
                endDate: endDate,
                intervals: state.intervals
            ) else { return nil }
            return state.vehicles.first { $0.id == vehicleID }
        }
    }

    func replaceProcessedDistances(
        for localDateKey: String,
        movements: [MovementSegmentData]
    ) -> [VehicleOilChangeNotification] {
        (try? mutate { state in
            let registeredVehicleIDs = Set(state.vehicles.map(\.id))
            let newDistances = movements.reduce(into: [UUID: Double]()) { result, movement in
                guard let vehicleID = Self.vehicleID(
                    forStartDate: movement.startDate,
                    endDate: movement.endDate,
                    intervals: state.intervals
                ), registeredVehicleIDs.contains(vehicleID) else { return }
                result[vehicleID, default: 0] += max(0, movement.distanceMeters) / 1_000
            }
            let existingIndex = state.dayDistanceCredits.firstIndex {
                $0.localDateKey == localDateKey
            }
            let previousDistances = existingIndex.map {
                state.dayDistanceCredits[$0].distanceKilometersByVehicleID
            } ?? [:]

            if let existingIndex {
                state.dayDistanceCredits[existingIndex].distanceKilometersByVehicleID = newDistances
            } else {
                state.dayDistanceCredits.append(VehicleDayDistanceCredit(
                    localDateKey: localDateKey,
                    distanceKilometersByVehicleID: newDistances
                ))
            }

            var notifications: [VehicleOilChangeNotification] = []
            let affectedVehicleIDs = Set(previousDistances.keys).union(newDistances.keys)
            for vehicleID in affectedVehicleIDs {
                guard let vehicleIndex = state.vehicles.firstIndex(where: { $0.id == vehicleID }) else {
                    continue
                }
                let delta = newDistances[vehicleID, default: 0]
                    - previousDistances[vehicleID, default: 0]
                guard abs(delta) > 0.000_001 else { continue }

                let existing = state.vehicles[vehicleIndex]
                let updated = VehicleProfile(
                    id: existing.id,
                    name: existing.name,
                    audioRouteUID: existing.audioRouteUID,
                    audioRouteName: existing.audioRouteName,
                    colorHex: existing.colorHex,
                    createdAt: existing.createdAt,
                    odometerKilometers: max(0, existing.odometerKilometers + delta),
                    oilChangeIntervalKilometers: existing.oilChangeIntervalKilometers,
                    lastOilChangeOdometerKilometers: existing.lastOilChangeOdometerKilometers
                )
                state.vehicles[vehicleIndex] = updated

                guard delta > 0 else { continue }
                var notificationState = state.oilNotificationStates[vehicleID]
                    ?? OilNotificationState()
                let dueOdometer = updated.oilChangeDueOdometerKilometers
                let remaining = updated.oilChangeRemainingKilometers
                if remaining <= 0,
                   notificationState.overdueDueOdometerKilometers != dueOdometer
                {
                    notifications.append(.overdue(
                        vehicleID: vehicleID,
                        vehicleName: updated.name
                    ))
                    notificationState.overdueDueOdometerKilometers = dueOdometer
                } else if remaining <= 500,
                          notificationState.upcomingDueOdometerKilometers != dueOdometer
                {
                    notifications.append(.upcoming(
                        vehicleID: vehicleID,
                        vehicleName: updated.name,
                        remainingKilometers: max(0, Int(remaining.rounded(.down)))
                    ))
                    notificationState.upcomingDueOdometerKilometers = dueOdometer
                }
                state.oilNotificationStates[vehicleID] = notificationState
            }
            return notifications
        }) ?? []
    }

    private static func vehicleID(
        forStartDate startDate: Date,
        endDate: Date,
        intervals: [DetectionInterval]
    ) -> UUID? {
        intervals.compactMap { interval -> (UUID, TimeInterval)? in
            let intervalEnd = interval.endDate ?? .distantFuture
            let overlapStart = max(startDate, interval.startDate)
            let overlapEnd = min(endDate, intervalEnd)
            let overlap = overlapEnd.timeIntervalSince(overlapStart)
            return overlap > 0 ? (interval.vehicleID, overlap) : nil
        }.max { first, second in
            first.1 < second.1
        }?.0
    }

    private static func hasValidMaintenanceValues(
        odometerKilometers: Double,
        oilChangeIntervalKilometers: Double,
        lastOilChangeOdometerKilometers: Double
    ) -> Bool {
        odometerKilometers.isFinite
            && oilChangeIntervalKilometers.isFinite
            && lastOilChangeOdometerKilometers.isFinite
            && odometerKilometers >= 0
            && oilChangeIntervalKilometers > 0
            && lastOilChangeOdometerKilometers >= 0
            && lastOilChangeOdometerKilometers <= odometerKilometers
    }

    private func mutate<Result>(
        _ body: (inout StoredState) throws -> Result
    ) throws -> Result {
        let output = try lock.withLock { state in
            let result = try body(&state)
            return (result, try? JSONEncoder().encode(state))
        }
        if let encoded = output.1 {
            defaults.set(encoded, forKey: Self.storageKey)
        }
        return output.0
    }
}
