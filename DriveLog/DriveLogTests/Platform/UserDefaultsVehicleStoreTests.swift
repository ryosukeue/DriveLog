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
}
