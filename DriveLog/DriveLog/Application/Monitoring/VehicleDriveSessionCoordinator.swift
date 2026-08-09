import Foundation

actor VehicleDriveSessionCoordinator {
    private struct Sample: Sendable {
        let latitude: Double
        let longitude: Double
        let timestamp: Date
        let horizontalAccuracy: Double
    }

    private let locationChanges: AsyncStream<LocationEventData>
    private let monitoringUseCase: StartMonitoringUseCase
    private let vehicleStore: UserDefaultsVehicleStore
    private let gasStationProvider: any NearbyGasStationProviding
    private let notificationService: FuelStopNotificationService
    private var observationTask: Task<Void, Never>?
    private var stationaryCheckTask: Task<Void, Never>?
    private var detectedVehicle: VehicleProfile?
    private var lastTrackingSample: Sample?
    private var stationaryAnchor: Sample?
    private var latestSample: Sample?
    private var checkedCurrentStop = false

    init(
        locationChanges: AsyncStream<LocationEventData>,
        monitoringUseCase: StartMonitoringUseCase,
        vehicleStore: UserDefaultsVehicleStore,
        gasStationProvider: any NearbyGasStationProviding,
        notificationService: FuelStopNotificationService
    ) {
        self.locationChanges = locationChanges
        self.monitoringUseCase = monitoringUseCase
        self.vehicleStore = vehicleStore
        self.gasStationProvider = gasStationProvider
        self.notificationService = notificationService
    }

    deinit {
        observationTask?.cancel()
        stationaryCheckTask?.cancel()
    }

    func start() {
        guard observationTask == nil else { return }
        let changes = locationChanges
        observationTask = Task { [weak self] in
            for await event in changes {
                guard !Task.isCancelled else { return }
                await self?.handle(event)
            }
        }
    }

    func updateDetectedVehicle(_ vehicle: VehicleProfile?) async {
        guard vehicle?.id != detectedVehicle?.id else { return }
        detectedVehicle = vehicle
        lastTrackingSample = nil
        resetStationaryDetection()
        await monitoringUseCase.setVehicleConnected(vehicle?.usesHighAccuracyTracking == true)
    }

    private func handle(_ event: LocationEventData) async {
        guard let vehicle = detectedVehicle,
              event.horizontalAccuracy >= 0,
              event.horizontalAccuracy <= 100
        else { return }
        let sample = Sample(
            latitude: event.latitude,
            longitude: event.longitude,
            timestamp: event.timestamp,
            horizontalAccuracy: event.horizontalAccuracy
        )
        latestSample = sample
        recordTrackedDistance(to: sample, vehicleID: vehicle.id)
        updateStationaryDetection(with: sample, speed: event.speedMetersPerSecond)
    }

    private func recordTrackedDistance(to sample: Sample, vehicleID: UUID) {
        defer { lastTrackingSample = sample }
        guard let previous = lastTrackingSample else { return }
        let elapsed = sample.timestamp.timeIntervalSince(previous.timestamp)
        guard elapsed > 0, elapsed <= 180 else { return }
        let distance = Self.distanceMeters(from: previous, to: sample)
        let plausibleMaximum = elapsed * 70 + previous.horizontalAccuracy
            + sample.horizontalAccuracy
        guard distance >= 5, distance <= plausibleMaximum else { return }
        vehicleStore.addFuelTrackingDistance(distance / 1_000, for: vehicleID)
    }

    private func updateStationaryDetection(with sample: Sample, speed: Double?) {
        if let speed, speed >= 3 {
            resetStationaryDetection()
            return
        }
        if let speed, speed > 1.5 {
            return
        }
        if let stationaryAnchor,
           Self.distanceMeters(from: stationaryAnchor, to: sample) > 75
        {
            resetStationaryDetection()
        }
        guard self.stationaryAnchor == nil else { return }
        stationaryAnchor = sample
        checkedCurrentStop = false
        stationaryCheckTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(120))
            guard !Task.isCancelled else { return }
            await self?.checkCurrentStop()
        }
    }

    private func checkCurrentStop() async {
        guard !checkedCurrentStop,
              let vehicle = detectedVehicle,
              let anchor = stationaryAnchor,
              let latestSample,
              Self.distanceMeters(from: anchor, to: latestSample) <= 75
        else { return }
        checkedCurrentStop = true
        let isNearGasStation = await gasStationProvider.isNearGasStation(
            latitude: latestSample.latitude,
            longitude: latestSample.longitude
        )
        guard isNearGasStation else { return }
        await notificationService.send(vehicleName: vehicle.name, vehicleID: vehicle.id)
    }

    private func resetStationaryDetection() {
        stationaryCheckTask?.cancel()
        stationaryCheckTask = nil
        stationaryAnchor = nil
        checkedCurrentStop = false
    }

    private nonisolated static func distanceMeters(from first: Sample, to second: Sample) -> Double {
        let earthRadius = 6_371_000.0
        let latitude1 = first.latitude * .pi / 180
        let latitude2 = second.latitude * .pi / 180
        let latitudeDelta = (second.latitude - first.latitude) * .pi / 180
        let longitudeDelta = (second.longitude - first.longitude) * .pi / 180
        let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(latitude1) * cos(latitude2)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return earthRadius * 2 * atan2(sqrt(haversine), sqrt(max(0, 1 - haversine)))
    }
}
