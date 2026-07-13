protocol MotionProviding: Sendable {
    var monitoringState: MotionMonitoringState { get async }
    var events: AsyncStream<MotionProviderEvent> { get }

    func startMonitoring() async throws
    func stopMonitoring() async
}

enum MotionMonitoringState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case unavailable
    case failed(code: String)
}

enum MotionProviderEvent: Sendable {
    case motion(MotionEventData)
    case stateChanged(MotionMonitoringState)
    case error(DriveLogError)
}
