import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Phase: Sendable, Equatable {
        case location
        case motion
    }

    private(set) var permissionState: PermissionState
    private(set) var isRequesting = false
    private(set) var phase: Phase = .location
    private let permissionManager: any PermissionManaging

    init(permissionManager: any PermissionManaging) {
        self.permissionManager = permissionManager
        permissionState = permissionManager.currentState
    }

    var primaryActionTitle: String {
        if phase == .motion {
            return permissionState.motion == .notDetermined
                ? "モーションの利用を許可する" : "次へ"
        }
        return switch permissionState.location {
        case .notDetermined:
            "位置情報の設定を始める"
        case .whenInUse:
            "「常に許可」の設定へ進む"
        case .always, .denied, .restricted:
            "次へ"
        }
    }

    func performPrimaryAction() async -> Bool {
        guard !isRequesting else { return false }
        isRequesting = true
        defer { isRequesting = false }
        switch phase {
        case .location:
            return await performLocationAction()
        case .motion:
            return await performMotionAction()
        }
    }

    private func performLocationAction() async -> Bool {
        switch permissionState.location {
        case .notDetermined:
            await permissionManager.requestLocationWhenInUse()
            synchronizeState()
            return false
        case .whenInUse:
            await permissionManager.requestLocationAlways()
            synchronizeState()
            if permissionState.location != .whenInUse {
                phase = .motion
            }
            return false
        case .always, .denied, .restricted:
            phase = .motion
            return false
        }
    }

    private func performMotionAction() async -> Bool {
        switch permissionState.motion {
        case .notDetermined:
            await permissionManager.requestMotion()
            synchronizeState()
            return false
        case .authorized, .denied, .restricted:
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
