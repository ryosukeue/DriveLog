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

    init(
        permissionManager: any PermissionManaging,
        startMonitoringUseCase: StartMonitoringUseCase
    ) {
        self.permissionManager = permissionManager
        self.startMonitoringUseCase = startMonitoringUseCase
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
    }
}
