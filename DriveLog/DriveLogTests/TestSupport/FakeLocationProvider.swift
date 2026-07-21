@testable import DriveLog

@MainActor
final class FakeLocationProvider: LocationProviding {
    nonisolated let events: AsyncStream<LocationProviderEvent>
    nonisolated let locationChanges: AsyncStream<LocationEventData>

    private let continuation: AsyncStream<LocationProviderEvent>.Continuation
    private let locationContinuation: AsyncStream<LocationEventData>.Continuation
    private var state: LocationMonitoringState
    private var startCount = 0
    private var stopCount = 0
    private var startError: DriveLogError?
    private var modes: [LocationRecordingMode] = []

    init(state: LocationMonitoringState = .stopped) {
        let stream = AsyncStream.makeStream(of: LocationProviderEvent.self)
        let locationStream = AsyncStream.makeStream(of: LocationEventData.self)
        events = stream.stream
        locationChanges = locationStream.stream
        continuation = stream.continuation
        locationContinuation = locationStream.continuation
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

    func setRecordingMode(_ mode: LocationRecordingMode) async throws {
        modes.append(mode)
        try await startSignificantLocationMonitoring()
    }

    func send(_ event: LocationProviderEvent) {
        continuation.yield(event)
        if case let .location(location) = event {
            locationContinuation.yield(location)
        }
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

    func appliedModes() -> [LocationRecordingMode] {
        modes
    }
}
