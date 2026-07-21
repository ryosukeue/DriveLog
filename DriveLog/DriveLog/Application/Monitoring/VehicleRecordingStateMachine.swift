import Foundation

nonisolated enum VehicleRecordingState: String, Sendable, Equatable {
    case idle
    case candidate
    case driving
    case stopping
}

nonisolated struct VehicleRecordingStateMachine: Sendable {
    private(set) var state: VehicleRecordingState = .idle

    mutating func observeAutomotiveActivity() -> VehicleRecordingState {
        switch state {
        case .idle, .stopping:
            state = .candidate
        case .candidate, .driving:
            break
        }
        return state
    }

    mutating func confirmLocationMovement() -> VehicleRecordingState {
        switch state {
        case .candidate, .stopping:
            state = .driving
        case .idle, .driving:
            break
        }
        return state
    }

    mutating func observeNonAutomotiveActivity() -> VehicleRecordingState {
        switch state {
        case .candidate:
            state = .idle
        case .driving:
            state = .stopping
        case .idle, .stopping:
            break
        }
        return state
    }

    mutating func expireStopGracePeriod() -> VehicleRecordingState {
        if state == .stopping {
            state = .idle
        }
        return state
    }

    mutating func expireCandidate() -> VehicleRecordingState {
        if state == .candidate {
            state = .idle
        }
        return state
    }
}
