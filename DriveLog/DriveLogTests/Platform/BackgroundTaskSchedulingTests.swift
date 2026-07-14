@testable import DriveLog
import os
import Testing

@Suite("Background task scheduling")
struct BackgroundTaskSchedulingTests {
    @Test("records registration scheduling conditions and cancellation")
    func recordsOperations() throws {
        let scheduler = BackgroundTaskSchedulerFake()

        try scheduler.registerProcessingTask()
        try scheduler.scheduleProcessingTask(requiresExternalPower: true)
        scheduler.cancelPendingProcessingTask()

        #expect(scheduler.registrationCount == 1)
        #expect(scheduler.externalPowerRequirements == [true])
        #expect(scheduler.cancellationCount == 1)
    }

    @Test("reproduces registration and scheduling failures")
    func failures() {
        let registration = BackgroundTaskSchedulerFake(registrationError: .backgroundTaskUnavailable)
        #expect(throws: DriveLogError.backgroundTaskUnavailable) {
            try registration.registerProcessingTask()
        }

        let scheduling = BackgroundTaskSchedulerFake(schedulingError: .backgroundTaskUnavailable)
        #expect(throws: DriveLogError.backgroundTaskUnavailable) {
            try scheduling.scheduleProcessingTask(requiresExternalPower: false)
        }
        #expect(scheduling.externalPowerRequirements == [false])
    }
}

private final class BackgroundTaskSchedulerFake: BackgroundTaskScheduling, @unchecked Sendable {
    private struct State {
        var registrationCount = 0
        var requirements: [Bool] = []
        var cancellationCount = 0
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())
    private let registrationError: DriveLogError?
    private let schedulingError: DriveLogError?

    var registrationCount: Int {
        storage.withLock(\.registrationCount)
    }

    var externalPowerRequirements: [Bool] {
        storage.withLock(\.requirements)
    }

    var cancellationCount: Int {
        storage.withLock(\.cancellationCount)
    }

    init(
        registrationError: DriveLogError? = nil,
        schedulingError: DriveLogError? = nil
    ) {
        self.registrationError = registrationError
        self.schedulingError = schedulingError
    }

    func registerProcessingTask() throws {
        storage.withLock { $0.registrationCount += 1 }
        if let registrationError {
            throw registrationError
        }
    }

    func scheduleProcessingTask(requiresExternalPower: Bool) throws {
        storage.withLock { $0.requirements.append(requiresExternalPower) }
        if let schedulingError {
            throw schedulingError
        }
    }

    func cancelPendingProcessingTask() {
        storage.withLock { $0.cancellationCount += 1 }
    }
}
