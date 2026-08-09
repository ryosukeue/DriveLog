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
        var fuelRecords: [VehicleFuelRecord] = []
        var fuelTrackingDistanceKilometersByVehicleID: [UUID: Double] = [:]

        private enum CodingKeys: String, CodingKey {
            case vehicles
            case intervals
            case dayDistanceCredits
            case oilNotificationStates
            case fuelRecords
            case fuelTrackingDistanceKilometersByVehicleID
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
            fuelRecords = try container.decodeIfPresent(
                [VehicleFuelRecord].self,
                forKey: .fuelRecords
            ) ?? []
            fuelTrackingDistanceKilometersByVehicleID = try container.decodeIfPresent(
                [UUID: Double].self,
                forKey: .fuelTrackingDistanceKilometersByVehicleID
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
        case invalidFuelAmount
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
        usesHighAccuracyTracking: Bool = true,
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
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers,
                usesHighAccuracyTracking: usesHighAccuracyTracking
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
        lastOilChangeOdometerKilometers: Double,
        usesHighAccuracyTracking: Bool = true
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
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers,
                usesHighAccuracyTracking: usesHighAccuracyTracking
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
            state.fuelRecords.removeAll { $0.vehicleID == id }
            state.fuelTrackingDistanceKilometersByVehicleID[id] = nil
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

    func fuelRecords(for vehicleID: UUID) -> [VehicleFuelRecord] {
        lock.withLock { state in
            state.fuelRecords
                .filter { $0.vehicleID == vehicleID }
                .sorted { $0.date < $1.date }
        }
    }

    func fuelTrackingDistanceKilometers(for vehicleID: UUID) -> Double {
        lock.withLock {
            max(0, $0.fuelTrackingDistanceKilometersByVehicleID[vehicleID, default: 0])
        }
    }

    func addFuelTrackingDistance(
        _ distanceKilometers: Double,
        for vehicleID: UUID
    ) {
        guard distanceKilometers.isFinite, distanceKilometers > 0 else { return }
        _ = try? mutate { state in
            guard state.vehicles.contains(where: { $0.id == vehicleID }) else { return }
            state.fuelTrackingDistanceKilometersByVehicleID[vehicleID, default: 0]
                += distanceKilometers
        }
    }

    @discardableResult
    func addFuelRecord(
        vehicleID: UUID,
        liters: Double,
        isFullTank: Bool,
        date: Date = Date()
    ) throws -> VehicleFuelRecord {
        guard liters.isFinite, liters > 0 else {
            throw StoreError.invalidFuelAmount
        }
        return try mutate { state in
            guard state.vehicles.contains(where: { $0.id == vehicleID }) else {
                throw StoreError.vehicleNotFound
            }
            let record = VehicleFuelRecord(
                id: UUID(),
                vehicleID: vehicleID,
                date: date,
                liters: liters,
                isFullTank: isFullTank,
                trackedDistanceKilometers: max(
                    0,
                    state.fuelTrackingDistanceKilometersByVehicleID[vehicleID, default: 0]
                )
            )
            state.fuelRecords.append(record)
            return record
        }
    }

    #if DEBUG
        func seedFuelReviewScreenshotData(now: Date, calendar: Calendar) {
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: DateComponents(
                year: components.year,
                month: components.month,
                day: 1,
                hour: 12
            )) else { return }

            let vehicleID = UUID(uuidString: "34000000-0000-0000-0000-000000000034") ?? UUID()
            let vehicle = VehicleProfile(
                id: vehicleID,
                name: "34",
                audioRouteUID: "fuel-review-34",
                audioRouteName: "34 Bluetooth",
                colorHex: "#007AFF",
                createdAt: monthStart,
                odometerKilometers: 34_820,
                oilChangeIntervalKilometers: 5_000,
                lastOilChangeOdometerKilometers: 32_000,
                usesHighAccuracyTracking: true
            )
            let entries: [(dayOffset: Int, liters: Double, fullTank: Bool, distance: Double)] = [
                (0, 38.0, true, 0),
                (2, 23.5, true, 310),
                (4, 16.0, false, 540),
                (6, 22.5, true, 825),
                (8, 28.0, true, 1_194)
            ]
            let records = entries.compactMap { entry -> VehicleFuelRecord? in
                guard let date = calendar.date(
                    byAdding: .day,
                    value: entry.dayOffset,
                    to: monthStart
                ) else { return nil }
                return VehicleFuelRecord(
                    id: UUID(),
                    vehicleID: vehicleID,
                    date: date,
                    liters: entry.liters,
                    isFullTank: entry.fullTank,
                    trackedDistanceKilometers: entry.distance
                )
            }

            _ = try? mutate { state in
                state = StoredState()
                state.vehicles = [vehicle]
                state.fuelRecords = records
                state.fuelTrackingDistanceKilometersByVehicleID[vehicleID] = 1_194
                state.intervals = [DetectionInterval(
                    vehicleID: vehicleID,
                    startDate: now.addingTimeInterval(-3_600),
                    endDate: nil
                )]
            }
        }
    #endif

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
        let dominantShare = distanceShares(forStartDate: startDate, endDate: endDate)
            .max { first, second in first.fraction < second.fraction }
        guard let dominantShare, dominantShare.fraction >= 0.5 else { return nil }
        return lock.withLock { state in
            state.vehicles.first { $0.id == dominantShare.vehicleID }
        }
    }

    func distanceShares(
        forStartDate startDate: Date,
        endDate: Date
    ) -> [VehicleDistanceShare] {
        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0, duration.isFinite else { return [] }
        return lock.withLock { state in
            Self.distanceShares(
                forStartDate: startDate,
                endDate: endDate,
                intervals: state.intervals,
                registeredVehicleIDs: Set(state.vehicles.map(\.id))
            )
        }
    }

    func replaceProcessedDistances(
        for localDateKey: String,
        movements: [MovementSegmentData]
    ) -> [VehicleOilChangeNotification] {
        (try? mutate { state in
            let registeredVehicleIDs = Set(state.vehicles.map(\.id))
            let newDistances = movements.reduce(into: [UUID: Double]()) { result, movement in
                let shares = Self.distanceShares(
                    forStartDate: movement.startDate,
                    endDate: movement.endDate,
                    intervals: state.intervals,
                    registeredVehicleIDs: registeredVehicleIDs
                )
                for share in shares where registeredVehicleIDs.contains(share.vehicleID) {
                    result[share.vehicleID, default: 0] += max(0, movement.distanceMeters)
                        * share.fraction / 1_000
                }
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
                    lastOilChangeOdometerKilometers: existing.lastOilChangeOdometerKilometers,
                    usesHighAccuracyTracking: existing.usesHighAccuracyTracking
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

    private static func distanceShares(
        forStartDate startDate: Date,
        endDate: Date,
        intervals: [DetectionInterval],
        registeredVehicleIDs: Set<UUID>
    ) -> [VehicleDistanceShare] {
        let duration = endDate.timeIntervalSince(startDate)
        guard duration > 0, duration.isFinite else { return [] }
        let overlaps = intervals.reduce(into: [UUID: TimeInterval]()) { result, interval in
            guard registeredVehicleIDs.contains(interval.vehicleID) else { return }
            let intervalEnd = interval.endDate ?? .distantFuture
            let overlapStart = max(startDate, interval.startDate)
            let overlapEnd = min(endDate, intervalEnd)
            let overlap = overlapEnd.timeIntervalSince(overlapStart)
            guard overlap > 0 else { return }
            result[interval.vehicleID, default: 0] += overlap
        }
        return overlaps.map { vehicleID, overlap in
            VehicleDistanceShare(
                vehicleID: vehicleID,
                fraction: min(max(overlap / duration, 0), 1)
            )
        }.sorted { first, second in
            if first.fraction == second.fraction {
                return first.vehicleID.uuidString < second.vehicleID.uuidString
            }
            return first.fraction > second.fraction
        }
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
