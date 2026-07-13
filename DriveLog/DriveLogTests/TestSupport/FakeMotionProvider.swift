@testable import DriveLog

actor FakeMotionProvider: MotionProviding {
    nonisolated let events: AsyncStream<MotionProviderEvent>

    private let continuation: AsyncStream<MotionProviderEvent>.Continuation
    private var state: MotionMonitoringState
    private var startCount = 0
    private var stopCount = 0
    private var startError: DriveLogError?

    init(state: MotionMonitoringState = .stopped) {
        let stream = AsyncStream.makeStream(of: MotionProviderEvent.self)
        events = stream.stream
        continuation = stream.continuation
        self.state = state
    }

    var monitoringState: MotionMonitoringState {
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

    func send(_ event: MotionProviderEvent) {
        continuation.yield(event)
    }

    func setStartError(_ error: DriveLogError?) {
        startError = error
    }

    func finish() {
        continuation.finish()
    }

    func callCounts() -> (start: Int, stop: Int) {
        (startCount, stopCount)
    }
}
