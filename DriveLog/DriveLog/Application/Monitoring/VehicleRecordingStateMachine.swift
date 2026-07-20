import Foundation

nonisolated enum VehicleRecordingState: String, Sendable, Equatable {
    case idle
    case driving
    case stopping
}

nonisolated struct VehicleRecordingStateMachine: Sendable {
    private(set) var state: VehicleRecordingState = .idle

    mutating func observeAutomotiveActivity() -> VehicleRecordingState {
        state = .driving
        return state
    }

    mutating func observeNonAutomotiveActivity() -> VehicleRecordingState {
        guard state == .driving else { return state }
        state = .stopping
        return state
    }

    mutating func expireStopGracePeriod() -> VehicleRecordingState {
        state = .idle
        return state
    }
}
