import Foundation
import Observation

@MainActor
@Observable
final class VehiclesViewModel {
    private(set) var vehicles: [VehicleProfile] = []
    private(set) var availableDevices: [AudioRouteDevice] = []
    private(set) var detectedVehicle: VehicleProfile?
    private(set) var errorMessage: String?

    var canAddVehicle: Bool {
        vehicles.isEmpty
    }

    private let store: UserDefaultsVehicleStore
    private let detector: AudioRouteVehicleDetector

    init(store: UserDefaultsVehicleStore, detector: AudioRouteVehicleDetector) {
        self.store = store
        self.detector = detector
        reload()
    }

    func refresh() {
        detector.start()
        detector.refresh()
        reload()
    }

    func addVehicle(name: String, device: AudioRouteDevice) -> Bool {
        do {
            try store.addVehicle(
                name: name,
                audioRouteUID: device.uid,
                audioRouteName: device.name,
                userVisibleLimit: 1
            )
            detector.refresh()
            reload()
            return true
        } catch UserDefaultsVehicleStore.StoreError.vehicleLimitReached {
            errorMessage = "現在登録できる車は1台までです"
        } catch UserDefaultsVehicleStore.StoreError.duplicateAudioRoute {
            errorMessage = "このオーディオデバイスは登録済みです"
        } catch {
            errorMessage = "車を登録できませんでした"
        }
        return false
    }

    func removeVehicle(id: UUID) {
        store.removeVehicle(id: id)
        detector.refresh()
        reload()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func reload() {
        vehicles = store.registeredVehicles()
        availableDevices = detector.availableDevices
        detectedVehicle = detector.detectedVehicle
    }
}
