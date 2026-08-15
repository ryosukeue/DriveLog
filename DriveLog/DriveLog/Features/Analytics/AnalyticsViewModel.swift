import Foundation
import Observation

nonisolated enum AnalyticsViewState: Sendable, Equatable {
    case idle
    case loading
    case loaded
    case error
}

@MainActor
@Observable
final class AnalyticsViewModel {
    private(set) var state: AnalyticsViewState = .idle
    private(set) var selectedMonth: LocalMonth
    private(set) var series: MonthlyDistanceSeriesData?
    private(set) var vehicles: [VehicleProfile] = []
    private(set) var fuelRecords: [VehicleFuelRecord] = []
    private(set) var fuelEconomyIntervals: [FuelEconomyInterval] = []
    private(set) var overallFuelEconomy: Double?
    private(set) var fuelRecordNotice: String?
    let currentMonth: LocalMonth

    var detectedVehicle: VehicleProfile? {
        detector.detectedVehicle
    }

    var selectedVehicle: VehicleProfile? {
        vehicles.first
    }

    var canMoveToNextMonth: Bool {
        selectedMonth < currentMonth
    }

    private let loadMonthlyDistanceSeries: any LoadMonthlyDistanceSeriesUseCase
    private let vehicleStore: UserDefaultsVehicleStore
    private let detector: AudioRouteVehicleDetector
    private var requestID = 0
    private var cachedSeries: [LocalMonth: MonthlyDistanceSeriesData] = [:]

    init(
        currentMonth: LocalMonth,
        loadMonthlyDistanceSeries: any LoadMonthlyDistanceSeriesUseCase,
        vehicleStore: UserDefaultsVehicleStore? = nil,
        detector: AudioRouteVehicleDetector? = nil
    ) {
        let resolvedStore = vehicleStore ?? UserDefaultsVehicleStore()
        self.currentMonth = currentMonth
        selectedMonth = currentMonth
        self.loadMonthlyDistanceSeries = loadMonthlyDistanceSeries
        self.vehicleStore = resolvedStore
        self.detector = detector ?? AudioRouteVehicleDetector(store: resolvedStore)
        reloadVehicleAnalytics()
    }

    func load() async {
        await load(month: selectedMonth)
    }

    func moveToPreviousMonth() async {
        await load(month: selectedMonth.adding(months: -1))
    }

    func moveToNextMonth() async {
        guard canMoveToNextMonth else { return }
        await load(month: selectedMonth.adding(months: 1))
    }

    func select(month: LocalMonth) async {
        guard month <= currentMonth else { return }
        await load(month: month)
    }

    func refreshVehicleData() {
        detector.start()
        detector.refresh()
        reloadVehicleAnalytics()
    }

    @discardableResult
    func recordFuel(liters: Double, isFullTank: Bool) -> Bool {
        refreshVehicleData()
        guard let vehicle = detector.detectedVehicle else {
            fuelRecordNotice = "登録した車のBluetooth接続中のみ給油を記録できます"
            return false
        }
        do {
            try vehicleStore.addFuelRecord(
                vehicleID: vehicle.id,
                liters: liters,
                isFullTank: isFullTank
            )
            reloadVehicleAnalytics()
            fuelRecordNotice = isFullTank
                ? "満タン給油を記録しました"
                : "給油を記録しました。次の満タン時に燃費へ反映します"
            return true
        } catch {
            fuelRecordNotice = "給油量を確認してください"
            return false
        }
    }

    func dismissFuelRecordNotice() {
        fuelRecordNotice = nil
    }

    @discardableResult
    func updateFuelRecord(
        id: UUID,
        liters: Double,
        isFullTank: Bool,
        manualDistanceKilometers: Double?
    ) -> Bool {
        do {
            try vehicleStore.updateFuelRecord(
                id: id,
                liters: liters,
                isFullTank: isFullTank,
                manualDistanceKilometers: manualDistanceKilometers
            )
            reloadVehicleAnalytics()
            fuelRecordNotice = "給油記録を更新しました"
            return true
        } catch {
            fuelRecordNotice = "給油量と走行距離を確認してください"
            return false
        }
    }

    func automaticDistanceKilometers(endingAt recordID: UUID) -> Double? {
        let sorted = fuelRecords.sorted { $0.date < $1.date }
        guard let recordIndex = sorted.firstIndex(where: { $0.id == recordID }),
              sorted[recordIndex].isFullTank
        else { return nil }
        guard let previousFullTank = sorted[..<recordIndex].last(where: \.isFullTank) else {
            return nil
        }
        let distance = sorted[recordIndex].trackedDistanceKilometers
            - previousFullTank.trackedDistanceKilometers
        guard distance > 0, distance.isFinite else { return nil }
        return distance
    }

    func fuelEconomyInterval(endingAt recordID: UUID) -> FuelEconomyInterval? {
        FuelEconomyCalculator.intervals(from: fuelRecords).first { $0.id == recordID }
    }

    @discardableResult
    func recordOilChange(vehicleID: UUID, odometerKilometers: Double) -> Bool {
        guard let vehicle = vehicles.first(where: { $0.id == vehicleID }) else {
            return false
        }
        do {
            try vehicleStore.updateVehicle(
                id: vehicle.id,
                name: vehicle.name,
                odometerKilometers: odometerKilometers,
                oilChangeIntervalKilometers: vehicle.oilChangeIntervalKilometers,
                lastOilChangeOdometerKilometers: odometerKilometers,
                usesHighAccuracyTracking: vehicle.usesHighAccuracyTracking
            )
            reloadVehicleAnalytics()
            return true
        } catch {
            return false
        }
    }

    private func load(month: LocalMonth) async {
        selectedMonth = month
        if let cached = cachedSeries[month] {
            series = cached
            reloadVehicleAnalytics()
            state = .loaded
            return
        }
        requestID += 1
        let currentRequestID = requestID
        state = .loading
        do {
            let result = try await loadMonthlyDistanceSeries.execute(month: month)
            guard currentRequestID == requestID else { return }
            cachedSeries[month] = result
            series = result
            reloadVehicleAnalytics()
            state = .loaded
        } catch is CancellationError {
            guard currentRequestID == requestID else { return }
        } catch {
            guard currentRequestID == requestID else { return }
            series = nil
            state = .error
        }
    }

    private func reloadVehicleAnalytics() {
        vehicles = vehicleStore.registeredVehicles()
        guard let vehicle = vehicles.first else {
            fuelRecords = []
            fuelEconomyIntervals = []
            overallFuelEconomy = nil
            return
        }
        let records = vehicleStore.fuelRecords(for: vehicle.id)
        let allIntervals = FuelEconomyCalculator.intervals(from: records)
        fuelRecords = records
        fuelEconomyIntervals = allIntervals.filter { interval in
            let components = Calendar.current.dateComponents(
                [.year, .month],
                from: interval.endDate
            )
            return components.year == selectedMonth.year
                && components.month == selectedMonth.month
        }
        overallFuelEconomy = FuelEconomyCalculator.overallKilometersPerLiter(
            from: allIntervals
        )
    }
}
