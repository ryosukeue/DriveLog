@testable import DriveLog
import os

@MainActor
final class HapticFeedbackSpy: HapticFeedbackProviding {
    private(set) var callCount = 0

    func performLightSuccess() {
        callCount += 1
    }
}

final class StayUseCaseSpy: UpdateStayOverrideUseCase, @unchecked Sendable {
    struct Call: Sendable {
        let stableID: String
        let action: StayOverrideAction
    }

    private let storage = OSAllocatedUnfairLock(initialState: [Call]())
    private let error: DriveLogError?

    var calls: [Call] {
        storage.withLock { $0 }
    }

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(stay: StaySegmentData, action: StayOverrideAction) throws {
        storage.withLock { $0.append(Call(stableID: stay.stableID, action: action)) }
        if let error {
            throw error
        }
    }
}

final class SuspendedStayUseCase: UpdateStayOverrideUseCase, @unchecked Sendable {
    private struct State {
        var callCount = 0
        var continuation: CheckedContinuation<Void, Never>?
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())

    var callCount: Int {
        storage.withLock(\.callCount)
    }

    var isSuspended: Bool {
        storage.withLock { $0.continuation != nil }
    }

    func execute(stay _: StaySegmentData, action _: StayOverrideAction) async {
        storage.withLock { $0.callCount += 1 }
        await withCheckedContinuation { continuation in
            storage.withLock { $0.continuation = continuation }
        }
    }

    func resume() {
        let continuation = storage.withLock { state in
            defer { state.continuation = nil }
            return state.continuation
        }
        continuation?.resume()
    }
}
