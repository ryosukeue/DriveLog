@testable import DriveLog

@MainActor
final class FakeMotionProvider: MotionProviding {
    nonisolated let events: AsyncStream<MotionProviderEvent>
    nonisolated let activityChanges: AsyncStream<MotionEventData>

    private let continuation: AsyncStream<MotionProviderEvent>.Continuation
    private let activityContinuation: AsyncStream<MotionEventData>.Continuation
    private var state: MotionMonitoringState
    private var startCount = 0
    private var stopCount = 0
    private var startError: DriveLogError?

    init(state: MotionMonitoringState = .stopped) {
        let stream = AsyncStream.makeStream(of: MotionProviderEvent.self)
        let activityStream = AsyncStream.makeStream(of: MotionEventData.self)
        events = stream.stream
        activityChanges = activityStream.stream
        continuation = stream.continuation
        activityContinuation = activityStream.continuation
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
        if case let .motion(motionEvent) = event {
            activityContinuation.yield(motionEvent)
        }
    }

    func sendActivity(_ event: MotionEventData) {
        activityContinuation.yield(event)
    }

    func setStartError(_ error: DriveLogError?) {
        startError = error
    }

    func finish() {
        continuation.finish()
        activityContinuation.finish()
    }

    func callCounts() -> (start: Int, stop: Int) {
        (startCount, stopCount)
    }
}
