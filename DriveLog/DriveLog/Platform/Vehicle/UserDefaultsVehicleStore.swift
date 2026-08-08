import Foundation
import os

final class UserDefaultsVehicleStore: VehicleAttributionProviding, @unchecked Sendable {
    private struct DetectionInterval: Codable, Sendable, Equatable {
        let vehicleID: UUID
        let startDate: Date
        var endDate: Date?
    }

    private struct StoredState: Codable, Sendable {
        var vehicles: [VehicleProfile] = []
        var intervals: [DetectionInterval] = []
    }

    enum StoreError: Error, Equatable {
        case vehicleLimitReached
        case duplicateAudioRoute
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
        userVisibleLimit: Int? = nil,
        now: Date = Date()
    ) throws -> VehicleProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
                createdAt: now
            )
            state.vehicles.append(vehicle)
            return vehicle
        }
    }

    func removeVehicle(id: UUID, now: Date = Date()) {
        _ = try? mutate { state in
            state.vehicles.removeAll { $0.id == id }
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
            let best = state.intervals.compactMap { interval -> (UUID, TimeInterval)? in
                let intervalEnd = interval.endDate ?? .distantFuture
                let overlapStart = max(startDate, interval.startDate)
                let overlapEnd = min(endDate, intervalEnd)
                let overlap = overlapEnd.timeIntervalSince(overlapStart)
                return overlap > 0 ? (interval.vehicleID, overlap) : nil
            }.max { first, second in
                first.1 < second.1
            }
            guard let best else { return nil }
            return state.vehicles.first { $0.id == best.0 }
        }
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
