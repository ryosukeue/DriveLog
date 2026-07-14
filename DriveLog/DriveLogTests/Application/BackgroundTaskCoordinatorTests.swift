@testable import DriveLog
import os
import Testing

@Suite("Background task coordinator")
struct BackgroundTaskCoordinatorTests {
    @Test("processes the default pending limit and completes successfully")
    func defaultLimit() async {
        let processing = BackgroundProcessingCoordinatorFake()
        let task = BackgroundProcessingTaskFake()
        let coordinator = BackgroundTaskCoordinator(dayProcessingCoordinator: processing)

        coordinator.handle(task: task)
        await waitUntil { task.completions.count == 1 }

        #expect(await processing.pendingLimits == [3])
        #expect(task.completions == [true])
        #expect(await processing.cancelCount == 0)
    }

    @Test("forwards a custom pending limit")
    func customLimit() async {
        let processing = BackgroundProcessingCoordinatorFake()
        let task = BackgroundProcessingTaskFake()
        let coordinator = BackgroundTaskCoordinator(
            dayProcessingCoordinator: processing,
            pendingDayLimit: 5
        )

        coordinator.handle(task: task)
        await waitUntil { task.completions.count == 1 }

        #expect(await processing.pendingLimits == [5])
        #expect(task.completions == [true])
    }

    @Test("expiration cancels processing and completes with failure once")
    func expiration() async {
        let processing = BackgroundProcessingCoordinatorFake(suspendsProcessing: true)
        let task = BackgroundProcessingTaskFake()
        let coordinator = BackgroundTaskCoordinator(dayProcessingCoordinator: processing)
        coordinator.handle(task: task)
        await processing.waitUntilProcessingStarted()

        task.triggerExpiration()
        task.triggerExpiration()
        await waitUntil { await processing.cancelCount == 1 }
        await processing.resumeProcessing()
        await waitUntil { task.completions.count == 1 }

        #expect(await processing.cancelCount == 1)
        #expect(task.completions == [false])
    }

    @Test("expiration after completion does not cancel completed work")
    func lateExpiration() async {
        let processing = BackgroundProcessingCoordinatorFake()
        let task = BackgroundProcessingTaskFake()
        let coordinator = BackgroundTaskCoordinator(dayProcessingCoordinator: processing)
        coordinator.handle(task: task)
        await waitUntil { task.completions.count == 1 }

        task.triggerExpiration()
        for _ in 0 ..< 10 {
            await Task.yield()
        }

        #expect(task.completions == [true])
        #expect(await processing.cancelCount == 0)
    }
}

private actor BackgroundProcessingCoordinatorFake: DayProcessingCoordinating {
    private(set) var pendingLimits: [Int] = []
    private(set) var cancelCount = 0
    private let suspendsProcessing: Bool
    private var processingContinuation: CheckedContinuation<Void, Never>?
    private var startWaiters: [CheckedContinuation<Void, Never>] = []

    init(suspendsProcessing: Bool = false) {
        self.suspendsProcessing = suspendsProcessing
    }

    func processIfNeeded(localDateKey _: String, priority _: ProcessingPriority) {}

    func processPendingDays(limit: Int) async {
        pendingLimits.append(limit)
        let waiters = startWaiters
        startWaiters.removeAll()
        waiters.forEach { $0.resume() }
        if suspendsProcessing {
            await withCheckedContinuation { processingContinuation = $0 }
        }
    }

    func cancelCurrentProcessing() {
        cancelCount += 1
    }

    func waitUntilProcessingStarted() async {
        guard pendingLimits.isEmpty else { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func resumeProcessing() {
        processingContinuation?.resume()
        processingContinuation = nil
    }
}

private final class BackgroundProcessingTaskFake: BackgroundProcessingTask, @unchecked Sendable {
    private struct State {
        var expirationHandler: (@Sendable () -> Void)?
        var completions: [Bool] = []
    }

    private let storage = OSAllocatedUnfairLock(initialState: State())

    var completions: [Bool] {
        storage.withLock(\.completions)
    }

    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void) {
        storage.withLock { $0.expirationHandler = handler }
    }

    func setTaskCompleted(success: Bool) {
        storage.withLock { $0.completions.append(success) }
    }

    func triggerExpiration() {
        let handler = storage.withLock { $0.expirationHandler }
        handler?()
    }
}

private func waitUntil(_ condition: () async -> Bool) async {
    for _ in 0 ..< 1000 {
        if await condition() {
            return
        }
        await Task.yield()
    }
}
