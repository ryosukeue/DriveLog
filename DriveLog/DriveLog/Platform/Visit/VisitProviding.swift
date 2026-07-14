@MainActor
protocol VisitProviding: Sendable {
    var monitoringState: VisitMonitoringState { get async }
    nonisolated var events: AsyncStream<VisitProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}

nonisolated enum VisitMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

nonisolated enum VisitProviderEvent: Sendable {
    case visit(VisitEventData)
    case stateChanged(VisitMonitoringState)
    case error(DriveLogError)
}
