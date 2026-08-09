import Foundation
import Observation

@MainActor
@Observable
final class VehiclesViewModel {
    private(set) var vehicles: [VehicleProfile] = []
    private(set) var availableDevices: [AudioRouteDevice] = []
    private(set) var detectedVehicle: VehicleProfile?
    private(set) var errorMessage: String?

    private static let vehicleLimit = 1

    var canAddVehicle: Bool {
        isPlus || vehicles.count < Self.vehicleLimit
    }

    var isPlus: Bool {
        plusPlanStore.isPlus
    }

    private let store: UserDefaultsVehicleStore
    private let detector: AudioRouteVehicleDetector
    private let oilChangeNotifier: any VehicleOilChangeNotifying
    private let plusPlanStore: PlusPlanStore

    init(
        store: UserDefaultsVehicleStore,
        detector: AudioRouteVehicleDetector,
        oilChangeNotifier: any VehicleOilChangeNotifying = EmptyVehicleOilChangeNotifier(),
        plusPlanStore: PlusPlanStore? = nil
    ) {
        self.store = store
        self.detector = detector
        self.oilChangeNotifier = oilChangeNotifier
        self.plusPlanStore = plusPlanStore ?? PlusPlanStore()
        reload()
    }

    func refresh() {
        detector.start()
        detector.refresh()
        reload()
    }

    func addVehicle(
        name: String,
        device: AudioRouteDevice,
        odometerKilometers: Double,
        oilChangeIntervalKilometers: Double,
        lastOilChangeOdometerKilometers: Double,
        usesHighAccuracyTracking: Bool = true
    ) -> Bool {
        do {
            try store.addVehicle(
                name: name,
                audioRouteUID: device.uid,
                audioRouteName: device.name,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers,
                usesHighAccuracyTracking: usesHighAccuracyTracking,
                userVisibleLimit: isPlus ? nil : Self.vehicleLimit
            )
            detector.refresh()
            reload()
            return true
        } catch UserDefaultsVehicleStore.StoreError.vehicleLimitReached {
            errorMessage = "登録可能な車両数の上限です"
        } catch UserDefaultsVehicleStore.StoreError.duplicateAudioRoute {
            errorMessage = "このオーディオデバイスは登録済みです"
        } catch UserDefaultsVehicleStore.StoreError.invalidMaintenanceValues {
            errorMessage = "走行距離とオイル交換情報を確認してください"
        } catch {
            errorMessage = "車を登録できませんでした"
        }
        return false
    }

    func updateVehicle(
        id: UUID,
        name: String,
        odometerKilometers: Double,
        oilChangeIntervalKilometers: Double,
        lastOilChangeOdometerKilometers: Double,
        usesHighAccuracyTracking: Bool
    ) -> Bool {
        do {
            try store.updateVehicle(
                id: id,
                name: name,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers,
                usesHighAccuracyTracking: usesHighAccuracyTracking
            )
            detector.refresh()
            reload()
            return true
        } catch UserDefaultsVehicleStore.StoreError.invalidMaintenanceValues {
            errorMessage = "走行距離とオイル交換情報を確認してください"
        } catch {
            errorMessage = "車の情報を更新できませんでした"
        }
        return false
    }

    func requestOilChangeNotificationAuthorization() async {
        guard isPlus else { return }
        await oilChangeNotifier.requestAuthorization()
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
