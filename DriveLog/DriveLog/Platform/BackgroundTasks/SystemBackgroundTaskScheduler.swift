import BackgroundTasks

final nonisolated class SystemBackgroundTaskScheduler: BackgroundTaskScheduling, @unchecked Sendable {
    static let processingTaskIdentifier = "com.ryosukeue.DriveLog.processing"

    private let scheduler: BGTaskScheduler
    private let launchHandler: @Sendable (any BackgroundProcessingTask) -> Void

    init(
        scheduler: BGTaskScheduler = .shared,
        launchHandler: @escaping @Sendable (any BackgroundProcessingTask) -> Void
    ) {
        self.scheduler = scheduler
        self.launchHandler = launchHandler
    }

    func registerProcessingTask() throws {
        let didRegister = scheduler.register(
            forTaskWithIdentifier: Self.processingTaskIdentifier,
            using: nil
        ) { [launchHandler] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            launchHandler(SystemBackgroundProcessingTask(task: processingTask))
        }
        guard didRegister else {
            throw DriveLogError.backgroundTaskUnavailable
        }
    }

    func scheduleProcessingTask(requiresExternalPower: Bool) throws {
        scheduler.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskIdentifier)
        request.requiresExternalPower = requiresExternalPower
        request.requiresNetworkConnectivity = false
        do {
            try scheduler.submit(request)
        } catch {
            throw DriveLogError.backgroundTaskUnavailable
        }
    }

    func cancelPendingProcessingTask() {
        scheduler.cancel(taskRequestWithIdentifier: Self.processingTaskIdentifier)
    }
}

private final nonisolated class SystemBackgroundProcessingTask: BackgroundProcessingTask, @unchecked Sendable {
    private let task: BGProcessingTask

    init(task: BGProcessingTask) {
        self.task = task
    }

    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void) {
        task.expirationHandler = handler
    }

    func setTaskCompleted(success: Bool) {
        task.setTaskCompleted(success: success)
    }
}
