@testable import DriveLog

@MainActor
final class FakePowerStateProvider: PowerStateProviding {
    nonisolated let changes: AsyncStream<PowerState>

    private let continuation: AsyncStream<PowerState>.Continuation
    private(set) var current: PowerState

    init(current: PowerState = .unplugged) {
        let stream = AsyncStream.makeStream(of: PowerState.self, bufferingPolicy: .unbounded)
        changes = stream.stream
        continuation = stream.continuation
        self.current = current
    }

    func send(_ state: PowerState) {
        current = state
        continuation.yield(state)
    }
}
