protocol LocationProviding: Sendable {
    var monitoringState: LocationMonitoringState { get async }
    var events: AsyncStream<LocationProviderEvent> { get }

    func startSignificantLocationMonitoring() async throws
    func stopSignificantLocationMonitoring() async
}

enum LocationMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

enum LocationProviderEvent: Sendable {
    case location(LocationEventData)
    case stateChanged(LocationMonitoringState)
    case error(DriveLogError)
}
