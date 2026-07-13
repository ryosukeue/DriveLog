import CoreLocation
import Foundation

@MainActor
final class CoreLocationProvider: NSObject, LocationProviding {
    nonisolated let events: AsyncStream<LocationProviderEvent>

    private let manager: CLLocationManager
    private let clock: any Clock
    private let localTimeContextProvider: any LocalTimeContextProviding
    private let continuation: AsyncStream<LocationProviderEvent>.Continuation
    private var state: LocationMonitoringState = .stopped

    init(
        manager: CLLocationManager = CLLocationManager(),
        clock: any Clock,
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        let stream = AsyncStream.makeStream(of: LocationProviderEvent.self)
        events = stream.stream
        continuation = stream.continuation
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
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            setState(.unavailable)
            throw DriveLogError.monitoringUnavailable
        }
        switch manager.authorizationStatus {
        case .denied:
            let error = DriveLogError.permissionDenied(.location)
            setState(.failed(code: "permission_denied"))
            continuation.yield(.error(error))
            throw error
        case .restricted:
            let error = DriveLogError.permissionRestricted(.location)
            setState(.failed(code: "permission_restricted"))
            continuation.yield(.error(error))
            throw error
        case .authorizedAlways, .authorizedWhenInUse, .notDetermined:
            setState(.starting)
            manager.startMonitoringSignificantLocationChanges()
            setState(.running)
        @unknown default:
            let error = DriveLogError.unknown(code: "location_authorization")
            setState(.failed(code: "authorization_unknown"))
            continuation.yield(.error(error))
            throw error
        }
    }

    func stopSignificantLocationMonitoring() async {
        manager.stopMonitoringSignificantLocationChanges()
        setState(.stopped)
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
        for location in locations {
            guard let event = convert(location) else { continue }
            continuation.yield(.location(event))
        }
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
