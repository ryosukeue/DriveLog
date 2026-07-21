import CoreLocation
import Foundation

@MainActor
final class CoreLocationProvider: NSObject, LocationProviding {
    nonisolated let events: AsyncStream<LocationProviderEvent>
    nonisolated let locationChanges: AsyncStream<LocationEventData>

    private let manager: CLLocationManager
    private let clock: any Clock
    private let localTimeContextProvider: any LocalTimeContextProviding
    private let continuation: AsyncStream<LocationProviderEvent>.Continuation
    private let locationContinuation: AsyncStream<LocationEventData>.Continuation
    private var state: LocationMonitoringState = .stopped
    private var recordingMode: LocationRecordingMode = .lowPower
    private var highAccuracyEmissionFilter = ChargingLocationEmissionFilter()

    init(
        manager: CLLocationManager = CLLocationManager(),
        clock: any Clock,
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        let stream = AsyncStream.makeStream(of: LocationProviderEvent.self)
        let locationStream = AsyncStream.makeStream(of: LocationEventData.self)
        events = stream.stream
        locationChanges = locationStream.stream
        continuation = stream.continuation
        locationContinuation = locationStream.continuation
        self.manager = manager
        self.clock = clock
        self.localTimeContextProvider = localTimeContextProvider
        super.init()
        manager.delegate = self
    }

    convenience init(
        manager: CLLocationManager = CLLocationManager(),
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        self.init(
            manager: manager,
            clock: SystemClock(),
            localTimeContextProvider: localTimeContextProvider
        )
    }

    var monitoringState: LocationMonitoringState {
        get async { state }
    }

    func startSignificantLocationMonitoring() async throws {
        try await setRecordingMode(.lowPower)
    }

    func stopSignificantLocationMonitoring() async {
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopUpdatingLocation()
        setState(.stopped)
    }

    func setRecordingMode(_ mode: LocationRecordingMode) async throws {
        guard mode != recordingMode || state != .running else { return }
        do {
            try validateAuthorizationAndAvailability(for: mode)
        } catch let error as DriveLogError {
            let code = switch error {
            case .permissionDenied: "permission_denied"
            case .permissionRestricted: "permission_restricted"
            case .monitoringUnavailable: "monitoring_unavailable"
            default: "location_start_failure"
            }
            if error == .monitoringUnavailable {
                setState(.unavailable)
            } else {
                setState(.failed(code: code))
            }
            continuation.yield(.error(error))
            throw error
        }
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopUpdatingLocation()
        recordingMode = mode
        highAccuracyEmissionFilter.reset()
        setState(.starting)
        switch mode {
        case .lowPower:
            manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            manager.distanceFilter = kCLDistanceFilterNone
            manager.activityType = .other
            manager.pausesLocationUpdatesAutomatically = true
            manager.allowsBackgroundLocationUpdates = false
            manager.startMonitoringSignificantLocationChanges()
        case .automotiveCandidate:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = 100
            manager.activityType = .automotiveNavigation
            manager.pausesLocationUpdatesAutomatically = false
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        case .automotiveHighAccuracy, .chargingHighAccuracy:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 50
            manager.activityType = .automotiveNavigation
            // Charging mode prioritizes a continuous vehicle route. Automatic pauses can leave
            // standard updates stopped after the device begins moving again.
            manager.pausesLocationUpdatesAutomatically = false
            manager.allowsBackgroundLocationUpdates = true
            manager.startUpdatingLocation()
        }
        setState(.running)
    }

    func convert(_ location: CLLocation) -> LocationEventData? {
        let coordinate = location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate),
              location.horizontalAccuracy >= 0,
              location.timestamp <= clock.now.addingTimeInterval(300)
        else { return nil }
        let context = localTimeContextProvider.makeContext(for: location.timestamp)
        return LocationEventData(
            latitude: coordinate.latitude, longitude: coordinate.longitude,
            timestamp: location.timestamp, horizontalAccuracy: location.horizontalAccuracy,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            createdAt: clock.now, timeZoneIdentifier: context.timeZoneIdentifier,
            utcOffsetSeconds: context.utcOffsetSeconds, localDateKey: context.localDateKey
        )
    }

    private func setState(_ newState: LocationMonitoringState) {
        state = newState
        continuation.yield(.stateChanged(newState))
    }

    private func validateAuthorizationAndAvailability(for mode: LocationRecordingMode) throws {
        if mode == .lowPower, !CLLocationManager.significantLocationChangeMonitoringAvailable() {
            setState(.unavailable)
            throw DriveLogError.monitoringUnavailable
        }
        switch manager.authorizationStatus {
        case .denied:
            throw DriveLogError.permissionDenied(.location)
        case .restricted:
            throw DriveLogError.permissionRestricted(.location)
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined:
            return
        @unknown default:
            throw DriveLogError.unknown(code: "location_authorization")
        }
    }

    private func mappedError(_ error: Error) -> DriveLogError {
        guard let coreLocationError = error as? CLError else {
            return .unknown(code: "core_location")
        }
        switch coreLocationError.code {
        case .denied: return .permissionDenied(.location)
        case .network: return .unknown(code: "location_network")
        case .locationUnknown: return .unknown(code: "location_unknown")
        default: return .unknown(code: "core_location")
        }
    }
}

extension CoreLocationProvider: CLLocationManagerDelegate {
    func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        var emittedCount = 0
        for location in locations {
            guard let event = convert(location) else { continue }
            if recordingMode != .lowPower {
                let interval: TimeInterval? = recordingMode == .automotiveCandidate ? 10 : nil
                guard highAccuracyEmissionFilter.shouldEmit(
                    location.timestamp, minimumInterval: interval
                ) else { continue }
            }
            continuation.yield(.location(event))
            locationContinuation.yield(event)
            emittedCount += 1
        }
        continuation.yield(.acquisitionDiagnostic(LocationAcquisitionDiagnostic(
            mode: recordingMode,
            receivedCount: locations.count,
            emittedCount: emittedCount
        )))
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let mappedError = mappedError(error)
        let code = switch mappedError {
        case .permissionDenied: "permission_denied"
        default: "location_error"
        }
        setState(.failed(code: code))
        continuation.yield(.error(mappedError))
    }
}
