@MainActor
protocol MotionProviding: Sendable {
    var monitoringState: MotionMonitoringState { get async }
    nonisolated var events: AsyncStream<MotionProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}

nonisolated enum MotionMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

nonisolated enum MotionProviderEvent: Sendable {
    case motion(MotionEventData)
    case stateChanged(MotionMonitoringState)
    case error(DriveLogError)
}
