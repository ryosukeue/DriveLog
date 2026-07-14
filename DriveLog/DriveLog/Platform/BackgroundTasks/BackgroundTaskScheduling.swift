nonisolated protocol BackgroundTaskScheduling: Sendable {
    func registerProcessingTask() throws
    func scheduleProcessingTask(requiresExternalPower: Bool) throws
    func cancelPendingProcessingTask()
}

nonisolated protocol BackgroundProcessingTask: Sendable {
    func setExpirationHandler(_ handler: @escaping @Sendable () -> Void)
    func setTaskCompleted(success: Bool)
}
