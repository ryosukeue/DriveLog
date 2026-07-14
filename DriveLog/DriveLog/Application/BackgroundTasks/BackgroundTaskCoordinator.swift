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
        let expiration = BackgroundTaskExpirationState()
        let dayProcessingCoordinator = dayProcessingCoordinator
        task.setExpirationHandler {
            expiration.markExpired()
            Task {
                await dayProcessingCoordinator.cancelCurrentProcessing()
            }
        }
        Task {
            await dayProcessingCoordinator.processPendingDays(limit: pendingDayLimit)
            task.setTaskCompleted(success: !expiration.isExpired)
        }
    }
}

private final class BackgroundTaskExpirationState: @unchecked Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: false)

    var isExpired: Bool {
        storage.withLock { $0 }
    }

    func markExpired() {
        storage.withLock { $0 = true }
    }
}
