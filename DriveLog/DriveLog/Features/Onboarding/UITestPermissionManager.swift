#if DEBUG
    @MainActor
    final class UITestPermissionManager: PermissionManaging {
        nonisolated let updates: AsyncStream<PermissionState>
        private(set) var currentState = PermissionState(
            location: .notDetermined,
            motion: .notDetermined,
            photos: .notDetermined
        )

        private let continuation: AsyncStream<PermissionState>.Continuation

        init() {
            let stream = AsyncStream.makeStream(of: PermissionState.self)
            updates = stream.stream
            continuation = stream.continuation
        }

        func refresh() async {}

        func requestLocationWhenInUse() async {
            update(location: .whenInUse)
        }

        func requestLocationAlways() async {
            update(location: .always)
        }

        func requestMotion() async {
            update(motion: .authorized)
        }

        func requestPhotos() async {
            update(photos: .limited)
        }

        func openSystemSettings() {}

        private func update(
            location: LocationPermissionState? = nil,
            motion: MotionPermissionState? = nil,
            photos: PhotoPermissionState? = nil
        ) {
            currentState = PermissionState(
                location: location ?? currentState.location,
                motion: motion ?? currentState.motion,
                photos: photos ?? currentState.photos
            )
            continuation.yield(currentState)
        }
    }
#endif
