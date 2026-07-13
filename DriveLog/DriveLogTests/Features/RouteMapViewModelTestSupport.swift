@testable import DriveLog

actor StayUseCaseSpy: UpdateStayOverrideUseCase {
    struct Call: Sendable {
        let stableID: String
        let action: StayOverrideAction
    }

    private(set) var calls: [Call] = []
    private let error: DriveLogError?

    init(error: DriveLogError? = nil) {
        self.error = error
    }

    func execute(stay: StaySegmentData, action: StayOverrideAction) throws {
        calls.append(Call(stableID: stay.stableID, action: action))
        if let error {
            throw error
        }
    }
}

actor SuspendedStayUseCase: UpdateStayOverrideUseCase {
    private(set) var callCount = 0
    private(set) var isSuspended = false
    private var continuation: CheckedContinuation<Void, Never>?

    func execute(stay _: StaySegmentData, action _: StayOverrideAction) async {
        callCount += 1
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            isSuspended = true
        }
    }

    func resume() {
        continuation?.resume()
        continuation = nil
        isSuspended = false
    }
}
