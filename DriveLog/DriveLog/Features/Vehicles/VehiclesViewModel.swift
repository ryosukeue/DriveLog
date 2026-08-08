import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class VehiclesViewModel {
    private(set) var vehicles: [VehicleProfile] = []
    private(set) var availableDevices: [AudioRouteDevice] = []
    private(set) var detectedVehicle: VehicleProfile?
    private(set) var errorMessage: String?
    private let slotStore: VehicleSlotStore

    var canAddVehicle: Bool {
        vehicles.count < slotStore.vehicleLimit
    }

    var extraSlotProduct: Product? { slotStore.product }
    var isPurchasingSlot: Bool { slotStore.isPurchasing }

    private let store: UserDefaultsVehicleStore
    private let detector: AudioRouteVehicleDetector
    private let oilChangeNotifier: any VehicleOilChangeNotifying

    init(
        store: UserDefaultsVehicleStore,
        detector: AudioRouteVehicleDetector,
        oilChangeNotifier: any VehicleOilChangeNotifying = EmptyVehicleOilChangeNotifier(),
        slotStore: VehicleSlotStore? = nil
    ) {
        self.store = store
        self.detector = detector
        self.oilChangeNotifier = oilChangeNotifier
        self.slotStore = slotStore ?? VehicleSlotStore()
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
        lastOilChangeOdometerKilometers: Double
    ) -> Bool {
        do {
            try store.addVehicle(
                name: name,
                audioRouteUID: device.uid,
                audioRouteName: device.name,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers,
                userVisibleLimit: slotStore.vehicleLimit
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
        lastOilChangeOdometerKilometers: Double
    ) -> Bool {
        do {
            try store.updateVehicle(
                id: id,
                name: name,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: lastOilChangeOdometerKilometers
            )
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

    func loadPurchaseProduct() async { await slotStore.loadProduct() }

    func purchaseExtraSlot() async -> Bool {
        let completed = await slotStore.purchaseSlot()
        if let message = slotStore.errorMessage { errorMessage = message }
        return completed
    }

    private func reload() {
        vehicles = store.registeredVehicles()
        availableDevices = detector.availableDevices
        detectedVehicle = detector.detectedVehicle
    }
}
