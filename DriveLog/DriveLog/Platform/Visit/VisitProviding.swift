protocol VisitProviding: Sendable {
    var monitoringState: VisitMonitoringState { get async }
    var events: AsyncStream<VisitProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}

enum VisitMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

enum VisitProviderEvent: Sendable {
    case visit(VisitEventData)
    case stateChanged(VisitMonitoringState)
    case error(DriveLogError)
}
