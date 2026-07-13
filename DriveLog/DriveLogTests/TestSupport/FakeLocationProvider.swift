@testable import DriveLog

actor FakeLocationProvider: LocationProviding {
    nonisolated let events: AsyncStream<LocationProviderEvent>

    private let continuation: AsyncStream<LocationProviderEvent>.Continuation
    private var state: LocationMonitoringState
    private var startCount = 0
    private var stopCount = 0
    private var startError: DriveLogError?

    init(state: LocationMonitoringState = .stopped) {
        let stream = AsyncStream.makeStream(of: LocationProviderEvent.self)
        events = stream.stream
        continuation = stream.continuation
        self.state = state
    }

    var monitoringState: LocationMonitoringState {
        get async { state }
    }

    func startSignificantLocationMonitoring() async throws {
        startCount += 1
        if let startError {
            throw startError
        }
        state = .running
        continuation.yield(.stateChanged(.running))
    }

    func stopSignificantLocationMonitoring() async {
        stopCount += 1
        state = .stopped
        continuation.yield(.stateChanged(.stopped))
    }

    func send(_ event: LocationProviderEvent) {
        continuation.yield(event)
    }

    func setState(_ state: LocationMonitoringState) {
        self.state = state
        continuation.yield(.stateChanged(state))
    }

    func setStartError(_ error: DriveLogError?) {
        startError = error
    }

    func callCounts() -> (start: Int, stop: Int) {
        (startCount, stopCount)
    }
}
