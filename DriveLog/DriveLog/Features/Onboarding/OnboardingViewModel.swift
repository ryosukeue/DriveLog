import Observation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Phase: Sendable, Equatable {
        case location
        case motion
        case photos
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
        if phase == .photos {
            return permissionState.photos == .notDetermined
                ? "写真と動画の利用を許可する" : "DriveLogを始める"
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
        case .photos:
            return await performPhotosAction()
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
            phase = .photos
            return false
        }
    }

    private func performPhotosAction() async -> Bool {
        switch permissionState.photos {
        case .notDetermined:
            await permissionManager.requestPhotos()
            synchronizeState()
            return false
        case .authorized, .limited, .denied, .restricted:
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
