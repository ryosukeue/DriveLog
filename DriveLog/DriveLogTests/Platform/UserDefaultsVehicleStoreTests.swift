@testable import DriveLog
import Foundation
import Testing

@Suite("Vehicle attribution store")
struct UserDefaultsVehicleStoreTests {
    @Test("attributes overlapping movement to the detected registered vehicle")
    func detectedInterval() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)
        let vehicle = try store.addVehicle(
            name: "テストカー",
            audioRouteUID: "audio-1",
            audioRouteName: "Car Audio",
            userVisibleLimit: 1,
            now: start.addingTimeInterval(-10)
        )

        store.updateDetectedAudioRoute(uid: "audio-1", at: start)
        store.updateDetectedAudioRoute(uid: nil, at: start.addingTimeInterval(600))

        let detected = store.vehicle(
            forStartDate: start.addingTimeInterval(60),
            endDate: start.addingTimeInterval(300)
        )
        let outside = store.vehicle(
            forStartDate: start.addingTimeInterval(700),
            endDate: start.addingTimeInterval(800)
        )

        #expect(detected == vehicle)
        #expect(outside == nil)
    }

    @Test("keeps multiple vehicles internally while enforcing an optional UI limit")
    func internalMultipleVehicleSupport() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)

        _ = try store.addVehicle(
            name: "1台目",
            audioRouteUID: "audio-1",
            audioRouteName: "Audio 1"
        )
        #expect(throws: UserDefaultsVehicleStore.StoreError.vehicleLimitReached) {
            try store.addVehicle(
                name: "UIでは2台目",
                audioRouteUID: "audio-2",
                audioRouteName: "Audio 2",
                userVisibleLimit: 1
            )
        }
        _ = try store.addVehicle(
            name: "内部の2台目",
            audioRouteUID: "audio-2",
            audioRouteName: "Audio 2"
        )

        #expect(store.registeredVehicles().count == 2)
        #expect(store.registeredVehicles()[0].colorHex != store.registeredVehicles()[1].colorHex)
    }

    @Test("edits and persists oil change information")
    func editsOilChangeInformation() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)
        let vehicle = try store.addVehicle(
            name: "登録名",
            audioRouteUID: "audio-1",
            audioRouteName: "Car Audio",
            odometerKilometers: 12_000,
            oilChangeIntervalKilometers: 5_000,
            lastOilChangeOdometerKilometers: 10_000
        )

        try store.updateVehicle(
            id: vehicle.id,
            name: "編集後",
            odometerKilometers: 12_500,
            oilChangeIntervalKilometers: 4_000,
            lastOilChangeOdometerKilometers: 11_000
        )
        let restored = try #require(
            UserDefaultsVehicleStore(defaults: defaults).registeredVehicles().first
        )

        #expect(restored.name == "編集後")
        #expect(restored.odometerKilometers == 12_500)
        #expect(restored.oilChangeIntervalKilometers == 4_000)
        #expect(restored.lastOilChangeOdometerKilometers == 11_000)
        #expect(restored.oilChangeRemainingKilometers == 2_500)
    }

    @Test("adds detected route distance once and emits each oil warning once")
    func recordsDistanceAndOilWarningsOnce() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)
        let vehicle = try store.addVehicle(
            name: "テストカー",
            audioRouteUID: "audio-1",
            audioRouteName: "Car Audio",
            odometerKilometers: 14_499,
            oilChangeIntervalKilometers: 5_000,
            lastOilChangeOdometerKilometers: 10_000,
            now: start.addingTimeInterval(-10)
        )
        store.updateDetectedAudioRoute(uid: "audio-1", at: start)

        let firstMovement = movement(
            id: "movement-1",
            localDateKey: "2026-08-08",
            start: start.addingTimeInterval(60),
            distanceMeters: 2_000
        )
        let upcoming = store.replaceProcessedDistances(
            for: "2026-08-08",
            movements: [firstMovement]
        )
        let duplicate = store.replaceProcessedDistances(
            for: "2026-08-08",
            movements: [firstMovement]
        )

        #expect(upcoming == [.upcoming(
            vehicleID: vehicle.id,
            vehicleName: "テストカー",
            remainingKilometers: 499
        )])
        #expect(duplicate.isEmpty)
        #expect(store.registeredVehicles().first?.odometerKilometers == 14_501)

        let overdue = store.replaceProcessedDistances(
            for: "2026-08-09",
            movements: [movement(
                id: "movement-2",
                localDateKey: "2026-08-09",
                start: start.addingTimeInterval(120),
                distanceMeters: 500_000
            )]
        )
        let repeatedOverdue = store.replaceProcessedDistances(
            for: "2026-08-10",
            movements: [movement(
                id: "movement-3",
                localDateKey: "2026-08-10",
                start: start.addingTimeInterval(180),
                distanceMeters: 1_000
            )]
        )

        #expect(overdue == [.overdue(
            vehicleID: vehicle.id,
            vehicleName: "テストカー"
        )])
        #expect(repeatedOverdue.isEmpty)
        #expect(store.registeredVehicles().first?.odometerKilometers == 15_002)
    }

    @Test("loads vehicle data saved before oil fields existed")
    func loadsLegacyVehicleData() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let id = UUID()
        let legacyState = LegacyStoredState(
            vehicles: [LegacyVehicleProfile(
                id: id,
                name: "以前の車",
                audioRouteUID: "legacy-audio",
                audioRouteName: "Legacy Audio",
                colorHex: "#007AFF",
                createdAt: Date(timeIntervalSince1970: 1_000)
            )],
            intervals: []
        )
        defaults.set(try JSONEncoder().encode(legacyState), forKey: "vehicle.store.v1")

        let restored = try #require(
            UserDefaultsVehicleStore(defaults: defaults).registeredVehicles().first
        )

        #expect(restored.id == id)
        #expect(restored.odometerKilometers == 0)
        #expect(restored.oilChangeIntervalKilometers == 5_000)
        #expect(restored.lastOilChangeOdometerKilometers == 0)
    }

    @Test("rebuilds fuel distance from processed vehicle movements")
    func rebuildsFuelDistanceFromProcessedMovements() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)
        let vehicle = try store.addVehicle(
            name: "テストカー",
            audioRouteUID: "audio-1",
            audioRouteName: "Car Audio",
            now: start.addingTimeInterval(-10)
        )
        store.updateDetectedAudioRoute(uid: "audio-1", at: start)

        _ = try store.addFuelRecord(
            vehicleID: vehicle.id,
            liters: 40,
            isFullTank: true,
            date: start.addingTimeInterval(100)
        )
        _ = try store.addFuelRecord(
            vehicleID: vehicle.id,
            liters: 30,
            isFullTank: true,
            date: start.addingTimeInterval(500)
        )

        _ = store.replaceProcessedDistances(
            for: "2026-08-08",
            movements: [
                movement(
                    id: "movement-1",
                    localDateKey: "2026-08-08",
                    start: start.addingTimeInterval(200),
                    distanceMeters: 60_000
                ),
                movement(
                    id: "movement-2",
                    localDateKey: "2026-08-08",
                    start: start.addingTimeInterval(350),
                    distanceMeters: 30_000
                )
            ]
        )

        let records = store.fuelRecords(for: vehicle.id)
        let interval = try #require(FuelEconomyCalculator.intervals(from: records).first)
        #expect(records[0].trackedDistanceKilometers == 0)
        #expect(records[1].trackedDistanceKilometers == 90)
        #expect(interval.distanceKilometers == 90)
        #expect(interval.kilometersPerLiter == 3)
    }

    @Test("edits fuel amount, tank state, and manual calculation distance")
    func editsFuelRecord() throws {
        let suiteName = "UserDefaultsVehicleStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsVehicleStore(defaults: defaults)
        let start = Date(timeIntervalSince1970: 1_000)
        let vehicle = try store.addVehicle(
            name: "テストカー",
            audioRouteUID: "audio-1",
            audioRouteName: "Car Audio"
        )
        let first = try store.addFuelRecord(
            vehicleID: vehicle.id,
            liters: 40,
            isFullTank: true,
            date: start
        )
        let second = try store.addFuelRecord(
            vehicleID: vehicle.id,
            liters: 30,
            isFullTank: false,
            date: start.addingTimeInterval(1_000)
        )

        _ = first
        let updated = try store.updateFuelRecord(
            id: second.id,
            liters: 36,
            isFullTank: true,
            manualDistanceKilometers: 360
        )

        #expect(updated.liters == 36)
        #expect(updated.isFullTank)
        #expect(updated.manualDistanceKilometers == 360)
        let interval = try #require(
            FuelEconomyCalculator.intervals(from: store.fuelRecords(for: vehicle.id)).first
        )
        #expect(interval.distanceKilometers == 360)
        #expect(interval.fuelLiters == 36)
        #expect(interval.kilometersPerLiter == 10)
    }
}

private struct LegacyStoredState: Encodable {
    let vehicles: [LegacyVehicleProfile]
    let intervals: [String]
}

private struct LegacyVehicleProfile: Encodable {
    let id: UUID
    let name: String
    let audioRouteUID: String
    let audioRouteName: String
    let colorHex: String
    let createdAt: Date
}

private func movement(
    id: String,
    localDateKey: String,
    start: Date,
    distanceMeters: Double
) -> MovementSegmentData {
    MovementSegmentData(
        stableID: id,
        localDateKey: localDateKey,
        startDate: start,
        endDate: start.addingTimeInterval(60),
        distanceMeters: distanceMeters,
        durationSeconds: 60,
        estimatedAverageSpeedMetersPerSecond: nil,
        automaticClassification: .automotiveLike,
        classificationConfidence: .high,
        route: [],
        labelCoordinate: nil,
        sourceRawRevision: 1,
        generatedAt: start
    )
}
