@MainActor
protocol LocationProviding: Sendable {
    var monitoringState: LocationMonitoringState { get async }
    nonisolated var events: AsyncStream<LocationProviderEvent> { get }

    func startSignificantLocationMonitoring() async throws
    func stopSignificantLocationMonitoring() async
}

nonisolated enum LocationMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

nonisolated enum LocationProviderEvent: Sendable {
    case location(LocationEventData)
    case stateChanged(LocationMonitoringState)
    case error(DriveLogError)
}
