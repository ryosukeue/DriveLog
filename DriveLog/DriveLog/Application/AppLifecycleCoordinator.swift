@MainActor
protocol AppLifecycleCoordinating: AnyObject {
    func handleLaunch() async
    func handleForeground() async
    func handleBackground() async
}

@MainActor
final class AppLifecycleCoordinator: AppLifecycleCoordinating {
    static let foregroundPendingDayLimit = 4

    private let permissionManager: any PermissionManaging
    private let startMonitoringUseCase: StartMonitoringUseCase
    private let dayProcessingCoordinator: any DayProcessingCoordinating
    private let backgroundTaskScheduler: any BackgroundTaskScheduling
    private let processingAlgorithmMigrator: any ProcessingAlgorithmMigrating
    private let vehicleDriveSessionCoordinator: VehicleDriveSessionCoordinator?

    init(
        permissionManager: any PermissionManaging,
        startMonitoringUseCase: StartMonitoringUseCase,
        dayProcessingCoordinator: any DayProcessingCoordinating,
        backgroundTaskScheduler: any BackgroundTaskScheduling,
        vehicleDriveSessionCoordinator: VehicleDriveSessionCoordinator? = nil,
        processingAlgorithmMigrator: any ProcessingAlgorithmMigrating =
            NoOpProcessingAlgorithmMigrator()
    ) {
        self.permissionManager = permissionManager
        self.startMonitoringUseCase = startMonitoringUseCase
        self.dayProcessingCoordinator = dayProcessingCoordinator
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.vehicleDriveSessionCoordinator = vehicleDriveSessionCoordinator
        self.processingAlgorithmMigrator = processingAlgorithmMigrator
    }

    func handleLaunch() async {
        await vehicleDriveSessionCoordinator?.start()
        await processingAlgorithmMigrator.migrateIfNeeded()
        try? backgroundTaskScheduler.registerProcessingTask()
        await refreshPermissionsAndMonitoring()
    }

    func handleForeground() async {
        await refreshPermissionsAndMonitoring()
    }

    func handleBackground() async {
        try? backgroundTaskScheduler.scheduleProcessingTask(requiresExternalPower: true)
        // Significant Location Change monitoring must continue in the background.
    }

    private func refreshPermissionsAndMonitoring() async {
        await permissionManager.refresh()
        try? await startMonitoringUseCase.execute()
        await dayProcessingCoordinator.processPendingDays(limit: Self.foregroundPendingDayLimit)
    }
}
