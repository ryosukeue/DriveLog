@MainActor
protocol AppLifecycleCoordinating: AnyObject {
    func handleLaunch() async
    func handleForeground() async
    func handleBackground() async
}

@MainActor
final class AppLifecycleCoordinator: AppLifecycleCoordinating {
    private let permissionManager: any PermissionManaging
    private let startMonitoringUseCase: StartMonitoringUseCase
    private let dayProcessingCoordinator: any DayProcessingCoordinating

    init(
        permissionManager: any PermissionManaging,
        startMonitoringUseCase: StartMonitoringUseCase,
        dayProcessingCoordinator: any DayProcessingCoordinating
    ) {
        self.permissionManager = permissionManager
        self.startMonitoringUseCase = startMonitoringUseCase
        self.dayProcessingCoordinator = dayProcessingCoordinator
    }

    func handleLaunch() async {
        await refreshPermissionsAndMonitoring()
    }

    func handleForeground() async {
        await refreshPermissionsAndMonitoring()
    }

    func handleBackground() async {
        // Significant Location Change monitoring must continue in the background.
    }

    private func refreshPermissionsAndMonitoring() async {
        await permissionManager.refresh()
        try? await startMonitoringUseCase.execute()
        await dayProcessingCoordinator.processPendingDays(limit: 1)
    }
}
