import Foundation
import os

nonisolated protocol BackgroundTaskCoordinating: Sendable {
    func handle(task: any BackgroundProcessingTask)
}

final nonisolated class BackgroundTaskCoordinator: BackgroundTaskCoordinating, @unchecked Sendable {
    static let defaultPendingDayLimit = 3

    private let dayProcessingCoordinator: any DayProcessingCoordinating
    private let pendingDayLimit: Int

    init(
        dayProcessingCoordinator: any DayProcessingCoordinating,
        pendingDayLimit: Int = defaultPendingDayLimit
    ) {
        self.dayProcessingCoordinator = dayProcessingCoordinator
        self.pendingDayLimit = max(0, pendingDayLimit)
    }

    func handle(task: any BackgroundProcessingTask) {
        let lifecycle = BackgroundTaskLifecycleState()
        let dayProcessingCoordinator = dayProcessingCoordinator
        task.setExpirationHandler {
            guard lifecycle.expire() else { return }
            Task {
                await dayProcessingCoordinator.cancelCurrentProcessing()
            }
        }
        Task {
            await dayProcessingCoordinator.processPendingDays(limit: pendingDayLimit)
            task.setTaskCompleted(success: lifecycle.complete())
        }
    }
}

private final nonisolated class BackgroundTaskLifecycleState: @unchecked Sendable {
    private enum State {
        case active
        case expired
        case completed
    }

    private let storage = OSAllocatedUnfairLock(initialState: State.active)

    func expire() -> Bool {
        storage.withLock { state in
            guard state == .active else { return false }
            state = .expired
            return true
        }
    }

    func complete() -> Bool {
        storage.withLock { state in
            let succeeded = state == .active
            state = .completed
            return succeeded
        }
    }
}
