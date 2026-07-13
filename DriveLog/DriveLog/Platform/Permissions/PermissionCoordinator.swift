import CoreLocation
import CoreMotion
import Photos

@MainActor
final class PermissionCoordinator: PermissionManaging {
    nonisolated let updates: AsyncStream<PermissionState>
    private(set) var currentState: PermissionState

    private let system: any PermissionSystemAccessing
    private let continuation: AsyncStream<PermissionState>.Continuation
    private var observationTask: Task<Void, Never>?

    convenience init() {
        self.init(system: SystemPermissionAccess())
    }

    init(system: any PermissionSystemAccessing) {
        let stream = AsyncStream.makeStream(of: PermissionState.self)
        updates = stream.stream
        continuation = stream.continuation
        self.system = system
        currentState = Self.makeState(system: system)
        observationTask = Task { [weak self, changes = system.authorizationChanges] in
            for await _ in changes {
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    deinit {
        observationTask?.cancel()
        continuation.finish()
    }

    func refresh() async {
        let state = Self.makeState(system: system)
        guard state != currentState else { return }
        currentState = state
        continuation.yield(state)
    }

    func requestLocationWhenInUse() async {
        system.requestLocationWhenInUse()
        await refresh()
    }

    func requestLocationAlways() async {
        system.requestLocationAlways()
        await refresh()
    }

    func requestMotion() async {
        system.requestMotion()
        await refresh()
    }

    func requestPhotos() async {
        await system.requestPhotos()
        await refresh()
    }

    func openSystemSettings() {
        system.openSystemSettings()
    }

    static func locationState(_ status: CLAuthorizationStatus) -> LocationPermissionState {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorizedWhenInUse: .whenInUse
        case .authorizedAlways: .always
        @unknown default: .denied
        }
    }

    static func motionState(_ status: CMAuthorizationStatus) -> MotionPermissionState {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .denied
        }
    }

    static func photoState(_ status: PHAuthorizationStatus) -> PhotoPermissionState {
        switch status {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .limited: .limited
        case .authorized: .authorized
        @unknown default: .denied
        }
    }

    private static func makeState(system: any PermissionSystemAccessing) -> PermissionState {
        PermissionState(
            location: locationState(system.locationStatus),
            motion: motionState(system.motionStatus),
            photos: photoState(system.photoStatus)
        )
    }
}
