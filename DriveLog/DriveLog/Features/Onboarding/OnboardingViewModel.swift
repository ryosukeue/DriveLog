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

    var deniedMessage: String? {
        switch phase {
        case .location where isDenied(permissionState.location):
            "位置情報が許可されていません。バックグラウンドで移動を記録するには、設定で位置情報を「常に許可」にしてください。"
        case .motion where isDenied(permissionState.motion):
            "モーションが許可されていません。移動方法の推定は利用できませんが、位置記録は継続できます。"
        case .photos where isDenied(permissionState.photos):
            "写真へのアクセスが許可されていません。移動記録は利用できますが、写真や動画は表示されません。"
        default:
            nil
        }
    }

    var limitedPhotosMessage: String? {
        guard phase == .photos, permissionState.photos == .limited else { return nil }
        return "選択した写真と動画だけを表示します。表示する項目は設定から変更できます。"
    }

    func openSystemSettings() {
        permissionManager.openSystemSettings()
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

    private func isDenied(_ state: LocationPermissionState) -> Bool {
        state == .denied || state == .restricted
    }

    private func isDenied(_ state: MotionPermissionState) -> Bool {
        state == .denied || state == .restricted
    }

    private func isDenied(_ state: PhotoPermissionState) -> Bool {
        state == .denied || state == .restricted
    }
}
