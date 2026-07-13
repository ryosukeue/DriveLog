import CoreLocation
import Foundation

struct VisitSnapshot: Sendable {
    let coordinate: CLLocationCoordinate2D
    let horizontalAccuracy: CLLocationAccuracy
    let arrivalDate: Date
    let departureDate: Date
}

@MainActor
final class CoreLocationVisitProvider: NSObject, VisitProviding {
    nonisolated let events: AsyncStream<VisitProviderEvent>

    private let manager: CLLocationManager
    private let clock: any Clock
    private let localTimeContextProvider: any LocalTimeContextProviding
    private let continuation: AsyncStream<VisitProviderEvent>.Continuation
    private var state: VisitMonitoringState = .stopped

    init(
        manager: CLLocationManager = CLLocationManager(),
        clock: any Clock,
        localTimeContextProvider: any LocalTimeContextProviding
    ) {
        let stream = AsyncStream.makeStream(of: VisitProviderEvent.self)
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
            manager: manager, clock: SystemClock(),
            localTimeContextProvider: localTimeContextProvider
        )
    }

    var monitoringState: VisitMonitoringState {
        get async { state }
    }

    func startMonitoring() async throws {
        guard CLLocationManager.locationServicesEnabled() else {
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
            manager.startMonitoringVisits()
            setState(.running)
        @unknown default:
            let error = DriveLogError.unknown(code: "visit_authorization")
            setState(.failed(code: "authorization_unknown"))
            continuation.yield(.error(error))
            throw error
        }
    }

    func stopMonitoring() async {
        manager.stopMonitoringVisits()
        setState(.stopped)
    }

    func convert(_ snapshot: VisitSnapshot) -> VisitEventData? {
        guard CLLocationCoordinate2DIsValid(snapshot.coordinate),
              snapshot.horizontalAccuracy >= 0
        else { return nil }
        let arrivalDate = snapshot.arrivalDate == .distantPast ? nil : snapshot.arrivalDate
        let departureDate = snapshot.departureDate == .distantFuture ? nil : snapshot.departureDate
        let contextDate = arrivalDate ?? departureDate ?? clock.now
        let context = localTimeContextProvider.makeContext(for: contextDate)
        return VisitEventData(
            latitude: snapshot.coordinate.latitude,
            longitude: snapshot.coordinate.longitude,
            arrivalDate: arrivalDate, departureDate: departureDate,
            horizontalAccuracy: snapshot.horizontalAccuracy,
            timeZoneIdentifier: context.timeZoneIdentifier,
            utcOffsetSeconds: context.utcOffsetSeconds, localDateKey: context.localDateKey
        )
    }

    func send(_ snapshot: VisitSnapshot) {
        guard let event = convert(snapshot) else { return }
        continuation.yield(.visit(event))
    }

    private func setState(_ newState: VisitMonitoringState) {
        state = newState
        continuation.yield(.stateChanged(newState))
    }

    private func mappedError(_ error: Error) -> DriveLogError {
        guard let coreLocationError = error as? CLError else {
            return .unknown(code: "visit_core_location")
        }
        switch coreLocationError.code {
        case .denied: return .permissionDenied(.location)
        case .network: return .unknown(code: "visit_network")
        default: return .unknown(code: "visit_core_location")
        }
    }
}

extension CoreLocationVisitProvider: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didVisit visit: CLVisit) {
        send(
            VisitSnapshot(
                coordinate: visit.coordinate, horizontalAccuracy: visit.horizontalAccuracy,
                arrivalDate: visit.arrivalDate, departureDate: visit.departureDate
            )
        )
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let mappedError = mappedError(error)
        setState(.failed(code: "visit_error"))
        continuation.yield(.error(mappedError))
    }
}
