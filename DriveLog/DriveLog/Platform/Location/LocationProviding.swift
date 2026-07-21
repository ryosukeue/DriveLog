@MainActor
protocol LocationProviding: Sendable {
    var monitoringState: LocationMonitoringState { get async }
    nonisolated var events: AsyncStream<LocationProviderEvent> { get }
    nonisolated var locationChanges: AsyncStream<LocationEventData> { get }

    func startSignificantLocationMonitoring() async throws
    func stopSignificantLocationMonitoring() async
    func setRecordingMode(_ mode: LocationRecordingMode) async throws
}

nonisolated enum LocationRecordingMode: String, Sendable, Equatable {
    case lowPower
    case automotiveCandidate
    case automotiveHighAccuracy
    case chargingHighAccuracy
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
    case acquisitionDiagnostic(LocationAcquisitionDiagnostic)
    case stateChanged(LocationMonitoringState)
    case error(DriveLogError)
}

nonisolated struct LocationAcquisitionDiagnostic: Sendable, Equatable {
    let mode: LocationRecordingMode
    let receivedCount: Int
    let emittedCount: Int
}
