@MainActor
protocol PermissionManaging: AnyObject {
    var currentState: PermissionState { get }
    var updates: AsyncStream<PermissionState> { get }

    func refresh() async
    func requestLocationWhenInUse() async
    func requestLocationAlways() async
    func requestMotion() async
    func requestPhotos() async
    func openSystemSettings()
}
