import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    private(set) var permissionState: PermissionState
    private(set) var isRequesting = false
    private let permissionManager: any PermissionManaging

    init(permissionManager: any PermissionManaging) {
        self.permissionManager = permissionManager
        permissionState = permissionManager.currentState
    }

    var primaryActionTitle: String {
        switch permissionState.location {
        case .notDetermined:
            "位置情報の設定を始める"
        case .whenInUse:
            "「常に許可」の設定へ進む"
        case .always, .denied, .restricted:
            "次へ"
        }
    }

    func performLocationAction() async -> Bool {
        guard !isRequesting else { return false }
        isRequesting = true
        defer { isRequesting = false }
        switch permissionState.location {
        case .notDetermined:
            await permissionManager.requestLocationWhenInUse()
            synchronizeState()
            return false
        case .whenInUse:
            await permissionManager.requestLocationAlways()
            synchronizeState()
            return permissionState.location != .whenInUse
        case .always, .denied, .restricted:
            return true
        }
    }

    func observePermissionUpdates() async {
        for await state in permissionManager.updates {
            guard !Task.isCancelled else { return }
            permissionState = state
        }
    }

    private func synchronizeState() {
        permissionState = permissionManager.currentState
    }
}
