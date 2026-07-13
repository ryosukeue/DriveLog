@testable import DriveLog

@MainActor
final class FakePermissionManager: PermissionManaging {
    nonisolated let updates: AsyncStream<PermissionState>
    private(set) var currentState: PermissionState
    private(set) var refreshCount = 0
    private(set) var locationWhenInUseRequestCount = 0
    private(set) var locationAlwaysRequestCount = 0
    private(set) var motionRequestCount = 0
    private(set) var photosRequestCount = 0
    private(set) var openSettingsCount = 0

    private let continuation: AsyncStream<PermissionState>.Continuation

    init(state: PermissionState) {
        let stream = AsyncStream.makeStream(of: PermissionState.self)
        updates = stream.stream
        continuation = stream.continuation
        currentState = state
    }

    func refresh() async {
        refreshCount += 1
    }

    func requestLocationWhenInUse() async {
        locationWhenInUseRequestCount += 1
    }

    func requestLocationAlways() async {
        locationAlwaysRequestCount += 1
    }

    func requestMotion() async {
        motionRequestCount += 1
    }

    func requestPhotos() async {
        photosRequestCount += 1
    }

    func openSystemSettings() {
        openSettingsCount += 1
    }

    func send(_ state: PermissionState) {
        currentState = state
        continuation.yield(state)
    }
}
