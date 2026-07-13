@testable import DriveLog

actor FakeVisitProvider: VisitProviding {
    nonisolated let events: AsyncStream<VisitProviderEvent>

    private let continuation: AsyncStream<VisitProviderEvent>.Continuation
    private var state: VisitMonitoringState
    private var startCount = 0
    private var stopCount = 0
    private var startError: DriveLogError?

    init(state: VisitMonitoringState = .stopped) {
        let stream = AsyncStream.makeStream(of: VisitProviderEvent.self)
        events = stream.stream
        continuation = stream.continuation
        self.state = state
    }

    var monitoringState: VisitMonitoringState {
        get async { state }
    }

    func startMonitoring() async throws {
        startCount += 1
        if let startError {
            throw startError
        }
        state = .running
        continuation.yield(.stateChanged(.running))
    }

    func stopMonitoring() async {
        stopCount += 1
        state = .stopped
        continuation.yield(.stateChanged(.stopped))
    }

    func send(_ event: VisitProviderEvent) {
        continuation.yield(event)
    }

    func setStartError(_ error: DriveLogError?) {
        startError = error
    }

    func callCounts() -> (start: Int, stop: Int) {
        (startCount, stopCount)
    }
}
